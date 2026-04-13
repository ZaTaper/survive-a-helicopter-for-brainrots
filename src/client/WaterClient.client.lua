-- WaterClient.client.lua
-- Client-side water effects for splash, screen effects, and restart notifications

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaterClient = {}

-- Configuration
local SPLASH_DURATION = 1.5
local SCREEN_FLASH_DURATION = 0.5
local CAMERA_SHAKE_INTENSITY = 0.3
local CAMERA_SHAKE_DURATION = 0.4

-- Remote events
local splashEvent = ReplicatedStorage:WaitForChild("WaterSplash")
local restartEvent = ReplicatedStorage:WaitForChild("HelicopterRestart")

-- Get player references
local player = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local notificationFrame = nil

-- Create splash particles
local function CreateSplashParticles()
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local particleFolder = Instance.new("Folder")
	particleFolder.Name = "SplashParticles"
	particleFolder.Parent = workspace

	local particleCount = 20
	for i = 1, particleCount do
		local particle = Instance.new("Part")
		particle.Name = "Droplet"
		particle.Shape = Enum.PartType.Ball
		particle.Material = Enum.Material.Neon
		particle.Color = Color3.fromRGB(0, 100, 200)
		particle.Size = Vector3.new(0.3, 0.3, 0.3)
		particle.CanCollide = false
		particle.Anchored = false
		particle.CFrame = humanoidRootPart.CFrame + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
		particle.Parent = particleFolder

		local velocity = Vector3.new(
			math.random(-20, 20),
			math.random(5, 20),
			math.random(-20, 20)
		)

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = velocity
		bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
		bodyVelocity.Parent = particle

		task.spawn(function()
			local fadeStart = tick()
			while particle and particle.Parent do
				local elapsed = tick() - fadeStart
				if elapsed > SPLASH_DURATION then
					particle:Destroy()
					break
				end

				local alpha = 1 - (elapsed / SPLASH_DURATION)
				particle.Transparency = 1 - alpha
				task.wait(0.016)
			end
		end)
	end

	task.delay(SPLASH_DURATION + 0.1, function()
		if particleFolder and particleFolder.Parent then
			particleFolder:Destroy()
		end
	end)
end

-- Apply screen flash
local function ApplyScreenFlash()
	local overlay = Instance.new("Frame")
	overlay.Name = "WaterFlash"
	overlay.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
	overlay.BackgroundTransparency = 0.6
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.ZIndex = 999
	overlay.Parent = playerGui

	local tween = TweenService:Create(
		overlay,
		TweenInfo.new(SCREEN_FLASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)

	tween.Completed:Connect(function()
		overlay:Destroy()
	end)

	tween:Play()
end

-- Apply screen shake
local function ApplyScreenShake()
	local shakeStart = tick()
	local originalCFrame = camera.CFrame

	while tick() - shakeStart < CAMERA_SHAKE_DURATION do
		local elapsed = tick() - shakeStart
		local intensity = CAMERA_SHAKE_INTENSITY * (1 - (elapsed / CAMERA_SHAKE_DURATION))

		local shakeOffset = Vector3.new(
			(math.random() - 0.5) * intensity,
			(math.random() - 0.5) * intensity,
			(math.random() - 0.5) * intensity
		)

		camera.CFrame = originalCFrame * CFrame.new(shakeOffset)
		task.wait(0.016)
	end

	camera.CFrame = originalCFrame
end

-- Create notification UI
local function CreateNotificationUI()
	if notificationFrame and notificationFrame.Parent then
		return notificationFrame
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WaterNotificationGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "Notification"
	notificationFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	notificationFrame.BackgroundTransparency = 0.1
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Size = UDim2.new(0, 400, 0, 100)
	notificationFrame.Position = UDim2.new(0.5, -200, 0.5, -50)
	notificationFrame.ZIndex = 100
	notificationFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notificationFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = notificationFrame

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Text = "You fell into the void!"
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 18
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Size = UDim2.new(1, -20, 0.5, -10)
	textLabel.Position = UDim2.new(0, 10, 0, 10)
	textLabel.TextWrapped = true
	textLabel.Parent = notificationFrame

	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name = "Progress"
	progressLabel.Text = "Respawning in 3 seconds..."
	progressLabel.Font = Enum.Font.Gotham
	progressLabel.TextSize = 14
	progressLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	progressLabel.BackgroundTransparency = 1
	progressLabel.BorderSizePixel = 0
	progressLabel.Size = UDim2.new(1, -20, 0.5, -10)
	progressLabel.Position = UDim2.new(0, 10, 0.5, 0)
	progressLabel.TextWrapped = true
	progressLabel.Parent = notificationFrame

	notificationFrame.TextLabel = textLabel
	notificationFrame.ProgressLabel = progressLabel

	return notificationFrame
end

-- Update notification
local function UpdateNotification(message)
	local frame = CreateNotificationUI()
	if frame and frame.Parent then
		frame.TextLabel.Text = message
		frame.ProgressLabel.Text = ""

		task.delay(2, function()
			if frame and frame.Parent then
				local tween = TweenService:Create(
					frame,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{BackgroundTransparency = 1}
				)
				tween.Completed:Connect(function()
					if frame and frame.Parent then
						frame.Parent:Destroy()
					end
				end)
				tween:Play()
			end
		end)
	end
end

-- Play splash sound
local function PlaySplashSound()
	local sound = Instance.new("Sound")
	sound.Name = "SplashSound"
	sound.Volume = 0.5
	sound.Pitch = 0.9 + (math.random() * 0.2)
	sound.SoundId = "rbxassetid://5986676015"
	sound.Parent = workspace

	sound:Play()

	task.delay(2, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Handle splash event
splashEvent.OnClientEvent:Connect(function()
	print("[WaterClient] Splash event received")

	CreateSplashParticles()
	ApplyScreenFlash()
	ApplyScreenShake()
	PlaySplashSound()
end)

-- Handle restart event
restartEvent.OnClientEvent:Connect(function(message)
	print("[WaterClient] Restart event: " .. message)
	UpdateNotification(message)
end)

print("[WaterClient] Initialized")

return WaterClient
