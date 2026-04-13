-- MoneySystem.server.lua
-- Central money management system for all players
-- Tracks player money balances, awards money for kills and passive generation
-- Manages all currency transactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local MoneySystem = {}

-- Storage for player money (cached in memory for fast access)
-- Format: { [player] = amount }
local playerMoney = {}

-- RemoteEvent for notifying clients of money changes
local moneyChangedEvent = Instance.new("RemoteEvent")
moneyChangedEvent.Name = "MoneyChanged"
moneyChangedEvent.Parent = ReplicatedStorage

-- RemoteFunction for client to check their balance
local getBalanceFunction = Instance.new("RemoteFunction")
getBalanceFunction.Name = "GetBalance"
getBalanceFunction.Parent = ReplicatedStorage

-- RemoteEvent for displaying floating money notifications
local floatingTextEvent = Instance.new("RemoteEvent")
floatingTextEvent.Name = "ShowFloatingMoney"
floatingTextEvent.Parent = ReplicatedStorage

-- Helper function defined before use: Initialize money for a player
-- @param player Player - The player to initialize
-- @param initialAmount number - Starting money amount
-- @return number - The player's starting money
local function InitializePlayerMoney(player, initialAmount)
	initialAmount = initialAmount or GameConfig.Currency.START_MONEY
	playerMoney[player] = initialAmount
	return initialAmount
end

-- Add money to a player's balance
-- @param player Player - The player to give money to
-- @param amount number - Amount of money to add
-- @param reason string - Reason for earning money (for logging)
-- @return number - The new balance, or nil if failed
function MoneySystem.AddMoney(player, amount, reason)
	if not player:IsDescendantOf(Players) then
		return nil
	end

	if not playerMoney[player] then
		InitializePlayerMoney(player)
	end

	-- Validate amount
	if type(amount) ~= "number" or amount < 0 then
		warn("[MoneySystem] Invalid amount for AddMoney: " .. tostring(amount))
		return nil
	end

	-- Add to balance
	playerMoney[player] = playerMoney[player] + amount

	-- Log the transaction
	reason = reason or "Unknown"
	print("[MoneySystem] " .. player.Name .. " earned " .. amount .. " " .. GameConfig.Currency.CURRENCY_NAME .. " (" .. reason .. ")")

	-- Fire event to notify client
	moneyChangedEvent:FireClient(player, playerMoney[player], "add", amount)

	-- Show floating text notification on player's screen
	floatingTextEvent:FireClient(player, amount, reason)

	return playerMoney[player]
end

-- Remove money from a player's balance
-- @param player Player - The player to take money from
-- @param amount number - Amount of money to remove
-- @param reason string - Reason for spending money (for logging)
-- @return boolean, number - Success flag and new balance (or nil if failed)
function MoneySystem.RemoveMoney(player, amount, reason)
	if not player:IsDescendantOf(Players) then
		return false, nil
	end

	if not playerMoney[player] then
		InitializePlayerMoney(player)
	end

	-- Validate amount
	if type(amount) ~= "number" or amount < 0 then
		warn("[MoneySystem] Invalid amount for RemoveMoney: " .. tostring(amount))
		return false, nil
	end

	-- Check if player has enough money
	if playerMoney[player] < amount then
		print("[MoneySystem] " .. player.Name .. " does not have enough money to spend " .. amount)
		return false, playerMoney[player]
	end

	-- Remove from balance
	playerMoney[player] = playerMoney[player] - amount

	-- Log the transaction
	reason = reason or "Unknown"
	print("[MoneySystem] " .. player.Name .. " spent " .. amount .. " " .. GameConfig.Currency.CURRENCY_NAME .. " (" .. reason .. ")")

	-- Fire event to notify client
	moneyChangedEvent:FireClient(player, playerMoney[player], "remove", amount)

	return true, playerMoney[player]
end

-- Get a player's current balance
-- @param player Player - The player
-- @return number - The player's money, or nil if not initialized
function MoneySystem.GetMoney(player)
	if not playerMoney[player] then
		return InitializePlayerMoney(player)
	end
	return playerMoney[player]
end

