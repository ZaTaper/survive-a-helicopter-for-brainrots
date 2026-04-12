-- GameLoop.server.lua
-- Main game loop and round system
-- Manages game states: Lobby → BuildPhase → SurvivePhase → RoundEnd → repeat
-- Handles player spawning, respawning, wave management, and difficulty scaling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Load modules
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerData"))
local InventorySystem = require(game.ServerScriptService:WaitForChild("InventorySystem"))
local ToolPickups = require(game.ServerScriptService:WaitForChild("ToolPickups"))
local SpawnManager = require(game.ServerScriptService:WaitForChild("SpawnManager"))

local GameLoop = {}

-- Game state tracking
local currentPhase = GameState.Phase.LOBBY
local waveNumber = 0
local playersInGame = {}  -- Format: { [player] = { helicopter = model, isAlive = bool, ... } }
local waveActive = false
local gameRunning = false

-- Configuration from GameConfig
local MIN_PLAYERS = 1  -- Minimum players to start game
local LOBBY_COUNTDOWN = 10  -- Seconds to wait in lobby before starting
local BUILD_TIME = GameConfig.Player.BUILD_TIME  -- Seconds for build phase
local RESPAWN_TIME = GameConfig.Player.RESPAWN_TIME  -- Seconds before respawn
local TIME_BETWEEN_WAVES = GameConfig.Waves.TIME_BETWEEN_WAVES  -- Seconds between waves
local BASE_FUEL = GameConfig.Helicopter.BASE_FUEL

-- RemoteEvents for client notifications
local gameStateEvent = Instance.new("RemoteEvent")
gameStateEvent.Name = "GameStateChanged"
gameStateEvent.Parent = ReplicatedStorage

local playerDeathEvent = Instance.new("RemoteEvent")
playerDeathEvent.Name = "PlayerDied"
playerDeathEvent.Parent = ReplicatedStorage

local waveStartEvent = Instance.new("RemoteEvent")
waveStartEvent.Name = "WaveStarted"
waveStartEvent.Parent = ReplicatedStorage

local waveEndEvent = Instance.new("RemoteEvent")
waveEndEvent.Name = "WaveEnded"
waveEndEvent.Parent = ReplicatedStorage

local roundEndEvent = Instance.new("RemoteEvent")
roundEndEvent.Name = "RoundEnded"
roundEndEvent.Parent = ReplicatedStorage

-- Initialize game loop
function GameLoop.Initialize()
	print("[GameLoop] Initializing game loop system...")

	-- Initialize spawn manager
	SpawnManager.InitializeSpawnPoints()

	-- Initialize tool pickups
	ToolPickups.Initialize()

	-- Setup player connections
	Players.PlayerAdded:Connect(GameLoop.OnPlayerAdded)
	Players.PlayerRemoving:Connect(GameLoop.OnPlayerRemoving)

	-- Start main game loop
	GameLoop.Start()

	print("[GameLoop] Game loop initialized and started")
end

