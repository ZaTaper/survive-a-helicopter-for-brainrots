-- TeleportSystem.server.lua
-- Handles teleport pads: stepping on a pad teleports you to its destination
-- Ground pad -> Sky showcase, Sky pad -> Back to ground

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local MAP_CENTER = Vector3.new(0, 50, 0)
local SKY_CENTER = MAP_CENTER + Vector3.new(0, 300, 0)

-- Debounce per player to prevent spamming
local teleportCooldowns = {}
local COOLDOWN_TIME = 2

local function TeleportPlayer(player, destination)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Check cooldown
	if teleportCooldowns[player.UserId] and (tick() - teleportCooldowns[player.UserId]) < COOLDOWN_TIME then
		return
	end
	teleportCooldowns[player.UserId] = tick()

	-- Teleport the player
	humanoidRootPart.CFrame = CFrame.new(destination + Vector3.new(0, 5, 0))
	print("[TeleportSystem] Teleported " .. player.Name .. " to " .. tostring(destination))
end

-- Wait for map to generate, then find teleport pads
local function SetupTeleportPads()
	-- Wait for the map structures to exist
	local gameMap = workspace:WaitForChild("GameMap", 30)
	if not gameMap then
		warn("[TeleportSystem] GameMap not found after 30 seconds!")
		return
	end

	local structures = gameMap:WaitForChild("Structures", 10)
	if not structures then
		warn("[TeleportSystem] Structures folder not found!")
		return
	end

	-- Search for teleport pad parts in structures (they are Parts named "TeleportPad_*")
	for _, child in ipairs(structures:GetChildren()) do
		if child:IsA("BasePart") and string.find(child.Name, "TeleportPad_") then
			local padName = child.Name

			if string.find(string.upper(padName), "SKY") or string.find(string.upper(padName), "COLLECTION") then
				-- Ground pad goes UP to sky showcase
				child.Touched:Connect(function(hit)
					local character = hit.Parent
					local player = Players:GetPlayerFromCharacter(character)
					if player then
						TeleportPlayer(player, SKY_CENTER + Vector3.new(0, 3, 0))
					end
				end)
				print("[TeleportSystem] Connected pad: " .. padName .. " -> Sky")

			elseif string.find(string.upper(padName), "RETURN") or string.find(string.upper(padName), "GROUND") then
				-- Sky pad goes DOWN to ground near hub
				child.Touched:Connect(function(hit)
					local character = hit.Parent
					local player = Players:GetPlayerFromCharacter(character)
					if player then
						TeleportPlayer(player, MAP_CENTER + Vector3.new(0, 5, 0))
					end
				end)
				print("[TeleportSystem] Connected pad: " .. padName .. " -> Ground")
			end
		end
	end
end

-- Clean up cooldowns when player leaves
Players.PlayerRemoving:Connect(function(player)
	teleportCooldowns[player.UserId] = nil
end)

-- Initialize
print("[TeleportSystem] Initializing teleport system...")
local success, err = pcall(SetupTeleportPads)
if not success then
	warn("[TeleportSystem] ERROR: " .. tostring(err))
else
	print("[TeleportSystem] Teleport system ready!")
end
