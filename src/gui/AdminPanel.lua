--[[
	AdminPanel.lua
	Redesigned admin GUI for "Survive a Helicopter for Brainrots"
	Dark theme with red/orange admin accents, tabbed interface
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local AdminPanel = {}
local screenGui = nil
local mainFrame = nil
local tabButtons = {}
local tabContents = {}
local panelVisible = false
local selectedPlayer = nil

-- Dark theme with red/orange admin accents
local COLORS = {
	Background = Color3.fromRGB(20, 20, 25),
	DarkFrame = Color3.fromRGB(30, 30, 35),
	Button = Color3.fromRGB(40, 40, 50),
	ButtonHover = Color3.fromRGB(50, 50, 60),
	Active = Color3.fromRGB(200, 100, 50),
	Inactive = Color3.fromRGB(100, 100, 120),
	TextColor = Color3.fromRGB(255, 255, 255),
	Red = Color3.fromRGB(220, 80, 80),
	Green = Color3.fromRGB(80, 220, 80),
	Orange = Color3.fromRGB(255, 140, 0),
}

-- Helper: Create styled button
local function CreateButton(parent, text, color, callback)
	local button = Instance.new("TextButton")
	button.Name = text
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = color or COLORS.Button
	button.BackgroundTransparency = 0
	button.TextColor3 = COLORS.TextColor
	button.TextSize = 14
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.BorderSizePixel = 0
	button.Parent = parent

	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.ButtonHover}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color or COLORS.Button}):Play()
	end)

	if callback then
		button.MouseButton1Click:Connect(callback)
	end

	return button
end

-- Helper: Create toggle button
local function CreateToggle(parent, text, callback)
	local container = Instance.new("Frame")
	container.Name = text .. "_Toggle"
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.85, 0, 1, 0)
	button.Position = UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = COLORS.Red
	button.TextColor3 = COLORS.TextColor
	button.TextSize = 14
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Text = text .. " [OFF]"
	button.BorderSizePixel = 0
	button.Parent = container

	local state = false

	button.MouseButton1Click:Connect(function()
		state = not state
		local newColor = state and COLORS.Green or COLORS.Red
		local statusText = state and " [ON]" or " [OFF]"
		button.Text = text .. statusText
		TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = newColor}):Play()
		if callback then
			callback(state)
		end
	end)

	return container
end

-- Helper: Create player dropdown
local function CreatePlayerDropdown(parent)
	local container = Instance.new("Frame")
	container.Name = "PlayerSelector"
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 100, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLORS.TextColor
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Text = "Player:"
	label.Parent = container

	local dropdown = Instance.new("TextButton")
	dropdown.Name = "Dropdown"
	dropdown.Size = UDim2.new(0.6, 0, 1, 0)
	dropdown.Position = UDim2.new(0.15, 0, 0, 0)
	dropdown.BackgroundColor3 = COLORS.Button
	dropdown.TextColor3 = COLORS.TextColor
	dropdown.TextSize = 12
	dropdown.Font = Enum.Font.Gotham
	dropdown.Text = "Select Player"
	dropdown.BorderSizePixel = 0
	dropdown.Parent = container

	local function UpdatePlayerList()
		local playerNames = {}
		for _, player in ipairs(Players:GetPlayers()) do
			table.insert(playerNames, player.Name)
		end
		return playerNames
	end

	dropdown.MouseButton1Click:Connect(function()
		local playerNames = UpdatePlayerList()
		selectedPlayer = playerNames[1] or nil
		if selectedPlayer then
			dropdown.Text = selectedPlayer
		end
	end)

	return container
end

-- Helper: Create input field
local function CreateInputField(parent, label, defaultValue)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0, 80, 1, 0)
	labelText.BackgroundTransparency = 1
	labelText.TextColor3 = COLORS.TextColor
	labelText.TextSize = 12
	labelText.Font = Enum.Font.GothamBold
	labelText.Text = label
	labelText.Parent = container

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(0.65, 0, 1, 0)
	input.Position = UDim2.new(0.2, 0, 0, 0)
	input.BackgroundColor3 = COLORS.Button
	input.TextColor3 = COLORS.TextColor
	input.TextSize = 12
	input.Font = Enum.Font.Gotham
	input.Text = defaultValue or ""
	input.BorderSizePixel = 0
	input.ClearTextOnFocus = false
	input.Parent = container

	return input
