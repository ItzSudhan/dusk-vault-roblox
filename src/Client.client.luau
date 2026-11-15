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

local STAGE_ASPECT = 5 / 4

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
Draw.frame(gui, Draw.colors.night, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))

-- The game is drawn on a stage of one fixed shape, centred in whatever shape the window has.
local stage = Draw.make("Frame", gui, {
	Name = "Stage",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Draw.colors.night,
	ClipsDescendants = true,
})
Draw.make("UIAspectRatioConstraint", stage, { AspectRatio = STAGE_ASPECT })
Board.mount(stage)
Screens.mount(stage, sendIntent)

Remotes.Snapshot.OnClientEvent:Connect(drawState)
UserInputService.InputBegan:Connect(function(input)
	local intent = KEYS[input.KeyCode]
	if intent then
		sendIntent(intent)
	end
end)

sendIntent("ready")
