--[[
	AdminClient.client.lua
	Client-side admin panel loader for "Survive a Helicopter for Brainrots"

	Responsibilities:
	- Verify the local player is the admin (googoo9876543)
	- Load and initialize the AdminPanel GUI if admin
	- Handle F9 keyboard shortcut to toggle the panel
	- Listen for server announcements
	- Manage admin panel visibility and lifecycle

	SECURITY NOTE:
	- Client-side UI only checks username for UX purposes
	- Server ALWAYS validates admin status before executing commands
	- NO commands are executed without server-side verification
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

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
	Show announcement on screen
]]
local function ShowAnnouncement(message)
	print("[ADMIN ANNOUNCEMENT] " .. message)
	-- Create a temporary TextLabel to show the announcement
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local announcementGui = Instance.new("ScreenGui")
	announcementGui.Name = "AnnouncementGui"
	announcementGui.ResetOnSpawn = false
	announcementGui.Parent = playerGui

	local announcementLabel = Instance.new("TextLabel")
	announcementLabel.Size = UDim2.new(1, 0, 0, 60)
	announcementLabel.Position = UDim2.new(0, 0, 0.4, -30)
	announcementLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	announcementLabel.BackgroundTransparency = 0.2
	announcementLabel.BorderColor3 = Color3.fromRGB(200, 100, 50)
	announcementLabel.BorderSizePixel = 2
	announcementLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
	announcementLabel.TextSize = 24
	announcementLabel.Font = Enum.Font.GothamBlack
	announcementLabel.Text = message
	announcementLabel.Parent = announcementGui

	-- Auto-remove after 5 seconds
	task.wait(5)
	announcementGui:Destroy()
end

--[[
	Main initialization function
]]
local function Initialize()
	-- Security check: verify this player is an admin
	if not IsPlayerAdmin() then
		print("[AdminClient] Player '" .. localPlayer.Name .. "' is not an admin. Admin panel not loaded.")
		return
	end

	print("[AdminClient] Admin detected: " .. localPlayer.Name)
	print("[AdminClient] Loading admin panel...")

	-- Load the AdminPanel module from GUI folder
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local AdminPanel = require(playerGui:WaitForChild("GUI"):WaitForChild("AdminPanel"))

	-- Initialize the admin panel UI
	AdminPanel:Init()

	-- Setup F9 keyboard shortcut for toggling panel
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Don't respond if user is typing in a textbox/chatbox
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.F9 then
			AdminPanel:Toggle()
			print("[AdminClient] Admin panel toggled")
		end
	end)

	-- Listen for server announcements
	local AdminEvents = ReplicatedStorage:WaitForChild("AdminEvents")
	local announcementEvent = AdminEvents:WaitForChild("ReceiveAnnouncement")
	announcementEvent.OnClientEvent:Connect(function(message)
		ShowAnnouncement(message)
	end)

	print("[AdminClient] Admin panel ready! Press F9 to open.")
	print("[AdminClient] All commands are validated server-side.")
end

-- Initialize when the game loads
Initialize()
