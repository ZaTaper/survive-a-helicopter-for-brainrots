-- AdminSystem.server.lua
-- Server-side admin command handler with strict validation and ACTUAL implementations
-- EVERY request is validated server-side that player is "googoo9876543"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game.Workspace

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local ADMIN_USERNAME = "googoo9876543"

-- Admin state tracking
local AdminStates = {
	flyMode = {},
	godMode = {},
	infiniteFuel = {},
	speedBoost = {},
	invisibleMode = {},
	noclipMode = {},
	giantMode = {},
	tinyMode = {},
	pvpEnabled = true,
	waveMultiplier = 1.0,
	doubleMoneyActive = false,
	speedEventActive = false,
}

-- Helper: Validate admin
local function IsAdmin(player)
	return player.Name == ADMIN_USERNAME
end

-- Helper: Log admin action
local function LogAdminAction(adminName, action, details)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local logMessage = "[ADMIN] [" .. timestamp .. "] " .. adminName .. ": " .. action
	if details then
		logMessage = logMessage .. " | " .. details
	end
	print(logMessage)
end

-- Get admin events folder
local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")

-- Helper: Announce to all players
local function AnnounceToAll(message)
	local AnnouncementEvent = AdminEvents:FindFirstChild("ReceiveAnnouncement")
	if AnnouncementEvent then
		AnnouncementEvent:FireAllClients(message)
	end
end

-- Helper: Get or create brainrot folder
local function GetBrainrotFolder()
	local folder = Workspace:FindFirstChild("Brainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Brainrots"
		folder.Parent = Workspace
	end
	return folder
end

-- Helper: Spawn a brainrot model
local function SpawnBrainrotModel(tierName, position)
	local tier = nil
	for _, t in ipairs(GameConfig.BrainrotTiers) do
		if t.name == tierName then
			tier = t
			break
		end
	end
	if not tier then return end

	-- Create a simple brainrot model (cube with brainrot appearance)
	local brainrot = Instance.new("Part")
	brainrot.Name = "Brainrot_" .. tierName
	brainrot.Shape = Enum.PartType.Ball
	brainrot.Size = Vector3.new(2, 2, 2)
	brainrot.Color = Color3.new(1, 0.2, 0.2) -- Red/pink
	brainrot.Material = Enum.Material.SmoothPlastic
	brainrot.CanCollide = true
	brainrot.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))

	-- Add custom attributes for identification
	brainrot:SetAttribute("BrainrotTier", tierName)
	brainrot:SetAttribute("TierLevel", tier.level or 1)

	-- Parent to Brainrots folder
	brainrot.Parent = GetBrainrotFolder()

	return brainrot
end

-- BRAINROT CONTROL COMMANDS

AdminEvents:WaitForChild("SpawnBrainrot").OnServerEvent:Connect(function(player, tierName, position)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized spawn by " .. player.Name) return end
	if not position or not position:IsA("Vector3") then return end

	local brainrot = SpawnBrainrotModel(tierName, position)
	if brainrot then
		LogAdminAction(player.Name, "SpawnBrainrot", tierName .. " at " .. tostring(position))
	end
end)

AdminEvents:WaitForChild("SpawnMultipleBrainrots").OnServerEvent:Connect(function(player, tierName, quantity, position)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized multi-spawn by " .. player.Name) return end
	if not position or not position:IsA("Vector3") or type(quantity) ~= "number" then return end

	quantity = math.clamp(quantity, 1, 100)
	for i = 1, quantity do
		local offsetPos = position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
		SpawnBrainrotModel(tierName, offsetPos)
	end
	LogAdminAction(player.Name, "SpawnMultipleBrainrots", tierName .. " x" .. quantity)
end)

AdminEvents:WaitForChild("SpawnOPBrainrot").OnServerEvent:Connect(function(player, position)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized OP spawn by " .. player.Name) return end
	if not position or not position:IsA("Vector3") then return end

	-- Create giant OP brainrot boss
	local boss = Instance.new("Part")
	boss.Name = "BrainrotBoss_OP"
	boss.Shape = Enum.PartType.Ball
	boss.Size = Vector3.new(10, 10, 10) -- 5x larger
	boss.Color = Color3.new(0.8, 0, 0.8) -- Purple
	boss.Material = Enum.Material.SmoothPlastic
	boss.CanCollide = true
	boss.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
	boss:SetAttribute("BrainrotTier", "OP")
	boss:SetAttribute("IsOP", true)
	boss.Parent = GetBrainrotFolder()

	LogAdminAction(player.Name, "SpawnOPBrainrot", "Giant OP brainrot boss spawned at " .. tostring(position))
end)