-- Main game loop
function GameLoop.Start()
	gameRunning = true

	while gameRunning do
		-- LOBBY PHASE
		GameLoop.RunLobbyPhase()

		if not gameRunning then break end

		-- BUILD PHASE
		GameLoop.RunBuildPhase()

		if not gameRunning then break end

		-- SURVIVE PHASE (can run multiple waves)
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
	ToolPickups.ClearAllPickups()

	GameLoop._BroadcastGameState()

	-- Wait for minimum players
	while #Players:GetPlayers() < MIN_PLAYERS do
		task.wait(1)
	end

	print("[GameLoop] Minimum players reached: " .. #Players:GetPlayers())

	-- Countdown before game starts
	local countdownTime = LOBBY_COUNTDOWN
	while countdownTime > 0 do
		countdownTime = countdownTime - 1
		GameLoop._BroadcastGameState(countdownTime)
		task.wait(1)

		-- Reset if players leave
		if #Players:GetPlayers() < MIN_PLAYERS then
			print("[GameLoop] Players dropped below minimum, restarting lobby")
			return GameLoop.RunLobbyPhase()
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
		InventorySystem.InitializePlayer(player, PlayerData.CreateNewPlayerData())
	end

	print("[GameLoop] Starting game with " .. #Players:GetPlayers() .. " players")
end

-- Build phase: players collect tools and build helicopters
function GameLoop.RunBuildPhase()
	print("[GameLoop] Entering BUILD PHASE")
	currentPhase = GameState.Phase.BUILD_PHASE

	-- Spawn initial pickups
	local engineCount = math.ceil(#Players:GetPlayers() * 2)  -- 2 engines per player avg
	local fuelCount = math.ceil(#Players:GetPlayers() * 1.5)  -- 1.5 fuel per player avg
	ToolPickups.SpawnInitialPickups(engineCount, fuelCount)

	-- Run build phase for set duration
	local buildTimeRemaining = BUILD_TIME
	while buildTimeRemaining > 0 do
		buildTimeRemaining = buildTimeRemaining - 1
		GameLoop._BroadcastGameState(buildTimeRemaining)
		task.wait(1)
	end

	print("[GameLoop] Build phase complete")
end

-- Survive phase: brainrot waves attack, players survive
function GameLoop.RunSurvivePhase()
	print("[GameLoop] Entering SURVIVE PHASE")
	currentPhase = GameState.Phase.SURVIVE_PHASE
	waveNumber = 1

	-- Clear pickups - no more tools during survive phase
	ToolPickups.ClearAllPickups()

	while true do
		-- Check if all players are dead
		local aliveCount = GameLoop._CountAlivePlayers()
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
			GameLoop._BroadcastGameState(waveWaitTime)
			task.wait(1)
		end

		-- Increase difficulty for next wave
		waveNumber = waveNumber + 1

		-- Optional: add a max wave limit
		if waveNumber > 20 then
			print("[GameLoop] Max waves reached")
			break
		end
	end

	print("[GameLoop] Survive phase complete at wave " .. waveNumber)
end

-- Run a single wave of brainrots
-- @param waveNum number - The wave number (affects difficulty)
function GameLoop.RunWave(waveNum)
	print("[GameLoop] Starting wave " .. waveNum)
	waveActive = true

	-- Fire wave start event
	waveStartEvent:FireAllClients(waveNum)
	GameLoop._BroadcastGameState()

	-- Calculate difficulty based on wave number
	local brainrotCount = math.min(
		GameConfig.Waves.BRAINROTS_PER_WAVE_BASE + (GameConfig.Waves.BRAINROTS_PER_WAVE_INCREMENT * (waveNum - 1)),
		GameConfig.Waves.MAX_BRAINROTS
	)

	print("[GameLoop] Spawning " .. brainrotCount .. " brainrots for wave " .. waveNum)

	-- Spawn brainrots gradually during wave
	for i = 1, brainrotCount do
		-- Get random player spawn point
		local spawnPos = SpawnManager.GetRandomBrainrotSpawnPoint()

		-- Here you would spawn a brainrot and track it
		-- For now, this is a placeholder - the actual brainrot spawning
		-- would be handled by a separate BrainrotSystem

		task.wait(0.3)  -- Spread out spawning
	end

	-- Wait for wave to end (all brainrots killed or wave timeout)
	-- This is simplified - in real implementation, you'd track spawned brainrots
	local waveTimeout = 120  -- 2 minutes per wave max
	local waveTimer = 0

	while waveTimer < waveTimeout do
		waveTimer = waveTimer + 1
		task.wait(1)

		-- Check if all brainrots in this wave are defeated
		-- This would be tracked by a brainrot system
		-- For now, we'll simulate a wave lasting 30-60 seconds
		if waveTimer > 60 then
			break
		end
	end

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

-- Round end phase: show results, cleanup
function GameLoop.RunRoundEndPhase()
	print("[GameLoop] Entering ROUND END phase")
	currentPhase = GameState.Phase.ROUND_END

	-- Calculate and broadcast round results
	local roundResults = GameLoop._CalculateRoundResults()
	roundEndEvent:FireAllClients(roundResults)

	-- Display results for 10 seconds
	task.wait(10)

	-- Cleanup for next round
	GameLoop._CleanupRound()
end

-- Handle player joining the game
-- @param player Player
function GameLoop.OnPlayerAdded(player)
	print("[GameLoop] Player " .. player.Name .. " joined")

	if currentPhase == GameState.Phase.LOBBY then
		-- Initialize for lobby
		playersInGame[player] = {
			isAlive = true,
			helicopter = nil,
			wavesSurvived = 0,
			killsThisRound = 0,
		}
	elseif currentPhase == GameState.Phase.BUILD_PHASE then
		-- Initialize mid-game
		playersInGame[player] = {
			isAlive = true,
			helicopter = nil,
			wavesSurvived = 0,
			killsThisRound = 0,
		}
		InventorySystem.InitializePlayer(player, PlayerData.CreateNewPlayerData())
	elseif currentPhase == GameState.Phase.SURVIVE_PHASE then
		-- Late join during survive phase - respawn after delay
		playersInGame[player] = {
			isAlive = false,
			helicopter = nil,
			wavesSurvived = 0,
			killsThisRound = 0,
		}
		InventorySystem.InitializePlayer(player, PlayerData.CreateNewPlayerData())

		-- Respawn after delay
		task.delay(RESPAWN_TIME, function()
			GameLoop.RespawnPlayer(player)
		end)
	end
end

-- Handle player leaving the game
-- @param player Player
function GameLoop.OnPlayerRemoving(player)
	print("[GameLoop] Player " .. player.Name .. " left")
	playersInGame[player] = nil
	ToolPickups.ClearAllPickups()  -- Could be more selective
end

-- Respawn a player with fresh fuel
-- @param player Player
function GameLoop.RespawnPlayer(player)
	if not Players:FindFirstChild(player.Name) then
		return  -- Player already left
	end

	print("[GameLoop] Respawning " .. player.Name)

	-- Reset fuel to base amount
	local inventory = InventorySystem.GetInventory(player)
	inventory.currentFuel = BASE_FUEL

	-- Set alive status
	if playersInGame[player] then
		playersInGame[player].isAlive = true
	end

	-- Spawn player at a spawn point
	local spawnPos = SpawnManager.GetRandomPlayerSpawnPoint()
	if spawnPos then
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.CFrame = CFrame.new(spawnPos)
		end
	end

	-- Notify client
	playerDeathEvent:FireClient(player, false)  -- false = respawned, not dead
end

-- Handle player death
-- @param player Player
function GameLoop.HandlePlayerDeath(player)
	if not playersInGame[player] then
		return
	end

	print("[GameLoop] Player " .. player.Name .. " died")

	playersInGame[player].isAlive = false

	-- Notify clients
	playerDeathEvent:FireAllClients(player.Name)

	-- Schedule respawn
	if waveActive then
		task.delay(RESPAWN_TIME, function()
			GameLoop.RespawnPlayer(player)
		end)
	end
end

-- Count alive players
-- @return number
function GameLoop._CountAlivePlayers()
	local count = 0
	for _, player in pairs(Players:GetPlayers()) do
		if playersInGame[player] and playersInGame[player].isAlive then
			count = count + 1
		end
	end
	return count
end

-- Broadcast current game state to all clients
-- @param timeRemaining number - Optional time remaining in phase
function GameLoop._BroadcastGameState(timeRemaining)
	local stateData = {
		phase = currentPhase,
		wave = waveNumber,
		timeRemaining = timeRemaining or 0,
		playersAlive = GameLoop._CountAlivePlayers(),
	}

	gameStateEvent:FireAllClients(stateData)
end

-- Calculate round results
-- @return table - Results data
function GameLoop._CalculateRoundResults()
	local results = {
		finalWave = waveNumber,
		playerStats = {},
	}

	for _, player in pairs(Players:GetPlayers()) do
		if playersInGame[player] then
			table.insert(results.playerStats, {
				playerName = player.Name,
				wavesSurvived = playersInGame[player].wavesSurvived,
				killsThisRound = playersInGame[player].killsThisRound,
			})
		end
	end

	return results
end

-- Cleanup after round ends
function GameLoop._CleanupRound()
	print("[GameLoop] Cleaning up round...")

	-- Destroy all brainrots
	local brainrotFolder = workspace:FindFirstChild("Brainrots")
	if brainrotFolder then
		brainrotFolder:Destroy()
	end

	-- Clear pickups
	ToolPickups.ClearAllPickups()

	-- Reset player states
	playersInGame = {}
	waveActive = false
end

-- Shutdown the game loop
function GameLoop.Shutdown()
	print("[GameLoop] Shutting down...")
	gameRunning = false
end

-- Public API for getting player game state
-- @param player Player
-- @return table
function GameLoop.GetPlayerGameState(player)
	return playersInGame[player]
end

-- Public API for getting current phase
-- @return string
function GameLoop.GetCurrentPhase()
	return currentPhase
end

-- Public API for getting current wave
-- @return number
function GameLoop.GetCurrentWave()
	return waveNumber
end

-- Start the game loop when this script runs
task.wait(2)  -- Wait for other systems to load
GameLoop.Initialize()

return GameLoop
