-- MusicClient.client.lua
-- Client-side music controller for "Survive a Helicopter for Brainrots"
-- Manages background music playback with smooth crossfades between game phases
-- Plays intense music for different game phases

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Wait for MusicData module
local MusicData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MusicData"))

-- Service references
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Load MusicSettings from GUI folder
local MusicSettings = require(playerGui:WaitForChild("GUI"):WaitForChild("MusicSettings"))

local MusicClient = {}

-- State tracking
local currentTrackKey = nil
local targetTrackKey = nil
local isCrossfading = false
local masterVolume = MusicData.DEFAULT_VOLUME
local currentPhase = "Lobby"
local soundObjects = {}  -- Cache of created sound objects { [trackKey] = Sound }
local soundFolder = nil

-- Initialize music system
function MusicClient.Initialize()
	print("[MusicClient] Initializing music client...")

	-- Create folder to hold sound objects
	soundFolder = Instance.new("Folder")
	soundFolder.Name = "MusicSounds"
	soundFolder.Parent = playerGui

	-- Initialize MusicSettings UI
	task.wait(0.1)
	MusicSettings:Init()

	-- Hook up UI callbacks
	MusicSettings.OnVolumeChanged = function(newVolume)
		MusicClient.SetVolume(newVolume)
	end

	-- Pre-create sound objects for all tracks
	MusicClient._PreloadSounds()

	-- Connect to game state changes
	MusicClient._ConnectGameStateEvents()

	-- Start with lobby music
	MusicClient.PlayTrack("Lobby")

	print("[MusicClient] Music client initialized")
end

-- Pre-load all sound objects to avoid delays when switching tracks
function MusicClient._PreloadSounds()
	print("[MusicClient] Pre-loading sound objects...")

	for trackKey, trackData in pairs(MusicData.Tracks) do
		local sound = Instance.new("Sound")
		sound.Name = "Track_" .. trackKey
		sound.SoundId = trackData.assetId
		sound.Volume = trackData.volume * masterVolume
		sound.Looped = trackData.looping
		sound.Parent = soundFolder

		soundObjects[trackKey] = sound
	end

	print("[MusicClient] Sounds pre-loaded")
end

-- Connect to game state events from server
function MusicClient._ConnectGameStateEvents()
	print("[MusicClient] Connecting to game state events...")

	-- Listen for game phase changes (RemoteEvent)
	local gamePhaseEvent = ReplicatedStorage:WaitForChild("GamePhaseChanged")
	gamePhaseEvent.OnClientEvent:Connect(function(phase)
		if phase then
			MusicClient.OnPhaseChanged(phase)
		end
	end)

	-- Listen for player death
	local playerDeathEvent = ReplicatedStorage:FindFirstChild("PlayerDied")
	if playerDeathEvent then
		playerDeathEvent.OnClientEvent:Connect(function(playerName)
			if playerName == localPlayer.Name then
				MusicClient.PlayDeathSound()
			end
		end)
	end

	-- Listen for round end / victory
	local roundEndEvent = ReplicatedStorage:FindFirstChild("RoundEnded")
	if roundEndEvent then
		roundEndEvent.OnClientEvent:Connect(function(roundResults)
			MusicClient.OnRoundEnd(roundResults)
		end)
	end

	print("[MusicClient] Game state events connected")
end

-- Handle phase change
function MusicClient.OnPhaseChanged(newPhase)
	if newPhase == currentPhase then
		return
	end

	print("[MusicClient] Phase changed to: " .. newPhase)
	currentPhase = newPhase

	-- Play appropriate track for phase
	local track = MusicData.GetTrackForPhase(newPhase)
	if track then
		MusicClient.PlayTrack(track)
	end
end

-- Handle round end
function MusicClient.OnRoundEnd(roundResults)
	print("[MusicClient] Round ended")
	local victoryTrack = MusicData.GetTrack("Victory")
	if victoryTrack then
		MusicClient.PlayTrack(victoryTrack)
	end
end

-- Play a death sound and fade out current music
function MusicClient.PlayDeathSound()
	print("[MusicClient] Playing death sound")

	-- Fade out current music
	if currentTrackKey then
		MusicClient.FadeOutTrack(currentTrackKey, 0.5)
	end

	-- Play death sting
	local deathTrack = MusicData.GetTrack("Death")
	if deathTrack and soundObjects["Death"] then
		local deathSound = soundObjects["Death"]
		deathSound.Volume = deathTrack.volume * masterVolume
		deathSound:Play()
	end
end