end

-- Create main screen GUI
local function CreateAdminPanel()
	-- Screen GUI
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanel"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 600)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
	mainFrame.BackgroundColor3 = COLORS.DarkFrame
	mainFrame.BorderSizePixel = 2
	mainFrame.BorderColor3 = COLORS.Active
	mainFrame.Parent = screenGui

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = COLORS.Background
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -20, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = COLORS.Active
	titleText.TextSize = 20
	titleText.Font = Enum.Font.GothamBlack
	titleText.Text = "👑 ADMIN PANEL"
	titleText.Parent = titleBar

	-- Tab buttons container
	local tabButtonsFrame = Instance.new("Frame")
	tabButtonsFrame.Name = "TabButtons"
	tabButtonsFrame.Size = UDim2.new(1, 0, 0, 50)
	tabButtonsFrame.Position = UDim2.new(0, 0, 0, 50)
	tabButtonsFrame.BackgroundColor3 = COLORS.Background
	tabButtonsFrame.BorderSizePixel = 0
	tabButtonsFrame.Parent = mainFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabButtonsFrame

	-- Tab contents container
	local tabContentsFrame = Instance.new("Frame")
	tabContentsFrame.Name = "TabContents"
	tabContentsFrame.Size = UDim2.new(1, 0, 1, -100)
	tabContentsFrame.Position = UDim2.new(0, 0, 0, 100)
	tabContentsFrame.BackgroundColor3 = COLORS.DarkFrame
	tabContentsFrame.BorderSizePixel = 0
	tabContentsFrame.Parent = mainFrame

	local scrolling = Instance.new("ScrollingFrame")
	scrolling.Size = UDim2.new(1, -10, 1, 0)
	scrolling.Position = UDim2.new(0, 5, 0, 0)
	scrolling.BackgroundTransparency = 1
	scrolling.ScrollBarThickness = 8
	scrolling.ScrollBarImageColor3 = COLORS.Active
	scrolling.Parent = tabContentsFrame

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	contentLayout.Padding = UDim.new(0, 5)
	contentLayout.Parent = scrolling

	-- Tab definitions
	local tabs = {
		{
			name = "Brainrots",
			createFunc = function(content)
				CreateButton(content, "Spawn Common", COLORS.Button, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("SpawnBrainrot"):FireServer("Common", localPlayer.Character.HumanoidRootPart.Position)
				end)
				CreateButton(content, "Spawn Rare", COLORS.Button, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("SpawnBrainrot"):FireServer("Rare", localPlayer.Character.HumanoidRootPart.Position)
				end)
				CreateButton(content, "Spawn Epic", COLORS.Button, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("SpawnBrainrot"):FireServer("Epic", localPlayer.Character.HumanoidRootPart.Position)
				end)
				CreateButton(content, "Spawn Legendary", COLORS.Button, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("SpawnBrainrot"):FireServer("Legendary", localPlayer.Character.HumanoidRootPart.Position)
				end)
				CreateButton(content, "Spawn OP Boss", COLORS.Orange, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("SpawnOPBrainrot"):FireServer(localPlayer.Character.HumanoidRootPart.Position)
				end)
				CreateButton(content, "Kill All Brainrots", COLORS.Red, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("KillAllBrainrots"):FireServer()
				end)
				CreateButton(content, "NUKE ALL (Explosions)", COLORS.Red, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("NukeAllBrainrots"):FireServer()
				end)
			end
		},
		{
			name = "Players",
			createFunc = function(content)
				CreatePlayerDropdown(content)
				CreateButton(content, "Heal Selected", COLORS.Green, function()
					if selectedPlayer then
						local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
						AdminEvents:WaitForChild("HealPlayer"):FireServer(selectedPlayer)
					end
				end)
				CreateButton(content, "Teleport To", COLORS.Button, function()
					if selectedPlayer then
						local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
						AdminEvents:WaitForChild("TeleportToPlayer"):FireServer(selectedPlayer)
					end
				end)
				CreateButton(content, "Teleport Here", COLORS.Button, function()
					if selectedPlayer then
						local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
						AdminEvents:WaitForChild("TeleportPlayerToMe"):FireServer(selectedPlayer)
					end
				end)
				CreateButton(content, "Give Money", COLORS.Green, function()
					if selectedPlayer then
						local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
						AdminEvents:WaitForChild("GiveMoney"):FireServer(selectedPlayer, 10000)
					end
				end)
				CreateButton(content, "Give All Money", COLORS.Green, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("GiveAllMoney"):FireServer(5000)
				end)
				CreateButton(content, "Kick Player", COLORS.Red, function()
					if selectedPlayer then
						local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
						AdminEvents:WaitForChild("KickPlayer"):FireServer(selectedPlayer)
					end
				end)
				CreateButton(content, "Teleport All To Me", COLORS.Orange, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("TeleportAllToAdmin"):FireServer()
				end)
			end
		},
		{
			name = "God Powers",
			createFunc = function(content)
				CreateToggle(content, "God Mode", function(state)
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("ToggleGodMode"):FireServer()
				end)
				CreateToggle(content, "Speed Boost", function(state)
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("ToggleSpeedBoost"):FireServer()
				end)
				CreateToggle(content, "Invisible", function(state)
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("ToggleInvisibleMode"):FireServer()
				end)
				CreateToggle(content, "Giant Mode", function(state)
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("ToggleGiantMode"):FireServer()
				end)
				CreateToggle(content, "Tiny Mode", function(state)
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("ToggleTinyMode"):FireServer()
				end)
			end
		},
		{
			name = "Server",
			createFunc = function(content)
				local announcementInput = CreateInputField(content, "Message:", "ADMIN ANNOUNCEMENT")
				CreateButton(content, "Send Announcement", COLORS.Orange, function()
					local message = announcementInput.Text
					if message and #message > 0 then
						local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
						AdminEvents:WaitForChild("ServerAnnouncement"):FireServer(message)
					end
				end)
				CreateButton(content, "Restart Round", COLORS.Red, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("RestartRound"):FireServer()
				end)
				CreateButton(content, "Toggle PVP", COLORS.Button, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("TogglePVP"):FireServer()
				end)
				CreateButton(content, "Double Money Event", COLORS.Green, function()
					local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
					AdminEvents:WaitForChild("StartDoubleMoneyEvent"):FireServer()
				end)
			end
		},
	}

	-- Create tabs
	for tabIndex, tab in ipairs(tabs) do
		-- Tab button
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tab.name
		tabButton.Size = UDim2.new(0, 90, 0, 40)
		tabButton.BackgroundColor3 = tabIndex == 1 and COLORS.Active or COLORS.Button
		tabButton.TextColor3 = COLORS.TextColor
		tabButton.TextSize = 12
		tabButton.Font = Enum.Font.GothamBold
		tabButton.Text = tab.name
		tabButton.BorderSizePixel = 0
		tabButton.Parent = tabButtonsFrame

		table.insert(tabButtons, tabButton)

		-- Tab content frame
		local tabContent = Instance.new("Frame")
		tabContent.Name = tab.name .. "_Content"
		tabContent.Size = UDim2.new(1, 0, 1, 0)
		tabContent.BackgroundTransparency = 1
		tabContent.Visible = tabIndex == 1
		tabContent.Parent = scrolling

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.Padding = UDim.new(0, 8)
		layout.Parent = tabContent

		table.insert(tabContents, tabContent)

		-- Populate tab content
		tab.createFunc(tabContent)

		-- Tab button click handler
		tabButton.MouseButton1Click:Connect(function()
			-- Hide all tabs
			for _, tab in ipairs(tabContents) do
				tab.Visible = false
			end
			-- Show selected tab
			tabContent.Visible = true

			-- Update tab button colors
			for _, btn in ipairs(tabButtons) do
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
			end
			TweenService:Create(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Active}):Play()
		end)
	end

	return screenGui
end

-- Initialize on first call
function AdminPanel:Init()
	if not screenGui then
		screenGui = CreateAdminPanel()
	end
	return screenGui
end

-- Show the panel
function AdminPanel:Show()
	if screenGui then
		screenGui.Enabled = true
		panelVisible = true
	end
end

-- Hide the panel
function AdminPanel:Hide()
	if screenGui then
		screenGui.Enabled = false
		panelVisible = false
	end
end

-- Toggle the panel
function AdminPanel:Toggle()
	if panelVisible then
		self:Hide()
	else
		self:Show()
	end
end

return AdminPanel
