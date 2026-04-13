--[[
	DeathScreen.lua
	Death overlay GUI for "Survive a Helicopter for Brainrots"

	Features:
	- "YOU FELL!" text overlay
	- "Restarting..." countdown timer
	- Starts hidden, shown via Show/Hide functions
	- Minimal, dramatic design

	This module is initialized by HUDClient.client.lua
]]

local TweenService = game:GetService("TweenService")

local DeathScreen = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	DANGER_COLOR = Color3.fromRGB(255, 60, 60),
}

local screenGui = nil
local elements = {}
local isVisible = false
local countdownRunning = false

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
	Creates the death screen overlay
	@return: ScreenGui - the death screen gui
]]
local function CreateDeathScreen()
	local screen = Instance.new("ScreenGui")
	screen.Name = "DeathScreen"
	screen.ResetOnSpawn = false
	screen.Enabled = false  -- Starts hidden

	-- Dark overlay background
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.Parent = screen

	-- "YOU FELL!" text
	local diedText = CreateLabel(screen, "YOU FELL!", 80)
	diedText.Name = "DiedText"
	diedText.Font = Enum.Font.GothamBold
	diedText.TextColor3 = UI_CONFIG.DANGER_COLOR
	diedText.TextStrokeTransparency = 0.5
	diedText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	diedText.Size = UDim2.new(1, 0, 0, 100)
	diedText.Position = UDim2.new(0, 0, 0.3, -50)
	diedText.TextXAlignment = Enum.TextXAlignment.Center

	-- Countdown container
	local countdownContainer = Instance.new("Frame")
	countdownContainer.Name = "CountdownContainer"
	countdownContainer.BackgroundTransparency = 1
	countdownContainer.BorderSizePixel = 0
	countdownContainer.Size = UDim2.new(0, 200, 0, 80)
	countdownContainer.Position = UDim2.new(0.5, -100, 0.5, -40)
	countdownContainer.Parent = screen

	-- "Restarting in..." label
	local restartingLabel = CreateLabel(countdownContainer, "Restarting in...", 18)
	restartingLabel.Size = UDim2.new(1, 0, 0, 25)
	restartingLabel.Position = UDim2.new(0, 0, 0, 0)
	restartingLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Countdown number
	local countdownText = CreateLabel(countdownContainer, "5", 48)
	countdownText.Name = "CountdownText"
	countdownText.Font = Enum.Font.GothamBold
	countdownText.TextColor3 = UI_CONFIG.DANGER_COLOR
	countdownText.Size = UDim2.new(1, 0, 0, 50)
	countdownText.Position = UDim2.new(0, 0, 0, 30)
	countdownText.TextXAlignment = Enum.TextXAlignment.Center

	elements.diedText = diedText
	elements.countdownText = countdownText
	elements.overlay = overlay

	return screen
end

--[[
	Shows the death screen with animation
	@param respawnCallback: function - callback when respawn is triggered
	@param countdownSeconds: number - seconds until respawn (default 5)
]]
function DeathScreen:Show(respawnCallback, countdownSeconds)
	if not screenGui then return end

	screenGui.Enabled = true
	isVisible = true
	countdownSeconds = countdownSeconds or 5

	-- Animate overlay in
	local overlayTween = TweenService:Create(
		elements.overlay,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.5}
	)
	overlayTween:Play()

	-- Animate died text in
	elements.diedText.TextTransparency = 1
	local textTween = TweenService:Create(
		elements.diedText,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	textTween:Play()

	-- Start countdown
	countdownRunning = true
	task.spawn(function()
		local remaining = countdownSeconds
		while remaining > 0 and isVisible do
			elements.countdownText.Text = tostring(remaining)
			task.wait(1)
			remaining = remaining - 1
		end

		-- Auto-respawn when countdown reaches 0
		if isVisible then
			self:Hide()
			if respawnCallback then
				respawnCallback()
			end
		end
	end)
end

--[[
	Hides the death screen with animation
]]
function DeathScreen:Hide()
	if not screenGui then return end

	isVisible = false
	countdownRunning = false

	-- Animate out
	local overlayTween = TweenService:Create(
		elements.overlay,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)
	overlayTween:Play()

	local textTween = TweenService:Create(
		elements.diedText,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)
	textTween:Play()

	-- Disable screen after animation
	textTween.Completed:Connect(function()
		if not isVisible then
			screenGui.Enabled = false
		end
	end)
end

--[[
	Initializes the death screen
	@return: ScreenGui - the created ScreenGui object
]]
function DeathScreen:Init()
	screenGui = CreateDeathScreen()
	print("[DeathScreen] Initialized")
	return screenGui
end

return DeathScreen
