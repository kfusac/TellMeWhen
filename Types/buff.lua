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

local db, CUR_TIME, UPD_INTV, EFF_THR, ClockGCD, rc, mc, pr, ab
local ipairs, tonumber, strlower =
	  ipairs, tonumber, strlower
local UnitAura, UnitExists =
	  UnitAura, UnitExists
local DS = TMW.DS

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	BuffOrDebuff = true,
	BuffShowWhen = true,
	OnlyMine = true,
	Unit = true,
	StackAlpha = true,
	StackMin = true,
	StackMax = true,
	StackMinEnabled = true,
	StackMaxEnabled = true,
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
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("buff", RelevantSettings)
Type.name = L["ICONMENU_BUFFDEBUFF"]

Type:SetScript("OnUpdate", function()
	CUR_TIME = TMW.CUR_TIME
end)

function Type:Update()
	CUR_TIME = TMW.CUR_TIME
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	EFF_THR = db.profile.EffThreshold
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end


local function Buff_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local NameArray, NameNameArray, NameDictionary, Filter, Filterh = icon.NameArray, icon.NameNameArray, icon.NameDictionary, icon.Filter, icon.Filterh

		for _, unit in ipairs(icon.Units) do
			if UnitExists(unit) then
				local buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id
				if #NameArray > EFF_THR then
					for z=1, 60 do --60 because i can and it breaks when there are no more buffs anyway
						buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filter)
						if not buffName
						or NameDictionary[id]
						or NameDictionary[strlower(buffName)]
						or NameDictionary[dispelType] then
							break
						end
					end
					if Filterh and not buffName then
						for z=1, 60 do
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filterh)
							if not buffName
							or NameDictionary[id]
							or NameDictionary[strlower(buffName)]
							or NameDictionary[dispelType] then
								break
							end
						end
					end
				else
					for i, iName in ipairs(NameArray) do
						if DS[iName] then --Enrage wont be handled here because it will always have more auras than the efficiency threshold (max 40, there are about 120 enrages i think)
							for z=1, 60 do
								buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filter)
								if not buffName or dispelType == iName then
									break
								end
							end
							if Filterh and not buffName then
								for z=1, 60 do
									buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filterh)
									if not buffName or dispelType == iName then
										break
									end
								end
							end
						else
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, NameNameArray[i], nil, Filter)
						end
						if Filterh and not buffName then
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, NameNameArray[i], nil, Filterh)
						end
						if buffName and id ~= iName and tonumber(iName) then
							for z=1, 60 do
								buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filter)
								if not id or id == iName then
									break
								end
							end
							if Filterh and not id then
								for z=1, 60 do
									buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filterh)
									if not id or id == iName then
										break
									end
								end
							end
						end
						if buffName then
							break
						end
					end
				end
				if buffName then
					local Alpha = icon.Alpha
					if Alpha == 0 then
						icon:SetAlpha(0)
						return
					end
					if (icon.StackMinEnabled and icon.StackMin > count) or (icon.StackMaxEnabled and count > icon.StackMax) then
						icon:SetAlpha(0)
						return
					end

					local d = expirationTime - CUR_TIME
					if expirationTime ~= 0 and ((icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax)) then
						icon:SetAlpha(0)
						return
					end

					icon:SetStack(count)
					icon:SetTexture(iconTexture)
					icon:SetAlpha(Alpha)
					if icon.UnAlpha ~= 0 then -- Alpha ~= 0 and  (not needed because it wou ld have returned earlier)
						icon:SetVertexColor(pr)
					else
						icon:SetVertexColor(1)
					end
					
					local start = expirationTime - duration
					if icon.ShowTimer then
						icon:SetCooldown(start, duration)
					end
					if icon.ShowCBar then
						icon:CDBarStart(start, duration, true)
					end
					if icon.ShowPBar then
						icon:PwrBarStart(buffName)
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
		if icon.ShowPBar then
			icon:PwrBarStart(icon.NameFirst)
		end
		if icon.ShowCBar then
			icon:CDBarStop()
		end

		icon:SetAlpha(UnAlpha)
		if icon.Alpha ~= 0 then -- and UnAlpha ~= 0  (not needed, it has to not be 0 or it would have returned earlier)
			icon:SetVertexColor(ab)
		else
			icon:SetVertexColor(1)
		end

		if icon.FirstTexture then
			icon:SetTexture(icon.FirstTexture)
		end
		if icon.ShowTimer then
			icon:SetCooldown(0, 0)
		end
		icon:SetStack(nil)

	end
end



function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)

	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = ((icon.BuffOrDebuff == "EITHER") and "HARMFUL")
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end
	icon:SetReverse(true)

	icon.FirstTexture = GetSpellTexture(icon.NameFirst)
	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnUpdate", Buff_OnUpdate)
	icon:OnUpdate()
end


