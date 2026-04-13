-- ShopClient.client.lua
-- Client-side shop system for handling UI and purchase requests
-- B key toggles shop visibility, listens for money updates

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shop remotes to be ready
local Shop = ReplicatedStorage:WaitForChild("Shop")
local BuyItemEvent = Shop:WaitForChild("BuyItem")
local GetMoneyFunction = Shop:WaitForChild("GetMoney")
local GetShopItemsFunction = Shop:WaitForChild("GetShopItems")
local MoneyChangedEvent = Shop:WaitForChild("MoneyChanged")
local PurchaseSuccessEvent = Shop:WaitForChild("PurchaseSuccess")
local PurchaseFailedEvent = Shop:WaitForChild("PurchaseFailed")

-- Load shop GUI module
local ShopGUI = require(playerGui:WaitForChild("GUI"):WaitForChild("ShopGUI"))

local currentMoney = 0
local shopItems = {}

-- Define functions before use

-- Buy item function - sends purchase request to server
local function BuyItem(itemID, itemName)
	print("Attempting to purchase: " .. itemID)
	BuyItemEvent:FireServer(itemID)
end

-- Connect category button handlers
local function SetupCategoryButtons()
	if not ShopGUI.categoryButtons then return end

	local categories = {
		"Helicopter Parts",
		"Upgrades",
		"Consumables",
	}

	for _, category in ipairs(categories) do
		local button = ShopGUI.categoryButtons[category]
		if button then
			button.MouseButton1Click:Connect(function()
				ShopGUI.currentCategory = category

				-- Update button colors
				for _, btn in pairs(ShopGUI.categoryButtons) do
					btn.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
				end
				button.BackgroundColor3 = Color3.fromRGB(100, 200, 255)

				-- Display items for this category
				ShopGUI:DisplayCategory(category, shopItems)
				ShopGUI:UpdateButtons(currentMoney)
				SetupBuyButtons()
			end)
		end
	end

	-- Set default category as active
	if ShopGUI.categoryButtons["Helicopter Parts"] then
		ShopGUI.categoryButtons["Helicopter Parts"].BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	end
end

-- Connect buy button handlers
local function SetupBuyButtons()
	if not ShopGUI.itemsContainer then return end

	for _, child in ipairs(ShopGUI.itemsContainer:GetChildren()) do
		if child:IsA("Frame") and child:FindFirstChild("BuyButton") then
			local buyButton = child:FindFirstChild("BuyButton")

			-- Remove old connections by disconnecting
			local connections = getmetatable(buyButton.MouseButton1Click).__index

			buyButton.MouseButton1Click:Connect(function()
				if buyButton:GetAttribute("Disabled") ~= true then
					local itemID = buyButton:GetAttribute("ItemID")
					local itemName = buyButton:GetAttribute("ItemName")
					BuyItem(itemID, itemName)
				end
			end)
		end
	end
end

-- Initialize shop - called once at startup
local function Initialize()
	-- Get initial money from server
	local success, result = pcall(function()
		return GetMoneyFunction:InvokeServer()
	end)

	if success then
		currentMoney = result
		print("Shop initialized. Current money: " .. currentMoney)
	else
		warn("Failed to get initial money: " .. tostring(result))
		currentMoney = 0
	end

	-- Get available shop items from server
	local itemsSuccess, itemsResult = pcall(function()
		return GetShopItemsFunction:InvokeServer()
	end)

	if itemsSuccess and itemsResult then
		shopItems = itemsResult
		print("Loaded " .. #shopItems .. " shop items")
	else
		warn("Failed to get shop items: " .. tostring(itemsResult))
	end

	-- Create the shop GUI (starts hidden/disabled)
	ShopGUI:CreateShop()
	ShopGUI:DisplayAllItems(shopItems)
	ShopGUI:UpdateMoneyDisplay(currentMoney)
	ShopGUI:UpdateButtons(currentMoney)
	ShopGUI:Close()

	-- Setup close button
	if ShopGUI.closeButton then
		ShopGUI.closeButton.MouseButton1Click:Connect(function()
			ShopGUI:Close()
		end)
	end

	-- Setup category buttons
	SetupCategoryButtons()

	-- Setup buy buttons
	SetupBuyButtons()

	print("Shop Client initialized successfully")
end

-- Listen for money changes from server
MoneyChangedEvent.OnClientEvent:Connect(function(newMoney)
	print("Money changed: " .. newMoney)
	currentMoney = newMoney
	ShopGUI:UpdateMoneyDisplay(newMoney)
	ShopGUI:UpdateButtons(newMoney)
end)

-- Listen for successful purchases
PurchaseSuccessEvent.OnClientEvent:Connect(function(itemID, itemName, newMoney)
	print("Purchase successful: " .. itemName)
	ShopGUI:ShowSuccessMessage(itemName)
	currentMoney = newMoney
	ShopGUI:UpdateMoneyDisplay(newMoney)
	ShopGUI:UpdateButtons(newMoney)
end)

-- Listen for failed purchases
PurchaseFailedEvent.OnClientEvent:Connect(function(errorMessage)
	print("Purchase failed: " .. errorMessage)
	ShopGUI:ShowErrorMessage(errorMessage)
end)

-- B key toggles shop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.B then
		ShopGUI:Toggle()
	end
end)

-- Initialize on startup
Initialize()

print("Shop Client loaded successfully. Press B to toggle shop.")
