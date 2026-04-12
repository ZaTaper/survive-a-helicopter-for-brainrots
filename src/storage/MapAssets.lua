-- MapAssets.lua
-- Utility module for creating map decorative elements and structures
-- Provides functions to create trees, rocks, buildings, barriers, and safe zones

local MapAssets = {}

-- Material and color constants
MapAssets.Colors = {
	GROUND = Color3.fromRGB(80, 120, 60),      -- Dark green grass
	SAFE_ZONE = Color3.fromRGB(100, 255, 100), -- Bright green
	BUILD_AREA = Color3.fromRGB(255, 200, 100), -- Orange
	DANGER_ZONE = Color3.fromRGB(200, 60, 60),  -- Red
	TREE_BARK = Color3.fromRGB(101, 67, 33),   -- Brown
	TREE_FOLIAGE = Color3.fromRGB(34, 139, 34), -- Forest green
	ROCK = Color3.fromRGB(128, 128, 128),       -- Gray
	BUILDING = Color3.fromRGB(180, 140, 100),   -- Tan
	BARRIER = Color3.fromRGB(100, 100, 100),    -- Dark gray
	SAFE_ZONE_GLOW = Color3.fromRGB(200, 255, 200), -- Light glow
}

MapAssets.Materials = {
	GRASS = Enum.Material.Grass,
	CONCRETE = Enum.Material.Concrete,
	WOOD = Enum.Material.Wood,
	ROCK = Enum.Material.Rock,
	NEON = Enum.Material.Neon,
}

