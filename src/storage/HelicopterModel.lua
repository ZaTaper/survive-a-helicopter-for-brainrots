-- HelicopterModel.lua
-- Creates and manages the visual helicopter model
-- Parts are created programmatically and updated based on engines/fuel canisters
-- Helicopter features: fuselage body, tail section, spinning rotor, visible engines

local HelicopterModel = {}

--- Creates a new helicopter model with customizable engines and fuel canisters
--- @param parent Instance - Parent instance to place helicopter in
--- @param numEngines number - Number of engines to display
--- @param numFuelCanisters number - Number of fuel canisters to display
--- @return Instance - The helicopter model folder
function HelicopterModel.CreateHelicopter(parent, numEngines, numFuelCanisters)
	numEngines = numEngines or 0
	numFuelCanisters = numFuelCanisters or 0

	-- Create main folder to hold all helicopter parts
	local helicopter = Instance.new("Folder")
	helicopter.Name = "Helicopter"
	helicopter.Parent = parent

	-- FUSELAGE (Main body) - streamlined and sleek
	local fuselage = Instance.new("Part")
	fuselage.Name = "Fuselage"
	fuselage.Shape = Enum.PartType.Block
	fuselage.Material = Enum.Material.SmoothPlastic
	fuselage.Color = Color3.fromRGB(240, 245, 250) -- White/light blue
	fuselage.Size = Vector3.new(2, 2.5, 14)
	fuselage.CanCollide = false
	fuselage.Anchored = true
	fuselage.CFrame = CFrame.new(0, 0, 0)
	fuselage.TopSurface = Enum.SurfaceType.Smooth
	fuselage.BottomSurface = Enum.SurfaceType.Smooth
	fuselage.Parent = helicopter

	-- COCKPIT - front section with windows
	local cockpit = Instance.new("Part")
	cockpit.Name = "Cockpit"
	cockpit.Shape = Enum.PartType.Block
	cockpit.Material = Enum.Material.SmoothPlastic
	cockpit.Color = Color3.fromRGB(220, 235, 255) -- Light blue tint
	cockpit.Size = Vector3.new(2, 2, 2)
	cockpit.CanCollide = false
	cockpit.Anchored = true
	cockpit.CFrame = fuselage.CFrame * CFrame.new(0, 0, 6.5)
	cockpit.TopSurface = Enum.SurfaceType.Smooth
	cockpit.BottomSurface = Enum.SurfaceType.Smooth
	cockpit.Parent = helicopter

	-- Cockpit window (neon blue for cool look)
	local window = Instance.new("Part")
	window.Name = "Window"
	window.Shape = Enum.PartType.Block
	window.Material = Enum.Material.Neon
	window.Color = Color3.fromRGB(0, 150, 255) -- Bright blue
	window.Size = Vector3.new(1.2, 1.2, 0.4)
	window.CanCollide = false
	window.Anchored = true
	window.CFrame = cockpit.CFrame * CFrame.new(0, 0.3, 1.2)
	window.Parent = helicopter

	-- TAIL BOOM - horizontal support structure (replaces wings for helicopter design)
	local tailBoom = Instance.new("Part")
	tailBoom.Name = "TailBoom"
	tailBoom.Shape = Enum.PartType.Block
	tailBoom.Material = Enum.Material.SmoothPlastic
	tailBoom.Color = Color3.fromRGB(240, 245, 250)
	tailBoom.Size = Vector3.new(1, 1, 8)
	tailBoom.CanCollide = false
	tailBoom.Anchored = true
	tailBoom.CFrame = fuselage.CFrame * CFrame.new(-6, -0.3, -1) * CFrame.Angles(0, 0, math.rad(-5))
	tailBoom.TopSurface = Enum.SurfaceType.Smooth
	tailBoom.BottomSurface = Enum.SurfaceType.Smooth
	tailBoom.Parent = helicopter

	-- TAIL BOOM RIGHT - counterpart for balance
	local tailBoomRight = Instance.new("Part")
	tailBoomRight.Name = "TailBoomRight"
	tailBoomRight.Shape = Enum.PartType.Block
	tailBoomRight.Material = Enum.Material.SmoothPlastic
	tailBoomRight.Color = Color3.fromRGB(240, 245, 250)
	tailBoomRight.Size = Vector3.new(1, 1, 8)
	tailBoomRight.CanCollide = false
	tailBoomRight.Anchored = true
	tailBoomRight.CFrame = fuselage.CFrame * CFrame.new(6, -0.3, -1) * CFrame.Angles(0, 0, math.rad(5))
	tailBoomRight.TopSurface = Enum.SurfaceType.Smooth
	tailBoomRight.BottomSurface = Enum.SurfaceType.Smooth
	tailBoomRight.Parent = helicopter

	-- TAIL SECTION - vertical stabilizer
	local verticalStabilizer = Instance.new("Part")
	verticalStabilizer.Name = "VerticalStabilizer"
	verticalStabilizer.Shape = Enum.PartType.Block
	verticalStabilizer.Material = Enum.Material.SmoothPlastic
	verticalStabilizer.Color = Color3.fromRGB(0, 100, 180) -- Dark blue accent
	verticalStabilizer.Size = Vector3.new(0.3, 2, 2)
	verticalStabilizer.CanCollide = false
	verticalStabilizer.Anchored = true
	verticalStabilizer.CFrame = fuselage.CFrame * CFrame.new(0, 0.5, -7.5)
	verticalStabilizer.TopSurface = Enum.SurfaceType.Smooth
	verticalStabilizer.BottomSurface = Enum.SurfaceType.Smooth
	verticalStabilizer.Parent = helicopter

	-- Horizontal stabilizer (rear element)
	local horizontalStabilizer = Instance.new("Part")
	horizontalStabilizer.Name = "HorizontalStabilizer"
	horizontalStabilizer.Shape = Enum.PartType.Block
	horizontalStabilizer.Material = Enum.Material.SmoothPlastic
	horizontalStabilizer.Color = Color3.fromRGB(0, 100, 180)
	horizontalStabilizer.Size = Vector3.new(3, 0.3, 2)
	horizontalStabilizer.CanCollide = false
	horizontalStabilizer.Anchored = true
	horizontalStabilizer.CFrame = fuselage.CFrame * CFrame.new(0, -0.8, -7.5)
	horizontalStabilizer.TopSurface = Enum.SurfaceType.Smooth
	horizontalStabilizer.BottomSurface = Enum.SurfaceType.Smooth
	horizontalStabilizer.Parent = helicopter

	-- ROTOR (spinning part at top)
	local rotorHub = Instance.new("Part")
	rotorHub.Name = "RotorHub"
	rotorHub.Shape = Enum.PartType.Cylinder
	rotorHub.Material = Enum.Material.Metal
	rotorHub.Color = Color3.fromRGB(180, 180, 190)
	rotorHub.Size = Vector3.new(0.6, 0.5, 0.5)
	rotorHub.CanCollide = false
	rotorHub.Anchored = true
	rotorHub.CFrame = fuselage.CFrame * CFrame.new(0, 0, 7.5) * CFrame.Angles(0, 0, math.rad(90))
	rotorHub.Parent = helicopter

	-- Rotor blade 1
	local rotorBlade1 = Instance.new("Part")
	rotorBlade1.Name = "RotorBlade1"
	rotorBlade1.Shape = Enum.PartType.Block
	rotorBlade1.Material = Enum.Material.Metal
	rotorBlade1.Color = Color3.fromRGB(220, 100, 0) -- Orange glow
	rotorBlade1.Size = Vector3.new(0.4, 3, 0.15)
	rotorBlade1.CanCollide = false
	rotorBlade1.Anchored = true
	rotorBlade1.CFrame = rotorHub.CFrame * CFrame.new(0, 1.5, 0)
	rotorBlade1.TopSurface = Enum.SurfaceType.Smooth
	rotorBlade1.BottomSurface = Enum.SurfaceType.Smooth
	rotorBlade1.Parent = helicopter

	-- Rotor blade 2
	local rotorBlade2 = Instance.new("Part")
	rotorBlade2.Name = "RotorBlade2"
	rotorBlade2.Shape = Enum.PartType.Block
	rotorBlade2.Material = Enum.Material.Metal
	rotorBlade2.Color = Color3.fromRGB(220, 100, 0)
	rotorBlade2.Size = Vector3.new(0.4, 3, 0.15)
	rotorBlade2.CanCollide = false
	rotorBlade2.Anchored = true
	rotorBlade2.CFrame = rotorHub.CFrame * CFrame.new(0, -1.5, 0)
	rotorBlade2.TopSurface = Enum.SurfaceType.Smooth
	rotorBlade2.BottomSurface = Enum.SurfaceType.Smooth
	rotorBlade2.Parent = helicopter

	-- Store rotor parts for animation
	helicopter:SetAttribute("RotorParts", {rotorBlade1, rotorBlade2, rotorHub})

	-- ENGINES (side-mounted)
	local enginesFolder = Instance.new("Folder")
	enginesFolder.Name = "Engines"
	enginesFolder.Parent = helicopter

	for i = 1, numEngines do
		-- Position engines on sides (alternating left/right)
		local isLeftSide = (i % 2 == 1)
		local engineOffset = if isLeftSide then -6 else 6

		-- Main engine block
		local engine = Instance.new("Part")
		engine.Name = "Engine" .. i
		engine.Shape = Enum.PartType.Block
		engine.Material = Enum.Material.Metal
		engine.Color = Color3.fromRGB(40, 40, 50) -- Dark metallic
		engine.Size = Vector3.new(1.2, 1.5, 1.8)
		engine.CanCollide = false
		engine.Anchored = true
		engine.CFrame = fuselage.CFrame * CFrame.new(engineOffset, 0.3, -2 + (i * 1.5))
		engine.TopSurface = Enum.SurfaceType.Smooth
		engine.BottomSurface = Enum.SurfaceType.Smooth
		engine.Parent = enginesFolder

		-- Engine glow (neon accent)
		local engineGlow = Instance.new("Part")
		engineGlow.Name = "EngineGlow" .. i
		engineGlow.Shape = Enum.PartType.Cylinder
		engineGlow.Material = Enum.Material.Neon
		engineGlow.Color = Color3.fromRGB(255, 150, 0) -- Orange glow
		engineGlow.Size = Vector3.new(0.8, 0.6, 0.6)
		engineGlow.CanCollide = false
		engineGlow.Anchored = true
		engineGlow.CFrame = engine.CFrame * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, 0, math.rad(90))
		engineGlow.Parent = enginesFolder
	end

	-- FUEL CANISTERS (body-mounted under fuselage)
	local fuelsFolder = Instance.new("Folder")
	fuelsFolder.Name = "FuelCanisters"
	fuelsFolder.Parent = helicopter

	for i = 1, numFuelCanisters do
		local canister = Instance.new("Part")
		canister.Name = "FuelCanister" .. i
		canister.Shape = Enum.PartType.Cylinder
		canister.Material = Enum.Material.SmoothPlastic
		canister.Color = Color3.fromRGB(200, 50, 50) -- Red tanks
		canister.Size = Vector3.new(1.5, 1.2, 1.2)
		canister.CanCollide = false
		canister.Anchored = true

		-- Position canisters in a staggered pattern
		local xOffset = if (i % 2 == 0) then 3 else -3
		local zOffset = -2 + (math.floor((i - 1) / 2) * 2.5)
		canister.CFrame = fuselage.CFrame * CFrame.new(xOffset, -1.5, zOffset) * CFrame.Angles(0, 0, math.rad(90))

		canister.Parent = fuelsFolder
	end

	return helicopter
