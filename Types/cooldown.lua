﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, CUR_TIME, UPD_INTV, ClockGCD, rc, mc
local ipairs =
	  ipairs
local GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellTexture =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellTexture
local GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon =
	  GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local OnGCD = TMW.OnGCD
local _, pclass = UnitClass("Player")

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	CooldownShowWhen = true,
	CooldownType = true,
	RangeCheck = true,
	ManaCheck = true,
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	IgnoreRunes = (pclass == "DEATHKNIGHT"),
	OnlyEquipped = true,
	OnlyInBags = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("cooldown", RelevantSettings)
Type.name = L["ICONMENU_COOLDOWN"]

Type:SetScript("OnUpdate", function()
	CUR_TIME = TMW.CUR_TIME
end)

function Type:Update()
	CUR_TIME = TMW.CUR_TIME
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end



local function SpellCooldown_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local n, inrange, nomana, start, duration, isGCD = 1
		local IgnoreRunes, RangeCheck, ManaCheck, NameNameArray = icon.IgnoreRunes, icon.RangeCheck, icon.ManaCheck, icon.NameNameArray
		for i, iName in ipairs(icon.NameArray) do
			n = i
			start, duration = GetSpellCooldown(iName)
			if duration then
				if IgnoreRunes then
					if start == GetSpellCooldown(45477) or start == GetSpellCooldown(45462) or start == GetSpellCooldown(45902) then
						start, duration = 0, 0
					end
				end
				inrange, nomana = 1
				if RangeCheck then
					inrange = IsSpellInRange(NameNameArray[i], "target") or 1
				end
				if ManaCheck then
					_, nomana = IsUsableSpell(iName)
				end
				isGCD = OnGCD(duration)
				if inrange == 1 and not nomana and (duration == 0 or isGCD) then --usable
					local Alpha = icon.Alpha
					if Alpha == 0 then
						icon:SetAlpha(0)
						return
					end

					local t = GetSpellTexture(iName)
					if t then
						icon:SetTexture(t)
					end

					icon:SetVertexColor(1)
					icon:SetAlpha(Alpha)

					if not icon.ShowTimer or (ClockGCD and isGCD) then
						icon:SetCooldown(0, 0)
					else
						icon:SetCooldown(start, duration)
					end

					if icon.ShowCBar then
						icon:CDBarStart(start, duration)
					end
					if icon.ShowPBar then
						icon:PwrBarStart(iName)
					end
					return
				end
			end
		end
		local UnAlpha = icon.UnAlpha
		if UnAlpha == 0 then
			icon:SetAlpha(0)
			return
		end
		
		local NameFirst = icon.NameFirst
		if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
			start, duration = GetSpellCooldown(NameFirst)
			inrange, nomana = 1
			if RangeCheck then
				inrange = IsSpellInRange(icon.NameName, "target") or 1
			end
			if ManaCheck then
				_, nomana = IsUsableSpell(NameFirst)
			end
			if IgnoreRunes then
				if start == GetSpellCooldown(45477) or start == GetSpellCooldown(45462) or start == GetSpellCooldown(45902) then
					start, duration = 0, 0
				end
			end
			isGCD = OnGCD(duration)
		end
		if duration then
			local d = duration - (CUR_TIME - start)
			if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
				icon:SetAlpha(0)
				return
			end

			if icon.Alpha ~= 0 then
				if inrange ~= 1 then
					icon:SetVertexColor(rc)
					icon:SetAlpha(UnAlpha*rc.a)
				elseif nomana then
					icon:SetVertexColor(mc)
					icon:SetAlpha(UnAlpha*mc.a)
				elseif not icon.ShowTimer then
					icon:SetVertexColor(0.5)
					icon:SetAlpha(UnAlpha)
				else
					icon:SetVertexColor(1)
					icon:SetAlpha(UnAlpha)
				end
			else
				icon:SetVertexColor(1)
				icon:SetAlpha(UnAlpha)
			end

			icon:SetTexture(icon.FirstTexture)

			if not icon.ShowTimer or (ClockGCD and isGCD) then
				icon:SetCooldown(0, 0)
			else
				icon:SetCooldown(start, duration)
			end

			if icon.ShowCBar then
				icon:CDBarStart(start, duration)
			end
			if icon.ShowPBar then
				icon:PwrBarStart(NameFirst)
			end
		else
			icon:Hide()
		end
	end
