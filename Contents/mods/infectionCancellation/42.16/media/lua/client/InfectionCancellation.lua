local player = nil
local modData = nil

-- Returns a float between 0 and 1, based on precision
local function GetRandomFloat() -- NEVER returns 0 to prevent crashes
	local precision = 1000000 -- decimal precision
	return (ZombRand(precision) + 1) / precision
end


-- could have secondary effects
local function CalcInfectionGrowthRate()
	local traitMultiplier = 1
	if (player:getTraits():contains("Resilient")) then
		traitMultiplier = 1.25
	elseif (player:getTraits():contains("ProneToIllness")) then
		traitMultiplier = 0.75
	end

	local mortality = SandboxVars.ZombieLore.Mortality
	local newInfectionGrowthRate = -1
	local hourConstant = 1/72

	-- based on decompiled Java function pickMortalityDuration()
	if (mortality == 1) then -- instantaneous
		newInfectionGrowthRate = 0
	elseif (mortality == 2) then -- 0s - 30s
		newInfectionGrowthRate = hourConstant / GetRandomFloat() * 30 / 3600 * traitMultiplier
	elseif (mortality == 3) then -- 30s - 1min
		newInfectionGrowthRate = hourConstant / (GetRandomFloat() / 2 + 0.5) / 60 * traitMultiplier
	elseif (mortality == 4) then -- 3h - 12h
		newInfectionGrowthRate = hourConstant / (GetRandomFloat() * 9 + 3) * traitMultiplier
	elseif (mortality == 5) then -- 2d - 3d
		newInfectionGrowthRate = hourConstant / (GetRandomFloat() + 2) * 24 * traitMultiplier
	elseif (mortality == 6) then -- 1week - 2weeks
		newInfectionGrowthRate = hourConstant / (GetRandomFloat() + 1) * 7 * 24 * traitMultiplier
	end

	return newInfectionGrowthRate
end


-- Entierly removes infection
local function RemoveInfection()
	local bodyDamage = player:getBodyDamage()
	
	local bodyParts = bodyDamage:getBodyParts()
	for i=0, bodyParts:size()-1 do
		local bodyPart = bodyParts:get(i)
		bodyPart:SetInfected(false)
	end

	bodyDamage:setInfected(false)
	bodyDamage:setInfectionTime(-1)
	bodyDamage:setInfectionLevel(0)
	bodyDamage:setInfectionMortalityDuration(-1)
end


-- Triggers a fakeInfection after calculating the growthRate
local function TriggerFakeInfection()
	local bodyDamage = player:getBodyDamage()
	
	bodyDamage:setInfectionGrowthRate(CalcInfectionGrowthRate())
	bodyDamage:setIsFakeInfected(true)
end


-- Debug print
local function PrintInfectionInfo()
	local bodyDamage = player:getBodyDamage()
	print()
	print(player:getDisplayName())
	print("isInfected : " .. tostring(bodyDamage:IsInfected()))
	print("infectionTime : " .. bodyDamage:getInfectionTime())
	print("infectionLevel : " .. bodyDamage:getInfectionLevel())
	print("infectionMortalityDuration : " .. bodyDamage:getInfectionMortalityDuration())
	print("reduceInfectionPower : " .. player:getReduceInfectionPower())
	print("canHeal: " .. tostring(modData.ICdata.canHeal))
	-- print("shouldHeal: " .. tostring(modData.ICdata.shouldHeal))
	-- print("fastHealerBonus: " .. tostring(SandboxVars.PZinfectionCancellation.FastHealer))
	-- print("isFakeInfected : " .. tostring(bodyDamage:IsFakeInfected()))
	-- print("fakeInfectionLevel : " .. bodyDamage:getFakeInfectionLevel())
	-- print("infectionGrowthRate : " .. bodyDamage:getInfectionGrowthRate())
	-- print("wasInfected : " .. tostring(playerModData.ICdata.wasInfected))
	-- print("apparentInfectionLevel : " .. bodyDamage:getApparentInfectionLevel()) -- max de infectLevel et fakeInfectLevel ?
end


