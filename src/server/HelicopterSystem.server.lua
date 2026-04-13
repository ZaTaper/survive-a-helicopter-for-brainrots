-- HelicopterSystem.server.lua
-- Server-side helicopter logic and management
-- Handles construction, fuel tracking, speed calculations, and flight mechanics
-- Implements starter helicopter system with upgrade tracking and death mechanics

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local HelicopterData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HelicopterData"))
local HelicopterModel = require(ServerStorage:WaitForChild("Storage"):WaitForChild("HelicopterModel"))

-- Player helicopter data tracking
local playerHelicopterData = {}

-- Create RemoteEvents for client-server communication
local function CreateRemoteEvents()
	local RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "HelicopterRemotes"
	RemoteEvents.Parent = ReplicatedStorage

	local BuildHelicopterEvent = Instance.new("RemoteEvent")
	BuildHelicopterEvent.Name = "BuildHelicopter"
	BuildHelicopterEvent.Parent = RemoteEvents

	local AddEngineEvent = Instance.new("RemoteEvent")
	AddEngineEvent.Name = "AddEngine"
	AddEngineEvent.Parent = RemoteEvents

	local AddFuelCanisterEvent = Instance.new("RemoteEvent")
	AddFuelCanisterEvent.Name = "AddFuelCanister"
	AddFuelCanisterEvent.Parent = RemoteEvents

	local ActivateHelicopterEvent = Instance.new("RemoteEvent")
	ActivateHelicopterEvent.Name = "ActivateHelicopter"
	ActivateHelicopterEvent.Parent = RemoteEvents

	local DeactivateHelicopterEvent = Instance.new("RemoteEvent")
	DeactivateHelicopterEvent.Name = "DeactivateHelicopter"
	DeactivateHelicopterEvent.Parent = RemoteEvents

	local GetHelicopterStatsEvent = Instance.new("RemoteFunction")
	GetHelicopterStatsEvent.Name = "GetHelicopterStats"
	GetHelicopterStatsEvent.Parent = RemoteEvents

	return {
		folder = RemoteEvents,
		buildHelicopter = BuildHelicopterEvent,
		addEngine = AddEngineEvent,
		addFuelCanister = AddFuelCanisterEvent,
		activateHelicopter = ActivateHelicopterEvent,
		deactivateHelicopter = DeactivateHelicopterEvent,
		getHelicopterStats = GetHelicopterStatsEvent,
	}
end

local RemoteEvents = CreateRemoteEvents()

-- Initialize player helicopter data with starter helicopter
local function InitializePlayerHelicopter(player)
	local userId = player.UserId
	playerHelicopterData[userId] = {
		engines = GameConfig.StarterHelicopter.ENGINES,
		fuelCanisters = GameConfig.StarterHelicopter.FUEL_CANISTERS,
		currentFuel = GameConfig.StarterHelicopter.MAX_FUEL,
		maxFuel = GameConfig.StarterHelicopter.MAX_FUEL,
		speed = GameConfig.StarterHelicopter.SPEED,
		drainRate = HelicopterData.CalculateFuelDrainRate(
			GameConfig.StarterHelicopter.ENGINES,
			GameConfig.StarterHelicopter.FUEL_CANISTERS
		),
		helicopterModel = nil,
		isActive = false,
		character = player.Character,
		isStarterHelicopter = true,
		hasEverUpgraded = false,
	}
	print("Player " .. player.Name .. " initialized with starter helicopter")
end

-- Build the helicopter (create initial model)
local function BuildHelicopter(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]

	if data.character then
		local helicopterFolder = data.character:FindFirstChild("Helicopter")
		if helicopterFolder then
			helicopterFolder:Destroy()
		end

		data.helicopterModel = HelicopterModel.CreateHelicopter(data.character, data.engines, data.fuelCanisters)
		HelicopterModel.AnimateRotor(data.helicopterModel, 720)
	end
	print("Player " .. player.Name .. " built helicopter")
end

-- Add an engine to the helicopter (upgrade)
local function AddEngine(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]

	if data.engines >= GameConfig.Helicopter.MAX_ENGINES then
		return false
	end

	data.engines = data.engines + 1
	data.isStarterHelicopter = false
	data.hasEverUpgraded = true

	data.speed = HelicopterData.CalculateSpeed(data.engines)
	data.drainRate = HelicopterData.CalculateFuelDrainRate(data.engines, data.fuelCanisters)

	if data.helicopterModel then
		HelicopterModel.UpdateHelicopter(data.helicopterModel, data.engines, data.fuelCanisters)
	end

	print("Player " .. player.Name .. " added engine. Total: " .. data.engines)
	return true
