-- ShopGUI.lua
-- Professional shop interface with categories
-- Dark theme with category sidebar and organized item cards

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ShopGUI = {}
ShopGUI.isOpen = false
ShopGUI.screenGui = nil
ShopGUI.moneyLabel = nil
ShopGUI.itemsContainer = nil
ShopGUI.closeButton = nil
ShopGUI.currentCategory = "Helicopter Parts"

-- Color scheme for dark professional theme
local COLORS = {
	background = Color3.fromRGB(20, 20, 25),
	darkBg = Color3.fromRGB(15, 15, 20),
	sidebar = Color3.fromRGB(25, 25, 35),
	accent = Color3.fromRGB(100, 200, 255),
	accentDark = Color3.fromRGB(70, 150, 220),
	text = Color3.fromRGB(230, 230, 240),
	textDim = Color3.fromRGB(150, 150, 160),
	success = Color3.fromRGB(100, 255, 100),
	danger = Color3.fromRGB(255, 100, 100),
	gold = Color3.fromRGB(255, 200, 50),
	disabled = Color3.fromRGB(100, 100, 110),
	categoryActive = Color3.fromRGB(100, 200, 255),
	categoryInactive = Color3.fromRGB(70, 70, 85),
}

-- Categories
local CATEGORIES = {
	"Helicopter Parts",
	"Upgrades",
	"Consumables",
}

-- Define all functions before use

-- Create the main shop screen
function ShopGUI:CreateShop()
	if self.screenGui then
		return self.screenGui
	end

	-- Main screen GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false -- MUST start hidden
	screenGui.Parent = playerGui

	-- Semi-transparent background (blur effect)
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = COLORS.background
	background.BackgroundTransparency = 0.4
	background.BorderSizePixel = 0
	background.Parent = screenGui

	-- Main shop container
	local shopContainer = Instance.new("Frame")
	shopContainer.Name = "ShopContainer"
	shopContainer.Size = UDim2.new(0, 1100, 0, 750)
	shopContainer.Position = UDim2.new(0.5, -550, 0.5, -375)
	shopContainer.BackgroundColor3 = COLORS.darkBg
	shopContainer.BorderSizePixel = 2
	shopContainer.BorderColor3 = COLORS.accent
	shopContainer.Parent = screenGui

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = shopContainer

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 70)
	titleBar.BackgroundColor3 = COLORS.accent
	titleBar.BorderSizePixel = 0
	titleBar.Parent = shopContainer

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	-- Title text
	local titleText = Instance.new("TextLabel")
	titleText.Name = "Title"
	titleText.Size = UDim2.new(0.7, 0, 1, 0)
	titleText.Position = UDim2.new(0.05, 0, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.TextSize = 40
	titleText.Font = Enum.Font.GothamBold
	titleText.Text = "SHOP"
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	-- Money display
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyDisplay"
	moneyLabel.Size = UDim2.new(0.25, 0, 1, 0)
	moneyLabel.Position = UDim2.new(0.7, 0, 0, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.TextColor3 = COLORS.gold
	moneyLabel.TextSize = 32
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.Text = "0"
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
	moneyLabel.TextYAlignment = Enum.TextYAlignment.Center
	moneyLabel.Parent = titleBar

	-- Money label prefix
	local moneyPrefix = Instance.new("TextLabel")
	moneyPrefix.Name = "MoneyPrefix"
	moneyPrefix.Size = UDim2.new(0.15, 0, 1, 0)
	moneyPrefix.Position = UDim2.new(0.55, 0, 0, 0)
	moneyPrefix.BackgroundTransparency = 1
	moneyPrefix.TextColor3 = COLORS.gold
	moneyPrefix.TextSize = 20
	moneyPrefix.Font = Enum.Font.Gotham
	moneyPrefix.Text = "BrainBucks:"
	moneyPrefix.TextXAlignment = Enum.TextXAlignment.Right
	moneyPrefix.TextYAlignment = Enum.TextYAlignment.Center
	moneyPrefix.Parent = titleBar

	-- Padding for title bar
	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingRight = UDim.new(0, 20)
	titlePadding.PaddingLeft = UDim.new(0, 20)
	titlePadding.Parent = titleBar

	-- Close button (X)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -60, 0, 10)
	closeButton.BackgroundColor3 = COLORS.danger
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "X"
	closeButton.BorderSizePixel = 0
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Sidebar for categories
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 220, 1, -70)
	sidebar.Position = UDim2.new(0, 0, 0, 70)
	sidebar.BackgroundColor3 = COLORS.sidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = shopContainer

	-- Sidebar padding
	local sidebarPadding = Instance.new("UIPadding")
	sidebarPadding.PaddingTop = UDim.new(0, 20)
	sidebarPadding.PaddingBottom = UDim.new(0, 20)
	sidebarPadding.PaddingLeft = UDim.new(0, 10)
	sidebarPadding.PaddingRight = UDim.new(0, 10)
	sidebarPadding.Parent = sidebar

	-- Category buttons list layout
	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.Padding = UDim.new(0, 10)
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent = sidebar

	-- Create category buttons
	local categoryButtons = {}
	for idx, category in ipairs(CATEGORIES) do
		local categoryButton = Instance.new("TextButton")
		categoryButton.Name = category .. "Button"
		categoryButton.Size = UDim2.new(1, 0, 0, 50)
		categoryButton.BackgroundColor3 = COLORS.categoryInactive
		categoryButton.TextColor3 = COLORS.text
		categoryButton.TextSize = 16
		categoryButton.Font = Enum.Font.GothamBold
		categoryButton.Text = category
		categoryButton.BorderSizePixel = 0
		categoryButton.LayoutOrder = idx
		categoryButton.Parent = sidebar

		local catCorner = Instance.new("UICorner")
		catCorner.CornerRadius = UDim.new(0, 8)
		catCorner.Parent = categoryButton

		categoryButtons[category] = categoryButton
	end

	-- Items container (scrolling frame for all items)
	local itemsContainer = Instance.new("ScrollingFrame")
	itemsContainer.Name = "ItemsContainer"
	itemsContainer.Size = UDim2.new(1, -240, 1, -70)
	itemsContainer.Position = UDim2.new(0, 230, 0, 70)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.BorderSizePixel = 0
	itemsContainer.ScrollBarThickness = 12
	itemsContainer.ScrollBarImageColor3 = COLORS.accent
	itemsContainer.Parent = shopContainer

	-- Grid layout for items
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 200, 0, 280)
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.Parent = itemsContainer

	-- Items padding
	local itemsPadding = Instance.new("UIPadding")
	itemsPadding.PaddingTop = UDim.new(0, 15)
	itemsPadding.PaddingLeft = UDim.new(0, 15)
	itemsPadding.PaddingRight = UDim.new(0, 15)
	itemsPadding.Parent = itemsContainer

	-- Store references
	screenGui:SetAttribute("MoneyLabel", moneyLabel)
	screenGui:SetAttribute("CloseButton", closeButton)
	screenGui:SetAttribute("ItemsContainer", itemsContainer)
	screenGui:SetAttribute("ShopContainer", shopContainer)
	screenGui:SetAttribute("CategoryButtons", categoryButtons)
	screenGui:SetAttribute("Sidebar", sidebar)

	self.screenGui = screenGui
	self.moneyLabel = moneyLabel
	self.itemsContainer = itemsContainer
	self.closeButton = closeButton
	self.categoryButtons = categoryButtons

	return screenGui
