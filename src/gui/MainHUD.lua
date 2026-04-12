--[[
	MainHUD.lua
	Client-side main HUD module for "Survive a Helicopter for Brainrots"

	Features:
	- Real-time fuel gauge with color transitions (green -> yellow -> red)
	- Speed indicator showing current helicopter speed
	- Engine and fuel canister counts with icons
	- Wave counter display
	- Phase indicator with phase-specific colors
	- Timer for current phase
	- Kill counter for brainrots defeated
	- Mini notifications for pickups (animated pop-ins)
	- Clean, modern gaming UI with rounded corners and gradients
	- Tweened animations for state transitions

	This module is initialized by HUDClient.client.lua
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local MainHUD = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	BORDER_COLOR = Color3.fromRGB(60, 60, 80),
	DANGER_COLOR = Color3.fromRGB(255, 60, 60),
	WARNING_COLOR = Color3.fromRGB(255, 180, 60),
	SUCCESS_COLOR = Color3.fromRGB(60, 255, 100),
}

-- Phase colors
local PHASE_COLORS = {
	LOBBY = Color3.fromRGB(100, 100, 200),
	BUILD = Color3.fromRGB(100, 200, 100),
	SURVIVE = Color3.fromRGB(255, 100, 100),
	ROUNDEND = Color3.fromRGB(200, 100, 255),
}

local mainFrame = nil
local playerGui = nil
local hudElements = {}

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
	Creates the main HUD frame (top-left corner)
	@return: Frame - the main HUD container
]]
local function CreateMainHUD()
	local screen = playerGui

	-- Main container (top-left corner)
	local main = Instance.new("Frame")
	main.Name = "MainHUD"
	main.BackgroundTransparency = 1
	main.BorderSizePixel = 0
	main.Size = UDim2.new(0, 350, 0, 400)
	main.Position = UDim2.new(0, 15, 0, 15)
	main.Parent = screen

	-- Title bar with game info
	local titleBar = CreateRoundedFrame(main, 10)
	titleBar.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Position = UDim2.new(0, 0, 0, 0)

	local titleText = CreateLabel(titleBar, "HELICOPTER STATS", 14)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Size = UDim2.new(1, -10, 1, 0)
	titleText.Position = UDim2.new(0, 8, 0, 0)

	-- Phase indicator (top-right info)
	local phaseContainer = CreateRoundedFrame(main, 8)
	phaseContainer.Size = UDim2.new(1, 0, 0, 35)
	phaseContainer.Position = UDim2.new(0, 0, 0, 45)

	local phaseLabel = CreateLabel(phaseContainer, "BUILD PHASE", 13)
	phaseLabel.Font = Enum.Font.GothamBold
	phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
	phaseLabel.Size = UDim2.new(0.5, -5, 1, 0)
	phaseLabel.Position = UDim2.new(0, 8, 0, 0)
	hudElements.phaseLabel = phaseLabel

	local phaseTimer = CreateLabel(phaseContainer, "0:00", 13)
	phaseTimer.Font = Enum.Font.GothamBold
	phaseTimer.TextXAlignment = Enum.TextXAlignment.Center
	phaseTimer.Size = UDim2.new(0.5, -5, 1, 0)
	phaseTimer.Position = UDim2.new(0.5, 5, 0, 0)
	hudElements.phaseTimer = phaseTimer

	-- Wave counter
	local waveContainer = CreateRoundedFrame(main, 8)
	waveContainer.Size = UDim2.new(1, 0, 0, 35)
	waveContainer.Position = UDim2.new(0, 0, 0, 85)

	local waveLabel = CreateLabel(waveContainer, "WAVE", 11)
	waveLabel.TextXAlignment = Enum.TextXAlignment.Left
	waveLabel.Size = UDim2.new(0.3, -5, 1, 0)
	waveLabel.Position = UDim2.new(0, 8, 0, 0)

	local waveNumber = CreateLabel(waveContainer, "1", 20)
	waveNumber.Font = Enum.Font.GothamBold
	waveNumber.TextXAlignment = Enum.TextXAlignment.Center
	waveNumber.Size = UDim2.new(0.7, -8, 1, 0)
	waveNumber.Position = UDim2.new(0.3, 5, 0, 0)
	hudElements.waveNumber = waveNumber

	-- Speed indicator
	local speedContainer = CreateRoundedFrame(main, 8)
	speedContainer.Size = UDim2.new(1, 0, 0, 35)
	speedContainer.Position = UDim2.new(0, 0, 0, 125)

	local speedLabel = CreateLabel(speedContainer, "SPEED", 11)
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Size = UDim2.new(0.3, -5, 1, 0)
	speedLabel.Position = UDim2.new(0, 8, 0, 0)

	local speedValue = CreateLabel(speedContainer, "20", 20)
	speedValue.Font = Enum.Font.GothamBold
	speedValue.TextXAlignment = Enum.TextXAlignment.Center
	speedValue.Size = UDim2.new(0.7, -8, 1, 0)
	speedValue.Position = UDim2.new(0.3, 5, 0, 0)
	hudElements.speedValue = speedValue

	-- Fuel gauge
	local fuelLabel = CreateLabel(main, "FUEL", 11)
	fuelLabel.TextXAlignment = Enum.TextXAlignment.Left
	fuelLabel.Size = UDim2.new(0.5, 0, 0, 20)
	fuelLabel.Position = UDim2.new(0, 0, 0, 165)

	local fuelPercentLabel = CreateLabel(main, "100%", 11)
	fuelPercentLabel.TextXAlignment = Enum.TextXAlignment.Right
	fuelPercentLabel.Size = UDim2.new(0.5, 0, 0, 20)
	fuelPercentLabel.Position = UDim2.new(0.5, 0, 0, 165)
	hudElements.fuelPercentLabel = fuelPercentLabel

	-- Fuel bar background
	local fuelBarBg = CreateRoundedFrame(main, 6)
	fuelBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	fuelBarBg.Size = UDim2.new(1, 0, 0, 20)
	fuelBarBg.Position = UDim2.new(0, 0, 0, 188)

	-- Fuel bar fill
	local fuelBar = CreateRoundedFrame(fuelBarBg, 6)
	fuelBar.BackgroundColor3 = UI_CONFIG.SUCCESS_COLOR
	fuelBar.Size = UDim2.new(1, 0, 1, 0)
	fuelBar.Position = UDim2.new(0, 0, 0, 0)
	hudElements.fuelBar = fuelBar

	-- Engines and fuel canisters info
	local equipmentContainer = CreateRoundedFrame(main, 8)
	equipmentContainer.Size = UDim2.new(1, 0, 0, 55)
	equipmentContainer.Position = UDim2.new(0, 0, 0, 215)

	-- Engines row
	local engineIcon = CreateLabel(equipmentContainer, "⚙", 20)
	engineIcon.TextXAlignment = Enum.TextXAlignment.Center
	engineIcon.Size = UDim2.new(0, 30, 0.5, 0)
	engineIcon.Position = UDim2.new(0, 8, 0, 3)

	local engineLabel = CreateLabel(equipmentContainer, "Engines:", 11)
	engineLabel.TextXAlignment = Enum.TextXAlignment.Left
	engineLabel.Size = UDim2.new(0.5, -40, 0.5, 0)
	engineLabel.Position = UDim2.new(0, 40, 0, 3)

	local engineCount = CreateLabel(equipmentContainer, "0", 13)
	engineCount.Font = Enum.Font.GothamBold
	engineCount.TextXAlignment = Enum.TextXAlignment.Right
	engineCount.Size = UDim2.new(0.5, -8, 0.5, 0)
	engineCount.Position = UDim2.new(0.5, -8, 0, 3)
	hudElements.engineCount = engineCount

	-- Fuel canisters row
	local canisterIcon = CreateLabel(equipmentContainer, "🛢", 20)
	canisterIcon.TextXAlignment = Enum.TextXAlignment.Center
	canisterIcon.Size = UDim2.new(0, 30, 0.5, 0)
	canisterIcon.Position = UDim2.new(0, 8, 0.5, 3)

	local canisterLabel = CreateLabel(equipmentContainer, "Canisters:", 11)
	canisterLabel.TextXAlignment = Enum.TextXAlignment.Left
	canisterLabel.Size = UDim2.new(0.5, -40, 0.5, 0)
	canisterLabel.Position = UDim2.new(0, 40, 0.5, 3)

	local canisterCount = CreateLabel(equipmentContainer, "0", 13)
	canisterCount.Font = Enum.Font.GothamBold
	canisterCount.TextXAlignment = Enum.TextXAlignment.Right
	canisterCount.Size = UDim2.new(0.5, -8, 0.5, 0)
	canisterCount.Position = UDim2.new(0.5, -8, 0.5, 3)
	hudElements.canisterCount = canisterCount

	-- Kill counter (bottom of HUD)
	local killContainer = CreateRoundedFrame(main, 8)
	killContainer.BackgroundColor3 = UI_CONFIG.DANGER_COLOR
	killContainer.Size = UDim2.new(1, 0, 0, 45)
	killContainer.Position = UDim2.new(0, 0, 0, 275)

	local killLabel = CreateLabel(killContainer, "BRAINROTS ELIMINATED", 10)
	killLabel.TextXAlignment = Enum.TextXAlignment.Center
	killLabel.Size = UDim2.new(1, -10, 0.4, 0)
	killLabel.Position = UDim2.new(0, 5, 0, 2)

	local killCount = CreateLabel(killContainer, "0", 24)
	killCount.Font = Enum.Font.GothamBold
	killCount.TextXAlignment = Enum.TextXAlignment.Center
	killCount.Size = UDim2.new(1, -10, 0.6, 0)
	killCount.Position = UDim2.new(0, 5, 0.4, 0)
	hudElements.killCount = killCount

	-- Notification container (for pickup notifications)
	local notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.BorderSizePixel = 0
	notificationContainer.Size = UDim2.new(0, 350, 0, 200)
	notificationContainer.Position = UDim2.new(0, 0, 0, 330)
	notificationContainer.Parent = main
	hudElements.notificationContainer = notificationContainer

	return main