end

--- Update the helicopter model's engines and fuel canisters
--- @param helicopterModel Instance - The helicopter model folder
--- @param numEngines number - New number of engines
--- @param numFuelCanisters number - New number of fuel canisters
function HelicopterModel.UpdateHelicopter(helicopterModel, numEngines, numFuelCanisters)
	if not helicopterModel then
		return
	end

	-- Update engines
	local enginesFolder = helicopterModel:FindFirstChild("Engines")
	if enginesFolder then
		enginesFolder:ClearAllChildren()

		local fuselage = helicopterModel:FindFirstChild("Fuselage")
		if fuselage then
			for i = 1, numEngines do
				local isLeftSide = (i % 2 == 1)
				local engineOffset = if isLeftSide then -6 else 6

				local engine = Instance.new("Part")
				engine.Name = "Engine" .. i
				engine.Shape = Enum.PartType.Block
				engine.Material = Enum.Material.Metal
				engine.Color = Color3.fromRGB(40, 40, 50)
				engine.Size = Vector3.new(1.2, 1.5, 1.8)
				engine.CanCollide = false
				engine.Anchored = true
				engine.CFrame = fuselage.CFrame * CFrame.new(engineOffset, 0.3, -2 + (i * 1.5))
				engine.TopSurface = Enum.SurfaceType.Smooth
				engine.BottomSurface = Enum.SurfaceType.Smooth
				engine.Parent = enginesFolder

				local engineGlow = Instance.new("Part")
				engineGlow.Name = "EngineGlow" .. i
				engineGlow.Shape = Enum.PartType.Cylinder
				engineGlow.Material = Enum.Material.Neon
				engineGlow.Color = Color3.fromRGB(255, 150, 0)
				engineGlow.Size = Vector3.new(0.8, 0.6, 0.6)
				engineGlow.CanCollide = false
				engineGlow.Anchored = true
				engineGlow.CFrame = engine.CFrame * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, 0, math.rad(90))
				engineGlow.Parent = enginesFolder
			end
		end
	end

	-- Update fuel canisters
	local fuelsFolder = helicopterModel:FindFirstChild("FuelCanisters")
	if fuelsFolder then
		fuelsFolder:ClearAllChildren()

		local fuselage = helicopterModel:FindFirstChild("Fuselage")
		if fuselage then
			for i = 1, numFuelCanisters do
				local canister = Instance.new("Part")
				canister.Name = "FuelCanister" .. i
				canister.Shape = Enum.PartType.Cylinder
				canister.Material = Enum.Material.SmoothPlastic
				canister.Color = Color3.fromRGB(200, 50, 50)
				canister.Size = Vector3.new(1.5, 1.2, 1.2)
				canister.CanCollide = false
				canister.Anchored = true

				local xOffset = if (i % 2 == 0) then 3 else -3
				local zOffset = -2 + (math.floor((i - 1) / 2) * 2.5)
				canister.CFrame = fuselage.CFrame * CFrame.new(xOffset, -1.5, zOffset) * CFrame.Angles(0, 0, math.rad(90))

				canister.Parent = fuelsFolder
			end
		end
	end