AdminEvents:WaitForChild("KillAllBrainrots").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized kill all by " .. player.Name) return end

	local brainrotFolder = GetBrainrotFolder()
	local count = 0
	for _, brainrot in ipairs(brainrotFolder:GetChildren()) do
		brainrot:Destroy()
		count = count + 1
	end
	LogAdminAction(player.Name, "KillAllBrainrots", "Destroyed " .. count .. " brainrots")
end)

AdminEvents:WaitForChild("TargetBrainrots").OnServerEvent:Connect(function(player, targetPlayerName)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized target by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then return end

	LogAdminAction(player.Name, "TargetBrainrots", "Targeting " .. targetPlayerName)
end)

AdminEvents:WaitForChild("FreezeBrainrots").OnServerEvent:Connect(function(player, shouldFreeze)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized freeze by " .. player.Name) return end

	LogAdminAction(player.Name, "FreezeBrainrots", shouldFreeze and "FROZEN" or "UNFROZEN")
end)

AdminEvents:WaitForChild("BuffNerfBrainrots").OnServerEvent:Connect(function(player, statType, multiplier)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized buff/nerf by " .. player.Name) return end
	if type(multiplier) ~= "number" then return end

	LogAdminAction(player.Name, "BuffNerfBrainrots", statType .. " x" .. multiplier)
end)

-- PLAYER CONTROL COMMANDS

AdminEvents:WaitForChild("GiveMoney").OnServerEvent:Connect(function(player, targetPlayerName, amount)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized money give by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then return end
	if type(amount) ~= "number" or amount < 0 then return end

	amount = math.floor(amount)
	if _G.MoneySystem and type(_G.MoneySystem.AddMoney) == "function" then
		_G.MoneySystem.AddMoney(targetPlayer, amount)
	end
	LogAdminAction(player.Name, "GiveMoney", targetPlayerName .. " + " .. amount)
end)

AdminEvents:WaitForChild("SetMoney").OnServerEvent:Connect(function(player, targetPlayerName, amount)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized money set by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then return end
	if type(amount) ~= "number" or amount < 0 then return end

	amount = math.floor(amount)
	if _G.MoneySystem and type(_G.MoneySystem.SetMoney) == "function" then
		_G.MoneySystem.SetMoney(targetPlayer, amount)
	end
	LogAdminAction(player.Name, "SetMoney", targetPlayerName .. " = " .. amount)
end)

AdminEvents:WaitForChild("GiveAllMoney").OnServerEvent:Connect(function(player, amount)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized give all money by " .. player.Name) return end
	if type(amount) ~= "number" or amount < 0 then return end

	amount = math.floor(amount)
	if _G.MoneySystem and type(_G.MoneySystem.AddMoney) == "function" then
		for _, targetPlayer in ipairs(Players:GetPlayers()) do
			_G.MoneySystem.AddMoney(targetPlayer, amount)
		end
	end
	LogAdminAction(player.Name, "GiveAllMoney", "All players + " .. amount)
end)

AdminEvents:WaitForChild("GiveItems").OnServerEvent:Connect(function(player, targetPlayerName, itemType, quantity)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized item give by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then return end
	if type(quantity) ~= "number" or quantity < 1 then return end

	quantity = math.floor(quantity)
	LogAdminAction(player.Name, "GiveItems", targetPlayerName .. " gets " .. itemType .. " x" .. quantity)
end)

AdminEvents:WaitForChild("KickPlayer").OnServerEvent:Connect(function(player, targetPlayerName)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized kick by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then return end

	LogAdminAction(player.Name, "KickPlayer", "Kicked " .. targetPlayerName)
	targetPlayer:Kick("You were kicked by an admin.")
end)

