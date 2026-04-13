-- GameLoop.server.lua
-- Main game loop and round system
-- Manages game states: Lobby -> BuildPhase -> SurvivePhase -> RoundEnd -> repeat
-- Handles player spawning, respawning, wave management, and difficulty scaling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Load modules
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))

-- Remote events
local gameStateEvent = ReplicatedStorage:WaitForChild("GameStateChanged")
local playerDeathEvent = ReplicatedStorage:WaitForChild("PlayerDied")
local waveStartEvent = ReplicatedStorage:WaitForChild("WaveStarted")
local waveEndEvent = ReplicatedStorage:WaitForChild("WaveEnded")
local roundEndEvent = ReplicatedStorage:WaitForChild("RoundEnded")

-- Game state tracking
local currentPhase = GameState.Phase.LOBBY
local waveNumber = 0
local playersInGame = {}
local waveActive = false
local gameRunning = false

-- Configuration from GameConfig
local MIN_PLAYERS = 1
local LOBBY_COUNTDOWN = 10
local BUILD_TIME = GameConfig.Player.BUILD_TIME
local RESPAWN_TIME = GameConfig.Player.RESPAWN_TIME
local TIME_BETWEEN_WAVES = GameConfig.Waves.TIME_BETWEEN_WAVES
local BASE_FUEL = GameConfig.Helicopter.BASE_FUEL

local GameLoop = {}

-- Count alive players
local function CountAlivePlayers()
	local count = 0
	for _, player in pairs(Players:GetPlayers()) do
		if playersInGame[player] and playersInGame[player].isAlive then
			count = count + 1
		end
	end
	return count
end

-- Broadcast game state to all clients
local function BroadcastGameState(timeRemaining)
	local stateData = {
		phase = currentPhase,
		wave = waveNumber,
		timeRemaining = timeRemaining or 0,
		playersAlive = CountAlivePlayers(),
	}
	gameStateEvent:FireAllClients(stateData)
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

		-- BUILD PHASE
		GameLoop.RunBuildPhase()
		if not gameRunning then break end

		-- SURVIVE PHASE
		GameLoop.RunSurvivePhase()
		if not gameRunning then break end

		-- ROUND END
		GameLoop.RunRoundEndPhase()
		if not gameRunning then break end
	end
end

