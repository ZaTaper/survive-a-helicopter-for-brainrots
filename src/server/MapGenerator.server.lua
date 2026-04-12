-- MapGenerator.server.lua
-- Server-side procedural map generation
-- Creates game map with zones, terrain, decorations, and lighting
-- Runs once at game startup to build the entire playable environment

local GameConfig = require(game.ServerScriptService:WaitForChild("GameConfig"))
local MapAssets = require(game.ServerStorage:WaitForChild("MapAssets"))
local SpawnManager = require(game.ServerScriptService:WaitForChild("SpawnManager"))

-- Configuration from GameConfig
local MAP_SIZE = GameConfig.Map.SIZE
local SAFE_ZONE_RADIUS = GameConfig.Map.SAFE_ZONE_RADIUS
local MAP_CENTER = Vector3.new(0, 0, 0)

-- Internal map generation constants
local BUILD_ZONE_INNER_RADIUS = SAFE_ZONE_RADIUS * 1.5
local BUILD_ZONE_OUTER_RADIUS = SAFE_ZONE_RADIUS * 3.5
local TREE_COUNT = 40
local ROCK_COUNT = 50
local BUILDING_COUNT = 6
local DECORATIVE_ROCK_CLUSTERS = 8

-- Main map generation function
local function GenerateMap()
	print("[MapGenerator] Starting map generation...")

	-- Create map container
	local mapContainer = Instance.new("Folder")
	mapContainer.Name = "GameMap"
	mapContainer.Parent = workspace

	-- Create sub-folders for organization
	local terrain = Instance.new("Folder")
	terrain.Name = "Terrain"
	terrain.Parent = mapContainer

	local decorations = Instance.new("Folder")
	decorations.Name = "Decorations"
	decorations.Parent = mapContainer

	local zones = Instance.new("Folder")
	zones.Name = "Zones"
	zones.Parent = mapContainer

	-- 1. Generate ground with colored zones
	print("[MapGenerator] Generating ground terrain...")
	local groundParts = MapAssets.CreateGround(MAP_CENTER, SAFE_ZONE_RADIUS, BUILD_ZONE_OUTER_RADIUS, MAP_SIZE)
	groundParts.Parent = terrain

	-- 2. Create safe zone with glow effect
	print("[MapGenerator] Creating safe zone...")
	local safeZone = MapAssets.CreateSafeZone(MAP_CENTER, SAFE_ZONE_RADIUS)
	safeZone.Parent = zones

	-- 3. Create build zone indicator
	print("[MapGenerator] Creating build zone...")
	local buildZone = MapAssets.CreateBuildZone(MAP_CENTER, BUILD_ZONE_INNER_RADIUS, BUILD_ZONE_OUTER_RADIUS)
	buildZone.Parent = zones

	-- 4. Create map barriers at edges
	print("[MapGenerator] Creating map barriers...")
	local barriers = CreateMapBarriers(mapContainer, MAP_SIZE)

	-- 5. Add decorative elements
	print("[MapGenerator] Adding trees...")
	AddTrees(decorations, TREE_COUNT)

	print("[MapGenerator] Adding rocks...")
	AddRocks(decorations, ROCK_COUNT)

	print("[MapGenerator] Adding rock clusters...")
	AddRockClusters(decorations, DECORATIVE_ROCK_CLUSTERS)

	print("[MapGenerator] Adding buildings...")
	AddBuildings(decorations, BUILDING_COUNT)

	-- 6. Setup lighting and atmosphere
	print("[MapGenerator] Setting up lighting and atmosphere...")
	SetupLighting()

	-- 7. Create invisible ceiling to prevent helicopter overflow
	print("[MapGenerator] Creating ceiling barrier...")
	CreateCeiling(mapContainer, MAP_SIZE)

	-- 8. Initialize spawn manager
	print("[MapGenerator] Initializing spawn manager...")
	SpawnManager.InitializeSpawnPoints()

	-- 9. Add tag to map so scripts can find it
	local mapTag = Instance.new("ObjectValue")
	mapTag.Name = "MapGenerated"
	mapTag.Parent = mapContainer

	print("[MapGenerator] Map generation complete!")
	return mapContainer
