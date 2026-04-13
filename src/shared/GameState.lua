-- GameState.lua
-- Shared game state enumeration and utilities
-- Defines game phases and provides helper functions for state checks

local GameState = {}

-- Game phase enumeration
GameState.Phase = {
	LOBBY = "Lobby",           -- Waiting for players to join
	BUILD_PHASE = "BuildPhase", -- Players build helicopters and collect tools
	SURVIVE_PHASE = "SurvivePhase", -- Brainrot waves attack players
	ROUND_END = "RoundEnd",    -- Round ended, showing results
}

-- Current game state (in-memory, server-side only)
local currentPhase = GameState.Phase.LOBBY
local waveNumber = 0
local timeRemaining = 0
local playersAlive = 0
local alivePlayersList = {}

-- Check if game is in lobby phase
-- @return boolean
function GameState.IsLobby()
	return currentPhase == GameState.Phase.LOBBY
end

-- Check if game is in build phase
-- @return boolean
function GameState.IsBuildPhase()
	return currentPhase == GameState.Phase.BUILD_PHASE
end

-- Check if game is in survive phase
-- @return boolean
function GameState.IsSurvivePhase()
	return currentPhase == GameState.Phase.SURVIVE_PHASE
end

-- Check if game is in round end phase
-- @return boolean
function GameState.IsRoundEnd()
	return currentPhase == GameState.Phase.ROUND_END
end

-- Check if game is currently active (not in lobby)
-- @return boolean
function GameState.IsActive()
	return currentPhase ~= GameState.Phase.LOBBY
end

-- Get the current phase
-- @return string
function GameState.GetPhase()
	return currentPhase
end

-- Get current wave number
-- @return number
function GameState.GetWaveNumber()
	return waveNumber
end

-- Get time remaining in current phase
-- @return number (seconds)
function GameState.GetTimeRemaining()
	return timeRemaining
end

-- Get number of players currently alive
-- @return number
function GameState.GetPlayersAlive()
	return playersAlive
end

-- Get list of alive players
-- @return table
function GameState.GetAlivePlayersList()
	return alivePlayersList
end

-- Set the current phase (server-side only)
-- @param phase string - One of GameState.Phase values
function GameState.SetPhase(phase)
	currentPhase = phase
end

-- Set wave number (server-side only)
-- @param wave number
function GameState.SetWaveNumber(wave)
	waveNumber = math.max(0, wave)
end

-- Set time remaining (server-side only)
-- @param time number (seconds)
function GameState.SetTimeRemaining(time)
	timeRemaining = math.max(0, time)
end

-- Set players alive count (server-side only)
-- @param count number
function GameState.SetPlayersAlive(count)
	playersAlive = math.max(0, count)
end

-- Set the list of alive players
-- @param players table - Array of player objects
function GameState.SetAlivePlayersList(players)
	alivePlayersList = players or {}
	playersAlive = #alivePlayersList
end

-- Get all current state as a table (for broadcasting to clients)
-- @return table
function GameState.GetStateSnapshot()
	return {
		phase = currentPhase,
		wave = waveNumber,
		timeRemaining = timeRemaining,
		playersAlive = playersAlive,
	}
end

return GameState
