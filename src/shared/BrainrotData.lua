-- BrainrotData.lua
-- Shared module for brainrot data structures, names, and utility functions
-- Used by both client and server for consistent brainrot handling

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local BrainrotData = {}

-- Funny brainrot names per tier (randomly selected when spawning)
BrainrotData.BRAINROT_NAMES = {
	Common = {
		"Sksksksks",
		"Bruh Moment",
		"Skibidi",
		"Sigma Grindset",
		"No Cap",
		"Bet",
		"Based",
		"Mid",
		"Gyatt",
		"Rizz Goblin",
		"L Taker",
		"Cope Bottle",
		"Ratio Hopeful",
		"Fax Machine",
		"Meme Rookie",
	},
	Uncommon = {
		"Alpha Chad",
		"Skibidi Toilet",
		"Fanum Tax Collector",
		"Mogging Monster",
		"Slay Queen",
		"It's Giving...",
		"Bussin Demon",
		"Periodt Enforcer",
		"Delulu Entity",
		"Vibe Check",
		"Mandem Special",
		"Sigma Energy",
		"Rizz Apprentice",
		"Slaying Novice",
		"Cringe Detector",
	},
	Rare = {
		"Meme Lord Ancient",
		"Ohio Creature",
		"Rizzmaster 3000",
		"Slay or Be Slayed",
		"The Unfunnies",
		"Cope Daemon",
		"Ratio Incarnate",
		"Vibes Eater",
		"Cringe Guardian",
		"Based AF Spirit",
		"Mogging Specialist",
		"Bussin' Collector",
		"Gyatt Summoner",
		"Sigma Enforcer",
		"Skibidi Scholar",
	},
	Epic = {
		"Skibidi Emperor",
		"The Sigma Beast",
		"Pilled Harbinger",
		"Gyatt Eternal",
		"Rizz Overlord",
		"Slaymageddon",
		"The Unhinged One",
		"Bussin' Celestial",
		"Mogged Beyond Repair",
		"Glow-Up Nightmare",
		"Vibe Annihilator",
		"Cope Void",
		"Cringe Oblivion",
		"The Ratio King",
		"Skibidi Awakened",
	},
	Mythic = {
		"SKIBIDI INFINITY",
		"THE ULTIMATE RIZZ",
		"SIGMA PRIMORDIAL",
		"GYATT UNLEASHED",
		"NO CAP ETERNAL",
		"BUSSIN ABSOLUTE",
		"SLAY INCARNATE",
		"MOGGING EVERYTHING",
		"THE UNDEFEATABLE VIBE",
		"BASED REALITY WARPER",
		"MEME APOCALYPSE",
		"VIBE SINGULARITY",
		"COPE DESTROYED",
		"RATIO DOMINATOR",
		"THE SKIBIDI CHOSEN",
	},
	Secret = {
		"Literally Me IRL",
		"The Algorithm Chosen",
		"Ratio Master Supreme",
		"Cringe Singularity",
		"The Deletor",
		"Vibe Obliterator",
		"The Unmeme",
		"Cope Infinity",
		"Slay Eternally",
		"The Forbidden Gyatt",
		"Sigma Transcendent",
		"The Bussin' Prophet",
		"No Cap Absolute",
		"Mogging Divinity",
		"Secret Skibidi",
	},
	Celestial = {
		"⭐ COSMIC SKIBIDI ⭐",
		"✨ THE RIZZ DIMENSION ✨",
		"🌌 SIGMA TRANSCENDENT 🌌",
		"💫 GYATT BEYOND SPACE 💫",
		"🪐 BUSSIN' DIMENSIONAL ⭐",
		"🌟 SLAYED REALITY 🌟",
		"✨ THE FORBIDDEN RIZZ ✨",
		"🌌 MOGGED UNIVERSE 🌌",
		"💫 GYATT ABSOLUTE 💫",
		"⭐ THE ULTIMATE NO CAP ⭐",
		"🌠 COSMIC VIBE WARPER 🌠",
		"🌙 MOONLIT SIGMA BEAST 🌙",
		"✨ ETHEREAL COPE BREAKER ✨",
		"💫 ASTRAL SKIBIDI 💫",
		"🌌 VOID SLAY ENTITY 🌌",
	},
	OP = {
		"【SKIBIDI ABSOLUTE】",
		"【SIGMA OMEGA】",
		"【THE ONE GYATT】",
		"【RIZZ SINGULARITY】",
		"【REALITY.EXE STOPPED】",
		"【MOGGING ITSELF】",
		"【BUSSIN' POWER】",
		"【SLAY APOCALYPSE】",
		"【THE FINAL RATIO】",
		"【UNFATHOMABLE VIBE】",
		"【NO CAP SUPREMACY】",
		"【GYATT TRANSCENDENCE】",
		"【VOID BREAKER】",
		"【THE FORBIDDEN SKIBIDI】",
		"【EXISTENCE ITSELF】",
	},
}

