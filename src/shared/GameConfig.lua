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
	FUEL_DRAIN_MULTIPLIER = 0.1, -- Extra fuel drain per engine
	HEIGHT = 50,               -- Flying height
}

-- Starter helicopter settings (free default helicopter for new players)
GameConfig.StarterHelicopter = {
	ENGINES = 1,
	FUEL_CANISTERS = 2,
	SPEED = 35,              -- BASE_SPEED + 1 engine
	MAX_FUEL = 200,          -- BASE_FUEL + 2 canisters
}

-- Brainrot rarity tiers (worst to best) with money rewards
GameConfig.BrainrotTiers = {
	{name = "Common",    color = Color3.fromRGB(180, 180, 180), damage = 10,  speed = 12, health = 50,   spawnWeight = 40,  money = 10},
	{name = "Uncommon",  color = Color3.fromRGB(50, 200, 50),   damage = 15,  speed = 14, health = 80,   spawnWeight = 25,  money = 25},
	{name = "Rare",      color = Color3.fromRGB(50, 100, 255),  damage = 25,  speed = 16, health = 120,  spawnWeight = 15,  money = 50},
	{name = "Epic",      color = Color3.fromRGB(160, 50, 255),  damage = 35,  speed = 18, health = 200,  spawnWeight = 10,  money = 100},
	{name = "Mythic",    color = Color3.fromRGB(255, 50, 50),   damage = 50,  speed = 22, health = 350,  spawnWeight = 5,   money = 250},
	{name = "Secret",    color = Color3.fromRGB(255, 215, 0),   damage = 70,  speed = 26, health = 500,  spawnWeight = 3,   money = 500},
	{name = "Celestial", color = Color3.fromRGB(0, 255, 255),   damage = 100, speed = 30, health = 800,  spawnWeight = 1.5, money = 1000},
	{name = "OP",        color = Color3.fromRGB(255, 0, 128),   damage = 150, speed = 35, health = 1500, spawnWeight = 0.5, money = 5000},
}

-- Shop prices for materials
GameConfig.Shop = {
	ENGINE_PRICE = 100,
	FUEL_CANISTER_PRICE = 75,
	ROTOR_UPGRADE_PRICE = 200,
	BODY_UPGRADE_PRICE = 150,
}

-- Currency settings
GameConfig.Currency = {
	START_MONEY = 50,
	CURRENCY_NAME = "BrainBucks",
}

-- Player settings
GameConfig.Player = {
	START_HEALTH = 100,
	RESPAWN_TIME = 5,
	BUILD_TIME = 60,
}

-- Map settings (sky-based floating map)
GameConfig.Map = {
	SIZE = 500,
	SPAWN_RADIUS = 400,
	SAFE_ZONE_RADIUS = 50,
	WATER_HEIGHT = 100,         -- Void death threshold (fall below this = death)
	MAP_CENTER_Y = 200,         -- Sky map center height
	PLAYER_BASE_RADIUS = 150,   -- Distance from hub to player bases
	BRAINROT_ISLAND_RADIUS = 350, -- Distance from hub to brainrot islands
}

-- Wave settings
GameConfig.Waves = {
	TIME_BETWEEN_WAVES = 30,
	BRAINROTS_PER_WAVE_BASE = 5,
	BRAINROTS_PER_WAVE_INCREMENT = 3,
	MAX_BRAINROTS = 50,
}

return GameConfig
