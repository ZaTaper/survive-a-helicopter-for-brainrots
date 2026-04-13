--[[
	Leaderboard.lua
	Leaderboard GUI for "Survive a Helicopter for Brainrots"

	Features:
	- Shows players ranked by BrainBucks
	- Toggle with Tab key
	- Starts hidden
	- Real-time updates

	This module is initialized by HUDClient.client.lua
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Leaderboard = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
	GOLD_COLOR = Color3.fromRGB(255, 215, 0),
	HIGHLIGHT_COLOR = Color3.fromRGB(100, 200, 100),
}

local screenGui = nil
local elements = {}
local isVisible = false
local playerRows = {}

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
	Creates a player row for the leaderboard
	@param parent: GuiObject - parent to add row to
	@param rank: number - player rank
	@param playerName: string - player name
	@param brainBucks: number - player's BrainBucks
	@param isCurrentPlayer: boolean - whether this is the local player
	@return: Frame - the player row
]]
local function CreatePlayerRow(parent, rank, playerName, brainBucks, isCurrentPlayer)
	local row = CreateRoundedFrame(parent, 6)
	row.Size = UDim2.new(1, -10, 0, 40)
	row.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	row.Position = UDim2.new(0, 5, 0, 0)

	if isCurrentPlayer then
		-- Highlight current player with top border
		local borderFrame = Instance.new("Frame")
		borderFrame.BackgroundColor3 = UI_CONFIG.HIGHLIGHT_COLOR
		borderFrame.BorderSizePixel = 0
		borderFrame.Size = UDim2.new(1, 0, 0, 3)
		borderFrame.Position = UDim2.new(0, 0, 0, 0)
		borderFrame.Parent = row

		local borderCorner = Instance.new("UICorner")
		borderCorner.CornerRadius = UDim.new(0, 6)
		borderCorner.Parent = borderFrame
	end

	-- Rank
	local rankLabel = CreateLabel(row, tostring(rank), 14)
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextXAlignment = Enum.TextXAlignment.Center
	rankLabel.TextColor3 = isCurrentPlayer and UI_CONFIG.HIGHLIGHT_COLOR or UI_CONFIG.TEXT_COLOR
	rankLabel.Size = UDim2.new(0, 40, 1, 0)
	rankLabel.Position = UDim2.new(0, 5, 0, 0)

	-- Player name
	local nameLabel = CreateLabel(row, playerName, 12)
	nameLabel.Font = isCurrentPlayer and Enum.Font.GothamBold or Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Size = UDim2.new(0.6, -50, 1, 0)
	nameLabel.Position = UDim2.new(0, 50, 0, 0)

	-- BrainBucks amount
	local bucksLabel = CreateLabel(row, tostring(brainBucks), 13)
	bucksLabel.Font = Enum.Font.GothamBold
	bucksLabel.TextColor3 = UI_CONFIG.GOLD_COLOR
	bucksLabel.TextXAlignment = Enum.TextXAlignment.Right
	bucksLabel.Size = UDim2.new(0.4, -5, 1, 0)
	bucksLabel.Position = UDim2.new(0.6, 0, 0, 0)

	return row
end

