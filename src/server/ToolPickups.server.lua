-- ToolPickups.server.lua
-- Tool pickup system for build phase
-- Spawns and manages engine and fuel canister pickups around the map
-- Handles pickup collection and respawning

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local InventorySystem = require(script.Parent:WaitForChild("InventorySystem"))
local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerData"))

local ToolPickups = {}

-- Active pickups in the world
-- Format: { [pickup] = { itemType = "engine"/"fuelCanister", respawnTime = number } }
local activePickups = {}

-- Pickup spawn locations around the map
local pickupSpawnPoints = {}

-- Visual models for pickups (stored in ServerStorage or created dynamically)
local toolModels = {
	engine = nil,
	fuelCanister = nil,
}

-- Configuration
local PICKUP_RESPAWN_TIME = 30  -- Seconds before pickup respawns
local MAP_CENTER = Vector3.new(0, 0, 0)
local PICKUP_SPAWN_RADIUS = GameConfig.Map.SIZE * 0.6  -- Spawn in middle area of map
local SAFE_ZONE_RADIUS = GameConfig.Map.SAFE_ZONE_RADIUS * 1.2  -- Avoid immediate spawn zone
local PICKUP_HEIGHT = 5  -- Height above ground for pickups

-- Initialize tool pickup system
function ToolPickups.Initialize()
	print("[ToolPickups] Initializing tool pickup system...")

	-- Generate spawn points distributed around the map
	ToolPickups._GenerateSpawnPoints()

	-- Setup detection for pickups
	ToolPickups._SetupPickupDetection()

	print("[ToolPickups] System initialized with " .. #pickupSpawnPoints .. " spawn points")
end

-- Generate spawn points for pickups in a circular pattern
function ToolPickups._GenerateSpawnPoints()
	local spawnCount = 12  -- 12 pickup spawn locations around the map
	local angleStep = (math.pi * 2) / spawnCount

	for i = 1, spawnCount do
		local angle = (i - 1) * angleStep

		-- Create spawn point at radius between SAFE_ZONE and PICKUP_SPAWN_RADIUS
		local radius = SAFE_ZONE_RADIUS + (math.random() * (PICKUP_SPAWN_RADIUS - SAFE_ZONE_RADIUS))

		local spawnPos = MAP_CENTER + Vector3.new(
			math.cos(angle) * radius,
			PICKUP_HEIGHT,
			math.sin(angle) * radius
		)

		-- Add slight randomness to position
		spawnPos = spawnPos + Vector3.new(
			(math.random() - 0.5) * 20,
			0,
			(math.random() - 0.5) * 20
		)

		table.insert(pickupSpawnPoints, spawnPos)
	end
end

-- Setup pickup detection using raycasting or TouchInterest
function ToolPickups._SetupPickupDetection()
	-- Wait for RemoteEvent created by AAA_Setup
	local pickupEvent = ReplicatedStorage:WaitForChild("PickupCollected")

	-- Server-side detection: listen for clients claiming to pick up items
	pickupEvent.OnServerEvent:Connect(function(player, pickupId)
		ToolPickups._HandlePickupCollection(player, pickupId)
	end)
end

-- Spawn a single pickup at a random spawn point
-- @param itemType string - "engine" or "fuelCanister"
function ToolPickups.SpawnPickup(itemType)
	-- Select random spawn point
	local spawnPos = pickupSpawnPoints[math.random(1, #pickupSpawnPoints)]

	-- Create pickup model
	local pickup = ToolPickups._CreatePickupModel(itemType, spawnPos)

	-- Store pickup data
	activePickups[pickup] = {
		itemType = itemType,
		spawnPos = spawnPos,
		lastPickupTime = 0,
	}

	return pickup
end

-- Create a visual model for a pickup
-- @param itemType string - "engine" or "fuelCanister"
-- @param position Vector3 - Spawn position
-- @return Instance - The pickup model
function ToolPickups._CreatePickupModel(itemType, position)
	local pickup = Instance.new("Part")
	pickup.Name = itemType .. "Pickup"
	pickup.Shape = Enum.PartType.Ball
	pickup.Size = Vector3.new(1.5, 1.5, 1.5)
	pickup.CanCollide = false
	pickup.CFrame = CFrame.new(position)
	pickup.TopSurface = Enum.SurfaceType.Smooth
	pickup.BottomSurface = Enum.SurfaceType.Smooth

	-- Visual differentiation by color and emissive property
	if itemType == "engine" then
		pickup.Color = Color3.fromRGB(255, 165, 0)  -- Orange for engines
		pickup.Material = Enum.Material.Neon
	else -- fuelCanister
		pickup.Color = Color3.fromRGB(0, 200, 255)  -- Cyan for fuel
		pickup.Material = Enum.Material.Neon
	end

	-- Add glow effect
	pickup.TopSurface = Enum.SurfaceType.Smooth
	pickup.BottomSurface = Enum.SurfaceType.Smooth

	-- Create a humanoid for detection (optional, for touch events)
	local touchDetector = Instance.new("Part")
	touchDetector.Name = "Detector"
	touchDetector.Transparency = 1
	touchDetector.CanCollide = false
	touchDetector.Size = Vector3.new(3, 3, 3)
	touchDetector.Parent = pickup
	touchDetector.TopSurface = Enum.SurfaceType.Smooth
	touchDetector.BottomSurface = Enum.SurfaceType.Smooth

	-- Add touch detection
	local debounce = {}
	touchDetector.Touched:Connect(function(hit)
		local player = Players:FindFirstChild(hit.Parent.Name)
		if player and not debounce[player] then
			debounce[player] = true
			task.wait(0.5)  -- Debounce time
			debounce[player] = nil
			ToolPickups._HandlePickupCollection(player, pickup)
		end
	end)

	-- Floating animation using BodyVelocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, 0, 0)  -- Just for rotation, not movement
	bodyVelocity.Parent = pickup

	-- Add rotating animation (client-side would be better, but this works)
	local rotationSpeed = math.rad(180)  -- Degrees per second

	-- Floating up and down
	local floatAmount = 0.5
	local floatSpeed = 2
	local startPos = position
	local elapsedTime = 0

	-- Animate using a loop
	task.spawn(function()
		while activePickups[pickup] do
			elapsedTime = elapsedTime + 0.016  -- ~60 FPS

			-- Floating animation
			local newY = startPos.Y + math.sin(elapsedTime * floatSpeed) * floatAmount
			local newPos = Vector3.new(startPos.X, newY, startPos.Z)
			pickup.Position = newPos

			-- Rotation
			pickup.CFrame = pickup.CFrame * CFrame.Angles(0, rotationSpeed * 0.016, 0)

			task.wait(0.016)
		end
	end)

	-- Parent to workspace to make visible
	pickup.Parent = workspace

	return pickup
end

-- Handle pickup collection by a player
-- @param player Player
-- @param pickup Instance or string (pickup part or ID)
function ToolPickups._HandlePickupCollection(player, pickup)
	if not pickup or not activePickups[pickup] then
		return
	end

	local itemType = activePickups[pickup].itemType
	local spawnPos = activePickups[pickup].spawnPos

	-- Remove the pickup from world
	local pickupCopy = pickup
	activePickups[pickup] = nil
	pickupCopy:Destroy()

	-- Convert item type to inventory format
	local inventoryType = itemType == "engine" and PlayerData.ItemType.ENGINE or PlayerData.ItemType.FUEL_CANISTER

	-- Add item to player inventory
	if InventorySystem.AddItem(player, inventoryType, 1) then
		-- Success - notify client of pickup
		local pickupEvent = ReplicatedStorage:FindFirstChild("PickupCollected")
		if pickupEvent then
			pickupEvent:FireClient(player, itemType)
		end

		print("[ToolPickups] Player " .. player.Name .. " collected " .. itemType)

		-- Schedule respawn of this pickup
		task.delay(PICKUP_RESPAWN_TIME, function()
			ToolPickups.SpawnPickup(itemType)
		end)
	end
end

-- Spawn initial set of pickups at game start
-- @param engineCount number - How many engines to spawn
-- @param fuelCount number - How many fuel canisters to spawn
function ToolPickups.SpawnInitialPickups(engineCount, fuelCount)
	print("[ToolPickups] Spawning initial pickups: " .. engineCount .. " engines, " .. fuelCount .. " fuel canisters")

	for i = 1, engineCount do
		task.wait(0.1)  -- Slight delay to spread spawning
		ToolPickups.SpawnPickup("engine")
	end

	for i = 1, fuelCount do
		task.wait(0.1)
		ToolPickups.SpawnPickup("fuelCanister")
	end
end

-- Clear all pickups from the world
function ToolPickups.ClearAllPickups()
	for pickup, _ in pairs(activePickups) do
		if pickup and pickup.Parent then
			pickup:Destroy()
		end
	end
	activePickups = {}
	print("[ToolPickups] All pickups cleared")
end

-- Get count of active pickups
-- @return number
function ToolPickups.GetActivePickupCount()
	return table.getn(activePickups)
end

-- Get active pickups by type
-- @param itemType string - "engine" or "fuelCanister"
-- @return number
function ToolPickups.GetPickupCountByType(itemType)
	local count = 0
	for pickup, data in pairs(activePickups) do
		if data.itemType == itemType then
			count = count + 1
		end
	end
	return count
end

return ToolPickups
