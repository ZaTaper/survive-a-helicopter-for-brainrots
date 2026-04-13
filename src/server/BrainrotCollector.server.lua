-- BrainrotCollector.server.lua
-- Brainrot collection system for players
-- Handles tracking collected brainrots, saving to DataStore, and notifications
-- Players can collect multiple copies of the same brainrot tier

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

-- BaseSystem will be available in _G after it loads
local function GetBaseSystem()
	return _G.BaseSystem
end

local BrainrotCollector = {}

-- Collection chances per tier (percentage)
local COLLECTION_CHANCES = {
	80,  -- Common
	60,  -- Uncommon
	40,  -- Rare
	25,  -- Epic
	15,  -- Mythic
	8,   -- Secret
	4,   -- Celestial
	2,   -- OP
}

-- Data store for persistent collection data
local COLLECTION_STORE_NAME = "BrainrotCollections_v1"
local RETRY_ATTEMPTS = 3
local RETRY_DELAY = 1

-- In-memory cache of player collections
-- Format: { [player] = { [tierName] = { count, timestamp } } }
local playerCollections = {}

-- Wait for RemoteEvents created by AAA_Setup
local collectionEvent = ReplicatedStorage:WaitForChild("BrainrotCollected")
local collectionUpdatedEvent = ReplicatedStorage:WaitForChild("CollectionUpdated")
local getCollectionFunction = ReplicatedStorage:WaitForChild("GetBrainrotCollection")

-- Get the collection data store
local function GetCollectionDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore(COLLECTION_STORE_NAME)
	end)

	if not success then
		warn("[BrainrotCollector] Failed to get DataStore: " .. tostring(dataStore))
		return nil
	end

	return dataStore
end

-- Load player's collection from data store
local function LoadPlayerCollection(player)
	local dataStore = GetCollectionDataStore()
	if not dataStore then return nil end

	local userId = player.UserId
	local key = "collection_" .. userId

	for attempt = 1, RETRY_ATTEMPTS do
		local success, data = pcall(function()
			return dataStore:GetAsync(key)
		end)

		if success then
			if data then
				-- Parse collection data
				local decoded = game:GetService("HttpService"):JSONDecode(data)
				return decoded or {}
			else
				-- No existing collection
				return {}
			end
		end

		if attempt < RETRY_ATTEMPTS then
			task.wait(RETRY_DELAY)
		end
	end

	warn("[BrainrotCollector] Failed to load collection for player " .. player.Name)
	return nil
end

-- Save player's collection to data store
local function SavePlayerCollection(player, collection)
	if not player:IsDescendantOf(Players) then
		return false
	end

	local dataStore = GetCollectionDataStore()
	if not dataStore then return false end

	local userId = player.UserId
	local key = "collection_" .. userId

	local encoded = game:GetService("HttpService"):JSONEncode(collection)

	for attempt = 1, RETRY_ATTEMPTS do
		local success = pcall(function()
			return dataStore:SetAsync(key, encoded)
		end)

		if success then
			return true
		end

		if attempt < RETRY_ATTEMPTS then
			task.wait(RETRY_DELAY)
		end
	end

	warn("[BrainrotCollector] Failed to save collection for player " .. player.Name)
	return false
end

-- Initialize player's collection on join
function BrainrotCollector.InitializePlayer(player)
	if playerCollections[player] then
		return -- Already initialized
	end

	local collection = LoadPlayerCollection(player)
	if collection == nil then
		collection = {}
	end

	playerCollections[player] = collection

	print("[BrainrotCollector] Initialized collection for player " .. player.Name .. " with " .. BrainrotCollector.GetTotalCollected(player) .. " brainrots")
end

-- Attempt to collect a brainrot when it dies
-- @param player Player - The player who killed the brainrot
-- @param tierName string - The tier name of the killed brainrot
-- @param displayName string - The display name of the killed brainrot
-- @return boolean - Whether the brainrot was collected
function BrainrotCollector.TryCollect(player, tierName, displayName)
	if not playerCollections[player] then
		BrainrotCollector.InitializePlayer(player)
	end

	-- Find tier index
	local tierIndex = nil
	for i, tier in ipairs(GameConfig.BrainrotTiers) do
		if tier.name == tierName then
			tierIndex = i
			break
		end
	end

	if not tierIndex then
		warn("[BrainrotCollector] Invalid tier: " .. tierName)
		return false
	end

	-- Get collection chance for this tier (percentage 0-100)
	local collectionChance = COLLECTION_CHANCES[tierIndex]
	if not collectionChance then
		collectionChance = 50 -- Default fallback
	end

	local rolled = math.random(1, 100)

	print("[BrainrotCollector] Collection roll for " .. player.Name .. " (" .. tierName .. "): " .. rolled .. "% vs " .. collectionChance .. "%")

	-- Check if collection attempt succeeds
	if rolled > collectionChance then
		return false -- Failed to collect
	end

	-- Success! Increment count for this tier
	if not playerCollections[player][tierName] then
		playerCollections[player][tierName] = { count = 0, timestamp = 0 }
	end
	playerCollections[player][tierName].count = playerCollections[player][tierName].count + 1
	playerCollections[player][tierName].timestamp = game:GetService("RunService"):GetServerTimeNow()

	-- Save to data store (async)
	task.spawn(function()
		SavePlayerCollection(player, playerCollections[player])
	end)

	-- Notify player
	collectionEvent:FireClient(player, tierName, displayName, playerCollections[player][tierName].count)

	-- Fire CollectionUpdated event with full data
	local collectionData = BrainrotCollector.GetCollectionDataForClient(player)
	collectionUpdatedEvent:FireClient(player, collectionData)

	-- Create floating visual at player's base
	local BaseSystem = GetBaseSystem()
	if BaseSystem then
		task.spawn(function()
			BaseSystem.AddFloatingBrainrot(player, tierIndex)
		end)
	end

	print("[BrainrotCollector] Player " .. player.Name .. " collected " .. tierName .. " brainrot: " .. displayName .. " (total: " .. playerCollections[player][tierName].count .. ")")

	return true
