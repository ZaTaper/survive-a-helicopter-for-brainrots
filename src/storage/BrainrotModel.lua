-- BrainrotModel.lua
-- Creates and manages brainrot visual models programmatically
-- Includes humanoid for pathfinding, visual effects based on tier
-- Professional design with unique shapes, particles, and menacing faces per tier

local BrainrotModel = {}

-- Size scale for different tiers (OP is largest)
local TIER_SIZES = {
	Common = 1.0,
	Uncommon = 1.2,
	Rare = 1.4,
	Epic = 1.7,
	Mythic = 2.0,
	Secret = 2.3,
	Celestial = 2.6,
	OP = 3.0,
}

-- Which tiers get a glowing effect (Mythic and above)
local GLOWING_TIERS = {
	Mythic = true,
	Secret = true,
	Celestial = true,
	OP = true,
}

-- Tier configuration for visual design
local TIER_DESIGNS = {
	Common = { hasSpikes = false, hasHorns = false, hasCrown = false, particleType = nil },
	Uncommon = { hasSpikes = false, hasHorns = false, hasCrown = false, particleType = nil },
	Rare = { hasSpikes = true, hasHorns = false, hasCrown = false, particleType = "sparkle" },
	Epic = { hasSpikes = true, hasHorns = false, hasCrown = false, particleType = "purple" },
	Mythic = { hasSpikes = true, hasHorns = true, hasCrown = false, particleType = "fire" },
	Secret = { hasSpikes = true, hasHorns = true, hasCrown = false, particleType = "gold" },
	Celestial = { hasSpikes = true, hasHorns = true, hasCrown = true, particleType = "cosmic" },
	OP = { hasSpikes = true, hasHorns = true, hasCrown = true, particleType = "multieffect" },
}

-- Helper function to create eyes with pupils and glow
local function CreateEyes(brainrot, head, sizeMultiplier, tierConfig, tierName)
	for i = 1, 2 do
		local eyeOffset = Vector3.new((i == 1 and -0.5 or 0.5) * sizeMultiplier, 0.4 * sizeMultiplier, 0.7 * sizeMultiplier)

		-- Main eye (white)
		local eye = Instance.new("Part")
		eye.Name = "Eye" .. i
		eye.Shape = Enum.PartType.Ball
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Size = Vector3.new(0.4, 0.4, 0.4) * sizeMultiplier
		eye.CanCollide = false
		eye.Anchored = true
		eye.CFrame = head.CFrame + eyeOffset
		eye.Parent = brainrot

		-- Weld eye to head
		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = head
		eyeWeld.Part1 = eye
		eyeWeld.Parent = eye

		-- Pupil (colored, smaller, positioned forward)
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil" .. i
		pupil.Shape = Enum.PartType.Ball
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.Color = tierConfig.color
		pupil.Size = Vector3.new(0.15, 0.15, 0.15) * sizeMultiplier
		pupil.CanCollide = false
		pupil.Anchored = true
		pupil.CFrame = eye.CFrame + Vector3.new(0, 0, 0.2 * sizeMultiplier)
		pupil.Parent = brainrot

		-- Weld pupil to eye
		local pupilWeld = Instance.new("WeldConstraint")
		pupilWeld.Part0 = eye
		pupilWeld.Part1 = pupil
		pupilWeld.Parent = pupil
	end
end

-- Helper function to create jagged teeth for mouth
local function CreateTeeth(brainrot, head, sizeMultiplier, tierName)
	-- Reduce tooth count for higher tiers to stay under part limit
	local toothCount = 3
	if not string.find(tierName, "Common") and not string.find(tierName, "Uncommon") then
		toothCount = 4
	end
	local mouthCFrame = head.CFrame + Vector3.new(0, -0.5 * sizeMultiplier, 0.6 * sizeMultiplier)

	for t = 1, toothCount do
		local toothOffset = (t - toothCount/2 - 0.5) * 0.25 * sizeMultiplier
		local tooth = Instance.new("Part")
		tooth.Name = "Tooth" .. t
		tooth.Shape = Enum.PartType.Wedge
		tooth.Material = Enum.Material.SmoothPlastic
		tooth.Color = Color3.fromRGB(255, 255, 255)
		tooth.Size = Vector3.new(0.15, 0.2, 0.1) * sizeMultiplier
		tooth.CanCollide = false
		tooth.Anchored = true
		tooth.CFrame = mouthCFrame * CFrame.new(toothOffset, 0, 0) * CFrame.Angles(0, 0, math.rad(45))
		tooth.Parent = brainrot

		-- Weld tooth to head
		local toothWeld = Instance.new("WeldConstraint")
		toothWeld.Part0 = head
		toothWeld.Part1 = tooth
		toothWeld.Parent = tooth
	end
end