end

-- Creates barrier walls at the edges of the map
-- Prevents players from leaving the play area
local function CreateMapBarriers(parent, mapSize)
	print("[MapGenerator] Building edge barriers...")

	local barriersFolder = Instance.new("Folder")
	barriersFolder.Name = "Barriers"
	barriersFolder.Parent = parent

	local barrierHeight = 50
	local barrierThickness = 10

	-- North barrier
	MapAssets.CreateBarrier(
		MAP_CENTER + Vector3.new(0, barrierHeight / 2, -mapSize),
		Vector3.new(mapSize * 2, barrierHeight, barrierThickness)
	).Parent = barriersFolder

	-- South barrier
	MapAssets.CreateBarrier(
		MAP_CENTER + Vector3.new(0, barrierHeight / 2, mapSize),
		Vector3.new(mapSize * 2, barrierHeight, barrierThickness)
	).Parent = barriersFolder

	-- East barrier
	MapAssets.CreateBarrier(
		MAP_CENTER + Vector3.new(mapSize, barrierHeight / 2, 0),
		Vector3.new(barrierThickness, barrierHeight, mapSize * 2)
	).Parent = barriersFolder

	-- West barrier
	MapAssets.CreateBarrier(
		MAP_CENTER + Vector3.new(-mapSize, barrierHeight / 2, 0),
		Vector3.new(barrierThickness, barrierHeight, mapSize * 2)
	).Parent = barriersFolder

	print("[MapGenerator] Edge barriers created")
end

-- Adds trees distributed around the map
local function AddTrees(parent, count)
	print("[MapGenerator] Generating " .. count .. " trees...")

	local treesFolder = Instance.new("Folder")
	treesFolder.Name = "Trees"
	treesFolder.Parent = parent

	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 2, MAP_SIZE * 0.8)

		-- Avoid placing trees in safe zone or too close to center
		if distance > SAFE_ZONE_RADIUS * 1.2 then
			local x = MAP_CENTER.X + math.cos(angle) * distance
			local z = MAP_CENTER.Z + math.sin(angle) * distance
			local treePos = Vector3.new(x, 0, z)

			local tree = MapAssets.CreateTree(treePos)
			tree.Parent = treesFolder
		end
	end
end

-- Adds randomly shaped rocks around the map
local function AddRocks(parent, count)
	print("[MapGenerator] Generating " .. count .. " rocks...")

	local rocksFolder = Instance.new("Folder")
	rocksFolder.Name = "Rocks"
	rocksFolder.Parent = parent

	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 2, MAP_SIZE * 0.9)

		-- Avoid safe zone
		if distance > SAFE_ZONE_RADIUS * 1.2 then
			local x = MAP_CENTER.X + math.cos(angle) * distance
			local z = MAP_CENTER.Z + math.sin(angle) * distance
			local rockPos = Vector3.new(x, 0, z)

			local rock = MapAssets.CreateRock(rockPos)
			rock.Parent = rocksFolder
		end
	end
end

-- Adds clusters of rocks (for visual interest)
local function AddRockClusters(parent, count)
	print("[MapGenerator] Generating " .. count .. " rock clusters...")

	local clustersFolder = Instance.new("Folder")
	clustersFolder.Name = "RockClusters"
	clustersFolder.Parent = parent

	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 2.5, MAP_SIZE * 0.85)

		-- Cluster center
		local centerX = MAP_CENTER.X + math.cos(angle) * distance
		local centerZ = MAP_CENTER.Z + math.sin(angle) * distance
		local centerPos = Vector3.new(centerX, 0, centerZ)

		-- Add 3-6 rocks per cluster
		local rocksInCluster = math.random(3, 6)
		for j = 1, rocksInCluster do
			local offsetAngle = math.random() * math.pi * 2
			local offsetDistance = math.random(5, 15)
			local offsetX = centerX + math.cos(offsetAngle) * offsetDistance
			local offsetZ = centerZ + math.sin(offsetAngle) * offsetDistance
			local clusterRockPos = Vector3.new(offsetX, 0, offsetZ)

			local rock = MapAssets.CreateRock(clusterRockPos)
			rock.Parent = clustersFolder
		end
	end
