-- HelicopterClient.client.lua
-- Client-side helicopter controls and interactions
-- Handles E to build, Space to fly, WASD to move while flying
-- Handles G to grab/drop brainrots
-- Shows HUD with fuel, speed, engines, carry status

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Get references to remote events and modules
local RemoteEvents = ReplicatedStorage:WaitForChild("HelicopterRemotes")
local BuildHelicopterEvent = RemoteEvents:WaitForChild("BuildHelicopter")
local AddEngineEvent = RemoteEvents:WaitForChild("AddEngine")
local AddFuelCanisterEvent = RemoteEvents:WaitForChild("AddFuelCanister")
local ActivateHelicopterEvent = RemoteEvents:WaitForChild("ActivateHelicopter")
local DeactivateHelicopterEvent = RemoteEvents:WaitForChild("DeactivateHelicopter")
local GetHelicopterStatsEvent = RemoteEvents:WaitForChild("GetHelicopterStats")

-- Get grab/carry brainrot events (standalone in ReplicatedStorage)
local GrabBrainrotEvent = ReplicatedStorage:WaitForChild("GrabBrainrot")
local DropBrainrotEvent = ReplicatedStorage:WaitForChild("DropBrainrot")
local CarryStateChangedEvent = ReplicatedStorage:WaitForChild("CarryStateChanged")
local BrainrotGrabbedEvent = ReplicatedStorage:WaitForChild("BrainrotGrabbed")
local BrainrotDroppedAtBaseEvent = ReplicatedStorage:WaitForChild("BrainrotDroppedAtBase")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local HelicopterData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HelicopterData"))

-- Helicopter state
local helicopterState = {
	isActive = false,
	hasHelicopter = false,
	engines = GameConfig.StarterHelicopter.ENGINES,
	fuelCanisters = GameConfig.StarterHelicopter.FUEL_CANISTERS,
	currentFuel = GameConfig.StarterHelicopter.MAX_FUEL,
	maxFuel = GameConfig.StarterHelicopter.MAX_FUEL,
	speed = GameConfig.StarterHelicopter.SPEED,
	drainRate = 0,
	carryingBrainrot = nil, -- nil or {tierName, displayName, money}
}

-- Movement input handling
local movementInput = {
	forward = false,
	backward = false,
	left = false,
	right = false,
}

-- Create UI HUD for displaying helicopter stats
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
	statusText.Size = UDim2.new(0, 200, 0, 150)
	statusText.Position = UDim2.new(0, 20, 0, 60)
	statusText.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusText.TextScaled = false
	statusText.TextSize = 12
	statusText.Font = Enum.Font.Gotham
	statusText.TextWrapped = true
	statusText.BorderSizePixel = 2
	statusText.Parent = screenGui

	-- Controls hint
	local controlsText = Instance.new("TextLabel")
	controlsText.Name = "ControlsText"
	controlsText.Size = UDim2.new(0, 350, 0, 120)
	controlsText.Position = UDim2.new(0, 20, 1, -140)
	controlsText.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	controlsText.TextColor3 = Color3.fromRGB(200, 200, 200)
	controlsText.TextScaled = false
	controlsText.TextSize = 11
	controlsText.Font = Enum.Font.Gotham
	controlsText.TextWrapped = true
	controlsText.BorderSizePixel = 1
	controlsText.Text = "E: Build | R: Engine | F: Fuel\nSpace: Fly/Land | WASD: Move\nG: Grab/Drop Brainrot | B: Shop | C: Collection"
	controlsText.Parent = screenGui

	-- Carry indicator (appears when carrying)
	local carryIndicator = Instance.new("Frame")
	carryIndicator.Name = "CarryIndicator"
	carryIndicator.Size = UDim2.new(0, 300, 0, 50)
	carryIndicator.Position = UDim2.new(0.5, -150, 0, 5)
	carryIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	carryIndicator.BorderSizePixel = 2
	carryIndicator.Visible = false
	carryIndicator.Parent = screenGui

	-- Carry indicator text
	local carryText = Instance.new("TextLabel")
	carryText.Name = "CarryText"
	carryText.Size = UDim2.new(1, 0, 1, 0)
	carryText.BackgroundTransparency = 1
	carryText.TextColor3 = Color3.fromRGB(255, 255, 255)
	carryText.TextScaled = true
	carryText.Font = Enum.Font.GothamBold
	carryText.Parent = carryIndicator

	return {
		screenGui = screenGui,
		fuelBar = fuelBar,
		fuelLabel = fuelLabel,
		statusText = statusText,
		carryIndicator = carryIndicator,
		carryText = carryText,
	}
