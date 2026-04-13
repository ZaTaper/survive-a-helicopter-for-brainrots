-- HelicopterSystem.server.lua
-- Server-side helicopter logic and management
-- Handles construction, fuel tracking, speed calculations, and flight mechanics
-- Implements starter helicopter system with upgrade tracking and death mechanics
-- Includes grab/carry/drop system for brainrot collection

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local HelicopterData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HelicopterData"))
local HelicopterModel = require(ServerStorage:WaitForChild("Storage"):WaitForChild("HelicopterModel"))

-- Player helicopter data tracking
local playerHelicopterData = {}

-- Wait for HelicopterRemotes folder created by AAA_Setup
local HelicopterRemotesFolder = ReplicatedStorage:WaitForChild("HelicopterRemotes", 15)
if not HelicopterRemotesFolder then
	warn("[HelicopterSystem] HelicopterRemotes not found! Creating fallback...")
	HelicopterRemotesFolder = Instance.new("Folder")
	HelicopterRemotesFolder.Name = "HelicopterRemotes"
	HelicopterRemotesFolder.Parent = ReplicatedStorage
end

local RemoteEvents = {
	folder = HelicopterRemotesFolder,
	buildHelicopter = HelicopterRemotesFolder:WaitForChild("BuildHelicopter"),
	addEngine = HelicopterRemotesFolder:WaitForChild("AddEngine"),
	addFuelCanister = HelicopterRemotesFolder:WaitForChild("AddFuelCanister"),
	activateHelicopter = HelicopterRemotesFolder:WaitForChild("ActivateHelicopter"),
	deactivateHelicopter = HelicopterRemotesFolder:WaitForChild("DeactivateHelicopter"),
	getHelicopterStats = HelicopterRemotesFolder:WaitForChild("GetHelicopterStats"),
}

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
		carryingBrainrot = nil,
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
	-- Include carry state
	stats.carryingBrainrot = data.carryingBrainrot
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
	data.carryingBrainrot = nil
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

-- Handle grabbing a brainrot
local function HandleGrabBrainrot(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
		return
	end

	local data = playerHelicopterData[userId]

	-- Check player has helicopter and it's active
	if not data.helicopterModel or not data.isActive then
		return
	end

	-- Check not already carrying
	if data.carryingBrainrot ~= nil then
		return
	end

	-- Get player position
	local character = data.character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local position = humanoidRootPart.Position

	-- Try to get nearest brainrot within 25 studs
	local success, brainrotData = pcall(function()
		return _G.BrainrotSystem.GetNearestBrainrot(position, 25)
	end)

	if not success then
		print("Error getting nearest brainrot: " .. tostring(brainrotData))
		return
	end

	if not brainrotData then
		return
	end

	-- Try to grab the brainrot
	local grabSuccess, grabResult = pcall(function()
		return _G.BrainrotSystem.GrabBrainrot(brainrotData.uniqueId)
	end)

	if not grabSuccess then
		print("Error grabbing brainrot: " .. tostring(grabResult))
		return
	end

	-- Store in carry data (use grabResult for money since GetNearestBrainrot doesn't include it)
	data.carryingBrainrot = {
		uniqueId = brainrotData.uniqueId,
		tierName = grabResult.tierName or brainrotData.tierName,
		tierIndex = grabResult.tierIndex or brainrotData.tierIndex,
		displayName = grabResult.displayName or brainrotData.displayName,
		money = grabResult.money or 0,
	}

	-- Fire CarryStateChanged to player
	local carryEvent = ReplicatedStorage:WaitForChild("CarryStateChanged")
	carryEvent:FireClient(player, data.carryingBrainrot)

	-- Fire BrainrotGrabbed to all clients
	local grabbedEvent = ReplicatedStorage:WaitForChild("BrainrotGrabbed")
	grabbedEvent:FireAllClients(brainrotData.uniqueId)

	print("Player " .. player.Name .. " grabbed brainrot: " .. brainrotData.uniqueId)
end

-- Handle dropping a brainrot
local function HandleDropBrainrot(player)
	local userId = player.UserId
	if not playerHelicopterData[userId] then
		InitializePlayerHelicopter(player)
		return
	end

	local data = playerHelicopterData[userId]

	-- Check player is carrying something
	if data.carryingBrainrot == nil then
		return
	end

	-- Get player position
	local character = data.character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local position = humanoidRootPart.Position

	-- Check if player is at their base (30 stud check)
	local atBase = false
	local checkBaseSuccess, checkBaseResult = pcall(function()
		return _G.BaseSystem.IsInPlayerBase(position, player)
	end)

	if checkBaseSuccess then
		atBase = checkBaseResult
	else
		print("Error checking base: " .. tostring(checkBaseResult))
	end

	if atBase then
		-- Get tier index from carry data
		local tierIndex = data.carryingBrainrot.tierIndex
		local brainrotMoney = data.carryingBrainrot.money
		local brainrotDisplayName = data.carryingBrainrot.displayName
		local brainrotUniqueId = data.carryingBrainrot.uniqueId

		-- Add to collected brainrots
		local addCollectedSuccess, addCollectedResult = pcall(function()
			return _G.BaseSystem.AddCollectedBrainrot(player, tierIndex)
		end)

		if not addCollectedSuccess then
			print("Error adding collected brainrot: " .. tostring(addCollectedResult))
		end

		-- Add floating brainrot for display
		local addFloatingSuccess, addFloatingResult = pcall(function()
			return _G.BaseSystem.AddFloatingBrainrot(player, tierIndex)
		end)

		if not addFloatingSuccess then
			print("Error adding floating brainrot: " .. tostring(addFloatingResult))
		end

		-- Award instant money bonus
		local awardMoneySuccess, awardMoneyResult = pcall(function()
			return _G.MoneySystem.AddMoney(player, brainrotMoney, "Delivered " .. brainrotDisplayName)
		end)

		if not awardMoneySuccess then
			print("Error awarding money: " .. tostring(awardMoneyResult))
		end

		-- Fire BrainrotDroppedAtBase to all clients
		local droppedEvent = ReplicatedStorage:WaitForChild("BrainrotDroppedAtBase")
		droppedEvent:FireAllClients(brainrotUniqueId, player.UserId)

		print("Player " .. player.Name .. " dropped brainrot at base: " .. brainrotUniqueId)
	end

	-- Clear carry state
	data.carryingBrainrot = nil

	-- Fire CarryStateChanged to player
	local carryEvent = ReplicatedStorage:WaitForChild("CarryStateChanged")
	carryEvent:FireClient(player, nil)
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

-- Connect to grab/drop brainrot events
local grabEvent = ReplicatedStorage:WaitForChild("GrabBrainrot")
local dropEvent = ReplicatedStorage:WaitForChild("DropBrainrot")

grabEvent.OnServerEvent:Connect(function(player)
	HandleGrabBrainrot(player)
end)

dropEvent.OnServerEvent:Connect(function(player)
	HandleDropBrainrot(player)
end)

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
task.spawn(function()
	while true do
		UpdateFuelDrain()
	end
end)

print("HelicopterSystem loaded and ready")
