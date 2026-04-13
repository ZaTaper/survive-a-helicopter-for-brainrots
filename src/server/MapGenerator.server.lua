-- MapGenerator.server.lua
-- Server-side map generation for "Survive a Helicopter for Brainrots"
-- Creates a simple floating sky pathway with 8 player bases, a spawn area, and a shop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local MapAssets = require(ServerStorage:WaitForChild("Storage"):WaitForChild("MapAssets"))

-- ============================================================
-- MAP CONFIGURATION
-- ============================================================

local MAP_CENTER = Vector3.new(0, 200, 0)
local PATHWAY_LENGTH = 200  -- Studs on Z axis
local PATHWAY_WIDTH = 30    -- Studs on X axis
local NUM_PLAYER_BASES = 8
local PLAYER_BASE_OFFSET_X = 20  -- Distance from pathway center (X axis)
local SPAWN_FLOOR_SIZE = 100     -- Safety net floor size

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

local function CreateMainPathway(parent)
	print("[MapGenerator] Creating main pathway...")
	local success, pathway = pcall(function()
		return MapAssets.CreatePathway(MAP_CENTER)
	end)

	if success and pathway then
		pathway.Parent = parent
		print("[MapGenerator] Pathway created successfully")
	else
		warn("[MapGenerator] Failed to create pathway: " .. tostring(pathway))
	end
end

local function CreatePlayerBases(parent)
	print("[MapGenerator] Creating " .. NUM_PLAYER_BASES .. " player bases along pathway...")
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "PlayerBases"
	basesFolder.Parent = parent

	-- Space bases evenly along the pathway (Z axis spans from -100 to +100 relative to center)
	local zStart = MAP_CENTER.Z - (PATHWAY_LENGTH / 2)
	local zEnd = MAP_CENTER.Z + (PATHWAY_LENGTH / 2)
	local zStep = PATHWAY_LENGTH / (NUM_PLAYER_BASES + 1)

	for i = 1, NUM_PLAYER_BASES do
		-- Alternate sides: odd bases on left (negative X), even on right (positive X)
		local xOffset = (i % 2 == 1) and -PLAYER_BASE_OFFSET_X or PLAYER_BASE_OFFSET_X
		local x = MAP_CENTER.X + xOffset
		local z = zStart + (i * zStep)
		local basePosition = Vector3.new(x, MAP_CENTER.Y, z)

		local success, playerBase = pcall(function()
			return MapAssets.CreatePlayerBase(basePosition, i, MAP_CENTER)
		end)

		if success and playerBase then
			playerBase.Parent = basesFolder
			print("[MapGenerator] Base " .. i .. " created at " .. tostring(basePosition))
		else
			warn("[MapGenerator] Failed to create base " .. i .. ": " .. tostring(playerBase))
		end
	end
end

local function CreateShop(parent)
	print("[MapGenerator] Creating shop at far end of pathway...")
	-- Far end = positive Z direction
	local shopPosition = Vector3.new(MAP_CENTER.X, MAP_CENTER.Y, MAP_CENTER.Z + (PATHWAY_LENGTH / 2))

	local success, shop = pcall(function()
		return MapAssets.CreateShop(shopPosition)
	end)

	if success and shop then
		shop.Parent = parent
		print("[MapGenerator] Shop created at " .. tostring(shopPosition))
	else
		warn("[MapGenerator] Failed to create shop: " .. tostring(shop))
	end
end

local function CreateSpawnArea(parent)
	print("[MapGenerator] Creating spawn area at start of pathway...")
	-- Start = negative Z direction
	local spawnPosition = Vector3.new(MAP_CENTER.X, MAP_CENTER.Y, MAP_CENTER.Z - (PATHWAY_LENGTH / 2))

	local success, spawnArea = pcall(function()
		return MapAssets.CreateSpawnArea(spawnPosition)
	end)

	if success and spawnArea then
		spawnArea.Parent = parent
		print("[MapGenerator] Spawn area created at " .. tostring(spawnPosition))
	else
		warn("[MapGenerator] Failed to create spawn area: " .. tostring(spawnArea))
	end
end

local function CreateGameSpawnLocation(parent)
	print("[MapGenerator] Creating game spawn location...")
	local spawnPosition = Vector3.new(MAP_CENTER.X, MAP_CENTER.Y + 5, MAP_CENTER.Z - (PATHWAY_LENGTH / 2))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GameSpawn"
	spawn.Size = Vector3.new(12, 2, 12)
	spawn.CFrame = CFrame.new(spawnPosition)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = MapAssets.Colors.SPAWN_PAD
	spawn.Transparency = 0.5
	spawn.Duration = 0
	spawn.CanTouch = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = parent
	print("[MapGenerator] Game spawn created at " .. tostring(spawnPosition))
end

-- ============================================================
-- MAIN MAP GENERATION
-- ============================================================

local function GenerateMap()
	print("[MapGenerator] Starting pathway map generation...")

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

	-- Clear all default terrain
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		terrain:Clear()
		print("[MapGenerator] Cleared all default terrain")
	end

	-- 2. Create guaranteed solid spawn floor (safety net underneath everything)
	print("[MapGenerator] Creating guaranteed solid spawn floor...")
	local spawnFloor = Instance.new("Part")
	spawnFloor.Name = "GuaranteedSpawnFloor"
	spawnFloor.Size = Vector3.new(SPAWN_FLOOR_SIZE, 4, SPAWN_FLOOR_SIZE)
	spawnFloor.Color = Color3.fromRGB(30, 30, 50)
	spawnFloor.Material = Enum.Material.SmoothPlastic
	spawnFloor.Transparency = 0
	spawnFloor.CanCollide = true
	spawnFloor.Anchored = true
	spawnFloor.CFrame = CFrame.new(MAP_CENTER - Vector3.new(0, 2, 0))
	spawnFloor.Parent = mapContainer
	print("[MapGenerator] Spawn floor created at " .. tostring(spawnFloor.Position))

	-- 3. Create main pathway
	CreateMainPathway(structures)

	-- 4. Create 8 player bases along the pathway sides
	CreatePlayerBases(structures)

	-- 5. Create shop at far end
	CreateShop(structures)

	-- 6. Create spawn area at start
	CreateSpawnArea(structures)

	-- 7. Setup dramatic sky lighting
	SetupLighting()

	-- 9. Log completion
	print("[MapGenerator] PATHWAY MAP GENERATION COMPLETE!")
	print("[MapGenerator] Map center: " .. tostring(MAP_CENTER))
	print("[MapGenerator] Pathway length: " .. PATHWAY_LENGTH .. " studs")
	print("[MapGenerator] Pathway width: " .. PATHWAY_WIDTH .. " studs")
	print("[MapGenerator] Player bases: " .. NUM_PLAYER_BASES .. " (offset " .. PLAYER_BASE_OFFSET_X .. " studs from center)")
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