end

local UI = CreateUI()

-- Tier color mapping for carry indicator (matches GameConfig.BrainrotTiers)
local function GetTierColor(tierName)
	if tierName == "Common" then
		return Color3.fromRGB(180, 180, 180)
	elseif tierName == "Uncommon" then
		return Color3.fromRGB(50, 200, 50)
	elseif tierName == "Rare" then
		return Color3.fromRGB(50, 100, 255)
	elseif tierName == "Epic" then
		return Color3.fromRGB(160, 50, 255)
	elseif tierName == "Mythic" then
		return Color3.fromRGB(255, 50, 50)
	elseif tierName == "Secret" then
		return Color3.fromRGB(255, 215, 0)
	elseif tierName == "Celestial" then
		return Color3.fromRGB(0, 255, 255)
	elseif tierName == "OP" then
		return Color3.fromRGB(255, 0, 128)
	else
		return Color3.fromRGB(100, 100, 100)
	end
end

-- Update UI with current stats
local function UpdateUI()
	local fuelPercentage = math.min(1, helicopterState.currentFuel / math.max(1, helicopterState.maxFuel))
	UI.fuelBar.Size = UDim2.new(fuelPercentage, 0, 1, 0)
	UI.fuelLabel.Text = string.format("Fuel: %.0f/%.0f", helicopterState.currentFuel, helicopterState.maxFuel)

	-- Determine status based on helicopter state
	local status = "READY"
	if not helicopterState.hasHelicopter then
		status = "NO HELICOPTER"
	elseif helicopterState.isActive then
		status = "FLYING"
	end

	local statusMessage = string.format(
		"Engines: %d\nCanisters: %d\nSpeed: %.0f\nStatus: %s",
		helicopterState.engines,
		helicopterState.fuelCanisters,
		helicopterState.speed,
		status
	)

	-- Add carry info to status message
	if helicopterState.carryingBrainrot then
		statusMessage = statusMessage .. string.format(
			"\nCarrying: %s (%s)",
			helicopterState.carryingBrainrot.displayName,
			helicopterState.carryingBrainrot.tierName
		)
	elseif helicopterState.isActive then
		statusMessage = statusMessage .. "\nFly near brainrot + G to grab"
	end

	UI.statusText.Text = statusMessage

	-- Update carry indicator
	if helicopterState.carryingBrainrot then
		UI.carryIndicator.Visible = true
		UI.carryText.Text = "Carrying: " .. helicopterState.carryingBrainrot.displayName
		UI.carryIndicator.BackgroundColor3 = GetTierColor(helicopterState.carryingBrainrot.tierName)
	else
		UI.carryIndicator.Visible = false
	end
end

-- Build helicopter (E key)
local function BuildHelicopter()
	BuildHelicopterEvent:FireServer()
	task.wait(0.5)
	SyncStats()
end

-- Add engine upgrade (R key)
local function AddEngine()
	AddEngineEvent:FireServer()
	task.wait(0.5)
	SyncStats()
end

-- Add fuel canister upgrade (F key)
local function AddFuelCanister()
	AddFuelCanisterEvent:FireServer()
	task.wait(0.5)
	SyncStats()
end

-- Activate helicopter for flight (Space key)
local function ActivateHelicopter()
	ActivateHelicopterEvent:FireServer()
	helicopterState.isActive = true
end

-- Deactivate helicopter
local function DeactivateHelicopter()
	DeactivateHelicopterEvent:FireServer()
	helicopterState.isActive = false
end

