-- DataManager.server.lua
-- Server-side data persistence using DataStoreService
-- Handles saving/loading player data with error handling, retries, and session locking

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = {}

-- Configuration
local CONFIG = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerData"))

-- Data store settings
local DATA_STORE_NAME = "PlayerData_v1"
local AUTO_SAVE_INTERVAL = 60 -- Auto-save every 60 seconds
local RETRY_ATTEMPTS = 3
local RETRY_DELAY = 1 -- Second

-- RemoteEvent for sending player data to client
local playerDataEvent = Instance.new("RemoteEvent")
playerDataEvent.Name = "PlayerDataLoaded"
playerDataEvent.Parent = ReplicatedStorage

-- RemoteFunction for client to request stat update
local updateStatsFunction = Instance.new("RemoteFunction")
updateStatsFunction.Name = "UpdateStats"
updateStatsFunction.Parent = ReplicatedStorage

-- Stores loaded player data in memory
-- Format: { [player] = { data = playerData, lastSaved = timestamp, changed = boolean } }
local playerDataCache = {}

-- Session lock tracking to prevent data corruption
-- Format: { [userId] = { sessionId = string, timestamp = number } }
local sessionLocks = {}

-- Get or create data store
local function GetDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)

	if not success then
		warn("[DataManager] Failed to get DataStore: " .. tostring(dataStore))
		return nil
	end

	return dataStore
end

-- Generate unique session ID for this server
local SERVER_SESSION_ID = game:GetService("HttpService"):GenerateGUID(false)

-- Create session lock
-- @param userId number - The user ID
-- @return boolean - True if lock created, false if someone else has it
local function CreateSessionLock(userId)
	local dataStore = GetDataStore()
	if not dataStore then return false end

	local lockKey = "session_lock_" .. userId

	for attempt = 1, RETRY_ATTEMPTS do
		local success, result = pcall(function()
			return dataStore:UpdateAsync(lockKey, function(oldValue)
				local now = os.time()

				-- Check if lock exists and is still valid (not expired after 5 minutes)
				if oldValue then
					local lockData = game:GetService("HttpService"):JSONDecode(oldValue)
					if now - lockData.timestamp < 300 then
						return nil -- Lock still valid, don't update
					end
				end

				-- Create new lock
				return game:GetService("HttpService"):JSONEncode({
					sessionId = SERVER_SESSION_ID,
					timestamp = now
				})
			end)
		end)

		if success and result then
			-- Verify we got the lock
			if result == SERVER_SESSION_ID then
				sessionLocks[userId] = { sessionId = SERVER_SESSION_ID, timestamp = os.time() }
				return true
			end
		end

		if attempt < RETRY_ATTEMPTS then
			wait(RETRY_DELAY)
		end
	end

	return false
end

-- Release session lock
-- @param userId number - The user ID
local function ReleaseSessionLock(userId)
	local dataStore = GetDataStore()
	if not dataStore then return end

	sessionLocks[userId] = nil

	local lockKey = "session_lock_" .. userId

	pcall(function()
		dataStore:RemoveAsync(lockKey)
	end)
end

-- Load player data from data store with retries
-- @param player Player - The player to load data for
-- @return table - Player data, or nil if failed
local function LoadPlayerData(player)
	local dataStore = GetDataStore()
	if not dataStore then return nil end

	local userId = player.UserId
	local key = "player_" .. userId

	for attempt = 1, RETRY_ATTEMPTS do
		local success, data = pcall(function()
			return dataStore:GetAsync(key)
		end)

		if success then
			if data then
				-- Parse and validate loaded data
				local decoded = game:GetService("HttpService"):JSONDecode(data)
				local isValid, errorMsg = PlayerData.ValidateData(decoded)

				if isValid then
					return PlayerData.SanitizeData(decoded, CONFIG)
				else
					warn("[DataManager] Invalid data for player " .. player.Name .. ": " .. errorMsg)
					return PlayerData.CreateNewPlayerData()
				end
			else
				-- No data exists, create new
				return PlayerData.CreateNewPlayerData()
			end
		end

		if attempt < RETRY_ATTEMPTS then
			wait(RETRY_DELAY)
		end
	end

	warn("[DataManager] Failed to load data for player " .. player.Name .. " after " .. RETRY_ATTEMPTS .. " attempts")
	return nil
end

-- Save player data to data store with retries
-- @param player Player - The player to save
-- @param data table - The data to save
-- @return boolean - Success
local function SavePlayerData(player, data)
	if not player:IsDescendantOf(Players) then
		return false -- Player already left
	end

	local dataStore = GetDataStore()
	if not dataStore then return false end

	local userId = player.UserId
	local key = "player_" .. userId

	-- Update last saved timestamp
	data.lastUpdated = os.time()

	local encoded = game:GetService("HttpService"):JSONEncode(data)

	for attempt = 1, RETRY_ATTEMPTS do
		local success, result = pcall(function()
			return dataStore:SetAsync(key, encoded)
		end)

		if success then
			if playerDataCache[player] then
				playerDataCache[player].lastSaved = os.time()
				playerDataCache[player].changed = false
			end
			return true
		end

		if attempt < RETRY_ATTEMPTS then
			wait(RETRY_DELAY)
		end
	end

	warn("[DataManager] Failed to save data for player " .. player.Name .. " after " .. RETRY_ATTEMPTS .. " attempts")
	return false
