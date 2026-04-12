-- PlayerData.lua
-- Shared module for player data structures, validation, and formatting
-- Used by both client and server for consistent data handling

local PlayerData = {}

-- Inventory item types enum
PlayerData.ItemType = {
	ENGINE = "engine",
	FUEL_CANISTER = "fuelCanister",
}

-- Create a new default player data template
-- @return table with all required fields initialized to defaults
function PlayerData.CreateNewPlayerData()
	return {
		-- Stats tracking
		totalKills = 0,
		totalWavesSurvived = 0,
		highestWave = 0,
		gamesPlayed = 0,
		bestHelicopterSpeed = 0,

		-- Inventory
		inventory = {
			engine = 0,
			fuelCanister = 0,
		},

		-- Current session state
		currentFuel = 100, -- Will be set to BASE_FUEL from config

		-- Metadata
		lastUpdated = os.time(),
		sessionLocked = false,
	}
end

-- Validate player data structure
-- @param data table - The data to validate
-- @return boolean - Whether data is valid
-- @return string - Error message if invalid
function PlayerData.ValidateData(data)
	if type(data) ~= "table" then
		return false, "Data must be a table"
	end

	-- Check required fields
	local requiredFields = {
		"totalKills", "totalWavesSurvived", "highestWave", "gamesPlayed",
		"bestHelicopterSpeed", "inventory", "currentFuel"
	}

	for _, field in ipairs(requiredFields) do
		if data[field] == nil then
			return false, "Missing required field: " .. field
		end
	end

	-- Validate types
	if type(data.totalKills) ~= "number" or data.totalKills < 0 then
		return false, "totalKills must be non-negative number"
	end
	if type(data.totalWavesSurvived) ~= "number" or data.totalWavesSurvived < 0 then
		return false, "totalWavesSurvived must be non-negative number"
	end
	if type(data.highestWave) ~= "number" or data.highestWave < 0 then
		return false, "highestWave must be non-negative number"
	end
	if type(data.gamesPlayed) ~= "number" or data.gamesPlayed < 0 then
		return false, "gamesPlayed must be non-negative number"
	end
	if type(data.bestHelicopterSpeed) ~= "number" or data.bestHelicopterSpeed < 0 then
		return false, "bestHelicopterSpeed must be non-negative number"
	end
	if type(data.currentFuel) ~= "number" or data.currentFuel < 0 then
		return false, "currentFuel must be non-negative number"
	end

	-- Validate inventory structure
	if type(data.inventory) ~= "table" then
		return false, "inventory must be a table"
	end
	if type(data.inventory.engine) ~= "number" or data.inventory.engine < 0 then
		return false, "inventory.engine must be non-negative number"
	end
	if type(data.inventory.fuelCanister) ~= "number" or data.inventory.fuelCanister < 0 then
		return false, "inventory.fuelCanister must be non-negative number"
	end

	return true, "Valid"
end

-- Sanitize player data to ensure all values are within acceptable ranges
-- @param data table - The data to sanitize
-- @param config table - GameConfig for reference values
-- @return table - Sanitized data
function PlayerData.SanitizeData(data, config)
	local sanitized = {
		totalKills = math.max(0, math.floor(data.totalKills or 0)),
		totalWavesSurvived = math.max(0, math.floor(data.totalWavesSurvived or 0)),
		highestWave = math.max(0, math.floor(data.highestWave or 0)),
		gamesPlayed = math.max(0, math.floor(data.gamesPlayed or 0)),
		bestHelicopterSpeed = math.max(0, data.bestHelicopterSpeed or 0),

		inventory = {
			engine = math.max(0, math.floor(data.inventory.engine or 0)),
			fuelCanister = math.max(0, math.floor(data.inventory.fuelCanister or 0)),
		},

		currentFuel = math.max(0, data.currentFuel or (config and config.Helicopter.BASE_FUEL or 100)),

		lastUpdated = data.lastUpdated or os.time(),
		sessionLocked = false,
	}

	-- Cap inventory at maximums if config is provided
	if config then
		sanitized.inventory.engine = math.min(sanitized.inventory.engine, config.Helicopter.MAX_ENGINES)
		sanitized.inventory.fuelCanister = math.min(sanitized.inventory.fuelCanister, config.Helicopter.MAX_FUEL_CANISTERS)
		sanitized.currentFuel = math.min(sanitized.currentFuel,
			config.Helicopter.BASE_FUEL + (config.Helicopter.FUEL_PER_CANISTER * sanitized.inventory.fuelCanister))
	end

	return sanitized
end

-- Format player data for sending to client (excludes sensitive info if needed)
-- @param data table - The data to format
-- @return table - Formatted data safe for client
function PlayerData.FormatForClient(data)
	return {
		totalKills = data.totalKills,
		totalWavesSurvived = data.totalWavesSurvived,
		highestWave = data.highestWave,
		gamesPlayed = data.gamesPlayed,
		bestHelicopterSpeed = data.bestHelicopterSpeed,

		inventory = {
			engine = data.inventory.engine,
			fuelCanister = data.inventory.fuelCanister,
		},

		currentFuel = data.currentFuel,
	}
end

-- Get inventory count for a specific item type
-- @param data table - Player data
-- @param itemType string - Item type (from PlayerData.ItemType)
-- @return number - Item count
function PlayerData.GetInventoryCount(data, itemType)
	if itemType == PlayerData.ItemType.ENGINE then
		return data.inventory.engine or 0
	elseif itemType == PlayerData.ItemType.FUEL_CANISTER then
		return data.inventory.fuelCanister or 0
	end
	return 0
end

-- Set inventory count for a specific item type
-- @param data table - Player data
-- @param itemType string - Item type (from PlayerData.ItemType)
-- @param amount number - New amount
function PlayerData.SetInventoryCount(data, itemType, amount)
	if itemType == PlayerData.ItemType.ENGINE then
		data.inventory.engine = amount
	elseif itemType == PlayerData.ItemType.FUEL_CANISTER then
		data.inventory.fuelCanister = amount
	end
	data.lastUpdated = os.time()
end

return PlayerData
