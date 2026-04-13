-- InventorySystem.server.lua
-- Server-side inventory management for players
-- Handles adding/removing items, building helicopters, and resetting fuel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventorySystem = {}

-- Configuration
local CONFIG = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerData"))

-- Stores player inventory in memory during session
-- Format: { [player] = playerDataTable }
local playerInventories = {}

-- Wait for RemoteEvents created by AAA_Setup
local inventoryUpdateEvent = ReplicatedStorage:WaitForChild("InventoryUpdate")
local getInventoryFunction = ReplicatedStorage:WaitForChild("GetInventory")

-- Initialize a player's inventory in memory
-- @param player Player - The player to initialize
-- @param initialData table - Player's data from data store
function InventorySystem.InitializePlayer(player, initialData)
	if not playerInventories[player] then
		playerInventories[player] = initialData or PlayerData.CreateNewPlayerData()
	end
end

-- Get a player's current inventory (in-memory copy)
-- @param player Player - The player
-- @return table - Inventory data
function InventorySystem.GetInventory(player)
	if not playerInventories[player] then
		InventorySystem.InitializePlayer(player)
	end
	return playerInventories[player]
end

-- Add items to player inventory
-- Validates against maximum limits from config
-- @param player Player - The player
-- @param itemType string - Item type (from PlayerData.ItemType)
-- @param amount number - Amount to add
-- @return boolean - Success
-- @return string - Result message
function InventorySystem.AddItem(player, itemType, amount)
	if not player:IsDescendantOf(Players) then
		return false, "Player not found"
	end

	if type(amount) ~= "number" or amount < 0 then
		return false, "Invalid amount"
	end

	local inventory = InventorySystem.GetInventory(player)

	if itemType == PlayerData.ItemType.ENGINE then
		local maxEngines = CONFIG.Helicopter.MAX_ENGINES
		local newCount = inventory.inventory.engine + amount

		if newCount > maxEngines then
			local excessAmount = newCount - maxEngines
			inventory.inventory.engine = maxEngines
			inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
			return true, "Added " .. (amount - excessAmount) .. " engines (inventory full, " .. excessAmount .. " dropped)"
		end

		inventory.inventory.engine = newCount
		inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
		return true, "Added " .. amount .. " engines"

	elseif itemType == PlayerData.ItemType.FUEL_CANISTER then
		local maxCanisters = CONFIG.Helicopter.MAX_FUEL_CANISTERS
		local newCount = inventory.inventory.fuelCanister + amount

		if newCount > maxCanisters then
			local excessAmount = newCount - maxCanisters
			inventory.inventory.fuelCanister = maxCanisters
			inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
			return true, "Added " .. (amount - excessAmount) .. " fuel canisters (inventory full, " .. excessAmount .. " dropped)"
		end

		inventory.inventory.fuelCanister = newCount
		inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
		return true, "Added " .. amount .. " fuel canisters"

	else
		return false, "Unknown item type: " .. tostring(itemType)
	end
end

-- Remove items from player inventory
-- @param player Player - The player
-- @param itemType string - Item type (from PlayerData.ItemType)
-- @param amount number - Amount to remove
-- @return boolean - Success
-- @return string - Result message
function InventorySystem.RemoveItem(player, itemType, amount)
	if not player:IsDescendantOf(Players) then
		return false, "Player not found"
	end

	if type(amount) ~= "number" or amount < 0 then
		return false, "Invalid amount"
	end

	local inventory = InventorySystem.GetInventory(player)
	local currentCount = 0

	if itemType == PlayerData.ItemType.ENGINE then
		currentCount = inventory.inventory.engine

		if currentCount < amount then
			return false, "Not enough engines (have: " .. currentCount .. ", need: " .. amount .. ")"
		end

		inventory.inventory.engine = currentCount - amount
		inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
		return true, "Removed " .. amount .. " engines"

	elseif itemType == PlayerData.ItemType.FUEL_CANISTER then
		currentCount = inventory.inventory.fuelCanister

		if currentCount < amount then
			return false, "Not enough fuel canisters (have: " .. currentCount .. ", need: " .. amount .. ")"
		end

		inventory.inventory.fuelCanister = currentCount - amount
		inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
		return true, "Removed " .. amount .. " fuel canisters"

	else
		return false, "Unknown item type: " .. tostring(itemType)
	end
end

