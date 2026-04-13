-- MapGenerator.server.lua
-- Server-side map generation for "Survive a Helicopter for Brainrots"
-- Creates island terrain, player bases, shop, decorations, water, and lighting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local MapAssets = require(ServerStorage:WaitForChild("Storage"):WaitForChild("MapAssets"))

-- Map configuration
local MAP_SIZE = GameConfig.Map.SIZE
local SAFE_ZONE_RADIUS = GameConfig.Map.SAFE_ZONE_RADIUS
local MAP_CENTER = Vector3.new(0, 50, 0)
local WATER_HEIGHT = GameConfig.Map.WATER_HEIGHT

-- Build zone radiuses
local BUILD_ZONE_INNER_RADIUS = SAFE_ZONE_RADIUS * 1.5
local BUILD_ZONE_OUTER_RADIUS = SAFE_ZONE_RADIUS * 3.5

-- Number of player bases to create
local NUM_PLAYER_BASES = 8

-- ============================================================
-- HELPER FUNCTIONS (defined BEFORE GenerateMap)
-- ============================================================

local function AddTrees(parent, count)
	print("[MapGenerator] Generating " .. count .. " trees...")
	local treesFolder = Instance.new("Folder")
	treesFolder.Name = "Trees"
	treesFolder.Parent = parent

	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 2, MAP_SIZE * 0.85)
		if distance > SAFE_ZONE_RADIUS * 1.3 then
			local x = MAP_CENTER.X + math.cos(angle) * distance
			local z = MAP_CENTER.Z + math.sin(angle) * distance
			local tree = MapAssets.CreateTree(Vector3.new(x, MAP_CENTER.Y, z))
			tree.Parent = treesFolder
		end
	end
end

local function AddRocks(parent, count)
	print("[MapGenerator] Generating " .. count .. " rocks...")
	local rocksFolder = Instance.new("Folder")
	rocksFolder.Name = "Rocks"
	rocksFolder.Parent = parent

	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 2, MAP_SIZE * 0.9)
		if distance > SAFE_ZONE_RADIUS * 1.2 then
			local x = MAP_CENTER.X + math.cos(angle) * distance
			local z = MAP_CENTER.Z + math.sin(angle) * distance
			local rock = MapAssets.CreateRock(Vector3.new(x, MAP_CENTER.Y, z))
			rock.Parent = rocksFolder
		end
	end
end

local function AddRockClusters(parent, count)
	print("[MapGenerator] Generating " .. count .. " rock clusters...")
	local clustersFolder = Instance.new("Folder")
	clustersFolder.Name = "RockClusters"
	clustersFolder.Parent = parent

	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 2.5, MAP_SIZE * 0.85)
		local centerX = MAP_CENTER.X + math.cos(angle) * distance
		local centerZ = MAP_CENTER.Z + math.sin(angle) * distance

		for j = 1, math.random(3, 5) do
			local oAngle = math.random() * math.pi * 2
			local oDist = math.random(5, 15)
			local ox = centerX + math.cos(oAngle) * oDist
			local oz = centerZ + math.sin(oAngle) * oDist
			local rock = MapAssets.CreateRock(Vector3.new(ox, MAP_CENTER.Y, oz))
			rock.Parent = clustersFolder
		end
	end
end

local function AddFlowers(parent, count)
	print("[MapGenerator] Generating " .. count .. " flowers...")
	local flowersFolder = Instance.new("Folder")
	flowersFolder.Name = "Flowers"
	flowersFolder.Parent = parent

	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 0.5, MAP_SIZE * 0.8)
		local x = MAP_CENTER.X + math.cos(angle) * distance
		local z = MAP_CENTER.Z + math.sin(angle) * distance
		local flower = MapAssets.CreateFlower(Vector3.new(x, MAP_CENTER.Y + 0.5, z))
		flower.Parent = flowersFolder
	end
end