-- Debug keys to test
local function DebugKeyParser(key)
	-- print(key)
	player = getPlayer()
	if (player == nil) then return end
	local bodyDamage = player:getBodyDamage()

	if (key == 156) then -- kp_enter
		PrintInfectionInfo()
	end

	if (key == 78) then -- kp_plus
		bodyDamage:setInfected(true)
		print("infected!")
	end

	if (key == 74) then -- kp_minus
		RemoveInfection()
		print("healed")
	end

	if (key == 55) then -- kp_star
		print("mortality : " .. SandboxVars.ZombieLore.Mortality)
	end

	if (key == 181) then -- kp_slash
		--TriggerFakeInfection()
		--print("fakeInfected")
		-- player:getInventory():AddItem("infectionCancellation.CuredBall") -Removed to maybe fix Crafting errors
	end

	if (key == 83) then -- kp_del
		--print(not nil)
	end
end


-- v1 : right after you get infected, cancels and removes infection, then triggers a fake one
local function CheckAndCancelInfection()
	local bodyDamage = player:getBodyDamage()

	if (bodyDamage:IsInfected()) then
		if (not modData.ICdata.wasInfected and modData.ICdata.wasInfected ~= nil) then
			if (ZombRand(100) + 1 <= SandboxVars.PZinfectionCancellation.SurvivalChance) then
				RemoveInfection()
				TriggerFakeInfection()
				print("Infection avoided !")
			else
				modData.ICdata.wasInfected = true
				print("Prepare the bleach.")
			end
		end
	else
		modData.ICdata.wasInfected = false
	end
end


-- v2 : Fired every minute, if you've reached 95% infection, rolls wether you should get cured for each of your infected members
local function CheckAndReduceInfection()
	player = getPlayer()
	modData = getPlayer():getModData()
	local infectionProcent = 95 -- Sets the 95% default Rate to check if you get healed
	if(SandboxVars.PZinfectionCancellation.FastHealer) then
		if (getPlayer():getTraits():contains("FastHealer")) then
			infectionProcent = 45 -- Fast Healer is around twice as fast.
		end
	end
	--print(infectionProcent) Debug
	local bodyDamage = getPlayer():getBodyDamage()
	if (bodyDamage:isInfected()) then
		if (getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) > infectionProcent and getPlayer():getModData().ICdata.canHeal) then -- TODO remettre > 95
			local allCured = true

			local bodyParts = bodyDamage:getBodyParts()
			--for i=0, bodyParts:getSize()-1 do
			for i = 0, bodyParts:size() - 1 do
				local bodyPart = bodyParts:get(i)
				if(bodyPart:IsInfected()) then
					print(tostring(bodyPart:getType()) .. " is infected")
					if (ZombRand(100) + 1 <= SandboxVars.PZinfectionCancellation.SurvivalChance) then
						bodyPart:SetInfected(false)
					else
						allCured = false
						break
					end
				end
			end
			
			if (allCured) then
				bodyDamage:setInfected(false)
				bodyDamage:setInfectionTime(-1)
				bodyDamage:setInfectionMortalityDuration(-1)
				getPlayer():getModData().ICdata.shouldHeal = true
				print("ALL CURED !")
				-- player:getInventory():AddItem("infectionCancellation.CuredBall") -Removed to maybe fix Crafting errors
			else
				getPlayer():getModData().ICdata.shouldHeal = false
				print("NOT ALL CURED")
			end

			getPlayer():getModData().ICdata.canHeal = false
		end
	else
		getPlayer():getModData().ICdata.canHeal = true
		if (getPlayer():getModData().ICdata.shouldHeal) then
			getPlayer():getStats():set(CharacterStat.ZOMBIE_INFECTION,getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) - 0.05)
			--bodyDamage:setInfectionLevel(getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) - 0.05)
			--print(bodyDamage:getInfectionLevel())
			if ( getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) <= 0) then
				bodyDamage:setInfectionLevel(0)
				getPlayer():getModData().ICdata.shouldHeal = false
			end
		end
	end
end


-- Fires when you enter a game or you create a new character. Loads player modData
local function LoadPlayerData()
	player = getPlayer()
	modData = player:getModData()
	modData.ICdata = modData.ICdata or {}
	modData.ICdata.canHeal = modData.ICdata.canHeal or true
	modData.ICdata.shouldHeal = modData.ICdata.shouldHeal or false
end


-- Fired whenever you enter a game
local function GameInit()
	LoadPlayerData()
	Events.EveryOneMinute.Add(CheckAndReduceInfection)
	Events.OnCreatePlayer.Add(LoadPlayerData)
end


Events.OnGameStart.Add(GameInit)
--Events.OnKeyPressed.Add(DebugKeyParser)
