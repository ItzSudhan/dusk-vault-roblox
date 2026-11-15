-- Rules: the whole game as pure functions over one run-state table. The server calls Rules.act for
-- every intent; nothing here touches a Roblox service, so the client can read the same constants.

local Levels = require(script.Parent.Levels)
local Enemies = require(script.Parent.Enemies)

local Rules = {}

Rules.LIVES = 3
Rules.SMOKE_TURNS = 4 -- turns the enemies stand still after a smoke bomb
Rules.LASER_PERIOD = 3 -- lasers fire on every third turn
Rules.POINTS = { gem = 50, key = 20, smoke = 10, clear = 100, moveLeft = 5, lifeLeft = 200 }

local STEPS = {
	up = { 0, -1 },
	down = { 0, 1 },
	left = { -1, 0 },
	right = { 1, 0 },
	wait = { 0, 0 },
}

-- One intent, one turn: the thief steps, the enemies answer, then the win and loss checks.
function Rules.act(state, intent)
	state.events = {}
	if intent == "start" and state.phase ~= "playing" then
		Rules.startRun(state)
	elseif state.phase ~= "playing" then
		return
	elseif intent == "smoke" then
		Rules.throwSmoke(state)
	elseif STEPS[intent] then
		Rules.takeTurn(state, STEPS[intent])
	end
end

function Rules.takeTurn(state, step)
	local level = Levels.load(state.level)
	local player = state.player
	local x, y = player.x + step[1], player.y + step[2]
	local atExit = x == level.exit.x and y == level.exit.y
	if level.walls[Levels.key(x, y)] then
		Rules.emit(state, "bump", x, y)
		return
	elseif atExit and state.keys < level.keysNeeded then
		Rules.emit(state, "locked", x, y)
		return
	end

	player.x, player.y = x, y
	state.movesLeft -= 1
	Rules.collect(state, level)

	-- A laser burns the thief who steps into it while it fires, or who is on it when it fires next.
	local onLaser = level.lasers[Levels.key(x, y)] == true
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
end

function Rules.laserOn(turn)
	return turn % Rules.LASER_PERIOD == 0
end

function Rules.collect(state, level)
	local player = state.player
	for index, item in state.items do
		if item.x == player.x and item.y == player.y then
			table.remove(state.items, index)
			state.score += Rules.POINTS[item.kind]
			Rules.emit(state, item.kind, item.x, item.y)
			if item.kind == "smoke" then
				state.smoke += 1
			elseif item.kind == "key" then
				state.keys += 1
				if state.keys == level.keysNeeded then
					Rules.emit(state, "unlock", level.exit.x, level.exit.y)
				end
			end
			return
		end
	end
end

function Rules.throwSmoke(state)
	local player = state.player
	if state.smoke <= 0 then
		Rules.emit(state, "empty", player.x, player.y)
		return
	end
	state.smoke -= 1
	state.frozen = Rules.SMOKE_TURNS
	Rules.emit(state, "haze", player.x, player.y)
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
	local bonus = Rules.POINTS.clear + state.movesLeft * Rules.POINTS.moveLeft
	state.score += bonus
	state.cleared = state.level
	Rules.emit(state, "clear", state.player.x, state.player.y, "+" .. bonus)
	if state.level == Levels.count then
		state.score += state.lives * Rules.POINTS.lifeLeft
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

-- A player's state before the first START: a full run, shown behind the title screen.
function Rules.newRun(best)
	local state = { best = best }
	Rules.startRun(state)
	state.phase = "title"
	state.events = {}
	return state
end

function Rules.startRun(state)
	state.phase = "playing"
	state.lives = Rules.LIVES
	state.score = 0
	state.smoke = 1
	state.cleared = 0
	state.cause = ""
	state.events = {}
	Rules.enterLevel(state, 1)
end

function Rules.enterLevel(state, index)
	local level = Levels.load(index)
	state.level = index
	state.keys = 0
	state.keysNeeded = level.keysNeeded
	state.items = Rules.fresh(level.items)
	Rules.placePieces(state)
	Rules.emit(state, "level", level.start.x, level.start.y, level.name)
end

-- Start of a level and after a lost life: thief and enemies back to their marks, a fresh move budget.
-- Keys and items already taken stay taken.
function Rules.placePieces(state)
	local level = Levels.load(state.level)
	state.player = { x = level.start.x, y = level.start.y }
	state.enemies = Rules.fresh(level.enemies)
	state.frozen = 0
	state.turn = 0
	state.movesLeft = level.moves
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
