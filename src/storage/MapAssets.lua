-- MapAssets.lua
-- Simple map assets for "Survive a Helicopter for Brainrots"
-- Creates a clean pathway, player bases, shop, and spawn area

local MapAssets = {}

-- Colors
MapAssets.Colors = {
	FLOOR = Color3.fromRGB(90, 90, 90),           -- Gray floor
	FLOOR_EDGE = Color3.fromRGB(60, 60, 60),      -- Darker edge
	BASE_PAD = Color3.fromRGB(120, 120, 140),     -- Light gray-blue base pad
	BASE_BORDER = Color3.fromRGB(80, 160, 255),   -- Blue border on bases
	SPAWN_PAD = Color3.fromRGB(80, 200, 80),      -- Green spawn
	SHOP_WALLS = Color3.fromRGB(200, 180, 140),   -- Tan/beige shop
	SHOP_ROOF = Color3.fromRGB(150, 60, 60),      -- Red roof
	SIGN_COLOR = Color3.fromRGB(255, 255, 255),   -- White signs
}

-- Helper: create a simple part
local function MakePart(name, size, color, material, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.CFrame = CFrame.new(position)
	return part
end

-- ===== MAIN PATHWAY =====
-- A simple solid platform, 200 long x 40 wide
function MapAssets.CreatePathway(center)
	local pathway = Instance.new("Model")
	pathway.Name = "Pathway"

	-- ONE solid floor part - no holes possible
	local floor = MakePart(
		"PathwayFloor",
		Vector3.new(40, 4, 200),
		MapAssets.Colors.FLOOR,
		Enum.Material.Concrete,
		center
	)
	floor.Parent = pathway

	-- Simple edge lines (thin strips on top, decorative only)
	local leftEdge = MakePart(
		"LeftEdge",
		Vector3.new(1, 0.5, 200),
		MapAssets.Colors.BASE_BORDER,
		Enum.Material.SmoothPlastic,
		center + Vector3.new(-19.5, 2.25, 0)
	)
	leftEdge.Parent = pathway

	local rightEdge = MakePart(
		"RightEdge",
		Vector3.new(1, 0.5, 200),
		MapAssets.Colors.BASE_BORDER,
		Enum.Material.SmoothPlastic,
		center + Vector3.new(19.5, 2.25, 0)
	)
	rightEdge.Parent = pathway

	return pathway
end

-- ===== PLAYER BASE =====
-- A simple flat square pad with a border ring
-- Has HexagonalFloor folder with HexSegment_1 (for BaseSystem compatibility)
-- Has FloatingBrainrotDisplay folder with FloatingPlatform (for BaseSystem compatibility)
function MapAssets.CreatePlayerBase(position, baseIndex, pathwayCenter)
	local base = Instance.new("Model")
	base.Name = "PlayerBase_" .. baseIndex
	base:SetAttribute("BaseIndex", baseIndex)

	-- Main base pad - ONE solid part, no gaps
	local pad = MakePart(
		"BasePad",
		Vector3.new(18, 1, 18),
		MapAssets.Colors.BASE_PAD,
		Enum.Material.SmoothPlastic,
		position + Vector3.new(0, 2.5, 0)
	)
	pad.Parent = base

	-- Blue border around the pad (4 thin strips)
	local borderThickness = 0.5
	local borders = {
		{name = "BorderFront", size = Vector3.new(18, 0.5, borderThickness), offset = Vector3.new(0, 3, 9)},
		{name = "BorderBack",  size = Vector3.new(18, 0.5, borderThickness), offset = Vector3.new(0, 3, -9)},
		{name = "BorderLeft",  size = Vector3.new(borderThickness, 0.5, 18), offset = Vector3.new(-9, 3, 0)},
		{name = "BorderRight", size = Vector3.new(borderThickness, 0.5, 18), offset = Vector3.new(9, 3, 0)},
	}
	for _, b in ipairs(borders) do
		local border = MakePart(b.name, b.size, MapAssets.Colors.BASE_BORDER, Enum.Material.SmoothPlastic, position + b.offset)
		border.Parent = base
	end

	-- HexagonalFloor folder (BaseSystem looks for this)
	local hexFloor = Instance.new("Folder")
	hexFloor.Name = "HexagonalFloor"
	hexFloor.Parent = base

	-- HexSegment_1 is just the main pad reference (BaseSystem uses its position)
	local hexRef = MakePart(
		"HexSegment_1",
		Vector3.new(1, 1, 1),
		MapAssets.Colors.BASE_PAD,
		Enum.Material.SmoothPlastic,
		position + Vector3.new(0, 2.5, 0)
	)
	hexRef.Transparency = 1
	hexRef.CanCollide = false
	hexRef.Parent = hexFloor

	-- FloatingBrainrotDisplay folder (BaseSystem looks for this)
	local displayFolder = Instance.new("Folder")
	displayFolder.Name = "FloatingBrainrotDisplay"
	displayFolder.Parent = base

	local floatingPlatform = MakePart(
		"FloatingPlatform",
		Vector3.new(1, 1, 1),
		MapAssets.Colors.BASE_PAD,
		Enum.Material.SmoothPlastic,
		position + Vector3.new(0, 5, 0)
	)
	floatingPlatform.Transparency = 1
	floatingPlatform.CanCollide = false
	floatingPlatform.Parent = displayFolder

	-- Base number label
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BaseLabel"
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 100
	billboard.Parent = pad

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Base " .. baseIndex
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = billboard

	return base
end

-- ===== SHOP =====
-- Simple building at the end of the pathway
function MapAssets.CreateShop(position)
	local shop = Instance.new("Model")
	shop.Name = "ShopBuilding"

	-- Floor
	local floor = MakePart("ShopFloor", Vector3.new(20, 1, 20), MapAssets.Colors.FLOOR, Enum.Material.Concrete, position)
	floor.Parent = shop

	-- Walls (4 sides, with a gap in front for entrance)
	local wallHeight = 12
	local wallThickness = 1
	-- Back wall
	local backWall = MakePart("BackWall", Vector3.new(20, wallHeight, wallThickness), MapAssets.Colors.SHOP_WALLS, Enum.Material.SmoothPlastic, position + Vector3.new(0, wallHeight/2, -10))
	backWall.Parent = shop
	-- Left wall
	local leftWall = MakePart("LeftWall", Vector3.new(wallThickness, wallHeight, 20), MapAssets.Colors.SHOP_WALLS, Enum.Material.SmoothPlastic, position + Vector3.new(-10, wallHeight/2, 0))
	leftWall.Parent = shop
	-- Right wall
	local rightWall = MakePart("RightWall", Vector3.new(wallThickness, wallHeight, 20), MapAssets.Colors.SHOP_WALLS, Enum.Material.SmoothPlastic, position + Vector3.new(10, wallHeight/2, 0))
	rightWall.Parent = shop

	-- Roof
	local roof = MakePart("Roof", Vector3.new(22, 1, 22), MapAssets.Colors.SHOP_ROOF, Enum.Material.SmoothPlastic, position + Vector3.new(0, wallHeight + 0.5, 0))
	roof.Parent = shop

	-- Shop sign
	local signPart = MakePart("SignPart", Vector3.new(12, 3, 0.5), MapAssets.Colors.SIGN_COLOR, Enum.Material.SmoothPlastic, position + Vector3.new(0, wallHeight + 3, 10))
	signPart.Parent = shop

	local signBillboard = Instance.new("BillboardGui")
	signBillboard.Name = "ShopSign"
	signBillboard.Size = UDim2.new(0, 200, 0, 60)
	signBillboard.StudsOffset = Vector3.new(0, 0, 0)
	signBillboard.MaxDistance = 200
	signBillboard.Parent = signPart

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "SHOP"
	signText.TextColor3 = Color3.fromRGB(255, 220, 50)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.TextStrokeTransparency = 0
	signText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	signText.Parent = signBillboard

	return shop
end

-- ===== SPAWN AREA =====
-- Simple spawn pad at the start of the pathway
function MapAssets.CreateSpawnArea(position)
	local spawnArea = Instance.new("Model")
	spawnArea.Name = "SpawnArea"

	-- Spawn pad
	local pad = MakePart("SpawnPad", Vector3.new(20, 1, 20), MapAssets.Colors.SPAWN_PAD, Enum.Material.SmoothPlastic, position + Vector3.new(0, 2.5, 0))
	pad.Parent = spawnArea

	-- Actual SpawnLocation on top
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "GameSpawn"
	spawnLoc.Size = Vector3.new(18, 1, 18)
	spawnLoc.Color = MapAssets.Colors.SPAWN_PAD
	spawnLoc.Material = Enum.Material.SmoothPlastic
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = true
	spawnLoc.CFrame = CFrame.new(position + Vector3.new(0, 3.5, 0))
	spawnLoc.Transparency = 0.5
	spawnLoc.Duration = 0
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.BottomSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = spawnArea

	-- Spawn sign
	local signPart = MakePart("SpawnSign", Vector3.new(1, 1, 1), MapAssets.Colors.SIGN_COLOR, Enum.Material.SmoothPlastic, position + Vector3.new(0, 8, 0))
	signPart.Transparency = 1
	signPart.CanCollide = false
	signPart.Parent = spawnArea

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 300, 0, 60)
	billboard.MaxDistance = 200
	billboard.Parent = signPart

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "SURVIVE A HELICOPTER FOR BRAINROTS"
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	text.Parent = billboard

	return spawnArea
end

return MapAssets
