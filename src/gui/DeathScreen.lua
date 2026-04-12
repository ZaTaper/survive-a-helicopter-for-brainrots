--[[
	DeathScreen.lua
	Client-side death screen module for "Survive a Helicopter for Brainrots"

	Features:
	- "YOU DIED!" dramatic animated text
	- Shows what brainrot killed you and its tier
	- Displays "Fuel Reset!" warning
	- Respawn countdown timer
	- Stats summary (waves survived, kills)
	- Dramatic animations and visual effects
	- Color-coded tier information

	This module is initialized by HUDClient.client.lua
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local DeathScreen = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	DANGER_COLOR = Color3.fromRGB(255, 60, 60),
	WARNING_COLOR = Color3.fromRGB(255, 180, 60),
}

local mainFrame = nil
local playerGui = nil
local isVisible = false

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
	Creates the death screen window
	@return: Frame - the main death screen frame
]]
local function CreateDeathScreen()
	local screen = playerGui

	-- Main container (full screen overlay)
	local main = Instance.new("Frame")
	main.Name = "DeathScreen"
	main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	main.BorderSizePixel = 0
	main.Size = UDim2.new(1, 0, 1, 0)
	main.Position = UDim2.new(0, 0, 0, 0)
	main.Visible = false
	main.ZIndex = 100
	main.Parent = screen

	-- Darken overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.ZIndex = 100
	overlay.Parent = main

	-- Center panel
	local panel = CreateRoundedFrame(main, 15)
	panel.BackgroundColor3 = UI_CONFIG.PRIMARY_COLOR
	panel.BorderColor3 = UI_CONFIG.DANGER_COLOR
	panel.BorderSizePixel = 3
	panel.Size = UDim2.new(0, 500, 0, 450)
	panel.Position = UDim2.new(0.5, -250, 0.5, -225)
	panel.ZIndex = 101
	panel.Parent = main

	-- YOU DIED! Text
	local diedText = CreateLabel(panel, "YOU DIED!", 60)
	diedText.Name = "DiedText"
	diedText.Font = Enum.Font.GothamBold
	diedText.TextColor3 = UI_CONFIG.DANGER_COLOR
	diedText.TextStrokeTransparency = 0.5
	diedText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	diedText.Size = UDim2.new(1, -20, 0, 80)
	diedText.Position = UDim2.new(0, 10, 0, 10)
	diedText.TextScaled = false
	diedText.TextWrapped = true

	-- Brainrot info container
	local brainrotContainer = CreateRoundedFrame(panel, 10)
	brainrotContainer.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	brainrotContainer.Size = UDim2.new(1, -20, 0, 70)
	brainrotContainer.Position = UDim2.new(0, 10, 0, 100)
	brainrotContainer.ZIndex = 102

	local killedByLabel = CreateLabel(brainrotContainer, "Eliminated by:", 11)
	killedByLabel.TextXAlignment = Enum.TextXAlignment.Left
	killedByLabel.Size = UDim2.new(1, -10, 0, 20)
	killedByLabel.Position = UDim2.new(0, 5, 0, 5)

	local brainrotNameLabel = CreateLabel(brainrotContainer, "Unknown", 16)
	brainrotNameLabel.Name = "BrainrotName"
	brainrotNameLabel.Font = Enum.Font.GothamBold
	brainrotNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	brainrotNameLabel.Size = UDim2.new(0.7, -5, 0, 25)
	brainrotNameLabel.Position = UDim2.new(0, 5, 0, 25)

	local tierLabelText = CreateLabel(brainrotContainer, "Tier", 10)
	tierLabelText.TextXAlignment = Enum.TextXAlignment.Right
	tierLabelText.Size = UDim2.new(0.3, -5, 0, 15)
	tierLabelText.Position = UDim2.new(0.7, 5, 0, 25)

	local tierLabel = CreateLabel(brainrotContainer, "COMMON", 11)
	tierLabel.Name = "TierLabel"
	tierLabel.Font = Enum.Font.GothamBold
	tierLabel.TextXAlignment = Enum.TextXAlignment.Right
	tierLabel.Size = UDim2.new(0.3, -5, 0, 20)
	tierLabel.Position = UDim2.new(0.7, 5, 0, 38)

	-- Fuel reset warning
	local fuelWarning = CreateRoundedFrame(panel, 8)
	fuelWarning.BackgroundColor3 = UI_CONFIG.WARNING_COLOR
	fuelWarning.Size = UDim2.new(1, -20, 0, 40)
	fuelWarning.Position = UDim2.new(0, 10, 0, 180)
	fuelWarning.ZIndex = 102

	local warningText = CreateLabel(fuelWarning, "⚠ FUEL HAS BEEN RESET!", 13)
	warningText.Font = Enum.Font.GothamBold
	warningText.TextColor3 = UI_CONFIG.PRIMARY_COLOR
	warningText.TextXAlignment = Enum.TextXAlignment.Center
	warningText.Size = UDim2.new(1, 0, 1, 0)

	-- Stats container
	local statsContainer = CreateRoundedFrame(panel, 10)
	statsContainer.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	statsContainer.Size = UDim2.new(1, -20, 0, 80)
	statsContainer.Position = UDim2.new(0, 10, 0, 230)
	statsContainer.ZIndex = 102

	local statsTitle = CreateLabel(statsContainer, "SESSION SUMMARY", 11)
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.Size = UDim2.new(1, -10, 0, 20)
	statsTitle.Position = UDim2.new(0, 5, 0, 5)

	local wavesLabel = CreateLabel(statsContainer, "Waves Survived:", 12)
	wavesLabel.TextXAlignment = Enum.TextXAlignment.Left
	wavesLabel.Size = UDim2.new(0.5, -5, 0, 25)
	wavesLabel.Position = UDim2.new(0, 5, 0, 28)

	local wavesValue = CreateLabel(statsContainer, "0", 14)
	wavesValue.Name = "WavesValue"
	wavesValue.Font = Enum.Font.GothamBold
	wavesValue.TextColor3 = UI_CONFIG.ACCENT_COLOR
	wavesValue.TextXAlignment = Enum.TextXAlignment.Right
	wavesValue.Size = UDim2.new(0.5, -5, 0, 25)
	wavesValue.Position = UDim2.new(0.5, 5, 0, 28)

	local killsLabel = CreateLabel(statsContainer, "Brainrots Eliminated:", 12)
	killsLabel.TextXAlignment = Enum.TextXAlignment.Left
	killsLabel.Size = UDim2.new(0.5, -5, 0, 25)
	killsLabel.Position = UDim2.new(0, 5, 0, 53)

	local killsValue = CreateLabel(statsContainer, "0", 14)
	killsValue.Name = "KillsValue"
	killsValue.Font = Enum.Font.GothamBold
	killsValue.TextColor3 = UI_CONFIG.ACCENT_COLOR
	killsValue.TextXAlignment = Enum.TextXAlignment.Right
	killsValue.Size = UDim2.new(0.5, -5, 0, 25)
	killsValue.Position = UDim2.new(0.5, 5, 0, 53)

	-- Respawn timer
	local timerContainer = CreateRoundedFrame(panel, 10)
	timerContainer.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	timerContainer.Size = UDim2.new(1, -20, 0, 50)
	timerContainer.Position = UDim2.new(0, 10, 0, 320)
	timerContainer.ZIndex = 102

	local timerLabel = CreateLabel(timerContainer, "Respawning in...", 12)
	timerLabel.TextXAlignment = Enum.TextXAlignment.Center
	timerLabel.Size = UDim2.new(1, 0, 0.4, 0)
	timerLabel.Position = UDim2.new(0, 0, 0, 3)

	local timerText = CreateLabel(timerContainer, "5", 36)
	timerText.Name = "TimerText"
	timerText.Font = Enum.Font.GothamBold
	timerText.TextColor3 = UI_CONFIG.DANGER_COLOR
	timerText.TextXAlignment = Enum.TextXAlignment.Center
	timerText.Size = UDim2.new(1, 0, 0.6, 0)
	timerText.Position = UDim2.new(0, 0, 0.4, 0)

	-- Skip button (if available)
	local skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Text = "Press SPACE to Respawn Now"
	skipButton.Font = Enum.Font.GothamBold
	skipButton.TextSize = 13
	skipButton.TextColor3 = UI_CONFIG.TEXT_COLOR
	skipButton.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
	skipButton.BorderSizePixel = 0
	skipButton.Size = UDim2.new(1, -20, 0, 40)
	skipButton.Position = UDim2.new(0, 10, 0, 380)
	skipButton.ZIndex = 102
	skipButton.Parent = panel

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 8)
	skipCorner.Parent = skipButton

	return main
