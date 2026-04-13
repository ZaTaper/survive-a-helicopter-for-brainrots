-- BrainrotSystem.server.lua
-- Server-side brainrot spawning, AI, damage, and management system
-- Handles wave spawning, chasing, attacking, loot drops, and cleanup

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotModel = require(ServerStorage:WaitForChild("Storage"):WaitForChild("BrainrotModel"))
local SpawnManager = require(script.Parent:WaitForChild("SpawnManager"))

-- Optional: Load BrainrotCollector for collection system
local BrainrotCollector = nil
local function LoadBrainrotCollector()
	if not BrainrotCollector then
		local success, collector = pcall(function()
			return require(script.Parent:WaitForChild("BrainrotCollector"))
		end)
		if success then
			BrainrotCollector = collector
		end
	end
	return BrainrotCollector
end

local BrainrotSystem = {}

-- Active brainrots indexed by their unique ID
local activeBrainrots = {}

-- Counter for unique brainrot IDs
local brainrotIdCounter = 0

-- RemoteEvents for client notifications
local brainrotSpawnEvent = Instance.new("RemoteEvent")
brainrotSpawnEvent.Name = "BrainrotSpawned"
brainrotSpawnEvent.Parent = game:GetService("ReplicatedStorage")

local brainrotDespawnEvent = Instance.new("RemoteEvent")
brainrotDespawnEvent.Name = "BrainrotDespawned"
brainrotDespawnEvent.Parent = game:GetService("ReplicatedStorage")

local brainrotDamagedEvent = Instance.new("RemoteEvent")
brainrotDamagedEvent.Name = "BrainrotDamaged"
brainrotDamagedEvent.Parent = game:GetService("ReplicatedStorage")

-- Settings
local CHASE_UPDATE_INTERVAL = 0.1 -- Update AI direction every 0.1 seconds
local ATTACK_RANGE = 5 -- Range for melee attacks
local ATTACK_COOLDOWN = 1.5 -- Seconds between attacks per brainrot
local DAMAGE_RANGE = 10 -- Range at which brainrot can deal damage
local LOOT_DROP_CHANCE = 0.7 -- 70% chance to drop loot on death
local CLEANUP_CHECK_INTERVAL = 5 -- Check for dead brainrots every 5 seconds

--- Initialize the brainrot system
function BrainrotSystem.Initialize()
	print("[BrainrotSystem] Initializing...")
	SpawnManager.InitializeSpawnPoints()

	-- Start the chase/AI loop
	task.spawn(function()
		while true do
			BrainrotSystem.UpdateAllBrainrotAI()
			task.wait(CHASE_UPDATE_INTERVAL)
		end
	end)

	-- Start the cleanup loop
	task.spawn(function()
		while true do
			task.wait(CLEANUP_CHECK_INTERVAL)
			BrainrotSystem.CleanupDeadBrainrots()
		end
	end)

	print("[BrainrotSystem] Initialized and running")
end

--- Spawn a wave of brainrots based on wave number
--- @param waveNumber number - Current wave number (1-indexed)
function BrainrotSystem.SpawnWave(waveNumber)
	print("[BrainrotSystem] Spawning wave " .. waveNumber)

	-- Calculate number of brainrots to spawn
	local baseCount = GameConfig.Waves.BRAINROTS_PER_WAVE_BASE
	local increment = GameConfig.Waves.BRAINROTS_PER_WAVE_INCREMENT
	local brainrotCount = baseCount + ((waveNumber - 1) * increment)

	-- Cap at maximum
	brainrotCount = math.min(brainrotCount, GameConfig.Waves.MAX_BRAINROTS)

	-- Account for already active brainrots
	local activeCount = BrainrotSystem.GetActiveBrainrotCount()
	local canSpawn = math.max(0, GameConfig.Waves.MAX_BRAINROTS - activeCount)
	brainrotCount = math.min(brainrotCount, canSpawn)

	print("[BrainrotSystem] Spawning " .. brainrotCount .. " brainrots (wave " .. waveNumber .. ")")

	for i = 1, brainrotCount do
		task.wait(0.1) -- Small delay between spawns to prevent lag spikes

		-- Pick a random tier based on wave (higher waves = better tiers)
		local tier = BrainrotData.GetRandomTier(waveNumber)

		-- Get spawn position
		local spawnPos = SpawnManager.GetRandomSpawnPosition("brainrot")
		if not spawnPos then
			warn("[BrainrotSystem] Could not get spawn position")
			break
		end

		-- Create the brainrot
		BrainrotSystem.SpawnBrainrot(tier, spawnPos)
	end

	print("[BrainrotSystem] Wave " .. waveNumber .. " completed spawning")
end

