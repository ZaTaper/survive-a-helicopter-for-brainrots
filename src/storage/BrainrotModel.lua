-- BrainrotModel.lua
-- Creates and manages brainrot visual models programmatically
-- Includes humanoid for pathfinding, visual effects based on tier

local BrainrotModel = {}

-- Size scale for different tiers (OP is largest)
local TIER_SIZES = {
	Common = 1.0,
	Uncommon = 1.15,
	Rare = 1.3,
	Epic = 1.5,
	Mythic = 1.8,
	Secret = 2.1,
	Celestial = 2.4,
	OP = 2.8,
}

-- Which tiers get a glowing effect (Mythic and above)
local GLOWING_TIERS = {
	Mythic = true,
	Secret = true,
	Celestial = true,
	OP = true,
}

--- Creates a new brainrot model with all necessary components
--- @param tierConfig table - Tier configuration from GameConfig
--- @param startPosition Vector3 - Where to spawn the brainrot
--- @return Instance - The brainrot model folder (parent of all parts)
function BrainrotModel.CreateBrainrotModel(tierConfig, startPosition)
	startPosition = startPosition or Vector3.new(0, 5, 0)

	-- Get size multiplier for this tier
	local sizeMultiplier = TIER_SIZES[tierConfig.name] or 1.0

	-- Create main folder to hold all brainrot parts
	local brainrot = Instance.new("Folder")
	brainrot.Name = "Brainrot_" .. tierConfig.name
	brainrot.Parent = workspace

	-- Create humanoid for pathfinding and health management
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = tierConfig.health
	humanoid.Health = tierConfig.health
	humanoid.Parent = brainrot

	-- Create main body (cube, scaled by tier)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Material = Enum.Material.SmoothPlastic
	body.Color = tierConfig.color
	body.Size = Vector3.new(2, 3, 2) * sizeMultiplier
	body.CanCollide = true
	body.CFrame = CFrame.new(startPosition)
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = brainrot

	-- Create head (sphere on top, sized by tier)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Material = Enum.Material.SmoothPlastic
	head.Color = tierConfig.color
	head.Size = Vector3.new(1.5, 1.5, 1.5) * sizeMultiplier
	head.CanCollide = false
	head.CFrame = body.CFrame + Vector3.new(0, 2.5 * sizeMultiplier, 0)
	head.Parent = brainrot

	-- Weld head to body
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head

	-- Create eyes (two small spheres on head)
	for i = 1, 2 do
		local eyeOffset = Vector3.new((i == 1 and -0.4 or 0.4) * sizeMultiplier, 0.3 * sizeMultiplier, 0.6 * sizeMultiplier)
		local eye = Instance.new("Part")
		eye.Name = "Eye" .. i
		eye.Shape = Enum.PartType.Ball
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.fromRGB(255, 255, 255) -- White eyes
		eye.Size = Vector3.new(0.3, 0.3, 0.3) * sizeMultiplier
		eye.CanCollide = false
		eye.CFrame = head.CFrame + eyeOffset
		eye.Parent = brainrot

		-- Weld eye to head
		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = head
		eyeWeld.Part1 = eye
		eyeWeld.Parent = eye
	end

	-- Create mouth (small red part) - gives it a menacing look
	local mouth = Instance.new("Part")
	mouth.Name = "Mouth"
	mouth.Shape = Enum.PartType.Block
	mouth.Material = Enum.Material.SmoothPlastic
	mouth.Color = Color3.fromRGB(200, 0, 0) -- Red mouth
	mouth.Size = Vector3.new(0.6, 0.2, 0.1) * sizeMultiplier
	mouth.CanCollide = false
	mouth.CFrame = head.CFrame + Vector3.new(0, -0.4 * sizeMultiplier, 0.5 * sizeMultiplier)
	mouth.Parent = brainrot

	-- Weld mouth to head
	local mouthWeld = Instance.new("WeldConstraint")
	mouthWeld.Part0 = head
	mouthWeld.Part1 = mouth
	mouthWeld.Parent = mouth

	-- Create arms (two cylinders on sides)
	for i = 1, 2 do
		local armOffset = Vector3.new((i == 1 and -1.5 or 1.5) * sizeMultiplier, 0.5 * sizeMultiplier, 0)
		local arm = Instance.new("Part")
		arm.Name = "Arm" .. i
		arm.Shape = Enum.PartType.Cylinder
		arm.Material = Enum.Material.SmoothPlastic
		arm.Color = tierConfig.color
		arm.Size = Vector3.new(0.6 * sizeMultiplier, 1.5 * sizeMultiplier, 0.6 * sizeMultiplier)
		arm.CanCollide = false
		arm.CFrame = body.CFrame + armOffset
		arm.Rotation = Vector3.new(0, 0, 90)
		arm.Parent = brainrot

		-- Weld arm to body
		local armWeld = Instance.new("WeldConstraint")
		armWeld.Part0 = body
		armWeld.Part1 = arm
		armWeld.Parent = arm
	end

	-- Create legs (two small blocks at bottom)
	for i = 1, 2 do
		local legOffset = Vector3.new((i == 1 and -0.6 or 0.6) * sizeMultiplier, -1.5 * sizeMultiplier, 0)
		local leg = Instance.new("Part")
		leg.Name = "Leg" .. i
		leg.Shape = Enum.PartType.Block
		leg.Material = Enum.Material.SmoothPlastic
		leg.Color = tierConfig.color
		leg.Size = Vector3.new(0.5, 1.2, 0.5) * sizeMultiplier
		leg.CanCollide = false
		leg.CFrame = body.CFrame + legOffset
		leg.Parent = brainrot

		-- Weld leg to body
		local legWeld = Instance.new("WeldConstraint")
		legWeld.Part0 = body
		legWeld.Part1 = leg
		legWeld.Parent = leg
	end

	-- Add BodyVelocity for movement
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.P = 10000
	bodyVelocity.Parent = body

	-- Add glowing effect for Mythic+ tiers
	if GLOWING_TIERS[tierConfig.name] then
		body.Material = Enum.Material.Neon
		head.Material = Enum.Material.Neon

		-- Add surface glow with PointLight for extra effect
		local pointLight = Instance.new("PointLight")
		pointLight.Color = tierConfig.color
		pointLight.Brightness = 2
		pointLight.Range = 15 * sizeMultiplier
		pointLight.Parent = body
	end

	-- Store tier info as attributes for easy access
	brainrot:SetAttribute("TierName", tierConfig.name)
	brainrot:SetAttribute("TierColor", tierConfig.color)
	brainrot:SetAttribute("SizeMultiplier", sizeMultiplier)
	brainrot:SetAttribute("IsGlowing", GLOWING_TIERS[tierConfig.name] == true)

	-- Add a humanoid for pathfinding to work properly
	-- (we already created it above, but let's make sure body is set)
	humanoid.Parent = brainrot

	-- Create name tag above head showing tier and display name
	-- This will be updated by the server system
	local nameTag = Instance.new("Part")
	nameTag.Name = "NameTag"
	nameTag.Shape = Enum.PartType.Block
	nameTag.Material = Enum.Material.Neon
	nameTag.Color = tierConfig.color
	nameTag.Size = Vector3.new(4 * sizeMultiplier, 1, 0.1)
	nameTag.CanCollide = false
	nameTag.CFrame = head.CFrame + Vector3.new(0, 2.5 * sizeMultiplier, 0)
	nameTag.Parent = brainrot

	-- Weld name tag to head
	local nameTagWeld = Instance.new("WeldConstraint")
	nameTagWeld.Part0 = head
	nameTagWeld.Part1 = nameTag
	nameTagWeld.Parent = nameTag

	-- Add BillboardGui to name tag for actual text
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(4, 0, 1, 0)
	billboardGui.MaxDistance = 100
	billboardGui.Parent = nameTag

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = tierConfig.name
	textLabel.TextColor3 = tierConfig.color
	textLabel.TextSize = 14 * sizeMultiplier
	textLabel.TextWrapped = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = billboardGui

	-- Store all parts in attributes for easy cleanup
	local partsTable = {}
	for _, part in ipairs(brainrot:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(partsTable, part)
		end
	end
	brainrot:SetAttribute("AllParts", partsTable)

	return brainrot
end

--- Update the nameTag of a brainrot to show its display name and tier
--- @param brainrotModel Instance - The brainrot model folder
--- @param displayName string - The display name to show
--- @param tierName string - The tier name for formatting
function BrainrotModel.UpdateNameTag(brainrotModel, displayName, tierName)
	local nameTag = brainrotModel:FindFirstChild("NameTag")
	if nameTag then
		local billboardGui = nameTag:FindFirstChildOfClass("BillboardGui")
		if billboardGui then
			local textLabel = billboardGui:FindFirstChild("TextLabel")
			if textLabel then
				textLabel.Text = displayName .. "\n[" .. tierName .. "]"
			end
		end
	end
end

--- Clean up a brainrot model (disconnect welds, destroy parts)
--- @param brainrotModel Instance - The brainrot model to clean up
function BrainrotModel.CleanupBrainrot(brainrotModel)
	if not brainrotModel or not brainrotModel.Parent then
		return
	end

	-- Disconnect all welds
	for _, weld in ipairs(brainrotModel:FindFirstChild("Humanoid") and {brainrotModel:FindFirstChild("Humanoid")} or {}) do
		if weld:IsA("WeldConstraint") then
			weld:Destroy()
		end
	end

	-- Remove BodyVelocity
	local body = brainrotModel:FindFirstChild("Body")
	if body then
		local bodyVelocity = body:FindFirstChildOfClass("BodyVelocity")
		if bodyVelocity then
			bodyVelocity:Destroy()
		end

		local pointLight = body:FindFirstChildOfClass("PointLight")
		if pointLight then
			pointLight:Destroy()
		end
	end

	-- Destroy the entire model
	brainrotModel:Destroy()
end

--- Update brainrot health visually
--- @param brainrotModel Instance - The brainrot model
--- @param currentHealth number - Current health value
--- @param maxHealth number - Maximum health
function BrainrotModel.UpdateHealthVisual(brainrotModel, currentHealth, maxHealth)
	local body = brainrotModel:FindFirstChild("Body")
	if not body then
		return
	end

	-- Darken the brainrot as health decreases
	local healthPercent = currentHealth / maxHealth
	local tierColor = brainrotModel:GetAttribute("TierColor")

	if tierColor then
		-- Interpolate between tier color and darker version
		local darkerColor = Color3.new(
			tierColor.R * healthPercent,
			tierColor.G * healthPercent,
			tierColor.B * healthPercent
		)
		body.Color = darkerColor

		local head = brainrotModel:FindFirstChild("Head")
		if head then
			head.Color = darkerColor
		end
	end
end

return BrainrotModel