end

-- Initialize a player's data
-- @param player Player - The player to initialize
-- @return boolean - Success
function DataManager.InitializePlayer(player)
	if playerDataCache[player] then
		return true -- Already initialized
	end

	-- Try to create session lock
	if not CreateSessionLock(player.UserId) then
		warn("[DataManager] Could not acquire session lock for player " .. player.Name)
		return false
	end

	-- Load data from data store
	local data = LoadPlayerData(player)
	if not data then
		ReleaseSessionLock(player.UserId)
		return false
	end

	-- Set initial fuel if first time
	if data.gamesPlayed == 0 then
		data.currentFuel = CONFIG.Helicopter.BASE_FUEL
	end

	-- Cache in memory
	playerDataCache[player] = {
		data = data,
		lastSaved = os.time(),
		changed = false
	}

	-- Send to client
	playerDataEvent:FireClient(player, PlayerData.FormatForClient(data))

	return true
end

-- Get player's data
-- @param player Player - The player
-- @return table - Player data, or nil if not initialized
function DataManager.GetPlayerData(player)
	if not playerDataCache[player] then
		return nil
	end
	return playerDataCache[player].data
end

-- Update a player's statistic
-- @param player Player - The player
-- @param statName string - Name of stat to update
-- @param value number - New value
-- @return boolean - Success
function DataManager.UpdateStat(player, statName, value)
	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	local validStats = {
		"totalKills", "totalWavesSurvived", "highestWave", "gamesPlayed", "bestHelicopterSpeed"
	}

	-- Check if stat exists
	local isValid = false
	for _, stat in ipairs(validStats) do
		if stat == statName then
			isValid = true
			break
		end
	end

	if not isValid then
		warn("[DataManager] Invalid stat name: " .. statName)
		return false
	end

	-- Update stat
	data[statName] = value
	playerDataCache[player].changed = true

	return true
end

-- Increment a player's statistic
-- @param player Player - The player
-- @param statName string - Name of stat to increment
-- @param amount number - Amount to add (default 1)
-- @return boolean - Success
function DataManager.IncrementStat(player, statName, amount)
	amount = amount or 1
	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	if not data[statName] then
		return false
	end

	if type(data[statName]) ~= "number" then
		return false
	end

	data[statName] = data[statName] + amount
	playerDataCache[player].changed = true

	return true
end

-- Mark player data as changed
-- @param player Player - The player
function DataManager.MarkDirty(player)
	if playerDataCache[player] then
		playerDataCache[player].changed = true
	end
end

-- Manually save player data (also called periodically)
-- @param player Player - The player
-- @return boolean - Success
function DataManager.SavePlayer(player)
	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	return SavePlayerData(player, data)
end

-- Clean up player on disconnect
-- @param player Player - The player
function DataManager.CleanupPlayer(player)
	local data = DataManager.GetPlayerData(player)
	if data then
		-- Save final data
		SavePlayerData(player, data)
	end

	ReleaseSessionLock(player.UserId)
	playerDataCache[player] = nil
end

-- Get all currently cached player count
-- @return number - Count of cached players
function DataManager.GetCachedPlayerCount()
	local count = 0
	for _ in pairs(playerDataCache) do
		count = count + 1
	end
	return count
end

-- RemoteFunction handler for stat updates from client
-- The client sends what stat changed; we update it
updateStatsFunction.OnServerInvoke = function(player, statName, value)
	return DataManager.UpdateStat(player, statName, value)
end

-- Auto-save loop
-- Saves all players with changed data periodically
local function AutoSaveLoop()
	while true do
		wait(AUTO_SAVE_INTERVAL)

		for player, cache in pairs(playerDataCache) do
			if cache.changed and player:IsDescendantOf(Players) then
				SavePlayerData(player, cache.data)
			end
		end
	end
end

-- Start auto-save loop in background
task.spawn(AutoSaveLoop)

-- BindToClose for emergency saves when server shuts down
game:BindToClose(function()
	print("[DataManager] Server closing, saving all player data...")

	-- Save all players
	for player, cache in pairs(playerDataCache) do
		SavePlayerData(player, cache.data)
	end

	-- Release all locks
	for userId in pairs(sessionLocks) do
		ReleaseSessionLock(userId)
	end

	print("[DataManager] All player data saved")
end)

-- Connect to player removal for cleanup
Players.PlayerRemoving:Connect(function(player)
	DataManager.CleanupPlayer(player)
end)

-- Debug: Print current state every 5 minutes
local function DebugPrintState()
	while true do
		wait(300)
		print("[DataManager] Cached players: " .. DataManager.GetCachedPlayerCount())
	end
end

task.spawn(DebugPrintState)

return DataManager
