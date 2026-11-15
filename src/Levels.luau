-- Levels: the six vaults as text maps, read once into walls, lasers, pads, items and enemies.
-- # wall, P start, E exit door, k key, g gem, L laser, T teleport pad (two to a vault),
-- tools to pick up: s smoke, c cloak, j jammer,
-- enemies: G guard pacing sideways, V guard pacing up and down, H hound, W wraith, D drone, M mimic.

local Levels = {}

local MAPS = {
	{ -- guards only: learn keys and the door
		name = "THE GALLERY",
		moves = 60,
		rows = {
			"#############",
			"#P..#...g...#",
			"#...#.###.#.#",
			"#.G.......#k#",
			"#...#.#.#.#.#",
			"#.#...#g#...#",
			"#.#.#.#.###.#",
			"#g..#..V...E#",
			"#############",
		},
	},
	{ -- its twist: lasers that fire every third turn, and the first hound
		name = "THE KENNELS",
		moves = 80,
		rows = {
			"#############",
			"#P....L.g..k#",
			"#.###.#.###.#",
			"#.#j..#...#.#",
			"#.#.###.#.#.#",
			"#...L.H.#..g#",
			"#.###.###.#.#",
			"#k..G...L..E#",
			"#############",
		},
	},
	{ -- its twist: a wraith that no wall stops
		name = "THE CRYPT",
		moves = 100,
		rows = {
			"#############",
			"#P..L...#g.k#",
			"#.#.###.#.#.#",
			"#.#..k#..c#.#",
			"#.###.#L###.#",
			"#...G.....W.#",
			"#.#.###.#.#.#",
			"#s#g.H.k#.LE#",
			"#############",
		},
	},
	{ -- its twist: two drones circling an outer and an inner ring
		name = "THE FOUNDRY",
		moves = 80,
		rows = {
			"#############",
			"#P....g....k#",
			"#.#########.#",
			"#..D.....s#.#",
			"#.#.#####.#.#",
			"#.#...k.....#",
			"#.#########.#",
			"#D....g....E#",
			"#############",
		},
	},
	{ -- its twist: teleport pads, the only way to the sealed key, and a mimic
		name = "THE MIRROR HALL",
		moves = 80,
		rows = {
			"#############",
			"#P...#k#...M#",
			"#.##.#.#.##.#",
			"#....#T#....#",
			"#.##.....##.#",
			"#..g.###.c..#",
			"#.##.....##.#",
			"#T..k.G....E#",
			"#############",
		},
	},
	{ -- its twist: all five enemy kinds at once
		name = "THE CROWN ROOM",
		moves = 110,
		rows = {
			"#############",
			"#P...L....Wk#",
			"#.###.###.#.#",
			"#...#.G.#...#",
			"#.#.#.#.#.#.#",
			"#k#...M...#.#",
			"#.#####.###.#",
			"#D...H..L.jE#",
			"#############",
		},
	},
}

local ITEMS = { k = "key", g = "gem", s = "smoke", c = "cloak", j = "jammer" }
local ENEMIES = {
	G = { kind = "guard", dx = 1, dy = 0 },
	V = { kind = "guard", dx = 0, dy = 1 },
	H = { kind = "hound", dx = 0, dy = 0 },
	W = { kind = "wraith", dx = 0, dy = 0 },
	D = { kind = "drone", dx = 1, dy = 0 },
	M = { kind = "mimic", dx = 0, dy = 0 },
}

local loaded = {} -- [index] = the level read from its map

Levels.count = #MAPS
Levels.width = #MAPS[1].rows[1]
Levels.height = #MAPS[1].rows

-- The level for a vault number, 1 to 6.
function Levels.load(index)
	loaded[index] = loaded[index] or Levels.read(MAPS[index])
	return loaded[index]
end

function Levels.key(x, y)
	return y * 100 + x
end

-- Walls and the exit door stop every enemy that walks.
function Levels.blocked(level, x, y)
	return level.walls[Levels.key(x, y)] == true or (x == level.exit.x and y == level.exit.y)
end

function Levels.read(map)
	local level = {
		name = map.name,
		moves = map.moves,
		rows = map.rows,
		width = Levels.width,
		height = Levels.height,
		walls = {},
		lasers = {},
		pads = {}, -- [key of a pad] = the tile of its twin
		items = {},
		enemies = {},
		keysNeeded = 0,
	}
	local padTiles = {}
	for y, row in map.rows do
		for x = 1, #row do
			local char = string.sub(row, x, x)
			local key = Levels.key(x, y)
			if char == "#" then
				level.walls[key] = true
			elseif char == "L" then
				level.lasers[key] = true
			elseif char == "T" then
				table.insert(padTiles, { x = x, y = y })
			elseif char == "P" then
				level.start = { x = x, y = y }
			elseif char == "E" then
				level.exit = { x = x, y = y }
			elseif ITEMS[char] then
				table.insert(level.items, { id = #level.items + 1, kind = ITEMS[char], x = x, y = y })
				if char == "k" then
					level.keysNeeded += 1
				end
			elseif ENEMIES[char] then
				local enemy = ENEMIES[char]
				table.insert(level.enemies, {
					id = #level.enemies + 1,
					kind = enemy.kind,
					x = x,
					y = y,
					dx = enemy.dx,
					dy = enemy.dy,
				})
			end
		end
	end
	if #padTiles == 2 then
		level.pads[Levels.key(padTiles[1].x, padTiles[1].y)] = padTiles[2]
		level.pads[Levels.key(padTiles[2].x, padTiles[2].y)] = padTiles[1]
	end
	return level
end

return Levels
