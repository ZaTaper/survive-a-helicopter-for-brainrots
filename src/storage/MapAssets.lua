-- MapAssets.lua
-- Utility module for creating map elements and structures
-- Provides functions to create trees, rocks, buildings, safe zones, water, and player bases

local MapAssets = {}

-- Material and color constants
MapAssets.Colors = {
	GRASS = Color3.fromRGB(76, 175, 80),        -- Vibrant grass green
	GRASS_LIGHT = Color3.fromRGB(102, 204, 102), -- Light grass green
	CONCRETE = Color3.fromRGB(140, 140, 150),   -- Stone/concrete gray
	SAFE_ZONE_GRASS = Color3.fromRGB(120, 255, 100), -- Bright safe zone green
	BUILD_AREA_GRASS = Color3.fromRGB(255, 200, 100), -- Orange build zone
	DANGER_ZONE_GRASS = Color3.fromRGB(220, 100, 100), -- Red danger zone
	TREE_BARK = Color3.fromRGB(101, 67, 33),    -- Brown
	TREE_FOLIAGE = Color3.fromRGB(34, 139, 34),  -- Forest green
	TREE_FOLIAGE_LIGHT = Color3.fromRGB(76, 175, 80), -- Bright green foliage
	ROCK = Color3.fromRGB(128, 128, 128),        -- Gray
	FLOWER_RED = Color3.fromRGB(255, 50, 80),    -- Red flowers
	FLOWER_YELLOW = Color3.fromRGB(255, 255, 100), -- Yellow flowers
	FLOWER_PURPLE = Color3.fromRGB(200, 100, 255), -- Purple flowers
	SAFE_ZONE_GLOW = Color3.fromRGB(100, 255, 100), -- Bright glow
	WATER = Color3.fromRGB(100, 150, 255),      -- Bright water blue
	SHOP_NEON = Color3.fromRGB(0, 255, 255),    -- Cyan neon for shop
	BASE_PLATFORM = Color3.fromRGB(200, 200, 220), -- Light gray for bases
}

