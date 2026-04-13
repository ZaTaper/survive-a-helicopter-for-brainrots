-- GameState.lua
-- Shared game state enumeration and utilities
-- Open-world collection game - no waves or rounds

local GameState = {}

-- Game phase enumeration (simplified for open-world)
GameState.Phase = {
	LOBBY = "Lobby",           -- Waiting for players to join
	PLAYING = "Playing",       -- Open world - fly, collect, upgrade
	BUILD_PHASE = "BuildPhase", -- Legacy compatibility
	SURVIVE_PHASE = "SurvivePhase", -- Legacy compatibility
	ROUND_END = "RoundEnd",    -- Legacy compatibility
}

-- Current game state (in-memory, server-side only)
local currentPhase = GameState.Phase.LOBBY
local waveNumber = 0
local timeRemaining = 0
local playersAlive = 0
local alivePlayersList = {}

-- Check if game is in lobby phase
function GameState.IsLobby()
	return currentPhase == GameState.Phase.LOBBY
end

-- Check if game is in playing (open world) phase
function GameState.IsPlaying()
	return currentPhase == GameState.Phase.PLAYING
end

-- Legacy compatibility
function GameState.IsBuildPhase()
	return currentPhase == GameState.Phase.BUILD_PHASE or currentPhase == GameState.Phase.PLAYING
end

function GameState.IsSurvivePhase()
	return currentPhase == GameState.Phase.SURVIVE_PHASE or currentPhase == GameState.Phase.PLAYING
end

function GameState.IsRoundEnd()
	return currentPhase == GameState.Phase.ROUND_END
end

-- Check if game is currently active (not in lobby)
function GameState.IsActive()
	return currentPhase ~= GameState.Phase.LOBBY
end

-- Get the current phase
function GameState.GetPhase()
	return currentPhase
end

-- Get current wave number (legacy, always 0 in open world)
function GameState.GetWaveNumber()
	return waveNumber
end

-- Get time remaining in current phase
function GameState.GetTimeRemaining()
	return timeRemaining
end

-- Get number of players currently alive
function GameState.GetPlayersAlive()
	return playersAlive
end

-- Get list of alive players
function GameState.GetAlivePlayersList()
	return alivePlayersList
end

-- Set the current phase (server-side only)
function GameState.SetPhase(phase)
	currentPhase = phase
end

-- Set wave number (server-side only, legacy)
function GameState.SetWaveNumber(wave)
	waveNumber = math.max(0, wave)
end

-- Set time remaining (server-side only)
function GameState.SetTimeRemaining(time)
	timeRemaining = math.max(0, time)
end

-- Set players alive count (server-side only)
function GameState.SetPlayersAlive(count)
	playersAlive = math.max(0, count)
end

-- Set the list of alive players
function GameState.SetAlivePlayersList(players)
	alivePlayersList = players or {}
	playersAlive = #alivePlayersList
end

-- Get all current state as a table (for broadcasting to clients)
function GameState.GetStateSnapshot()
	return {
		phase = currentPhase,
		wave = waveNumber,
		timeRemaining = timeRemaining,
		playersAlive = playersAlive,
	}
end

return GameState
