--[[
	MusicSettings.lua
	Music control GUI for "Survive a Helicopter for Brainrots"

	Compact music control widget in bottom-right corner:
	- Volume slider (click to adjust)
	- Mute/unmute button (speaker icon)
	- Now playing text display
	- Dark semi-transparent background
	- Non-intrusive, doesn't block gameplay

	This module is initialized by MusicClient.client.lua
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MusicSettings = {}

-- UI Configuration
local UI_CONFIG = {
	PRIMARY_COLOR = Color3.fromRGB(20, 20, 28),
	SECONDARY_COLOR = Color3.fromRGB(30, 30, 40),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
}

local screenGui = nil
local elements = {}
local currentVolume = 0.6
local isMuted = false

-- Create a rounded frame with styling
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

-- Create a text label with styling
local function CreateLabel(parent, text, textSize)
	local label = Instance.new("TextLabel")
	label.Name = "Label_" .. text
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize or 12
	label.TextColor3 = UI_CONFIG.TEXT_COLOR
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Parent = parent
	return label
end

-- Create the music settings UI
local function CreateMusicSettingsUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "MusicSettings"
	screen.ResetOnSpawn = false
	screen.Enabled = true

	-- Main container (bottom-right corner)
	local mainContainer = CreateRoundedFrame(screen, 8)
	mainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	mainContainer.BackgroundTransparency = 0.2
	mainContainer.Size = UDim2.new(0, 220, 0, 100)
	mainContainer.Position = UDim2.new(1, -230, 1, -110)

	-- Now Playing label
	local nowPlayingLabel = CreateLabel(mainContainer, "Now Playing:", 10)
	nowPlayingLabel.TextXAlignment = Enum.TextXAlignment.Left
	nowPlayingLabel.Size = UDim2.new(1, -20, 0, 15)
	nowPlayingLabel.Position = UDim2.new(0, 10, 0, 5)

	-- Track name display
	local trackNameLabel = CreateLabel(mainContainer, "Lobby Theme", 11)
	trackNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	trackNameLabel.TextColor3 = UI_CONFIG.ACCENT_COLOR
	trackNameLabel.Size = UDim2.new(1, -20, 0, 15)
	trackNameLabel.Position = UDim2.new(0, 10, 0, 18)

	-- Volume label
	local volumeLabel = CreateLabel(mainContainer, "Volume", 10)
	volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
	volumeLabel.Size = UDim2.new(0.6, 0, 0, 12)
	volumeLabel.Position = UDim2.new(0, 10, 0, 38)

	-- Mute button (speaker icon using text)
	local muteBtn = Instance.new("TextButton")
	muteBtn.Name = "MuteButton"
	muteBtn.Text = "🔊"
	muteBtn.Font = Enum.Font.Gotham
	muteBtn.TextSize = 16
	muteBtn.TextColor3 = UI_CONFIG.TEXT_COLOR
	muteBtn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
	muteBtn.BorderSizePixel = 0
	muteBtn.Size = UDim2.new(0, 30, 0, 30)
	muteBtn.Position = UDim2.new(1, -40, 0, 35)
	muteBtn.Parent = mainContainer

	local muteCorner = Instance.new("UICorner")
	muteCorner.CornerRadius = UDim.new(0, 4)
	muteCorner.Parent = muteBtn

	-- Volume slider background
	local sliderBg = CreateRoundedFrame(mainContainer, 3)
	sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	sliderBg.Size = UDim2.new(0.6, -15, 0, 8)
	sliderBg.Position = UDim2.new(0, 10, 0, 55)

	-- Volume slider fill
	local sliderFill = CreateRoundedFrame(sliderBg, 3)
	sliderFill.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
	sliderFill.Size = UDim2.new(currentVolume, 0, 1, 0)
	sliderFill.Position = UDim2.new(0, 0, 0, 0)

	-- Volume percentage label
	local volPercentLabel = CreateLabel(mainContainer, "60%", 9)
	volPercentLabel.TextXAlignment = Enum.TextXAlignment.Center
	volPercentLabel.Size = UDim2.new(0.35, 0, 0, 12)
	volPercentLabel.Position = UDim2.new(0.65, 0, 0, 56)

	elements.mainContainer = mainContainer
	elements.trackNameLabel = trackNameLabel
	elements.sliderBg = sliderBg
	elements.sliderFill = sliderFill
	elements.volPercentLabel = volPercentLabel
	elements.muteBtn = muteBtn

	return screen
end

-- Setup slider input handling
local function SetupSliderInput()
	local sliderBg = elements.sliderBg
	local sliderFill = elements.sliderFill
	local volPercentLabel = elements.volPercentLabel
	local dragging = false
	local mouse = game:GetService("Players").LocalPlayer:GetMouse()

	-- Slider click handling
	sliderBg.MouseButton1Down:Connect(function()
		dragging = true
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	-- Update volume as mouse moves
	game:GetService("RunService").RenderStepped:Connect(function()
		if dragging and sliderBg.Visible then
			local sliderSize = sliderBg.AbsoluteSize.X
			local sliderPos = sliderBg.AbsolutePosition.X
			local mouseX = mouse.X

			currentVolume = math.max(0, math.min(1, (mouseX - sliderPos) / sliderSize))
			sliderFill.Size = UDim2.new(currentVolume, 0, 1, 0)
			volPercentLabel.Text = string.format("%.0f%%", currentVolume * 100)

			-- Fire volume changed callback
			if MusicSettings.OnVolumeChanged then
				MusicSettings.OnVolumeChanged(currentVolume)
			end
		end
	end)
end

-- Setup mute button handling
local function SetupMuteButton()
	local muteBtn = elements.muteBtn

	muteBtn.MouseButton1Click:Connect(function()
		isMuted = not isMuted

		if isMuted then
			muteBtn.Text = "🔇"
		else
			muteBtn.Text = "🔊"
		end

		if MusicSettings.OnMuteChanged then
			MusicSettings.OnMuteChanged(isMuted)
		end
	end)
end

-- Initialize the music settings UI
function MusicSettings:Init()
	screenGui = CreateMusicSettingsUI()

	-- Setup slider input
	SetupSliderInput()

	-- Setup mute button
	SetupMuteButton()

	print("[MusicSettings] Initialized")
	return screenGui
end

-- Set current track name display
function MusicSettings:SetCurrentTrack(trackName)
	if elements.trackNameLabel then
		elements.trackNameLabel.Text = trackName or "Unknown"
	end
end

-- Set the current volume
function MusicSettings:SetVolume(volume)
	currentVolume = math.max(0, math.min(1, volume))
	elements.sliderFill.Size = UDim2.new(currentVolume, 0, 1, 0)
	elements.volPercentLabel.Text = string.format("%.0f%%", currentVolume * 100)
end

-- Get the current volume
function MusicSettings:GetVolume()
	return currentVolume
end

-- Get mute state
function MusicSettings:IsMuted()
	return isMuted
end

return MusicSettings
