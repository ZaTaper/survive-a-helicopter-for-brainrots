--[[
	AdminClient.client.lua
	Client-side admin panel loader for "Survive a Helicopter for Brainrots"

	Responsibilities:
	- Verify the local player is the admin (googoo9876543)
	- Load and initialize the AdminPanel GUI if admin
	- Handle F9 keyboard shortcut to toggle panel
	- Manage admin panel visibility lifecycle

	SECURITY NOTE:
	- Client-side UI only checks username for UX
	- Server ALWAYS validates admin status before executing commands
	- Admin usernames are verified by GameConfig.ADMINS
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Admin username to check
local ADMIN_USERNAME = "googoo9876543"

--[[
	Checks if the current player is an admin
	@return: boolean - true if player is in admin list
]]
local function IsPlayerAdmin()
	for _, adminName in ipairs(GameConfig.ADMINS) do
		if localPlayer.Name == adminName then
			return true
		end
	end
	return false
end

--[[
	Main initialization function
]]
local function Initialize()
	-- Security check: verify this player is an admin
	if not IsPlayerAdmin() then
		print("Player " .. localPlayer.Name .. " is not an admin. Admin panel not loaded.")
		return
	end

	print("Admin detected: " .. localPlayer.Name .. ". Loading admin panel...")

	-- Wait for required services and modules
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	-- Load the AdminPanel module
	local AdminPanel = require(ReplicatedStorage:WaitForChild("AdminPanel"))

	-- Initialize the admin panel UI
	AdminPanel:Init()

	-- Setup F9 keyboard shortcut for toggling panel
	local panelOpen = false
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Only respond to F9 if not typing in a chat/textbox
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.F9 then
			AdminPanel:Toggle()
			panelOpen = not panelOpen
			print("Admin panel toggled: " .. (panelOpen and "OPEN" or "CLOSED"))
		end
	end)

	print("Admin panel loaded successfully! Press F9 to toggle.")
end

-- Start initialization when the game loads
Initialize()