end

--[[
	Updates the fuel gauge with current fuel value
	@param currentFuel: number - current fuel amount
	@param maxFuel: number - maximum fuel capacity
]]
function MainHUD:UpdateFuel(currentFuel, maxFuel)
	if not hudElements.fuelBar then return end

	local fuelPercent = math.min(1, math.max(0, currentFuel / maxFuel))
	local fuelPercentInt = math.floor(fuelPercent * 100)

	-- Color based on fuel level: green -> yellow -> red
	local fuelColor
	if fuelPercent > 0.5 then
		-- Green to yellow: interpolate between green and yellow
		fuelColor = Color3.fromRGB(60, 255, 100):Lerp(Color3.fromRGB(255, 180, 60), 1 - ((fuelPercent - 0.5) / 0.5))
	else
		-- Yellow to red: interpolate between yellow and red
		fuelColor = Color3.fromRGB(255, 180, 60):Lerp(Color3.fromRGB(255, 60, 60), 1 - (fuelPercent / 0.5))
	end

	-- Animate fuel bar width and color
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hudElements.fuelBar, tweenInfo, {
		Size = UDim2.new(fuelPercent, 0, 1, 0),
		BackgroundColor3 = fuelColor
	})
	tween:Play()

	-- Update fuel percentage label
	hudElements.fuelPercentLabel.Text = fuelPercentInt .. "%"
