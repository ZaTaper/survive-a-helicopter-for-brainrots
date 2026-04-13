-- BaseSystem.server.lua
-- Server-side base management system
-- Manages player bases, positioning, brainrot collections, and passive money generation
-- Integrates with MoneySystem for earnings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local BaseModel = require(ServerStorage:WaitForChild("Storage"):WaitForChild("BaseModel"))

local BaseSystem = {}

-- Storage for player bases and collected brainrots
local playerBases = {} -- Format: { [player] = baseFolder }
local playerCollectedBrainrots = {} -- Format: { [player] = { tierIndex = count, ... } }
local floatingBrainrots = {} -- Format: { [player] = { [tierIndex] = count } }

-- Base positioning configuration
local BASE_CONFIG = {
	SPAWN_RADIUS = 200,  -- Distance from center to place bases
	BASE_SIZE = 30,      -- Size of each base platform
	BASES_PER_RING = 8,  -- Number of bases in a circle around spawn
	HEIGHT = 200,        -- Height above ground (sky map is at Y=200)
	PASSIVE_MONEY_TICK = 10, -- Seconds between passive money generation
}

-- Wait for RemoteEvents created by AAA_Setup
local baseUpdatedEvent = ReplicatedStorage:WaitForChild("BaseUpdated")
local getBaseInfoFunction = ReplicatedStorage:WaitForChild("GetBaseInfo")

-- Helper function defined before use: Calculate base position in circular layout
-- @param playerIndex number - Index of the player (starting from 1)
-- @return Vector3 - The position for this player's base
local function CalculateBasePosition(playerIndex)
	local baseIndex = (playerIndex - 1) % BASE_CONFIG.BASES_PER_RING
	local angle = (baseIndex / BASE_CONFIG.BASES_PER_RING) * (2 * math.pi)
	local x = math.cos(angle) * BASE_CONFIG.SPAWN_RADIUS
	local z = math.sin(angle) * BASE_CONFIG.SPAWN_RADIUS
	local y = BASE_CONFIG.HEIGHT

	return Vector3.new(x, y, z)
end

-- Helper function: Get all current player count
-- @return number - Count of players currently in game
local function GetPlayerIndex(player)
	local index = 0
	for _, p in ipairs(Players:GetPlayers()) do
		index = index + 1
		if p == player then
			return index
		end
	end
	return index
end

