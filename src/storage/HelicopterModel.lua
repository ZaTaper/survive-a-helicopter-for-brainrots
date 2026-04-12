-- HelicopterModel.lua
-- Creates and manages the visual helicopter model
-- Parts are created programmatically and updated based on engines/fuel canisters

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

	-- Create base platform
	local basePlatform = Instance.new("Part")
	basePlatform.Name = "BasePlatform"
	basePlatform.Shape = Enum.PartType.Block
	basePlatform.Material = Enum.Material.Metal
	basePlatform.Color = Color3.fromRGB(100, 100, 110)
	basePlatform.Size = Vector3.new(10, 2, 10)
	basePlatform.CanCollide = false
	basePlatform.CFrame = CFrame.new(0, 0, 0)
	basePlatform.Parent = helicopter

	-- Create rotor (spinning part on top)
	local rotor = Instance.new("Part")
	rotor.Name = "Rotor"
	rotor.Shape = Enum.PartType.Cylinder
	rotor.Material = Enum.Material.Metal
	rotor.Color = Color3.fromRGB(200, 200, 200)
	rotor.Size = Vector3.new(1, 0.5, 12)
	rotor.CanCollide = false
	rotor.CFrame = basePlatform.CFrame + Vector3.new(0, 3, 0)
	rotor.Rotation = Vector3.new(90, 0, 0)
	rotor.Parent = helicopter

	-- Create rotor blades (two perpendicular cylinders)
	local blade1 = Instance.new("Part")
	blade1.Name = "Blade1"
	blade1.Shape = Enum.PartType.Cylinder
	blade1.Material = Enum.Material.Metal
	blade1.Color = Color3.fromRGB(180, 180, 180)
	blade1.Size = Vector3.new(0.3, 15, 0.3)
	blade1.CanCollide = false
	blade1.CFrame = rotor.CFrame * CFrame.new(0, 0, 0)
	blade1.Rotation = Vector3.new(0, 0, 0)
	blade1.Parent = helicopter

	local blade2 = Instance.new("Part")
	blade2.Name = "Blade2"
	blade2.Shape = Enum.PartType.Cylinder
	blade2.Material = Enum.Material.Metal
	blade2.Color = Color3.fromRGB(180, 180, 180)
	blade2.Size = Vector3.new(0.3, 15, 0.3)
	blade2.CanCollide = false
	blade2.CFrame = rotor.CFrame * CFrame.new(0, 0, 0)
	blade2.Rotation = Vector3.new(0, 90, 0)
	blade2.Parent = helicopter

	-- Store rotating parts for animation
	helicopter:SetAttribute("RotatingParts", {blade1, blade2, rotor})

	-- Create engines (positioned around the base)
	local enginesFolder = Instance.new("Folder")
	enginesFolder.Name = "Engines"
	enginesFolder.Parent = helicopter

	for i = 1, numEngines do
		local enginePart = Instance.new("Part")
		enginePart.Name = "Engine" .. i
		enginePart.Shape = Enum.PartType.Block
		enginePart.Material = Enum.Material.Metal
		enginePart.Color = Color3.fromRGB(50, 50, 50)
		enginePart.Size = Vector3.new(1.5, 2, 1.5)
		enginePart.CanCollide = false

		-- Position engines in a circular pattern around the base
		local angle = (2 * math.pi / numEngines) * (i - 1)
		local offsetX = math.cos(angle) * 4
		local offsetZ = math.sin(angle) * 4
		enginePart.CFrame = basePlatform.CFrame + Vector3.new(offsetX, 1.5, offsetZ)

		enginePart.Parent = enginesFolder
	end

	-- Create fuel canisters (positioned differently than engines)
	local fuelsFolder = Instance.new("Folder")
	fuelsFolder.Name = "FuelCanisters"
	fuelsFolder.Parent = helicopter

	for i = 1, numFuelCanisters do
		local canister = Instance.new("Part")
		canister.Name = "FuelCanister" .. i
		canister.Shape = Enum.PartType.Ball
		canister.Material = Enum.Material.Neon
		canister.Color = Color3.fromRGB(255, 200, 0)
		canister.Size = Vector3.new(1, 1, 1)
		canister.CanCollide = false

		-- Position canisters in a circular pattern, slightly offset from engines
		local angle = (2 * math.pi / numFuelCanisters) * (i - 1) + (math.pi / numFuelCanisters)
		local offsetX = math.cos(angle) * 3
		local offsetZ = math.sin(angle) * 3
		canister.CFrame = basePlatform.CFrame + Vector3.new(offsetX, -0.5, offsetZ)

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

		local basePlatform = helicopterModel:FindFirstChild("BasePlatform")
		if basePlatform then
			for i = 1, numEngines do
				local enginePart = Instance.new("Part")
				enginePart.Name = "Engine" .. i
				enginePart.Shape = Enum.PartType.Block
				enginePart.Material = Enum.Material.Metal
				enginePart.Color = Color3.fromRGB(50, 50, 50)
				enginePart.Size = Vector3.new(1.5, 2, 1.5)
				enginePart.CanCollide = false

				local angle = (2 * math.pi / numEngines) * (i - 1)
				local offsetX = math.cos(angle) * 4
				local offsetZ = math.sin(angle) * 4
				enginePart.CFrame = basePlatform.CFrame + Vector3.new(offsetX, 1.5, offsetZ)

				enginePart.Parent = enginesFolder
			end
		end
	end

	-- Update fuel canisters
	local fuelsFolder = helicopterModel:FindFirstChild("FuelCanisters")
	if fuelsFolder then
		fuelsFolder:ClearAllChildren()

		local basePlatform = helicopterModel:FindFirstChild("BasePlatform")
		if basePlatform then
			for i = 1, numFuelCanisters do
				local canister = Instance.new("Part")
				canister.Name = "FuelCanister" .. i
				canister.Shape = Enum.PartType.Ball
				canister.Material = Enum.Material.Neon
				canister.Color = Color3.fromRGB(255, 200, 0)
				canister.Size = Vector3.new(1, 1, 1)
				canister.CanCollide = false

				local angle = (2 * math.pi / numFuelCanisters) * (i - 1) + (math.pi / numFuelCanisters)
				local offsetX = math.cos(angle) * 3
				local offsetZ = math.sin(angle) * 3
				canister.CFrame = basePlatform.CFrame + Vector3.new(offsetX, -0.5, offsetZ)

				canister.Parent = fuelsFolder
			end
		end
	end
end

--- Animate helicopter rotor (continuous spin)
--- @param helicopterModel Instance - The helicopter model folder
--- @param rotationSpeed number - Rotation speed (degrees per frame)
function HelicopterModel.AnimateRotor(helicopterModel, rotationSpeed)
	if not helicopterModel then
		return
	end

	local blade1 = helicopterModel:FindFirstChild("Blade1")
	local blade2 = helicopterModel:FindFirstChild("Blade2")
	local rotor = helicopterModel:FindFirstChild("Rotor")

	if blade1 and blade2 and rotor then
		-- Create BodyAngularVelocity for continuous smooth rotation
		local rotationVelocity = Instance.new("BodyAngularVelocity")
		rotationVelocity.Velocity = Vector3.new(0, math.rad(rotationSpeed), 0)
		rotationVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		rotationVelocity.Parent = rotor

		-- Store reference for cleanup
		rotor:SetAttribute("RotationVelocity", rotationVelocity)
	end
end

return HelicopterModel