end

--[[
	Updates the speed indicator
	@param speed: number - current helicopter speed
]]
function MainHUD:UpdateSpeed(speed)
	if hudElements.speedValue then
		hudElements.speedValue.Text = tostring(math.floor(speed))
	end
end

--[[
	Updates the engine count display
	@param engineCount: number - number of engines installed
]]
function MainHUD:UpdateEngineCount(engineCount)
	if hudElements.engineCount then
		hudElements.engineCount.Text = tostring(engineCount)
	end
end

--[[
	Updates the fuel canister count display
	@param canisterCount: number - number of fuel canisters installed
]]
function MainHUD:UpdateCanisterCount(canisterCount)
	if hudElements.canisterCount then
		hudElements.canisterCount.Text = tostring(canisterCount)
	end
end

--[[
	Updates the wave counter
	@param waveNumber: number - current wave number
]]
function MainHUD:UpdateWave(waveNumber)
	if hudElements.waveNumber then
		hudElements.waveNumber.Text = tostring(waveNumber)
	end
end

--[[
	Updates the phase indicator with color and text
	@param phase: string - current phase ("LOBBY", "BUILD", "SURVIVE", "ROUNDEND")
	@param parent: GuiObject - parent frame containing the phase label
]]
function MainHUD:UpdatePhase(phase, parent)
	if not hudElements.phaseLabel then return end

	local phaseText = phase == "SURVIVE" and "SURVIVE!" or (phase or "UNKNOWN")
	local phaseColor = PHASE_COLORS[phase] or UI_CONFIG.ACCENT_COLOR

	hudElements.phaseLabel.Text = phaseText

	-- Animate phase label color change
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hudElements.phaseLabel.Parent, tweenInfo, {
		BackgroundColor3 = phaseColor
	})
	tween:Play()