local function SetupLighting()
	print("[MapGenerator] Configuring lighting...")
	Lighting.ClockTime = 16.5
	Lighting.Ambient = Color3.fromRGB(220, 200, 180)
	Lighting.OutdoorAmbient = Color3.fromRGB(220, 200, 180)
	Lighting.FogStart = 150
	Lighting.FogEnd = MAP_SIZE * 1.8
	Lighting.FogColor = Color3.fromRGB(200, 220, 255)

	-- Atmosphere
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Color = Color3.fromRGB(220, 230, 255)
	atmosphere.Glare = 0.6
	atmosphere.Decay = Color3.fromRGB(210, 210, 210)
	atmosphere.Parent = Lighting
end

local function CreateCeiling(parent)
	print("[MapGenerator] Creating helicopter ceiling...")
	local helicopterHeight = GameConfig.Helicopter and GameConfig.Helicopter.HEIGHT or 50
	local ceilingHeight = helicopterHeight + 150

	local ceiling = Instance.new("Part")
	ceiling.Name = "HelicopterCeiling"
	ceiling.Size = Vector3.new(MAP_SIZE * 2.5, 1, MAP_SIZE * 2.5)
	ceiling.Transparency = 1
	ceiling.CanCollide = true
	ceiling.Anchored = true
	ceiling.CFrame = CFrame.new(MAP_CENTER.X, MAP_CENTER.Y + ceilingHeight, MAP_CENTER.Z)
	ceiling.Parent = parent
end

local function CreatePlayerBases(parent)
	print("[MapGenerator] Creating " .. NUM_PLAYER_BASES .. " player bases...")
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "PlayerBases"
	basesFolder.Parent = parent

	local baseRadius = BUILD_ZONE_OUTER_RADIUS * 0.75

	for i = 1, NUM_PLAYER_BASES do
		local angle = (i - 1) / NUM_PLAYER_BASES * math.pi * 2
		local x = MAP_CENTER.X + math.cos(angle) * baseRadius
		local z = MAP_CENTER.Z + math.sin(angle) * baseRadius

		local basePosition = Vector3.new(x, MAP_CENTER.Y, z)
		local playerBase = MapAssets.CreatePlayerBase(basePosition, i, MAP_CENTER)
		playerBase.Parent = basesFolder
	end
end

local function CreateCentralHub(parent)
	print("[MapGenerator] Creating central hub with shop...")
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "CentralHub"
	hubFolder.Parent = parent

	-- Create shop
	local shop = MapAssets.CreateShop(MAP_CENTER + Vector3.new(0, 0, 0))
	shop.Parent = hubFolder

	-- Create hub platform
	local hubPlatform = Instance.new("Part")
	hubPlatform.Name = "HubPlatform"
	hubPlatform.Size = Vector3.new(60, 2, 60)
	hubPlatform.Color = Color3.fromRGB(200, 200, 220)
	hubPlatform.Material = Enum.Material.Concrete
	hubPlatform.CanCollide = true
	hubPlatform.Anchored = true
	hubPlatform.CFrame = CFrame.new(MAP_CENTER + Vector3.new(0, 0.5, 0))
	hubPlatform.Parent = hubFolder
end

local function CreatePaths(parent)
	print("[MapGenerator] Creating paths from hub to bases...")
	local pathsFolder = Instance.new("Folder")
	pathsFolder.Name = "Paths"
	pathsFolder.Parent = parent

	local baseRadius = BUILD_ZONE_OUTER_RADIUS * 0.75
	local pathWidth = 8

	for i = 1, NUM_PLAYER_BASES do
		local angle = (i - 1) / NUM_PLAYER_BASES * math.pi * 2
		local x = MAP_CENTER.X + math.cos(angle) * baseRadius
		local z = MAP_CENTER.Z + math.sin(angle) * baseRadius

		-- Create path from center to base
		local pathLength = baseRadius
		local pathMidX = MAP_CENTER.X + math.cos(angle) * (baseRadius / 2)
		local pathMidZ = MAP_CENTER.Z + math.sin(angle) * (baseRadius / 2)

		local path = Instance.new("Part")
		path.Name = "Path_" .. i
		path.Size = Vector3.new(pathWidth, 1.5, pathLength)
		path.Color = Color3.fromRGB(220, 180, 100)
		path.Material = Enum.Material.Concrete
		path.CanCollide = true
		path.Anchored = true
		path.CFrame = CFrame.new(pathMidX, MAP_CENTER.Y + 0.5, pathMidZ) * CFrame.Angles(0, angle, 0)
		path.Parent = pathsFolder
	end
