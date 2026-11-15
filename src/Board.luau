-- Board: draws the vault from the server's state. Tiles are drawn once per level; pieces slide to
-- where the state puts them; each event of the turn gets a popup, a flash or a shake.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Levels = require(ReplicatedStorage.Levels)
local Rules = require(ReplicatedStorage.Rules)
local Draw = require(script.Parent.Draw)

local Board = {}

local WIDTH, HEIGHT = Levels.width, Levels.height
local CELL = UDim2.fromScale(1 / WIDTH, 1 / HEIGHT)
local HOME = UDim2.fromScale(0.02, 0.14)
local SLIDE_SECONDS = 0.12
local LASER_SPRITES = { [0] = "laserOn", [1] = "laserOff", [2] = "laserWarn" }

-- What the player sees and feels for each event the rules emit.
local REACTIONS = {
	bump = { shake = true },
	locked = { text = "LOCKED", color = "rose", shake = true },
	unlock = { text = "DOOR OPEN", color = "teal", flash = "teal" },
	gem = { text = "+" .. Rules.POINTS.gem, color = "teal" },
	key = { text = "+" .. Rules.POINTS.key, color = "gold" },
	smoke = { text = "+" .. Rules.POINTS.smoke, color = "ink" },
	haze = { text = "SMOKE!", color = "ink", flash = "ink" },
	empty = { text = "NO SMOKE", color = "dim", shake = true },
	hurt = { color = "rose", flash = "rose", shake = true }, -- its text is the cause
}

local board, tileLayer, pieceLayer, popupLayer, flashFrame
local pieces = {} -- [id] = the cell of a thief, enemy or item now on the board
local laserCells = {}
local doorCell
local shown = { level = 0, laser = 1, open = false } -- what the tiles currently show

function Board.render(state) -- tiles once per level; pieces slide; each event flashes or pops
	local level = Levels.load(state.level)
	if shown.level ~= state.level then
		Board.drawTiles(level)
		shown.level = state.level
	end
	Board.placePieces(state)

	local laser = state.turn % Rules.LASER_PERIOD
	if shown.laser ~= laser then
		shown.laser = laser
		for _, cell in laserCells do
			Board.redraw(cell, LASER_SPRITES[laser])
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
	board = Draw.frame(parent, Draw.colors.pit, HOME, UDim2.fromScale(0.7, 0.83), 0.02)
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

function Board.drawTiles(level)
	tileLayer:ClearAllChildren()
	pieceLayer:ClearAllChildren()
	table.clear(pieces)
	table.clear(laserCells)
	for y = 1, HEIGHT do
		for x = 1, WIDTH do
			local key = Levels.key(x, y)
			Board.addCell(tileLayer, if level.walls[key] then "wall" else "floor", x, y)
			if level.lasers[key] then
				table.insert(laserCells, Board.addCell(tileLayer, "laserOff", x, y))
			end
		end
	end
	doorCell = Board.addCell(tileLayer, "doorLocked", level.exit.x, level.exit.y)
	shown.laser, shown.open = 1, false
end

function Board.placePieces(state)
	local onBoard = {}
	local function place(id, kind, spot)
		onBoard[id] = true
		if pieces[id] then
			Draw.tween(pieces[id], SLIDE_SECONDS, { Position = Board.cellAt(spot.x, spot.y) })
		else
			pieces[id] = Board.addCell(pieceLayer, kind, spot.x, spot.y)
		end
		return pieces[id]
	end

	for _, item in state.items do
		place("item" .. item.id, item.kind, item)
	end
	for _, enemy in state.enemies do
		local cell = place("enemy" .. enemy.id, enemy.kind, enemy)
		local haze = cell:FindFirstChild("haze")
		if state.frozen > 0 and not haze then
			Draw.sprite("haze", cell)
		elseif state.frozen <= 0 and haze then
			haze:Destroy()
		end
	end
	place("player", "player", state.player)

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
	local text = reaction.text or event.text
	if text then
		Board.popup(text, Draw.colors[reaction.color], event.x, event.y)
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