end

-- Add a fuel canister to the helicopter (upgrade)
local function AddFuelCanister(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]

	if data.fuelCanisters >= GameConfig.Helicopter.MAX_FUEL_CANISTERS then
		return false
	end

	data.fuelCanisters = data.fuelCanisters + 1
	data.isStarterHelicopter = false
	data.hasEverUpgraded = true

	data.maxFuel = HelicopterData.CalculateMaxFuel(data.fuelCanisters)
	data.currentFuel = math.min(data.currentFuel, data.maxFuel)
	data.drainRate = HelicopterData.CalculateFuelDrainRate(data.engines, data.fuelCanisters)

	if data.helicopterModel then
		HelicopterModel.UpdateHelicopter(data.helicopterModel, data.engines, data.fuelCanisters)
	end

	print("Player " .. player.Name .. " added fuel canister. Total: " .. data.fuelCanisters)
	return true
end

-- Activate the helicopter for flight
local function ActivateHelicopter(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]
	data.isActive = true
end

-- Deactivate helicopter
local function DeactivateHelicopter(player)
	local userId = player.UserId
	if playerHelicopterData[userId] then
		playerHelicopterData[userId].isActive = false
	end
end

-- Get current helicopter stats
local function GetHelicopterStats(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]
	local stats = HelicopterData.GetHelicopterStats(data)
	-- Include isActive in stats so client knows real state
	stats.isActive = data.isActive
	-- Include whether helicopter model exists
	stats.hasHelicopter = data.helicopterModel ~= nil
	return stats
end

-- Handle player death/respawn
local function OnPlayerRespawn(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
		return
	end

	local data = playerHelicopterData[userId]

	if data.isStarterHelicopter then
		data.engines = GameConfig.StarterHelicopter.ENGINES
		data.fuelCanisters = GameConfig.StarterHelicopter.FUEL_CANISTERS
		data.maxFuel = GameConfig.StarterHelicopter.MAX_FUEL
		data.speed = GameConfig.StarterHelicopter.SPEED
	else
		data.maxFuel = HelicopterData.CalculateMaxFuel(data.fuelCanisters)
		data.speed = HelicopterData.CalculateSpeed(data.engines)
	end

	data.currentFuel = data.maxFuel
	data.isActive = false
	data.drainRate = HelicopterData.CalculateFuelDrainRate(data.engines, data.fuelCanisters)
end

-- Update fuel drain every heartbeat
local function UpdateFuelDrain()
	local deltaTime = RunService.Heartbeat:Wait()

	for userId, data in pairs(playerHelicopterData) do
		if data.isActive and data.currentFuel > 0 then
			data.currentFuel = math.max(0, data.currentFuel - (data.drainRate * deltaTime))

			if data.currentFuel <= 0 then
				data.isActive = false
			end
		end
	end
end

-- Connect RemoteEvent handlers
RemoteEvents.buildHelicopter.OnServerEvent:Connect(function(player)
	BuildHelicopter(player)
end)

RemoteEvents.addEngine.OnServerEvent:Connect(function(player)
	AddEngine(player)
end)

RemoteEvents.addFuelCanister.OnServerEvent:Connect(function(player)
	AddFuelCanister(player)
end)

RemoteEvents.activateHelicopter.OnServerEvent:Connect(function(player)
	ActivateHelicopter(player)
end)

RemoteEvents.deactivateHelicopter.OnServerEvent:Connect(function(player)
	DeactivateHelicopter(player)
end)

RemoteEvents.getHelicopterStats.OnServerInvoke = function(player)
	return GetHelicopterStats(player)
end

-- Connect to player events
Players.PlayerAdded:Connect(function(player)
	InitializePlayerHelicopter(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	playerHelicopterData[userId] = nil
end)

-- Handle character respawning
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local userId = player.UserId
		if playerHelicopterData[userId] then
			playerHelicopterData[userId].character = character
			OnPlayerRespawn(player)
		end
	end)
end)

-- Start fuel drain update loop
spawn(function()
	while true do
		UpdateFuelDrain()
	end
end)

print("HelicopterSystem loaded and ready")
