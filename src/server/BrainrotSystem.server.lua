-- BrainrotSystem.server.lua
-- Server-side static brainrot collectible system for "Survive a Helicopter for Brainrots"
-- Manages floating brainrot collectibles on tier-themed islands with gentle bob animation
-- Players fly helicopters to grab them
--
-- CRITICAL: This is a .server.lua file (cannot be required). Uses _G.BrainrotSystem for global export.
-- HelicopterSystem calls:
--   _G.BrainrotSystem.GetNearestBrainrot(position, radius) -> {uniqueId, tierName, tierIndex, displayName, model} or nil
--   _G.BrainrotSystem.GrabBrainrot(uniqueId) -> {tierName, tierIndex, displayName, money} or nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotModel = require(ServerStorage:WaitForChild("Storage"):WaitForChild("BrainrotModel"))

local BrainrotSystem = {}

-- Tracking table: uniqueId -> brainrotData
local activeBrainrots = {}

-- Unique ID counter
local brainrotIdCounter = 0

-- Map configuration (matching MapGenerator pathway layout)
local MAP_CENTER = Vector3.new(0, 200, 0)
local PATHWAY_LENGTH = 200             -- Pathway goes from Z=-100 to Z=+100

-- Open air brainrot zone: right past the pathway end, close enough to see
local BRAINROT_ZONE_START_Z = 50       -- Start spawning near the middle/end of pathway
local BRAINROT_ZONE_END_Z = 250        -- Don't go too far out
local BRAINROT_ZONE_WIDTH = 150        -- Spread on X axis
local BRAINROT_ZONE_HEIGHT_MIN = 195   -- Just below pathway level
local BRAINROT_ZONE_HEIGHT_MAX = 220   -- Just above pathway level

-- Settings
local BOB_HEIGHT = 1.5                 -- Max distance up/down from center (studs)
local BRAINROTS_PER_TIER = 5           -- Number of each tier to spawn
local RESPAWN_DELAY_MIN = 30           -- Min seconds until respawn
local RESPAWN_DELAY_MAX = 60           -- Max seconds until respawn

--- Calculate a random spawn position in the open air brainrot zone
--- Higher tiers spawn further out
--- @param tierIndex number - 1-8
--- @return Vector3
local function GetRandomBrainrotPosition(tierIndex)
	-- Higher tiers spawn further out from the pathway
	local tierFraction = (tierIndex - 1) / 7 -- 0 to 1
	local minZ = BRAINROT_ZONE_START_Z + tierFraction * 30 -- Spread tiers out gradually
	local maxZ = minZ + 25 -- Each tier has a 25-stud deep zone

	local z = minZ + math.random() * (maxZ - minZ)
	local x = (math.random() - 0.5) * BRAINROT_ZONE_WIDTH
	local y = BRAINROT_ZONE_HEIGHT_MIN + math.random() * (BRAINROT_ZONE_HEIGHT_MAX - BRAINROT_ZONE_HEIGHT_MIN)

	-- Higher tiers float a bit higher
	y = y + tierIndex * 2

	return Vector3.new(x, y, z)
end

--- Get random respawn delay between min/max
--- @return number - Seconds
local function GetRespawnDelay()
	return RESPAWN_DELAY_MIN + math.random() * (RESPAWN_DELAY_MAX - RESPAWN_DELAY_MIN)
end

--- Start gentle bob animation for a brainrot using math.sin
--- Moves the Body part up/down while other parts follow via welds
--- @param brainrotData table - The brainrot data structure
local function StartBobAnimation(brainrotData)
	task.spawn(function()
		local body = brainrotData.model:FindFirstChild("Body")
		if not body then return end

		local startCFrame = body.CFrame
		local t = math.random() * math.pi * 2  -- Random starting phase

		while body and body.Parent do
			t = t + 0.05
			local bobOffset = math.sin(t) * BOB_HEIGHT
			body.CFrame = startCFrame + Vector3.new(0, bobOffset, 0)
			task.wait(0.03)
		end
	end)
end

--- Initialize the brainrot system
--- Spawns brainrots floating in open air beyond the pathway
function BrainrotSystem.Initialize()
	print("[BrainrotSystem] Initializing floating brainrot collectible system...")

	-- Spawn brainrots for all 8 tiers in the open air
	for tierIndex = 1, 8 do
		local tierConfig = GameConfig.BrainrotTiers[tierIndex]
		if tierConfig then
			for i = 1, BRAINROTS_PER_TIER do
				BrainrotSystem.SpawnSingleBrainrot(tierIndex)
			end
			print("[BrainrotSystem] Spawned " .. BRAINROTS_PER_TIER .. " " .. tierConfig.name .. " brainrots in the sky")
		end
	end

	print("[BrainrotSystem] Initialized with " .. BrainrotSystem.GetActiveBrainrotCount() .. " total brainrots floating in the air")
end

