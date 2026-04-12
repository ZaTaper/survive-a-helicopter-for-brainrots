-- HelicopterClient.client.lua
-- Client-side helicopter controls and interactions
-- Handles WASD movement, tilt animation, particle effects, and UI updates

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Get references to remote events
local RemoteEvents = game.ReplicatedStorage:WaitForChild("HelicopterRemotes")
local BuildHelicopterEvent = RemoteEvents:WaitForChild("BuildHelicopter")
local AddEngineEvent = RemoteEvents:WaitForChild("AddEngine")
local AddFuelCanisterEvent = RemoteEvents:WaitForChild("AddFuelCanister")
local ActivateHelicopterEvent = RemoteEvents:WaitForChild("ActivateHelicopter")
local GetHelicopterStatsEvent = RemoteEvents:WaitForChild("GetHelicopterStats")

-- Game config
local GameConfig = require(game.ReplicatedStorage.shared.GameConfig)
local HelicopterData = require(game.ReplicatedStorage.shared.HelicopterData)

-- Helicopter state
local helicopterState = {
	isActive = false,
	engines = 0,
	fuelCanisters = 0,
	currentFuel = GameConfig.Helicopter.BASE_FUEL,
	maxFuel = GameConfig.Helicopter.BASE_FUEL,
	speed = GameConfig.Helicopter.BASE_SPEED,
	drainRate = GameConfig.Helicopter.FUEL_DRAIN_RATE,
}

-- Movement input handling
local movementInput = {
	forward = false,
	backward = false,
	left = false,
	right = false,
}

-- Create UI elements for displaying helicopter stats
local function CreateUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HelicopterUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Fuel bar background
	local fuelBarBg = Instance.new("Frame")
	fuelBarBg.Name = "FuelBarBg"
	fuelBarBg.Size = UDim2.new(0, 200, 0, 30)
	fuelBarBg.Position = UDim2.new(0, 20, 0, 20)
	fuelBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	fuelBarBg.BorderSizePixel = 2
	fuelBarBg.Parent = screenGui

	-- Fuel bar fill
	local fuelBar = Instance.new("Frame")
	fuelBar.Name = "FuelBar"
	fuelBar.Size = UDim2.new(1, 0, 1, 0)
	fuelBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	fuelBar.BorderSizePixel = 0
	fuelBar.Parent = fuelBarBg

	-- Fuel label
	local fuelLabel = Instance.new("TextLabel")
	fuelLabel.Name = "FuelLabel"
	fuelLabel.Size = UDim2.new(1, 0, 1, 0)
	fuelLabel.BackgroundTransparency = 1
	fuelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	fuelLabel.TextScaled = true
	fuelLabel.Font = Enum.Font.GothamBold
	fuelLabel.Parent = fuelBarBg

	-- Status text
	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(0, 200, 0, 100)
	statusText.Position = UDim2.new(0, 20, 0, 60)
	statusText.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusText.TextScaled = true
	statusText.Font = Enum.Font.Gotham
	statusText.TextWrapped = true
	statusText.BorderSizePixel = 2
	statusText.Parent = screenGui

	return {
		screenGui = screenGui,
		fuelBar = fuelBar,
		fuelBarBg = fuelBarBg,
		fuelLabel = fuelLabel,
		statusText = statusText,
	}
end

-- Update UI with current stats
local UI = CreateUI()

local function UpdateUI()
	-- Update fuel bar
	local fuelPercentage = helicopterState.currentFuel / helicopterState.maxFuel
	UI.fuelBar.Size = UDim2.new(fuelPercentage, 0, 1, 0)
	UI.fuelLabel.Text = string.format("Fuel: %.0f/%.0f", helicopterState.currentFuel, helicopterState.maxFuel)

	-- Update status text
	local statusMessage = string.format(
		"Engines: %d\nFuel Canisters: %d\nSpeed: %.1f\nActive: %s",
		helicopterState.engines,
		helicopterState.fuelCanisters,
		helicopterState.speed,
		helicopterState.isActive and "Yes" or "No"
	)
	UI.statusText.Text = statusMessage
end

-- Create particle effects for helicopter exhaust
local function CreateExhaustParticles(helicopterModel)
	if not helicopterModel then
		return
	end

	local basePlatform = helicopterModel:FindFirstChild("BasePlatform")
	if not basePlatform then
		return
	end

	-- Create particle emitter attachment
	local attachment = Instance.new("Attachment")
	attachment.Parent = basePlatform

	-- Create particle emitter
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Texture = "rbxasset://textures/Particles/smoke_main.dds"
	particleEmitter.Rate = 30
	particleEmitter.Lifetime = NumberRange.new(1, 2)
	particleEmitter.Speed = NumberRange.new(5, 10)
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100))
	particleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	particleEmitter.Parent = attachment

	return particleEmitter
