-- GameLoop.server.lua
-- Main game loop for open-world brainrot collection
-- Players join, get a base, build helicopters, collect brainrots, return for money
-- Game runs continuously with no rounds or waves

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))

-- Remote events
local gameStateChangedEvent = ReplicatedStorage:WaitForChild("GameStateChanged")
local gamePhaseChangedEvent = ReplicatedStorage:WaitForChild("GamePhaseChanged")
local playerDiedEvent = ReplicatedStorage:WaitForChild("PlayerDied")

-- Game state tracking
local currentPhase = GameState.Phase.LOBBY
local playersInGame = {}
local gameRunning = false
local brainrotSystemInitialized = false

-- Configuration
local MIN_PLAYERS = 1
local LOBBY_COUNTDOWN = 5
local STATE_UPDATE_INTERVAL = 5
local RESPAWN_TIME = GameConfig.Player.RESPAWN_TIME
local RESPAWN_POSITION = Vector3.new(0, GameConfig.Map.MAP_CENTER_Y + 5, 0)

local GameLoop = {}

-- Broadcast game state to all clients
local function BroadcastGameState()
	local stateData = {
		phase = currentPhase,
		timestamp = tick(),
	}
	gameStateChangedEvent:FireAllClients(stateData)
end

-- Broadcast phase change to all clients
local function BroadcastPhaseChange()
	local phaseData = {
		phase = currentPhase,
		timestamp = tick(),
	}
	gamePhaseChangedEvent:FireAllClients(phaseData)
	print("[GameLoop] Broadcasting phase change: " .. tostring(currentPhase))
end

-- Initialize BrainrotSystem with retry logic
local function InitializeBrainrotSystem()
	if brainrotSystemInitialized then
		return true
	end

	local retries = 0
	local maxRetries = 10

	while retries < maxRetries do
		local success = pcall(function()
			if _G.BrainrotSystem and _G.BrainrotSystem.Initialize then
				print("[GameLoop] Initializing BrainrotSystem...")
				_G.BrainrotSystem.Initialize()
				print("[GameLoop] BrainrotSystem initialized successfully")
				brainrotSystemInitialized = true
			else
				error("BrainrotSystem not available yet")
			end
		end)

		if success and brainrotSystemInitialized then
			return true
		end

		retries = retries + 1
		print("[GameLoop] BrainrotSystem initialization attempt " .. retries .. "/" .. maxRetries .. " failed, retrying...")
		task.wait(1)
	end

	print("[GameLoop] WARNING: BrainrotSystem failed to initialize after " .. maxRetries .. " attempts")
	return false
end

-- Initialize game loop
function GameLoop.Initialize()
	print("[GameLoop] Initializing...")
	Players.PlayerAdded:Connect(GameLoop.OnPlayerAdded)
	Players.PlayerRemoving:Connect(GameLoop.OnPlayerRemoving)
	GameLoop.Start()
	print("[GameLoop] Initialized")
end

-- Main game loop
function GameLoop.Start()
	gameRunning = true
	print("[GameLoop] Starting main loop...")

	while gameRunning do
		-- LOBBY PHASE
		GameLoop.RunLobbyPhase()
		if not gameRunning then break end

		-- PLAYING PHASE (continuous, no rounds)
		GameLoop.RunPlayingPhase()
		if not gameRunning then break end
	end
end

-- Lobby phase: wait for minimum players and countdown
function GameLoop.RunLobbyPhase()
	print("[GameLoop] Entering LOBBY phase")
	currentPhase = GameState.Phase.LOBBY
	GameState.SetPhase(currentPhase)
	BroadcastPhaseChange()

	-- Wait for minimum players
	while #Players:GetPlayers() < MIN_PLAYERS do
		task.wait(1)
	end

	print("[GameLoop] Minimum players reached: " .. #Players:GetPlayers())

	-- Countdown before game starts
	local countdownTime = LOBBY_COUNTDOWN
	while countdownTime > 0 do
		countdownTime = countdownTime - 1
		BroadcastGameState()
		task.wait(1)

		if #Players:GetPlayers() < MIN_PLAYERS then
			print("[GameLoop] Players dropped below minimum, restarting lobby")
			return
		end
	end

	print("[GameLoop] Starting game with " .. #Players:GetPlayers() .. " players")
end

-- Playing phase: open-world brainrot collection (continuous)
function GameLoop.RunPlayingPhase()
	print("[GameLoop] Entering PLAYING phase")
	currentPhase = GameState.Phase.PLAYING
	GameState.SetPhase(currentPhase)
	BroadcastPhaseChange()

	-- Initialize brainrots
	InitializeBrainrotSystem()

	-- Game runs forever in PLAYING phase
	local lastStateUpdate = tick()

	while gameRunning do
		-- Broadcast state updates every 5 seconds
		local currentTime = tick()
		if currentTime - lastStateUpdate >= STATE_UPDATE_INTERVAL then
			BroadcastGameState()
			lastStateUpdate = currentTime
		end

		task.wait(1)
	end
end

-- Handle player joining
function GameLoop.OnPlayerAdded(player)
	print("[GameLoop] Player " .. player.Name .. " joined")

	-- Track player
	playersInGame[player] = {
		joinedAt = tick(),
	}

	-- In PLAYING phase, BaseSystem will automatically give them a base
	-- When their character loads, they can start building and collecting brainrots

	-- Connect to character for death tracking
	if player.Character then
		GameLoop.OnCharacterLoaded(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		GameLoop.OnCharacterLoaded(player, character)
	end)
end

-- Handle character loaded
function GameLoop.OnCharacterLoaded(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Connect to death event
	humanoid.Died:Connect(function()
		GameLoop.HandlePlayerDeath(player)
	end)
end

-- Handle player leaving
function GameLoop.OnPlayerRemoving(player)
	print("[GameLoop] Player " .. player.Name .. " left")
	playersInGame[player] = nil
end

-- Handle player death
function GameLoop.HandlePlayerDeath(player)
	if not Players:FindFirstChild(player.Name) then
		return
	end

	print("[GameLoop] Player " .. player.Name .. " died")

	-- Broadcast death notification to all clients
	playerDiedEvent:FireAllClients(player.Name)

	-- Wait for respawn time
	task.wait(RESPAWN_TIME)

	-- Check player still exists
	if not Players:FindFirstChild(player.Name) then
		return
	end

	-- Respawn player at hub center
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart then
			-- Teleport to respawn position
			local success = pcall(function()
				rootPart.CFrame = CFrame.new(RESPAWN_POSITION)
				humanoid.Health = humanoid.MaxHealth
			end)

			if success then
				print("[GameLoop] Player " .. player.Name .. " respawned at hub")
			else
				print("[GameLoop] ERROR: Failed to respawn player " .. player.Name)
			end
		end
	end
end

-- Get current phase
function GameLoop.GetCurrentPhase()
	return currentPhase
end

-- Start when script runs
task.wait(2)
GameLoop.Initialize()

return GameLoop
