-- BaseModel.lua
-- Creates and manages player base visuals
-- Integrates with redesigned bases from MapAssets with hexagonal floors, building pads, and floating displays

local BaseModel = {}

-- Color palette for distinct bases per player
local BASE_COLORS = {
	Color3.fromRGB(220, 100, 100), -- Red accent
	Color3.fromRGB(100, 150, 220), -- Blue accent
	Color3.fromRGB(100, 220, 120), -- Green accent
	Color3.fromRGB(220, 180, 100), -- Orange accent
	Color3.fromRGB(180, 100, 220), -- Purple accent
	Color3.fromRGB(100, 220, 220), -- Cyan accent
	Color3.fromRGB(220, 220, 100), -- Yellow accent
	Color3.fromRGB(180, 180, 180), -- Silver accent
}

-- Helper function defined before use: Get a distinct color for a player
-- @param player Player - The player
-- @return Color3 - A color for this player's base accent
local function GetPlayerColor(player)
	local colorIndex = (player.UserId % #BASE_COLORS) + 1
	return BASE_COLORS[colorIndex]
end

-- Create a player name billboard display (shown when player joins)
-- @param position Vector3 - Position above the base
-- @param playerName string - Name of the player
-- @param accentColor Color3 - Accent color for this base
-- @return Part - The nameplate part with billboard GUI
local function CreateNameDisplay(position, playerName, accentColor)
	local namePart = Instance.new("Part")
	namePart.Name = "NameDisplay"
	namePart.Size = Vector3.new(1, 1, 1)
	namePart.Transparency = 1
	namePart.CanCollide = false
	namePart.Anchored = true
	namePart.CFrame = CFrame.new(position)

	-- Billboard GUI for player's base name
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BaseNameBillboard"
	billboard.Size = UDim2.new(0, 300, 0, 80)
	billboard.MaxDistance = 150
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = namePart

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "BaseNameLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.BackgroundTransparency = 0.3
	textLabel.Text = playerName .. "'s Base"
	textLabel.TextColor3 = accentColor
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0.3
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Parent = billboard

	-- Glow light for the nameplate
	local light = Instance.new("PointLight")
	light.Color = accentColor
	light.Brightness = 1.5
	light.Range = 30
	light.Parent = namePart

	return namePart
end

-- Creates a base in the player workspace (not used for map generation, but available for on-demand creation)
-- @param player Player - The player who owns this base
-- @param position Vector3 - The center position for the base
-- @param mapCenter Vector3 - The center of the map (for direction calculation)
-- @return Instance - The base folder with all components
function BaseModel.CreateBase(player, position, mapCenter)
	-- Create main base container folder
	local baseContainer = Instance.new("Folder")
	baseContainer.Name = "PlayerBase_" .. player.Name
	baseContainer.Parent = workspace

	-- Get accent color for this player
	local accentColor = GetPlayerColor(player)

	-- Store metadata on the container
	baseContainer:SetAttribute("Owner", player.Name)
	baseContainer:SetAttribute("OwnerId", player.UserId)
	baseContainer:SetAttribute("AccentColor", accentColor)
	baseContainer:SetAttribute("CreatedAt", os.time())

	-- Add nameplate display above the base center
	local nameDisplay = CreateNameDisplay(
		position + Vector3.new(0, 8, 0),
		player.Name,
		accentColor
	)
	nameDisplay.Parent = baseContainer

	return baseContainer
end

-- Gets the base platform position (center of the hexagonal floor)
-- @param baseModel Instance - The base folder
-- @return Vector3 - The center position of the hexagonal floor
function BaseModel.GetBaseCenterPosition(baseModel)
	-- The base platform is at the center position
	-- This is used for various game mechanics
	for child in baseModel:GetChildren() do
		if child:IsA("Model") and child.Name == "HexagonalFloor" then
			-- Found the hexagonal floor folder
			-- The center is approximately at the first wedge's position
			local firstWedge = child:FindFirstChild("HexSegment_1")
			if firstWedge then
				return firstWedge.Position
			end
		end
	end
	if baseModel.Parent then
		return baseModel.Parent.Position
	else
		return Vector3.new(0, 0, 0)
	end
end

-- Gets the helicopter building pad position
-- @param baseModel Instance - The base folder
-- @return Vector3 - The center position of the building pad
function BaseModel.GetBuildingPadPosition(baseModel)
	for child in baseModel:GetChildren() do
		if child:IsA("Folder") and child.Name == "HelicopterBuildingPad" then
			local buildPad = child:FindFirstChild("BuildPad")
			if buildPad then
				return buildPad.Position + Vector3.new(0, 1, 0)
			end
		end
	end
	return nil
end

-- Gets the floating brainrot display area position
-- @param baseModel Instance - The base folder
-- @return Vector3 - The center position of the floating display platform
function BaseModel.GetFloatingDisplayPosition(baseModel)
	for child in baseModel:GetChildren() do
		if child:IsA("Folder") and child.Name == "FloatingBrainrotDisplay" then
			local floatingPlatform = child:FindFirstChild("FloatingPlatform")
			if floatingPlatform then
				return floatingPlatform.Position
			end
		end
	end
	return nil
end

-- Gets all display pedestals in the floating display area
-- @param baseModel Instance - The base folder
-- @return table - Array of pedestals {part=Part, index=number}
function BaseModel.GetDisplayPedestals(baseModel)
	local pedestals = {}

	for child in baseModel:GetChildren() do
		if child:IsA("Folder") and child.Name == "FloatingBrainrotDisplay" then
			local pedestalsFolder = child:FindFirstChild("DisplayPedestals")
			if pedestalsFolder then
				for pedestal in pedestalsFolder:GetChildren() do
					if pedestal:IsA("Part") and pedestal.Name:match("^Pedestal_") then
						local index = pedestal:GetAttribute("SlotIndex") or 1
						table.insert(pedestals, {part = pedestal, index = index})
					end
				end
			end
		end
	end

	-- Sort by index
	table.sort(pedestals, function(a, b) return a.index < b.index end)
	return pedestals
end

-- Destroys a base completely
-- @param baseModel Instance - The base folder to destroy
function BaseModel.DestroyBase(baseModel)
	if baseModel and baseModel.Parent then
		baseModel:Destroy()
	end
end

return BaseModel