MapAssets.Materials = {
	GRASS = Enum.Material.Grass,
	CONCRETE = Enum.Material.Concrete,
	WOOD = Enum.Material.Wood,
	ROCK = Enum.Material.Rock,
	NEON = Enum.Material.Neon,
	SMOOTHPLASTIC = Enum.Material.SmoothPlastic,
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

-- Creates a player base platform with hexagonal floor, building pad, and floating brainrot display
-- @param position: Vector3 - Position to place base
-- @param baseIndex: number - Base number for naming
-- @param mapCenter: Vector3 - Center of the map (for determining direction)
-- @return Model with base parts
function MapAssets.CreatePlayerBase(position, baseIndex, mapCenter)
	local base = Instance.new("Model")
	base.Name = "PlayerBase_" .. baseIndex

	-- Determine direction: from map center to this base (for building pad to face outward)
	local directionToBase = (position - mapCenter).Unit

	-- Base accent colors for each player position
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

	-- ===== HEXAGONAL FLOOR PLATFORM =====
	-- Create hexagonal floor from 6 triangular sections
	local hexRadius = 18
	local hexHeight = 0.5

	local hexFolder = Instance.new("Folder")
	hexFolder.Name = "HexagonalFloor"
	hexFolder.Parent = base

	for i = 1, 6 do
		local angle1 = (i - 1) / 6 * math.pi * 2
		local angle2 = i / 6 * math.pi * 2

		-- Create a wedge part for each section
		local wedge = Instance.new("WedgePart")
		wedge.Name = "HexSegment_" .. i
		wedge.Size = Vector3.new(hexRadius * 2, hexHeight, hexRadius * 2)

		-- Alternate between darker and lighter shades
		if i % 2 == 0 then
			wedge.Color = Color3.fromRGB(60, 60, 75)
			wedge.Material = Enum.Material.Concrete
		else
			wedge.Color = Color3.fromRGB(50, 50, 65)
			wedge.Material = Enum.Material.Concrete
		end

		wedge.CanCollide = true
		wedge.Anchored = true

		-- Position and rotate each segment
		local midAngle = (angle1 + angle2) / 2
		local segmentPos = position + Vector3.new(
			math.cos(midAngle) * (hexRadius / 2),
			0.25,
			math.sin(midAngle) * (hexRadius / 2)
		)
		wedge.CFrame = CFrame.new(segmentPos) * CFrame.Angles(0, angle1, 0)
		wedge.Parent = hexFolder
	end

	-- Add glowing neon hex edges
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

	-- ===== CORNER PILLARS WITH NEON TIPS =====
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

		-- Main pillar (metal)
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar_" .. i
		pillar.Size = Vector3.new(1.5, 6, 1.5)
		pillar.Color = Color3.fromRGB(100, 100, 110)
		pillar.Material = Enum.Material.Metal
		pillar.CanCollide = false
		pillar.Anchored = true
		pillar.CFrame = CFrame.new(pillarBasePos + Vector3.new(0, 3, 0))
		pillar.Parent = pillars

		-- Neon tip on pillar
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

	-- ===== GLOWING BORDER AROUND BASE =====
	local borderParts = Instance.new("Folder")
	borderParts.Name = "GlowingBorder"
	borderParts.Parent = base

	for i = 1, 12 do
		local angle = (i - 1) / 12 * math.pi * 2
		local borderPos = position + Vector3.new(
			math.cos(angle) * (hexRadius + 2),
			0.5,
			math.sin(angle) * (hexRadius + 2)
		)

		local borderSegment = Instance.new("Part")
		borderSegment.Name = "BorderSegment_" .. i
		borderSegment.Size = Vector3.new(2, 0.5, 2)
		borderSegment.Color = accentColor
		borderSegment.Material = Enum.Material.Neon
		borderSegment.CanCollide = false
		borderSegment.Anchored = true
		borderSegment.CFrame = CFrame.new(borderPos)
		borderSegment.Parent = borderParts
	end

	-- ===== HELICOPTER BUILDING PAD (IN FRONT / AWAY FROM CENTER) =====
	local buildingPadFolder = Instance.new("Folder")
	buildingPadFolder.Name = "HelicopterBuildingPad"
	buildingPadFolder.Parent = base

	-- Position: outward from map center by ~30 studs
	local buildPadDistance = 30
	local buildPadPos = position + (directionToBase * buildPadDistance)

	-- Main building pad
	local buildPad = Instance.new("Part")
	buildPad.Name = "BuildPad"
	buildPad.Size = Vector3.new(18, 1, 18)
	buildPad.Color = Color3.fromRGB(100, 100, 120)
	buildPad.Material = Enum.Material.Metal
	buildPad.CanCollide = true
	buildPad.Anchored = true
	buildPad.CFrame = CFrame.new(buildPadPos + Vector3.new(0, 0.5, 0))
	buildPad.Parent = buildingPadFolder

	-- "H" landing marker
	local landingMarker = Instance.new("Part")
	landingMarker.Name = "LandingMarker"
	landingMarker.Size = Vector3.new(12, 0.2, 12)
	landingMarker.Color = accentColor
	landingMarker.Material = Enum.Material.Neon
	landingMarker.CanCollide = false
	landingMarker.Anchored = true
	landingMarker.CFrame = CFrame.new(buildPadPos + Vector3.new(0, 1.2, 0))
	landingMarker.Parent = buildingPadFolder

	-- "BUILD HERE" sign
	local signPart = Instance.new("Part")
	signPart.Name = "BuildSign"
	signPart.Size = Vector3.new(0.5, 1, 1)
	signPart.Transparency = 1
	signPart.CanCollide = false
	signPart.Anchored = true
	signPart.CFrame = CFrame.new(buildPadPos + Vector3.new(0, 3, 0))
	signPart.Parent = buildingPadFolder

	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.new(0, 200, 0, 50)
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

	-- Glow light on building pad
	local buildLight = Instance.new("PointLight")
	buildLight.Color = accentColor
	buildLight.Brightness = 2
	buildLight.Range = 25
	buildLight.Parent = buildPad

	-- ===== FLOATING BRAINROT DISPLAY AREA =====
	local floatingDisplay = Instance.new("Folder")
	floatingDisplay.Name = "FloatingBrainrotDisplay"
	floatingDisplay.Parent = base

	-- Position: elevated and to the side (perpendicular to building pad direction)
	local perpendicularDir = Vector3.new(-directionToBase.Z, 0, directionToBase.X).Unit
	local displayPos = position + (perpendicularDir * 22) + Vector3.new(0, 8, 0)

	-- Floating glass platform
	local floatingPlatform = Instance.new("Part")
	floatingPlatform.Name = "FloatingPlatform"
	floatingPlatform.Size = Vector3.new(16, 0.5, 16)
	floatingPlatform.Color = Color3.fromRGB(150, 150, 200)
	floatingPlatform.Material = Enum.Material.Glass
	floatingPlatform.Transparency = 0.3
	floatingPlatform.CanCollide = true
	floatingPlatform.Anchored = true
	floatingPlatform.CFrame = CFrame.new(displayPos)
	floatingPlatform.Parent = floatingDisplay

	-- Glowing support beams (1 thin beam from base to floating platform)
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

	-- Display pedestals (8 pedestals in a circle on floating platform)
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

	return base
end

-- Creates a barrier/wall piece (no longer used - map has no barriers)
-- @param position: Vector3 - Position to place barrier
-- @param size: Vector3 - Size of barrier
-- @return Part (barrier piece)
function MapAssets.CreateBarrier(position, size)
	local barrier = Instance.new("Part")
	barrier.Name = "Barrier"
	barrier.Size = size
	barrier.Color = MapAssets.Colors.CONCRETE
	barrier.Material = MapAssets.Materials.CONCRETE
	barrier.CanCollide = true
	barrier.CFrame = CFrame.new(position)

	return barrier
end

-- Creates a glowing safe zone with bright border and nice effects
-- @param center: Vector3 - Center of safe zone
-- @param radius: number - Radius of safe zone
-- @return Model with zone indicator
function MapAssets.CreateSafeZone(center, radius)
	local safeZone = Instance.new("Model")
	safeZone.Name = "SafeZone"

	-- Outer glowing ring border with more density
	local ringSegments = 48
	for i = 1, ringSegments do
		local angle1 = (i - 1) / ringSegments * math.pi * 2
		local angle2 = i / ringSegments * math.pi * 2

		local pos1 = center + Vector3.new(math.cos(angle1) * radius, 0.5, math.sin(angle1) * radius)
		local pos2 = center + Vector3.new(math.cos(angle2) * radius, 0.5, math.sin(angle2) * radius)
		local midPos = (pos1 + pos2) / 2

		local ringPart = Instance.new("Part")
		ringPart.Name = "SafeZoneRing"
		ringPart.Size = Vector3.new(radius / 20, 0.8, radius / 20)
		ringPart.Color = MapAssets.Colors.SAFE_ZONE_GLOW
		ringPart.Material = MapAssets.Materials.NEON
		ringPart.CanCollide = false
		ringPart.Anchored = true
		ringPart.CFrame = CFrame.new(midPos)
		ringPart.Parent = safeZone
	end

	-- Inner ring for extra glow effect
	local innerSegments = 32
	for i = 1, innerSegments do
		local angle1 = (i - 1) / innerSegments * math.pi * 2
		local angle2 = i / innerSegments * math.pi * 2
		local innerRad = radius * 0.95

		local pos1 = center + Vector3.new(math.cos(angle1) * innerRad, 0.3, math.sin(angle1) * innerRad)
		local pos2 = center + Vector3.new(math.cos(angle2) * innerRad, 0.3, math.sin(angle2) * innerRad)
		local midPos = (pos1 + pos2) / 2

		local ringPart = Instance.new("Part")
		ringPart.Name = "SafeZoneInnerRing"
		ringPart.Size = Vector3.new(radius / 25, 0.5, radius / 25)
		ringPart.Color = Color3.fromRGB(150, 255, 150)
		ringPart.Material = MapAssets.Materials.NEON
		ringPart.CanCollide = false
		ringPart.Anchored = true
		ringPart.CFrame = CFrame.new(midPos)
		ringPart.Parent = safeZone
	end

	-- Center glowing beacon
	local centerGlow = Instance.new("Part")
	centerGlow.Name = "SafeZoneCenter"
	centerGlow.Shape = Enum.PartType.Ball
	centerGlow.Size = Vector3.new(radius * 0.15, radius * 0.15, radius * 0.15)
	centerGlow.Color = MapAssets.Colors.SAFE_ZONE_GLOW
	centerGlow.Material = MapAssets.Materials.NEON
	centerGlow.CanCollide = false
	centerGlow.Anchored = true
	centerGlow.CFrame = CFrame.new(center + Vector3.new(0, 5, 0))
	centerGlow.Parent = safeZone

	-- Marker surface (ground level indicator)
	local marker = Instance.new("Part")
	marker.Name = "SafeZoneMarker"
	marker.Size = Vector3.new(radius * 2, 0.5, radius * 2)
	marker.Color = MapAssets.Colors.SAFE_ZONE_GRASS
	marker.Material = Enum.Material.Grass
	marker.CanCollide = false
	marker.Anchored = true
	marker.CFrame = CFrame.new(center + Vector3.new(0, 0.25, 0))
	marker.Parent = safeZone

	return safeZone
end

-- Creates the build zone ring indicator with decorative elements
-- @param center: Vector3 - Center of build zone
-- @param innerRadius: number - Inner radius (safe zone edge)
-- @param outerRadius: number - Outer radius (danger zone edge)
-- @return Model with zone indicator
function MapAssets.CreateBuildZone(center, innerRadius, outerRadius)
	local buildZone = Instance.new("Model")
	buildZone.Name = "BuildZone"

	-- Outer boundary ring
	local ringSegments = 64
	local outerRingWidth = (outerRadius - innerRadius) / 5

	for i = 1, ringSegments do
		local angle1 = (i - 1) / ringSegments * math.pi * 2
		local angle2 = i / ringSegments * math.pi * 2

		local midAngle = (angle1 + angle2) / 2

		-- Outer ring
		local outerPos = center + Vector3.new(math.cos(midAngle) * outerRadius, 0.3, math.sin(midAngle) * outerRadius)
		local outerRingPart = Instance.new("Part")
		outerRingPart.Name = "BuildZoneOuterRing"
		outerRingPart.Size = Vector3.new(outerRingWidth, 0.6, outerRingWidth)
		outerRingPart.Color = Color3.fromRGB(255, 165, 50)
		outerRingPart.Material = Enum.Material.Neon
		outerRingPart.CanCollide = false
		outerRingPart.Anchored = true
		outerRingPart.CFrame = CFrame.new(outerPos)
		outerRingPart.Parent = buildZone

		-- Inner ring
		local innerPos = center + Vector3.new(math.cos(midAngle) * innerRadius, 0.3, math.sin(midAngle) * innerRadius)
		local innerRingPart = Instance.new("Part")
		innerRingPart.Name = "BuildZoneInnerRing"
		innerRingPart.Size = Vector3.new(outerRingWidth, 0.6, outerRingWidth)
		innerRingPart.Color = Color3.fromRGB(150, 255, 100)
		innerRingPart.Material = Enum.Material.Neon
		innerRingPart.CanCollide = false
		innerRingPart.Anchored = true
		innerRingPart.CFrame = CFrame.new(innerPos)
		innerRingPart.Parent = buildZone
	end

	return buildZone
end

-- Creates large layered ground/terrain for the island
-- Builds a floating island look with grass top and concrete visible from sides
-- @param center: Vector3 - Center of map
-- @param mapRadius: number - Total map radius
-- @return Model with ground parts
function MapAssets.CreateIslandGround(center, mapRadius)
	local ground = Instance.new("Model")
	ground.Name = "Ground"

	-- Main grass platform (top surface) - large single piece
	local grassTop = Instance.new("Part")
	grassTop.Name = "GrassTop"
	grassTop.Size = Vector3.new(mapRadius * 2, 2, mapRadius * 2)
	grassTop.Color = MapAssets.Colors.GRASS
	grassTop.Material = Enum.Material.Grass
	grassTop.CanCollide = true
	grassTop.Anchored = true
	grassTop.TopSurface = Enum.SurfaceType.Smooth
	grassTop.BottomSurface = Enum.SurfaceType.Smooth
	grassTop.CFrame = CFrame.new(center + Vector3.new(0, 1, 0))
	grassTop.Parent = ground

	-- Concrete layer underneath (visible from sides)
	local concreteBase = Instance.new("Part")
	concreteBase.Name = "ConcreteBase"
	concreteBase.Size = Vector3.new(mapRadius * 2, 10, mapRadius * 2)
	concreteBase.Color = MapAssets.Colors.CONCRETE
	concreteBase.Material = Enum.Material.Concrete
	concreteBase.CanCollide = true
	concreteBase.Anchored = true
	concreteBase.TopSurface = Enum.SurfaceType.Smooth
	concreteBase.BottomSurface = Enum.SurfaceType.Smooth
	concreteBase.CFrame = CFrame.new(center + Vector3.new(0, -4, 0))
	concreteBase.Parent = ground

	-- Edge detail blocks for visual interest (much fewer than before)
	local edgeDetailFolder = Instance.new("Folder")
	edgeDetailFolder.Name = "EdgeDetails"
	edgeDetailFolder.Parent = ground

	local edgeBlockSize = 20
	local edgeSegments = 20
	for i = 1, edgeSegments do
		local angle = (i / edgeSegments) * math.pi * 2
		local dist = mapRadius - 20
		local x = center.X + math.cos(angle) * dist
		local z = center.Z + math.sin(angle) * dist

		local grassBlock = Instance.new("Part")
		grassBlock.Name = "EdgeGrass"
		grassBlock.Size = Vector3.new(edgeBlockSize, 3, edgeBlockSize)
		grassBlock.Color = MapAssets.Colors.GRASS_LIGHT
		grassBlock.Material = Enum.Material.Grass
		grassBlock.CanCollide = true
		grassBlock.Anchored = true
		grassBlock.CFrame = CFrame.new(x, center.Y + 1.5, z)
		grassBlock.Parent = edgeDetailFolder

		local concreteBlock = Instance.new("Part")
		concreteBlock.Name = "EdgeConcrete"
		concreteBlock.Size = Vector3.new(edgeBlockSize, 8, edgeBlockSize)
		concreteBlock.Color = MapAssets.Colors.CONCRETE
		concreteBlock.Material = Enum.Material.Concrete
		concreteBlock.CanCollide = true
		concreteBlock.Anchored = true
		concreteBlock.CFrame = CFrame.new(x, center.Y - 3, z)
		concreteBlock.Parent = edgeDetailFolder
	end

	return ground
end

-- Creates water body below the map
-- @param center: Vector3 - Center of map
-- @param mapRadius: number - Map radius
-- @param waterHeight: number - Height of water surface
-- @return Part (water part)
function MapAssets.CreateWater(center, mapRadius, waterHeight)
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Shape = Enum.PartType.Block
	water.Size = Vector3.new(mapRadius * 3, 500, mapRadius * 3)
	water.Color = MapAssets.Colors.WATER
	water.Material = Enum.Material.SmoothPlastic
	water.CanCollide = false
	water.CanTouch = true
	water.CanQuery = true
	water.Transparency = 0.3
	water.Anchored = true
	water.CFrame = CFrame.new(center.X, waterHeight, center.Z)

	return water
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