end


local function ItemCooldown_OnEvent(icon)
	-- the reason for doing it like this is because this event will fire several times at once sometimes,
	-- but there is no reason to recheck things until they are needed next.
	icon.DoUpdateIDs = true
end

local function ItemCooldown_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		if icon.DoUpdateIDs then
			local Name = icon.Name
			icon.NameFirst = TMW:GetItemIDs(icon, Name, 1)
			icon.NameArray = TMW:GetItemIDs(icon, Name)
			icon.DoUpdateIDs = nil
		end

		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local n, inrange, equipped, start, duration, isGCD = 1
		local RangeCheck, OnlyEquipped, OnlyInBags = icon.RangeCheck, icon.OnlyEquipped, icon.OnlyInBags
		for i, iName in ipairs(icon.NameArray) do
			n = i
			start, duration = GetItemCooldown(iName)
			if duration then
				inrange, equipped = 1, true
				if RangeCheck then
					inrange = IsItemInRange(iName, "target") or 1
				end
				if OnlyEquipped and not IsEquippedItem(iName) then
					equipped = false
				end
				if equipped and OnlyInBags and (GetItemCount(iName) == 0) then
					equipped = false
				end
				isGCD = OnGCD(duration)
				if equipped and inrange == 1 and (duration == 0 or isGCD) then --usable
					local Alpha = icon.Alpha
					if Alpha == 0 then
						icon:SetAlpha(0)
						return
					end

					icon:SetTexture(GetItemIcon(iName) or "Interface\\Icons\\INV_Misc_QuestionMark")

					icon:SetVertexColor(1)
					icon:SetAlpha(Alpha)

					if not icon.ShowTimer or (ClockGCD and isGCD) then
						icon:SetCooldown(0, 0)
					else
						icon:SetCooldown(start, duration)
					end

					if icon.ShowCBar then
						icon:CDBarStart(start, duration)
					end
					return
				end
			end
		end
		
		local UnAlpha = icon.UnAlpha
		if UnAlpha == 0 then
			icon:SetAlpha(0)
			return
		end
		
		local NameFirst2
		if OnlyInBags then
			for i, iName in ipairs(icon.NameArray) do
				if OnlyEquipped then
					if IsEquippedItem(iName) then
						NameFirst2 = iName
						break
					end
				elseif GetItemCount(iName) > 0 then
					NameFirst2 = iName
					break
				end				
			end
			if not NameFirst2 then
				icon:SetAlpha(0)
				return
			end
		else
			NameFirst2 = icon.NameFirst
		end
		if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
			start, duration = GetItemCooldown(NameFirst2)
			inrange = 1
			if RangeCheck then
				inrange = IsItemInRange(NameFirst2, "target") or 1
			end
			isGCD = OnGCD(duration)
		end
		if duration then

			local d = duration - (CUR_TIME - start)
			if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
				icon:SetAlpha(0)
				return
			end

			local ShowTimer = icon.ShowTimer
			if icon.Alpha ~= 0 then
				if inrange ~= 1 then
					icon:SetVertexColor(rc)
					icon:SetAlpha(UnAlpha*rc.a)
				elseif not ShowTimer then
					icon:SetVertexColor(0.5)
					icon:SetAlpha(UnAlpha)
				else
					icon:SetVertexColor(1)
					icon:SetAlpha(UnAlpha)
				end
			else
				icon:SetVertexColor(1)
				icon:SetAlpha(UnAlpha)
			end

			local t = GetItemIcon(NameFirst2)
			if t then
				icon:SetTexture(t)
			end

			if not ShowTimer or (ClockGCD and isGCD) then
				icon:SetCooldown(0, 0)
			else
				icon:SetCooldown(start, duration)
			end

			if icon.ShowCBar then
				icon:CDBarStart(start, duration)
			end
		end
	end
end