-- Helper function: Calculate passive money earned from collected brainrots
-- @param player Player - The player
-- @return number - Total money to award this tick
local function CalculatePassiveMoneyEarned(player)
	if not playerCollectedBrainrots[player] then
		return 0
	end

	local totalMoney = 0
	local collected = playerCollectedBrainrots[player]

	-- Get MoneySystem from _G (since it's a .server.lua and cannot be required)
	if not _G.MoneySystem then
		return 0
	end

	-- Iterate through each tier with collected brainrots
	for tierIndex, count in pairs(collected) do
		if tierIndex >= 1 and tierIndex <= #GameConfig.BrainrotTiers then
			local tierConfig = GameConfig.BrainrotTiers[tierIndex]
			local passiveRatePerTick = tierConfig.money / 5 -- Passive rate is 1/5 of kill rate
			totalMoney = totalMoney + (passiveRatePerTick * count)
		end
	end

	return math.floor(totalMoney)
end

-- Helper function: Create a floating brainrot visual at the display area
-- @param player Player - The player
-- @param tierIndex number - The tier being collected
-- @return Instance - The created model, or nil if failed
local function CreateFloatingBrainrotVisual(player, tierIndex)
	if not playerBases[player] or tierIndex < 1 or tierIndex > 8 then
		return nil
	end

	local displayPos = BaseModel.GetFloatingDisplayPosition(playerBases[player])
	if not displayPos then
		return nil
	end

	local tier = GameConfig.BrainrotTiers[tierIndex]
	if not tier then
		return nil
	end

	-- Create a simple model representing the collected brainrot
	local model = Instance.new("Model")
	model.Name = tier.name

	-- Create a simple sphere as the visual
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(2, 2, 2)
	part.Color = tier.color or Color3.fromRGB(255, 255, 255)
	part.Material = Enum.Material.Neon
	part.CanCollide = false

	-- Calculate position based on grid pattern
	local count = floatingBrainrots[player] and floatingBrainrots[player][tierIndex] or 0
	local row = math.floor(count / 4) -- 4 brainrots per row
	local col = count % 4
	local xOffset = (col - 1.5) * 3 -- Spread 3 studs apart horizontally
	local zOffset = row * 3 -- Spread 3 studs apart vertically
	local yOffset = 5 + (tierIndex - 1) * 0.5 -- Slightly higher for rarer tiers

	part.CFrame = CFrame.new(displayPos + Vector3.new(xOffset, yOffset, zOffset))
	part.Anchored = true
	part.Parent = model

	-- Add rotation
	local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
	bodyAngularVelocity.AngularVelocity = Vector3.new(math.random(-3, 3), math.random(2, 4), math.random(-3, 3))
	bodyAngularVelocity.Parent = part

	model.Parent = playerBases[player]

	-- Track floating brainrot
	if not floatingBrainrots[player] then
		floatingBrainrots[player] = {}
	end
	floatingBrainrots[player][tierIndex] = (floatingBrainrots[player][tierIndex] or 0) + 1

	-- Brainrot visuals are permanent - they stay until player leaves

	return model
end

-- Helper function: Start passive money generation loop for all players
-- Runs every 10 seconds and gives money based on collected brainrots
local function StartPassiveMoneyLoop()
	while true do
		task.wait(BASE_CONFIG.PASSIVE_MONEY_TICK)

		for _, player in ipairs(Players:GetPlayers()) do
			if player:IsDescendantOf(Players) then
				local passiveMoney = CalculatePassiveMoneyEarned(player)
				if passiveMoney > 0 and _G.MoneySystem then
					_G.MoneySystem.AddMoney(player, passiveMoney, "Passive brainrot earnings")
				end
			end
		end
	end
end

-- Helper function: Try to find a pre-built base from MapGenerator
-- @param playerIndex number - The player index for base assignment
-- @return Instance - The pre-built base folder, or nil if not found
local function FindPreBuiltBase(playerIndex)
	local gameMap = workspace:FindFirstChild("GameMap")
	if not gameMap then return nil end
	local structures = gameMap:FindFirstChild("Structures")
	if not structures then return nil end
	local playerBasesFolder = structures:FindFirstChild("PlayerBases")
	if not playerBasesFolder then return nil end

	-- Look for base by index attribute
	for _, child in ipairs(playerBasesFolder:GetChildren()) do
		if child:IsA("Model") or child:IsA("Folder") then
			local baseIndex = child:GetAttribute("BaseIndex")
			if baseIndex == playerIndex then
				return child
			end
		end
	end

	-- Fallback: get by child order
	local children = playerBasesFolder:GetChildren()
	if playerIndex <= #children then
		return children[playerIndex]
	end
	return nil
end

-- Create a base for a player
-- @param player Player - The player to create a base for
-- @return Instance - The base folder, or nil if failed
function BaseSystem.CreatePlayerBase(player)
	if playerBases[player] then
		return playerBases[player] -- Already has a base
	end

	-- Get a unique position for this player
	local playerIndex = GetPlayerIndex(player)

	-- Try to find a pre-built base from MapGenerator first
	local baseFolder = FindPreBuiltBase(playerIndex)

	-- If no pre-built base, create one at sky height
	if not baseFolder then
		local basePosition = CalculateBasePosition(playerIndex)
		baseFolder = BaseModel.CreateBase(player, basePosition)

		if baseFolder then
			print("[BaseSystem] Created new base for " .. player.Name .. " at position " .. tostring(basePosition))
		else
			warn("[BaseSystem] Failed to create base for " .. player.Name)
			return nil
		end
	else
		print("[BaseSystem] Using pre-built base for " .. player.Name)
	end

	playerBases[player] = baseFolder
	playerCollectedBrainrots[player] = {} -- Initialize empty brainrot collection
	return baseFolder
end

-- Get a player's base
-- @param player Player - The player
-- @return Instance - The base folder, or nil if doesn't exist
function BaseSystem.GetPlayerBase(player)
	return playerBases[player]
end

-- Add a collected brainrot to a player's base
-- @param player Player - The player
-- @param brainrotTierIndex number - Index of the brainrot tier (1-8)
-- @return boolean - Success
function BaseSystem.AddCollectedBrainrot(player, brainrotTierIndex)
	if not playerBases[player] or not playerCollectedBrainrots[player] then
		return false
	end

	if brainrotTierIndex < 1 or brainrotTierIndex > #GameConfig.BrainrotTiers then
		return false
	end

	-- Track this brainrot in the collection
	if not playerCollectedBrainrots[player][brainrotTierIndex] then
		playerCollectedBrainrots[player][brainrotTierIndex] = 0
	end
	playerCollectedBrainrots[player][brainrotTierIndex] = playerCollectedBrainrots[player][brainrotTierIndex] + 1

	-- Notify client of base update
	baseUpdatedEvent:FireClient(player, {
		action = "brainrotAdded",
		tierIndex = brainrotTierIndex,
		tierName = GameConfig.BrainrotTiers[brainrotTierIndex].name,
		totalCollected = playerCollectedBrainrots[player][brainrotTierIndex],
	})

	print("[BaseSystem] " .. player.Name .. " collected " .. GameConfig.BrainrotTiers[brainrotTierIndex].name .. " brainrot")
	return true
end

-- Get collected brainrots for a player
-- @param player Player - The player
-- @return table - Dictionary of { tierIndex = count, ... }
function BaseSystem.GetCollectedBrainrots(player)
	if not playerCollectedBrainrots[player] then
		return {}
	end
	return playerCollectedBrainrots[player]
end

-- Get total passive income per tick for a player
-- @param player Player - The player
-- @return number - Total passive money earned per tick
function BaseSystem.GetTotalPassiveIncome(player)
	return CalculatePassiveMoneyEarned(player)
end

-- Check if a position is within a player's base area
-- @param position Vector3 - The position to check
-- @param player Player - The player who owns the base
-- @return boolean - True if position is in player's base
function BaseSystem.IsInPlayerBase(position, player)
	local base = playerBases[player]
	if not base then
		return false
	end

	-- Find base center position from HexagonalFloor or any child Part
	local baseCenter = nil

	-- Try HexagonalFloor first (MapAssets pre-built bases)
	local hexFloor = base:FindFirstChild("HexagonalFloor")
	if hexFloor then
		local firstSegment = hexFloor:FindFirstChild("HexSegment_1")
		if firstSegment then
			baseCenter = firstSegment.Position
		end
	end

	-- Fallback: find any Part descendant
	if not baseCenter then
		for _, child in ipairs(base:GetDescendants()) do
			if child:IsA("BasePart") then
				baseCenter = child.Position
				break
			end
		end
	end

	if not baseCenter then
		return false
	end

	-- Check if position is within the base area (use horizontal distance only)
	local dx = position.X - baseCenter.X
	local dz = position.Z - baseCenter.Z
	local horizontalDistance = math.sqrt(dx * dx + dz * dz)
	return horizontalDistance <= (BASE_CONFIG.BASE_SIZE / 2 + 10) -- 10 stud margin
end

-- Get the landing pad position for a player's base
-- @param player Player - The player
-- @return Vector3 - The landing pad position, or nil if base doesn't exist
function BaseSystem.GetLandingPadPosition(player)
	local base = playerBases[player]
	if not base then
		return nil
	end

	return BaseModel.GetBuildingPadPosition(base)
end

-- Get the brainrot display area position for a player's base
-- @param player Player - The player
-- @return Vector3 - The display area position, or nil if base doesn't exist
function BaseSystem.GetDisplayAreaPosition(player)
	local base = playerBases[player]
	if not base then
		return nil
	end

	return BaseModel.GetFloatingDisplayPosition(base)
end

-- Add a collected brainrot visual to the display area
-- @param player Player - The player
-- @param tierIndex number - Index of the tier collected (1-8)
-- @return boolean - Success
function BaseSystem.AddFloatingBrainrot(player, tierIndex)
	if not playerBases[player] then
		return false
	end

	local model = CreateFloatingBrainrotVisual(player, tierIndex)
	return model ~= nil
end

-- Clean up a player's base when they leave
-- @param player Player - The player
function BaseSystem.CleanupPlayerBase(player)
	local base = playerBases[player]
	if base then
		base:Destroy()
		playerBases[player] = nil
		playerCollectedBrainrots[player] = nil
		print("[BaseSystem] Cleaned up base for " .. player.Name)
	end
end

-- RemoteFunction handler: Get base info from client
getBaseInfoFunction.OnServerInvoke = function(player)
	local base = playerBases[player]
	if not base then
		return nil
	end

	-- Find base center from HexagonalFloor or any Part
	local baseCenter = nil
	local hexFloor = base:FindFirstChild("HexagonalFloor")
	if hexFloor then
		local firstSegment = hexFloor:FindFirstChild("HexSegment_1")
		if firstSegment then
			baseCenter = firstSegment.Position
		end
	end
	if not baseCenter then
		for _, child in ipairs(base:GetDescendants()) do
			if child:IsA("BasePart") then
				baseCenter = child.Position
				break
			end
		end
	end
	if not baseCenter then
		return nil
	end

	return {
		basePosition = baseCenter,
		baseSize = BASE_CONFIG.BASE_SIZE,
		baseRadius = BASE_CONFIG.BASE_SIZE / 2,
		collectedBrainrots = BaseSystem.GetCollectedBrainrots(player),
	}
end

-- Initialize bases when players join
Players.PlayerAdded:Connect(function(player)
	task.wait(0.5) -- Brief delay to ensure player is fully loaded
	BaseSystem.CreatePlayerBase(player)
end)

-- Clean up bases when players leave
Players.PlayerRemoving:Connect(function(player)
	BaseSystem.CleanupPlayerBase(player)
end)

-- Start the passive money generation loop
task.spawn(StartPassiveMoneyLoop)

-- Debug: Print all active bases and collections every 30 seconds
local function DebugPrintBases()
	while true do
		task.wait(30)
		local count = 0
		for player in pairs(playerBases) do
			if player:IsDescendantOf(Players) then
				count = count + 1
				local collected = playerCollectedBrainrots[player] or {}
				local brainrotCount = 0
				for _ in pairs(collected) do
					brainrotCount = brainrotCount + 1
				end
				print("[BaseSystem] " .. player.Name .. " - " .. brainrotCount .. " unique brainrot types collected")
			end
		end
		print("[BaseSystem] Active bases: " .. count)
	end
end

task.spawn(DebugPrintBases)

-- Export to _G so other server scripts can access it
_G.BaseSystem = BaseSystem

return BaseSystem