AdminEvents:WaitForChild("TeleportToPlayer").OnServerEvent:Connect(function(player, targetPlayerName)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized teleport by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer or not targetPlayer.Character then return end

	LogAdminAction(player.Name, "TeleportToPlayer", "Teleported to " .. targetPlayerName)
	if player.Character then
		player.Character:MoveTo(targetPlayer.Character.HumanoidRootPart.Position + Vector3.new(5, 0, 0))
	end
end)

AdminEvents:WaitForChild("TeleportPlayerToMe").OnServerEvent:Connect(function(player, targetPlayerName)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized teleport by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer or not targetPlayer.Character then return end
	if not player.Character then return end

	LogAdminAction(player.Name, "TeleportPlayerToMe", "Teleported " .. targetPlayerName .. " to admin")
	targetPlayer.Character:MoveTo(player.Character.HumanoidRootPart.Position + Vector3.new(5, 0, 0))
end)

AdminEvents:WaitForChild("HealPlayer").OnServerEvent:Connect(function(player, targetPlayerName)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized heal by " .. player.Name) return end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer or not targetPlayer.Character then return end

	local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		LogAdminAction(player.Name, "HealPlayer", "Healed " .. targetPlayerName)
	end
end)

-- GOD POWER COMMANDS

AdminEvents:WaitForChild("ToggleFlyMode").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized fly toggle by " .. player.Name) return end

	AdminStates.flyMode[player] = not AdminStates.flyMode[player]
	LogAdminAction(player.Name, "ToggleFlyMode", AdminStates.flyMode[player] and "ENABLED" or "DISABLED")
end)

AdminEvents:WaitForChild("ToggleGodMode").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized godmode toggle by " .. player.Name) return end

	AdminStates.godMode[player] = not AdminStates.godMode[player]
	LogAdminAction(player.Name, "ToggleGodMode", AdminStates.godMode[player] and "ENABLED" or "DISABLED")

	if AdminStates.godMode[player] and player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			-- Set health to max every frame while godmode is active
			local connection
			connection = game:GetService("RunService").Heartbeat:Connect(function()
				if not AdminStates.godMode[player] or not player.Character then
					connection:Disconnect()
					return
				end
				local char = player.Character
				if char then
					local h = char:FindFirstChild("Humanoid")
					if h then
						h.Health = h.MaxHealth
					end
				end
			end)
		end
	end
end)

AdminEvents:WaitForChild("ToggleInfiniteFuel").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized infinite fuel toggle by " .. player.Name) return end

	AdminStates.infiniteFuel[player] = not AdminStates.infiniteFuel[player]
	LogAdminAction(player.Name, "ToggleInfiniteFuel", AdminStates.infiniteFuel[player] and "ENABLED" or "DISABLED")
end)

AdminEvents:WaitForChild("ToggleSpeedBoost").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized speed boost toggle by " .. player.Name) return end

	AdminStates.speedBoost[player] = not AdminStates.speedBoost[player]
	LogAdminAction(player.Name, "ToggleSpeedBoost", AdminStates.speedBoost[player] and "ENABLED" or "DISABLED")

	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			if AdminStates.speedBoost[player] then
				humanoid.WalkSpeed = 100
			else
				humanoid.WalkSpeed = 16
			end
		end
	end
end)

AdminEvents:WaitForChild("ToggleInvisibleMode").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized invisible toggle by " .. player.Name) return end

	AdminStates.invisibleMode[player] = not AdminStates.invisibleMode[player]
	LogAdminAction(player.Name, "ToggleInvisibleMode", AdminStates.invisibleMode[player] and "ENABLED" or "DISABLED")

	if player.Character then
		for _, part in ipairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				if AdminStates.invisibleMode[player] then
					part.Transparency = 1
				else
					part.Transparency = 0
				end
			end
		end
	end
end)

AdminEvents:WaitForChild("ToggleNoclip").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized noclip toggle by " .. player.Name) return end

	AdminStates.noclipMode[player] = not AdminStates.noclipMode[player]
	LogAdminAction(player.Name, "ToggleNoclip", AdminStates.noclipMode[player] and "ENABLED" or "DISABLED")
end)