-- Reset fuel to BASE_FUEL amount (called on player death)
-- @param player Player - The player
-- @return boolean - Success
function InventorySystem.ResetFuel(player)
	if not player:IsDescendantOf(Players) then
		return false
	end

	local inventory = InventorySystem.GetInventory(player)
	inventory.currentFuel = CONFIG.Helicopter.BASE_FUEL
	inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
	return true
end

-- Set fuel to a specific amount
-- @param player Player - The player
-- @param amount number - New fuel amount
-- @return boolean - Success
function InventorySystem.SetFuel(player, amount)
	if not player:IsDescendantOf(Players) then
		return false
	end

	local inventory = InventorySystem.GetInventory(player)
	inventory.currentFuel = math.max(0, amount)
	inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
	return true
end

-- Use items from inventory to build helicopter
-- Consumes engines and fuel canisters according to selection
-- @param player Player - The player
-- @param engineCount number - Number of engines to use
-- @param fuelCanisterCount number - Number of fuel canisters to use
-- @return boolean - Success
-- @return string - Result message
function InventorySystem.UseItemsForHelicopter(player, engineCount, fuelCanisterCount)
	if not player:IsDescendantOf(Players) then
		return false, "Player not found"
	end

	if type(engineCount) ~= "number" or type(fuelCanisterCount) ~= "number" then
		return false, "Invalid parameters"
	end

	-- Validate against config limits
	if engineCount < 0 or engineCount > CONFIG.Helicopter.MAX_ENGINES then
		return false, "Invalid engine count (0-" .. CONFIG.Helicopter.MAX_ENGINES .. ")"
	end

	if fuelCanisterCount < 0 or fuelCanisterCount > CONFIG.Helicopter.MAX_FUEL_CANISTERS then
		return false, "Invalid fuel canister count (0-" .. CONFIG.Helicopter.MAX_FUEL_CANISTERS .. ")"
	end

	local inventory = InventorySystem.GetInventory(player)

	-- Check if player has enough items
	if inventory.inventory.engine < engineCount then
		return false, "Not enough engines (have: " .. inventory.inventory.engine .. ", need: " .. engineCount .. ")"
	end

	if inventory.inventory.fuelCanister < fuelCanisterCount then
		return false, "Not enough fuel canisters (have: " .. inventory.inventory.fuelCanister .. ", need: " .. fuelCanisterCount .. ")"
	end

	-- Consume items
	inventory.inventory.engine = inventory.inventory.engine - engineCount
	inventory.inventory.fuelCanister = inventory.inventory.fuelCanister - fuelCanisterCount

	-- Calculate and set fuel amount
	local totalFuel = CONFIG.Helicopter.BASE_FUEL + (CONFIG.Helicopter.FUEL_PER_CANISTER * fuelCanisterCount)
	inventory.currentFuel = totalFuel

	inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))
	return true, "Built helicopter with " .. engineCount .. " engines and " .. fuelCanisterCount .. " fuel canisters"
end

-- Get current fuel amount
-- @param player Player - The player
-- @return number - Current fuel
function InventorySystem.GetFuel(player)
	local inventory = InventorySystem.GetInventory(player)
	return inventory.currentFuel
end

-- Drain fuel (call this periodically during helicopter flight)
-- @param player Player - The player
-- @param amount number - Amount of fuel to drain
-- @return boolean - Success (false if fuel depleted)
function InventorySystem.DrainFuel(player, amount)
	if not player:IsDescendantOf(Players) then
		return true -- Already left, so "success"
	end

	local inventory = InventorySystem.GetInventory(player)
	inventory.currentFuel = math.max(0, inventory.currentFuel - amount)

	-- Only send update if fuel significantly changed to reduce network traffic
	inventoryUpdateEvent:FireClient(player, PlayerData.FormatForClient(inventory))

	return inventory.currentFuel > 0
end

-- Clean up player inventory on disconnect
-- @param player Player - The player
function InventorySystem.CleanupPlayer(player)
	playerInventories[player] = nil
end

-- RemoteFunction handler for getting inventory
getInventoryFunction.OnServerInvoke = function(player)
	local inventory = InventorySystem.GetInventory(player)
	return PlayerData.FormatForClient(inventory)
end

-- Connect to player removal for cleanup
Players.PlayerRemoving:Connect(function(player)
	InventorySystem.CleanupPlayer(player)
end)

return InventorySystem