end

-- Adds buildings distributed around the map
local function AddBuildings(parent, count)
	print("[MapGenerator] Generating " .. count .. " buildings...")

	local buildingsFolder = Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = parent

	for i = 1, count do
		local angle = (i - 1) / count * math.pi * 2
		local distance = math.random(SAFE_ZONE_RADIUS * 3, MAP_SIZE * 0.75)

		local x = MAP_CENTER.X + math.cos(angle) * distance
		local z = MAP_CENTER.Z + math.sin(angle) * distance
		local buildingPos = Vector3.new(x, 0, z)

		local building = MapAssets.CreateBuilding(buildingPos)
		building.Parent = buildingsFolder
	end
end

-- Sets up game lighting and atmosphere
local function SetupLighting()
	print("[MapGenerator] Configuring lighting...")

	local lighting = game:GetService("Lighting")

	-- Set time of day (late afternoon / early evening)
	lighting.ClockTime = 17

	-- Configure ambient light
	lighting.Ambient = Color3.fromRGB(180, 180, 200)
	lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 200)

	-- Add fog for atmosphere
	lighting.FogStart = 100
	lighting.FogEnd = MAP_SIZE * 1.5
	lighting.FogColor = Color3.fromRGB(180, 200, 220)

	-- Add sunlight (directional light)
	local sun = Instance.new("Part")
	sun.Name = "SunLight"
	sun.CanCollide = false
	sun.CanQuery = false
	sun.CanTouch = false
	sun.Transparency = 1
	sun.Parent = workspace

	local sunLight = Instance.new("SurfaceGui")
	sunLight.Parent = sun

	-- Create a surface light simulation using parts
	local skyPart = Instance.new("Part")
	skyPart.Name = "SkyLighting"
	skyPart.Shape = Enum.PartType.Ball
	skyPart.Size = Vector3.new(1000, 1000, 1000)
	skyPart.CanCollide = false
	skyPart.CanQuery = false
	skyPart.CanTouch = false
	skyPart.Transparency = 1
	skyPart.CFrame = MAP_CENTER + Vector3.new(0, 300, 0)
	skyPart.Parent = workspace

	-- Create sky
	local sky = Instance.new("Sky")
	sky.Parent = lighting
	sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.png"
	sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.png"
	sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.png"
	sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.png"
	sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.png"
	sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.png"
	sky.CelestialBodiesShown = true

	-- Atmosphere
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Parent = lighting
	atmosphere.Density = 0.3
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	atmosphere.Glare = 0.5
	atmosphere.Decay = Color3.fromRGB(200, 200, 200)

	print("[MapGenerator] Lighting configured")
end

-- Creates an invisible ceiling to prevent infinite helicopter flight
local function CreateCeiling(parent, mapSize)
	print("[MapGenerator] Creating flight ceiling...")

	local ceilingFolder = Instance.new("Folder")
	ceilingFolder.Name = "Ceiling"
	ceilingFolder.Parent = parent

	local ceiling = Instance.new("Part")
	ceiling.Name = "HelicopterCeiling"
	ceiling.Size = Vector3.new(mapSize * 2.5, 1, mapSize * 2.5)
	ceiling.Color = Color3.fromRGB(255, 0, 0)
	ceiling.Material = Enum.Material.Plastic
	ceiling.CanCollide = true
	ceiling.Transparency = 1 -- Invisible but solid
	ceiling.TopSurface = Enum.SurfaceType.Smooth
	ceiling.BottomSurface = Enum.SurfaceType.Smooth
	ceiling.CFrame = CFrame.new(MAP_CENTER + Vector3.new(0, GameConfig.Helicopter.HEIGHT + 100, 0))
	ceiling.Parent = ceilingFolder

	print("[MapGenerator] Ceiling created at height " .. (GameConfig.Helicopter.HEIGHT + 100))
end

-- Run map generation on startup
pcall(function()
	GenerateMap()
end)

print("[MapGenerator] Map generator script loaded")
