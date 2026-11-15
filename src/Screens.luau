-- Screens: everything around the board. The HUD panel with the run's numbers and the on-screen
-- buttons, the title screen, the end screen, and the banner that announces each vault. All of it
-- is filled from the server's state; the buttons send the same intents as the keyboard.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Levels = require(ReplicatedStorage.Levels)
local Rules = require(ReplicatedStorage.Rules)
local Draw = require(script.Parent.Draw)

local Screens = {}

local SHOWN, ABOVE = UDim2.fromScale(0, 0), UDim2.fromScale(0, -1)
local BANNER_Y = 0.38
local ROW_GAP = 0.098
local ICONS_PER_ROW = 3
local CAST = { "player", "key", "gem", "smoke", "guard", "hound", "wraith" }
local ENDINGS = {
	won = { headline = "VAULT CRACKED!", color = "teal" },
	lost = { headline = "BUSTED!", color = "rose" },
}

-- A HUD stat is shown as text, or as a row of icons: so many filled out of a total.
local STATS = {
	{
		name = "VAULT",
		text = function(state)
			return state.level .. " / " .. Levels.count
		end,
	},
	{
		name = "SCORE",
		text = function(state)
			return tostring(state.score)
		end,
	},
	{
		name = "MOVES",
		text = function(state)
			return tostring(state.movesLeft)
		end,
	},
	{
		name = "LIVES",
		icon = "player",
		count = function(state)
			return state.lives, Rules.LIVES
		end,
	},
	{
		name = "KEYS",
		icon = "key",
		count = function(state)
			return state.keys, state.keysNeeded
		end,
	},
	{
		name = "SMOKE",
		icon = "smoke",
		count = function(state)
			return state.smoke, math.max(state.smoke, 1)
		end,
	},
}

-- text, intent, colour name, x, y, width (fractions of the HUD panel)
local BUTTONS = {
	{ "W", "up", "wallTop", 0.37, 0.635, 0.26 },
	{ "A", "left", "wallTop", 0.07, 0.745, 0.26 },
	{ "S", "down", "wallTop", 0.37, 0.745, 0.26 },
	{ "D", "right", "wallTop", 0.67, 0.745, 0.26 },
	{ "WAIT", "wait", "dim", 0.07, 0.865, 0.41 },
	{ "SMOKE", "smoke", "amber", 0.52, 0.865, 0.41 },
}

local titleScreen, endScreen, banner
local texts = {} -- the labels whose words change with the state
local stats = {} -- [stat name] = its text label or its icon row
local drawn = {} -- [stat name] = what that stat last showed
local shownPhase = nil
local announcements = 0

function Screens.show(state) -- HUD each turn; title, vault banner, win and loss screens by phase
	Screens.showStats(state)
	if shownPhase ~= state.phase then
		shownPhase = state.phase
		local ending = ENDINGS[state.phase]
		if ending then
			Screens.fillEnd(state, ending)
		end
		texts.titleBest.Text = "BEST " .. state.best
		Draw.tween(titleScreen, 0.35, { Position = if state.phase == "title" then SHOWN else ABOVE })
		Draw.tween(endScreen, 0.35, { Position = if ending then SHOWN else ABOVE })
	end
	for _, event in state.events do
		if event.name == "level" then
			Screens.announce("VAULT " .. state.level .. ": " .. event.text)
		end
	end
end

function Screens.showStats(state)
	texts.vaultName.Text = "VAULT " .. state.level .. ": " .. Levels.load(state.level).name
	for _, stat in STATS do
		local showing = if stat.text then stat.text(state) else table.concat({ stat.count(state) }, "/")
		if drawn[stat.name] ~= showing then
			drawn[stat.name] = showing
			local value = stats[stat.name]
			if stat.text then
				value.Text = showing
				value.TextColor3 = Draw.colors.amber
				Draw.tween(value, 0.5, { TextColor3 = Draw.colors.ink })
			else
				Screens.drawIcons(value, stat.icon, stat.count(state))
			end
		end
	end
end

function Screens.drawIcons(row, kind, filled, total)
	row:ClearAllChildren()
	for index = 1, math.min(total, ICONS_PER_ROW) do
		Draw.icon(
			if index <= filled then kind else "slot",
			row,
			UDim2.fromScale((index - 1) / ICONS_PER_ROW, 0),
			UDim2.fromScale(1 / ICONS_PER_ROW, 1)
		)
	end
end

function Screens.fillEnd(state, ending)
	texts.headline.Text = ending.headline
	texts.headline.TextColor3 = Draw.colors[ending.color]
	texts.reason.Text = if state.phase == "won"
		then "ALL " .. Levels.count .. " VAULTS CLEANED OUT"
		else string.upper(state.cause) .. " IN VAULT " .. state.level
	texts.SCORE.Text = tostring(state.score)
	texts.BEST.Text = tostring(state.best)
	texts.VAULTS.Text = state.cleared .. " / " .. Levels.count
	texts.newBest.Visible = state.score > 0 and state.score >= state.best
end

function Screens.announce(text)
	announcements += 1
	local mine = announcements
	texts.banner.Text = text
	banner.Position = UDim2.fromScale(-1, BANNER_Y)
	Draw.tween(banner, 0.3, { Position = UDim2.fromScale(0, BANNER_Y) })
	task.delay(1.3, function()
		if mine == announcements then
			Draw.tween(banner, 0.3, { Position = UDim2.fromScale(1, BANNER_Y) })
		end
	end)