end

--[[
	Shows the death screen with animation
	@param brainrotData: table - {name: string, tier: string, tierColor: Color3}
	@param wavesSurvived: number - number of waves the player survived
	@param killCount: number - number of brainrots eliminated
	@param respawnCallback: function - callback when skip/respawn is triggered
]]
function DeathScreen:Show(brainrotData, wavesSurvived, killCount, respawnCallback)
	if not mainFrame then return end

	mainFrame.Visible = true
	isVisible = true

	-- Update brainrot info
	local panel = mainFrame:FindFirstChild("Panel") or mainFrame
	if panel:FindFirstChild("BrainrotContainer") then
		local container = panel:FindFirstChild("BrainrotContainer")
		if container:FindFirstChild("BrainrotName") then
			container:FindFirstChild("BrainrotName").Text = brainrotData.name or "Unknown Brainrot"
		end
		if container:FindFirstChild("TierLabel") then
			local tierLabel = container:FindFirstChild("TierLabel")
			tierLabel.Text = brainrotData.tier or "COMMON"
			tierLabel.TextColor3 = brainrotData.tierColor or Color3.fromRGB(180, 180, 180)
		end
	end

	-- Update stats
	if mainFrame:FindFirstChild("StatsContainer") then
		local statsContainer = mainFrame:FindFirstChild("StatsContainer")
		if statsContainer:FindFirstChild("WavesValue") then
			statsContainer:FindFirstChild("WavesValue").Text = tostring(wavesSurvived or 0)
		end
		if statsContainer:FindFirstChild("KillsValue") then
			statsContainer:FindFirstChild("KillsValue").Text = tostring(killCount or 0)
		end
	end

	-- Animate in
	local panel = mainFrame:FindFirstChild("Panel")
	if panel then
		panel.Position = UDim2.new(0.5, -250, 0.5, -500)
		panel.BackgroundTransparency = 1

		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tween = TweenService:Create(panel, tweenInfo, {
			Position = UDim2.new(0.5, -250, 0.5, -225),
			BackgroundTransparency = 0
		})
		tween:Play()

		-- Shake effect
		tween.Completed:Connect(function()
			for i = 1, 4 do
				panel.Position = UDim2.new(0.5, -250 + math.random(-5, 5), 0.5, -225 + math.random(-3, 3))
				task.wait(0.05)
			end
			panel.Position = UDim2.new(0.5, -250, 0.5, -225)
		end)
	end

	-- Start countdown
	local respawnTime = 5
	local skipButton = panel:FindFirstChild("SkipButton")
	local timerText = nil
	if panel:FindFirstChild("TimerContainer") then
		timerText = panel:FindFirstChild("TimerContainer"):FindFirstChild("TimerText")
	end

	if skipButton and respawnCallback then
		skipButton.MouseButton1Click:Connect(function()
			self:Hide()
			respawnCallback()
		end)
	end

	-- Countdown loop
	task.spawn(function()
		while respawnTime > 0 and isVisible do
			if timerText then
				timerText.Text = tostring(respawnTime)
			end
			task.wait(1)
			respawnTime = respawnTime - 1
		end

		-- Auto respawn when timer reaches 0
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
	if not mainFrame then return end

	isVisible = false

	-- Animate out
	local panel = mainFrame:FindFirstChild("Panel")
	if panel then
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(panel, tweenInfo, {
			Position = UDim2.new(0.5, -250, 0.5, 500),
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			mainFrame.Visible = false
		end)
	end
end

--[[
	Initializes the death screen
	@param playerGui: ScreenGui - the PlayerGui to attach to
]]
function DeathScreen:Init(playerGui_)
	playerGui = playerGui_
	mainFrame = CreateDeathScreen()
	print("DeathScreen initialized")
	return mainFrame
end

return DeathScreen