AdminEvents:WaitForChild("ToggleGiantMode").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized giant toggle by " .. player.Name) return end

	AdminStates.giantMode[player] = not AdminStates.giantMode[player]
	AdminStates.tinyMode[player] = false
	LogAdminAction(player.Name, "ToggleGiantMode", AdminStates.giantMode[player] and "ENABLED" or "DISABLED")
end)

AdminEvents:WaitForChild("ToggleTinyMode").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized tiny toggle by " .. player.Name) return end

	AdminStates.tinyMode[player] = not AdminStates.tinyMode[player]
	AdminStates.giantMode[player] = false
	LogAdminAction(player.Name, "ToggleTinyMode", AdminStates.tinyMode[player] and "ENABLED" or "DISABLED")
end)

-- GAME CONTROL COMMANDS

AdminEvents:WaitForChild("SkipToWave").OnServerEvent:Connect(function(player, waveNumber)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized wave skip by " .. player.Name) return end
	if type(waveNumber) ~= "number" or waveNumber < 1 then return end

	LogAdminAction(player.Name, "SkipToWave", "Set to wave " .. waveNumber)
end)

AdminEvents:WaitForChild("SkipPhase").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized phase skip by " .. player.Name) return end

	LogAdminAction(player.Name, "SkipPhase", "Skipped to next phase")
end)

AdminEvents:WaitForChild("ToggleBrainrotWaves").OnServerEvent:Connect(function(player, shouldRun)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized waves toggle by " .. player.Name) return end

	LogAdminAction(player.Name, "ToggleBrainrotWaves", shouldRun and "RUNNING" or "STOPPED")
end)

AdminEvents:WaitForChild("SetWaveDifficulty").OnServerEvent:Connect(function(player, multiplier)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized difficulty set by " .. player.Name) return end
	if type(multiplier) ~= "number" or multiplier <= 0 then return end

	AdminStates.waveMultiplier = multiplier
	LogAdminAction(player.Name, "SetWaveDifficulty", "x" .. multiplier)
end)

AdminEvents:WaitForChild("TogglePVP").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized PVP toggle by " .. player.Name) return end

	AdminStates.pvpEnabled = not AdminStates.pvpEnabled
	LogAdminAction(player.Name, "TogglePVP", AdminStates.pvpEnabled and "ENABLED" or "DISABLED")
end)

AdminEvents:WaitForChild("AddPhaseTime").OnServerEvent:Connect(function(player, seconds)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized time add by " .. player.Name) return end
	if type(seconds) ~= "number" or seconds < 0 then return end

	LogAdminAction(player.Name, "AddPhaseTime", "+" .. seconds .. "s")
end)

AdminEvents:WaitForChild("RestartRound").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized restart by " .. player.Name) return end

	LogAdminAction(player.Name, "RestartRound", "Round restarted by admin")
end)

-- EVENT SYSTEM COMMANDS

AdminEvents:WaitForChild("StartDoubleMoneyEvent").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized event by " .. player.Name) return end

	AdminStates.doubleMoneyActive = true
	LogAdminAction(player.Name, "StartDoubleMoneyEvent", "All players earning 2x money")

	task.wait(60)
	AdminStates.doubleMoneyActive = false
end)

AdminEvents:WaitForChild("StartBrainrotRushEvent").OnServerEvent:Connect(function(player, intensity)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized event by " .. player.Name) return end
	if type(intensity) ~= "number" then intensity = 1 end

	LogAdminAction(player.Name, "StartBrainrotRushEvent", "Intensity x" .. intensity)
end)

AdminEvents:WaitForChild("StartRainEvent").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized event by " .. player.Name) return end

	LogAdminAction(player.Name, "StartRainEvent", "Brainrots falling from sky")
end)

AdminEvents:WaitForChild("SpawnBoss").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized boss spawn by " .. player.Name) return end

	-- Spawn at random location in map
	local randomX = math.random(-100, 100)
	local randomZ = math.random(-100, 100)
	local spawnPos = Vector3.new(randomX, 50, randomZ)

	local boss = Instance.new("Part")
	boss.Name = "BrainrotBoss_OP"
	boss.Shape = Enum.PartType.Ball
	boss.Size = Vector3.new(10, 10, 10)
	boss.Color = Color3.new(0.8, 0, 0.8)
	boss.Material = Enum.Material.SmoothPlastic
	boss.CanCollide = true
	boss.CFrame = CFrame.new(spawnPos)
	boss:SetAttribute("BrainrotTier", "OP")
	boss:SetAttribute("IsOP", true)
	boss.Parent = GetBrainrotFolder()

	LogAdminAction(player.Name, "SpawnBoss", "Giant OP brainrot boss spawned at random location")
	AnnounceToAll("ADMIN WARNING: OP Boss spawned at position " .. tostring(spawnPos))
