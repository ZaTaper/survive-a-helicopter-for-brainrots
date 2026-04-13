-- MapGenerator.server.lua
-- Server-side map generation for "Survive a Helicopter for Brainrots"
-- Creates a sky-based floating map with spawn hub, player bases, neon bridges, and brainrot islands

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local MapAssets = require(ServerStorage:WaitForChild("Storage"):WaitForChild("MapAssets"))

-- ============================================================
-- MAP CONFIGURATION
-- ============================================================

local MAP_CENTER = Vector3.new(0, 200, 0)
local NUM_PLAYER_BASES = 8
local PLAYER_BASE_RADIUS = 150
local BRAINROT_ISLAND_RADIUS_MIN = 300
local BRAINROT_ISLAND_RADIUS_MAX = 400
local VOID_CENTER_Y = 50

-- ============================================================
-- HELPER FUNCTIONS (defined BEFORE GenerateMap)
-- ============================================================

local function SetupLighting()
	print("[MapGenerator] Configuring dramatic sky lighting...")
	Lighting.ClockTime = 7  -- Sunrise/dramatic lighting
	Lighting.Ambient = Color3.fromRGB(150, 180, 220)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 180, 220)
	Lighting.FogStart = 100
	Lighting.FogEnd = 2000
	Lighting.FogColor = Color3.fromRGB(100, 150, 200)

	-- Atmosphere for sky effect
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Color = Color3.fromRGB(180, 200, 255)
	atmosphere.Glare = 0.5
	atmosphere.Decay = Color3.fromRGB(150, 150, 180)
	atmosphere.Parent = Lighting
end

local function CreateSpawnHub(parent)
	print("[MapGenerator] Creating spawn hub at center...")
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "SpawnHub"
	hubFolder.Parent = parent

	local hub = MapAssets.CreateSpawnHub(MAP_CENTER)
	hub.Parent = hubFolder
end

local function CreatePlayerBases(parent)
	print("[MapGenerator] Creating " .. NUM_PLAYER_BASES .. " player bases...")
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "PlayerBases"
	basesFolder.Parent = parent

	for i = 1, NUM_PLAYER_BASES do
		local angle = (i - 1) / NUM_PLAYER_BASES * math.pi * 2
		local x = MAP_CENTER.X + math.cos(angle) * PLAYER_BASE_RADIUS
		local z = MAP_CENTER.Z + math.sin(angle) * PLAYER_BASE_RADIUS
		local basePosition = Vector3.new(x, MAP_CENTER.Y, z)

		local playerBase = MapAssets.CreatePlayerBase(basePosition, i, MAP_CENTER)
		playerBase.Parent = basesFolder
	end
end

local function CreateNeonBridges(parent)
	print("[MapGenerator] Creating neon bridges from hub to bases...")
	local bridgesFolder = Instance.new("Folder")
	bridgesFolder.Name = "NeonBridges"
	bridgesFolder.Parent = parent

	for i = 1, NUM_PLAYER_BASES do
		local angle = (i - 1) / NUM_PLAYER_BASES * math.pi * 2
		local x = MAP_CENTER.X + math.cos(angle) * PLAYER_BASE_RADIUS
		local z = MAP_CENTER.Z + math.sin(angle) * PLAYER_BASE_RADIUS
		local basePosition = Vector3.new(x, MAP_CENTER.Y, z)

		-- Alternate bridge colors
		local bridgeColor = (i % 2 == 0) and MapAssets.Colors.NEON_CYAN or MapAssets.Colors.NEON_PINK

		local bridge = MapAssets.CreateNeonBridge(MAP_CENTER, basePosition, bridgeColor)
		bridge.Parent = bridgesFolder
	end
end

