--[[
	Leaderboard.lua
	Client-side custom leaderboard module for "Survive a Helicopter for Brainrots"

	Features:
	- Displays all players with their stats
	- Shows: waves survived, brainrots killed, helicopter stats
	- Real-time updates as stats change
	- Highlights current player
	- Toggle with Tab key
	- Modern, clean design matching main HUD
	- Scrollable for many players

	This module is initialized by HUDClient.client.lua
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Leaderboard = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	BORDER_COLOR = Color3.fromRGB(60, 60, 80),
	HIGHLIGHT_COLOR = Color3.fromRGB(100, 200, 100),
}

local mainFrame = nil
local playerGui = nil
local isVisible = false
local playerRows = {}

--[[
	Creates a rounded corner frame with styling
	@param parent: GuiObject - parent to add frame to
	@param cornerRadius: number - radius for rounded corners (default 8)
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
	Creates a text label with default styling
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
	Creates the leaderboard window
	@return: Frame - the main leaderboard frame
]]
local function CreateLeaderboardWindow()
	local screen = playerGui

	-- Main container
	local main = Instance.new("Frame")
	main.Name = "Leaderboard"
	main.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	main.BorderColor3 = UI_CONFIG.BORDER_COLOR
	main.BorderSizePixel = 2
	main.Size = UDim2.new(0, 500, 0, 600)
	main.Position = UDim2.new(0.5, -250, 0.5, -300)
	main.Visible = false
	main.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = main

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
	titleBar.BorderSizePixel = 0
	titleBar.Size = UDim2.new(1, 0, 0, 45)
	titleBar.Parent = main

	local cornerTitle = Instance.new("UICorner")
	cornerTitle.CornerRadius = UDim.new(0, 12)
	cornerTitle.Parent = titleBar

	local titleText = CreateLabel(titleBar, "LEADERBOARD", 18)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Size = UDim2.new(1, -15, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = UI_CONFIG.TEXT_COLOR
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	closeBtn.BorderSizePixel = 0
	closeBtn.Size = UDim2.new(0, 40, 1, 0)
	closeBtn.Position = UDim2.new(1, -40, 0, 0)
	closeBtn.Parent = titleBar

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtn.Parent = titleBar

	-- Column headers
	local headerBg = CreateRoundedFrame(main, 0)
	headerBg.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	headerBg.Size = UDim2.new(1, 0, 0, 35)
	headerBg.Position = UDim2.new(0, 0, 0, 45)

	local rankHeader = CreateLabel(headerBg, "RANK", 11)
	rankHeader.Font = Enum.Font.GothamBold
	rankHeader.TextXAlignment = Enum.TextXAlignment.Center
	rankHeader.Size = UDim2.new(0, 35, 1, 0)
	rankHeader.Position = UDim2.new(0, 5, 0, 0)

	local playerHeader = CreateLabel(headerBg, "PLAYER", 11)
	playerHeader.Font = Enum.Font.GothamBold
	playerHeader.TextXAlignment = Enum.TextXAlignment.Left
	playerHeader.Size = UDim2.new(0.3, -40, 1, 0)
	playerHeader.Position = UDim2.new(0, 45, 0, 0)

	local waveHeader = CreateLabel(headerBg, "WAVES", 11)
	waveHeader.Font = Enum.Font.GothamBold
	waveHeader.TextXAlignment = Enum.TextXAlignment.Center
	waveHeader.Size = UDim2.new(0.2, 0, 1, 0)
	waveHeader.Position = UDim2.new(0.3, 0, 0, 0)

	local killsHeader = CreateLabel(headerBg, "KILLS", 11)
	killsHeader.Font = Enum.Font.GothamBold
	killsHeader.TextXAlignment = Enum.TextXAlignment.Center
	killsHeader.Size = UDim2.new(0.2, 0, 1, 0)
	killsHeader.Position = UDim2.new(0.5, 0, 0, 0)

	local speedHeader = CreateLabel(headerBg, "SPEED", 11)
	speedHeader.Font = Enum.Font.GothamBold
	speedHeader.TextXAlignment = Enum.TextXAlignment.Center
	speedHeader.Size = UDim2.new(0.2, 0, 1, 0)
	speedHeader.Position = UDim2.new(0.7, 0, 0, 0)

	-- Scrolling frame for player rows
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerListScroll"
	scrollFrame.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Size = UDim2.new(1, 0, 1, -80)
	scrollFrame.Position = UDim2.new(0, 0, 0, 80)
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = UI_CONFIG.ACCENT_COLOR
	scrollFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
	scrollFrame.Parent = main

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Fill
	listLayout.Parent = scrollFrame

	listLayout.Changed:Connect(function()
		scrollFrame.CanvasSize = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Store references
	local leaderboardData = {
		mainFrame = main,
		scrollFrame = scrollFrame,
		closeBtn = closeBtn,
		playerRows = {}
	}

	return main, leaderboardData
end

--[[
	Creates a player row for the leaderboard
	@param scrollFrame: ScrollingFrame - parent scroll frame
	@param rank: number - player rank
	@param playerName: string - player name
	@param stats: table - player stats {wavesSurvived, kills, speed}
	@param isCurrentPlayer: boolean - whether this is the local player
	@return: Frame - the player row
]]
local function CreatePlayerRow(scrollFrame, rank, playerName, stats, isCurrentPlayer)
	local row = CreateRoundedFrame(scrollFrame, 6)
	row.Size = UDim2.new(1, -10, 0, 45)
	row.BackgroundColor3 = isCurrentPlayer and UI_CONFIG.HIGHLIGHT_COLOR or UI_CONFIG.SECONDARY_COLOR
	row.Position = UDim2.new(0, 5, 0, 0)

	if isCurrentPlayer then
		row.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
		-- Add highlight border effect
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
	local rankLabel = CreateLabel(row, tostring(rank), 13)
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextXAlignment = Enum.TextXAlignment.Center
	rankLabel.TextColor3 = isCurrentPlayer and UI_CONFIG.HIGHLIGHT_COLOR or UI_CONFIG.TEXT_COLOR
	rankLabel.Size = UDim2.new(0, 35, 1, 0)
	rankLabel.Position = UDim2.new(0, 5, 0, 0)

	-- Player name
	local nameLabel = CreateLabel(row, playerName, 12)
	nameLabel.Font = isCurrentPlayer and Enum.Font.GothamBold or Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Size = UDim2.new(0.3, -40, 1, 0)
	nameLabel.Position = UDim2.new(0, 45, 0, 0)

	-- Waves survived
	local wavesLabel = CreateLabel(row, tostring(stats.wavesSurvived or 0), 12)
	wavesLabel.TextXAlignment = Enum.TextXAlignment.Center
	wavesLabel.Size = UDim2.new(0.2, 0, 1, 0)
	wavesLabel.Position = UDim2.new(0.3, 0, 0, 0)

	-- Kills
	local killsLabel = CreateLabel(row, tostring(stats.kills or 0), 12)
	killsLabel.TextXAlignment = Enum.TextXAlignment.Center
	killsLabel.Size = UDim2.new(0.2, 0, 1, 0)
	killsLabel.Position = UDim2.new(0.5, 0, 0, 0)

	-- Speed
	local speedLabel = CreateLabel(row, tostring(math.floor(stats.speed or 0)), 12)
	speedLabel.TextXAlignment = Enum.TextXAlignment.Center
	speedLabel.Size = UDim2.new(0.2, 0, 1, 0)
	speedLabel.Position = UDim2.new(0.7, 0, 0, 0)

	return row
end

--[[
	Refreshes the leaderboard with updated player data
	@param playerStats: table - dictionary of player data {playerName: {wavesSurvived, kills, speed}}
]]
function Leaderboard:Refresh(playerStats)
	if not mainFrame or not mainFrame:FindFirstChild("PlayerListScroll") then return end

	local scrollFrame = mainFrame:FindFirstChild("PlayerListScroll")
	local currentPlayer = Players.LocalPlayer.Name

	-- Clear existing rows
	for _, row in ipairs(playerRows) do
		row:Destroy()
	end
	playerRows = {}

	-- Convert to sortable table and sort by waves
	local sortedPlayers = {}
	for playerName, stats in pairs(playerStats) do
		table.insert(sortedPlayers, {name = playerName, stats = stats})
	end

	table.sort(sortedPlayers, function(a, b)
		if a.stats.wavesSurvived ~= b.stats.wavesSurvived then
			return a.stats.wavesSurvived > b.stats.wavesSurvived
		end
		return a.stats.kills > b.stats.kills
	end)

	-- Create rows for top 20 players
	for rank, playerData in ipairs(sortedPlayers) do
		if rank > 20 then break end
		local isCurrentPlayer = playerData.name == currentPlayer
		local row = CreatePlayerRow(scrollFrame, rank, playerData.name, playerData.stats, isCurrentPlayer)
		table.insert(playerRows, row)
	end
end

--[[
	Shows the leaderboard with animation
]]
function Leaderboard:Show()
	if not mainFrame then return end

	mainFrame.Visible = true
	isVisible = true

	-- Animate in
	mainFrame.Size = UDim2.new(0, 500, 0, 100)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -50)

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(mainFrame, tweenInfo, {
		Size = UDim2.new(0, 500, 0, 600),
		Position = UDim2.new(0.5, -250, 0.5, -300)
	})
	tween:Play()
end

--[[
	Hides the leaderboard with animation
]]
function Leaderboard:Hide()
	if not mainFrame then return end

	isVisible = false

	-- Animate out
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local tween = TweenService:Create(mainFrame, tweenInfo, {
		Size = UDim2.new(0, 500, 0, 100),
		Position = UDim2.new(0.5, -250, 0.5, -50)
	})
	tween:Play()
	tween.Completed:Connect(function()
		mainFrame.Visible = false
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
	@param playerGui: ScreenGui - the PlayerGui to attach to
]]
function Leaderboard:Init(playerGui_)
	playerGui = playerGui_
	mainFrame, leaderboardData = CreateLeaderboardWindow()

	-- Wire up close button
	if mainFrame:FindFirstChild("TitleBar") then
		local titleBar = mainFrame:FindFirstChild("TitleBar")
		if titleBar:FindFirstChild("CloseButton") then
			titleBar:FindFirstChild("CloseButton").MouseButton1Click:Connect(function()
				self:Hide()
			end)
		end
	end

	print("Leaderboard initialized")
	return mainFrame
end

return Leaderboard