-- Set a player's balance directly (use carefully)
-- @param player Player - The player
-- @param amount number - The new balance
-- @return number - The new balance
function MoneySystem.SetMoney(player, amount)
	if not player:IsDescendantOf(Players) then
		return nil
	end

	if type(amount) ~= "number" or amount < 0 then
		warn("[MoneySystem] Invalid amount for SetMoney: " .. tostring(amount))
		return nil
	end

	playerMoney[player] = amount

	-- Fire event to notify client
	moneyChangedEvent:FireClient(player, playerMoney[player], "set", 0)

	print("[MoneySystem] " .. player.Name .. " balance set to " .. amount)

	return playerMoney[player]
end

-- Award money for killing a brainrot
-- @param player Player - The player who made the kill
-- @param brainrotTierIndex number - Index of the tier in GameConfig.BrainrotTiers
-- @return number - Amount earned, or nil if failed
function MoneySystem.AwardBrainrotKill(player, brainrotTierIndex)
	if not player:IsDescendantOf(Players) then
		return nil
	end

	if brainrotTierIndex < 1 or brainrotTierIndex > #GameConfig.BrainrotTiers then
		warn("[MoneySystem] Invalid brainrot tier index: " .. tostring(brainrotTierIndex))
		return nil
	end

	local tierConfig = GameConfig.BrainrotTiers[brainrotTierIndex]
	local moneyReward = tierConfig.money

	-- Add the money
	local newBalance = MoneySystem.AddMoney(player, moneyReward, "Killed " .. tierConfig.name .. " brainrot")

	if newBalance then
		return moneyReward
	end

	return nil
end

-- Award money for a specific tier name
-- @param player Player - The player who made the kill
-- @param tierName string - Name of the tier (e.g., "Common", "Rare")
-- @return number - Amount earned, or nil if failed
function MoneySystem.AwardBrainrotKillByName(player, tierName)
	-- Find the tier in GameConfig
	local tierIndex = nil
	for i, tierConfig in ipairs(GameConfig.BrainrotTiers) do
		if tierConfig.name == tierName then
			tierIndex = i
			break
		end
	end

	if not tierIndex then
		warn("[MoneySystem] Unknown brainrot tier: " .. tierName)
		return nil
	end

	return MoneySystem.AwardBrainrotKill(player, tierIndex)
end

-- Get all player money (for leaderboard, admin purposes)
-- @return table - Dictionary of { playerName = amount }
function MoneySystem.GetAllPlayerMoney()
	local result = {}
	for player, money in pairs(playerMoney) do
		if player:IsDescendantOf(Players) then
			result[player.Name] = money
		end
	end
	return result
end

-- Get cached player count
-- @return number - Number of players with money tracked
function MoneySystem.GetTrackedPlayerCount()
	local count = 0
	for player in pairs(playerMoney) do
		if player:IsDescendantOf(Players) then
			count = count + 1
		end
	end
	return count
end

-- RemoteFunction handler: Client requests their balance
getBalanceFunction.OnServerInvoke = function(player)
	return MoneySystem.GetMoney(player)
end

-- Initialize money when player joins
Players.PlayerAdded:Connect(function(player)
	-- Wait a moment to ensure player data is loaded
	task.wait(0.5)

	-- Initialize with starting money from GameConfig
	InitializePlayerMoney(player, GameConfig.Currency.START_MONEY)
	print("[MoneySystem] Initialized " .. player.Name .. " with " .. GameConfig.Currency.START_MONEY .. " " .. GameConfig.Currency.CURRENCY_NAME)
end)

-- Clean up money tracking when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerMoney[player] = nil
end)

-- Debug: Print money stats every 60 seconds
local function DebugPrintMoneyStats()
	while true do
		task.wait(60)
		local allMoney = MoneySystem.GetAllPlayerMoney()
		print("[MoneySystem] Total players tracked: " .. MoneySystem.GetTrackedPlayerCount())
		for playerName, money in pairs(allMoney) do
			print("  - " .. playerName .. ": " .. money .. " " .. GameConfig.Currency.CURRENCY_NAME)
		end
	end
end

task.spawn(DebugPrintMoneyStats)

return MoneySystem
