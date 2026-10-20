local player = nil
local modData = nil

-- MULTIPLAYER 

local function CheckAndReduceInfectionServer()
	local infectionProcent = 80

	local random_instance = newrandom()
	local randomNumber = random_instance:random(100)
	-- i mean its uncommon that 2 persons gets infected the same minute(ingame), so one time random per minute
	-- is enough, no need for new random for each player.

	local players = getOnlinePlayers()
	for i=0,  players:size() -1 do
		local currPlayer = players:get(i)
		local bodyDamage = currPlayer:getBodyDamage()
		local currmodData = currPlayer:getModData()
		currmodData.ICdata = currmodData.ICdata or {}
		if currmodData.ICdata.canHeal == nil then
			currmodData.ICdata.canHeal = true
		end
		if currmodData.ICdata.shouldHeal == nil then
			currmodData.ICdata.shouldHeal = false
		end
		if (currPlayer:getStats():get(CharacterStat.ZOMBIE_INFECTION) > 0) then
			-- When Infected		
			if (currPlayer:getStats():get(CharacterStat.ZOMBIE_INFECTION) > infectionProcent and currPlayer:getModData().ICdata.canHeal) then
				-- Wenn Infected and Reached infectionprocent
				local args = {}
				if (randomNumber <= SandboxVars.PZinfectionCancellation.SurvivalChance) then
					args.infected = false
					local bodyParts = bodyDamage:getBodyParts()
					for i=0,  bodyParts:size() -1 do
						local bodyPart = bodyParts:get(i)
						bodyPart:SetInfected(false)
					end
					bodyDamage:setInfected(false)
					bodyDamage:setInfectionTime(-1)
					bodyDamage:setInfectionMortalityDuration(-1)
					currPlayer:getModData().ICdata.shouldHeal = true
					print("CURED !".." Chance:".. SandboxVars.PZinfectionCancellation.SurvivalChance .. "% | Rolled:"..randomNumber.."/100")
				else
					args.infected = true
					currPlayer:getModData().ICdata.shouldHeal = false
					print("NOT CURED!".." Chance:".. SandboxVars.PZinfectionCancellation.SurvivalChance .. "% | Rolled:"..randomNumber.."/100")
				end
				currPlayer:getModData().ICdata.canHeal = false
				sendServerCommand(currPlayer, "InfectionServer", "Check", args)
			end
			
			-- Reduce
			
			if (currPlayer:getModData().ICdata.shouldHeal) then
				-- When he should be healed.
				currPlayer:getStats():set(CharacterStat.ZOMBIE_INFECTION,currPlayer:getStats():get(CharacterStat.ZOMBIE_INFECTION) - 0.05)
				local args = {}
				args.done = false
				args.infection = currPlayer:getStats():get(CharacterStat.ZOMBIE_INFECTION)
				if ( currPlayer:getStats():get(CharacterStat.ZOMBIE_INFECTION) <= 0.05) then
					-- When infection is very small remove it.
					currPlayer:getStats():set(CharacterStat.ZOMBIE_INFECTION,0)
					currPlayer:getModData().ICdata.shouldHeal = false
					currPlayer:getModData().ICdata.canHeal = true
					args.done = true
				end
				sendServerCommand(currPlayer, "InfectionServer", "Reduce", args)
			end
		end
	end
end

local function onServerCommand(module, command, args)
    if module == "InfectionServer" then
		local user = getPlayer()
        if command == "Check" then
			if args.infected then
				return
			end
			local bodyDamage = user:getBodyDamage()
			local bodyParts = bodyDamage:getBodyParts()
			for i=0,  bodyParts:size() -1 do
				local bodyPart = bodyParts:get(i)
				bodyPart:SetInfected(false)
			end
			bodyDamage:setInfected(false)
			bodyDamage:setInfectionTime(-1)
			bodyDamage:setInfectionMortalityDuration(-1)
        end
		if command == "Reduce" then
			if args.done then
				user:getStats():set(CharacterStat.ZOMBIE_INFECTION,0)
				return
			end
			user:getStats():set(CharacterStat.ZOMBIE_INFECTION,args.infection)
        end
    end
end

-- MULTIPLAYER END
-- SINGLEPLAYER

-- v3 : Fired every minute, if you've reached 80% infection, rolls wether you should get cured and at the end heals you
local function CheckAndReduceInfection()
	local infectionProcent = 80
	local bodyDamage = getPlayer():getBodyDamage()
	
	player = getPlayer()
	modData = getPlayer():getModData()
	
	-- Check	
	if (getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) > 0) then
		
		-- When Infected
		if (getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) > infectionProcent and getPlayer():getModData().ICdata.canHeal) then
			-- Wenn Infected and Reached infectionprocent
			local random_instance = newrandom()-- singleplayer need only random when the player need it
			local randomNumber = random_instance:random(100)
			if (randomNumber <= SandboxVars.PZinfectionCancellation.SurvivalChance) then
				local bodyParts = bodyDamage:getBodyParts()
				for i=0,  bodyParts:size() -1 do
					local bodyPart = bodyParts:get(i)
					bodyPart:SetInfected(false)
				end
				bodyDamage:setInfected(false)
				bodyDamage:setInfectionTime(-1)
				bodyDamage:setInfectionMortalityDuration(-1)

				getPlayer():getModData().ICdata.shouldHeal = true
				print("CURED !".." Chance:".. SandboxVars.PZinfectionCancellation.SurvivalChance .. "% | Rolled:"..randomNumber.."/100")
			else
				getPlayer():getModData().ICdata.shouldHeal = false
				print("NOT CURED!".." Chance:".. SandboxVars.PZinfectionCancellation.SurvivalChance .. "% | Rolled:"..randomNumber.."/100")
			end
			
			getPlayer():getModData().ICdata.canHeal = false
		end
	end
	
	-- Reduce
	
	if (getPlayer():getModData().ICdata.shouldHeal) then
		-- When he should be healed.
		getPlayer():getStats():set(CharacterStat.ZOMBIE_INFECTION,getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) - 0.05)
		if ( getPlayer():getStats():get(CharacterStat.ZOMBIE_INFECTION) <= 0.05) then
			-- When infection is very small remove it.
			getPlayer():getStats():set(CharacterStat.ZOMBIE_INFECTION,0)
			getPlayer():getModData().ICdata.shouldHeal = false
			getPlayer():getModData().ICdata.canHeal = true
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

-- SINGLEPLAYER END

local function isSinglePlayer()
    return not isClient() and not isServer()
end

local function GameInit()
	if isSinglePlayer() then
		LoadPlayerData()
		Events.OnCreatePlayer.Add(LoadPlayerData)
		Events.EveryOneMinute.Add(CheckAndReduceInfection)
	else
		if isServer() then
			Events.EveryOneMinute.Add(CheckAndReduceInfectionServer)
		else
			Events.OnServerCommand.Add(onServerCommand)
		end
	end
end

Events.OnServerStarted.Add(GameInit)
Events.OnGameStart.Add(GameInit)			