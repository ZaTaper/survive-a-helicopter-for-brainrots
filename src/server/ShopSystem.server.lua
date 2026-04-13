-- ShopSystem.server.lua
-- Server-side shop system for managing player purchases
-- Validates purchases server-side and deducts money

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

-- Wait for MoneySystem to be available
local MoneySystem = nil
local function WaitForMoneySystem()
	while not _G.MoneySystem do
		task.wait(0.1)
	end
	return _G.MoneySystem
end

-- Wait for Shop folder created by AAA_Setup
local ShopFolder = ReplicatedStorage:WaitForChild("Shop")

-- Wait for remote objects created by AAA_Setup
local BuyItemEvent = ShopFolder:WaitForChild("BuyItem")
local GetMoneyFunction = ShopFolder:WaitForChild("GetMoney")
local GetShopItemsFunction = ShopFolder:WaitForChild("GetShopItems")
local MoneyChangedEvent = ShopFolder:WaitForChild("MoneyChanged")
local PurchaseSuccessEvent = ShopFolder:WaitForChild("PurchaseSuccess")
local PurchaseFailedEvent = ShopFolder:WaitForChild("PurchaseFailed")

-- Item definitions with categories and prices
local ITEMS = {
	-- Helicopter Parts category
	["ENGINE"] = {
		price = 100,
		name = "Engine",
		description = "+15 Speed",
		category = "Helicopter Parts",
		icon = "⚙️",
	},
	["FUEL_CANISTER"] = {
		price = 75,
		name = "Fuel Canister",
		description = "+50 Fuel Capacity",
		category = "Helicopter Parts",
		icon = "⛽",
	},
	["ROTOR_UPGRADE"] = {
		price = 200,
		name = "Rotor Upgrade",
		description = "+10% Control",
		category = "Helicopter Parts",
		icon = "🪶",
	},

	-- Upgrades category
	["BODY_UPGRADE"] = {
		price = 150,
		name = "Body Upgrade",
		description = "+25 Health",
		category = "Upgrades",
		icon = "🛡️",
	},
	["SHIELD"] = {
		price = 300,
		name = "Shield",
		description = "Temporary damage reduction",
		category = "Upgrades",
		icon = "🔰",
	},
	["TURBO_BOOST"] = {
		price = 250,
		name = "Turbo Boost",
		description = "Temporary speed boost",
		category = "Upgrades",
		icon = "⚡",
	},

	-- Consumables category
	["FUEL_REFILL"] = {
		price = 50,
		name = "Fuel Refill",
		description = "Refills fuel to max",
		category = "Consumables",
		icon = "🪶",
	},
}

-- GetMoney RemoteFunction handler
GetMoneyFunction.OnServerInvoke = function(player)
	MoneySystem = MoneySystem or WaitForMoneySystem()
	return MoneySystem.GetMoney(player)
end

-- GetShopItems RemoteFunction handler - returns all available items
GetShopItemsFunction.OnServerInvoke = function(player)
	local itemsList = {}
	for itemType, itemData in pairs(ITEMS) do
		table.insert(itemsList, {
			id = itemType,
			name = itemData.name,
			description = itemData.description,
			price = itemData.price,
			category = itemData.category,
			icon = itemData.icon,
		})
	end
	return itemsList
end

-- BuyItem RemoteEvent handler - validate and process purchases
BuyItemEvent.OnServerEvent:Connect(function(player, itemType)
	MoneySystem = MoneySystem or WaitForMoneySystem()

	-- Validate item exists
	if not ITEMS[itemType] then
		PurchaseFailedEvent:FireClient(player, "Invalid item")
		return
	end

	local itemData = ITEMS[itemType]
	local currentMoney = MoneySystem.GetMoney(player)
	local price = itemData.price

	-- Validate player has enough money
	if currentMoney < price then
		PurchaseFailedEvent:FireClient(player, "Not enough BrainBucks")
		return
	end

	-- Deduct money using MoneySystem
	local success, newMoney = MoneySystem.RemoveMoney(player, price, "Purchased " .. itemData.name)

	if success then
		-- Notify player of successful purchase
		PurchaseSuccessEvent:FireClient(player, itemType, itemData.name, newMoney)
		print("Player " .. player.Name .. " purchased " .. itemData.name .. " for " .. price .. " BrainBucks. New balance: " .. newMoney)

		-- TODO: Add item to player's inventory/helicopter
		-- This would integrate with your helicopter/inventory system
	else
		PurchaseFailedEvent:FireClient(player, "Purchase failed")
	end
end)

-- Expose shop items to other server scripts
_G.ShopItems = ITEMS

print("Shop System loaded. Shop folder created in ReplicatedStorage.")
