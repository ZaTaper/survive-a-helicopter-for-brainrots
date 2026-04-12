--[[
	HUDClient.client.lua
	Main client script that initializes and manages all GUI elements for "Survive a Helicopter for Brainrots"

	Responsibilities:
	- Initializes MainHUD, Leaderboard, and DeathScreen modules
	- Listens to RemoteEvents for state updates from server
	- Updates HUD elements in real-time
	- Manages GUI transitions between game phases
	- Handles keyboard shortcuts (Tab for leaderboard)
	- Syncs player data and helicopter stats

	Run frequency: Once when the game loads
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import modules
local MainHUD = require(script.Parent.Parent.gui.MainHUD)
local Leaderboard = require(script.Parent.Parent.gui.Leaderboard)
local DeathScreen = require(script.Parent.Parent.gui.DeathScreen)
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local HelicopterData = require(ReplicatedStorage:WaitForChild("HelicopterData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- State tracking
local gameState = {
	currentPhase = "LOBBY",
	currentWave = 1,
	currentFuel = GameConfig.Helicopter.BASE_FUEL,
	maxFuel = GameConfig.Helicopter.BASE_FUEL,
	currentSpeed = GameConfig.Helicopter.BASE_SPEED,
	engineCount = 0,
	canisterCount = 0,
	killCount = 0,
	wavesSurvived = 0,
	isDead = false,
}

local playerStats = {} -- Store all players' stats for leaderboard
local phaseStartTime = 0
local phaseEndTime = 0

-- Create events folder if it doesn't exist
if not ReplicatedStorage:FindFirstChild("HUDEvents") then
	local folder = Instance.new("Folder")
	folder.Name = "HUDEvents"
	folder.Parent = ReplicatedStorage
end

local HUDEvents = ReplicatedStorage:WaitForChild("HUDEvents")

-- Create remote events for communication
local function GetOrCreateRemoteEvent(name)
	if not HUDEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = HUDEvents
	end
	return HUDEvents:WaitForChild(name)
end

-- Events for server->client communication
local updateFuelEvent = GetOrCreateRemoteEvent("UpdateFuel")
local updateSpeedEvent = GetOrCreateRemoteEvent("UpdateSpeed")
local updateInventoryEvent = GetOrCreateRemoteEvent("UpdateInventory")
local updateKillCountEvent = GetOrCreateRemoteEvent("UpdateKillCount")
local updateWaveEvent = GetOrCreateRemoteEvent("UpdateWave")
local updatePhaseEvent = GetOrCreateRemoteEvent("UpdatePhase")
local updateLeaderboardEvent = GetOrCreateRemoteEvent("UpdateLeaderboard")
local playerDiedEvent = GetOrCreateRemoteEvent("PlayerDied")
local pickupNotificationEvent = GetOrCreateRemoteEvent("PickupNotification")

--[[
	Initializes all HUD modules
]]
local function InitializeHUD()
	print("[HUDClient] Initializing HUD systems...")

	-- Initialize MainHUD
	MainHUD:Init(playerGui)
	print("[HUDClient] MainHUD initialized")

	-- Initialize Leaderboard
	Leaderboard:Init(playerGui)
	print("[HUDClient] Leaderboard initialized")

	-- Initialize DeathScreen
	DeathScreen:Init(playerGui)
	print("[HUDClient] DeathScreen initialized")
end

--[[
	Sets up keyboard input handlers
]]
local function SetupInputHandlers()
	print("[HUDClient] Setting up input handlers...")

	-- Tab key to toggle leaderboard
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Tab then
			Leaderboard:Toggle()
		elseif input.KeyCode == Enum.KeyCode.Space and gameState.isDead then
			-- Space to respawn (handled by DeathScreen)
		end
	end)
end

--[[
	Connects to remote events for state updates from the server
]]
local function ConnectToRemoteEvents()
	print("[HUDClient] Connecting to remote events...")

	-- Update fuel
	updateFuelEvent.OnClientEvent:Connect(function(currentFuel, maxFuel)
		gameState.currentFuel = currentFuel
		gameState.maxFuel = maxFuel
		MainHUD:UpdateFuel(currentFuel, maxFuel)
	end)

	-- Update speed
	updateSpeedEvent.OnClientEvent:Connect(function(speed)
		gameState.currentSpeed = speed
		MainHUD:UpdateSpeed(speed)
	end)

	-- Update inventory (engines and canisters)
	updateInventoryEvent.OnClientEvent:Connect(function(engines, canisters, currentFuel)
		gameState.engineCount = engines
		gameState.canisterCount = canisters
		gameState.currentFuel = currentFuel
		gameState.maxFuel = GameConfig.Helicopter.BASE_FUEL + (GameConfig.Helicopter.FUEL_PER_CANISTER * canisters)

		MainHUD:UpdateEngineCount(engines)
		MainHUD:UpdateCanisterCount(canisters)
		MainHUD:UpdateFuel(currentFuel, gameState.maxFuel)
		MainHUD:UpdateSpeed(HelicopterData.CalculateSpeed(engines))
	end)

	-- Update kill count
	updateKillCountEvent.OnClientEvent:Connect(function(kills)
		gameState.killCount = kills
		MainHUD:UpdateKillCount(kills)
	end)

	-- Update wave
	updateWaveEvent.OnClientEvent:Connect(function(waveNumber)
		gameState.currentWave = waveNumber
		gameState.wavesSurvived = waveNumber - 1
		MainHUD:UpdateWave(waveNumber)
	end)

	-- Update phase
	updatePhaseEvent.OnClientEvent:Connect(function(phase, duration)
		gameState.currentPhase = phase
		phaseStartTime = tick()
		phaseEndTime = phaseStartTime + (duration or 60)
		MainHUD:UpdatePhase(phase)
	end)

	-- Update leaderboard
	updateLeaderboardEvent.OnClientEvent:Connect(function(leaderboardData)
		playerStats = leaderboardData
		Leaderboard:Refresh(leaderboardData)
	end)

	-- Player died
	playerDiedEvent.OnClientEvent:Connect(function(brainrotName, brainrotTier, tierColor)
		gameState.isDead = true
		local respawnCallback = function()
			gameState.isDead = false
			-- Server will handle respawn via dedicated respawn event
		end

		DeathScreen:Show(
			{name = brainrotName, tier = brainrotTier, tierColor = tierColor},
			gameState.wavesSurvived,
			gameState.killCount,
			respawnCallback
		)
	end)

	-- Pickup notification
	pickupNotificationEvent.OnClientEvent:Connect(function(itemType, quantity)
		MainHUD:ShowPickupNotification(itemType, quantity or 1)
	end)
end

--[[
	Updates phase timer every frame
]]
local function SetupPhaseTimerUpdate()
	print("[HUDClient] Setting up phase timer updates...")

	RunService.RenderStepped:Connect(function()
		if gameState.currentPhase and phaseEndTime and tick() < phaseEndTime then
			local timeRemaining = phaseEndTime - tick()
			if timeRemaining > 0 then
				MainHUD:UpdatePhaseTimer(timeRemaining)
			end
		end
	end)
end

--[[
	Requests initial game state from the server
]]
local function RequestInitialState()
	print("[HUDClient] Requesting initial game state...")

	-- This would be called by server during player join
	-- For now, we set reasonable defaults
	MainHUD:UpdateFuel(gameState.currentFuel, gameState.maxFuel)
	MainHUD:UpdateSpeed(gameState.currentSpeed)
	MainHUD:UpdateWave(gameState.currentWave)
	MainHUD:UpdatePhase(gameState.currentPhase)
	MainHUD:UpdateKillCount(gameState.killCount)
	MainHUD:UpdateEngineCount(gameState.engineCount)
	MainHUD:UpdateCanisterCount(gameState.canisterCount)
end

--[[
	Main initialization sequence
]]
local function Initialize()
	print("[HUDClient] Starting HUD initialization...")

	-- Wait a frame to ensure PlayerGui is ready
	task.wait(0.1)

	-- Initialize modules
	InitializeHUD()

	-- Set up event handlers
	ConnectToRemoteEvents()
	SetupInputHandlers()
	SetupPhaseTimerUpdate()

	-- Request initial state
	RequestInitialState()

	print("[HUDClient] HUD fully initialized and ready!")
end

-- Start the system
pcall(Initialize)