local function CreateBrainrotIslands(parent)
	print("[MapGenerator] Creating 8 brainrot islands for each tier...")
	local islandsFolder = Instance.new("Folder")
	islandsFolder.Name = "BrainrotIslands"
	islandsFolder.Parent = parent

	-- Get brainrot tiers from GameConfig
	local tiers = GameConfig.BrainrotTiers or {}

	-- Create one island per tier at different positions
	for tierIndex = 1, math.min(8, #tiers) do
		local tierConfig = tiers[tierIndex]

		-- Higher tiers are further out and higher up
		local angle = (tierIndex - 1) / 8 * math.pi * 2
		local radiusOffset = (tierIndex - 1) * ((BRAINROT_ISLAND_RADIUS_MAX - BRAINROT_ISLAND_RADIUS_MIN) / 7)
		local radius = BRAINROT_ISLAND_RADIUS_MIN + radiusOffset
		local heightVariation = (tierIndex - 1) * 10  -- Higher tiers get higher

		local x = MAP_CENTER.X + math.cos(angle) * radius
		local y = MAP_CENTER.Y + heightVariation
		local z = MAP_CENTER.Z + math.sin(angle) * radius

		local islandPosition = Vector3.new(x, y, z)
		local island = MapAssets.CreateBrainrotIsland(islandPosition, tierIndex, tierConfig)
		island.Parent = islandsFolder
	end
end

local function CreateDecorationClouds(parent)
	print("[MapGenerator] Creating decorative clouds...")
	local cloudsFolder = Instance.new("Folder")
	cloudsFolder.Name = "DecorationClouds"
	cloudsFolder.Parent = parent

	-- Scatter clouds around the map at various heights
	local cloudPositions = {
		Vector3.new(200, 150, 150),
		Vector3.new(-200, 160, 100),
		Vector3.new(100, 180, -250),
		Vector3.new(-300, 140, -100),
		Vector3.new(250, 170, -200),
		Vector3.new(-100, 155, 300),
	}

	for _, cloudPos in ipairs(cloudPositions) do
		local cloud = MapAssets.CreateCloud(cloudPos, Vector3.new(30, 8, 30))
		cloud.Parent = cloudsFolder
	end
end

local function CreateVoidFloor(parent)
	print("[MapGenerator] Creating void floor below map...")
	local voidFolder = Instance.new("Folder")
	voidFolder.Name = "Void"
	voidFolder.Parent = parent

	local voidFloor = MapAssets.CreateVoidFloor(Vector3.new(MAP_CENTER.X, VOID_CENTER_Y, MAP_CENTER.Z))
	voidFloor.Parent = voidFolder
end

-- ============================================================
-- MAIN MAP GENERATION
-- ============================================================

local function GenerateMap()
	print("[MapGenerator] Starting sky-based map generation...")

	-- Create map container
	local mapContainer = Instance.new("Folder")
	mapContainer.Name = "GameMap"
	mapContainer.Parent = workspace

	-- Create subfolders
	local structures = Instance.new("Folder")
	structures.Name = "Structures"
	structures.Parent = mapContainer

	-- 1. Delete default baseplate, spawn, AND terrain
	print("[MapGenerator] Removing default baseplate, terrain, and spawn...")
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("[MapGenerator] Removed default baseplate")
	end

	local defaultSpawn = workspace:FindFirstChild("SpawnLocation")
	if defaultSpawn then
		defaultSpawn:Destroy()
		print("[MapGenerator] Removed default SpawnLocation")
	end

	-- CRITICAL: Clear ALL default terrain (the green grass)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		terrain:Clear()
		print("[MapGenerator] Cleared all default terrain")
	end

	-- 2a. FIRST: Create a guaranteed solid spawn floor (simple Part, cannot fail)
	print("[MapGenerator] Creating guaranteed solid spawn floor...")
	local spawnFloor = Instance.new("Part")
	spawnFloor.Name = "GuaranteedSpawnFloor"
	spawnFloor.Size = Vector3.new(100, 4, 100)
	spawnFloor.Color = Color3.fromRGB(30, 30, 50)
	spawnFloor.Material = Enum.Material.SmoothPlastic
	spawnFloor.Transparency = 0
	spawnFloor.CanCollide = true
	spawnFloor.Anchored = true
	spawnFloor.CFrame = CFrame.new(MAP_CENTER - Vector3.new(0, 2, 0))
	spawnFloor.Parent = mapContainer
	print("[MapGenerator] Spawn floor created at " .. tostring(spawnFloor.Position))

	-- 2b. Create spawn hub at center (decorative, on top of the solid floor)
	CreateSpawnHub(structures)

	-- 3. Create 8 player bases arranged in circle
	CreatePlayerBases(structures)

	-- 4. Create neon bridges connecting hub to bases
	CreateNeonBridges(structures)

	-- 5. Create 8 brainrot islands (one per tier)
	CreateBrainrotIslands(structures)

	-- 6. Create decorative clouds
	CreateDecorationClouds(structures)

	-- 7. Create void floor below
	CreateVoidFloor(mapContainer)

	-- 8. Setup dramatic sky lighting
	SetupLighting()

	-- 9. Create game spawn location (on the hub)
	print("[MapGenerator] Creating game spawn location...")
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GameSpawn"
	spawn.Size = Vector3.new(12, 2, 12)
	spawn.CFrame = CFrame.new(MAP_CENTER + Vector3.new(0, 5, 0))
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = MapAssets.Colors.NEON_CYAN
	spawn.Transparency = 0.3
	spawn.Duration = 0
	spawn.CanTouch = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = mapContainer

	-- 10. Log completion
	print("[MapGenerator] SKY-BASED MAP GENERATION COMPLETE!")
	print("[MapGenerator] Spawn hub at: " .. tostring(MAP_CENTER))
	print("[MapGenerator] Player bases: " .. NUM_PLAYER_BASES)
	print("[MapGenerator] Player base radius: " .. PLAYER_BASE_RADIUS)
	print("[MapGenerator] Brainrot island range: " .. BRAINROT_ISLAND_RADIUS_MIN .. " - " .. BRAINROT_ISLAND_RADIUS_MAX)
end

-- Run map generation with error reporting
print("[MapGenerator] Initializing map generation...")
local success, err = pcall(GenerateMap)
if not success then
	warn("[MapGenerator] ERROR: " .. tostring(err))
	debug.traceback()
else
	print("[MapGenerator] Map loaded successfully!")
end
