--[[
	CollectionGUI.lua
	Brainrot collection viewer GUI for "Survive a Helicopter for Brainrots"

	Features:
	- Grid showing all 8 tiers of brainrots with tier names and collection chances
	- Collected ones are lit up with tier color, uncollected are dark
	- Shows count collected and collection chance percentage
	- Toggle with C key
	- Starts hidden

	This module is initialized by HUDClient.client.lua
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectionGUI = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	DIM_TEXT_COLOR = Color3.fromRGB(100, 100, 100),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
}

-- Tier colors (8 tiers)
local TIER_COLORS = {
	Color3.fromRGB(150, 150, 150),  -- Tier 1: Common (Light Gray)
	Color3.fromRGB(0, 200, 100),    -- Tier 2: Uncommon (Green)
	Color3.fromRGB(0, 150, 255),    -- Tier 3: Rare (Blue)
	Color3.fromRGB(200, 0, 255),    -- Tier 4: Epic (Purple)
	Color3.fromRGB(255, 0, 0),      -- Tier 5: Mythic (Red)
	Color3.fromRGB(255, 200, 0),    -- Tier 6: Secret (Orange)
	Color3.fromRGB(0, 255, 255),    -- Tier 7: Celestial (Cyan)
	Color3.fromRGB(255, 0, 200),    -- Tier 8: OP (Hot Pink)
}

-- Tier names
local TIER_NAMES = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Mythic",
	"Secret",
	"Celestial",
	"OP",
}

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

local screenGui = nil
local elements = {}
local isVisible = false
local collectedBrainrots = {}  -- Track which brainrots are collected
local tierCounts = {}  -- Track counts per tier
local uniqueTiersCollected = 0

--[[
	Creates a rounded corner frame with styling
	@param parent: GuiObject - parent to add frame to
	@param cornerRadius: number - radius for rounded corners
	@return: Frame
]]
local function CreateRoundedFrame(parent, cornerRadius)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius or 8)
	corner.Parent = frame

	return frame
end

--[[
	Creates a text label with styling
	@param parent: GuiObject - parent to add label to
	@param text: string - label text
	@param textSize: number - font size
	@return: TextLabel
]]
local function CreateLabel(parent, text, textSize)
	local label = Instance.new("TextLabel")
	label.Name = text
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize or 14
	label.TextColor3 = UI_CONFIG.TEXT_COLOR
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Parent = parent
	return label
end

--[[
	Creates a brainrot tier card
	@param parent: GuiObject - parent to add card to
	@param tierNumber: number - which tier (1-8)
	@param tierName: string - name of the tier
	@param chance: number - collection chance percentage
	@param count: number - how many collected
	@param isCollected: boolean - whether this tier has been collected
	@return: Frame - the tier card
]]
local function CreateTierCard(parent, tierNumber, tierName, chance, count, isCollected)
	local card = CreateRoundedFrame(parent, 10)
	card.Size = UDim2.new(0.22, -12, 0.35, -12)
	card.BackgroundColor3 = isCollected and TIER_COLORS[tierNumber] or Color3.fromRGB(40, 40, 50)
	card.BackgroundTransparency = isCollected and 0 or 0.75

	-- Colored icon square at top
	local icon = Instance.new("Frame")
	icon.BackgroundColor3 = TIER_COLORS[tierNumber]
	icon.BorderSizePixel = 0
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0.5, -15, 0, 8)
	icon.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 4)
	iconCorner.Parent = icon

	-- Tier name label
	local nameLabel = CreateLabel(card, tierName, 13)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = isCollected and Color3.fromRGB(255, 255, 255) or UI_CONFIG.DIM_TEXT_COLOR
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextScaled = true
	nameLabel.Size = UDim2.new(1, -8, 0, 20)
	nameLabel.Position = UDim2.new(0, 4, 0, 42)

	-- Count label
	local countLabel = CreateLabel(card, "x" .. count, 12)
	countLabel.Font = Enum.Font.Gotham
	countLabel.TextColor3 = isCollected and Color3.fromRGB(200, 200, 200) or UI_CONFIG.DIM_TEXT_COLOR
	countLabel.TextXAlignment = Enum.TextXAlignment.Center
	countLabel.Size = UDim2.new(1, -8, 0, 16)
	countLabel.Position = UDim2.new(0, 4, 0, 64)

	-- Chance label
	local chanceLabel = CreateLabel(card, chance .. "%", 11)
	chanceLabel.Font = Enum.Font.Gotham
	chanceLabel.TextColor3 = isCollected and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(80, 80, 80)
	chanceLabel.TextXAlignment = Enum.TextXAlignment.Center
	chanceLabel.Size = UDim2.new(1, -8, 0, 14)
	chanceLabel.Position = UDim2.new(0, 4, 1, -30)

	-- Store references for updating
	card.NameLabel = nameLabel
	card.CountLabel = countLabel
	card.ChanceLabel = chanceLabel
	card.Icon = icon

	return card
