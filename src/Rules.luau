-- Rules: the whole game as pure functions over one run-state table. Sessions calls Rules.act for
-- every intent; nothing here touches a Roblox service. The state it keeps is everything the client
-- draws, so the client needs no rules of its own.

local Enemies = require(script.Parent.Enemies)
local Levels = require(script.Parent.Levels)
local Tools = require(script.Parent.Tools)

local Rules = {}

Rules.LASER_PERIOD = 3 -- lasers fire on every third turn
Rules.POINTS = { gem = 50, key = 20, tool = 10, clear = 100, moveLeft = 5, lifeLeft = 200 }

-- The two modes: MASTER has fewer lives and tighter move budgets, and doubles every point.
Rules.MODES = {
	heist = { name = "HEIST", lives = 3, budget = 1, score = 1 },
	master = { name = "MASTER", lives = 2, budget = 0.7, score = 2 },
}

local STEPS = {
	up = { 0, -1 },
	down = { 0, 1 },
	left = { -1, 0 },
	right = { 1, 0 },
	wait = { 0, 0 },
}
local LASER_PHASES = { [0] = "on", [1] = "off", [2] = "warn" }

-- One intent, one answer: choose a mode, start, use a tool, or take a turn.
function Rules.act(state, intent)
	state.events = {}
	local playing = state.phase == "playing"
	if Rules.MODES[intent] and not playing then
		Rules.setMode(state, intent)
	elseif intent == "start" and not playing then
		Rules.startRun(state)
	elseif intent == "menu" and not playing then
		state.phase = "title"
	elseif playing and Tools.KINDS[intent] then
		Rules.useTool(state, intent)
	elseif playing and STEPS[intent] then
		Rules.takeTurn(state, STEPS[intent])
	end
	Rules.readLasers(state)
end

-- A turn: the thief steps (and warps on a pad), picks up, then lasers, enemies and the budget.
function Rules.takeTurn(state, step)
	local level = Levels.load(state.level)
	local player = state.player
	local x, y = player.x + step[1], player.y + step[2]
	local atExit = x == level.exit.x and y == level.exit.y
	if level.walls[Levels.key(x, y)] then
		Rules.emit(state, "bump", x, y)
		return
	elseif atExit and state.keys < level.keysNeeded then
		Rules.emit(state, "locked", x, y, "LOCKED")
		return
	end

	local twin = level.pads[Levels.key(x, y)]
	if twin and (step[1] ~= 0 or step[2] ~= 0) then
		x, y = twin.x, twin.y
		Rules.emit(state, "warp", x, y, "WARP!")
	end
	player.x, player.y = x, y
	state.step = step
	state.movesLeft -= 1
	Rules.collect(state, level)

	-- A laser burns the thief who steps into it while it fires, or who is on it when it fires next.
	local onLaser = level.lasers[Levels.key(x, y)] == true and state.active.jammer == 0
	local zapped = onLaser and Rules.laserOn(state.turn)
	state.turn += 1
	zapped = zapped or (onLaser and Rules.laserOn(state.turn))

	if atExit then
		Rules.clearLevel(state)
	elseif zapped then
		Rules.loseLife(state, "zapped")
	elseif Enemies.move(state) then
		Rules.loseLife(state, "caught")
	elseif state.movesLeft <= 0 then
		Rules.loseLife(state, "out of moves")
	end
	Tools.tick(state)
end

function Rules.laserOn(turn)
	return turn % Rules.LASER_PERIOD == 0
end

-- What the lasers show this turn: on, warn (fires next turn), off, or jammed.
function Rules.readLasers(state)
	state.laser = if state.active.jammer > 0 then "jammed" else LASER_PHASES[state.turn % Rules.LASER_PERIOD]
end

function Rules.useTool(state, kind)
	local player = state.player
	if Tools.use(state, kind) then
		Rules.emit(state, "use", player.x, player.y, Tools.KINDS[kind].shout)
	else
		Rules.emit(state, "empty", player.x, player.y, "NO " .. string.upper(kind))
	end