end

--- Upgrade helicopter tail boom to be bigger and more impressive
--- @param helicopterModel Instance - The helicopter model folder
function HelicopterModel.UpgradeTailBoom(helicopterModel)
	if not helicopterModel then
		return
	end

	local tailBoom = helicopterModel:FindFirstChild("TailBoom")
	local tailBoomRight = helicopterModel:FindFirstChild("TailBoomRight")

	if tailBoom then
		-- Make tail boom larger and add glow
		tailBoom.Size = Vector3.new(1.3, 1.2, 9)
		if not tailBoom:FindFirstChild("TailBoomGlow") then
			local glow = Instance.new("Part")
			glow.Name = "TailBoomGlow"
			glow.Shape = Enum.PartType.Block
			glow.Material = Enum.Material.Neon
			glow.Color = Color3.fromRGB(100, 200, 255)
			glow.Size = Vector3.new(0.3, 0.8, 8)
			glow.CanCollide = false
			glow.Anchored = true
			glow.CFrame = tailBoom.CFrame * CFrame.new(-0.5, 0.5, 0)
			glow.Parent = tailBoom
		end
	end

	if tailBoomRight then
		tailBoomRight.Size = Vector3.new(1.3, 1.2, 9)
		if not tailBoomRight:FindFirstChild("TailBoomGlow") then
			local glow = Instance.new("Part")
			glow.Name = "TailBoomGlow"
			glow.Shape = Enum.PartType.Block
			glow.Material = Enum.Material.Neon
			glow.Color = Color3.fromRGB(100, 200, 255)
			glow.Size = Vector3.new(0.3, 0.8, 8)
			glow.CanCollide = false
			glow.Anchored = true
			glow.CFrame = tailBoomRight.CFrame * CFrame.new(0.5, 0.5, 0)
			glow.Parent = tailBoomRight
		end
	end