-- Play a specific track
-- @param trackData table - The track data object
function MusicClient.PlayTrack(trackData)
	if not trackData then
		print("[MusicClient] No track data provided")
		return
	end

	-- Find the track key
	local trackKey = nil
	for key, data in pairs(MusicData.Tracks) do
		if data == trackData then
			trackKey = key
			break
		end
	end

	if not trackKey then
		print("[MusicClient] Track not found in registry")
		return
	end

	-- If already playing this track, don't restart it
	if currentTrackKey == trackKey then
		print("[MusicClient] Track already playing: " .. trackData.name)
		return
	end

	-- Get the sound object
	local sound = soundObjects[trackKey]
	if not sound then
		print("[MusicClient] Sound object not found for track: " .. trackData.name)
		return
	end

	targetTrackKey = trackKey

	-- If no current track, just play it
	if not currentTrackKey then
		sound.Volume = trackData.volume * masterVolume
		sound:Play()
		currentTrackKey = trackKey
		print("[MusicClient] Now playing: " .. trackData.name)
		return
	end

	-- Crossfade to new track
	MusicClient.CrossfadeToTrack(trackKey, trackData)
end

-- Crossfade from current track to a new track
-- @param newTrackKey string - The key of the new track
-- @param newTrackData table - The new track data
function MusicClient.CrossfadeToTrack(newTrackKey, newTrackData)
	if isCrossfading then
		print("[MusicClient] Already crossfading, queueing next track")
		targetTrackKey = newTrackKey
		return
	end

	isCrossfading = true
	print("[MusicClient] Starting crossfade to: " .. newTrackData.name)

	local crossfadeDuration = newTrackData.fadeTime or MusicData.CROSSFADE_DURATION
	local oldSound = soundObjects[currentTrackKey]
	local newSound = soundObjects[newTrackKey]
	local startTime = tick()

	-- Start playing new track at low volume
	newSound.Volume = 0
	newSound:Play()

	-- Crossfade
	while isCrossfading and (tick() - startTime) < crossfadeDuration do
		local elapsed = tick() - startTime
		local progress = elapsed / crossfadeDuration

		-- Fade out old track
		if oldSound then
			local oldTrackData = MusicData.Tracks[currentTrackKey]
			oldSound.Volume = (1 - progress) * (oldTrackData.volume * masterVolume)
		end

		-- Fade in new track
		newSound.Volume = progress * (newTrackData.volume * masterVolume)

		task.wait(0.01)
	end

	-- Finalize
	if oldSound then
		oldSound:Stop()
		oldSound.Volume = 0
	end

	newSound.Volume = newTrackData.volume * masterVolume
	currentTrackKey = targetTrackKey
	isCrossfading = false

	print("[MusicClient] Crossfade complete. Now playing: " .. newTrackData.name)

	-- If a new track was queued during crossfade, play it
	if targetTrackKey ~= currentTrackKey then
		local queuedTrackKey = targetTrackKey
		targetTrackKey = nil
		task.wait(0.1)
		local queuedTrack = MusicData.Tracks[queuedTrackKey]
		if queuedTrack then
			MusicClient.PlayTrack(queuedTrack)
		end
	end
end

-- Fade out a track
-- @param trackKey string - The track key to fade out
-- @param duration number - Duration of fade in seconds
function MusicClient.FadeOutTrack(trackKey, duration)
	if not trackKey or not soundObjects[trackKey] then
		return
	end

	local sound = soundObjects[trackKey]
	local trackData = MusicData.Tracks[trackKey]
	local targetVolume = trackData.volume * masterVolume
	local startTime = tick()

	while (tick() - startTime) < duration do
		local elapsed = tick() - startTime
		local progress = 1 - (elapsed / duration)
		sound.Volume = targetVolume * progress
		task.wait(0.01)
	end

	sound:Stop()
	sound.Volume = 0
end

-- Set master volume (affects all playing tracks)
-- @param volume number - Volume level (0-1)
function MusicClient.SetVolume(volume)
	masterVolume = math.max(0, math.min(1, volume))
	print(string.format("[MusicClient] Master volume set to: %.2f", masterVolume))

	-- Update all sound objects
	for trackKey, sound in pairs(soundObjects) do
		local trackData = MusicData.Tracks[trackKey]
		if trackData and sound then
			if sound.Playing then
				sound.Volume = trackData.volume * masterVolume
			end
		end
	end
end

-- Stop all music
function MusicClient.StopMusic()
	print("[MusicClient] Stopping all music")

	for _, sound in pairs(soundObjects) do
		sound:Stop()
	end

	currentTrackKey = nil
	targetTrackKey = nil
end

-- Get current track name
-- @return string
function MusicClient.GetCurrentTrackName()
	if currentTrackKey and MusicData.Tracks[currentTrackKey] then
		return MusicData.Tracks[currentTrackKey].name
	end
	return "None"
end

-- Get current phase
-- @return string
function MusicClient.GetCurrentPhase()
	return currentPhase
end

-- Start the music client
print("[MusicClient] Music client script loading...")
task.wait(1)
MusicClient.Initialize()

return MusicClient