end

-- Build helicopter
local function BuildHelicopter()
	BuildHelicopterEvent:FireServer()
	wait(0.5)
	SyncStats()
end

-- Add engine
local function AddEngine()
	AddEngineEvent:FireServer()
	wait(0.5)
	SyncStats()
end

-- Add fuel canister
local function AddFuelCanister()
	AddFuelCanisterEvent:FireServer()
	wait(0.5)
	SyncStats()
end

-- Activate helicopter
local function ActivateHelicopter()
	ActivateHelicopterEvent:FireServer()
	helicopterState.isActive = true
end

-- Sync helicopter stats from server
local function SyncStats()
	local stats = GetHelicopterStatsEvent:InvokeServer()
	if stats then
		helicopterState.engines = stats.engines
		helicopterState.fuelCanisters = stats.fuelCanisters
		helicopterState.currentFuel = stats.currentFuel
		helicopterState.maxFuel = stats.maxFuel
		helicopterState.speed = stats.speed
		helicopterState.drainRate = stats.drainRate
		UpdateUI()
	end
end

-- Handle keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- Movement keys
	if input.KeyCode == Enum.KeyCode.W then
		movementInput.forward = true
	elseif input.KeyCode == Enum.KeyCode.S then
		movementInput.backward = true
	elseif input.KeyCode == Enum.KeyCode.A then
		movementInput.left = true
	elseif input.KeyCode == Enum.KeyCode.D then
		movementInput.right = true
	end

	-- Helicopter build shortcuts
	if input.KeyCode == Enum.KeyCode.E then
		BuildHelicopter()
	elseif input.KeyCode == Enum.KeyCode.R then
		AddEngine()
	elseif input.KeyCode == Enum.KeyCode.F then
		AddFuelCanister()
	elseif input.KeyCode == Enum.KeyCode.Space then
		ActivateHelicopter()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.W then
		movementInput.forward = false
	elseif input.KeyCode == Enum.KeyCode.S then
		movementInput.backward = false
	elseif input.KeyCode == Enum.KeyCode.A then
		movementInput.left = false
	elseif input.KeyCode == Enum.KeyCode.D then
		movementInput.right = false
	end
end)

-- Movement and tilt logic
local lastMovementTilt = Vector3.new(0, 0, 0)

local function UpdateMovement()
	local helicopterModel = character:FindFirstChild("Helicopter")
	if not helicopterModel or not helicopterState.isActive then
		return
	end

	local basePlatform = helicopterModel:FindFirstChild("BasePlatform")
	if not basePlatform then
		return
	end

	-- Calculate movement direction
	local moveDirection = Vector3.new(0, 0, 0)
	if movementInput.forward then
		moveDirection = moveDirection + basePlatform.CFrame.LookVector
	end
	if movementInput.backward then
		moveDirection = moveDirection - basePlatform.CFrame.LookVector
	end
	if movementInput.left then
		moveDirection = moveDirection - basePlatform.CFrame.RightVector
	end
	if movementInput.right then
		moveDirection = moveDirection + basePlatform.CFrame.RightVector
	end

	-- Normalize movement direction
	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit
	end

	-- Calculate tilt angle based on movement (max 30 degrees)
	local maxTilt = 30
	local tiltTarget = Vector3.new(
		moveDirection.X * maxTilt,
		0,
		-moveDirection.Z * maxTilt
	)

	-- Smooth tilt transition
	lastMovementTilt = lastMovementTilt:Lerp(tiltTarget, 0.1)

	-- Apply movement at helicopter speed
	local deltaTime = RunService.Heartbeat:Wait()
	local movementCFrame = basePlatform.CFrame + (moveDirection * helicopterState.speed * deltaTime)

	-- Apply tilt to the helicopter
	basePlatform.CFrame = movementCFrame * CFrame.Angles(
		math.rad(lastMovementTilt.X),
		0,
		math.rad(lastMovementTilt.Z)
	)
end

-- Periodically sync stats from server (every 0.5 seconds)
spawn(function()
	while true do
		wait(0.5)
		SyncStats()
	end
end)

-- Main render loop for movement
RunService.RenderStepped:Connect(function()
	if helicopterState.isActive then
		UpdateMovement()
		UpdateUI()
	end
end)

-- Initial setup
wait(0.1)
SyncStats()
UpdateUI()

print("HelicopterClient loaded and ready")
