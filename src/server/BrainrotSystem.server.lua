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

-- Map configuration (matching MapGenerator)
local MAP_CENTER = Vector3.new(0, 200, 0)
local BRAINROT_ISLAND_RADIUS_MIN = 300
local BRAINROT_ISLAND_RADIUS_MAX = 400

-- Settings
local BOB_HEIGHT = 1.5                 -- Max distance up/down from center (studs)
local SPAWN_HEIGHT_MIN = 8             -- Min distance above island surface
local SPAWN_HEIGHT_MAX = 15            -- Max distance above island surface
local SPAWN_RADIUS = 25                -- Horizontal scatter radius (studs)
local BRAINROT_COUNT_PER_ISLAND = 4    -- Number to spawn on each island (3-5 per spec)
local RESPAWN_DELAY_MIN = 30           -- Min seconds until respawn
local RESPAWN_DELAY_MAX = 60           -- Max seconds until respawn

--- Calculate fallback island position if MapGenerator islands don't exist
--- @param tierIndex number - 1-8
--- @return Vector3
local function GetIslandPositionFallback(tierIndex)
	local angle = (tierIndex - 1) / 8 * math.pi * 2
	local radiusOffset = (tierIndex - 1) * ((BRAINROT_ISLAND_RADIUS_MAX - BRAINROT_ISLAND_RADIUS_MIN) / 7)
	local radius = BRAINROT_ISLAND_RADIUS_MIN + radiusOffset
	local height = MAP_CENTER.Y + (tierIndex - 1) * 10

	local x = MAP_CENTER.X + math.cos(angle) * radius
	local z = MAP_CENTER.Z + math.sin(angle) * radius

	return Vector3.new(x, height, z)
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
--- Spawns brainrots on all 8 tier-themed islands
function BrainrotSystem.Initialize()
	print("[BrainrotSystem] Initializing static floating collectible system...")

	-- Spawn on all 8 islands
	for tierIndex = 1, 8 do
		local tierConfig = GameConfig.BrainrotTiers[tierIndex]
		if tierConfig then
			-- Try to find island from MapGenerator
			local islandPosition = nil
			local gameMap = workspace:FindFirstChild("GameMap")
			if gameMap then
				local structures = gameMap:FindFirstChild("Structures")
				if structures then
					local brainrotIslands = structures:FindFirstChild("BrainrotIslands")
					if brainrotIslands then
						local islandModel = brainrotIslands:FindFirstChild("BrainrotIsland_" .. tierIndex)
						if islandModel then
							-- Try GetBoundingBox for Models, fall back to finding a BasePart
							local ok, result = pcall(function()
								local cf, size = islandModel:GetBoundingBox()
								return cf.Position
							end)
							if ok and result then
								islandPosition = result
							else
								-- Find first BasePart in island
								for _, part in ipairs(islandModel:GetDescendants()) do
									if part:IsA("BasePart") then
										islandPosition = part.Position
										break
									end
								end
							end
							if islandPosition then
								print("[BrainrotSystem] Found BrainrotIsland_" .. tierIndex .. " at " .. tostring(islandPosition))
							end
						end
					end
				end
			end

			-- Fallback to calculated position
			if not islandPosition then
				islandPosition = GetIslandPositionFallback(tierIndex)
				print("[BrainrotSystem] Using fallback position for tier " .. tierIndex .. " at " .. tostring(islandPosition))
			end

			BrainrotSystem.SpawnBrainrotsOnIsland(islandPosition, tierIndex)
		end
	end

	print("[BrainrotSystem] Initialized with " .. BrainrotSystem.GetActiveBrainrotCount() .. " total brainrots")
end

--- Spawn 3-5 brainrots on a specific island
--- @param islandPosition Vector3 - Island center
--- @param tierIndex number - 1-8
function BrainrotSystem.SpawnBrainrotsOnIsland(islandPosition, tierIndex)
	local tierConfig = GameConfig.BrainrotTiers[tierIndex]
	if not tierConfig then return end

	local count = BRAINROT_COUNT_PER_ISLAND

	for i = 1, count do
		BrainrotSystem.SpawnSingleBrainrot(tierIndex, islandPosition)
	end
end

--- Spawn a single brainrot at a specific tier location
--- @param tierIndex number - 1-8
--- @param islandPosition Vector3 - Island center
function BrainrotSystem.SpawnSingleBrainrot(tierIndex, islandPosition)
	local tierConfig = GameConfig.BrainrotTiers[tierIndex]
	if not tierConfig then return end

	-- Generate unique ID
	brainrotIdCounter = brainrotIdCounter + 1
	local uniqueId = "brainrot_" .. brainrotIdCounter

	-- Calculate spawn position: scattered above island
	local randomAngle = math.random() * math.pi * 2
	local randomDist = math.random() * SPAWN_RADIUS
	local spawnHeight = SPAWN_HEIGHT_MIN + math.random() * (SPAWN_HEIGHT_MAX - SPAWN_HEIGHT_MIN)

	local offsetX = math.cos(randomAngle) * randomDist
	local offsetZ = math.sin(randomAngle) * randomDist
	local spawnPos = islandPosition + Vector3.new(offsetX, spawnHeight, offsetZ)

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

		-- Create new model
		local newModel = BrainrotModel.CreateBrainrotModel(tierConfig, brainrotData.originalPosition)
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
		gameMap:WaitForChild("Structures", 15)
		task.wait(1) -- Extra delay for islands to fully generate
	end
	BrainrotSystem.Initialize()
end)

print("[BrainrotSystem] Exported to _G.BrainrotSystem")