--- Spawn a single brainrot at a position
--- @param tier table - Tier configuration from GameConfig.BrainrotTiers
--- @param spawnPos Vector3 - Position to spawn at
--- @return string - Unique ID of the spawned brainrot
function BrainrotSystem.SpawnBrainrot(tier, spawnPos)
	-- Generate unique ID
	brainrotIdCounter = brainrotIdCounter + 1
	local uniqueId = "brainrot_" .. brainrotIdCounter

	-- Create visual model
	local brainrotModel = BrainrotModel.CreateBrainrotModel(tier, spawnPos)
	brainrotModel.Name = uniqueId

	-- Create brainrot data structure
	local brainrot = BrainrotData.CreateBrainrot(tier, brainrotModel, uniqueId)

	-- Update name tag with display name
	BrainrotModel.UpdateNameTag(brainrotModel, brainrot.displayName, tier.name)

	-- Store in active brainrots
	activeBrainrots[uniqueId] = brainrot

	-- Set up damage tracking
	local humanoid = brainrotModel:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.wait(0.1) -- Small delay to ensure death is complete
			BrainrotSystem.OnBrainrotDeath(uniqueId)
		end)
	end

	-- Notify clients of spawn
	brainrotSpawnEvent:FireAllClients(uniqueId, spawnPos, tier.name, brainrot.displayName)

	return uniqueId
end

--- Update AI for all active brainrots (chasing, attacking)
function BrainrotSystem.UpdateAllBrainrotAI()
	local players = game:GetService("Players"):GetPlayers()
	if #players == 0 then
		return
	end

	for uniqueId, brainrot in pairs(activeBrainrots) do
		if brainrot.model and brainrot.model.Parent then
			BrainrotSystem.UpdateBrainrotAI(uniqueId, brainrot, players)
		end
	end
end

--- Update AI for a single brainrot
--- @param uniqueId string - Unique ID of brainrot
--- @param brainrot table - Brainrot data
--- @param players table - Array of player objects
function BrainrotSystem.UpdateBrainrotAI(uniqueId, brainrot, players)
	local model = brainrot.model
	if not model or not model.Parent then
		return
	end

	local body = model:FindFirstChild("Body")
	if not body then
		return
	end

	-- Find nearest player
	local nearestPlayer = nil
	local nearestDistance = math.huge

	for _, player in ipairs(players) do
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local distance = (body.Position - humanoidRootPart.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestPlayer = player
				end
			end
		end
	end

	-- Chase nearest player
	if nearestPlayer and nearestPlayer.Character then
		local targetPos = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetPos then
			brainrot.targetPlayer = nearestPlayer

			-- Calculate direction to target
			local direction = (targetPos.Position - body.Position).Unit

			-- Move towards target at brainrot's speed
			local bodyVelocity = body:FindFirstChildOfClass("BodyVelocity")
			if bodyVelocity then
				bodyVelocity.Velocity = direction * brainrot.speed
			end

			-- Try to attack if in range
			if nearestDistance <= ATTACK_RANGE then
				BrainrotSystem.TryAttackPlayer(uniqueId, brainrot, nearestPlayer, nearestDistance)
			end

			brainrot.lastChaseTime = tick()
		end
	else
		-- No players, stop moving
		local bodyVelocity = body:FindFirstChildOfClass("BodyVelocity")
		if bodyVelocity then
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end
		brainrot.targetPlayer = nil
	end
end

--- Try to attack a player (with cooldown check)
--- @param uniqueId string - Unique ID of brainrot
--- @param brainrot table - Brainrot data
--- @param player Instance - Player to attack
--- @param distance number - Distance to player
function BrainrotSystem.TryAttackPlayer(uniqueId, brainrot, player, distance)
	local now = tick()

	-- Check attack cooldown
	if now - brainrot.lastAttackTime < ATTACK_COOLDOWN then
		return
	end

	if distance > DAMAGE_RANGE then
		return
	end

	brainrot.lastAttackTime = now

	-- Deal damage to player
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(brainrot.damage)
		end
	end
end

--- Handle brainrot death
--- @param uniqueId string - Unique ID of brainrot that died
function BrainrotSystem.OnBrainrotDeath(uniqueId)
	local brainrot = activeBrainrots[uniqueId]
	if not brainrot or not brainrot.model or not brainrot.model.Parent then
		return
	end

	print("[BrainrotSystem] Brainrot " .. uniqueId .. " (" .. brainrot.tier .. ") died")

	local model = brainrot.model
	local position = model:FindFirstChild("Body") and model:FindFirstChild("Body").Position or Vector3.new(0, 0, 0)

	-- Award kill to player if they're close enough
	local players = game:GetService("Players"):GetPlayers()
	local killingPlayer = nil

	for _, player in ipairs(players) do
		if player.Character then
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart and (humanoidRootPart.Position - position).Magnitude < 100 then
				-- Increment kill count in player data
				local playerData = player:GetAttribute("PlayerData")
				if playerData then
					playerData.totalKills = (playerData.totalKills or 0) + 1
					player:SetAttribute("PlayerData", playerData)
				end
				killingPlayer = player
				break
			end
		end
	end

	-- Try to collect brainrot with killing player
	if killingPlayer then
		local collector = LoadBrainrotCollector()
		if collector then
			collector.TryCollect(killingPlayer, brainrot.tier, brainrot.displayName)
		end
	end

	-- Drop loot
	if math.random() < LOOT_DROP_CHANCE then
		BrainrotSystem.DropLoot(brainrot, position)
	end

	-- Notify clients
	brainrotDespawnEvent:FireAllClients(uniqueId)

	-- Clean up data
	activeBrainrots[uniqueId] = nil

	-- Destroy model
	BrainrotModel.CleanupBrainrot(model)
end

--- Drop loot from a dead brainrot
--- @param brainrot table - Brainrot data
--- @param position Vector3 - Position to drop loot at
function BrainrotSystem.DropLoot(brainrot, position)
	-- Higher tier brainrots drop better loot
	-- Common/Uncommon: Engine 70%, Fuel 30%
	-- Rare/Epic: Engine 50%, Fuel 50%
	-- Mythic+: Engine 30%, Fuel 70%

	local tierName = brainrot.tier
	local isEngine = false

	if tierName == "Common" or tierName == "Uncommon" then
		isEngine = math.random() < 0.7
	elseif tierName == "Rare" or tierName == "Epic" then
		isEngine = math.random() < 0.5
	else -- Mythic, Secret, Celestial, OP
		isEngine = math.random() < 0.3
	end

	-- Create loot item (engine or fuel canister)
	local loot = Instance.new("Part")
	loot.Name = isEngine and "Engine" or "FuelCanister"
	loot.Shape = Enum.PartType.Block
	loot.Material = Enum.Material.Neon
	loot.Color = isEngine and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(255, 200, 0)
	loot.Size = isEngine and Vector3.new(1.5, 1.5, 1.5) or Vector3.new(1, 1, 1)
	loot.CanCollide = true
	loot.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	loot.Parent = workspace

	-- Add velocity to scatter loot
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(math.random(-10, 10), math.random(5, 15), math.random(-10, 10))
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.P = 5000
	bodyVelocity.Parent = loot

	-- Add touchable surface for pickup
	loot.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and hit.Parent:IsA("Model") then
			-- Player picked up loot, queue for inventory addition
			local player = game:GetService("Players"):FindFirstChild(hit.Parent.Name)
			if player then
				task.wait(0.1)
				if loot.Parent then
					loot:Destroy()
				end
			end
		end
	end)

	-- Despawn after 30 seconds if not picked up
	task.delay(30, function()
		if loot and loot.Parent then
			loot:Destroy()
		end
	end)
