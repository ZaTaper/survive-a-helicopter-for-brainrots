-- MapAssets.lua
-- Utility module for creating sky-based floating map elements
-- Provides functions to create spawn hub, floating bases, neon bridges, brainrot islands, and decorative clouds

local MapAssets = {}

-- Material and color constants
MapAssets.Colors = {
	NEON_CYAN = Color3.fromRGB(0, 255, 255),      -- Bright cyan neon
	NEON_PINK = Color3.fromRGB(255, 0, 128),      -- Hot pink neon
	NEON_GREEN = Color3.fromRGB(0, 255, 100),     -- Bright green neon
	NEON_PURPLE = Color3.fromRGB(200, 100, 255),  -- Purple neon
	GLASS_LIGHT = Color3.fromRGB(200, 200, 220),  -- Light glass color
	HUB_CENTER = Color3.fromRGB(50, 100, 255),    -- Blue for hub
	VOID_GLOW = Color3.fromRGB(50, 100, 200),     -- Deep blue for void
	CLOUD_WHITE = Color3.fromRGB(255, 255, 255),  -- White for clouds
	TREE_BARK = Color3.fromRGB(101, 67, 33),      -- Brown (kept for compatibility)
	TREE_FOLIAGE = Color3.fromRGB(34, 139, 34),   -- Forest green (kept for compatibility)
	TREE_FOLIAGE_LIGHT = Color3.fromRGB(76, 175, 80), -- Bright green (kept for compatibility)
	ROCK = Color3.fromRGB(128, 128, 128),         -- Gray (kept for compatibility)
	FLOWER_RED = Color3.fromRGB(255, 50, 80),     -- Red flowers (kept for compatibility)
	FLOWER_YELLOW = Color3.fromRGB(255, 255, 100), -- Yellow flowers (kept for compatibility)
	FLOWER_PURPLE = Color3.fromRGB(200, 100, 255), -- Purple flowers (kept for compatibility)
	SHOP_NEON = Color3.fromRGB(100, 255, 100),    -- Green neon for shop
	BASE_PLATFORM = Color3.fromRGB(100, 100, 150), -- Blue-gray for base platforms
}

MapAssets.Materials = {
	NEON = Enum.Material.Neon,
	GLASS = Enum.Material.Glass,
	SMOOTHPLASTIC = Enum.Material.SmoothPlastic,
	METAL = Enum.Material.Metal,
	WOOD = Enum.Material.Wood,
	ROCK = Enum.Material.Rock,
	CONCRETE = Enum.Material.Concrete,
}

-- Helper function to safely create parts with all required properties
-- @param name: string - Part name
-- @param size: Vector3 - Part size
-- @param color: Color3 - Part color
-- @param material: Material - Part material
-- @param position: Vector3 - Part position
-- @param canCollide: boolean - Whether part collides
-- @param anchored: boolean - Whether part is anchored
-- @return Part with all properties set
local function CreatePart(name, size, color, material, position, canCollide, anchored)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = canCollide
	part.Anchored = anchored
	part.CFrame = CFrame.new(position)
	return part
end

-- ========== SKY-BASED MAP FUNCTIONS ==========

