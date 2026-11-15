-- Enemies: how each enemy kind takes its turn. Pure: reads the level, moves the enemies in the state.

local Levels = require(script.Parent.Levels)

local Enemies = {}

local MOVERS = {} -- [kind] = function(enemy, player, level, turn)

-- Every enemy takes its turn by its kind's rule, unless a smoke bomb has them frozen.
function Enemies.move(state) -- guard, hound, wraith
	local level = Levels.load(state.level)
	local player = state.player
	local frozen = state.frozen > 0
	if frozen then
		state.frozen -= 1
	end
	local caught = false
	for _, enemy in state.enemies do
		local touching = enemy.x == player.x and enemy.y == player.y
		if not touching and not frozen then
			MOVERS[enemy.kind](enemy, player, level, state.turn)
			touching = enemy.x == player.x and enemy.y == player.y
		end
		caught = caught or touching
	end
	return caught -- true when an enemy stands on the thief
end

function Enemies.blocked(level, x, y)
	return level.walls[Levels.key(x, y)] == true or (x == level.exit.x and y == level.exit.y)
end

-- One step toward the player along the longer axis, else the other, into any tile canEnter allows.
function Enemies.stepToward(enemy, player, canEnter)
	local dx, dy = math.sign(player.x - enemy.x), math.sign(player.y - enemy.y)
	local sideways, upDown = { dx, 0 }, { 0, dy }
	local wideGap = math.abs(player.x - enemy.x) >= math.abs(player.y - enemy.y)
	for _, step in (if wideGap then { sideways, upDown } else { upDown, sideways }) do
		local moves = step[1] ~= 0 or step[2] ~= 0
		if moves and canEnter(enemy.x + step[1], enemy.y + step[2]) then
			enemy.x += step[1]
			enemy.y += step[2]
			return
		end
	end
end

-- Guard: paces its corridor every turn and turns round at a wall.
function MOVERS.guard(enemy, _player, level)
	if Enemies.blocked(level, enemy.x + enemy.dx, enemy.y + enemy.dy) then
		enemy.dx, enemy.dy = -enemy.dx, -enemy.dy
	end
	if not Enemies.blocked(level, enemy.x + enemy.dx, enemy.y + enemy.dy) then
		enemy.x += enemy.dx
		enemy.y += enemy.dy
	end
end

-- Hound: chases the thief round the walls, but only on every second turn.
function MOVERS.hound(enemy, player, level, turn)
	if turn % 2 == 1 then
		Enemies.stepToward(enemy, player, function(x, y)
			return not Enemies.blocked(level, x, y)
		end)
	end
end

-- Wraith: drifts straight through walls toward the thief, one step every third turn.
function MOVERS.wraith(enemy, player, level, turn)
	if turn % 3 == 0 then
		Enemies.stepToward(enemy, player, function(x, y)
			return x > 1 and x < level.width and y > 1 and y < level.height
		end)
	end
end

return Enemies