end

function Rules.collect(state, level)
	local player = state.player
	for index, item in state.items do
		if item.x == player.x and item.y == player.y then
			table.remove(state.items, index)
			local points = Rules.POINTS[item.kind] or Rules.POINTS.tool
			if Tools.KINDS[item.kind] then
				Tools.pickUp(state, item.kind)
				Rules.emit(state, "pick", item.x, item.y, string.upper(item.kind) .. " +1")
			else
				Rules.emit(state, "pick", item.x, item.y, "+" .. Rules.gain(state, points))
			end
			if item.kind == "key" then
				state.keys += 1
				if state.keys == level.keysNeeded then
					Rules.emit(state, "unlock", level.exit.x, level.exit.y, "DOOR OPEN")
				end
			end
			return
		end
	end
end

-- Every point goes through here, so the mode's multiplier applies to all of them.
function Rules.gain(state, points)
	local gained = points * Rules.MODES[state.mode].score
	state.score += gained
	return gained
end

function Rules.loseLife(state, cause)
	state.lives -= 1
	state.cause = cause
	Rules.emit(state, "hurt", state.player.x, state.player.y, string.upper(cause))
	if state.lives <= 0 then
		Rules.endRun(state, "lost")
	else
		Rules.placePieces(state)
	end
end

function Rules.clearLevel(state)
	local bonus = Rules.gain(state, Rules.POINTS.clear + state.movesLeft * Rules.POINTS.moveLeft)
	state.cleared = state.level
	Rules.emit(state, "clear", state.player.x, state.player.y, "+" .. bonus)
	if state.level == Levels.count then
		Rules.gain(state, state.lives * Rules.POINTS.lifeLeft)
		Rules.endRun(state, "won")
	else
		Rules.enterLevel(state, state.level + 1)
	end
end

function Rules.endRun(state, phase)
	state.phase = phase
	state.best = math.max(state.best, state.score)
	Rules.emit(state, phase, state.player.x, state.player.y)
end

-- A player's state before the first START: a full run in HEIST mode, shown behind the title.
function Rules.newRun(best)
	local state = { best = best, plan = {} }
	for index = 1, Levels.count do
		state.plan[index] = string.gsub(Levels.load(index).name, "^THE ", "")
	end
	Rules.setMode(state, "heist")
	Rules.startRun(state)
	state.phase = "title"
	state.events = {}
	Rules.readLasers(state)
	return state
end

function Rules.setMode(state, mode)
	state.mode = mode
	state.modeName = Rules.MODES[mode].name
	state.maxLives = Rules.MODES[mode].lives
end

function Rules.startRun(state)
	state.phase = "playing"
	state.lives = state.maxLives
	state.score = 0
	state.cleared = 0
	state.cause = ""
	state.events = {}
	Tools.stock(state)
	Rules.enterLevel(state, 1)
end

function Rules.enterLevel(state, index)
	local level = Levels.load(index)
	state.level = index
	state.vault = level.name
	state.rows = level.rows
	state.keys = 0
	state.keysNeeded = level.keysNeeded
	state.items = Rules.fresh(level.items)
	Rules.placePieces(state)
	Rules.emit(state, "level", level.start.x, level.start.y, level.name)
end

-- Start of a level and after a lost life: thief and enemies back to their marks, a fresh move
-- budget, no effects running. Keys and items already taken stay taken.
function Rules.placePieces(state)
	local level = Levels.load(state.level)
	state.player = { x = level.start.x, y = level.start.y }
	state.step = STEPS.wait
	state.enemies = Rules.fresh(level.enemies)
	state.turn = 0
	state.movesLeft = math.ceil(level.moves * Rules.MODES[state.mode].budget)
	Tools.calm(state)
end

function Rules.fresh(pieces)
	local copies = {}
	for index, piece in pieces do
		copies[index] = table.clone(piece)
	end
	return copies
end

function Rules.emit(state, name, x, y, text)
	table.insert(state.events, { name = name, x = x, y = y, text = text })
end

return Rules
