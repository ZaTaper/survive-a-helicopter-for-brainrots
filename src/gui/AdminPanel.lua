--[[
	AdminPanel.lua
	Client-side admin panel GUI module for "Survive a Helicopter for Brainrots"

	Features:
	- Beautiful dark-themed professional UI
	- Draggable panel with close button
	- Scrollable content for long lists
	- Color-coded buttons matching brainrot tiers
	- Organized sections for different admin functions
	- F9 keyboard shortcut to toggle visibility

	This module is loaded by AdminClient.client.lua
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local AdminPanel = {}

-- Panel state
local panelVisible = false
local mainFrame = nil
local mouse = game.Players.LocalPlayer:GetMouse()

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(25, 25, 35),
	SECONDARY_COLOR = Color3.fromRGB(35, 35, 45),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	BORDER_COLOR = Color3.fromRGB(100, 100, 120),
	DANGER_COLOR = Color3.fromRGB(255, 60, 60),
	SUCCESS_COLOR = Color3.fromRGB(60, 255, 100),
	WARNING_COLOR = Color3.fromRGB(255, 180, 60),
}

--[[
	Creates a basic button with styling
	@param parent: GuiObject - parent to add button to
	@param text: string - button text
	@param color: Color3 - button color (defaults to accent)
	@param callback: function - function to call on click
	@return: TextButton
]]
local function CreateButton(parent, text, color, callback)
	local button = Instance.new("TextButton")
	button.Name = text
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = UI_CONFIG.TEXT_COLOR
	button.BackgroundColor3 = color or UI_CONFIG.ACCENT_COLOR
	button.BorderSizePixel = 0
	button.Parent = parent

	-- Add hover effect
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = originalColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = originalColor
	end)

	if callback then
		button.MouseButton1Click:Connect(callback)
	end

	return button
end

--[[
	Creates a text label with styling
	@param parent: GuiObject - parent to add label to
	@param text: string - label text
	@param textSize: number - font size (default 16)
	@return: TextLabel
]]
local function CreateLabel(parent, text, textSize)
	local label = Instance.new("TextLabel")
	label.Name = text
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize or 16
	label.TextColor3 = UI_CONFIG.TEXT_COLOR
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Parent = parent
	return label
end

--[[
	Creates a section header with a background
	@param parent: GuiObject - parent container
	@param text: string - section title
	@return: Frame
]]
local function CreateSection(parent, text)
	-- Section frame
	local section = Instance.new("Frame")
	section.Name = text .. "Section"
	section.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	section.BorderColor3 = UI_CONFIG.BORDER_COLOR
	section.BorderSizePixel = 1
	section.Parent = parent

	-- Section title
	local title = CreateLabel(section, text, 16)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, -10, 0, 25)
	title.Position = UDim2.new(0, 5, 0, 5)

	-- Content container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "Content"
	contentContainer.BackgroundTransparency = 1
	contentContainer.BorderSizePixel = 0
	contentContainer.Position = UDim2.new(0, 5, 0, 35)
	contentContainer.Size = UDim2.new(1, -10, 1, -40)
	contentContainer.Parent = section

	return section, contentContainer
end