-- Creates a simple tree from parts
-- @param position: Vector3 - Position to place tree
-- @return Model with tree structure
function MapAssets.CreateTree(position)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	tree.Parent = workspace

	-- Trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(3, 12, 3)
	trunk.Color = MapAssets.Colors.TREE_BARK
	trunk.Material = MapAssets.Materials.WOOD
	trunk.CanCollide = true
	trunk.CFrame = CFrame.new(position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = tree

	-- Foliage (sphere)
	local foliage = Instance.new("Part")
	foliage.Name = "Foliage"
	foliage.Shape = Enum.PartType.Ball
	foliage.Size = Vector3.new(15, 15, 15)
	foliage.Color = MapAssets.Colors.TREE_FOLIAGE
	foliage.Material = Enum.Material.Grass
	foliage.CanCollide = false
	foliage.CFrame = CFrame.new(position + Vector3.new(0, 18, 0))
	foliage.Parent = tree

	-- Weld parts together
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = trunk
	weld.Part1 = foliage
	weld.Parent = foliage

	return tree
end

-- Creates a random rock formation
-- @param position: Vector3 - Position to place rock
-- @return Part (single rock piece)
function MapAssets.CreateRock(position)
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Shape = Enum.PartType.Ball

	-- Randomize size
	local size = math.random(3, 8)
	rock.Size = Vector3.new(size, size, size)
	rock.Color = MapAssets.Colors.ROCK
	rock.Material = MapAssets.Materials.ROCK
	rock.CanCollide = true
	rock.CFrame = CFrame.new(position + Vector3.new(
		math.random(-5, 5),
		size / 2,
		math.random(-5, 5)
	))
	rock.Parent = workspace

	return rock
end

-- Creates a simple building structure
-- @param position: Vector3 - Position to place building
-- @return Model with building parts
function MapAssets.CreateBuilding(position)
	local building = Instance.new("Model")
	building.Name = "Building"
	building.Parent = workspace

	-- Main structure
	local walls = Instance.new("Part")
	walls.Name = "Walls"
	walls.Size = Vector3.new(20, 20, 20)
	walls.Color = MapAssets.Colors.BUILDING
	walls.Material = MapAssets.Materials.CONCRETE
	walls.CanCollide = true
	walls.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
	walls.Parent = building

	-- Roof
	local roof = Instance.new("WedgePart")
	roof.Name = "Roof"
	roof.Size = Vector3.new(20, 10, 20)
	roof.Color = Color3.fromRGB(139, 69, 19) -- Brown roof
	roof.Material = Enum.Material.Wood
	roof.CanCollide = true
	roof.CFrame = CFrame.new(position + Vector3.new(0, 25, 0))
	roof.Parent = building

	-- Door opening
	local door = Instance.new("Part")
	door.Name = "DoorFrame"
	door.Size = Vector3.new(4, 8, 1)
	door.Color = Color3.fromRGB(101, 67, 33)
	door.Material = MapAssets.Materials.WOOD
	door.CanCollide = false
	door.CFrame = CFrame.new(position + Vector3.new(10, 8, 10.5))
	door.Parent = building

	return building
end

-- Creates a barrier/wall piece
-- @param position: Vector3 - Position to place barrier
-- @param size: Vector3 - Size of barrier
-- @return Part (barrier piece)
function MapAssets.CreateBarrier(position, size)
	local barrier = Instance.new("Part")
	barrier.Name = "Barrier"
	barrier.Size = size
	barrier.Color = MapAssets.Colors.BARRIER
	barrier.Material = MapAssets.Materials.CONCRETE
	barrier.CanCollide = true
	barrier.CFrame = CFrame.new(position)
	barrier.Parent = workspace

	return barrier
end

-- Creates a glowing safe zone indicator
-- @param center: Vector3 - Center of safe zone
-- @param radius: number - Radius of safe zone
-- @return Model with zone indicator
function MapAssets.CreateSafeZone(center, radius)
	local safeZone = Instance.new("Model")
	safeZone.Name = "SafeZone"
	safeZone.Parent = workspace

	-- Outer ring (visual boundary)
	local ringSegments = 32
	for i = 1, ringSegments do
		local angle1 = (i - 1) / ringSegments * math.pi * 2
		local angle2 = i / ringSegments * math.pi * 2

		local pos1 = center + Vector3.new(math.cos(angle1) * radius, 0.5, math.sin(angle1) * radius)
		local pos2 = center + Vector3.new(math.cos(angle2) * radius, 0.5, math.sin(angle2) * radius)
		local midPos = (pos1 + pos2) / 2

		local ringPart = Instance.new("Part")
		ringPart.Name = "SafeZoneRing"
		ringPart.Size = Vector3.new(radius / 16, 1, radius / 16)
		ringPart.Color = MapAssets.Colors.SAFE_ZONE_GLOW
		ringPart.Material = MapAssets.Materials.NEON
		ringPart.CanCollide = false
		ringPart.CFrame = CFrame.new(midPos)
		ringPart.Parent = safeZone
	end

	-- Center glowing part
	local centerGlow = Instance.new("Part")
	centerGlow.Name = "SafeZoneCenter"
	centerGlow.Shape = Enum.PartType.Ball
	centerGlow.Size = Vector3.new(radius * 0.1, radius * 0.1, radius * 0.1)
	centerGlow.Color = MapAssets.Colors.SAFE_ZONE
	centerGlow.Material = MapAssets.Materials.NEON
	centerGlow.CanCollide = false
	centerGlow.CFrame = CFrame.new(center + Vector3.new(0, 5, 0))
	centerGlow.Parent = safeZone

	-- Marker surface (ground level indicator)
	local marker = Instance.new("Part")
	marker.Name = "SafeZoneMarker"
	marker.Size = Vector3.new(radius * 2, 0.5, radius * 2)
	marker.Color = MapAssets.Colors.SAFE_ZONE
	marker.Material = Enum.Material.Grass
	marker.CanCollide = false
	marker.CFrame = CFrame.new(center + Vector3.new(0, 0.25, 0))
	marker.Parent = safeZone

	return safeZone
end

-- Creates the build zone ring indicator
-- @param center: Vector3 - Center of build zone
-- @param innerRadius: number - Inner radius (safe zone edge)
-- @param outerRadius: number - Outer radius (danger zone edge)
-- @return Model with zone indicator
function MapAssets.CreateBuildZone(center, innerRadius, outerRadius)
	local buildZone = Instance.new("Model")
	buildZone.Name = "BuildZone"
	buildZone.Parent = workspace

	-- Ring surface
	local ringSegments = 48
	local ringWidth = (outerRadius - innerRadius) / 4

	for i = 1, ringSegments do
		local angle1 = (i - 1) / ringSegments * math.pi * 2
		local angle2 = i / ringSegments * math.pi * 2

		local midAngle = (angle1 + angle2) / 2
		local midRadius = (innerRadius + outerRadius) / 2

		local pos = center + Vector3.new(math.cos(midAngle) * midRadius, 0.25, math.sin(midAngle) * midRadius)

		local ringPart = Instance.new("Part")
		ringPart.Name = "BuildZoneIndicator"
		ringPart.Size = Vector3.new(ringWidth, 0.5, (outerRadius - innerRadius) / 4)
		ringPart.Color = MapAssets.Colors.BUILD_AREA
		ringPart.Material = Enum.Material.Grass
		ringPart.CanCollide = false
		ringPart.CFrame = CFrame.new(pos) * CFrame.Angles(0, midAngle, 0)
		ringPart.Parent = buildZone
	end

	return buildZone
end

-- Creates ground/terrain with zone coloring
-- @param center: Vector3 - Center of map
-- @param safeZoneRadius: number - Radius of safe zone
-- @param buildZoneRadius: number - Radius of build zone
-- @param mapRadius: number - Total map radius
-- @return Model with ground parts
function MapAssets.CreateGround(center, safeZoneRadius, buildZoneRadius, mapRadius)
	local ground = Instance.new("Model")
	ground.Name = "Ground"
	ground.Parent = workspace

	-- Safe zone (innermost)
	local safeGroundPart = Instance.new("Part")
	safeGroundPart.Name = "SafeZoneGround"
	safeGroundPart.Shape = Enum.PartType.Ball
	safeGroundPart.Size = Vector3.new(safeZoneRadius * 2, 1, safeZoneRadius * 2)
	safeGroundPart.Color = MapAssets.Colors.SAFE_ZONE
	safeGroundPart.Material = Enum.Material.Grass
	safeGroundPart.CanCollide = true
	safeGroundPart.TopSurface = Enum.SurfaceType.Smooth
	safeGroundPart.BottomSurface = Enum.SurfaceType.Smooth
	safeGroundPart.CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0))
	safeGroundPart.Parent = ground

	-- Build zone (middle ring)
	local buildGroundPart = Instance.new("Part")
	buildGroundPart.Name = "BuildZoneGround"
	buildGroundPart.Size = Vector3.new(buildZoneRadius * 2, 1, buildZoneRadius * 2)
	buildGroundPart.Color = MapAssets.Colors.BUILD_AREA
	buildGroundPart.Material = Enum.Material.Grass
	buildGroundPart.CanCollide = true
	buildGroundPart.TopSurface = Enum.SurfaceType.Smooth
	buildGroundPart.BottomSurface = Enum.SurfaceType.Smooth
	buildGroundPart.CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0))
	buildGroundPart.Parent = ground

	-- Danger zone (outer ring)
	local dangerGroundPart = Instance.new("Part")
	dangerGroundPart.Name = "DangerZoneGround"
	dangerGroundPart.Size = Vector3.new(mapRadius * 2, 1, mapRadius * 2)
	dangerGroundPart.Color = MapAssets.Colors.DANGER_ZONE
	dangerGroundPart.Material = Enum.Material.Grass
	dangerGroundPart.CanCollide = true
	dangerGroundPart.TopSurface = Enum.SurfaceType.Smooth
	dangerGroundPart.BottomSurface = Enum.SurfaceType.Smooth
	dangerGroundPart.CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0))
	dangerGroundPart.Parent = ground

	return ground
end

return MapAssets
