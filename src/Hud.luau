-- Hud: everything on the play screen that is not the board. The ledger down the side (the run's
-- numbers, the heist plan, the threats), the goal line, and the on-screen buttons, which send the
-- same intents as the keyboard. All of it is filled from the server's state.

local Draw = require(script.Parent.Draw)

local Hud = {}

local PLAN_SLOTS = 6
local NUMBERS = { "VAULT", "SCORE", "MOVES" }
local ICON_ROWS = { "LIVES", "KEYS" }
-- text, intent, x, y (fractions of the stage)
local STEP_BUTTONS = {
	{ "W", "up", 0.075, 0.84 },
	{ "A", "left", 0.015, 0.91 },
	{ "S", "down", 0.075, 0.91 },
	{ "D", "right", 0.135, 0.91 },
}
local TOOL_BUTTONS = {
	{ kind = "smoke", key = "Q", x = 0.31 },
	{ kind = "cloak", key = "E", x = 0.41 },
	{ kind = "jammer", key = "R", x = 0.51 },
}
-- The goal line while a tool is at work: the effect, then how many turns it has left.
local EFFECTS = {
	{ kind = "smoke", text = "ENEMIES BLINDED: " },
	{ kind = "cloak", text = "CLOAKED: " },
	{ kind = "jammer", text = "LASERS JAMMED: " },
}

local texts = {} -- the labels whose words change with the state
local iconRows = {} -- [name] = the frame holding a row of icons
local plan = {} -- [vault number] = { marker = frame, name = label }
local threats = {} -- [enemy kind] = { name = label, rule = label }
local drawn = {} -- [name] = what that part of the ledger last showed

