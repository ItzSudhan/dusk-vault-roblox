-- Screens: what covers the board between runs. The title screen (the bestiary, the mode choice,
-- START), the end screen (the result and the run's numbers), and the banner that announces each
-- vault. They slide over the stage according to the phase of the server's state.

local Draw = require(script.Parent.Draw)

local Screens = {}

local SHOWN, ABOVE = UDim2.fromScale(0, 0), UDim2.fromScale(0, -1)
local BANNER_Y = 0.38
local ENDINGS = {
	won = { headline = "VAULT CRACKED!", color = "teal" },
	lost = { headline = "BUSTED!", color = "rose" },
}
-- The two modes on the title screen: the intent that picks it, its name, what it changes.
local MODES = {
	{ intent = "heist", name = "HEIST", terms = "3 LIVES", x = 0.14 },
	{ intent = "master", name = "MASTER", terms = "2 LIVES, FEWER MOVES, x2 SCORE", x = 0.51 },
}
local TILES = { "SCORE", "BEST", "VAULTS", "MODE" }

local titleScreen, endScreen, banner
local texts = {} -- the labels whose words change with the state
local modeButtons = {} -- [mode intent] = its button on the title screen
local shownPhase = nil
local announcements = 0

function Screens.show(state) -- title with bestiary and mode choice, vault banner, win and loss
	for intent, button in modeButtons do
		local chosen = state.mode == intent
		button.BackgroundColor3 = if chosen then Draw.colors.amber else Draw.colors.panel
		button.TextColor3 = if chosen then Draw.colors.night else Draw.colors.dim
	end
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

function Screens.fillEnd(state, ending)
	texts.headline.Text = ending.headline
	texts.headline.TextColor3 = Draw.colors[ending.color]
	texts.reason.Text = if state.phase == "won"
		then "ALL " .. #state.plan .. " VAULTS CLEANED OUT"
		else string.upper(state.cause) .. " IN VAULT " .. state.level .. ": " .. state.vault
	texts.SCORE.Text = tostring(state.score)
	texts.BEST.Text = tostring(state.best)
	texts.VAULTS.Text = state.cleared .. "/" .. #state.plan
	texts.MODE.Text = state.modeName
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
	local colors = Draw.colors
	local function sends(intent)
		return function()
			sendIntent(intent)
		end
	end

	banner = Draw.frame(parent, colors.amber, UDim2.fromScale(-1, BANNER_Y), UDim2.fromScale(1, 0.2))
	banner.ZIndex = 5
	texts.banner = Draw.label(banner, "", colors.night, UDim2.fromScale(0.05, 0.2), UDim2.fromScale(0.9, 0.6), Draw.titleFont)

	titleScreen = Draw.frame(parent, colors.night, SHOWN, UDim2.fromScale(1, 1))
	titleScreen.ZIndex = 10
	titleScreen.Active = true -- a screen over the board takes the clicks meant for it
	Draw.label(titleScreen, "DUSK VAULT", colors.amber, UDim2.fromScale(0.1, 0.01), UDim2.fromScale(0.8, 0.21), Draw.titleFont)
	Draw.label(titleScreen, "6 VAULTS   5 THREATS   3 TOOLS   2 MODES", colors.ink, UDim2.fromScale(0.1, 0.225), UDim2.fromScale(0.8, 0.055))
	for index, member in Draw.CAST do
		local x = 0.075 + (index - 1) * 0.17
		Draw.icon(member.kind, titleScreen, UDim2.fromScale(x + 0.045, 0.3), UDim2.fromScale(0.08, 0.125))
		Draw.label(titleScreen, member.name, colors.amber, UDim2.fromScale(x, 0.43), UDim2.fromScale(0.17, 0.055), Draw.titleFont)
		Draw.label(titleScreen, member.rule, colors.dim, UDim2.fromScale(x, 0.487), UDim2.fromScale(0.17, 0.036))
	end
	for _, mode in MODES do
		local button = Draw.make("TextButton", titleScreen, {
			AutoButtonColor = false,
			BackgroundColor3 = colors.panel,
			Text = mode.name,
			TextColor3 = colors.dim,
			TextScaled = true,
			Font = Draw.titleFont,
			Position = UDim2.fromScale(mode.x, 0.55),
			Size = UDim2.fromScale(0.35, 0.115),
		})
		Draw.make("UICorner", button, { CornerRadius = UDim.new(0.3, 0) })
		Draw.make("UIPadding", button, { PaddingTop = UDim.new(0.12, 0), PaddingBottom = UDim.new(0.12, 0) })
		button.Activated:Connect(sends(mode.intent))
		modeButtons[mode.intent] = button
		Draw.label(titleScreen, mode.terms, colors.dim, UDim2.fromScale(mode.x, 0.672), UDim2.fromScale(0.35, 0.036))
	end
	Draw.button(titleScreen, "START", colors.amber, UDim2.fromScale(0.3, 0.73), UDim2.fromScale(0.4, 0.17), sends("start"))
	texts.titleBest = Draw.label(titleScreen, "BEST 0", colors.teal, UDim2.fromScale(0.3, 0.915), UDim2.fromScale(0.4, 0.06), Draw.titleFont)

	endScreen = Draw.frame(parent, colors.night, ABOVE, UDim2.fromScale(1, 1))
	endScreen.ZIndex = 10
	endScreen.Active = true
	texts.headline = Draw.label(endScreen, "", colors.teal, UDim2.fromScale(0.08, 0.03), UDim2.fromScale(0.84, 0.25), Draw.titleFont)
	texts.reason = Draw.label(endScreen, "", colors.ink, UDim2.fromScale(0.08, 0.285), UDim2.fromScale(0.84, 0.07))
	for index, name in TILES do
		local tile = Draw.frame(endScreen, colors.panel, UDim2.fromScale(0.05 + (index - 1) * 0.23, 0.39), UDim2.fromScale(0.21, 0.26), 0.12)
		Draw.label(tile, name, colors.dim, UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.8, 0.22))
		texts[name] = Draw.label(tile, "0", colors.ink, UDim2.fromScale(0.06, 0.36), UDim2.fromScale(0.88, 0.54), Draw.titleFont)
	end
	Draw.button(endScreen, "PLAY AGAIN", colors.amber, UDim2.fromScale(0.2, 0.7), UDim2.fromScale(0.38, 0.17), sends("start"))
	Draw.button(endScreen, "MENU", colors.dim, UDim2.fromScale(0.6, 0.7), UDim2.fromScale(0.2, 0.17), sends("menu"))
	texts.newBest = Draw.label(endScreen, "NEW BEST!", colors.gold, UDim2.fromScale(0.3, 0.9), UDim2.fromScale(0.4, 0.07), Draw.titleFont)
end

return Screens
