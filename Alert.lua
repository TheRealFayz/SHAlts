-------------------------------------------------------------------------------
-- Cooldown alert.
--
-- When a cooldown finishes on ANY stored character (not just the one you are
-- playing), a small window lists it. Everything that is ready at the same time
-- goes in the same window, and anything that finishes while it is open is added
-- to it. Each finished cooldown is announced once.
--
-- It waits while you are in combat or dead, and for a few seconds after logging
-- in. It never takes keyboard focus or blocks the screen, and it can be dragged.
-- Which cooldown was already announced is shared through the sync file, so with
-- several accounts running only one of them pops it up.
-- It can be turned off in the Settings tab.
-------------------------------------------------------------------------------
local S = SHAlts

S.Try("Alert.lua", function()

local CHECK_EVERY = 2      -- seconds between checks
local LOGIN_WAIT = 10      -- let the first scan and sync finish before announcing
local MAX_LINES = 12       -- characters listed before "and N more"

local SAME_WINDOW = 60     -- two end times this close are the same cooldown
local pending = {}         -- id -> { key, name, endsAt, showAt } waiting for a calm moment
local order = {}           -- ids in the order they came in
local shownIds = {}        -- ids currently listed in the window, in order
local shown = {}           -- id -> entry for what the window lists
local loginTime = 0
local popup

S.On("PLAYER_LOGIN", function()
	loginTime = GetTime()
	math.randomseed(math.floor(GetTime() * 1000) + time())
end)

-------------------------------------------------------------------------------
-- Finding finished cooldowns
-------------------------------------------------------------------------------
-- the end time identifies this particular cooldown, so using the item again and
-- waiting it out gives a new announcement. A few seconds of difference in the
-- stored end time (a rescan, another account's copy) is still the same cooldown.
local function SameCooldown(a, b)
	return a ~= nil and b ~= nil and math.abs(a - b) <= SAME_WINDOW
end

function S.QueueAlert(key, name, endsAt)
	local db = S.db
	if not db or not db.alert then return end
	if S.CdTracked and not S.CdTracked(name) then return end   -- switched off in the cooldown list
	local id = key .. "|" .. name
	if SameCooldown(db.alerted[id], endsAt) or pending[id] or shown[id] then return end
	-- A random delay of up to 3 seconds keeps two game windows from picking the
	-- same moment; whichever is second sees the first one's note in the sync file.
	pending[id] = { key = key, name = name, endsAt = endsAt, showAt = GetTime() + math.random() * 3 }
	table.insert(order, id)
end

-- every stored character whose cooldown time has passed
function S.AlertScan()
	local now = time()
	for key, c in pairs(S.db.chars) do
		for name, endsAt in pairs(c.cd or {}) do
			if endsAt and endsAt > 0 and endsAt <= now then S.QueueAlert(key, name, endsAt) end
		end
	end
end

local function Calm()
	if UnitAffectingCombat and UnitAffectingCombat("player") then return false end
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return false end
	return true
end

-------------------------------------------------------------------------------
-- The window
-------------------------------------------------------------------------------
local function Render()
	local p = popup
	-- group by character, keeping the order they became ready
	local keys, names = {}, {}
	for i = 1, table.getn(shownIds) do
		local e = shown[shownIds[i]]
		if S.db.chars[e.key] then
			if not names[e.key] then
				names[e.key] = {}
				table.insert(keys, e.key)
			end
			table.insert(names[e.key], e.name)
		end
	end

	local lines = {}
	local limit = table.getn(keys)
	if limit > MAX_LINES then limit = MAX_LINES end
	for i = 1, limit do
		local key = keys[i]
		table.insert(lines, S.ColoredName(S.db.chars[key]) .. "  |cffaaaaaa-|r  " .. table.concat(names[key], ", "))
	end
	if table.getn(keys) > limit then
		table.insert(lines, "|cffaaaaaaand " .. (table.getn(keys) - limit) .. " more|r")
	end

	p.text:SetText(table.concat(lines, "\n"))
	local h = p.text:GetHeight() or 14
	if h < 14 then h = 14 end
	p:SetHeight(h + 100)

	local n = 0
	for _ in pairs(names) do n = n + 1 end
	if n == 1 then
		p.title:SetText("Cooldown ready")
	else
		p.title:SetText("Cooldowns ready")
	end
end

local function CreatePopup()
	local p = CreateFrame("Frame", "SHAltsAlertPopup", UIParent)
	p:SetWidth(340); p:SetHeight(140)
	p:SetPoint("TOP", UIParent, "TOP", 0, -150)
	p:SetFrameStrata("DIALOG")
	p:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	p:EnableMouse(true)
	p:SetMovable(true)
	p:RegisterForDrag("LeftButton")
	p:SetScript("OnDragStart", function() this:StartMoving() end)
	p:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	p:Hide()
	table.insert(UISpecialFrames, "SHAltsAlertPopup")   -- Escape closes it

	p.title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	p.title:SetPoint("TOP", p, "TOP", 0, -18)

	p.text = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	p.text:SetPoint("TOP", p, "TOP", 0, -44)
	p.text:SetWidth(290)
	p.text:SetJustifyH("LEFT")

	local ok = CreateFrame("Button", "SHAltsAlertOK", p, "UIPanelButtonTemplate")
	ok:SetWidth(128); ok:SetHeight(22)
	ok:SetPoint("BOTTOMRIGHT", p, "BOTTOM", -6, 16)
	ok:SetText("OK")
	ok:SetScript("OnClick", function() p:Hide() end)

	local open = CreateFrame("Button", "SHAltsAlertOpen", p, "UIPanelButtonTemplate")
	open:SetWidth(128); open:SetHeight(22)
	open:SetPoint("BOTTOMLEFT", p, "BOTTOM", 6, 16)
	open:SetText("Open SHAlts")
	open:SetScript("OnClick", function()
		S.tab = "cd"
		S.UI.Show()
		S.UIChanged()
		p:Hide()
	end)

	-- closing it in any way is "seen"; the next window only holds new cooldowns
	p:SetScript("OnHide", function()
		shownIds = {}
		shown = {}
	end)

	popup = p
end

-- pending items move into the window, and are recorded as announced
local function Announce()
	local db = S.db
	local added = false
	for i = 1, table.getn(order) do
		local id = order[i]
		local e = pending[id]
		if e and not SameCooldown(db.alerted[id], e.endsAt) and db.chars[e.key] then
			db.alerted[id] = e.endsAt
			shown[id] = e
			table.insert(shownIds, id)
			added = true
		end
	end
	pending = {}
	order = {}
	return added
end

function S.ShowAlert()
	local db = S.db
	if not db then return end
	if not popup then CreatePopup() end

	-- another account may have announced these a moment ago
	if db.sync and S.SyncAvailable() then S.SyncPull() end
	local added = Announce()
	if not added then return end

	-- tell the other accounts right away so they don't announce it too
	if db.sync and S.SyncAvailable() then
		S.Sync()
	else
		S.syncDirty = true
	end

	Render()
	if not popup:IsShown() then
		popup:Show()
		pcall(PlaySound, "igQuestListOpen")
	end
end

-- for the Test alert button in Settings: shows the window with a sample, without recording anything
function S.ShowAlertPreview()
	if not popup then CreatePopup() end
	shown = {}
	shownIds = {}
	local c = S.db.chars[S.CharKey()]
	local key = S.CharKey()
	if not c then return end
	shown[key .. "|Salt Shaker"] = { key = key, name = "Salt Shaker", endsAt = 0 }
	table.insert(shownIds, key .. "|Salt Shaker")
	Render()
	popup:Show()
end

-------------------------------------------------------------------------------
-- Check every few seconds
-------------------------------------------------------------------------------
local function Check()
	S.After(CHECK_EVERY, Check)
	if not S.ready or not S.db or not S.db.alert then return end
	S.AlertScan()
	if table.getn(order) == 0 then return end
	if GetTime() - loginTime < LOGIN_WAIT then return end
	local due = false
	for i = 1, table.getn(order) do
		local e = pending[order[i]]
		if e and GetTime() >= e.showAt then due = true end
	end
	if not due then return end
	if not Calm() then return end
	S.ShowAlert()
end

S.On("PLAYER_LOGIN", function()
	S.After(CHECK_EVERY, Check)
end)

-------------------------------------------------------------------------------
-- Red message across the middle of the screen (the same style the raid warning
-- uses), with the same text in chat. Used for the login reminders.
-------------------------------------------------------------------------------
function S.RedNotice(text)
	if RaidWarningFrame and RaidWarningFrame.AddMessage then
		RaidWarningFrame:AddMessage(text, 1.0, 0.1, 0.2, 1.0, 8)
	end
	pcall(PlaySound, "RaidWarning")
	S.Print("|cffff0000" .. text .. "|r")
end

-------------------------------------------------------------------------------
-- Login reminder for profession cooldowns that are ready on any of your characters.
-- Custom timers and cooldowns you switched off in the choose list are left out.
-------------------------------------------------------------------------------
local CD_NOTICE_WAIT = 20      -- after the quest reminder, once everything has loaded
local CD_GIVE_UP = 600         -- stop waiting for a calm moment after this long
local CD_REPEAT_GAP = 600      -- no second reminder for the same character this soon (/reload)
local cdLoginAt = 0
local cdNoticeDone = false

-- how many stored cooldowns are ready right now, and on how many characters
function S.ReadyCooldownCount()
	local now = time()
	local n, chars = 0, 0
	for key, c in pairs(S.db.chars) do
		local here = 0
		for name, endsAt in pairs(c.cd or {}) do
			local ready = endsAt ~= nil and endsAt <= now
			local custom = S.IsCustomTimer and S.IsCustomTimer(name)
			local tracked = not S.CdTracked or S.CdTracked(name)
			if ready and tracked and not custom then here = here + 1 end
		end
		if here > 0 then n = n + here; chars = chars + 1 end
	end
	return n, chars
end

function S.CooldownNoticeText()
	return "You have profession cooldowns available, please check the Cooldowns and timers tab."
end

local function CooldownNoticeCheck()
	if cdNoticeDone then return end
	if not S.db or not S.ready then S.After(3, CooldownNoticeCheck); return end
	local waited = GetTime() - cdLoginAt
	if waited > CD_GIVE_UP then cdNoticeDone = true; return end
	if waited < CD_NOTICE_WAIT then S.After(3, CooldownNoticeCheck); return end
	if not S.CalmNow() then S.After(3, CooldownNoticeCheck); return end

	cdNoticeDone = true
	if S.db.cdNotice == false then return end
	if S.ReadyCooldownCount() == 0 then return end        -- nothing ready: say nothing
	if type(S.db.cdNoticeAt) ~= "table" then S.db.cdNoticeAt = {} end
	local key = S.CharKey()
	local last = S.db.cdNoticeAt[key]
	if last and time() - last < CD_REPEAT_GAP and time() >= last then return end
	S.db.cdNoticeAt[key] = time()
	S.RedNotice(S.CooldownNoticeText())
end

S.On("PLAYER_LOGIN", function()
	cdLoginAt = GetTime()
	cdNoticeDone = false
	S.After(CD_NOTICE_WAIT, CooldownNoticeCheck)
end)

-- true when nothing is going on that a message would get in the way of
function S.CalmNow()
	if UnitAffectingCombat and UnitAffectingCombat("player") then return false end
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return false end
	return true
end

end)