-- Lobby phase: wait for minimum players and countdown
function GameLoop.RunLobbyPhase()
	print("[GameLoop] Entering LOBBY phase")
	currentPhase = GameState.Phase.LOBBY
	waveNumber = 0
	playersInGame = {}
	GameState.SetPhase(currentPhase)
	GameState.SetWaveNumber(waveNumber)

	BroadcastGameState(LOBBY_COUNTDOWN)

	-- Wait for minimum players
	while #Players:GetPlayers() < MIN_PLAYERS do
		task.wait(1)
	end

	print("[GameLoop] Minimum players reached: " .. #Players:GetPlayers())

	-- Countdown before game starts
	local countdownTime = LOBBY_COUNTDOWN
	while countdownTime > 0 do
		countdownTime = countdownTime - 1
		BroadcastGameState(countdownTime)
		task.wait(1)

		if #Players:GetPlayers() < MIN_PLAYERS then
			print("[GameLoop] Players dropped below minimum, restarting lobby")
			return
		end
	end

	-- Initialize players for game
	for _, player in pairs(Players:GetPlayers()) do
		playersInGame[player] = {
			isAlive = true,
			helicopter = nil,
			wavesSurvived = 0,
			killsThisRound = 0,
		}
	end

	print("[GameLoop] Starting game with " .. #Players:GetPlayers() .. " players")
end

-- Build phase: players collect tools and build helicopters
function GameLoop.RunBuildPhase()
	print("[GameLoop] Entering BUILD PHASE")
	currentPhase = GameState.Phase.BUILD_PHASE
	GameState.SetPhase(currentPhase)

	local buildTimeRemaining = BUILD_TIME
	while buildTimeRemaining > 0 do
		buildTimeRemaining = buildTimeRemaining - 1
		BroadcastGameState(buildTimeRemaining)
		task.wait(1)
	end

	print("[GameLoop] Build phase complete")
end

-- Survive phase: brainrot waves attack, players survive
function GameLoop.RunSurvivePhase()
	print("[GameLoop] Entering SURVIVE PHASE")
	currentPhase = GameState.Phase.SURVIVE_PHASE
	waveNumber = 1
	GameState.SetPhase(currentPhase)
	GameState.SetWaveNumber(waveNumber)

	while true do
		local aliveCount = CountAlivePlayers()
		if aliveCount == 0 then
			print("[GameLoop] All players dead, ending survive phase")
			break
		end

		-- Run wave
		GameLoop.RunWave(waveNumber)

		-- Time between waves
		local waveWaitTime = TIME_BETWEEN_WAVES
		while waveWaitTime > 0 do
			waveWaitTime = waveWaitTime - 1
			BroadcastGameState(waveWaitTime)
			task.wait(1)
		end

		waveNumber = waveNumber + 1
		GameState.SetWaveNumber(waveNumber)

		if waveNumber > 20 then
			print("[GameLoop] Max waves reached")
			break
		end
	end

	print("[GameLoop] Survive phase complete at wave " .. waveNumber)
end

-- Run a single wave of brainrots
function GameLoop.RunWave(waveNum)
	print("[GameLoop] Starting wave " .. waveNum)
	waveActive = true

	waveStartEvent:FireAllClients(waveNum)
	BroadcastGameState()

	-- Calculate difficulty
	local brainrotCount = math.min(
		GameConfig.Waves.BRAINROTS_PER_WAVE_BASE + (GameConfig.Waves.BRAINROTS_PER_WAVE_INCREMENT * (waveNum - 1)),
		GameConfig.Waves.MAX_BRAINROTS
	)

	print("[GameLoop] Spawning " .. brainrotCount .. " brainrots for wave " .. waveNum)

	-- Wave duration (simplified)
	local waveTimeout = 60
	task.wait(waveTimeout)

	waveActive = false
	waveEndEvent:FireAllClients(waveNum)

	-- Update player stats
	for _, player in pairs(Players:GetPlayers()) do
		if playersInGame[player] and playersInGame[player].isAlive then
			playersInGame[player].wavesSurvived = playersInGame[player].wavesSurvived + 1
		end
	end

	print("[GameLoop] Wave " .. waveNum .. " complete")
end

-- Round end phase: show results
function GameLoop.RunRoundEndPhase()
	print("[GameLoop] Entering ROUND END phase")
	currentPhase = GameState.Phase.ROUND_END
	GameState.SetPhase(currentPhase)

	local roundResults = {
		finalWave = waveNumber,
		playerStats = {},
	}

	for _, player in pairs(Players:GetPlayers()) do
		if playersInGame[player] then
			table.insert(roundResults.playerStats, {
				playerName = player.Name,
				wavesSurvived = playersInGame[player].wavesSurvived,
				killsThisRound = playersInGame[player].killsThisRound,
			})
		end
	end

	roundEndEvent:FireAllClients(roundResults)
	task.wait(10)

	playersInGame = {}
	waveActive = false
end

-- Handle player joining
function GameLoop.OnPlayerAdded(player)
	print("[GameLoop] Player " .. player.Name .. " joined")

	if currentPhase == GameState.Phase.LOBBY or currentPhase == GameState.Phase.BUILD_PHASE then
		playersInGame[player] = {
			isAlive = true,
			helicopter = nil,
			wavesSurvived = 0,
			killsThisRound = 0,
		}
	elseif currentPhase == GameState.Phase.SURVIVE_PHASE then
		playersInGame[player] = {
			isAlive = false,
			helicopter = nil,
			wavesSurvived = 0,
			killsThisRound = 0,
		}
		task.delay(RESPAWN_TIME, function()
			GameLoop.RespawnPlayer(player)
		end)
	end
end

-- Handle player leaving
function GameLoop.OnPlayerRemoving(player)
	print("[GameLoop] Player " .. player.Name .. " left")
	playersInGame[player] = nil
end

-- Respawn a player
function GameLoop.RespawnPlayer(player)
	if not Players:FindFirstChild(player.Name) then
		return
	end

	print("[GameLoop] Respawning " .. player.Name)

	if playersInGame[player] then
		playersInGame[player].isAlive = true
	end

	playerDeathEvent:FireClient(player, false)
end

-- Handle player death
function GameLoop.HandlePlayerDeath(player)
	if not playersInGame[player] then
		return
	end

	print("[GameLoop] Player " .. player.Name .. " died")
	playersInGame[player].isAlive = false
	playerDeathEvent:FireAllClients(player.Name)

	if waveActive then
		task.delay(RESPAWN_TIME, function()
			GameLoop.RespawnPlayer(player)
		end)
	end
end

-- Get current phase
function GameLoop.GetCurrentPhase()
	return currentPhase
end

-- Get current wave
function GameLoop.GetCurrentWave()
	return waveNumber
end

-- Get player game state
function GameLoop.GetPlayerGameState(player)
	return playersInGame[player]
end

-- Shutdown
function GameLoop.Shutdown()
	print("[GameLoop] Shutting down...")
	gameRunning = false
end

-- Start when script runs
task.wait(2)
GameLoop.Initialize()

return GameLoop