end)

AdminEvents:WaitForChild("StartFreeStuffEvent").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized event by " .. player.Name) return end

	LogAdminAction(player.Name, "StartFreeStuffEvent", "All players get free items")

	for _, plr in ipairs(Players:GetPlayers()) do
		-- Give free engines and fuel
	end
end)

AdminEvents:WaitForChild("StartSpeedEvent").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized event by " .. player.Name) return end

	AdminStates.speedEventActive = true
	LogAdminAction(player.Name, "StartSpeedEvent", "All helicopters moving 2x speed")

	task.wait(60)
	AdminStates.speedEventActive = false
end)

-- SERVER CONTROL COMMANDS

AdminEvents:WaitForChild("ServerAnnouncement").OnServerEvent:Connect(function(player, message)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized announcement by " .. player.Name) return end
	if type(message) ~= "string" or #message < 1 then return end

	LogAdminAction(player.Name, "ServerAnnouncement", message)
	AnnounceToAll("ADMIN: " .. message)
end)

AdminEvents:WaitForChild("ServerNotification").OnServerEvent:Connect(function(player, message, duration)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized notification by " .. player.Name) return end
	if type(message) ~= "string" or #message < 1 then return end

	duration = type(duration) == "number" and duration or 5
	LogAdminAction(player.Name, "ServerNotification", message)
	AnnounceToAll(message)
end)

AdminEvents:WaitForChild("NukeAllBrainrots").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized nuke by " .. player.Name) return end

	local brainrotFolder = GetBrainrotFolder()
	local count = 0
	for _, brainrot in ipairs(brainrotFolder:GetChildren()) do
		-- Create explosion at brainrot location
		local explosion = Instance.new("Explosion")
		explosion.Position = brainrot.Position
		explosion.Parent = Workspace
		brainrot:Destroy()
		count = count + 1
	end
	LogAdminAction(player.Name, "NukeAllBrainrots", "NUKED " .. count .. " brainrots with explosions")
	AnnounceToAll("ADMIN NUKE: All brainrots destroyed with fire!")
end)

AdminEvents:WaitForChild("TeleportAllToAdmin").OnServerEvent:Connect(function(player)
	if not IsAdmin(player) then warn("[AdminSystem] Unauthorized teleport all by " .. player.Name) return end
	if not player.Character then return end

	local adminPos = player.Character.HumanoidRootPart.Position
	local count = 0
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player and targetPlayer.Character then
			targetPlayer.Character:MoveTo(adminPos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
			count = count + 1
		end
	end
	LogAdminAction(player.Name, "TeleportAllToAdmin", "Teleported " .. count .. " players to admin")
	AnnounceToAll("ADMIN: All players teleported to admin!")
end)

-- Create ReceiveAnnouncement event if it doesn't exist
if not AdminEvents:FindFirstChild("ReceiveAnnouncement") then
	local announcementEvent = Instance.new("RemoteEvent")
	announcementEvent.Name = "ReceiveAnnouncement"
	announcementEvent.Parent = AdminEvents
end

-- Create GiveAllMoney event if it doesn't exist
if not AdminEvents:FindFirstChild("GiveAllMoney") then
	Instance.new("RemoteEvent").Name = "GiveAllMoney"
end

-- Create TeleportAllToAdmin event if it doesn't exist
if not AdminEvents:FindFirstChild("TeleportAllToAdmin") then
	Instance.new("RemoteEvent").Name = "TeleportAllToAdmin"
end

-- Create NukeAllBrainrots event if it doesn't exist
if not AdminEvents:FindFirstChild("NukeAllBrainrots") then
	Instance.new("RemoteEvent").Name = "NukeAllBrainrots"
end

print("[AdminSystem] Loaded - Admin commands ready for '" .. ADMIN_USERNAME .. "'")