end

--[[
	Updates the phase timer
	@param timeRemaining: number - seconds remaining in phase
]]
function MainHUD:UpdatePhaseTimer(timeRemaining)
	if not hudElements.phaseTimer then return end

	local minutes = math.floor(timeRemaining / 60)
	local seconds = math.floor(timeRemaining % 60)
	hudElements.phaseTimer.Text = string.format("%d:%02d", minutes, seconds)
end

--[[
	Updates the kill counter
	@param killCount: number - number of brainrots eliminated
]]
function MainHUD:UpdateKillCount(killCount)
	if hudElements.killCount then
		-- Animate kill count with scale
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tween = TweenService:Create(hudElements.killCount, tweenInfo, {
			TextScaled = true
		})
		tween:Play()

		hudElements.killCount.Text = tostring(killCount)
	end
end

--[[
	Shows a pickup notification (animated pop-in)
	@param itemType: string - "engine" or "fuelCanister"
	@param quantity: number - how many were picked up (default 1)
]]
function MainHUD:ShowPickupNotification(itemType, quantity)
	if not hudElements.notificationContainer then return end

	local notif = CreateRoundedFrame(hudElements.notificationContainer, 8)
	notif.Size = UDim2.new(1, -10, 0, 40)
	notif.Position = UDim2.new(0.5, -155, 0, #hudElements.notificationContainer:GetChildren() * 45)

	-- Color based on item type
	local itemColor = (itemType == "engine") and UI_CONFIG.SUCCESS_COLOR or UI_CONFIG.WARNING_COLOR
	notif.BackgroundColor3 = itemColor

	local text = (itemType == "engine" and "⚙ " or "🛢 ")
	text = text .. "+" .. (quantity or 1) .. " " .. (itemType == "engine" and "Engine" or "Fuel Canister")

	local label = CreateLabel(notif, text, 13)
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)

	-- Animate in
	notif.Size = UDim2.new(1, -10, 0, 0)
	notif.BackgroundTransparency = 1
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, -10, 0, 40),
		BackgroundTransparency = 0
	})
	tweenIn:Play()

	-- Wait and animate out
	task.delay(3, function()
		local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1, -10, 0, 0),
			BackgroundTransparency = 1
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end

--[[
	Initializes the main HUD
	@param playerGui: ScreenGui - the PlayerGui to attach to
]]
function MainHUD:Init(playerGui_)
	playerGui = playerGui_
	mainFrame = CreateMainHUD()
	print("MainHUD initialized")
	return mainFrame
end

return MainHUD
