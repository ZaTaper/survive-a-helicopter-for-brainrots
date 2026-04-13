--[[
	MainHUD.lua
	Client-side main HUD module for "Survive a Helicopter for Brainrots"

	Features:
	- Minimal fuel bar (top left) with color-coded status
	- BrainBucks balance display (top right, gold colored)
	- Wave counter
	- Engine/fuel canister count
	- Clean, minimal design that doesn't block gameplay
	- Always visible at start

	This module is initialized by HUDClient.client.lua
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MainHUD = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
	DANGER_COLOR = Color3.fromRGB(255, 60, 60),
	WARNING_COLOR = Color3.fromRGB(255, 180, 60),
	SUCCESS_COLOR = Color3.fromRGB(60, 255, 100),
	GOLD_COLOR = Color3.fromRGB(255, 215, 0),
}

local screenGui = nil
local hudElements = {}

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
	Creates the main HUD (minimal and non-intrusive)
	@return: ScreenGui - the main HUD screen gui
]]
local function CreateMainHUD()
	-- Create the ScreenGui container
	local screen = Instance.new("ScreenGui")
	screen.Name = "MainHUD"
	screen.ResetOnSpawn = false
	screen.Enabled = true  -- Starts visible

	-- Top-left corner: Fuel bar and stats
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.BackgroundTransparency = 1
	leftPanel.BorderSizePixel = 0
	leftPanel.Size = UDim2.new(0, 200, 0, 180)
	leftPanel.Position = UDim2.new(0, 10, 0, 10)
	leftPanel.Parent = screen

	-- Fuel bar background
	local fuelBarBg = CreateRoundedFrame(leftPanel, 6)
	fuelBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	fuelBarBg.Size = UDim2.new(1, 0, 0, 12)
	fuelBarBg.Position = UDim2.new(0, 0, 0, 0)

	-- Fuel bar fill
	local fuelBar = CreateRoundedFrame(fuelBarBg, 6)
	fuelBar.BackgroundColor3 = UI_CONFIG.SUCCESS_COLOR
	fuelBar.Size = UDim2.new(1, 0, 1, 0)
	fuelBar.Position = UDim2.new(0, 0, 0, 0)
	hudElements.fuelBar = fuelBar

	-- Fuel percentage text
	local fuelPercentLabel = CreateLabel(leftPanel, "100%", 12)
	fuelPercentLabel.Font = Enum.Font.GothamBold
	fuelPercentLabel.TextXAlignment = Enum.TextXAlignment.Right
	fuelPercentLabel.Size = UDim2.new(1, 0, 0, 16)
	fuelPercentLabel.Position = UDim2.new(0, 0, 0, 14)
	hudElements.fuelPercentLabel = fuelPercentLabel

	-- Wave counter
	local waveLabel = CreateLabel(leftPanel, "Wave: 1", 11)
	waveLabel.TextXAlignment = Enum.TextXAlignment.Left
	waveLabel.Size = UDim2.new(1, 0, 0, 18)
	waveLabel.Position = UDim2.new(0, 0, 0, 35)
	hudElements.waveLabel = waveLabel

	-- Engine count
	local engineCountLabel = CreateLabel(leftPanel, "Engines: 0", 11)
	engineCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	engineCountLabel.Size = UDim2.new(1, 0, 0, 18)
	engineCountLabel.Position = UDim2.new(0, 0, 0, 55)
	hudElements.engineCountLabel = engineCountLabel

	-- Fuel canister count
	local canisterCountLabel = CreateLabel(leftPanel, "Canisters: 0", 11)
	canisterCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	canisterCountLabel.Size = UDim2.new(1, 0, 0, 18)
	canisterCountLabel.Position = UDim2.new(0, 0, 0, 75)
	hudElements.canisterCountLabel = canisterCountLabel

	-- Top-right corner: BrainBucks balance
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	rightPanel.BorderSizePixel = 0
	rightPanel.Size = UDim2.new(0, 140, 0, 50)
	rightPanel.Position = UDim2.new(1, -150, 0, 10)
	rightPanel.Parent = screen

	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 6)
	rightCorner.Parent = rightPanel

	local brainBucksLabel = CreateLabel(rightPanel, "BrainBucks", 9)
	brainBucksLabel.TextXAlignment = Enum.TextXAlignment.Center
	brainBucksLabel.Size = UDim2.new(1, 0, 0, 14)
	brainBucksLabel.Position = UDim2.new(0, 0, 0, 3)

	local brainBucksValue = CreateLabel(rightPanel, "0", 24)
	brainBucksValue.Font = Enum.Font.GothamBold
	brainBucksValue.TextColor3 = UI_CONFIG.GOLD_COLOR
	brainBucksValue.TextXAlignment = Enum.TextXAlignment.Center
	brainBucksValue.Size = UDim2.new(1, 0, 0, 30)
	brainBucksValue.Position = UDim2.new(0, 0, 0, 18)
	hudElements.brainBucksValue = brainBucksValue

	return screen
end

--[[
	Updates the fuel gauge with current fuel value and color
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
		fuelColor = UI_CONFIG.SUCCESS_COLOR:Lerp(UI_CONFIG.WARNING_COLOR, 1 - ((fuelPercent - 0.5) / 0.5))
	else
		fuelColor = UI_CONFIG.WARNING_COLOR:Lerp(UI_CONFIG.DANGER_COLOR, 1 - (fuelPercent / 0.5))
	end

	-- Animate fuel bar
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hudElements.fuelBar, tweenInfo, {
		Size = UDim2.new(fuelPercent, 0, 1, 0),
		BackgroundColor3 = fuelColor
	})
	tween:Play()

	-- Update percentage label
	hudElements.fuelPercentLabel.Text = fuelPercentInt .. "%"
end

--[[
	Updates the wave counter display
	@param waveNumber: number - current wave number
]]
function MainHUD:UpdateWave(waveNumber)
	if hudElements.waveLabel then
		hudElements.waveLabel.Text = "Wave: " .. tostring(waveNumber)
	end
end

--[[
	Updates the engine count display
	@param engineCount: number - number of engines installed
]]
function MainHUD:UpdateEngineCount(engineCount)
	if hudElements.engineCountLabel then
		hudElements.engineCountLabel.Text = "Engines: " .. tostring(engineCount)
	end
end

--[[
	Updates the fuel canister count display
	@param canisterCount: number - number of fuel canisters installed
]]
function MainHUD:UpdateCanisterCount(canisterCount)
	if hudElements.canisterCountLabel then
		hudElements.canisterCountLabel.Text = "Canisters: " .. tostring(canisterCount)
	end
end

--[[
	Updates the BrainBucks balance display
	@param brainBucks: number - current BrainBucks balance
]]
function MainHUD:UpdateBrainBucks(brainBucks)
	if hudElements.brainBucksValue then
		hudElements.brainBucksValue.Text = tostring(brainBucks)
	end
end

--[[
	Initializes the main HUD
	@return: ScreenGui - the created ScreenGui object
]]
function MainHUD:Init()
	screenGui = CreateMainHUD()
	print("[MainHUD] Initialized")
	return screenGui
end

return MainHUD
