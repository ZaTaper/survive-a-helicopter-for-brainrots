-- WaterSystem.server.lua
-- Handles water fall detection, splash effects, and helicopter restart logic
-- When player falls below water height, they are respawned at base with helicopter restored

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local WaterSystem = {}

-- Water system settings
local WATER_HEIGHT = GameConfig.Map.WATER_HEIGHT
local RESPAWN_DELAY = 3
local CHECK_INTERVAL = 0.2

-- Remote events
local splashEvent = ReplicatedStorage:WaitForChild("WaterSplash")
local restartEvent = ReplicatedStorage:WaitForChild("HelicopterRestart")

-- Create the water visual
local function CreateWaterVisual()
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Shape = Enum.PartType.Block
	water.Material = Enum.Material.Neon
	water.Color = Color3.fromRGB(0, 100, 200)
	water.Transparency = 0.4
	water.CanCollide = false
	water.CFrame = CFrame.new(0, WATER_HEIGHT - 50, 0)
	water.Size = Vector3.new(2000, 100, 2000)
	water.TopSurface = Enum.SurfaceType.Smooth
	water.BottomSurface = Enum.SurfaceType.Smooth
	water.CastShadow = false
	water.Anchored = true
	water.Parent = Workspace

	return water
end

-- Get player's helicopter model
local function GetPlayerHelicopter(player)
	if not player or not player.Character then return nil end

	local character = player.Character
	local helicopterModel = nil

	if character:FindFirstChild("Body") then
		helicopterModel = character
	else
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj.Name == player.Name and obj ~= character and obj:FindFirstChild("Body") then
				helicopterModel = obj
				break
			end
		end
	end

	return helicopterModel
end

-- Get the player's base location
local function GetPlayerBaseLocation(player)
	if not player then return nil end

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj.Name == player.Name .. "_Base" and obj:IsA("Model") then
			local landingPad = obj:FindFirstChild("LandingPad") or obj:FindFirstChild("Base")
			if landingPad then
				return landingPad.Position + Vector3.new(0, 10, 0)
			end
			return Vector3.new(0, 50, 0)
		end
	end

	return Vector3.new(0, 50, 0)
end

-- Store helicopter configs for restart
local helicopterConfigs = {}

-- Save helicopter configuration
function WaterSystem.SaveHelicopterConfig(player, helicopter, engines, fuelCanisters, isStarterHelicopter)
	if not helicopter then return end

	helicopterConfigs[player.UserId] = {
		engines = engines or 1,
		fuelCanisters = fuelCanisters or 2,
		isStarterHelicopter = isStarterHelicopter or false,
		helicopterName = helicopter.Name,
	}
end

-- Get saved helicopter config
local function GetSavedHelicopterConfig(player)
	return helicopterConfigs[player.UserId]
end

-- Restart the helicopter
local function RestartHelicopter(player, helicopter)
	if not helicopter then return end

	local config = GetSavedHelicopterConfig(player)
	if not config then
		config = {
			engines = 1,
			fuelCanisters = 2,
			isStarterHelicopter = true,
		}
	end

	local baseLocation = GetPlayerBaseLocation(player)

	local body = helicopter:FindFirstChild("Body")
	if body then
		helicopter:MoveTo(baseLocation)
	else
		if helicopter.PrimaryPart then
			helicopter:SetPrimaryPartCFrame(CFrame.new(baseLocation))
		end
	end

	helicopter:SetAttribute("Engines", config.engines)
	helicopter:SetAttribute("FuelCanisters", config.fuelCanisters)

	local maxFuel = GameConfig.Helicopter.BASE_FUEL + (GameConfig.Helicopter.FUEL_PER_CANISTER * config.fuelCanisters)
	helicopter:SetAttribute("CurrentFuel", maxFuel)

	if body then
		local bodyVelocity = body:FindFirstChildOfClass("BodyVelocity")
		if bodyVelocity then
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end
	end

	print("[WaterSystem] Restarted helicopter for " .. player.Name)
end

-- Restore player to base
local function RestorePlayerToBase(player)
	if not player or not player.Character then return end

	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart then
		local baseLocation = GetPlayerBaseLocation(player)
		humanoidRootPart.CFrame = CFrame.new(baseLocation + Vector3.new(0, 5, 0))
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end

	print("[WaterSystem] Restored player " .. player.Name .. " to base")
end

-- Handle water touch
function WaterSystem.OnPlayerTouchWater(player, hitPart)
	if not player or not player.Parent then return end

	splashEvent:FireClient(player)
	restartEvent:FireClient(player, "You fell into the water!")

	print("[WaterSystem] Player " .. player.Name .. " fell into water")

	task.wait(RESPAWN_DELAY)

	if player and player.Parent then
		RestorePlayerToBase(player)

		local helicopter = GetPlayerHelicopter(player)
		if helicopter then
			RestartHelicopter(player, helicopter)
		end

		restartEvent:FireClient(player, "Restarted! Good luck!")
	end
end

-- Monitor water height continuously
local function StartWaterHeightMonitor()
	while true do
		task.wait(CHECK_INTERVAL)

		local players = Players:GetPlayers()
		for _, player in ipairs(players) do
			if player.Character then
				local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart and humanoidRootPart.Position.Y < WATER_HEIGHT then
					if player:GetAttribute("FallingInWater") ~= true then
						player:SetAttribute("FallingInWater", true)
						task.spawn(function()
							WaterSystem.OnPlayerTouchWater(player, humanoidRootPart)
							task.wait(RESPAWN_DELAY + 2)
							player:SetAttribute("FallingInWater", false)
						end)
					end
				end
			end
		end
	end
end

-- Initialize
function WaterSystem.Initialize()
	print("[WaterSystem] Initializing water system at height " .. WATER_HEIGHT)

	CreateWaterVisual()
	task.spawn(StartWaterHeightMonitor)

	Players.PlayerRemoving:Connect(function(player)
		helicopterConfigs[player.UserId] = nil
	end)

	print("[WaterSystem] Initialized")
end

WaterSystem.Initialize()

return WaterSystem
