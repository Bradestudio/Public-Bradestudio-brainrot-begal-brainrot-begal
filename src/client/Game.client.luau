-- BRAINROT BEGAL — client bootstrap.
-- Builds the HUD, listens for the server's state, wave and notification
-- events, and binds the keys: F slaps a nearby thief, L locks your base,
-- R asks for a rebirth. Catching and stealing use the prompts on the
-- brainrots themselves (hold E), which the server validates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local HUD = require(script:WaitForChild("HUD"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hud = HUD.build(playerGui, remotes)

remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(state)
	hud.setState(state)
end)

remotes:WaitForChild("WaveUpdate").OnClientEvent:Connect(function(wave)
	hud.showWave(wave)
end)

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(message)
	hud.notify(message)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		remotes:WaitForChild("Slap"):FireServer()
	elseif input.KeyCode == Enum.KeyCode.L then
		remotes:WaitForChild("LockBase"):FireServer()
	elseif input.KeyCode == Enum.KeyCode.R then
		remotes:WaitForChild("Rebirth"):FireServer()
	end
end)