end

-- Create an item card for display
function ShopGUI:CreateItemCard(item)
	local itemCard = Instance.new("Frame")
	itemCard.Name = item.id .. "Card"
	itemCard.BackgroundColor3 = COLORS.background
	itemCard.BorderColor3 = COLORS.accentDark
	itemCard.BorderSizePixel = 2
	itemCard:SetAttribute("ItemID", item.id)
	itemCard:SetAttribute("Category", item.category)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = itemCard

	-- Icon background
	local iconBg = Instance.new("Frame")
	iconBg.Name = "IconBg"
	iconBg.Size = UDim2.new(1, 0, 0, 70)
	iconBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	iconBg.BorderSizePixel = 0
	iconBg.Parent = itemCard

	-- Icon/Emoji
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.TextColor3 = COLORS.gold
	icon.TextSize = 48
	icon.Font = Enum.Font.GothamBold
	icon.Text = item.icon
	icon.Parent = iconBg

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(1, -16, 0, 35)
	nameLabel.Position = UDim2.new(0, 8, 0, 80)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = COLORS.text
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = item.name
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.Parent = itemCard

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, -16, 0, 40)
	descLabel.Position = UDim2.new(0, 8, 0, 120)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = COLORS.textDim
	descLabel.TextSize = 13
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = item.description
	descLabel.TextWrapped = true
	descLabel.Parent = itemCard

	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.new(1, -16, 0, 25)
	priceLabel.Position = UDim2.new(0, 8, 0, 165)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = COLORS.gold
	priceLabel.TextSize = 16
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = item.price .. " BrainBucks"
	priceLabel.Parent = itemCard

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(1, -16, 0, 40)
	buyButton.Position = UDim2.new(0, 8, 1, -48)
	buyButton.BackgroundColor3 = COLORS.accent
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 16
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Text = "BUY"
	buyButton.BorderSizePixel = 0
	buyButton.Parent = itemCard

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton

	-- Store item attributes on button
	buyButton:SetAttribute("ItemID", item.id)
	buyButton:SetAttribute("ItemPrice", item.price)
	buyButton:SetAttribute("ItemName", item.name)

	-- Button hover effects
	buyButton.MouseEnter:Connect(function()
		if buyButton:GetAttribute("Disabled") ~= true then
			buyButton.BackgroundColor3 = COLORS.accentDark
		end
	end)

	buyButton.MouseLeave:Connect(function()
		if buyButton:GetAttribute("Disabled") ~= true then
			buyButton.BackgroundColor3 = COLORS.accent
		end
	end)

	return itemCard
