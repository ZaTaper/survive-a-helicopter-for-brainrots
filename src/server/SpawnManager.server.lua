-- SpawnManager.server.lua
-- Manages player spawning, brainrot spawning, and tool placement
-- Handles spawn points, cooldowns, and visual/audio effects

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local MapAssets = require(ServerStorage:WaitForChild("Storage"):WaitForChild("MapAssets"))

local SpawnManager = {}

-- Cache for spawn points
local playerSpawnPoints = {}
local brainrotSpawnPoints = {}
local toolSpawnPoints = {}
local lastSpawnTime = {}

-- Spawn cooldown times (in seconds)
local PLAYER_SPAWN_COOLDOWN = 0.1
local BRAINROT_SPAWN_COOLDOWN = 0.5
local TOOL_SPAWN_COOLDOWN = 1

-- Map dimensions from config
local MAP_SIZE = GameConfig.Map.SIZE
local SAFE_ZONE_RADIUS = GameConfig.Map.SAFE_ZONE_RADIUS
local SPAWN_RADIUS = GameConfig.Map.SPAWN_RADIUS

-- Map center
local MAP_CENTER = Vector3.new(0, 0, 0)

-- Initialize spawn points when called
function SpawnManager.InitializeSpawnPoints()
	print("[SpawnManager] Initializing spawn points...")

	-- Generate player spawn points in safe zone (circular distribution)
	local playerSpawnCount = 8
	local playerSpawnRadius = SAFE_ZONE_RADIUS * 0.7

	for i = 1, playerSpawnCount do
		local angle = (i - 1) / playerSpawnCount * math.pi * 2
		local spawnPos = MAP_CENTER
			+ Vector3.new(
				math.cos(angle) * playerSpawnRadius,
				3,
				math.sin(angle) * playerSpawnRadius
			)
		table.insert(playerSpawnPoints, spawnPos)
	end

	-- Generate brainrot spawn points around map edges (circular distribution)
	local brainrotSpawnCount = 16
	local angleStep = (math.pi * 2) / brainrotSpawnCount

	for i = 1, brainrotSpawnCount do
		local angle = (i - 1) * angleStep
		local spawnPos = MAP_CENTER
			+ Vector3.new(
				math.cos(angle) * SPAWN_RADIUS,
				5,
				math.sin(angle) * SPAWN_RADIUS
			)
		table.insert(brainrotSpawnPoints, spawnPos)
	end

	-- Generate tool spawn points in build zone
	local buildZoneInnerRadius = SAFE_ZONE_RADIUS * 1.5
	local buildZoneOuterRadius = SAFE_ZONE_RADIUS * 3.5
	local toolSpawnCount = 12

	for i = 1, toolSpawnCount do
		local angle = (i - 1) / toolSpawnCount * math.pi * 2
		local radius = buildZoneInnerRadius
			+ (buildZoneOuterRadius - buildZoneInnerRadius) * (i % 3) / 3
		local spawnPos = MAP_CENTER
			+ Vector3.new(
				math.cos(angle) * radius,
				2,
				math.sin(angle) * radius
			)
		table.insert(toolSpawnPoints, spawnPos)
	end

	print(
		"[SpawnManager] Initialized "
			.. #playerSpawnPoints
			.. " player spawns, "
			.. #brainrotSpawnPoints
			.. " brainrot spawns, "
			.. #toolSpawnPoints
			.. " tool spawns"
	)
end

