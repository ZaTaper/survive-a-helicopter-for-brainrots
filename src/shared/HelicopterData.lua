-- HelicopterData.lua
-- Shared module for helicopter utility functions and calculations
-- Used by both server and client to ensure consistency

local GameConfig = require(script.Parent.GameConfig)

local HelicopterData = {}

--- Calculate helicopter speed based on number of engines
--- @param numEngines number - Number of engines installed
--- @return number - Speed value
function HelicopterData.CalculateSpeed(numEngines)
	numEngines = math.max(0, math.min(numEngines, GameConfig.Helicopter.MAX_ENGINES))
	return GameConfig.Helicopter.BASE_SPEED + (GameConfig.Helicopter.SPEED_PER_ENGINE * numEngines)
end

--- Calculate maximum fuel based on number of fuel canisters
--- @param numFuelCanisters number - Number of fuel canisters installed
--- @return number - Maximum fuel amount
function HelicopterData.CalculateMaxFuel(numFuelCanisters)
	numFuelCanisters = math.max(0, math.min(numFuelCanisters, GameConfig.Helicopter.MAX_FUEL_CANISTERS))
	return GameConfig.Helicopter.BASE_FUEL + (GameConfig.Helicopter.FUEL_PER_CANISTER * numFuelCanisters)
end

--- Calculate fuel drain rate per second
--- More canisters = lower drain rate (better endurance)
--- More engines = higher drain rate (more speed = more fuel consumption)
--- @param numEngines number - Number of engines
--- @param numFuelCanisters number - Number of fuel canisters
--- @return number - Fuel consumed per second
function HelicopterData.CalculateFuelDrainRate(numEngines, numFuelCanisters)
	numEngines = math.max(0, math.min(numEngines, GameConfig.Helicopter.MAX_ENGINES))
	numFuelCanisters = math.max(0, math.min(numFuelCanisters, GameConfig.Helicopter.MAX_FUEL_CANISTERS))

	-- Base drain rate
	local drainRate = GameConfig.Helicopter.FUEL_DRAIN_RATE

	-- Engines increase drain (speed requires more fuel)
	drainRate = drainRate + (GameConfig.Helicopter.FUEL_DRAIN_MULTIPLIER * numEngines)

	-- Canisters decrease drain (more efficient fuel consumption with better equipment)
	-- Reduction formula: drain * (1 - canister_efficiency)
	local canisteEfficiency = math.min(0.9, numFuelCanisters * 0.05) -- 5% efficiency per canister, max 90%
	drainRate = drainRate * (1 - canisteEfficiency)

	return math.max(0.1, drainRate) -- Minimum drain of 0.1 per second
end

--- Get complete helicopter stats from player data
--- @param playerData table - Player's helicopter data {engines, fuelCanisters, currentFuel}
--- @return table - Stats including speed, maxFuel, drainRate
function HelicopterData.GetHelicopterStats(playerData)
	local engines = playerData.engines or 0
	local fuelCanisters = playerData.fuelCanisters or 0
	local currentFuel = playerData.currentFuel or GameConfig.Helicopter.BASE_FUEL

	local speed = HelicopterData.CalculateSpeed(engines)
	local maxFuel = HelicopterData.CalculateMaxFuel(fuelCanisters)
	local drainRate = HelicopterData.CalculateFuelDrainRate(engines, fuelCanisters)

	return {
		speed = speed,
		maxFuel = maxFuel,
		currentFuel = currentFuel,
		drainRate = drainRate,
		engines = engines,
		fuelCanisters = fuelCanisters,
		timeRemaining = currentFuel / drainRate, -- Seconds of flight time remaining
	}
end

return HelicopterData