function Hud.render(state) -- ledger: numbers, the six-vault plan, the five threats, the three tools
	texts.vaultName.Text = "VAULT " .. state.level .. ": " .. state.vault
	texts.planTitle.Text = "HEIST PLAN: " .. state.modeName .. " MODE"
	local goal, colorName = Hud.goalLine(state)
	texts.goal.Text = goal
	texts.goal.TextColor3 = Draw.colors[colorName]

	Hud.setNumber("VAULT", state.level .. "/" .. #state.plan)
	Hud.setNumber("SCORE", tostring(state.score))
	Hud.setNumber("MOVES", tostring(state.movesLeft))
	Hud.setIcons("LIVES", "player", state.lives, state.maxLives)
	Hud.setIcons("KEYS", "key", state.keys, state.keysNeeded)
	for kind, count in state.tools do
		texts[kind].Text = tostring(count)
		texts[kind].TextColor3 = if count > 0 then Draw.colors.ink else Draw.colors.wall
	end
	Hud.showPlan(state)
	Hud.showThreats(state)
end

-- The line under the board: what to do next, and its colour.
function Hud.goalLine(state)
	for _, effect in EFFECTS do
		local turns = state.active[effect.kind]
		if turns > 0 then
			return effect.text .. turns .. (if turns == 1 then " TURN" else " TURNS"), "ink"
		end
	end
	local keysLeft = state.keysNeeded - state.keys
	if keysLeft > 0 then
		return "FIND " .. keysLeft .. (if keysLeft == 1 then " KEY" else " KEYS") .. ", THEN REACH THE DOOR", "gold"
	end
	return "THE DOOR IS OPEN. GET OUT!", "teal"
end

-- A number flashes amber when it changes.
function Hud.setNumber(name, showing)
	if drawn[name] ~= showing then
		drawn[name] = showing
		texts[name].Text = showing
		texts[name].TextColor3 = Draw.colors.amber
		Draw.tween(texts[name], 0.5, { TextColor3 = Draw.colors.ink })
	end
end

-- A row of icons: so many filled out of a total.
function Hud.setIcons(name, kind, filled, total)
	local showing = filled .. "/" .. total
	if drawn[name] ~= showing then
		drawn[name] = showing
		iconRows[name]:ClearAllChildren()
		for index = 1, total do
			Draw.icon(
				if index <= filled then kind else "slot",
				iconRows[name],
				UDim2.fromScale((index - 1) / 3, 0),
				UDim2.fromScale(1 / 3, 1)
			)
		end
	end
end

-- The heist plan: cleared vaults ticked in teal, the current one marked in amber, the rest dim.
function Hud.showPlan(state)
	local showing = state.level .. "/" .. state.cleared
	if drawn.plan == showing then
		return
	end
	drawn.plan = showing
	for index, entry in plan do
		local marker, colorName = "slot", "dim"
		if index == state.level then
			marker, colorName = "here", "amber"
		elseif index <= state.cleared then
			marker, colorName = "done", "teal"
		end
		entry.marker:ClearAllChildren()
		Draw.sprite(marker, entry.marker)
		entry.name.Text = index .. " " .. (state.plan[index] or "")
		entry.name.TextColor3 = Draw.colors[colorName]
	end
end

-- The threats: the kinds prowling this vault are lit, the others dim.
function Hud.showThreats(state)
	local here = {}
	for _, enemy in state.enemies do
		here[enemy.kind] = true
	end
	for kind, row in threats do
		row.name.TextColor3 = if here[kind] then Draw.colors.amber else Draw.colors.wall
		row.rule.TextColor3 = if here[kind] then Draw.colors.ink else Draw.colors.wall
	end
end

function Hud.mount(parent, sendIntent)
	local colors = Draw.colors
	local function left(label)
		label.TextXAlignment = Enum.TextXAlignment.Left
		return label
	end
	local function sends(intent)
		return function()
			sendIntent(intent)
		end
	end

	left(Draw.label(parent, "DUSK VAULT", colors.amber, UDim2.fromScale(0.115, 0.015), UDim2.fromScale(0.22, 0.075), Draw.titleFont))
	texts.vaultName = Draw.label(parent, "", colors.ink, UDim2.fromScale(0.34, 0.032), UDim2.fromScale(0.27, 0.045))
	texts.vaultName.TextXAlignment = Enum.TextXAlignment.Right
	texts.goal = left(Draw.label(parent, "", colors.gold, UDim2.fromScale(0.015, 0.775), UDim2.fromScale(0.596, 0.045)))

	-- Under the board: steps, wait, and the three tools with how many are left.
	for _, button in STEP_BUTTONS do
		local text, intent, x, y = table.unpack(button)
		Draw.button(parent, text, colors.wallTop, UDim2.fromScale(x, y), UDim2.fromScale(0.055, 0.062), sends(intent))
	end
	Draw.button(parent, "WAIT", colors.dim, UDim2.fromScale(0.205, 0.84), UDim2.fromScale(0.095, 0.132), sends("wait"))
	for _, tool in TOOL_BUTTONS do
		local button = Draw.button(parent, "", colors.panel, UDim2.fromScale(tool.x, 0.84), UDim2.fromScale(0.095, 0.132), sends(tool.kind))
		Draw.icon(tool.kind, button, UDim2.fromScale(0, 0), UDim2.fromScale(0.55, 0.64))
		texts[tool.kind] = Draw.label(button, "0", colors.ink, UDim2.fromScale(0.55, 0), UDim2.fromScale(0.45, 0.64), Draw.titleFont)
		Draw.label(button, tool.key .. " " .. string.upper(tool.kind), colors.dim, UDim2.fromScale(0, 0.68), UDim2.fromScale(1, 0.32))
	end

	-- The ledger, top to bottom: numbers, lives and keys, the plan, the threats.
	local ledger = Draw.frame(parent, colors.panel, UDim2.fromScale(0.625, 0.02), UDim2.fromScale(0.36, 0.96), 0.05)
	for index, name in NUMBERS do
		local x = 0.05 + (index - 1) * 0.32
		left(Draw.label(ledger, name, colors.dim, UDim2.fromScale(x, 0.02), UDim2.fromScale(0.28, 0.03)))
		texts[name] = left(Draw.label(ledger, "", colors.ink, UDim2.fromScale(x, 0.052), UDim2.fromScale(0.28, 0.08), Draw.titleFont))
	end
	for index, name in ICON_ROWS do
		local x = 0.05 + (index - 1) * 0.47
		left(Draw.label(ledger, name, colors.dim, UDim2.fromScale(x, 0.168), UDim2.fromScale(0.13, 0.03)))
		iconRows[name] = Draw.make("Frame", ledger, {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(x + 0.14, 0.145),
			Size = UDim2.fromScale(0.3, 0.075),
		})
	end

	texts.planTitle = left(Draw.label(ledger, "", colors.dim, UDim2.fromScale(0.05, 0.245), UDim2.fromScale(0.9, 0.03)))
	for index = 1, PLAN_SLOTS do
		local x = 0.05 + ((index - 1) % 2) * 0.47
		local y = 0.285 + math.floor((index - 1) / 2) * 0.068
		plan[index] = {
			marker = Draw.layer(Draw.icon("slot", ledger, UDim2.fromScale(x, y), UDim2.fromScale(0.07, 0.055)), 2),
			name = left(Draw.label(ledger, "", colors.dim, UDim2.fromScale(x + 0.08, y + 0.005), UDim2.fromScale(0.36, 0.045))),
		}
	end

	left(Draw.label(ledger, "THREATS", colors.dim, UDim2.fromScale(0.05, 0.505), UDim2.fromScale(0.9, 0.03)))
	for index, member in Draw.CAST do
		local y = 0.545 + (index - 1) * 0.088
		Draw.icon(member.kind, ledger, UDim2.fromScale(0.05, y), UDim2.fromScale(0.12, 0.078))
		threats[member.kind] = {
			name = left(Draw.label(ledger, member.name, colors.ink, UDim2.fromScale(0.19, y + 0.012), UDim2.fromScale(0.27, 0.05), Draw.titleFont)),
			rule = left(Draw.label(ledger, member.rule, colors.dim, UDim2.fromScale(0.47, y + 0.02), UDim2.fromScale(0.5, 0.04))),
		}
	end
end

return Hud
