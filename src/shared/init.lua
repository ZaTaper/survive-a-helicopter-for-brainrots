-- Shared module loader - used by ReplicatedStorage.Shared
-- In Rojo, this file is at src/shared/init.lua which becomes ReplicatedStorage/Shared

local Shared = {}

-- Load shared modules from the same folder
Shared.GameConfig = require(script:WaitForChild("GameConfig"))
Shared.PlayerData = require(script:WaitForChild("PlayerData"))
Shared.GameState = require(script:WaitForChild("GameState"))
Shared.HelicopterData = require(script:WaitForChild("HelicopterData"))
Shared.BrainrotData = require(script:WaitForChild("BrainrotData"))
Shared.MusicData = require(script:WaitForChild("MusicData"))

return Shared
