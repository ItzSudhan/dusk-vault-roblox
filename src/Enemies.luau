-- Enemies: how each of the five enemy kinds takes its turn. Pure: reads the level, moves the
-- enemies in the state, and says whether one of them caught the thief.

local Levels = require(script.Parent.Levels)

local Enemies = {}

local MOVERS = {} -- [kind] = function(enemy, state, level)

-- Every enemy takes its turn by its kind's rule. Smoke freezes them all; a cloak hides the thief.
function Enemies.move(state) -- guard, hound, wraith, drone, mimic
	local level = Levels.load(state.level)
	local player = state.player
	local frozen = state.active.smoke > 0
	local hidden = state.active.cloak > 0
	local caught = false
	for _, enemy in state.enemies do
		local touching = enemy.x == player.x and enemy.y == player.y
		if not frozen and (hidden or not touching) then
			MOVERS[enemy.kind](enemy, state, level)
			touching = enemy.x == player.x and enemy.y == player.y
		end
		caught = caught or (touching and not hidden)
	end
	return caught
end

-- One step toward the thief along the longer axis, else the other, into any tile canEnter allows.
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
function MOVERS.guard(enemy, _state, level)
	if Levels.blocked(level, enemy.x + enemy.dx, enemy.y + enemy.dy) then
		enemy.dx, enemy.dy = -enemy.dx, -enemy.dy
	end
	if not Levels.blocked(level, enemy.x + enemy.dx, enemy.y + enemy.dy) then
		enemy.x += enemy.dx
		enemy.y += enemy.dy
	end
end

-- Hound: chases the thief round the walls, but only on every second turn.
function MOVERS.hound(enemy, state, level)
	if state.turn % 2 == 1 then
		Enemies.stepToward(enemy, state.player, function(x, y)
			return not Levels.blocked(level, x, y)
		end)
	end
end

-- Wraith: drifts straight through walls toward the thief, one step every third turn.
function MOVERS.wraith(enemy, state, level)
	if state.turn % 3 == 0 then
		Enemies.stepToward(enemy, state.player, function(x, y)
			return x > 1 and x < level.width and y > 1 and y < level.height
		end)
	end
end

-- Drone: flies straight every turn and turns right whenever something is in its way.
function MOVERS.drone(enemy, _state, level)
	for _ = 1, 4 do
		if not Levels.blocked(level, enemy.x + enemy.dx, enemy.y + enemy.dy) then
			enemy.x += enemy.dx
			enemy.y += enemy.dy
			return
		end
		enemy.dx, enemy.dy = -enemy.dy, enemy.dx
	end
end

-- Mimic: takes the thief's own step backwards, and stands still when the thief waits.
function MOVERS.mimic(enemy, state, level)
	local x, y = enemy.x - state.step[1], enemy.y - state.step[2]
	if not Levels.blocked(level, x, y) then
		enemy.x, enemy.y = x, y
	end
end

return Enemies