-- Gets a random spawn position of specified type
-- Respects spawn cooldowns to prevent overlapping spawns
-- @param spawnType: string - "player", "brainrot", or "tool"
-- @return Vector3 - Position to spawn at
function SpawnManager.GetRandomSpawnPosition(spawnType)
	local now = tick()
	local spawnPoints
	local cooldown = PLAYER_SPAWN_COOLDOWN

	if spawnType == "player" then
		spawnPoints = playerSpawnPoints
		cooldown = PLAYER_SPAWN_COOLDOWN
	elseif spawnType == "brainrot" then
		spawnPoints = brainrotSpawnPoints
		cooldown = BRAINROT_SPAWN_COOLDOWN
	elseif spawnType == "tool" then
		spawnPoints = toolSpawnPoints
		cooldown = TOOL_SPAWN_COOLDOWN
	else
		error("Invalid spawn type: " .. tostring(spawnType))
	end

	if #spawnPoints == 0 then
		warn("[SpawnManager] No spawn points available for type: " .. spawnType)
		return MAP_CENTER + Vector3.new(0, 3, 0)
	end

	-- Find valid spawn points (respecting cooldown)
	local validPoints = {}
	for _, point in ipairs(spawnPoints) do
		local lastTime = lastSpawnTime[spawnType .. tostring(point)] or 0
		if now - lastTime >= cooldown then
			table.insert(validPoints, point)
		end
	end

	-- If all points are on cooldown, use random anyway
	if #validPoints == 0 then
		validPoints = spawnPoints
	end

	local randomPoint = validPoints[math.random(1, #validPoints)]

	-- Update last spawn time
	lastSpawnTime[spawnType .. tostring(randomPoint)] = now

	-- Add small random offset to prevent exact overlap
	local offset = Vector3.new(
		(math.random() - 0.5) * 3,
		0,
		(math.random() - 0.5) * 3
	)

	return randomPoint + offset
end

-- Spawns a player and creates spawn effects
-- @param player: Player - Player to spawn
-- @param character: Model - Character model to position
function SpawnManager.SpawnPlayer(player, character)
	local spawnPos = SpawnManager.GetRandomSpawnPosition("player")

	-- Move character to spawn position
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CFrame = CFrame.new(spawnPos)
	end

	-- Play spawn effects
	SpawnManager.PlaySpawnEffect(spawnPos)

	print("[SpawnManager] Spawned player " .. player.Name .. " at " .. tostring(spawnPos))
end

-- Spawns a brainrot at a random edge location
-- @param brainrotModel: Model - The brainrot to spawn
-- @return Vector3 - Position where brainrot was spawned
function SpawnManager.SpawnBrainrot(brainrotModel)
	local spawnPos = SpawnManager.GetRandomSpawnPosition("brainrot")

	local primaryPart = brainrotModel:FindFirstChild("Head")
		or brainrotModel:FindFirstChildOfClass("Part")

	if primaryPart then
		primaryPart.CFrame = CFrame.new(spawnPos)
	else
		-- Fallback: move entire model
		brainrotModel:MoveTo(spawnPos)
	end

	-- Play spawn effects
	SpawnManager.PlaySpawnEffect(spawnPos)

	return spawnPos
end

-- Spawns a tool pickup at a random build zone location
-- @param tool: Part/Model - The tool to spawn
-- @return Vector3 - Position where tool was spawned
function SpawnManager.SpawnTool(tool)
	local spawnPos = SpawnManager.GetRandomSpawnPosition("tool")

	if tool:IsA("Part") then
		tool.CFrame = CFrame.new(spawnPos)
	else
		tool:MoveTo(spawnPos)
	end

	-- Play spawn effects
	SpawnManager.PlaySpawnEffect(spawnPos)

	return spawnPos
end

-- Creates visual and audio spawn effects at a position
-- @param position: Vector3 - Where to create effects
function SpawnManager.PlaySpawnEffect(position)
	-- Particle effect
	local particleFolder = Instance.new("Folder")
	particleFolder.Name = "SpawnEffect"
	particleFolder.Parent = workspace

	-- Particles
	for i = 1, 15 do
		local particle = Instance.new("Part")
		particle.Name = "Particle"
		particle.Shape = Enum.PartType.Ball
		particle.Size = Vector3.new(0.5, 0.5, 0.5)
		particle.Color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.CFrame = CFrame.new(position)
		particle.Parent = particleFolder

		-- Animate particle upward
		local direction = (Vector3.new(
			(math.random() - 0.5) * 2,
			1,
			(math.random() - 0.5) * 2
		)).Unit

		local velocity = direction * 30
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = velocity
		bodyVelocity.Parent = particle

		-- Fade out
		game:GetService("Debris"):AddItem(particle, 0.5)
	end

	-- Create sound effect if possible
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://2597369437" -- Generic spawn sound
	sound.Volume = 0.5
	sound.Parent = particleFolder

	pcall(function()
		sound:Play()
	end)

	game:GetService("Debris"):AddItem(particleFolder, 1)
end

-- Gets all player spawn point positions (for visualization/debugging)
-- @return table - Array of Vector3 positions
function SpawnManager.GetPlayerSpawnPoints()
	return playerSpawnPoints
end

-- Gets all brainrot spawn point positions (for visualization/debugging)
-- @return table - Array of Vector3 positions
function SpawnManager.GetBrainrotSpawnPoints()
	return brainrotSpawnPoints
end

-- Gets all tool spawn point positions (for visualization/debugging)
-- @return table - Array of Vector3 positions
function SpawnManager.GetToolSpawnPoints()
	return toolSpawnPoints
end

-- Clears all spawn point data (useful for map resets)
function SpawnManager.ClearSpawnData()
	playerSpawnPoints = {}
	brainrotSpawnPoints = {}
	toolSpawnPoints = {}
	lastSpawnTime = {}
	print("[SpawnManager] Cleared all spawn data")
end

return SpawnManager