end

-- Display items for a specific category
function ShopGUI:DisplayCategory(category, items)
	if not self.itemsContainer then return end

	-- Clear existing items
	for _, child in ipairs(self.itemsContainer:GetChildren()) do
		if child:IsA("Frame") and child:GetAttribute("Category") == category then
			child:Destroy()
		end
	end

	-- Add items for this category
	for _, item in ipairs(items) do
		if item.category == category then
			local card = self:CreateItemCard(item)
			card.Parent = self.itemsContainer
		end
	end
end

-- Display all items
function ShopGUI:DisplayAllItems(items)
	if not self.itemsContainer then return end

	-- Clear existing items
	for _, child in ipairs(self.itemsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add all items
	for _, item in ipairs(items) do
		local card = self:CreateItemCard(item)
		card.Parent = self.itemsContainer
	end
end

-- Update money display
function ShopGUI:UpdateMoneyDisplay(amount)
	if self.moneyLabel then
		self.moneyLabel.Text = tostring(amount)

		-- Animate the money update
		local tween = TweenService:Create(
			self.moneyLabel,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextColor3 = COLORS.success }
		)
		tween:Play()
		tween.Completed:Connect(function()
			local tweenBack = TweenService:Create(
				self.moneyLabel,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ TextColor3 = COLORS.gold }
			)
			tweenBack:Play()
		end)
	end
end

-- Update buy buttons based on current money
function ShopGUI:UpdateButtons(currentMoney)
	if self.itemsContainer then
		for _, child in ipairs(self.itemsContainer:GetChildren()) do
			if child:IsA("Frame") and child:FindFirstChild("BuyButton") then
				local buyButton = child:FindFirstChild("BuyButton")
				local price = buyButton:GetAttribute("ItemPrice")

				if currentMoney >= price then
					buyButton.BackgroundColor3 = COLORS.accent
					buyButton:SetAttribute("Disabled", false)
					buyButton.TextTransparency = 0
				else
					buyButton.BackgroundColor3 = COLORS.disabled
					buyButton:SetAttribute("Disabled", true)
					buyButton.TextTransparency = 0.5
				end
			end
		end
	end
end

-- Show success message
function ShopGUI:ShowSuccessMessage(itemName)
	if not self.screenGui then return end

	local notification = Instance.new("Frame")
	notification.Name = "SuccessNotification"
	notification.Size = UDim2.new(0, 400, 0, 80)
	notification.Position = UDim2.new(0.5, -200, 0, 20)
	notification.BackgroundColor3 = COLORS.success
	notification.BorderSizePixel = 0
	notification.Parent = self.screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextSize = 20
	text.Font = Enum.Font.GothamBold
	text.Text = "Purchase successful!"
	text.Parent = notification

	game:GetService("Debris"):AddItem(notification, 3)
end

-- Show error message
function ShopGUI:ShowErrorMessage(errorText)
	if not self.screenGui then return end

	local notification = Instance.new("Frame")
	notification.Name = "ErrorNotification"
	notification.Size = UDim2.new(0, 400, 0, 80)
	notification.Position = UDim2.new(0.5, -200, 0, 20)
	notification.BackgroundColor3 = COLORS.danger
	notification.BorderSizePixel = 0
	notification.Parent = self.screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextSize = 20
	text.Font = Enum.Font.GothamBold
	text.Text = "Not enough BrainBucks!"
	text.Parent = notification

	game:GetService("Debris"):AddItem(notification, 3)
end

-- Toggle shop visibility
function ShopGUI:Toggle()
	if self.isOpen then
		self:Close()
	else
		self:Open()
	end
end

-- Open shop
function ShopGUI:Open()
	if not self.screenGui then
		self:CreateShop()
	end

	self.screenGui.Enabled = true
	self.isOpen = true

	-- Animate opening with scale
	local shopContainer = self.screenGui:FindFirstChild("ShopContainer")
	shopContainer.Size = UDim2.new(0, 1100, 0, 750)

	local tween = TweenService:Create(
		shopContainer,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 1100, 0, 750) }
	)
	tween:Play()
end

-- Close shop
function ShopGUI:Close()
	if self.screenGui then
		self.screenGui.Enabled = false
		self.isOpen = false
	end
end

function ShopGUI:Destroy()
	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return ShopGUI
