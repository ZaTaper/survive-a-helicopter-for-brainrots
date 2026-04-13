-- WaterSystem.server.lua
-- Handles void fall detection and player respawn logic
-- When player falls below Y=100 (the void threshold), they are teleported back to spawn hub

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local WaterSystem = {}

-- Void fall system settings
local VOID_HEIGHT = 100  -- Threshold Y position for falling into the void
local SPAWN_HUB_POSITION = Vector3.new(0, 205, 0)  -- MAP_CENTER + 5 up
local RESPAWN_DELAY = 3
local CHECK_INTERVAL = 0.2

-- Remote events
local restartEvent = ReplicatedStorage:WaitForChild("HelicopterRestart")


-- Teleport player to spawn hub and restore health
local function TeleportToSpawnHub(player)
	if not player or not player.Character then return end

	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart then
		humanoidRootPart.CFrame = CFrame.new(SPAWN_HUB_POSITION)
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end

	print("[WaterSystem] Teleported player " .. player.Name .. " to spawn hub")
end

-- Handle void fall
local function OnPlayerFallIntoVoid(player, hitPart)
	if not player or not player.Parent then return end

	restartEvent:FireClient(player, "You fell into the void!")

	print("[WaterSystem] Player " .. player.Name .. " fell into the void")

	task.wait(RESPAWN_DELAY)

	if player and player.Parent then
		TeleportToSpawnHub(player)
		restartEvent:FireClient(player, "Restarted! Good luck!")
	end
end

-- Monitor void height continuously
local function StartVoidHeightMonitor()
	while true do
		task.wait(CHECK_INTERVAL)

		local players = Players:GetPlayers()
		for _, player in ipairs(players) do
			if player.Character then
				local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart and humanoidRootPart.Position.Y < VOID_HEIGHT then
					if player:GetAttribute("FallingInWater") ~= true then
						player:SetAttribute("FallingInWater", true)
						task.spawn(function()
							OnPlayerFallIntoVoid(player, humanoidRootPart)
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
local function Initialize()
	print("[WaterSystem] Initializing void fall system at height " .. VOID_HEIGHT)

	task.spawn(StartVoidHeightMonitor)

	print("[WaterSystem] Initialized")
end

Initialize()

return WaterSystem
