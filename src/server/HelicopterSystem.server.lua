-- HelicopterSystem.server.lua
-- Server-side helicopter logic and management
-- Handles construction, fuel tracking, speed calculations, and flight mechanics

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameConfig = require(game.ServerScriptService.Parent.shared.GameConfig)
local HelicopterData = require(game.ServerScriptService.Parent.shared.HelicopterData)
local HelicopterModel = require(game.ServerScriptService.Parent.storage.HelicopterModel)

-- Player helicopter data tracking
-- Structure: {
--   userId = {
--     engines = number,
--     fuelCanisters = number,
--     currentFuel = number,
--     maxFuel = number,
--     speed = number,
--     helicopterModel = Instance,
--     isActive = boolean,
--     character = Instance,
--   }
-- }
local playerHelicopterData = {}

-- Create RemoteEvents for client-server communication
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "HelicopterRemotes"
RemoteEvents.Parent = game.ReplicatedStorage

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

local GetHelicopterStatsEvent = Instance.new("RemoteFunction")
GetHelicopterStatsEvent.Name = "GetHelicopterStats"
GetHelicopterStatsEvent.Parent = RemoteEvents

-- Initialize player helicopter data
local function InitializePlayerHelicopter(player)
	local userId = player.UserId
	playerHelicopterData[userId] = {
		engines = 0,
		fuelCanisters = 0,
		currentFuel = GameConfig.Helicopter.BASE_FUEL,
		maxFuel = GameConfig.Helicopter.BASE_FUEL,
		speed = GameConfig.Helicopter.BASE_SPEED,
		drainRate = GameConfig.Helicopter.FUEL_DRAIN_RATE,
		helicopterModel = nil,
		isActive = false,
		character = player.Character,
	}
end

-- Build the helicopter (create initial model and set to default state)
local function BuildHelicopter(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]

	-- Create helicopter model in the player's character
	if data.character then
		local helicopterFolder = data.character:FindFirstChild("Helicopter")
		if helicopterFolder then
			helicopterFolder:Destroy()
		end

		data.helicopterModel = HelicopterModel.CreateHelicopter(data.character, data.engines, data.fuelCanisters)

		-- Start rotor animation
		HelicopterModel.AnimateRotor(data.helicopterModel, 720) -- 720 degrees per second (2 rotations)
	end
end

-- Add an engine to the helicopter
local function AddEngine(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]

	-- Check maximum engines limit
	if data.engines >= GameConfig.Helicopter.MAX_ENGINES then
		print("Player " .. player.Name .. " reached maximum engines: " .. GameConfig.Helicopter.MAX_ENGINES)
		return false
	end

	data.engines = data.engines + 1

	-- Recalculate stats
	data.speed = HelicopterData.CalculateSpeed(data.engines)
	data.drainRate = HelicopterData.CalculateFuelDrainRate(data.engines, data.fuelCanisters)

	-- Update visual model
	if data.helicopterModel then
		HelicopterModel.UpdateHelicopter(data.helicopterModel, data.engines, data.fuelCanisters)
	end

	print("Player " .. player.Name .. " added engine. Total: " .. data.engines)
	return true
end

-- Add a fuel canister to the helicopter
local function AddFuelCanister(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]

	-- Check maximum fuel canisters limit
	if data.fuelCanisters >= GameConfig.Helicopter.MAX_FUEL_CANISTERS then
		print("Player " .. player.Name .. " reached maximum fuel canisters: " .. GameConfig.Helicopter.MAX_FUEL_CANISTERS)
		return false
	end

	data.fuelCanisters = data.fuelCanisters + 1

	-- Recalculate stats
	data.maxFuel = HelicopterData.CalculateMaxFuel(data.fuelCanisters)
	data.currentFuel = math.min(data.currentFuel, data.maxFuel) -- Don't exceed new max
	data.drainRate = HelicopterData.CalculateFuelDrainRate(data.engines, data.fuelCanisters)

	-- Update visual model
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
	print("Player " .. player.Name .. " activated helicopter. Speed: " .. data.speed .. ", Current Fuel: " .. data.currentFuel)
end

-- Get current helicopter stats (RemoteFunction)
local function GetHelicopterStats(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
	end

	local data = playerHelicopterData[userId]
	return HelicopterData.GetHelicopterStats(data)
end

-- Reset fuel when player dies
local function OnPlayerDied(player)
	local userId = player.UserId
	if playerHelicopterData[userId] then
		playerHelicopterData[userId].currentFuel = GameConfig.Helicopter.BASE_FUEL
		playerHelicopterData[userId].isActive = false
		print("Player " .. player.Name .. " died. Fuel reset to " .. GameConfig.Helicopter.BASE_FUEL)
	end
end

-- Update fuel drain every frame (when helicopter is active)
local function UpdateFuelDrain()
	for userId, data in pairs(playerHelicopterData) do
		if data.isActive and data.currentFuel > 0 then
			-- Drain fuel based on delta time
			local deltaTime = RunService.Heartbeat:Wait()
			data.currentFuel = math.max(0, data.currentFuel - (data.drainRate * deltaTime))

			-- Deactivate helicopter if out of fuel
			if data.currentFuel <= 0 then
				data.isActive = false
				print("Player with userId " .. userId .. " ran out of fuel")
			end
		end
	end
end

-- Connect RemoteEvent handlers
BuildHelicopterEvent.OnServerEvent:Connect(function(player)
	BuildHelicopter(player)
end)

AddEngineEvent.OnServerEvent:Connect(function(player)
	AddEngine(player)
end)

AddFuelCanisterEvent.OnServerEvent:Connect(function(player)
	AddFuelCanister(player)
end)

ActivateHelicopterEvent.OnServerEvent:Connect(function(player)
	ActivateHelicopter(player)
end)

GetHelicopterStatsEvent.OnServerInvoke = function(player)
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
			-- Reset fuel on spawn
			OnPlayerDied(player)
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