local function MultiStateCD_OnEvent(icon)
	local actionType, spellID = GetActionInfo(icon.Slot) -- check the current slot first, because it probably didnt change
		if actionType == "spell" and spellID == icon.NameFirst then
		return
	end
	for i=1, 120 do
		local actionType, spellID = GetActionInfo(i)
		if actionType == "spell" and spellID == icon.NameFirst then
			icon.Slot = i
			return
		end
	end

end

local function MultiStateCD_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		local Slot = icon.Slot
		local start, duration = GetActionCooldown(Slot)
		if duration then

			local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
			local d = duration - (CUR_TIME - start)
			if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
				icon:SetAlpha(0)
				return
			end

			if (not icon.ShowTimer) or (ClockGCD and OnGCD(duration)) then
				icon:SetCooldown(0, 0)
			else
				icon:SetCooldown(start, duration)
			end
			if icon.ShowCBar then
				icon:CDBarStart(start, duration)
			end
			icon:SetTexture(GetActionTexture(Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

			local inrange = IsActionInRange(Slot, "target")
			local _, nomana = IsUsableAction(Slot)
			if not icon.RangeCheck or not inrange then
				inrange = 1
			end
			if not icon.ManaCheck then
				nomana = nil
			end
			if (duration == 0 or OnGCD(duration)) and inrange == 1 and not nomana then
				icon:SetVertexColor(1)
				icon:SetAlpha(icon.Alpha)
			elseif icon.Alpha ~= 0 then
				if inrange ~= 1 then
					icon:SetVertexColor(rc)
					icon:SetAlpha(icon.UnAlpha*rc.a)
				elseif nomana then
					icon:SetVertexColor(mc)
					icon:SetAlpha(icon.UnAlpha*mc.a)
				elseif not icon.ShowTimer then
					icon:SetVertexColor(0.5)
					icon:SetAlpha(icon.UnAlpha)
				else
					icon:SetVertexColor(1)
					icon:SetAlpha(icon.UnAlpha)
				end
			else
				icon:SetVertexColor(1)
				icon:SetAlpha(icon.UnAlpha)
			end
		end
	end
end



function Type:Setup(icon, groupID, iconID)
	if icon.CooldownType == "spell" then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
		icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
		icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
		icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)

		icon.FirstTexture = GetSpellTexture(icon.NameFirst)

		if icon.Name == "" then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		elseif icon.FirstTexture then
			icon:SetTexture(icon.FirstTexture)
		elseif TMW:DoSetTexture(icon) then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
		icon:SetScript("OnUpdate", SpellCooldown_OnUpdate)
		icon:OnUpdate()
	end
	if icon.CooldownType == "item" then
		icon.NameFirst = TMW:GetItemIDs(icon, icon.Name, 1)
		icon.NameArray = TMW:GetItemIDs(icon, icon.Name)

		for _, n in ipairs(TMW:SplitNames(icon.Name)) do
			n = tonumber(strtrim(n))
			if n and n <= 19 then
				icon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
				icon:SetScript("OnEvent", ItemCooldown_OnEvent)
				break
			end
		end

		icon.ShowPBar = nil
		if icon.OnlyEquipped then
			icon.OnlyInBags = true
		end

		local itemTexture = GetItemIcon(icon.NameFirst)
		if itemTexture then
			icon:SetTexture(itemTexture)
		else
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end

		icon:SetScript("OnUpdate", ItemCooldown_OnUpdate)
		icon:OnUpdate()
	end
	if icon.CooldownType == "multistate" then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)

		if icon.NameFirst and icon.NameFirst ~= "" and GetSpellLink(icon.NameFirst) and not tonumber(icon.NameFirst) then
			icon.NameFirst = tonumber(strmatch(GetSpellLink(icon.NameFirst), ":(%d+)")) -- extract the spellID from the link
		end
		icon.Slot = 0
		for i=1, 120 do
			local actionType, spellID = GetActionInfo(i)
			if actionType == "spell" and spellID == icon.NameFirst then
				icon.Slot = i
				break
			end
		end
		if icon.ShowPBar then
			icon:PwrBarStart(icon.NameFirst)
		end

		icon:SetTexture(GetActionTexture(icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

		icon:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
		icon:SetScript("OnEvent", MultiStateCD_OnEvent)

		icon:SetScript("OnUpdate", MultiStateCD_OnUpdate)
		icon:OnUpdate()
	end
end



