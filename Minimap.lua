-------------------------------------------------------------------------------
-- SHAlts minimap button. Left-click opens the window, right-click and drag
-- moves it around the minimap. The logo does its quick spin on the same beat
-- as the window portrait, but the ring stays still here.
-------------------------------------------------------------------------------
local S = SHAlts

S.Try("Minimap.lua", function()

local button = CreateFrame("Button", "SHAltsMinimapButton", Minimap)
button:SetWidth(31); button:SetHeight(31)   -- the usual size, so button bars treat it like the rest
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- the portrait has its own ring, so no minimap border; a little smaller than
-- the button so its ring matches the gold ring on other buttons
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetWidth(28); icon:SetHeight(28)
icon:SetPoint("CENTER", button, "CENTER", 0, 0)
icon:SetTexture(S.MEDIA .. "Portrait")
S.AddSpin(icon, button, "logo")

-- the ring is not registered for spinning. Angle 0 keeps the same zoom as
-- the logo so the two line up.
local ring = button:CreateTexture(nil, "OVERLAY")
ring:SetAllPoints(icon)
ring:SetTexture(S.MEDIA .. "PortraitRing")
S.SetSpinAngle(ring, 0)

function S.UpdateMinimapButton()
	local db = S.db or {}
	local angle = math.rad(db.minimapPos or 225)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
	if db.minimapHidden then button:Hide() else button:Show() end
end

button:RegisterForClicks("LeftButtonUp")
button:SetScript("OnClick", function() S.UI.Toggle() end)

button:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this, "ANCHOR_LEFT")
	GameTooltip:SetText("SHAlts")
	if S.db then
		local total, n = S.TotalGold()
		GameTooltip:AddLine(n .. " characters, " .. S.FormatMoney(total), 1, 1, 1)
		local ready = S.ReadyList()
		if table.getn(ready) > 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Cooldowns ready:", 1, .82, 0)
			for i = 1, table.getn(ready) do GameTooltip:AddLine(ready[i], 1, 1, 1) end
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Click to open", .6, .6, .6)
	GameTooltip:AddLine("Right-click and drag to move", .6, .6, .6)
	GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

button:RegisterForDrag("RightButton")
button:SetScript("OnDragStart", function()
	this:SetScript("OnUpdate", function()
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		S.db.minimapPos = math.deg(math.atan2(py - my, px - mx))
		S.UpdateMinimapButton()
	end)
end)
button:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)

S.On("PLAYER_LOGIN", function() S.UpdateMinimapButton() end)

end)
