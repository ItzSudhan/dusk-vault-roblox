-- Board: draws the vault from the server's state and nothing else. Tiles come from the rows the
-- server sends, once per vault; pieces slide to where the state puts them; each event of the turn
-- gets a popup, a flash or a shake.

local Draw = require(script.Parent.Draw)

local Board = {}

local WIDTH, HEIGHT = 13, 9
local CELL = UDim2.fromScale(1 / WIDTH, 1 / HEIGHT)
local HOME = UDim2.fromScale(0.015, 0.1)
local SIZE = UDim2.fromScale(0.596, 0.66)
local SLIDE_SECONDS = 0.12
local TILES = { ["#"] = "wall", T = "pad", L = "laserOff", E = "doorLocked" } -- drawn over the floor
local LASER_SPRITES = { on = "laserOn", off = "laserOff", warn = "laserWarn", jammed = "laserJammed" }

-- What the player sees and feels for each event the rules emit. The words come with the event.
local REACTIONS = {
	bump = { shake = true },
	locked = { color = "rose", shake = true },
	unlock = { color = "teal", flash = "teal" },
	pick = { color = "gold" },
	warp = { color = "steel", flash = "steel" },
	use = { color = "ink", flash = "ink" },
	empty = { color = "dim", shake = true },
	hurt = { color = "rose", flash = "rose", shake = true },
	clear = { color = "teal", flash = "teal" },
}

local board, tileLayer, pieceLayer, popupLayer, flashFrame
local pieces = {} -- [id] = the cell of a thief, enemy or item now on the board
local laserCells = {}
local doorCell
local shown = { vault = "", laser = "off", open = false } -- what the tiles currently show

function Board.render(state) -- tiles once per vault; pieces slide; each event flashes or pops
	if shown.vault ~= state.vault then
		Board.drawTiles(state.rows)
		shown.vault = state.vault
	end
	Board.placePieces(state)

	if shown.laser ~= state.laser then
		shown.laser = state.laser
		for _, cell in laserCells do
			Board.redraw(cell, LASER_SPRITES[state.laser])
		end
	end
	local open = state.keys >= state.keysNeeded
	if shown.open ~= open then
		shown.open = open
		Board.redraw(doorCell, if open then "doorOpen" else "doorLocked")
	end

	for _, event in state.events do
		Board.react(event)
	end
end

function Board.mount(parent)
	board = Draw.frame(parent, Draw.colors.pit, HOME, SIZE, 0.02)
	Draw.make("UIAspectRatioConstraint", board, { AspectRatio = WIDTH / HEIGHT })
	tileLayer = Draw.layer(board, 1)
	pieceLayer = Draw.layer(board, 2)
	popupLayer = Draw.layer(board, 3)
	flashFrame = Draw.frame(board, Draw.colors.rose, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 0.02)
	flashFrame.BackgroundTransparency = 1
	flashFrame.ZIndex = 4
end

function Board.cellAt(x, y)
	return UDim2.fromScale((x - 1) / WIDTH, (y - 1) / HEIGHT)
end

function Board.addCell(layer, kind, x, y)
	local cell = Draw.make("Frame", layer, {
		BackgroundTransparency = 1,
		Position = Board.cellAt(x, y),
		Size = CELL,
	})
	Draw.sprite(kind, cell)
	return cell
end

function Board.redraw(cell, kind)
	cell:ClearAllChildren()
	Draw.sprite(kind, cell)
end

function Board.drawTiles(rows)
	tileLayer:ClearAllChildren()
	pieceLayer:ClearAllChildren()
	table.clear(pieces)
	table.clear(laserCells)
	for y, row in rows do
		for x = 1, #row do
			local tile = TILES[string.sub(row, x, x)]
			if tile ~= "wall" then
				Board.addCell(tileLayer, "floor", x, y)
			end
			if tile then
				local cell = Board.addCell(tileLayer, tile, x, y)
				if tile == "laserOff" then
					table.insert(laserCells, cell)
				elseif tile == "doorLocked" then
					doorCell = cell
				end
			end
		end
	end
	shown.laser, shown.open = "off", false
end

function Board.placePieces(state)
	local onBoard = {}
	local function place(id, kind, spot, overlay, covered)
		onBoard[id] = true
		if pieces[id] then
			Draw.tween(pieces[id], SLIDE_SECONDS, { Position = Board.cellAt(spot.x, spot.y) })
		else
			pieces[id] = Board.addCell(pieceLayer, kind, spot.x, spot.y)
		end
		-- A tool at work shows on the piece: haze on a blinded enemy, a veil on the cloaked thief.
		local cover = overlay and pieces[id]:FindFirstChild(overlay)
		if covered and not cover then
			Draw.sprite(overlay, pieces[id])
		elseif cover and not covered then
			cover:Destroy()
		end
	end

	for _, item in state.items do
		place("item" .. item.id, item.kind, item)
	end
	for _, enemy in state.enemies do
		place("enemy" .. enemy.id, enemy.kind, enemy, "haze", state.active.smoke > 0)
	end
	place("player", "player", state.player, "veil", state.active.cloak > 0)

	for id, cell in pieces do
		if not onBoard[id] then
			cell:Destroy()
			pieces[id] = nil
		end
	end
end

function Board.react(event)
	local reaction = REACTIONS[event.name]
	if not reaction then
		return
	end
	if event.text then
		Board.popup(event.text, Draw.colors[reaction.color], event.x, event.y)
	end
	if reaction.flash then
		flashFrame.BackgroundColor3 = Draw.colors[reaction.flash]
		flashFrame.BackgroundTransparency = 0.45
		Draw.tween(flashFrame, 0.45, { BackgroundTransparency = 1 })
	end
	if reaction.shake then
		board.Position = HOME + UDim2.fromOffset(8, 0)
		Draw.tween(board, 0.18, { Position = HOME })
	end
end

-- A word that rises from a tile and fades: points, LOCKED, CAUGHT.
function Board.popup(text, color, x, y)
	local label = Draw.label(
		popupLayer,
		text,
		color,
		Board.cellAt(x - 1.5, y),
		UDim2.fromScale(4 / WIDTH, 1 / HEIGHT),
		Draw.titleFont
	)
	label.TextStrokeColor3 = Draw.colors.night
	label.TextStrokeTransparency = 0
	local rise = Draw.tween(label, 0.8, {
		Position = Board.cellAt(x - 1.5, y - 1),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	rise.Completed:Once(function()
		label:Destroy()
	end)
end

return Board