end

function Screens.mount(parent, sendIntent)
	Screens.mountHud(parent, sendIntent)
	local colors = Draw.colors
	local function start()
		sendIntent("start")
	end

	banner = Draw.frame(parent, colors.amber, UDim2.fromScale(-1, BANNER_Y), UDim2.fromScale(1, 0.2))
	banner.ZIndex = 5
	texts.banner = Draw.label(banner, "", colors.night, UDim2.fromScale(0.05, 0.2), UDim2.fromScale(0.9, 0.6), Draw.titleFont)

	titleScreen = Draw.frame(parent, colors.night, SHOWN, UDim2.fromScale(1, 1))
	titleScreen.ZIndex = 10
	Draw.label(titleScreen, "DUSK VAULT", colors.amber, UDim2.fromScale(0.1, 0.05), UDim2.fromScale(0.8, 0.27), Draw.titleFont)
	for index, kind in CAST do
		Draw.icon(kind, titleScreen, UDim2.fromScale(0.5 + (index - 4) * 0.09 - 0.04, 0.33), UDim2.fromScale(0.08, 0.15))
	end
	Draw.label(titleScreen, "GRAB THE KEYS. DODGE THE GUARDS. REACH THE DOOR.", colors.ink, UDim2.fromScale(0.04, 0.51), UDim2.fromScale(0.92, 0.075))
	Draw.label(titleScreen, "WASD OR ARROWS: MOVE     SPACE: WAIT     F: SMOKE BOMB", colors.dim, UDim2.fromScale(0.1, 0.6), UDim2.fromScale(0.8, 0.05))
	Draw.button(titleScreen, "START HEIST", colors.amber, UDim2.fromScale(0.3, 0.69), UDim2.fromScale(0.4, 0.16), start)
	texts.titleBest = Draw.label(titleScreen, "BEST 0", colors.teal, UDim2.fromScale(0.3, 0.88), UDim2.fromScale(0.4, 0.07), Draw.titleFont)

	endScreen = Draw.frame(parent, colors.night, ABOVE, UDim2.fromScale(1, 1))
	endScreen.ZIndex = 10
	texts.headline = Draw.label(endScreen, "", colors.teal, UDim2.fromScale(0.08, 0.05), UDim2.fromScale(0.84, 0.25), Draw.titleFont)
	texts.reason = Draw.label(endScreen, "", colors.ink, UDim2.fromScale(0.1, 0.31), UDim2.fromScale(0.8, 0.075))
	for index, name in { "SCORE", "BEST", "VAULTS" } do
		local tile = Draw.frame(endScreen, colors.panel, UDim2.fromScale(0.09 + (index - 1) * 0.28, 0.43), UDim2.fromScale(0.26, 0.25), 0.12)
		Draw.label(tile, name, colors.dim, UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.8, 0.22))
		texts[name] = Draw.label(tile, "0", colors.ink, UDim2.fromScale(0.08, 0.36), UDim2.fromScale(0.84, 0.54), Draw.titleFont)
	end
	Draw.button(endScreen, "PLAY AGAIN", colors.amber, UDim2.fromScale(0.3, 0.73), UDim2.fromScale(0.4, 0.16), start)
	texts.newBest = Draw.label(endScreen, "NEW BEST!", colors.gold, UDim2.fromScale(0.3, 0.905), UDim2.fromScale(0.4, 0.07), Draw.titleFont)
end

function Screens.mountHud(parent, sendIntent)
	local colors = Draw.colors
	local title = Draw.label(parent, "DUSK VAULT", colors.amber, UDim2.fromScale(0.15, 0.02), UDim2.fromScale(0.3, 0.1), Draw.titleFont)
	title.TextXAlignment = Enum.TextXAlignment.Left
	texts.vaultName = Draw.label(parent, "", colors.ink, UDim2.fromScale(0.46, 0.04), UDim2.fromScale(0.52, 0.065))
	texts.vaultName.TextXAlignment = Enum.TextXAlignment.Right

	local panel = Draw.frame(parent, colors.panel, UDim2.fromScale(0.74, 0.14), UDim2.fromScale(0.24, 0.83), 0.06)
	for index, stat in STATS do
		local y = 0.03 + (index - 1) * ROW_GAP
		local name = Draw.label(panel, stat.name, colors.dim, UDim2.fromScale(0.07, y + 0.022), UDim2.fromScale(0.36, 0.045))
		name.TextXAlignment = Enum.TextXAlignment.Left
		if stat.text then
			local value = Draw.label(panel, "", colors.ink, UDim2.fromScale(0.42, y), UDim2.fromScale(0.51, 0.085), Draw.titleFont)
			value.TextXAlignment = Enum.TextXAlignment.Right
			stats[stat.name] = value
		else
			stats[stat.name] = Draw.make("Frame", panel, {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.45, y + 0.005),
				Size = UDim2.fromScale(0.5, 0.078),
			})
		end
	end

	for _, button in BUTTONS do
		local text, intent, colorName, x, y, width = table.unpack(button)
		Draw.button(panel, text, colors[colorName], UDim2.fromScale(x, y), UDim2.fromScale(width, 0.095), function()
			sendIntent(intent)
		end)
	end
end

return Screens