--- Get tier configuration by tier name
--- @param tierName string - Name of the tier (e.g., "Common", "Rare")
--- @return table - Tier configuration table, or nil if not found
function BrainrotData.GetTierByName(tierName)
	for _, tier in ipairs(GameConfig.BrainrotTiers) do
		if tier.name == tierName then
			return tier
		end
	end
	return nil
end

--- Get a random brainrot name for a given tier
--- @param tierName string - Name of the tier
--- @return string - A funny brainrot name
function BrainrotData.GetRandomBrainrotName(tierName)
	local names = BrainrotData.BRAINROT_NAMES[tierName]
	if not names or #names == 0 then
		return tierName .. " Creature"
	end
	return names[math.random(1, #names)]
end

--- Pick a random tier based on wave number (higher waves = better chance of higher tiers)
--- Uses weighted random selection based on spawnWeight values
--- @param waveNumber number - Current wave number (1-indexed)
--- @return table - Tier configuration table
function BrainrotData.GetRandomTier(waveNumber)
	local tiers = GameConfig.BrainrotTiers

	-- Calculate wave multiplier (0.5x at wave 1, increases with wave)
	-- This makes higher waves more likely to spawn better tiers
	local waveMultiplier = 0.5 + (waveNumber - 1) * 0.15

	-- Calculate adjusted weights based on wave
	local adjustedWeights = {}
	local totalWeight = 0

	for i, tier in ipairs(tiers) do
		-- Higher tier index (better tiers) get exponentially better odds at higher waves
		local tierBonus = math.pow(1.5, i - 1) * waveMultiplier
		local adjustedWeight = tier.spawnWeight * tierBonus
		adjustedWeights[i] = adjustedWeight
		totalWeight = totalWeight + adjustedWeight
	end

	-- Select a random tier based on adjusted weights
	local random = math.random() * totalWeight
	local accumulated = 0

	for i, tier in ipairs(tiers) do
		accumulated = accumulated + adjustedWeights[i]
		if random <= accumulated then
			return tier
		end
	end

	-- Fallback to last tier (should never happen)
	return tiers[#tiers]
end

--- Get display information for a brainrot tier (name, color)
--- @param tierName string - Name of the tier
--- @return table - Table with name and color
function BrainrotData.GetBrainrotDisplayInfo(tierName)
	local tier = BrainrotData.GetTierByName(tierName)
	if not tier then
		return {
			name = "Unknown",
			color = Color3.fromRGB(128, 128, 128),
		}
	end

	return {
		name = tier.name,
		color = tier.color,
	}
end

--- Validate brainrot attributes
--- @param brainrot table - Brainrot data to validate
--- @return boolean - Whether brainrot is valid
function BrainrotData.ValidateBrainrot(brainrot)
	if type(brainrot) ~= "table" then
		return false
	end

	local requiredFields = {
		"uniqueId", "tier", "displayName", "health", "maxHealth",
		"damage", "speed", "model", "lastAttackTime", "targetPlayer",
	}

	for _, field in ipairs(requiredFields) do
		if brainrot[field] == nil then
			return false
		end
	end

	return true
end

--- Create a new brainrot instance data structure
--- @param tier table - Tier configuration from GameConfig
--- @param model Instance - The model instance for this brainrot
--- @param uniqueId string - Unique identifier for this brainrot
--- @return table - New brainrot data structure
function BrainrotData.CreateBrainrot(tier, model, uniqueId)
	return {
		uniqueId = uniqueId,
		tier = tier.name,
		displayName = BrainrotData.GetRandomBrainrotName(tier.name),
		health = tier.health,
		maxHealth = tier.health,
		damage = tier.damage,
		speed = tier.speed,
		model = model,
		lastAttackTime = 0,
		targetPlayer = nil,
		lastChaseTime = 0,
		createdAt = tick(),
	}
end

--- Collection chances by tier (percentage 0-100)
--- Tiers indexed 1-8 (Common through OP)
BrainrotData.COLLECTION_CHANCES = {
	80,  -- 1: Common
	60,  -- 2: Uncommon
	40,  -- 3: Rare
	25,  -- 4: Epic
	15,  -- 5: Mythic
	8,   -- 6: Secret
	4,   -- 7: Celestial
	2,   -- 8: OP
}

--- Get collection chance for a tier (percentage 0-100)
--- @param tierIndex number - Index of tier (1-8)
--- @return number - Collection chance as percentage (0-100)
function BrainrotData.GetCollectionChance(tierIndex)
	if tierIndex < 1 or tierIndex > #GameConfig.BrainrotTiers then
		return 0
	end
	return BrainrotData.COLLECTION_CHANCES[tierIndex] or 0
end

--- Get money reward for a tier
--- @param tierIndex number - Index of tier (1-8)
--- @return number - Money reward amount
function BrainrotData.GetMoneyReward(tierIndex)
	if tierIndex < 1 or tierIndex > #GameConfig.BrainrotTiers then
		return 0
	end
	local tier = GameConfig.BrainrotTiers[tierIndex]
	return tier.money or 0
end

return BrainrotData