-- Helper function to create spikes on shoulders for higher tiers
local function CreateShoulderSpikes(brainrot, body, sizeMultiplier)
	for side = 1, 2 do
		-- One prominent spike per shoulder
		local spikeOffset = Vector3.new(
			(side == 1 and -1.2 or 1.2) * sizeMultiplier,
			1.0 * sizeMultiplier,
			0
		)
		local s = Instance.new("Part")
		s.Name = "Spike_" .. side
		s.Shape = Enum.PartType.Wedge
		s.Material = Enum.Material.SmoothPlastic
		s.Color = Color3.fromRGB(200, 200, 200)
		s.Size = Vector3.new(0.4, 0.5, 0.4) * sizeMultiplier
		s.CanCollide = false
		s.Anchored = true
		s.CFrame = body.CFrame + spikeOffset
		s.Parent = brainrot

		local spikeWeld = Instance.new("WeldConstraint")
		spikeWeld.Part0 = body
		spikeWeld.Part1 = s
		spikeWeld.Parent = s
	end
end

-- Helper function to create horns on head
local function CreateHorns(brainrot, head, sizeMultiplier)
	for side = 1, 2 do
		local horn = Instance.new("Part")
		horn.Name = "Horn" .. side
		horn.Shape = Enum.PartType.Wedge
		horn.Material = Enum.Material.SmoothPlastic
		horn.Color = Color3.fromRGB(139, 69, 19)
		horn.Size = Vector3.new(0.3, 0.7, 0.3) * sizeMultiplier
		horn.CanCollide = false
		horn.Anchored = true
		horn.CFrame = head.CFrame + Vector3.new((side == 1 and -0.4 or 0.4) * sizeMultiplier, 0.8 * sizeMultiplier, 0)
		horn.Parent = brainrot

		local hornWeld = Instance.new("WeldConstraint")
		hornWeld.Part0 = head
		hornWeld.Part1 = horn
		hornWeld.Parent = horn
	end
end

-- Helper function to create a crown on head
local function CreateCrown(brainrot, head, sizeMultiplier)
	-- Single prominent crown part on top of head
	local crownPart = Instance.new("Part")
	crownPart.Name = "Crown"
	crownPart.Shape = Enum.PartType.Block
	crownPart.Material = Enum.Material.Neon
	crownPart.Color = Color3.fromRGB(255, 215, 0) -- Gold
	crownPart.Size = Vector3.new(0.5, 0.7, 0.5) * sizeMultiplier
	crownPart.CanCollide = false
	crownPart.Anchored = true
	local offset = Vector3.new(0, 1.1 * sizeMultiplier, 0)
	crownPart.CFrame = head.CFrame + offset
	crownPart.Parent = brainrot

	local crownWeld = Instance.new("WeldConstraint")
	crownWeld.Part0 = head
	crownWeld.Part1 = crownPart
	crownWeld.Parent = crownPart
end

-- Helper function to create particle emitters
local function CreateParticleEmitter(part, particleType, tierName)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Parent = part
	emitter.Enabled = true
	emitter.Rate = 20
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Speed = NumberRange.new(5, 10)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new(0.3, 0.1)

	if particleType == "sparkle" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
		emitter.Rate = 15
		emitter.Speed = NumberRange.new(3, 6)
	elseif particleType == "purple" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(200, 100, 255))
		emitter.Rate = 25
		emitter.Speed = NumberRange.new(5, 8)
	elseif particleType == "fire" then
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0)),
		})
		emitter.Rate = 30
		emitter.Speed = NumberRange.new(8, 15)
		emitter.Acceleration = Vector3.new(0, 10, 0)
	elseif particleType == "gold" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		emitter.Rate = 20
		emitter.Speed = NumberRange.new(4, 7)
	elseif particleType == "cosmic" then
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 255, 255)),
		})
		emitter.Rate = 25
		emitter.Speed = NumberRange.new(6, 12)
	elseif particleType == "multieffect" then
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 100)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255)),
		})
		emitter.Rate = 40
		emitter.Speed = NumberRange.new(10, 20)
		emitter.Lifetime = NumberRange.new(2.5, 3.5)
	end
end

