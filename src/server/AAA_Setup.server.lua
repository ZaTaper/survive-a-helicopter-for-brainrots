-- AAA_Setup.server.lua
-- Game Setup Script - Runs FIRST to create all RemoteEvents and RemoteFolders
-- Name starts with AAA_ to ensure it loads before other server scripts alphabetically
-- This prevents "Infinite yield possible" errors when client scripts wait for these objects

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Setup] Starting game initialization...")

-- Helper function to create or get a RemoteEvent
local function CreateRemoteEvent(name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = parent
	return event
end

-- Helper function to create or get a RemoteFunction
local function CreateRemoteFunction(name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local func = Instance.new("RemoteFunction")
	func.Name = name
	func.Parent = parent
	return func
end

-- Helper function to create or get a Folder
local function CreateFolder(name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- ============================================================================
-- HELICOPTER REMOTES
-- ============================================================================
print("[Setup] Creating HelicopterRemotes folder and events...")
local HelicopterRemotes = CreateFolder("HelicopterRemotes", ReplicatedStorage)
CreateRemoteEvent("BuildHelicopter", HelicopterRemotes)
CreateRemoteEvent("AddEngine", HelicopterRemotes)
CreateRemoteEvent("AddFuelCanister", HelicopterRemotes)
CreateRemoteEvent("ActivateHelicopter", HelicopterRemotes)
CreateRemoteEvent("DeactivateHelicopter", HelicopterRemotes)
CreateRemoteFunction("GetHelicopterStats", HelicopterRemotes)

-- ============================================================================
-- GAME LOOP EVENTS
-- ============================================================================
print("[Setup] Creating GameLoop remote events...")
CreateRemoteEvent("GameStateChanged", ReplicatedStorage)
CreateRemoteEvent("PlayerDied", ReplicatedStorage)
CreateRemoteEvent("WaveStarted", ReplicatedStorage)
CreateRemoteEvent("WaveEnded", ReplicatedStorage)
CreateRemoteEvent("RoundEnded", ReplicatedStorage)

-- ============================================================================
-- BRAINROT SYSTEM EVENTS
-- ============================================================================
print("[Setup] Creating BrainrotSystem remote events...")
CreateRemoteEvent("BrainrotSpawned", ReplicatedStorage)
CreateRemoteEvent("BrainrotDespawned", ReplicatedStorage)
CreateRemoteEvent("BrainrotDamaged", ReplicatedStorage)
CreateRemoteEvent("BrainrotCollected", ReplicatedStorage)
CreateRemoteEvent("CollectionUpdated", ReplicatedStorage)
CreateRemoteFunction("GetBrainrotCollection", ReplicatedStorage)

-- ============================================================================
-- MUSIC / GAME PHASE EVENTS
-- ============================================================================
print("[Setup] Creating Music and GamePhase remote events...")
CreateRemoteEvent("GamePhaseChanged", ReplicatedStorage)

-- ============================================================================
-- TOOL PICKUPS EVENTS
-- ============================================================================
print("[Setup] Creating ToolPickups remote events...")
CreateRemoteEvent("PickupCollected", ReplicatedStorage)

-- ============================================================================
-- DATA MANAGER EVENTS
-- ============================================================================
print("[Setup] Creating DataManager remote events...")
CreateRemoteEvent("PlayerDataLoaded", ReplicatedStorage)
CreateRemoteFunction("UpdateStats", ReplicatedStorage)

-- ============================================================================
-- INVENTORY SYSTEM EVENTS
-- ============================================================================
print("[Setup] Creating InventorySystem remote events...")
CreateRemoteEvent("InventoryUpdate", ReplicatedStorage)
CreateRemoteFunction("GetInventory", ReplicatedStorage)

-- ============================================================================
-- SHOP SYSTEM FOLDER AND EVENTS
-- ============================================================================
print("[Setup] Creating Shop folder and events...")
local ShopFolder = CreateFolder("Shop", ReplicatedStorage)
CreateRemoteEvent("BuyItem", ShopFolder)
CreateRemoteFunction("GetMoney", ShopFolder)
CreateRemoteFunction("GetShopItems", ShopFolder)
CreateRemoteEvent("MoneyChanged", ShopFolder)
CreateRemoteEvent("PurchaseSuccess", ShopFolder)
CreateRemoteEvent("PurchaseFailed", ShopFolder)

-- ============================================================================
-- ADMIN SYSTEM FOLDER AND EVENTS
-- ============================================================================
print("[Setup] Creating AdminEvents folder and all admin command events...")
local AdminEvents = CreateFolder("AdminEvents", ReplicatedStorage)

-- Brainrot control events
CreateRemoteEvent("SpawnBrainrot", AdminEvents)
CreateRemoteEvent("SpawnMultipleBrainrots", AdminEvents)
CreateRemoteEvent("SpawnOPBrainrot", AdminEvents)
CreateRemoteEvent("KillAllBrainrots", AdminEvents)
CreateRemoteEvent("TargetBrainrots", AdminEvents)
CreateRemoteEvent("FreezeBrainrots", AdminEvents)
CreateRemoteEvent("BuffNerfBrainrots", AdminEvents)

-- Player control events
CreateRemoteEvent("GiveMoney", AdminEvents)
CreateRemoteEvent("SetMoney", AdminEvents)
CreateRemoteEvent("GiveItems", AdminEvents)
CreateRemoteEvent("KickPlayer", AdminEvents)
CreateRemoteEvent("TeleportToPlayer", AdminEvents)
CreateRemoteEvent("TeleportPlayerToMe", AdminEvents)
CreateRemoteEvent("HealPlayer", AdminEvents)

-- God power events
CreateRemoteEvent("ToggleFlyMode", AdminEvents)
CreateRemoteEvent("ToggleGodMode", AdminEvents)
CreateRemoteEvent("ToggleInfiniteFuel", AdminEvents)
CreateRemoteEvent("ToggleSpeedBoost", AdminEvents)
CreateRemoteEvent("ToggleInvisibleMode", AdminEvents)
CreateRemoteEvent("ToggleNoclip", AdminEvents)
CreateRemoteEvent("ToggleGiantMode", AdminEvents)
CreateRemoteEvent("ToggleTinyMode", AdminEvents)

-- Game control events
CreateRemoteEvent("SkipToWave", AdminEvents)
CreateRemoteEvent("SkipPhase", AdminEvents)
CreateRemoteEvent("ToggleBrainrotWaves", AdminEvents)
CreateRemoteEvent("SetWaveDifficulty", AdminEvents)
CreateRemoteEvent("TogglePVP", AdminEvents)
CreateRemoteEvent("AddPhaseTime", AdminEvents)
CreateRemoteEvent("RestartRound", AdminEvents)

-- Event system events
CreateRemoteEvent("StartDoubleMoneyEvent", AdminEvents)
CreateRemoteEvent("StartBrainrotRushEvent", AdminEvents)
CreateRemoteEvent("StartRainEvent", AdminEvents)
CreateRemoteEvent("SpawnBoss", AdminEvents)
CreateRemoteEvent("StartFreeStuffEvent", AdminEvents)
CreateRemoteEvent("StartSpeedEvent", AdminEvents)

-- Server control events
CreateRemoteEvent("ServerAnnouncement", AdminEvents)
CreateRemoteEvent("ServerNotification", AdminEvents)
CreateRemoteEvent("ReceiveAnnouncement", AdminEvents)

-- New admin events
CreateRemoteEvent("NukeAllBrainrots", AdminEvents)
CreateRemoteEvent("GiveAllMoney", AdminEvents)
CreateRemoteEvent("TeleportAllToAdmin", AdminEvents)

-- ============================================================================
-- BASE SYSTEM EVENTS
-- ============================================================================
print("[Setup] Creating BaseSystem remote events...")
CreateRemoteEvent("MoneyEarned", ReplicatedStorage)
CreateRemoteFunction("GetBaseInfo", ReplicatedStorage)

-- ============================================================================
-- MONEY SYSTEM EVENTS
-- ============================================================================
print("[Setup] Creating MoneySystem remote events...")
CreateRemoteEvent("MoneyChanged", ReplicatedStorage)
CreateRemoteFunction("GetBalance", ReplicatedStorage)
CreateRemoteEvent("ShowFloatingMoney", ReplicatedStorage)

-- ============================================================================
-- WATER SYSTEM EVENTS
-- ============================================================================
print("[Setup] Creating WaterSystem remote events...")
CreateRemoteEvent("WaterSplash", ReplicatedStorage)
CreateRemoteEvent("HelicopterRestart", ReplicatedStorage)

-- ============================================================================
-- HUD SYSTEM EVENTS (Created by HUDClient but setup here as safety net)
-- ============================================================================
print("[Setup] Creating HUDEvents folder and events...")
local HUDEvents = CreateFolder("HUDEvents", ReplicatedStorage)
CreateRemoteEvent("UpdateFuel", HUDEvents)
CreateRemoteEvent("UpdateSpeed", HUDEvents)
CreateRemoteEvent("UpdateInventory", HUDEvents)
CreateRemoteEvent("UpdateKillCount", HUDEvents)
CreateRemoteEvent("UpdateWave", HUDEvents)
CreateRemoteEvent("UpdatePhase", HUDEvents)
CreateRemoteEvent("UpdateLeaderboard", HUDEvents)
CreateRemoteEvent("PlayerDied", HUDEvents)
CreateRemoteEvent("PickupNotification", HUDEvents)
CreateRemoteEvent("UpdateBrainBucks", HUDEvents)
CreateRemoteEvent("CollectionUpdated", HUDEvents)
CreateRemoteEvent("MusicVolumeChanged", HUDEvents)

-- ============================================================================
-- SHARED FOLDERS (create if missing)
-- ============================================================================
print("[Setup] Creating shared folders...")
CreateFolder("Shared", ReplicatedStorage)
CreateFolder("Storage", ReplicatedStorage)

-- ============================================================================
-- VALIDATION AND COMPLETION
-- ============================================================================
print("[Setup] All RemoteEvents, RemoteFolders, and RemoteFunctions created")
print("[Setup] Setup complete!")