--[[
	Creates the leaderboard window
	@return: ScreenGui - the leaderboard screen gui
]]
local function CreateLeaderboardWindow()
	local screen = Instance.new("ScreenGui")
	screen.Name = "Leaderboard"
	screen.ResetOnSpawn = false
	screen.Enabled = false  -- Starts hidden

	-- Main panel
	local mainPanel = CreateRoundedFrame(screen, 12)
	mainPanel.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	mainPanel.BorderSizePixel = 2
	mainPanel.BorderColor3 = UI_CONFIG.ACCENT_COLOR
	mainPanel.Size = UDim2.new(0, 400, 0, 500)
	mainPanel.Position = UDim2.new(0.5, -200, 0.5, -250)

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
	titleBar.BorderSizePixel = 0
	titleBar.Size = UDim2.new(1, 0, 0, 45)
	titleBar.Parent = mainPanel

	local cornerTitle = Instance.new("UICorner")
	cornerTitle.CornerRadius = UDim.new(0, 12)
	cornerTitle.Parent = titleBar

	local titleText = CreateLabel(titleBar, "LEADERBOARD", 18)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Center
	titleText.Size = UDim2.new(1, 0, 1, 0)
	titleText.Position = UDim2.new(0, 0, 0, 0)

	-- Column headers
	local headerBg = CreateRoundedFrame(mainPanel, 0)
	headerBg.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	headerBg.Size = UDim2.new(1, 0, 0, 30)
	headerBg.Position = UDim2.new(0, 0, 0, 45)

	local rankHeader = CreateLabel(headerBg, "RANK", 11)
	rankHeader.Font = Enum.Font.GothamBold
	rankHeader.TextXAlignment = Enum.TextXAlignment.Center
	rankHeader.Size = UDim2.new(0, 40, 1, 0)
	rankHeader.Position = UDim2.new(0, 5, 0, 0)

	local nameHeader = CreateLabel(headerBg, "PLAYER", 11)
	nameHeader.Font = Enum.Font.GothamBold
	nameHeader.TextXAlignment = Enum.TextXAlignment.Left
	nameHeader.Size = UDim2.new(0.6, -50, 1, 0)
	nameHeader.Position = UDim2.new(0, 50, 0, 0)

	local bucksHeader = CreateLabel(headerBg, "BRAINBUCKS", 11)
	bucksHeader.Font = Enum.Font.GothamBold
	bucksHeader.TextColor3 = UI_CONFIG.GOLD_COLOR
	bucksHeader.TextXAlignment = Enum.TextXAlignment.Right
	bucksHeader.Size = UDim2.new(0.4, -5, 1, 0)
	bucksHeader.Position = UDim2.new(0.6, 0, 0, 0)

	-- Scrolling frame for player rows
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerListScroll"
	scrollFrame.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Size = UDim2.new(1, 0, 1, -75)
	scrollFrame.Position = UDim2.new(0, 0, 0, 75)
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = UI_CONFIG.ACCENT_COLOR
	scrollFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
	scrollFrame.Parent = mainPanel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Fill
	listLayout.Parent = scrollFrame

	listLayout.Changed:Connect(function()
		scrollFrame.CanvasSize = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	elements.mainPanel = mainPanel
	elements.scrollFrame = scrollFrame

	return screen
end

--[[
	Refreshes the leaderboard with player data
	@param playerStats: table - dictionary of player data {playerName: brainBucks}
]]
function Leaderboard:Refresh(playerStats)
	if not elements.scrollFrame then return end

	local currentPlayer = Players.LocalPlayer.Name

	-- Clear existing rows
	for _, row in ipairs(playerRows) do
		row:Destroy()
	end
	playerRows = {}

	-- Convert to sortable table
	local sortedPlayers = {}
	for playerName, brainBucks in pairs(playerStats) do
		table.insert(sortedPlayers, {name = playerName, brainBucks = brainBucks})
	end

	-- Sort by BrainBucks descending
	table.sort(sortedPlayers, function(a, b)
		return a.brainBucks > b.brainBucks
	end)

	-- Create rows for top 20 players
	for rank, playerData in ipairs(sortedPlayers) do
		if rank > 20 then break end
		local isCurrentPlayer = playerData.name == currentPlayer
		local row = CreatePlayerRow(elements.scrollFrame, rank, playerData.name, playerData.brainBucks, isCurrentPlayer)
		table.insert(playerRows, row)
	end
end

--[[
	Shows the leaderboard with animation
]]
function Leaderboard:Show()
	if not screenGui then return end

	screenGui.Enabled = true
	isVisible = true

	-- Animate in
	elements.mainPanel.Size = UDim2.new(0, 400, 0, 100)
	elements.mainPanel.Position = UDim2.new(0.5, -200, 0.5, -50)

	local tween = TweenService:Create(
		elements.mainPanel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 400, 0, 500), Position = UDim2.new(0.5, -200, 0.5, -250)}
	)
	tween:Play()
end

--[[
	Hides the leaderboard with animation
]]
function Leaderboard:Hide()
	if not screenGui then return end

	isVisible = false

	-- Animate out
	local tween = TweenService:Create(
		elements.mainPanel,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Size = UDim2.new(0, 400, 0, 100), Position = UDim2.new(0.5, -200, 0.5, -50)}
	)
	tween:Play()

	tween.Completed:Connect(function()
		if not isVisible then
			screenGui.Enabled = false
		end
	end)
end

--[[
	Toggles the leaderboard visibility
]]
function Leaderboard:Toggle()
	if isVisible then
		self:Hide()
	else
		self:Show()
	end
end

--[[
	Initializes the leaderboard
	@return: ScreenGui - the created ScreenGui object
]]
function Leaderboard:Init()
	screenGui = CreateLeaderboardWindow()
	print("[Leaderboard] Initialized")
	return screenGui
end

return Leaderboard