--- Creates a new brainrot model with all necessary components
--- @param tierConfig table - Tier configuration from GameConfig
--- @param startPosition Vector3 - Where to spawn the brainrot
--- @return Instance - The brainrot model folder (parent of all parts)
function BrainrotModel.CreateBrainrotModel(tierConfig, startPosition)
	startPosition = startPosition or Vector3.new(0, 5, 0)

	-- Get size multiplier for this tier
	local sizeMultiplier = TIER_SIZES[tierConfig.name] or 1.0
	local tierDesign = TIER_DESIGNS[tierConfig.name] or {}

	-- Create main folder to hold all brainrot parts
	local brainrot = Instance.new("Folder")
	brainrot.Name = "Brainrot_" .. tierConfig.name
	brainrot.Parent = workspace

	-- Create humanoid for pathfinding and health management
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = tierConfig.health
	humanoid.Health = tierConfig.health
	humanoid.Parent = brainrot

	-- Create main body with shape based on tier
	local body = Instance.new("Part")
	body.Name = "Body"
	-- Higher tiers get more rounded, threatening shape
	if string.find(tierConfig.name, "Mythic") or string.find(tierConfig.name, "Secret") or string.find(tierConfig.name, "Celestial") or string.find(tierConfig.name, "OP") then
		body.Shape = Enum.PartType.Ball
	else
		body.Shape = Enum.PartType.Block
	end
	body.Material = Enum.Material.SmoothPlastic
	body.Color = tierConfig.color
	body.Size = Vector3.new(2.2, 3.5, 2.2) * sizeMultiplier
	body.CanCollide = true
	body.Anchored = true
	body.CFrame = CFrame.new(startPosition)
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = brainrot

	-- Create head (sphere, sized by tier)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Material = Enum.Material.SmoothPlastic
	head.Color = tierConfig.color
	head.Size = Vector3.new(1.8, 1.8, 1.8) * sizeMultiplier
	head.CanCollide = false
	head.Anchored = true
	head.CFrame = body.CFrame + Vector3.new(0, 2.8 * sizeMultiplier, 0)
	head.Parent = brainrot

	-- Weld head to body
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head

	-- Create professional eyes with pupils
	CreateEyes(brainrot, head, sizeMultiplier, tierConfig, tierConfig.name)

	-- Create menacing teeth/mouth
	CreateTeeth(brainrot, head, sizeMultiplier, tierConfig.name)

	-- Create shoulder spikes for Rare and above
	if tierDesign.hasSpikes then
		CreateShoulderSpikes(brainrot, body, sizeMultiplier)
	end

	-- Create horns for Mythic and above
	if tierDesign.hasHorns then
		CreateHorns(brainrot, head, sizeMultiplier)
	end

	-- Create crown for Celestial and OP
	if tierDesign.hasCrown then
		CreateCrown(brainrot, head, sizeMultiplier)
	end

	-- Create arms (cylinders on sides)
	for i = 1, 2 do
		local armOffset = Vector3.new((i == 1 and -1.6 or 1.6) * sizeMultiplier, 0.3 * sizeMultiplier, 0)
		local arm = Instance.new("Part")
		arm.Name = "Arm" .. i
		arm.Shape = Enum.PartType.Cylinder
		arm.Material = Enum.Material.SmoothPlastic
		arm.Color = tierConfig.color
		arm.Size = Vector3.new(0.6 * sizeMultiplier, 1.8 * sizeMultiplier, 0.6 * sizeMultiplier)
		arm.CanCollide = false
		arm.Anchored = true
		arm.CFrame = body.CFrame + armOffset
		arm.Rotation = Vector3.new(0, 0, 90)
		arm.Parent = brainrot

		local armWeld = Instance.new("WeldConstraint")
		armWeld.Part0 = body
		armWeld.Part1 = arm
		armWeld.Parent = arm
	end

	-- Create legs (wider stance for higher tiers)
	for i = 1, 2 do
		local legOffset = Vector3.new((i == 1 and -0.8 or 0.8) * sizeMultiplier, -1.8 * sizeMultiplier, 0)
		local leg = Instance.new("Part")
		leg.Name = "Leg" .. i
		leg.Shape = Enum.PartType.Block
		leg.Material = Enum.Material.SmoothPlastic
		leg.Color = tierConfig.color
		leg.Size = Vector3.new(0.6, 1.5, 0.6) * sizeMultiplier
		leg.CanCollide = false
		leg.Anchored = true
		leg.CFrame = body.CFrame + legOffset
		leg.Parent = brainrot

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

		local pointLight = Instance.new("PointLight")
		pointLight.Color = tierConfig.color
		pointLight.Brightness = 2.5
		pointLight.Range = 18 * sizeMultiplier
		pointLight.Parent = body
	end

	-- Add particle effects for Rare and above
	if tierDesign.particleType then
		CreateParticleEmitter(body, tierDesign.particleType, tierConfig.name)
	end

	-- Store tier info as attributes for easy access
	brainrot:SetAttribute("TierName", tierConfig.name)
	brainrot:SetAttribute("TierColor", tierConfig.color)
	brainrot:SetAttribute("SizeMultiplier", sizeMultiplier)
	brainrot:SetAttribute("IsGlowing", GLOWING_TIERS[tierConfig.name] == true)

	humanoid.Parent = brainrot

	-- Create name tag above head
	local nameTag = Instance.new("Part")
	nameTag.Name = "NameTag"
	nameTag.Shape = Enum.PartType.Block
	nameTag.Material = Enum.Material.Neon
	nameTag.Color = tierConfig.color
	nameTag.Size = Vector3.new(4 * sizeMultiplier, 1, 0.1)
	nameTag.CanCollide = false
	nameTag.Anchored = true
	nameTag.CFrame = head.CFrame + Vector3.new(0, 2.5 * sizeMultiplier, 0)
	nameTag.Parent = brainrot

	local nameTagWeld = Instance.new("WeldConstraint")
	nameTagWeld.Part0 = head
	nameTagWeld.Part1 = nameTag
	nameTagWeld.Parent = nameTag

	-- Add BillboardGui to name tag
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

	-- Unanchor all parts for physics simulation
	for _, part in ipairs(partsTable) do
		part.Anchored = false
	end

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
