--[[
	AdminSystem.server.lua
	Server-side admin command handler for "Survive a Helicopter for Brainrots"

	SECURITY:
	- Validates EVERY admin request to ensure only "googoo9876543" can execute commands
	- Never trusts client input - all permissions verified server-side
	- Logs all admin actions for audit purposes

	Admin Commands:
	- SpawnBrainrot(tierName, position)
	- KillAllBrainrots()
	- SetWave(waveNumber)
	- GiveTools(playerName, toolType, amount)
	- SkipPhase()
	- SetFuel(playerName, amount)
	- ToggleGodmode(playerName)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Admin configuration
local ADMIN_USERNAME = "googoo9876543"

-- Create RemoteFunction for authentication check
local AdminAuthCheck = Instance.new("RemoteFunction")
AdminAuthCheck.Name = "AdminAuthCheck"
AdminAuthCheck.Parent = ReplicatedStorage

-- Create RemoteEvent folder for admin commands
local AdminEvents = Instance.new("Folder")
AdminEvents.Name = "AdminEvents"
AdminEvents.Parent = ReplicatedStorage

-- Create individual RemoteEvents for each command
local SpawnBrainrotEvent = Instance.new("RemoteEvent")
SpawnBrainrotEvent.Name = "SpawnBrainrot"
SpawnBrainrotEvent.Parent = AdminEvents

local KillAllBraindrotsEvent = Instance.new("RemoteEvent")
KillAllBraindrotsEvent.Name = "KillAllBrainrots"
KillAllBraindrotsEvent.Parent = AdminEvents

local SetWaveEvent = Instance.new("RemoteEvent")
SetWaveEvent.Name = "SetWave"
SetWaveEvent.Parent = AdminEvents

local GiveToolsEvent = Instance.new("RemoteEvent")
GiveToolsEvent.Name = "GiveTools"
GiveToolsEvent.Parent = AdminEvents

local SkipPhaseEvent = Instance.new("RemoteEvent")
SkipPhaseEvent.Name = "SkipPhase"
SkipPhaseEvent.Parent = AdminEvents

local SetFuelEvent = Instance.new("RemoteEvent")
SetFuelEvent.Name = "SetFuel"
SetFuelEvent.Parent = AdminEvents

local ToggleGodmodeEvent = Instance.new("RemoteEvent")
ToggleGodmodeEvent.Name = "ToggleGodmode"
ToggleGodmodeEvent.Parent = AdminEvents

--[[
	Validates if a player is an admin
	@param player: Player object
	@return: boolean - true if player is admin
]]
local function IsAdmin(player)
	return player.Name == ADMIN_USERNAME
end

--[[
	Logs an admin action to output for audit purposes
	@param adminName: string - name of admin
	@param action: string - description of action taken
	@param details: string - optional additional details
]]
local function LogAdminAction(adminName, action, details)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local logMessage = string.format("[ADMIN LOG] [%s] %s: %s", timestamp, adminName, action)
	if details then
		logMessage = logMessage .. " | " .. details
	end
	print(logMessage)
end

--[[
	Admin authentication check - RemoteFunction callback
	Used by client to verify admin status
]]
function AdminAuthCheck:InvokeClient(player)
	return IsAdmin(player)
end

AdminAuthCheck.OnServerInvoke = function(player)
	-- Just return admin status, client should already handle this check
	return IsAdmin(player)
end

--[[
	SpawnBrainrot command - Spawns a brainrot at specified position
]]
SpawnBrainrotEvent.OnServerEvent:Connect(function(player, tierName, position)
	-- Security check
	if not IsAdmin(player) then
		warn("Unauthorized spawn attempt by " .. player.Name)
		return
	end

	-- Validate tier exists
	local tierData = nil
	for _, tier in ipairs(GameConfig.BrainrotTiers) do
		if tier.name == tierName then
			tierData = tier
			break
		end
	end

	if not tierData then
		warn("Invalid brainrot tier: " .. tierName)
		return
	end

	-- Validate position
	if not position or not position:IsA("Vector3") then
		warn("Invalid spawn position")
		return
	end

	-- TODO: Spawn brainrot logic here
	-- This would integrate with your BrainrotSpawner or similar system
	LogAdminAction(player.Name, "SpawnBrainrot",
		string.format("Tier: %s at position (%.1f, %.1f, %.1f)",
			tierName, position.X, position.Y, position.Z))

	-- Broadcast to clients that a brainrot should be spawned
	local BrainrotSpawnEvent = ReplicatedStorage:FindFirstChild("BrainrotSpawn")
	if BrainrotSpawnEvent then
		BrainrotSpawnEvent:FireAllClients(tierName, position)
	end
end)

--[[
	KillAllBrainrots command - Removes all brainrots from the map
]]
KillAllBraindrotsEvent.OnServerEvent:Connect(function(player)
	-- Security check
	if not IsAdmin(player) then
		warn("Unauthorized kill all attempt by " .. player.Name)
		return
	end

	-- TODO: Kill all brainrots logic here
	-- This would find and destroy all brainrot instances
	LogAdminAction(player.Name, "KillAllBrainrots", "Removed all brainrots from map")

	-- Broadcast to clients
	local KillAllEvent = ReplicatedStorage:FindFirstChild("KillAllBrainrots")
	if KillAllEvent then
		KillAllEvent:FireAllClients()
	end
end)

--[[
	SetWave command - Sets the current wave number
]]
SetWaveEvent.OnServerEvent:Connect(function(player, waveNumber)
	-- Security check
	if not IsAdmin(player) then
		warn("Unauthorized wave set by " .. player.Name)
		return
	end

	-- Validate wave number
	if type(waveNumber) ~= "number" or waveNumber < 1 then
		warn("Invalid wave number: " .. tostring(waveNumber))
		return
	end

	-- TODO: Set wave logic here
	LogAdminAction(player.Name, "SetWave", "Wave set to: " .. waveNumber)

	-- Broadcast to clients
	local SetWaveEvent = ReplicatedStorage:FindFirstChild("SetWaveValue")
	if SetWaveEvent then
		SetWaveEvent:FireAllClients(waveNumber)
	end
end)

--[[
	GiveTools command - Gives tools/items to a specified player
]]
GiveToolsEvent.OnServerEvent:Connect(function(player, targetPlayerName, toolType, amount)
	-- Security check
	if not IsAdmin(player) then
		warn("Unauthorized give tools by " .. player.Name)
		return
	end

	-- Find target player
	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		warn("Target player not found: " .. targetPlayerName)
		return
	end

	-- Validate tool type and amount
	if type(toolType) ~= "string" or type(amount) ~= "number" or amount < 1 then
		warn("Invalid tool type or amount")
		return
	end

	-- TODO: Give tools logic here
	LogAdminAction(player.Name, "GiveTools",
		string.format("Gave %s x%d to %s", toolType, amount, targetPlayerName))
end)

--[[
	SkipPhase command - Skips to the next game phase
]]
SkipPhaseEvent.OnServerEvent:Connect(function(player)
	-- Security check
	if not IsAdmin(player) then
		warn("Unauthorized phase skip by " .. player.Name)
		return
	end

	-- TODO: Skip phase logic here
	LogAdminAction(player.Name, "SkipPhase", "Skipped to next phase")

	-- Broadcast to clients
	local SkipEvent = ReplicatedStorage:FindFirstChild("SkipPhase")
	if SkipEvent then
		SkipEvent:FireAllClients()
	end
end)

--[[
	SetFuel command - Sets fuel amount for a player
]]
SetFuelEvent.OnServerEvent:Connect(function(player, targetPlayerName, fuelAmount)
	-- Security check
	if not IsAdmin(player) then
		warn("Unauthorized fuel set by " .. player.Name)
		return
	end

	-- Find target player
	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		warn("Target player not found: " .. targetPlayerName)
		return
	end

	-- Validate fuel amount
	if type(fuelAmount) ~= "number" or fuelAmount < 0 then
		warn("Invalid fuel amount: " .. tostring(fuelAmount))
		return
	end

	-- TODO: Set fuel logic here
	LogAdminAction(player.Name, "SetFuel",
		string.format("Set %s's fuel to: %d", targetPlayerName, fuelAmount))
end)

--[[
	ToggleGodmode command - Gives/removes godmode for a player
]]
ToggleGodmodeEvent.OnServerEvent:Connect(function(player, targetPlayerName)
	-- Security check
	if not IsAdmin(player) then
		warn("Unauthorized godmode toggle by " .. player.Name)
		return
	end

	-- Find target player
	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		warn("Target player not found: " .. targetPlayerName)
		return
	end

	-- TODO: Godmode toggle logic here
	LogAdminAction(player.Name, "ToggleGodmode",
		string.format("Toggled godmode for %s", targetPlayerName))

	-- Broadcast to clients
	local GodmodeEvent = ReplicatedStorage:FindFirstChild("ToggleGodmode")
	if GodmodeEvent then
		GodmodeEvent:FireAllClients(targetPlayerName)
	end
end)

print("AdminSystem loaded - Admin commands ready for " .. ADMIN_USERNAME)
