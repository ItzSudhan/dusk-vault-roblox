-- Client: sends the player's intents to the server and draws whatever state the server sends back.
-- It keeps no game state of its own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Ui = ReplicatedStorage:WaitForChild("Ui")
local Board = require(Ui.Board)
local Draw = require(Ui.Draw)
local Screens = require(Ui.Screens)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local KEYS = {
	[Enum.KeyCode.W] = "up",
	[Enum.KeyCode.Up] = "up",
	[Enum.KeyCode.S] = "down",
	[Enum.KeyCode.Down] = "down",
	[Enum.KeyCode.A] = "left",
	[Enum.KeyCode.Left] = "left",
	[Enum.KeyCode.D] = "right",
	[Enum.KeyCode.Right] = "right",
	[Enum.KeyCode.Space] = "wait",
	[Enum.KeyCode.F] = "smoke",
	[Enum.KeyCode.Return] = "start",
}

local function sendIntent(intent) -- keys and buttons only ask; the server decides
	Remotes.Intent:FireServer(intent)
end

local function drawState(state)
	Board.render(state)
	Screens.show(state)
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local gui = Draw.make("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {
	Name = "DuskVault",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local root = Draw.frame(gui, Draw.colors.night, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
Board.mount(root)
Screens.mount(root, sendIntent)

Remotes.Snapshot.OnClientEvent:Connect(drawState)
UserInputService.InputBegan:Connect(function(input)
	local intent = KEYS[input.KeyCode]
	if intent then
		sendIntent(intent)
	end
end)

sendIntent("ready")