end

--[[
	Creates the collection GUI window
	@return: ScreenGui - the collection screen gui
]]
local function CreateCollectionGUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "CollectionGUI"
	screen.ResetOnSpawn = false
	screen.Enabled = false  -- Starts hidden

	-- Main panel
	local mainPanel = CreateRoundedFrame(screen, 15)
	mainPanel.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	mainPanel.BorderSizePixel = 2
	mainPanel.BorderColor3 = UI_CONFIG.ACCENT_COLOR
	mainPanel.Size = UDim2.new(0, 900, 0, 600)
	mainPanel.Position = UDim2.new(0.5, -450, 0.5, -300)

	-- Title
	local titleLabel = CreateLabel(mainPanel, "BRAINROT COLLECTION", 28)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 10)

	-- Tiers collected counter
	local counterLabel = CreateLabel(mainPanel, "0/8 Tiers Collected", 14)
	counterLabel.Font = Enum.Font.Gotham
	counterLabel.TextColor3 = UI_CONFIG.ACCENT_COLOR
	counterLabel.TextXAlignment = Enum.TextXAlignment.Center
	counterLabel.Size = UDim2.new(1, 0, 0, 20)
	counterLabel.Position = UDim2.new(0, 0, 0, 52)
	elements.counterLabel = counterLabel

	-- Grid container (4 columns x 2 rows = 8 tiers)
	local gridContainer = Instance.new("Frame")
	gridContainer.Name = "GridContainer"
	gridContainer.BackgroundTransparency = 1
	gridContainer.BorderSizePixel = 0
	gridContainer.Size = UDim2.new(1, -60, 1, -140)
	gridContainer.Position = UDim2.new(0, 30, 0, 80)
	gridContainer.Parent = mainPanel

	-- Create 4x2 grid for 8 tiers
	elements.tierCards = {}
	local index = 1
	for row = 0, 1 do
		for col = 0, 3 do
			local tierNum = row * 4 + col + 1
			if tierNum <= 8 then
				local card = CreateTierCard(
					gridContainer,
					tierNum,
					TIER_NAMES[tierNum],
					COLLECTION_CHANCES[tierNum],
					tierCounts[tierNum] or 0,
					collectedBrainrots[tierNum] or false
				)
				card.Position = UDim2.new(col * 0.25, 8, row * 0.5, 8)
				table.insert(elements.tierCards, card)
			end
		end
	end

	-- Close hint
	local closeHint = CreateLabel(mainPanel, "Press C to close", 12)
	closeHint.TextXAlignment = Enum.TextXAlignment.Center
	closeHint.Size = UDim2.new(1, 0, 0, 20)
	closeHint.Position = UDim2.new(0, 0, 1, -25)
	closeHint.TextColor3 = UI_CONFIG.ACCENT_COLOR

	elements.mainPanel = mainPanel

	return screen
end