end

-- ============================================================
-- MAIN MAP GENERATION
-- ============================================================

local function GenerateMap()
	print("[MapGenerator] Starting map generation...")

	-- Create map container
	local mapContainer = Instance.new("Folder")
	mapContainer.Name = "GameMap"
	mapContainer.Parent = workspace

	local terrain = Instance.new("Folder")
	terrain.Name = "Terrain"
	terrain.Parent = mapContainer

	local waterFolder = Instance.new("Folder")
	waterFolder.Name = "Water"
	waterFolder.Parent = mapContainer

	local decorations = Instance.new("Folder")
	decorations.Name = "Decorations"
	decorations.Parent = mapContainer

	local structures = Instance.new("Folder")
	structures.Name = "Structures"
	structures.Parent = mapContainer

	-- 1. Delete default baseplate and spawn
	print("[MapGenerator] Removing default baseplate and spawn...")
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

	-- 2. Create island ground
	print("[MapGenerator] Creating island ground...")
	local ground = MapAssets.CreateIslandGround(MAP_CENTER, MAP_SIZE)
	ground.Parent = terrain

	-- 3. Create water below
	print("[MapGenerator] Creating water...")
	local water = MapAssets.CreateWater(MAP_CENTER, MAP_SIZE, WATER_HEIGHT)
	water.Parent = waterFolder

	-- 4. Create safe zone
	print("[MapGenerator] Creating safe zone...")
	local safeZone = MapAssets.CreateSafeZone(MAP_CENTER, SAFE_ZONE_RADIUS)
	safeZone.Parent = structures

	-- 5. Create build zone
	print("[MapGenerator] Creating build zone...")
	local buildZone = MapAssets.CreateBuildZone(MAP_CENTER, BUILD_ZONE_INNER_RADIUS, BUILD_ZONE_OUTER_RADIUS)
	buildZone.Parent = structures

	-- 6. Create central hub with shop
	CreateCentralHub(structures)

	-- 7. Create player bases
	CreatePlayerBases(structures)

	-- 8. Create connecting paths
	CreatePaths(structures)

	-- 9. Create sky showcase (floating brainrot display area)
	print("[MapGenerator] Creating sky showcase...")
	local SKY_CENTER = MAP_CENTER + Vector3.new(0, 300, 0)
	local skyShowcase = MapAssets.CreateSkyShowcase(SKY_CENTER)
	skyShowcase.Parent = structures

	-- 10. Create teleport pad near central hub to go to sky showcase
	print("[MapGenerator] Creating teleport pad...")
	local teleportPad = MapAssets.CreateTeleportPad(MAP_CENTER + Vector3.new(35, 1.5, 0), "SKY COLLECTION")
	teleportPad.Parent = structures

	-- 11. Create return teleport pad on sky showcase to come back down
	local returnPad = MapAssets.CreateTeleportPad(SKY_CENTER + Vector3.new(50, 1, 0), "RETURN TO GROUND")
	returnPad.Parent = structures

	-- 12. Add decorations
	AddTrees(decorations, 25)
	AddRocks(decorations, 30)
	AddRockClusters(decorations, 5)
	AddFlowers(decorations, 20)

	-- 13. Setup lighting
	SetupLighting()

	-- 14. Create ceiling
	CreateCeiling(mapContainer)

	-- 15. Create game spawn location
	print("[MapGenerator] Creating game spawn location...")
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GameSpawn"
	spawn.Size = Vector3.new(12, 2, 12)
	spawn.CFrame = CFrame.new(MAP_CENTER + Vector3.new(0, 3, 0))
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(100, 255, 100)
	spawn.Transparency = 0.5
	spawn.Duration = 0
	spawn.CanTouch = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = mapContainer

	print("[MapGenerator] MAP GENERATION COMPLETE!")
	print("[MapGenerator] Map size: " .. MAP_SIZE)
	print("[MapGenerator] Player bases: " .. NUM_PLAYER_BASES)
	print("[MapGenerator] Safe zone radius: " .. SAFE_ZONE_RADIUS)
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