-- Creates the central spawn hub at the center of the map
-- Large circular neon platform with shop booth and title sign
-- @param center: Vector3 - Center position (typically Y=200)
-- @return Model with hub parts
function MapAssets.CreateSpawnHub(center)
	local hub = Instance.new("Model")
	hub.Name = "SpawnHub"

	-- Main circular platform (using a flat cylinder - axis along Y for horizontal disk)
	local platformSize = 80
	local mainPlatform = Instance.new("Part")
	mainPlatform.Name = "MainPlatform"
	mainPlatform.Shape = Enum.PartType.Cylinder
	-- Cylinder axis = X. Size.X = length, Size.Y/Z = diameters
	-- Rotate 90° on Z so axis points up (Y), making a flat disk
	mainPlatform.Size = Vector3.new(3, platformSize, platformSize)
	mainPlatform.Color = MapAssets.Colors.GLASS_LIGHT
	mainPlatform.Material = Enum.Material.Glass
	mainPlatform.Transparency = 0.2
	mainPlatform.CanCollide = true
	mainPlatform.Anchored = true
	mainPlatform.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	mainPlatform.Parent = hub

	-- Backup solid platform underneath to guarantee collision
	local solidPlatform = Instance.new("Part")
	solidPlatform.Name = "SolidFloor"
	solidPlatform.Size = Vector3.new(platformSize, 2, platformSize)
	solidPlatform.Color = Color3.fromRGB(30, 30, 50)
	solidPlatform.Material = Enum.Material.SmoothPlastic
	solidPlatform.Transparency = 0.5
	solidPlatform.CanCollide = true
	solidPlatform.Anchored = true
	solidPlatform.CFrame = CFrame.new(center - Vector3.new(0, 1, 0))
	solidPlatform.Parent = hub

	-- Glowing neon rim around platform
	local rimSegments = 32
	for i = 1, rimSegments do
		local angle1 = (i - 1) / rimSegments * math.pi * 2
		local angle2 = i / rimSegments * math.pi * 2
		local pos1 = center + Vector3.new(math.cos(angle1) * (platformSize / 2), 1, math.sin(angle1) * (platformSize / 2))
		local pos2 = center + Vector3.new(math.cos(angle2) * (platformSize / 2), 1, math.sin(angle2) * (platformSize / 2))
		local midPos = (pos1 + pos2) / 2

		local rimPart = Instance.new("Part")
		rimPart.Name = "RimSegment_" .. i
		rimPart.Size = Vector3.new((pos2 - pos1).Magnitude, 0.5, 0.5)
		rimPart.Color = MapAssets.Colors.NEON_CYAN
		rimPart.Material = MapAssets.Materials.NEON
		rimPart.CanCollide = false
		rimPart.Anchored = true
		rimPart.CFrame = CFrame.new(midPos) * CFrame.Angles(0, math.atan2(pos2.Z - pos1.Z, pos2.X - pos1.X), 0)
		rimPart.Parent = hub
	end

	-- Title sign: "SURVIVE A HELICOPTER FOR BRAINROTS" floating above
	local titlePart = Instance.new("Part")
	titlePart.Name = "TitleSign"
	titlePart.Size = Vector3.new(1, 1, 1)
	titlePart.Transparency = 1
	titlePart.CanCollide = false
	titlePart.Anchored = true
	titlePart.CFrame = CFrame.new(center + Vector3.new(0, 30, 0))
	titlePart.Parent = hub

	local titleGui = Instance.new("BillboardGui")
	titleGui.Name = "TitleGui"
	titleGui.Size = UDim2.new(0, 600, 0, 100)
	titleGui.AlwaysOnTop = true
	titleGui.Parent = titlePart

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "SURVIVE A HELICOPTER FOR BRAINROTS"
	titleLabel.TextColor3 = MapAssets.Colors.NEON_CYAN
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Parent = titleGui

	-- Shop booth (on the platform)
	local shop = MapAssets.CreateShop(center + Vector3.new(0, 1, 0))
	shop.Parent = hub

	return hub
end

