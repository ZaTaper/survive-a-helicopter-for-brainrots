-- LoadingScreen.client.lua
-- Shows a loading screen while the game assets load

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create loading screen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
background.BorderSizePixel = 0
background.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.8, 0, 0.15, 0)
title.Position = UDim2.new(0.1, 0, 0.3, 0)
title.BackgroundTransparency = 1
title.Text = "SURVIVE A HELICOPTER\nFOR BRAINROTS"
title.TextColor3 = Color3.fromRGB(255, 100, 50)
title.TextScaled = true
title.Font = Enum.Font.FredokaOne
title.Parent = background

local loadingText = Instance.new("TextLabel")
loadingText.Size = UDim2.new(0.5, 0, 0.05, 0)
loadingText.Position = UDim2.new(0.25, 0, 0.6, 0)
loadingText.BackgroundTransparency = 1
loadingText.Text = "Loading..."
loadingText.TextColor3 = Color3.fromRGB(200, 200, 200)
loadingText.TextScaled = true
loadingText.Font = Enum.Font.GothamBold
loadingText.Parent = background

-- Loading bar
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0.5, 0, 0.02, 0)
barBg.Position = UDim2.new(0.25, 0, 0.67, 0)
barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
barBg.BorderSizePixel = 0
barBg.Parent = background

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

-- Animate loading bar
ReplicatedFirst:RemoveDefaultLoadingScreen()

local tween = TweenService:Create(barFill, TweenInfo.new(3, Enum.EasingStyle.Quad), {
	Size = UDim2.new(1, 0, 1, 0)
})
tween:Play()
tween.Completed:Wait()

-- Wait a bit then fade out
task.wait(0.5)
local fadeOut = TweenService:Create(background, TweenInfo.new(1, Enum.EasingStyle.Quad), {
	BackgroundTransparency = 1
})
local fadeTitleOut = TweenService:Create(title, TweenInfo.new(1), {TextTransparency = 1})
local fadeLoadOut = TweenService:Create(loadingText, TweenInfo.new(1), {TextTransparency = 1})

fadeOut:Play()
fadeTitleOut:Play()
fadeLoadOut:Play()
fadeOut.Completed:Wait()

screenGui:Destroy()