end

--- Upgrade helicopter body to be sleeker
--- @param helicopterModel Instance - The helicopter model folder
function HelicopterModel.UpgradeBody(helicopterModel)
	if not helicopterModel then
		return
	end

	local fuselage = helicopterModel:FindFirstChild("Fuselage")
	if fuselage then
		-- Change color to sleeker appearance
		fuselage.Color = Color3.fromRGB(220, 230, 245)
		-- Add metallic shine
		fuselage.Material = Enum.Material.SmoothPlastic

		-- Add a stripe for visual appeal
		if not fuselage:FindFirstChild("Stripe") then
			local stripe = Instance.new("Part")
			stripe.Name = "Stripe"
			stripe.Shape = Enum.PartType.Block
			stripe.Material = Enum.Material.Neon
			stripe.Color = Color3.fromRGB(0, 150, 255)
			stripe.Size = Vector3.new(0.2, 2.5, 12)
			stripe.CanCollide = false
			stripe.Anchored = true
			stripe.CFrame = fuselage.CFrame * CFrame.new(1.1, 0, 0)
			stripe.Parent = fuselage
		end
	end
end

--- Animate helicopter rotor (continuous spin)
--- @param helicopterModel Instance - The helicopter model folder
--- @param rotationSpeed number - Rotation speed (degrees per second)
function HelicopterModel.AnimateRotor(helicopterModel, rotationSpeed)
	if not helicopterModel then
		return
	end

	local rotorBlade1 = helicopterModel:FindFirstChild("RotorBlade1")
	local rotorBlade2 = helicopterModel:FindFirstChild("RotorBlade2")
	local rotorHub = helicopterModel:FindFirstChild("RotorHub")

	if rotorBlade1 and rotorBlade2 and rotorHub then
		-- Create BodyAngularVelocity for continuous smooth rotation around Z axis
		local rotationVelocity = Instance.new("BodyAngularVelocity")
		rotationVelocity.Velocity = Vector3.new(0, 0, math.rad(rotationSpeed))
		rotationVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		rotationVelocity.Parent = rotorHub

		-- Store reference for cleanup
		rotorHub:SetAttribute("RotationVelocity", rotationVelocity)
	end
end

return HelicopterModel
