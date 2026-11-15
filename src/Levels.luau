-- Levels: the three vaults as text maps, read once into walls, lasers, items and enemies.
-- # wall, P start, E exit door, k key, g gem, s smoke bomb, L laser,
-- G guard pacing sideways, V guard pacing up and down, H hound, W wraith.

local Levels = {}

local MAPS = {
	{
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
	{
		name = "THE KENNELS",
		moves = 80,
		rows = {
			"#############",
			"#P....L.g..k#",
			"#.###.#.###.#",
			"#.#s..#...#.#",
			"#.#.###.#.#.#",
			"#...L.H.#..g#",
			"#.###.###.#.#",
			"#k..G...L..E#",
			"#############",
		},
	},
	{
		name = "THE CRYPT",
		moves = 100,
		rows = {
			"#############",
			"#P..L...#g.k#",
			"#.#.###.#.#.#",
			"#.#..k#...#.#",
			"#.###.#L###.#",
			"#...G.....W.#",
			"#.#.###.#.#.#",
			"#s#g.H.k#.LE#",
			"#############",
		},
	},
}

local ITEMS = { k = "key", g = "gem", s = "smoke" }
local ENEMIES = {
	G = { kind = "guard", dx = 1, dy = 0 },
	V = { kind = "guard", dx = 0, dy = 1 },
	H = { kind = "hound", dx = 0, dy = 0 },
	W = { kind = "wraith", dx = 0, dy = 0 },
}

local loaded = {} -- [index] = the level read from its map

Levels.count = #MAPS
Levels.width = #MAPS[1].rows[1]
Levels.height = #MAPS[1].rows

-- The level for a vault number: 1 the gallery, 2 the kennels, 3 the crypt.
function Levels.load(index)
	loaded[index] = loaded[index] or Levels.read(MAPS[index])
	return loaded[index]
end

function Levels.key(x, y)
	return y * 100 + x
end

function Levels.read(map)
	local level = {
		name = map.name,
		moves = map.moves,
		width = Levels.width,
		height = Levels.height,
		walls = {},
		lasers = {},
		items = {},
		enemies = {},
		keysNeeded = 0,
	}
	for y, row in map.rows do
		for x = 1, #row do
			local char = string.sub(row, x, x)
			local key = Levels.key(x, y)
			if char == "#" then
				level.walls[key] = true
			elseif char == "L" then
				level.lasers[key] = true
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
	return level
end

return Levels