end

--- Clean up dead brainrots and remove them from tracking
function BrainrotSystem.CleanupDeadBrainrots()
	for uniqueId, brainrot in pairs(activeBrainrots) do
		if not brainrot.model or not brainrot.model.Parent then
			activeBrainrots[uniqueId] = nil
		else
			local humanoid = brainrot.model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health <= 0 then
				-- Already handled by Died event, just remove from table
				activeBrainrots[uniqueId] = nil
			end
		end
	end
end

--- Get count of active brainrots
--- @return number - Number of active brainrots
function BrainrotSystem.GetActiveBrainrotCount()
	local count = 0
	for _, _ in pairs(activeBrainrots) do
		count = count + 1
	end
	return count
end

--- Get brainrot data by unique ID
--- @param uniqueId string - Unique ID of brainrot
--- @return table - Brainrot data, or nil if not found
function BrainrotSystem.GetBrainrot(uniqueId)
	return activeBrainrots[uniqueId]
end

--- Deal damage to a brainrot
--- @param uniqueId string - Unique ID of brainrot
--- @param damage number - Amount of damage to deal
function BrainrotSystem.DamageBrainrot(uniqueId, damage)
	local brainrot = activeBrainrots[uniqueId]
	if not brainrot or not brainrot.model or not brainrot.model.Parent then
		return
	end

	local humanoid = brainrot.model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		brainrot.health = brainrot.health - damage
		humanoid:TakeDamage(damage)

		-- Update visual representation of health
		BrainrotModel.UpdateHealthVisual(brainrot.model, brainrot.health, brainrot.maxHealth)

		-- Notify clients
		brainrotDamagedEvent:FireAllClients(uniqueId, brainrot.health, brainrot.maxHealth)
	end
end

--- Kill a brainrot instantly
--- @param uniqueId string - Unique ID of brainrot
function BrainrotSystem.KillBrainrot(uniqueId)
	local brainrot = activeBrainrots[uniqueId]
	if not brainrot or not brainrot.model or not brainrot.model.Parent then
		return
	end

	local humanoid = brainrot.model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

--- Despawn all active brainrots (for wave cleanup)
function BrainrotSystem.DespawnAllBrainrots()
	for uniqueId, brainrot in pairs(activeBrainrots) do
		if brainrot.model and brainrot.model.Parent then
			BrainrotModel.CleanupBrainrot(brainrot.model)
		end
		activeBrainrots[uniqueId] = nil
	end
	print("[BrainrotSystem] Despawned all brainrots")
end

-- Start the system when the script runs
BrainrotSystem.Initialize()

return BrainrotSystem