-- Grab or drop brainrot (G key)
local function GrabOrDropBrainrot()
	if not helicopterState.isActive then
		return
	end

	if helicopterState.carryingBrainrot then
		-- Currently carrying, so drop
		DropBrainrotEvent:FireServer()
	else
		-- Not carrying, so try to grab
		GrabBrainrotEvent:FireServer()
	end
end

-- Sync helicopter stats from server (MUST be defined before being called)
local function SyncStats()
	local ok, stats = pcall(function()
		return GetHelicopterStatsEvent:InvokeServer()
	end)

	if not ok then
		warn("Error syncing helicopter stats: " .. tostring(stats))
		return
	end

	if stats then
		helicopterState.engines = stats.engines
		helicopterState.fuelCanisters = stats.fuelCanisters
		helicopterState.currentFuel = stats.currentFuel
		helicopterState.maxFuel = stats.maxFuel
		helicopterState.speed = stats.speed
		helicopterState.drainRate = stats.drainRate
		helicopterState.isActive = stats.isActive or false
		helicopterState.hasHelicopter = stats.hasHelicopter or false
		helicopterState.carryingBrainrot = stats.carryingBrainrot or nil

		-- Check if out of fuel
		if helicopterState.currentFuel <= 0 and helicopterState.isActive then
			DeactivateHelicopter()
		end

		UpdateUI()
	end
end

-- Handle CarryStateChanged from server
CarryStateChangedEvent.OnClientEvent:Connect(function(carryData)
	helicopterState.carryingBrainrot = carryData
	UpdateUI()
end)

-- Handle BrainrotGrabbed notification (server sends uniqueId)
BrainrotGrabbedEvent.OnClientEvent:Connect(function(uniqueId)
	-- A brainrot was grabbed somewhere in the world
end)

-- Handle BrainrotDroppedAtBase notification (server sends uniqueId, playerUserId)
BrainrotDroppedAtBaseEvent.OnClientEvent:Connect(function(uniqueId, playerUserId)
	-- A brainrot was dropped at a base
end)

-- Handle keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.W then
		movementInput.forward = true
	elseif input.KeyCode == Enum.KeyCode.S then
		movementInput.backward = true
	elseif input.KeyCode == Enum.KeyCode.A then
		movementInput.left = true
	elseif input.KeyCode == Enum.KeyCode.D then
		movementInput.right = true
	elseif input.KeyCode == Enum.KeyCode.E then
		BuildHelicopter()
	elseif input.KeyCode == Enum.KeyCode.R then
		AddEngine()
	elseif input.KeyCode == Enum.KeyCode.F then
		AddFuelCanister()
	elseif input.KeyCode == Enum.KeyCode.Space then
		if not helicopterState.isActive then
			ActivateHelicopter()
		else
			DeactivateHelicopter()
		end
	elseif input.KeyCode == Enum.KeyCode.G then
		GrabOrDropBrainrot()
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

	local fuselage = helicopterModel:FindFirstChild("Fuselage")
	if not fuselage then
		return
	end

	-- Calculate movement direction
	local moveDirection = Vector3.new(0, 0, 0)
	if movementInput.forward then
		moveDirection = moveDirection + fuselage.CFrame.LookVector
	end
	if movementInput.backward then
		moveDirection = moveDirection - fuselage.CFrame.LookVector
	end
	if movementInput.left then
		moveDirection = moveDirection - fuselage.CFrame.RightVector
	end
	if movementInput.right then
		moveDirection = moveDirection + fuselage.CFrame.RightVector
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
	local movementCFrame = fuselage.CFrame + (moveDirection * helicopterState.speed * deltaTime)

	-- Apply tilt to the entire helicopter
	fuselage.CFrame = movementCFrame * CFrame.Angles(
		math.rad(lastMovementTilt.X),
		0,
		math.rad(lastMovementTilt.Z)
	)
end

-- Periodically sync stats from server
spawn(function()
	while true do
		task.wait(0.5)
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

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	helicopterState.isActive = false
	helicopterState.carryingBrainrot = nil
	task.wait(0.1)
	SyncStats()
end)

-- Initial setup
task.wait(0.1)
SyncStats()
UpdateUI()

print("HelicopterClient loaded and ready")
