local player = nil
local modData = nil

-- v2 : Fired every minute, if you've reached 95% infection, rolls wether you should get cured for each of your infected members
local function CheckAndReduceInfection()
	local random_instance = newrandom()
	local randomNumber = random_instance:random(100)
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
			print("Triggered")
			if (randomNumber <= SandboxVars.PZinfectionCancellation.SurvivalChance) then
				bodyDamage:setInfected(false)
				bodyDamage:setInfectionTime(-1)
				bodyDamage:setInfectionMortalityDuration(-1)
				getPlayer():getModData().ICdata.shouldHeal = true
				print("CURED !")
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