--- Spawn a single brainrot floating in the open air
--- @param tierIndex number - 1-8
function BrainrotSystem.SpawnSingleBrainrot(tierIndex)
	local tierConfig = GameConfig.BrainrotTiers[tierIndex]
	if not tierConfig then return end

	-- Generate unique ID
	brainrotIdCounter = brainrotIdCounter + 1
	local uniqueId = "brainrot_" .. brainrotIdCounter

	-- Get random position in the open air zone
	local spawnPos = GetRandomBrainrotPosition(tierIndex)

	-- Create model via BrainrotModel
	local brainrotModel = BrainrotModel.CreateBrainrotModel(tierConfig, spawnPos)
	brainrotModel.Name = uniqueId

	-- CRITICAL: Anchor all parts (CreateBrainrotModel unanchors at end)
	for _, part in ipairs(brainrotModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Remove any BodyVelocity (static collectibles don't move)
	local body = brainrotModel:FindFirstChild("Body")
	if body then
		local bodyVelocity = body:FindFirstChildOfClass("BodyVelocity")
		if bodyVelocity then
			bodyVelocity:Destroy()
		end
	end

	-- Remove Humanoid (no health/combat)
	local humanoid = brainrotModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:Destroy()
	end

	-- Set display name
	local displayName = BrainrotData.GetRandomBrainrotName(tierConfig.name)
	pcall(function()
		BrainrotModel.UpdateNameTag(brainrotModel, displayName, tierConfig.name)
	end)

	-- Create data structure
	local brainrotData = {
		uniqueId = uniqueId,
		tierName = tierConfig.name,
		tierIndex = tierIndex,
		displayName = displayName,
		money = tierConfig.money,
		model = brainrotModel,
		originalPosition = spawnPos,
		isGrabbed = false,
	}

	-- Store
	activeBrainrots[uniqueId] = brainrotData

	-- Start bob animation (task.spawn with math.sin)
	StartBobAnimation(brainrotData)
end

--- Get the nearest brainrot within radius
--- @param position Vector3
--- @param radius number
--- @return {uniqueId, tierName, tierIndex, displayName, model} or nil
function BrainrotSystem.GetNearestBrainrot(position, radius)
	local nearest = nil
	local nearestDistance = radius

	for uniqueId, brainrotData in pairs(activeBrainrots) do
		-- Only active, not grabbed, in world
		if brainrotData.model and brainrotData.model.Parent and not brainrotData.isGrabbed then
			local body = brainrotData.model:FindFirstChild("Body")
			if body then
				local distance = (body.Position - position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearest = brainrotData
				end
			end
		end
	end

	if nearest then
		return {
			uniqueId = nearest.uniqueId,
			tierName = nearest.tierName,
			tierIndex = nearest.tierIndex,
			displayName = nearest.displayName,
			model = nearest.model,
		}
	end

	return nil
end

--- Grab a brainrot (remove from world, schedule respawn)
--- @param uniqueId string
--- @return {tierName, tierIndex, displayName, money} or nil
function BrainrotSystem.GrabBrainrot(uniqueId)
	local brainrotData = activeBrainrots[uniqueId]
	if not brainrotData or brainrotData.isGrabbed then
		return nil
	end

	-- Mark as grabbed
	brainrotData.isGrabbed = true

	-- Remove from world
	if brainrotData.model and brainrotData.model.Parent then
		brainrotData.model.Parent = nil
	end

	-- Schedule respawn
	BrainrotSystem.RespawnBrainrot(uniqueId)

	-- Return loot data
	return {
		tierName = brainrotData.tierName,
		tierIndex = brainrotData.tierIndex,
		displayName = brainrotData.displayName,
		money = brainrotData.money,
	}
end

--- Respawn a brainrot after delay
--- @param uniqueId string
function BrainrotSystem.RespawnBrainrot(uniqueId)
	local brainrotData = activeBrainrots[uniqueId]
	if not brainrotData then
		return
	end

	local respawnDelay = GetRespawnDelay()

	task.delay(respawnDelay, function()
		if not activeBrainrots[uniqueId] then
			return
		end

		local tierConfig = GameConfig.BrainrotTiers[brainrotData.tierIndex]
		if not tierConfig then
			return
		end

		-- Clean up old model
		if brainrotData.model and brainrotData.model.Parent then
			pcall(function()
				brainrotData.model:Destroy()
			end)
		end

		-- New random position (don't always respawn in same spot)
		local newPos = GetRandomBrainrotPosition(brainrotData.tierIndex)
		brainrotData.originalPosition = newPos

		-- Create new model
		local newModel = BrainrotModel.CreateBrainrotModel(tierConfig, newPos)
		newModel.Name = uniqueId

		-- Anchor all parts
		for _, part in ipairs(newModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		-- Remove BodyVelocity
		local body = newModel:FindFirstChild("Body")
		if body then
			local bodyVelocity = body:FindFirstChildOfClass("BodyVelocity")
			if bodyVelocity then
				bodyVelocity:Destroy()
			end
		end

		-- Remove Humanoid
		local humanoid = newModel:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:Destroy()
		end

		-- Update name tag
		pcall(function()
			BrainrotModel.UpdateNameTag(newModel, brainrotData.displayName, brainrotData.tierName)
		end)

		-- Update brainrot data
		brainrotData.model = newModel
		brainrotData.isGrabbed = false

		-- Start bob animation
		StartBobAnimation(brainrotData)
	end)
end

--- Get active (non-grabbed) brainrot count
--- @return number
function BrainrotSystem.GetActiveBrainrotCount()
	local count = 0
	for _, brainrotData in pairs(activeBrainrots) do
		if not brainrotData.isGrabbed then
			count = count + 1
		end
	end
	return count
end

-- Track initialization state to prevent double-init
local initialized = false
local originalInit = BrainrotSystem.Initialize

BrainrotSystem.Initialize = function()
	if initialized then
		print("[BrainrotSystem] Already initialized, skipping")
		return
	end
	initialized = true
	originalInit()
end

-- Export via global
_G.BrainrotSystem = BrainrotSystem

-- Wait for map to be generated, then initialize
task.spawn(function()
	-- Wait for GameMap to exist (MapGenerator creates it)
	local gameMap = workspace:WaitForChild("GameMap", 30)
	if gameMap then
		task.wait(1) -- Brief delay for map to fully generate
	end
	BrainrotSystem.Initialize()
end)

print("[BrainrotSystem] Exported to _G.BrainrotSystem")
