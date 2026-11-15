-- Tools: the three things a thief can use besides walking. Each is a count carried through the run
-- and an effect that lasts a set number of turns. Pure: it only changes the state it is given.

local Tools = {}

Tools.KINDS = {
	smoke = { turns = 4, shout = "SMOKE!" }, -- every enemy stands still
	cloak = { turns = 3, shout = "CLOAKED!" }, -- enemies pass through the thief
	jammer = { turns = 5, shout = "LASERS JAMMED!" }, -- no laser fires
}

function Tools.use(state, kind) -- smoke blinds enemies, cloak hides the thief, jammer kills lasers
	if state.tools[kind] <= 0 then
		return false
	end
	state.tools[kind] -= 1
	state.active[kind] = Tools.KINDS[kind].turns
	return true
end

-- A new run starts with one smoke bomb; the rest are found in the vaults.
function Tools.stock(state)
	state.tools = { smoke = 1, cloak = 0, jammer = 0 }
	Tools.calm(state)
end

-- No effect outlives a vault or a lost life.
function Tools.calm(state)
	state.active = { smoke = 0, cloak = 0, jammer = 0 }
end

function Tools.pickUp(state, kind)
	state.tools[kind] += 1
end

-- The end of a turn: every running effect has one turn less.
function Tools.tick(state)
	for kind, turns in state.active do
		state.active[kind] = math.max(0, turns - 1)
	end
end

return Tools