-- Creates a floating player base platform
-- Hexagonal floor with building pad and brainrot display area
-- @param position: Vector3 - Position to place base
-- @param baseIndex: number - Base number for naming
-- @param mapCenter: Vector3 - Center of the map
-- @return Model with base parts
function MapAssets.CreatePlayerBase(position, baseIndex, mapCenter)
	local base = Instance.new("Model")
	base.Name = "PlayerBase_" .. baseIndex

	-- Direction from center to this base
	local directionToBase = (position - mapCenter).Unit

	-- Base accent colors
	local baseColors = {
		Color3.fromRGB(220, 100, 100), -- Red
		Color3.fromRGB(100, 150, 220), -- Blue
		Color3.fromRGB(100, 220, 120), -- Green
		Color3.fromRGB(220, 180, 100), -- Orange
		Color3.fromRGB(180, 100, 220), -- Purple
		Color3.fromRGB(100, 220, 220), -- Cyan
		Color3.fromRGB(220, 220, 100), -- Yellow
		Color3.fromRGB(180, 180, 180), -- Silver
	}
	local accentColor = baseColors[((baseIndex - 1) % #baseColors) + 1]

	-- ===== HEXAGONAL FLOOR =====
	local hexRadius = 18
	local hexHeight = 0.5

	local hexFolder = Instance.new("Folder")
	hexFolder.Name = "HexagonalFloor"
	hexFolder.Parent = base

	for i = 1, 6 do
		local angle1 = (i - 1) / 6 * math.pi * 2
		local angle2 = i / 6 * math.pi * 2

		local wedge = Instance.new("WedgePart")
		wedge.Name = "HexSegment_" .. i
		wedge.Size = Vector3.new(hexRadius * 2, hexHeight, hexRadius * 2)

		if i % 2 == 0 then
			wedge.Color = Color3.fromRGB(60, 60, 75)
			wedge.Material = Enum.Material.Concrete
		else
			wedge.Color = Color3.fromRGB(50, 50, 65)
			wedge.Material = Enum.Material.Concrete
		end

		wedge.CanCollide = true
		wedge.Anchored = true

		local midAngle = (angle1 + angle2) / 2
		local segmentPos = position + Vector3.new(
			math.cos(midAngle) * (hexRadius / 2),
			0.25,
			math.sin(midAngle) * (hexRadius / 2)
		)
		wedge.CFrame = CFrame.new(segmentPos) * CFrame.Angles(0, angle1, 0)
		wedge.Parent = hexFolder
	end

	-- Neon hex edges
	local neonEdges = Instance.new("Folder")
	neonEdges.Name = "NeonEdges"
	neonEdges.Parent = base

	for i = 1, 6 do
		local angle1 = (i - 1) / 6 * math.pi * 2
		local angle2 = i / 6 * math.pi * 2

		local v1 = position + Vector3.new(math.cos(angle1) * hexRadius, 0.3, math.sin(angle1) * hexRadius)
		local v2 = position + Vector3.new(math.cos(angle2) * hexRadius, 0.3, math.sin(angle2) * hexRadius)
		local edgePos = (v1 + v2) / 2

		local edgeLength = (v2 - v1).Magnitude
		local edge = Instance.new("Part")
		edge.Name = "HexEdge_" .. i
		edge.Size = Vector3.new(edgeLength, 0.3, 0.3)
		edge.Color = accentColor
		edge.Material = Enum.Material.Neon
		edge.CanCollide = false
		edge.Anchored = true
		edge.CFrame = CFrame.new(edgePos) * CFrame.Angles(0, math.atan2(v2.Z - v1.Z, v2.X - v1.X), 0)
		edge.Parent = neonEdges
	end

	-- Corner pillars with neon tips
	local pillars = Instance.new("Folder")
	pillars.Name = "Pillars"
	pillars.Parent = base

	for i = 1, 6 do
		local angle = (i - 1) / 6 * math.pi * 2
		local pillarBasePos = position + Vector3.new(
			math.cos(angle) * hexRadius,
			0,
			math.sin(angle) * hexRadius
		)

		local pillar = Instance.new("Part")
		pillar.Name = "Pillar_" .. i
		pillar.Size = Vector3.new(1.5, 6, 1.5)
		pillar.Color = Color3.fromRGB(100, 100, 110)
		pillar.Material = Enum.Material.Metal
		pillar.CanCollide = false
		pillar.Anchored = true
		pillar.CFrame = CFrame.new(pillarBasePos + Vector3.new(0, 3, 0))
		pillar.Parent = pillars

		local tip = Instance.new("Part")
		tip.Name = "PillarTip_" .. i
		tip.Shape = Enum.PartType.Ball
		tip.Size = Vector3.new(0.8, 0.8, 0.8)
		tip.Color = accentColor
		tip.Material = Enum.Material.Neon
		tip.CanCollide = false
		tip.Anchored = true
		tip.CFrame = CFrame.new(pillarBasePos + Vector3.new(0, 6.5, 0))
		tip.Parent = pillars
	end

	-- ===== HELICOPTER BUILD PAD =====
	local buildingPadFolder = Instance.new("Folder")
	buildingPadFolder.Name = "HelicopterBuildingPad"
	buildingPadFolder.Parent = base

	local buildPadDistance = 30
	local buildPadPos = position + (directionToBase * buildPadDistance)

	local buildPad = Instance.new("Part")
	buildPad.Name = "BuildPad"
	buildPad.Size = Vector3.new(20, 1, 20)
	buildPad.Color = accentColor
	buildPad.Material = Enum.Material.Neon
	buildPad.CanCollide = true
	buildPad.Anchored = true
	buildPad.CFrame = CFrame.new(buildPadPos + Vector3.new(0, 0.5, 0))
	buildPad.Parent = buildingPadFolder

	local landingMarker = Instance.new("Part")
	landingMarker.Name = "LandingMarker"
	landingMarker.Size = Vector3.new(16, 0.2, 16)
	landingMarker.Color = Color3.fromRGB(255, 255, 255)
	landingMarker.Material = Enum.Material.Neon
	landingMarker.CanCollide = false
	landingMarker.Anchored = true
	landingMarker.CFrame = CFrame.new(buildPadPos + Vector3.new(0, 1.2, 0))
	landingMarker.Parent = buildingPadFolder

	local signPart = Instance.new("Part")
	signPart.Name = "BuildSign"
	signPart.Size = Vector3.new(0.5, 1, 1)
	signPart.Transparency = 1
	signPart.CanCollide = false
	signPart.Anchored = true
	signPart.CFrame = CFrame.new(buildPadPos + Vector3.new(0, 3, 0))
	signPart.Parent = buildingPadFolder

	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.new(0, 150, 0, 40)
	signGui.MaxDistance = 200
	signGui.Parent = signPart

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 0.2
	signText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	signText.Text = "BUILD HERE"
	signText.TextColor3 = accentColor
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.TextStrokeTransparency = 0.5
	signText.Parent = signGui

	-- ===== BRAINROT DISPLAY AREA =====
	local floatingDisplay = Instance.new("Folder")
	floatingDisplay.Name = "FloatingBrainrotDisplay"
	floatingDisplay.Parent = base

	local perpendicularDir = Vector3.new(-directionToBase.Z, 0, directionToBase.X).Unit
	local displayPos = position + (perpendicularDir * 22) + Vector3.new(0, 8, 0)

	local displayPlatform = Instance.new("Part")
	displayPlatform.Name = "DisplayPlatform"
	displayPlatform.Size = Vector3.new(16, 0.5, 16)
	displayPlatform.Color = MapAssets.Colors.GLASS_LIGHT
	displayPlatform.Material = Enum.Material.Glass
	displayPlatform.Transparency = 0.3
	displayPlatform.CanCollide = true
	displayPlatform.Anchored = true
	displayPlatform.CFrame = CFrame.new(displayPos)
	displayPlatform.Parent = floatingDisplay

	local supportBeam = Instance.new("Part")
	supportBeam.Name = "SupportBeam"
	supportBeam.Size = Vector3.new(0.5, (displayPos.Y - position.Y), 0.5)
	local beamMidPos = position + ((displayPos - position) * 0.5)
	supportBeam.Color = accentColor
	supportBeam.Material = Enum.Material.Neon
	supportBeam.CanCollide = false
	supportBeam.Anchored = true
	supportBeam.CFrame = CFrame.new(beamMidPos)
	supportBeam.Parent = floatingDisplay

	local pedestalsFolder = Instance.new("Folder")
	pedestalsFolder.Name = "DisplayPedestals"
	pedestalsFolder.Parent = floatingDisplay

	for i = 1, 8 do
		local angle = (i - 1) / 8 * math.pi * 2
		local pedestalRadius = 5
		local pedestalPos = displayPos + Vector3.new(
			math.cos(angle) * pedestalRadius,
			1,
			math.sin(angle) * pedestalRadius
		)

		local pedestal = Instance.new("Part")
		pedestal.Name = "Pedestal_" .. i
		pedestal.Size = Vector3.new(2, 1.5, 2)
		pedestal.Color = accentColor
		pedestal.Material = Enum.Material.Neon
		pedestal.CanCollide = false
		pedestal.Anchored = true
		pedestal.Transparency = 0.1
		pedestal.CFrame = CFrame.new(pedestalPos)
		pedestal.Parent = pedestalsFolder
		pedestal:SetAttribute("SlotIndex", i)
	end

	-- Player base name sign
	local namePart = Instance.new("Part")
	namePart.Name = "BaseNameSign"
	namePart.Size = Vector3.new(0.5, 1, 1)
	namePart.Transparency = 1
	namePart.CanCollide = false
	namePart.Anchored = true
	namePart.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
	namePart.Parent = base

	local nameGui = Instance.new("BillboardGui")
	nameGui.Size = UDim2.new(0, 150, 0, 40)
	nameGui.AlwaysOnTop = true
	nameGui.Parent = namePart

	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(1, 0, 1, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = "PLAYER " .. baseIndex .. "'S BASE"
	nameText.TextColor3 = accentColor
	nameText.TextScaled = true
	nameText.Font = Enum.Font.GothamBold
	nameText.TextStrokeTransparency = 0.3
	nameText.Parent = nameGui

	return base
end

-- Creates a glowing neon bridge connecting two positions
-- @param startPos: Vector3 - Starting position
-- @param endPos: Vector3 - Ending position
-- @param color: Color3 - Bridge color (default cyan)
-- @return Model with bridge parts
function MapAssets.CreateNeonBridge(startPos, endPos, color)
	color = color or MapAssets.Colors.NEON_CYAN

	local bridge = Instance.new("Model")
	bridge.Name = "NeonBridge"

	local bridgeWidth = 6
	local direction = (endPos - startPos)
	local distance = direction.Magnitude
	local midPos = (startPos + endPos) / 2

	-- Main bridge walkway (glass with slight transparency)
	local walkway = Instance.new("Part")
	walkway.Name = "Walkway"
	walkway.Size = Vector3.new(bridgeWidth, 1, distance)
	walkway.Color = MapAssets.Colors.GLASS_LIGHT
	walkway.Material = Enum.Material.Glass
	walkway.Transparency = 0.2
	walkway.CanCollide = true
	walkway.Anchored = true
	local upDir = Vector3.new(0, 1, 0)
	walkway.CFrame = CFrame.new(midPos, endPos) * CFrame.Angles(0, 0, 0)
	walkway.Parent = bridge

	-- Left neon rail
	local leftRail = Instance.new("Part")
	leftRail.Name = "LeftRail"
	leftRail.Size = Vector3.new(0.4, 0.8, distance)
	leftRail.Color = color
	leftRail.Material = Enum.Material.Neon
	leftRail.CanCollide = false
	leftRail.Anchored = true
	leftRail.CFrame = CFrame.new(midPos - Vector3.new(bridgeWidth / 2, 0, 0), endPos - Vector3.new(bridgeWidth / 2, 0, 0))
	leftRail.Parent = bridge

	-- Right neon rail
	local rightRail = Instance.new("Part")
	rightRail.Name = "RightRail"
	rightRail.Size = Vector3.new(0.4, 0.8, distance)
	rightRail.Color = color
	rightRail.Material = Enum.Material.Neon
	rightRail.CanCollide = false
	rightRail.Anchored = true
	rightRail.CFrame = CFrame.new(midPos + Vector3.new(bridgeWidth / 2, 0, 0), endPos + Vector3.new(bridgeWidth / 2, 0, 0))
	rightRail.Parent = bridge

	return bridge
end

-- Creates a themed brainrot island
-- Different sizes and colors based on rarity tier
-- @param position: Vector3 - Position to place island
-- @param tierIndex: number - Tier index (1-8)
-- @param tierConfig: table - Config with {name, color, money}
-- @return Model with island parts
function MapAssets.CreateBrainrotIsland(position, tierIndex, tierConfig)
	local island = Instance.new("Model")
	island.Name = "BrainrotIsland_" .. tierConfig.name

	-- Island sizes vary by tier (higher tier = bigger)
	local sizes = {20, 22, 24, 26, 28, 32, 36, 40}
	local islandSize = sizes[tierIndex] or 30
	local islandHeight = 2

	-- Main island platform
	local platform = Instance.new("Part")
	platform.Name = "IslandPlatform"
	platform.Size = Vector3.new(islandSize, islandHeight, islandSize)
	platform.Color = tierConfig.color
	platform.Material = Enum.Material.Neon
	platform.Transparency = 0.1
	platform.CanCollide = true
	platform.Anchored = true
	platform.CFrame = CFrame.new(position)
	platform.Parent = island

	-- Cloud mist underneath (white transparent parts)
	local cloudFolder = Instance.new("Folder")
	cloudFolder.Name = "CloudMist"
	cloudFolder.Parent = island

	for i = 1, 4 do
		local cloudOffset = (i - 1) * (islandSize / 4)
		local cloud = Instance.new("Part")
		cloud.Name = "Cloud_" .. i
		cloud.Size = Vector3.new(islandSize / 3, 1.5, islandSize / 3)
		cloud.Color = MapAssets.Colors.CLOUD_WHITE
		cloud.Material = Enum.Material.SmoothPlastic
		cloud.Transparency = 0.7
		cloud.CanCollide = false
		cloud.Anchored = true
		cloud.CFrame = CFrame.new(position + Vector3.new(cloudOffset - islandSize / 4, -3, cloudOffset - islandSize / 4))
		cloud.Parent = cloudFolder
	end

	-- Tier name sign floating above
	local signPart = Instance.new("Part")
	signPart.Name = "TierSign"
	signPart.Size = Vector3.new(0.5, 1, 1)
	signPart.Transparency = 1
	signPart.CanCollide = false
	signPart.Anchored = true
	signPart.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
	signPart.Parent = island

	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.new(0, 200, 0, 50)
	signGui.AlwaysOnTop = true
	signGui.Parent = signPart

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = tierConfig.name:upper() .. " ISLAND"
	signText.TextColor3 = tierConfig.color
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.TextStrokeTransparency = 0
	signText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	signText.Parent = signGui

	-- Brainrot spawn pedestals (3-6 per island, higher tier = more)
	local pedestalCounts = {3, 3, 4, 4, 5, 5, 6, 6}
	local pedestalCount = pedestalCounts[tierIndex] or 4

	local pedestalsFolder = Instance.new("Folder")
	pedestalsFolder.Name = "BrainrotPedestals"
	pedestalsFolder.Parent = island

	for i = 1, pedestalCount do
		local angle = (i - 1) / pedestalCount * math.pi * 2
		local pedestalRadius = islandSize / 3
		local pedestalPos = position + Vector3.new(
			math.cos(angle) * pedestalRadius,
			2,
			math.sin(angle) * pedestalRadius
		)

		local pedestal = Instance.new("Part")
		pedestal.Name = "BrainrotPedestal_" .. i
		pedestal.Size = Vector3.new(2, 0.8, 2)
		pedestal.Color = tierConfig.color
		pedestal.Material = Enum.Material.Neon
		pedestal.CanCollide = false
		pedestal.Anchored = true
		pedestal.Transparency = 0.15
		pedestal.CFrame = CFrame.new(pedestalPos)
		pedestal.Parent = pedestalsFolder
		pedestal:SetAttribute("TierIndex", tierIndex)
	end

	-- Glow light on island
	local light = Instance.new("PointLight")
	light.Color = tierConfig.color
	light.Brightness = 2
	light.Range = islandSize / 2
	light.Parent = platform

	return island
end

-- Creates a decorative cloud
-- @param position: Vector3 - Position for cloud
-- @param size: Vector3 - Cloud size (optional, default medium)
-- @return Part (cloud part)
function MapAssets.CreateCloud(position, size)
	size = size or Vector3.new(20, 5, 20)

	local cloud = Instance.new("Part")
	cloud.Name = "Cloud"
	cloud.Size = size
	cloud.Color = MapAssets.Colors.CLOUD_WHITE
	cloud.Material = Enum.Material.SmoothPlastic
	cloud.Transparency = 0.6
	cloud.CanCollide = false
	cloud.Anchored = true
	cloud.CFrame = CFrame.new(position)

	return cloud
end

-- Creates a void floor (large transparent glow below the map)
-- @param center: Vector3 - Center of the void
-- @return Part (void floor part)
function MapAssets.CreateVoidFloor(center)
	local voidFloor = Instance.new("Part")
	voidFloor.Name = "VoidFloor"
	voidFloor.Size = Vector3.new(2000, 100, 2000)
	voidFloor.Color = MapAssets.Colors.VOID_GLOW
	voidFloor.Material = Enum.Material.SmoothPlastic
	voidFloor.Transparency = 0.9
	voidFloor.CanCollide = false
	voidFloor.CanTouch = true
	voidFloor.Anchored = true
	voidFloor.CFrame = CFrame.new(center)

	return voidFloor
end

-- ========== COMPATIBILITY FUNCTIONS (kept for existing code) ==========

-- Creates a simple tree from parts with nicer design
-- @param position: Vector3 - Position to place tree
-- @return Model with tree structure
function MapAssets.CreateTree(position)
	local tree = Instance.new("Model")
	tree.Name = "Tree"

	-- Trunk - cylinder rotated to stand up
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(3, 12, 3)
	trunk.Color = MapAssets.Colors.TREE_BARK
	trunk.Material = MapAssets.Materials.WOOD
	trunk.CanCollide = true
	trunk.Anchored = true
	trunk.CFrame = CFrame.new(position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = tree

	-- Main foliage (bottom sphere)
	local foliage1 = Instance.new("Part")
	foliage1.Name = "Foliage1"
	foliage1.Shape = Enum.PartType.Ball
	foliage1.Size = Vector3.new(14, 14, 14)
	foliage1.Color = MapAssets.Colors.TREE_FOLIAGE
	foliage1.Material = Enum.Material.Grass
	foliage1.CanCollide = false
	foliage1.Anchored = true
	foliage1.CFrame = CFrame.new(position + Vector3.new(0, 16, 0))
	foliage1.Parent = tree

	-- Upper foliage (top sphere for more volume)
	local foliage2 = Instance.new("Part")
	foliage2.Name = "Foliage2"
	foliage2.Shape = Enum.PartType.Ball
	foliage2.Size = Vector3.new(12, 12, 12)
	foliage2.Color = MapAssets.Colors.TREE_FOLIAGE_LIGHT
	foliage2.Material = Enum.Material.Grass
	foliage2.CanCollide = false
	foliage2.Anchored = true
	foliage2.CFrame = CFrame.new(position + Vector3.new(0, 24, 0))
	foliage2.Parent = tree

	return tree
end

-- Creates a random rock formation
-- @param position: Vector3 - Position to place rock
-- @return Part (single rock piece)
function MapAssets.CreateRock(position)
	local rock = Instance.new("Part")
	rock.Name = "Rock"

	-- Randomize size
	local size = math.random(3, 8)
	rock.Size = Vector3.new(size, size, size)
	rock.Color = MapAssets.Colors.ROCK
	rock.Material = MapAssets.Materials.ROCK
	rock.CanCollide = true
	rock.Anchored = true
	rock.CFrame = CFrame.new(position + Vector3.new(
		math.random(-5, 5),
		size / 2,
		math.random(-5, 5)
	))

	return rock
end

-- Creates a simple building structure (spawn/build station)
-- @param position: Vector3 - Position to place building
-- @return Model with building parts
function MapAssets.CreateBuilding(position)
	local building = Instance.new("Model")
	building.Name = "Building"

	-- Main structure
	local walls = Instance.new("Part")
	walls.Name = "Walls"
	walls.Size = Vector3.new(20, 20, 20)
	walls.Color = Color3.fromRGB(180, 140, 100)
	walls.Material = MapAssets.Materials.CONCRETE
	walls.CanCollide = true
	walls.Anchored = true
	walls.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
	walls.Parent = building

	-- Roof
	local roof = Instance.new("WedgePart")
	roof.Name = "Roof"
	roof.Size = Vector3.new(20, 10, 20)
	roof.Color = Color3.fromRGB(139, 69, 19)
	roof.Material = Enum.Material.Wood
	roof.CanCollide = true
	roof.Anchored = true
	roof.CFrame = CFrame.new(position + Vector3.new(0, 25, 0))
	roof.Parent = building

	-- Door opening
	local door = Instance.new("Part")
	door.Name = "DoorFrame"
	door.Size = Vector3.new(4, 8, 1)
	door.Color = Color3.fromRGB(101, 67, 33)
	door.Material = MapAssets.Materials.WOOD
	door.CanCollide = false
	door.Anchored = true
	door.CFrame = CFrame.new(position + Vector3.new(10, 8, 10.5))
	door.Parent = building

	return building
end

-- Creates a glowing shop building for the central hub
-- @param position: Vector3 - Position to place shop
-- @return Model with shop parts
function MapAssets.CreateShop(position)
	local shop = Instance.new("Model")
	shop.Name = "Shop"

	-- Main structure with neon glow
	local walls = Instance.new("Part")
	walls.Name = "Walls"
	walls.Size = Vector3.new(30, 25, 30)
	walls.Color = MapAssets.Colors.SHOP_NEON
	walls.Material = Enum.Material.Neon
	walls.CanCollide = true
	walls.Anchored = true
	walls.CFrame = CFrame.new(position + Vector3.new(0, 12, 0))
	walls.Parent = shop

	-- Base platform
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(32, 2, 32)
	base.Color = MapAssets.Colors.BASE_PLATFORM
	base.Material = Enum.Material.Concrete
	base.CanCollide = true
	base.Anchored = true
	base.CFrame = CFrame.new(position + Vector3.new(0, 1, 0))
	base.Parent = shop

	-- Roof peak
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Shape = Enum.PartType.Ball
	roof.Size = Vector3.new(32, 20, 32)
	roof.Color = MapAssets.Colors.SHOP_NEON
	roof.Material = Enum.Material.Neon
	roof.CanCollide = false
	roof.Anchored = true
	roof.CFrame = CFrame.new(position + Vector3.new(0, 32, 0))
	roof.Parent = shop

	-- Entrance platform
	local entrance = Instance.new("Part")
	entrance.Name = "Entrance"
	entrance.Size = Vector3.new(30, 2, 8)
	entrance.Color = Color3.fromRGB(100, 255, 100)
	entrance.Material = Enum.Material.Neon
	entrance.CanCollide = true
	entrance.Anchored = true
	entrance.CFrame = CFrame.new(position + Vector3.new(0, 3, 20))
	entrance.Parent = shop

	return shop
end



-- Creates flower decorations
-- @param position: Vector3 - Position to place flower
-- @return Part (flower part)
function MapAssets.CreateFlower(position)
	local flower = Instance.new("Model")
	flower.Name = "Flower"

	-- Stem
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.5, 3, 0.5)
	stem.Color = Color3.fromRGB(34, 139, 34)
	stem.Material = Enum.Material.Grass
	stem.CanCollide = false
	stem.Anchored = true
	stem.CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0))
	stem.Parent = flower

	-- Flower petals (random color)
	local flowerColors = {
		MapAssets.Colors.FLOWER_RED,
		MapAssets.Colors.FLOWER_YELLOW,
		MapAssets.Colors.FLOWER_PURPLE,
	}
	local petalColor = flowerColors[math.random(1, #flowerColors)]

	local petals = Instance.new("Part")
	petals.Name = "Petals"
	petals.Shape = Enum.PartType.Ball
	petals.Size = Vector3.new(2, 2, 2)
	petals.Color = petalColor
	petals.Material = Enum.Material.SmoothPlastic
	petals.CanCollide = false
	petals.Anchored = true
	petals.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
	petals.Parent = flower

	return flower
end

-- Creates a floating sky showcase platform for displaying collected brainrots
-- This is a big floating area high in the sky where all brainrots are shown
-- @param center: Vector3 - Center position (above the map)
-- @return Model with sky showcase parts
function MapAssets.CreateSkyShowcase(center)
	local showcase = Instance.new("Model")
	showcase.Name = "SkyShowcase"

	-- Main floating platform (large, glass-like)
	local mainPlatform = Instance.new("Part")
	mainPlatform.Name = "MainPlatform"
	mainPlatform.Size = Vector3.new(120, 3, 120)
	mainPlatform.Color = Color3.fromRGB(180, 180, 220)
	mainPlatform.Material = Enum.Material.Glass
	mainPlatform.Transparency = 0.3
	mainPlatform.CanCollide = true
	mainPlatform.Anchored = true
	mainPlatform.CFrame = CFrame.new(center)
	mainPlatform.Parent = showcase

	-- Glowing neon border around the platform
	local borderColors = {
		Color3.fromRGB(255, 100, 50),  -- Orange
		Color3.fromRGB(0, 255, 255),   -- Cyan
		Color3.fromRGB(255, 50, 255),  -- Pink
		Color3.fromRGB(100, 255, 100), -- Green
	}
	local sides = {
		{offset = Vector3.new(60, 2, 0), size = Vector3.new(2, 4, 120)},
		{offset = Vector3.new(-60, 2, 0), size = Vector3.new(2, 4, 120)},
		{offset = Vector3.new(0, 2, 60), size = Vector3.new(120, 4, 2)},
		{offset = Vector3.new(0, 2, -60), size = Vector3.new(120, 4, 2)},
	}
	for i, side in ipairs(sides) do
		local border = Instance.new("Part")
		border.Name = "Border_" .. i
		border.Size = side.size
		border.Color = borderColors[i]
		border.Material = Enum.Material.Neon
		border.CanCollide = true
		border.Anchored = true
		border.CFrame = CFrame.new(center + side.offset)
		border.Parent = showcase
	end

	-- 8 display pedestals for each brainrot tier
	local tierColors = {
		Color3.fromRGB(180, 180, 180), -- Common
		Color3.fromRGB(50, 200, 50),   -- Uncommon
		Color3.fromRGB(50, 100, 255),  -- Rare
		Color3.fromRGB(160, 50, 255),  -- Epic
		Color3.fromRGB(255, 50, 50),   -- Mythic
		Color3.fromRGB(255, 215, 0),   -- Secret
		Color3.fromRGB(0, 255, 255),   -- Celestial
		Color3.fromRGB(255, 0, 128),   -- OP
	}
	local tierNames = {"Common", "Uncommon", "Rare", "Epic", "Mythic", "Secret", "Celestial", "OP"}

	for i = 1, 8 do
		local col = ((i - 1) % 4)
		local row = math.floor((i - 1) / 4)
		local pedestalX = center.X - 45 + (col * 30)
		local pedestalZ = center.Z - 20 + (row * 40)

		-- Pedestal base
		local pedestal = Instance.new("Part")
		pedestal.Name = "Pedestal_" .. tierNames[i]
		pedestal.Size = Vector3.new(20, 5, 20)
		pedestal.Color = tierColors[i]
		pedestal.Material = Enum.Material.Neon
		pedestal.CanCollide = true
		pedestal.Anchored = true
		pedestal.Transparency = 0.2
		pedestal.CFrame = CFrame.new(pedestalX, center.Y + 4, pedestalZ)
		pedestal.Parent = showcase

		-- Tier name label
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "TierLabel"
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 5, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = pedestal

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = tierNames[i]
		label.TextColor3 = tierColors[i]
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextStrokeTransparency = 0.5
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.Parent = billboard

		-- Glow light on pedestal
		local light = Instance.new("PointLight")
		light.Color = tierColors[i]
		light.Brightness = 2
		light.Range = 15
		light.Parent = pedestal
	end

	-- "BRAINROT COLLECTION" title sign floating above
	local titlePart = Instance.new("Part")
	titlePart.Name = "TitleSign"
	titlePart.Size = Vector3.new(1, 1, 1)
	titlePart.Transparency = 1
	titlePart.CanCollide = false
	titlePart.Anchored = true
	titlePart.CFrame = CFrame.new(center + Vector3.new(0, 20, 0))
	titlePart.Parent = showcase

	local titleGui = Instance.new("BillboardGui")
	titleGui.Name = "TitleGui"
	titleGui.Size = UDim2.new(0, 500, 0, 80)
	titleGui.AlwaysOnTop = true
	titleGui.Parent = titlePart

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "BRAINROT COLLECTION"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Parent = titleGui

	-- Teleport pad (on the ground level, players step on this to go to sky showcase)
	-- This is returned separately so it can be placed on the ground
	showcase:SetAttribute("TeleportUpY", center.Y + 3)

	return showcase
end

-- Creates a teleport pad that takes players to the sky showcase
-- @param position: Vector3 - Ground-level position for the pad
-- @return Part (glowing teleport pad)
function MapAssets.CreateTeleportPad(position, label)
	local pad = Instance.new("Part")
	pad.Name = "TeleportPad_" .. (label or "Sky")
	pad.Size = Vector3.new(10, 1, 10)
	pad.Color = Color3.fromRGB(255, 215, 0)
	pad.Material = Enum.Material.Neon
	pad.CanCollide = true
	pad.Anchored = true
	pad.CFrame = CFrame.new(position)

	-- Label above pad
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PadLabel"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = pad

	local padLabel = Instance.new("TextLabel")
	padLabel.Size = UDim2.new(1, 0, 1, 0)
	padLabel.BackgroundTransparency = 1
	padLabel.Text = label or "GO TO SKY"
	padLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	padLabel.TextScaled = true
	padLabel.Font = Enum.Font.FredokaOne
	padLabel.TextStrokeTransparency = 0.3
	padLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	padLabel.Parent = billboard

	-- Glow
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 215, 0)
	light.Brightness = 3
	light.Range = 20
	light.Parent = pad

	return pad
end

return MapAssets
