--[[
	HUDClient.client.lua
	Main client orchestrator for all GUI elements in "Survive a Helicopter for Brainrots"

	Responsibilities:
	- Loads all GUI modules from PlayerGui.GUI
	- Initializes MainHUD (visible by default), everything else hidden
	- Handles keyboard shortcuts: B=shop, C=collection, Tab=leaderboard
	- Listens to RemoteEvents for HUD updates
	- Updates fuel bar and stats via RunService.Heartbeat

	Run frequency: Once when the game loads
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the GUI folder if it doesn't exist, otherwise wait for it
local guiFolder = playerGui:FindFirstChild("GUI")
if not guiFolder then
	guiFolder = Instance.new("Folder")
	guiFolder.Name = "GUI"
	guiFolder.Parent = playerGui
end

-- Load GUI modules
local MainHUD = require(guiFolder:WaitForChild("MainHUD"))
local DeathScreen = require(guiFolder:WaitForChild("DeathScreen"))
local CollectionGUI = require(guiFolder:WaitForChild("CollectionGUI"))
local Leaderboard = require(guiFolder:WaitForChild("Leaderboard"))
local MusicSettings = require(guiFolder:WaitForChild("MusicSettings"))

-- Shared modules
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local HelicopterData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HelicopterData"))

-- State tracking
local gameState = {
	currentPhase = "LOBBY",
	currentWave = 1,
	currentFuel = GameConfig.Helicopter.BASE_FUEL,
	maxFuel = GameConfig.Helicopter.BASE_FUEL,
	engineCount = 0,
	canisterCount = 0,
	brainBucks = 0,
	isDead = false,
}

local playerStats = {}  -- Store all players' stats for leaderboard

--[[
	Creates or gets RemoteEvents in HUDEvents folder
]]
local function GetOrCreateRemoteEvent(name)
	local hudEvents = ReplicatedStorage:FindFirstChild("HUDEvents")
	if not hudEvents then
		hudEvents = Instance.new("Folder")
		hudEvents.Name = "HUDEvents"
		hudEvents.Parent = ReplicatedStorage
	end

	if not hudEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = hudEvents
	end
	return hudEvents:WaitForChild(name)
end

--[[
	Initializes all HUD modules
]]
local function InitializeHUD()
	print("[HUDClient] Initializing all HUD modules...")

	-- Create ScreenGui parent objects by initializing modules
	local mainHudGui = MainHUD:Init()
	mainHudGui.Parent = playerGui
	mainHudGui.Enabled = true  -- MainHUD starts visible

	local deathScreenGui = DeathScreen:Init()
	deathScreenGui.Parent = playerGui
	deathScreenGui.Enabled = false

	local collectionGui = CollectionGUI:Init()
	collectionGui.Parent = playerGui
	collectionGui.Enabled = false

	local leaderboardGui = Leaderboard:Init()
	leaderboardGui.Parent = playerGui
	leaderboardGui.Enabled = false

	local musicGui = MusicSettings:Init()
	musicGui.Parent = playerGui
	musicGui.Enabled = true

	print("[HUDClient] All HUD modules initialized")
end

--[[
	Sets up keyboard input handlers
]]
local function SetupInputHandlers()
	print("[HUDClient] Setting up input handlers...")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Tab then
			-- Tab toggles leaderboard
			Leaderboard:Toggle()
		elseif input.KeyCode == Enum.KeyCode.C then
			-- C toggles collection GUI
			CollectionGUI:Toggle()
		elseif input.KeyCode == Enum.KeyCode.B then
			-- B would toggle shop (not implemented in this set)
			print("[HUDClient] Shop toggle not yet implemented")
		end
	end)
end

--[[
	Connects to RemoteEvents for state updates
]]
local function ConnectToRemoteEvents()
	print("[HUDClient] Connecting to remote events...")

	-- Update fuel
	local updateFuelEvent = GetOrCreateRemoteEvent("UpdateFuel")
	updateFuelEvent.OnClientEvent:Connect(function(currentFuel, maxFuel)
		gameState.currentFuel = currentFuel
		gameState.maxFuel = maxFuel
		MainHUD:UpdateFuel(currentFuel, maxFuel)
	end)

	-- Update wave
	local updateWaveEvent = GetOrCreateRemoteEvent("UpdateWave")
	updateWaveEvent.OnClientEvent:Connect(function(waveNumber)
		gameState.currentWave = waveNumber
		MainHUD:UpdateWave(waveNumber)
	end)

	-- Update inventory (engines and canisters)
	local updateInventoryEvent = GetOrCreateRemoteEvent("UpdateInventory")
	updateInventoryEvent.OnClientEvent:Connect(function(engines, canisters, currentFuel)
		gameState.engineCount = engines
		gameState.canisterCount = canisters
		gameState.currentFuel = currentFuel
		gameState.maxFuel = GameConfig.Helicopter.BASE_FUEL + (GameConfig.Helicopter.FUEL_PER_CANISTER * canisters)

		MainHUD:UpdateEngineCount(engines)
		MainHUD:UpdateCanisterCount(canisters)
		MainHUD:UpdateFuel(currentFuel, gameState.maxFuel)
	end)

	-- Update BrainBucks
	local updateBrainBucksEvent = GetOrCreateRemoteEvent("UpdateBrainBucks")
	updateBrainBucksEvent.OnClientEvent:Connect(function(brainBucks)
		gameState.brainBucks = brainBucks
		MainHUD:UpdateBrainBucks(brainBucks)
	end)

	-- Update leaderboard
	local updateLeaderboardEvent = GetOrCreateRemoteEvent("UpdateLeaderboard")
	updateLeaderboardEvent.OnClientEvent:Connect(function(leaderboardData)
		playerStats = leaderboardData
		Leaderboard:Refresh(leaderboardData)
	end)

	-- Player death
	local playerDiedEvent = GetOrCreateRemoteEvent("PlayerDied")
	playerDiedEvent.OnClientEvent:Connect(function(respawnSeconds)
		gameState.isDead = true
		local respawnCallback = function()
			gameState.isDead = false
		end
		DeathScreen:Show(respawnCallback, respawnSeconds or 5)
	end)

	-- Collection updated
	local collectionUpdatedEvent = GetOrCreateRemoteEvent("CollectionUpdated")
	collectionUpdatedEvent.OnClientEvent:Connect(function(tierNumber, isCollected)
		CollectionGUI:SetTierCollected(tierNumber, isCollected)
	end)

	-- Music volume change
	MusicSettings.OnVolumeChanged = function(volume)
		local musicVolumeEvent = GetOrCreateRemoteEvent("MusicVolumeChanged")
		musicVolumeEvent:FireServer(volume)
	end
end

--[[
	Main initialization sequence
]]
local function Initialize()
	print("[HUDClient] Starting HUD client initialization...")

	-- Wait a frame to ensure PlayerGui is ready
	task.wait(0.1)

	-- Initialize all HUD modules
	InitializeHUD()

	-- Set up input handlers and event connections
	SetupInputHandlers()
	ConnectToRemoteEvents()

	-- Set initial HUD values
	MainHUD:UpdateFuel(gameState.currentFuel, gameState.maxFuel)
	MainHUD:UpdateWave(gameState.currentWave)
	MainHUD:UpdateEngineCount(gameState.engineCount)
	MainHUD:UpdateCanisterCount(gameState.canisterCount)
	MainHUD:UpdateBrainBucks(gameState.brainBucks)

	print("[HUDClient] HUD client fully initialized and ready!")
end

-- Start the system
pcall(Initialize)
