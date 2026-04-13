-- MusicData.lua
-- Shared music configuration for "Survive a Helicopter for Brainrots"
-- Stores all music tracks with Roblox asset IDs
-- Theme: Epic, intense background music for helicopter building and survival

local MusicData = {}

-- Default volume settings (0-1)
MusicData.DEFAULT_VOLUME = 0.5
MusicData.CROSSFADE_DURATION = 1.5  -- seconds for smooth transitions

-- Music track definitions
-- Each track has: assetId, name, volume (0-1), looping (boolean), fadeTime
MusicData.Tracks = {
	-- LOBBY/MENU: Calm ambient music
	Lobby = {
		assetId = "rbxassetid://1837849285",
		name = "Lobby Theme",
		volume = 0.5,
		looping = true,
		fadeTime = 1.5,
		phase = "Lobby",
	},

	-- BUILD PHASE: Upbeat construction vibes
	BuildPhase = {
		assetId = "rbxassetid://1839841326",
		name = "Build Time",
		volume = 0.6,
		looping = true,
		fadeTime = 1.5,
		phase = "BuildPhase",
	},

	-- SURVIVE PHASE: Intense action music for combat waves
	SurvivePhase = {
		assetId = "rbxassetid://1836350065",
		name = "Combat Mode",
		volume = 0.7,
		looping = true,
		fadeTime = 1.5,
		phase = "SurvivePhase",
	},

	-- BOSS WAVE: Epic boss battle music
	BossWave = {
		assetId = "rbxassetid://1838677299",
		name = "Boss Encounter",
		volume = 0.8,
		looping = true,
		fadeTime = 1.5,
		phase = "BossWave",
	},

	-- VICTORY: Triumphant celebration
	Victory = {
		assetId = "rbxassetid://1837121023",
		name = "Victory!",
		volume = 0.7,
		looping = true,
		fadeTime = 1.5,
		phase = "RoundEnd",
	},

	-- DEATH: Sad/dramatic sting
	Death = {
		assetId = "rbxassetid://1837024835",
		name = "Game Over",
		volume = 0.7,
		looping = false,
		fadeTime = 0.5,
		phase = "Death",
	},
}

-- Get a track by key name
-- @param trackKey string - The key of the track (e.g., "Lobby", "BuildPhase")
-- @return table - Track data or nil if not found
function MusicData.GetTrack(trackKey)
	return MusicData.Tracks[trackKey]
end

-- Phase to track key mapping for easy lookup
MusicData.PhaseToTrack = {
	["Lobby"] = "Lobby",
	["BuildPhase"] = "BuildPhase",
	["SurvivePhase"] = "SurvivePhase",
	["BossWave"] = "BossWave",
	["RoundEnd"] = "Victory",
	["Death"] = "Death",
}

-- Get the primary track for a game phase
-- @param phase string - Game phase
-- @return table - Track data
function MusicData.GetTrackForPhase(phase)
	local trackKey = MusicData.PhaseToTrack[phase]
	if trackKey then
		return MusicData.GetTrack(trackKey)
	end
	return nil
end

return MusicData