--[[
	Updates a specific tier's visual state and count
	@param tierNumber: number - which tier (1-8)
	@param isCollected: boolean - whether this tier is collected
	@param count: number - how many of this tier collected
]]
function CollectionGUI:SetTierCollected(tierNumber, isCollected, count)
	if tierNumber < 1 or tierNumber > 8 then return end

	collectedBrainrots[tierNumber] = isCollected
	if count then
		tierCounts[tierNumber] = count
	end

	if elements.tierCards and elements.tierCards[tierNumber] then
		local card = elements.tierCards[tierNumber]
		local newColor = isCollected and TIER_COLORS[tierNumber] or Color3.fromRGB(40, 40, 50)
		local newTransparency = isCollected and 0 or 0.75

		-- Animate color change
		local tween = TweenService:Create(
			card,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = newColor, BackgroundTransparency = newTransparency}
		)
		tween:Play()

		-- Update label colors
		if card.NameLabel then
			card.NameLabel.TextColor3 = isCollected and Color3.fromRGB(255, 255, 255) or UI_CONFIG.DIM_TEXT_COLOR
		end
		if card.ChanceLabel then
			card.ChanceLabel.TextColor3 = isCollected and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(80, 80, 80)
		end
	end

	self:UpdateCount(tierNumber, tierCounts[tierNumber] or 0)
	self:UpdateTiersCounter()
end

--[[
	Updates the count for a specific tier
	@param tierNumber: number - which tier (1-8)
	@param count: number - how many collected
]]
function CollectionGUI:UpdateCount(tierNumber, count)
	if tierNumber < 1 or tierNumber > 8 then return end

	tierCounts[tierNumber] = count

	if elements.tierCards and elements.tierCards[tierNumber] then
		local card = elements.tierCards[tierNumber]
		if card.CountLabel then
			card.CountLabel.Text = "x" .. count
		end
	end
end

--[[
	Updates the tiers collected counter
]]
function CollectionGUI:UpdateTiersCounter()
	if elements.counterLabel then
		elements.counterLabel.Text = uniqueTiersCollected .. "/8 Tiers Collected"
	end
end

--[[
	Sets the collection data from the server
	@param data: table - Collection data with tiers array
]]
function CollectionGUI:SetCollectionData(data)
	if not data or not data.tiers then return end

	uniqueTiersCollected = data.uniqueTiersCollected or 0

	for _, tierData in ipairs(data.tiers) do
		local tierIndex = tierData.tierIndex
		if tierIndex >= 1 and tierIndex <= 8 then
			self:SetTierCollected(tierIndex, tierData.count > 0, tierData.count)
		end
	end

	self:UpdateTiersCounter()
end

--[[
	Shows the collection GUI with animation
]]
function CollectionGUI:Show()
	if not screenGui then return end

	screenGui.Enabled = true
	isVisible = true

	-- Animate in
	elements.mainPanel.Size = UDim2.new(0, 900, 0, 150)
	elements.mainPanel.Position = UDim2.new(0.5, -450, 0.5, -75)

	local tween = TweenService:Create(
		elements.mainPanel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 900, 0, 600), Position = UDim2.new(0.5, -450, 0.5, -300)}
	)
	tween:Play()
end

--[[
	Hides the collection GUI with animation
]]
function CollectionGUI:Hide()
	if not screenGui then return end

	isVisible = false

	-- Animate out
	local tween = TweenService:Create(
		elements.mainPanel,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Size = UDim2.new(0, 900, 0, 150), Position = UDim2.new(0.5, -450, 0.5, -75)}
	)
	tween:Play()

	tween.Completed:Connect(function()
		if not isVisible then
			screenGui.Enabled = false
		end
	end)
end

--[[
	Toggles the collection GUI visibility
]]
function CollectionGUI:Toggle()
	if isVisible then
		self:Hide()
	else
		self:Show()
	end
end

--[[
	Initializes the collection GUI
	@return: ScreenGui - the created ScreenGui object
]]
function CollectionGUI:Init()
	screenGui = CreateCollectionGUI()
	print("[CollectionGUI] Initialized")
	return screenGui
end

return CollectionGUI