end

-- Get player's collection data
-- @param player Player - The player
-- @return table - Collection data
function BrainrotCollector.GetCollection(player)
	if not playerCollections[player] then
		BrainrotCollector.InitializePlayer(player)
	end

	return playerCollections[player]
end

-- Get formatted collection data for client (GUI)
-- @param player Player - The player
-- @return table - Formatted collection data with tier info
function BrainrotCollector.GetCollectionDataForClient(player)
	local collection = BrainrotCollector.GetCollection(player)
	local tiers = GameConfig.BrainrotTiers

	local tiersCounts = {}
	local uniqueTiersCollected = 0

	for i, tier in ipairs(tiers) do
		local tierData = collection[tier.name]
		local count = 0
		if tierData then
			count = tierData.count or 0
			if count > 0 then
				uniqueTiersCollected = uniqueTiersCollected + 1
			end
		end
		table.insert(tiersCounts, {
			tierIndex = i,
			tierName = tier.name,
			count = count,
			chance = COLLECTION_CHANCES[i] or 50,
		})
	end

	return {
		tiers = tiersCounts,
		uniqueTiersCollected = uniqueTiersCollected,
		totalTiers = #tiers,
	}
end

-- Get total number of brainrots collected by player (across all tiers)
-- @param player Player - The player
-- @return number - Total count of collected brainrots
function BrainrotCollector.GetTotalCollected(player)
	local collection = BrainrotCollector.GetCollection(player)
	local count = 0

	for _, tierData in pairs(collection) do
		if type(tierData) == "table" and tierData.count then
			count = count + tierData.count
		else
			count = count + tierData
		end
	end

	return count
end

-- Get count of a specific tier collected by player
-- @param player Player - The player
-- @param tierName string - The tier name
-- @return number - Count of this tier
function BrainrotCollector.GetTierCount(player, tierName)
	local collection = BrainrotCollector.GetCollection(player)
	local tierData = collection[tierName]
	if not tierData then
		return 0
	end
	if type(tierData) == "table" then
		return tierData.count or 0
	end
	return tierData
end

-- Check if player has collected at least one of a specific tier
-- @param player Player - The player
-- @param tierName string - The tier name
-- @return boolean - Whether collected at least one
function BrainrotCollector.HasCollected(player, tierName)
	local collection = BrainrotCollector.GetCollection(player)
	local tierData = collection[tierName]
	if not tierData then
		return false
	end
	if type(tierData) == "table" then
		return (tierData.count or 0) > 0
	end
	return tierData > 0
end

-- Get collection progress as a formatted string
-- @param player Player - The player
-- @return string - e.g., "5/8 Collected"
function BrainrotCollector.GetProgressString(player)
	local collected = BrainrotCollector.GetTotalCollected(player)
	local total = #GameConfig.BrainrotTiers

	return collected .. "/" .. total .. " Collected"
end

-- Clean up player on disconnect
function BrainrotCollector.CleanupPlayer(player)
	-- Save final collection before cleanup
	if playerCollections[player] then
		SavePlayerCollection(player, playerCollections[player])
	end

	playerCollections[player] = nil
end

-- RemoteFunction handler: Client requests collection data
getCollectionFunction.OnServerInvoke = function(player)
	return BrainrotCollector.GetCollectionDataForClient(player)
end

-- Connect to player join/leave events
Players.PlayerAdded:Connect(function(player)
	task.wait(0.1) -- Wait for player data to be initialized
	BrainrotCollector.InitializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	BrainrotCollector.CleanupPlayer(player)
end)

-- Auto-save collections every 2 minutes
local function AutoSaveCollections()
	while true do
		task.wait(120)

		for player, collection in pairs(playerCollections) do
			if player:IsDescendantOf(Players) then
				SavePlayerCollection(player, collection)
			end
		end
	end
end

task.spawn(AutoSaveCollections)

print("[BrainrotCollector] System initialized")

return BrainrotCollector
