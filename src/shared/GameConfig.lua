-- GameConfig.lua
-- Central configuration for "Survive a Helicopter for Brainrots"

local GameConfig = {}

-- Admin users who get the admin panel
GameConfig.ADMINS = {
	"googoo9876543", -- Game owner
}

-- Helicopter settings
GameConfig.Helicopter = {
	BASE_SPEED = 20,           -- Base speed without engines
	SPEED_PER_ENGINE = 15,     -- Additional speed per engine
	MAX_ENGINES = 10,          -- Maximum engines per helicopter
	BASE_FUEL = 100,           -- Starting fuel amount
	FUEL_PER_CANISTER = 50,    -- Additional fuel per canister
	MAX_FUEL_CANISTERS = 20,   -- Maximum fuel canisters
	FUEL_DRAIN_RATE = 1,       -- Fuel consumed per second at base speed
	FUEL_DRAIN_MULTIPLIER = 0.1, -- Extra fuel drain per engine (more speed = more drain)
	HEIGHT = 50,               -- Flying height
}

-- Brainrot rarity tiers (worst to best)
GameConfig.BrainrotTiers = {
	{name = "Common",    color = Color3.fromRGB(180, 180, 180), damage = 10,  speed = 12, health = 50,   spawnWeight = 40},
	{name = "Uncommon",  color = Color3.fromRGB(50, 200, 50),   damage = 15,  speed = 14, health = 80,   spawnWeight = 25},
	{name = "Rare",      color = Color3.fromRGB(50, 100, 255),  damage = 25,  speed = 16, health = 120,  spawnWeight = 15},
	{name = "Epic",      color = Color3.fromRGB(160, 50, 255),  damage = 35,  speed = 18, health = 200,  spawnWeight = 10},
	{name = "Mythic",    color = Color3.fromRGB(255, 50, 50),   damage = 50,  speed = 22, health = 350,  spawnWeight = 5},
	{name = "Secret",    color = Color3.fromRGB(255, 215, 0),   damage = 70,  speed = 26, health = 500,  spawnWeight = 3},
	{name = "Celestial", color = Color3.fromRGB(0, 255, 255),   damage = 100, speed = 30, health = 800,  spawnWeight = 1.5},
	{name = "OP",        color = Color3.fromRGB(255, 0, 128),   damage = 150, speed = 35, health = 1500, spawnWeight = 0.5},
}

-- Player settings
GameConfig.Player = {
	START_HEALTH = 100,
	RESPAWN_TIME = 5,
	BUILD_TIME = 60, -- Seconds to build helicopter before brainrots attack
}

-- Map settings
GameConfig.Map = {
	SIZE = 500,           -- Map radius
	SPAWN_RADIUS = 400,   -- Brainrot spawn radius
	SAFE_ZONE_RADIUS = 50, -- Safe zone around spawn
}

-- Wave settings
GameConfig.Waves = {
	TIME_BETWEEN_WAVES = 30,
	BRAINROTS_PER_WAVE_BASE = 5,
	BRAINROTS_PER_WAVE_INCREMENT = 3,
	MAX_BRAINROTS = 50,
}

return GameConfig
