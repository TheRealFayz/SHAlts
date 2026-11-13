-------------------------------------------------------------------------------
-- Weekly dungeon quest: has this character already done it this week?
--
-- The game gives an addon no list of finished quests, so this watches for the
-- quest being handed in. A turn-in is only counted once the quest is gone from the
-- quest log afterwards, so a failed hand-in or an abandoned quest is not mistaken
-- for a finished one. The week starts on Thursday at server midnight.
-------------------------------------------------------------------------------
local S = SHAlts

S.Try("Quests.lua", function()

local QUEST = "Call to Arms: Dungeon Delving"
local MIN_LEVEL = 60
local CONFIRM_FOR = 30   -- seconds to wait for the quest to leave the log after a hand-in

S.WeeklyQuestName = QUEST

-- the moment the current week started and the next one begins, as real clock seconds
function S.WeeklyResetStart(now)
	return S.WeeklyQuestWindow(now or time())
end

-- true when the quest is in the quest log right now (taken but not handed in)
local function InLog()
	if not GetNumQuestLogEntries or not GetQuestLogTitle then return false end
	local n = GetNumQuestLogEntries() or 0
	for i = 1, n do
		local title, _, _, isHeader = GetQuestLogTitle(i)
		if title and not isHeader and title == QUEST then return true end
	end
	return false
end
S.WeeklyQuestInLog = InLog

local function Rec()
	local c = S.db and S.GetChar and S.GetChar()
	if not c then return nil end
	if type(c.wq) ~= "table" then c.wq = {} end
	return c.wq
end

-- "low"   the character is too low a level for the quest
-- "done"  handed in since this week started
-- "taken" in the quest log, waiting to be handed in
-- "open"  not done this week and can be picked up
function S.WeeklyQuestStatus(now)
	now = now or time()
	local lvl = UnitLevel and UnitLevel("player") or 0
	if lvl < MIN_LEVEL then return "low" end
	local start = S.WeeklyResetStart(now)
	local wq = Rec()
	if wq and wq.doneAt and start and wq.doneAt >= start then return "done" end
	if InLog() then return "taken" end
	return "open"
end

-- the hand-in is recorded as pending, then confirmed once the quest has left the log
local function Confirm()
	local wq = Rec()
	if not wq or not wq.pending then return end
	if time() - wq.pending > CONFIRM_FOR then
		wq.pending = nil           -- the hand-in never went through
		return
	end
	if not InLog() then
		wq.doneAt = math.floor(wq.pending)
		wq.pending = nil
	end
end
S.WeeklyQuestConfirm = Confirm

if type(GetQuestReward) == "function" then
	local origReward = GetQuestReward
	GetQuestReward = function(choice)
		local title = GetTitleText and GetTitleText()
		if title == QUEST then
			local wq = Rec()
			if wq then
				wq.pending = time()
				-- the quest leaves the log a moment later, so look a few times
				S.After(1.5, Confirm)
				S.After(4, Confirm)
				S.After(10, Confirm)
			end
		end
		return origReward(choice)
	end
end

S.On("QUEST_LOG_UPDATE", Confirm)

-------------------------------------------------------------------------------
-- Login reminder: tell the player the quest can be picked up, but only when it
-- really can (not done this week, not already in the log, level 60 or more).
-------------------------------------------------------------------------------
local LOGIN_WAIT = 15      -- let the quest log finish loading first
local GIVE_UP = 600        -- stop waiting for a calm moment after this long
local REPEAT_GAP = 600     -- no second reminder for the same character this soon (/reload)
local loginAt = 0
local noticeDone = false

function S.QuestNoticeText()
	return "Weekly Dungeon Quest is available to pick up!"
end

local function NoticeCheck()
	if noticeDone then return end
	if not S.db or not S.ready then S.After(3, NoticeCheck); return end
	local waited = GetTime() - loginAt
	if waited > GIVE_UP then noticeDone = true; return end
	if waited < LOGIN_WAIT then S.After(3, NoticeCheck); return end
	-- an empty quest log this early may just not be loaded yet
	if (GetNumQuestLogEntries() or 0) == 0 and waited < 30 then S.After(3, NoticeCheck); return end
	if not S.CalmNow() then S.After(3, NoticeCheck); return end

	noticeDone = true
	if S.db.questNotice == false then return end
	if S.WeeklyQuestStatus() ~= "open" then return end     -- done, in the log, or too low: say nothing
	local wq = Rec()
	if wq and wq.noticeAt and time() - wq.noticeAt < REPEAT_GAP and time() >= wq.noticeAt then return end
	if wq then wq.noticeAt = time() end
	S.RedNotice(S.QuestNoticeText())
end

S.On("PLAYER_LOGIN", function()
	loginAt = GetTime()
	noticeDone = false
	S.After(LOGIN_WAIT, NoticeCheck)
end)

-- one line per fact, for /shalts quest
function S.QuestReport()
	local out = {}
	local status = S.WeeklyQuestStatus()
	local names = {
		low = "too low a level (needs " .. MIN_LEVEL .. ")",
		done = "already done this week",
		taken = "in your quest log, not handed in yet",
		open = "not done this week, you can pick it up",
	}
	table.insert(out, QUEST .. ": " .. (names[status] or status))
	local start, nxt = S.WeeklyResetStart()
	if start then
		table.insert(out, "week started " .. date("%a %b %d, %I:%M %p", start) .. ", resets " .. date("%a %b %d, %I:%M %p", nxt))
	end
	local wq = Rec()
	if wq and wq.doneAt then
		table.insert(out, "last handed in " .. date("%a %b %d, %I:%M %p", wq.doneAt))
	else
		table.insert(out, "no hand-in seen yet on this character")
	end
	return out
end

end)