--[[
	Creates the brainrot spawner section
	@param parent: GuiObject - parent container
]]
local function CreateBrainrotSpawner(parent)
	local section, content = CreateSection(parent, "Brainrot Spawner")

	-- Tier selection dropdown
	local dropdownLabel = CreateLabel(content, "Select Tier:", 13)
	dropdownLabel.Size = UDim2.new(1, 0, 0, 20)
	dropdownLabel.Position = UDim2.new(0, 0, 0, 0)

	local dropdown = Instance.new("TextButton")
	dropdown.Name = "TierDropdown"
	dropdown.Text = "Select Tier..."
	dropdown.Font = Enum.Font.Gotham
	dropdown.TextSize = 12
	dropdown.TextColor3 = UI_CONFIG.TEXT_COLOR
	dropdown.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	dropdown.BorderColor3 = UI_CONFIG.BORDER_COLOR
	dropdown.BorderSizePixel = 1
	dropdown.Size = UDim2.new(1, 0, 0, 30)
	dropdown.Position = UDim2.new(0, 0, 0, 25)
	dropdown.Parent = content

	local selectedTier = "Common"

	-- Dropdown menu (hidden by default)
	local dropdownMenu = Instance.new("Frame")
	dropdownMenu.Name = "DropdownMenu"
	dropdownMenu.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	dropdownMenu.BorderColor3 = UI_CONFIG.BORDER_COLOR
	dropdownMenu.BorderSizePixel = 1
	dropdownMenu.Size = UDim2.new(1, 0, 0, 0)
	dropdownMenu.Position = UDim2.new(0, 0, 0, 60)
	dropdownMenu.ClipsDescendants = true
	dropdownMenu.Parent = content
	dropdownMenu.Visible = false

	-- Create dropdown options
	local optionHeight = 30
	for index, tier in ipairs(GameConfig.BrainrotTiers) do
		local option = Instance.new("TextButton")
		option.Name = tier.name
		option.Text = tier.name
		option.Font = Enum.Font.Gotham
		option.TextSize = 12
		option.TextColor3 = UI_CONFIG.TEXT_COLOR
		option.BackgroundColor3 = tier.color
		option.BorderSizePixel = 0
		option.Size = UDim2.new(1, 0, 0, optionHeight)
		option.Position = UDim2.new(0, 0, 0, (index - 1) * optionHeight)
		option.Parent = dropdownMenu

		option.MouseButton1Click:Connect(function()
			selectedTier = tier.name
			dropdown.Text = tier.name
			dropdown.BackgroundColor3 = tier.color
			dropdownMenu.Visible = false
		end)
	end

	-- Toggle dropdown
	dropdown.MouseButton1Click:Connect(function()
		dropdownMenu.Visible = not dropdownMenu.Visible
		if dropdownMenu.Visible then
			dropdownMenu.Size = UDim2.new(1, 0, 0, #GameConfig.BrainrotTiers * optionHeight)
		else
			dropdownMenu.Size = UDim2.new(1, 0, 0, 0)
		end
	end)

	-- Spawn button
	local spawnBtn = CreateButton(content, "Spawn at Mouse", UI_CONFIG.SUCCESS_COLOR, function()
		local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
		local spawnEvent = AdminEvents:WaitForChild("SpawnBrainrot")
		spawnEvent:FireServer(selectedTier, mouse.Hit.Position + Vector3.new(0, 5, 0))
	end)
	spawnBtn.Size = UDim2.new(1, 0, 0, 35)
	spawnBtn.Position = UDim2.new(0, 0, 0, 70 + (#GameConfig.BrainrotTiers * optionHeight))

	section.Size = UDim2.new(1, 0, 0, 115 + (#GameConfig.BrainrotTiers * optionHeight))
	return section
end

--[[
	Creates the wave control section
	@param parent: GuiObject - parent container
]]
local function CreateWaveControl(parent, startYPos)
	local section, content = CreateSection(parent, "Wave Control")
	section.Position = UDim2.new(0, 0, 0, startYPos)

	-- Wave number input
	local waveLabel = CreateLabel(content, "Wave Number:", 13)
	waveLabel.Size = UDim2.new(1, 0, 0, 20)
	waveLabel.Position = UDim2.new(0, 0, 0, 0)

	local waveInput = Instance.new("TextBox")
	waveInput.Name = "WaveInput"
	waveInput.Text = "1"
	waveInput.Font = Enum.Font.Gotham
	waveInput.TextSize = 13
	waveInput.TextColor3 = UI_CONFIG.TEXT_COLOR
	waveInput.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	waveInput.BorderColor3 = UI_CONFIG.BORDER_COLOR
	waveInput.BorderSizePixel = 1
	waveInput.Size = UDim2.new(1, 0, 0, 30)
	waveInput.Position = UDim2.new(0, 0, 0, 25)
	waveInput.Parent = content

	-- Set wave button
	local setWaveBtn = CreateButton(content, "Set Wave", UI_CONFIG.ACCENT_COLOR, function()
		local waveNum = tonumber(waveInput.Text)
		if waveNum and waveNum >= 1 then
			local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
			local setWaveEvent = AdminEvents:WaitForChild("SetWave")
			setWaveEvent:FireServer(waveNum)
		end
	end)
	setWaveBtn.Size = UDim2.new(1, 0, 0, 35)
	setWaveBtn.Position = UDim2.new(0, 0, 0, 60)

	-- Skip phase button
	local skipBtn = CreateButton(content, "Skip to Next Wave", UI_CONFIG.WARNING_COLOR, function()
		local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
		local skipEvent = AdminEvents:WaitForChild("SkipPhase")
		skipEvent:FireServer()
	end)
	skipBtn.Size = UDim2.new(1, 0, 0, 35)
	skipBtn.Position = UDim2.new(0, 0, 0, 100)

	section.Size = UDim2.new(1, 0, 0, 145)
	return section
end

--[[
	Creates the game control section
	@param parent: GuiObject - parent container
]]
local function CreateGameControl(parent, startYPos)
	local section, content = CreateSection(parent, "Game Control")
	section.Position = UDim2.new(0, 0, 0, startYPos)

	-- Kill all brainrots button
	local killAllBtn = CreateButton(content, "Kill All Brainrots", UI_CONFIG.DANGER_COLOR, function()
		local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
		local killEvent = AdminEvents:WaitForChild("KillAllBrainrots")
		killEvent:FireServer()
	end)
	killAllBtn.Size = UDim2.new(1, 0, 0, 35)
	killAllBtn.Position = UDim2.new(0, 0, 0, 0)

	-- Toggle godmode button
	local godmodeBtn = CreateButton(content, "Toggle Godmode (You)", UI_CONFIG.SUCCESS_COLOR, function()
		local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
		local godmodeEvent = AdminEvents:WaitForChild("ToggleGodmode")
		godmodeEvent:FireServer(game.Players.LocalPlayer.Name)
	end)
	godmodeBtn.Size = UDim2.new(1, 0, 0, 35)
	godmodeBtn.Position = UDim2.new(0, 0, 0, 40)

	section.Size = UDim2.new(1, 0, 0, 85)
	return section
end

--[[
	Creates the main admin panel UI
	@return: Frame - the main panel frame
]]
local function CreateAdminPanel()
	local screenSize = game.Players.LocalPlayer:WaitForChild("PlayerGui").AbsoluteSize

	-- Main frame (draggable container)
	local main = Instance.new("Frame")
	main.Name = "AdminPanel"
	main.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	main.BorderColor3 = UI_CONFIG.BORDER_COLOR
	main.BorderSizePixel = 2
	main.Size = UDim2.new(0, 400, 0, 600)
	main.Position = UDim2.new(0.5, -200, 0.5, -300)
	main.Visible = false
	main.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
	titleBar.BorderSizePixel = 0
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Parent = main

	local titleText = CreateLabel(titleBar, "ADMIN PANEL", 18)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Size = UDim2.new(1, -45, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = UI_CONFIG.TEXT_COLOR
	closeBtn.BackgroundColor3 = UI_CONFIG.DANGER_COLOR
	closeBtn.BorderSizePixel = 0
	closeBtn.Size = UDim2.new(0, 35, 1, 0)
	closeBtn.Position = UDim2.new(1, -40, 0, 0)
	closeBtn.Parent = titleBar

	closeBtn.MouseButton1Click:Connect(function()
		panelVisible = false
		main.Visible = false
	end)

	-- Dragging functionality
	local dragging = false
	local dragStart = nil
	local framePos = nil

	titleBar.MouseButton1Down:Connect(function()
		dragging = true
		dragStart = mouse.X - main.AbsolutePosition.X
		framePos = main.Position
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	game:GetService("RunService").RenderStepped:Connect(function()
		if dragging and titleBar.Visible then
			local mousePos = mouse.X
			local newPos = framePos.X.Offset + (mousePos - (dragStart + main.AbsolutePosition.X))
			main.Position = UDim2.new(framePos.X.Scale, newPos, main.Position.Y.Scale, main.Position.Y.Offset)
		end
	end)

	-- Scrollable content frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ContentScroll"
	scrollFrame.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Size = UDim2.new(1, 0, 1, -40)
	scrollFrame.Position = UDim2.new(0, 0, 0, 40)
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = UI_CONFIG.ACCENT_COLOR
	scrollFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
	scrollFrame.Parent = main

	-- Create sections
	local brainrotSpawner = CreateBrainrotSpawner(scrollFrame)
	brainrotSpawner.Position = UDim2.new(0, 5, 0, 5)
	brainrotSpawner.Size = UDim2.new(1, -10, 0, 150)

	local waveControl = CreateWaveControl(scrollFrame, 160)
	waveControl.Size = UDim2.new(1, -10, 0, 150)

	local gameControl = CreateGameControl(scrollFrame, 320)
	gameControl.Size = UDim2.new(1, -10, 0, 100)

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(1, 0, 0, 430)

	return main
end

--[[
	Shows the admin panel
]]
function AdminPanel:Show()
	if mainFrame then
		mainFrame.Visible = true
		panelVisible = true
	end
end

--[[
	Hides the admin panel
]]
function AdminPanel:Hide()
	if mainFrame then
		mainFrame.Visible = false
		panelVisible = false
	end
end

--[[
	Toggles admin panel visibility
]]
function AdminPanel:Toggle()
	if panelVisible then
		self:Hide()
	else
		self:Show()
	end
end

--[[
	Initializes the admin panel
]]
function AdminPanel:Init()
	mainFrame = CreateAdminPanel()
	print("Admin Panel initialized for " .. game.Players.LocalPlayer.Name)
end

return AdminPanel
