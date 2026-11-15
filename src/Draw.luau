-- Draw: everything on screen is made here. The dusk palette, the two fonts, the styled frame, label
-- and button, and every piece of the game as a sprite of rounded rectangles. No images are uploaded.

local TweenService = game:GetService("TweenService")

local Draw = {}

Draw.colors = {
	night = Color3.fromRGB(13, 15, 34), -- screen background, outlines
	pit = Color3.fromRGB(19, 22, 48), -- board background between tiles
	floor = Color3.fromRGB(33, 38, 76),
	wall = Color3.fromRGB(74, 84, 150),
	wallTop = Color3.fromRGB(112, 124, 196),
	panel = Color3.fromRGB(26, 30, 62),
	ink = Color3.fromRGB(244, 240, 226), -- text
	dim = Color3.fromRGB(148, 156, 204), -- labels
	cream = Color3.fromRGB(246, 230, 196), -- the thief
	amber = Color3.fromRGB(255, 186, 66), -- title, buttons
	gold = Color3.fromRGB(255, 214, 84), -- keys
	teal = Color3.fromRGB(62, 226, 200), -- gems, open door, victory
	rose = Color3.fromRGB(255, 86, 118), -- guards, lasers, defeat
	roseDark = Color3.fromRGB(150, 44, 82),
	orange = Color3.fromRGB(255, 146, 66), -- hounds
	violet = Color3.fromRGB(172, 124, 255), -- wraiths
	steel = Color3.fromRGB(110, 200, 240), -- drones, pads, the jammer
	lime = Color3.fromRGB(150, 232, 104), -- mimics
}

-- The cast: each enemy's sprite, its name and its rule in a few words, for the ledger and the title.
Draw.CAST = {
	{ kind = "guard", name = "GUARD", rule = "PACES HALLS" },
	{ kind = "hound", name = "HOUND", rule = "CHASES YOU" },
	{ kind = "wraith", name = "WRAITH", rule = "WALKS WALLS" },
	{ kind = "drone", name = "DRONE", rule = "TURNS RIGHT" },
	{ kind = "mimic", name = "MIMIC", rule = "MIRRORS YOU" },
}
Draw.titleFont = Enum.Font.FredokaOne
Draw.textFont = Enum.Font.GothamBold

-- A sprite is a list of shapes laid over one square cell. Each shape is
-- { x, y, width, height, colour name, corner (0 square to 0.5 round), rotation, transparency },
-- with positions and sizes as fractions of the cell.
local SHAPES = {
	player = {
		{ 0.2, 0.14, 0.6, 0.74, "cream", 0.35 }, -- hooded body
		{ 0.2, 0.3, 0.6, 0.22, "night", 0.3 }, -- mask
		{ 0.31, 0.36, 0.11, 0.11, "amber", 0.5 },
		{ 0.58, 0.36, 0.11, 0.11, "amber", 0.5 },
		{ 0.6, 0.58, 0.3, 0.3, "amber", 0.5 }, -- loot sack
		{ 0.69, 0.52, 0.12, 0.1, "gold", 0.3 },
	},
	guard = {
		{ 0.2, 0.28, 0.6, 0.62, "rose", 0.3 },
		{ 0.12, 0.12, 0.76, 0.22, "roseDark", 0.4 }, -- cap
		{ 0.26, 0.42, 0.48, 0.16, "night", 0.4 }, -- visor
		{ 0.42, 0.46, 0.16, 0.08, "ink", 0.5 },
	},
	hound = {
		{ 0.18, 0.12, 0.22, 0.22, "orange", 0.15, 45 }, -- ears
		{ 0.6, 0.12, 0.22, 0.22, "orange", 0.15, 45 },
		{ 0.14, 0.24, 0.72, 0.58, "orange", 0.35 },
		{ 0.34, 0.52, 0.32, 0.26, "cream", 0.4 }, -- snout
		{ 0.43, 0.55, 0.14, 0.09, "night", 0.5 },
		{ 0.27, 0.38, 0.1, 0.1, "night", 0.5 },
		{ 0.63, 0.38, 0.1, 0.1, "night", 0.5 },
	},
	wraith = {
		{ 0.18, 0.1, 0.64, 0.64, "violet", 0.5 },
		{ 0.18, 0.42, 0.64, 0.3, "violet", 0 },
		{ 0.18, 0.62, 0.22, 0.24, "violet", 0.5 }, -- ragged hem
		{ 0.39, 0.62, 0.22, 0.24, "violet", 0.5 },
		{ 0.6, 0.62, 0.22, 0.24, "violet", 0.5 },
		{ 0.3, 0.3, 0.13, 0.18, "ink", 0.5 },
		{ 0.57, 0.3, 0.13, 0.18, "ink", 0.5 },
	},
	key = {
		{ 0.12, 0.3, 0.38, 0.38, "gold", 0.5 },
		{ 0.23, 0.41, 0.16, 0.16, "floor", 0.5 },
		{ 0.46, 0.44, 0.42, 0.1, "gold", 0.3 },
		{ 0.68, 0.5, 0.08, 0.17, "gold", 0.2 },
		{ 0.8, 0.5, 0.07, 0.12, "gold", 0.2 },
	},
	gem = {
		{ 0.29, 0.29, 0.42, 0.42, "teal", 0.12, 45 },
		{ 0.4, 0.34, 0.13, 0.13, "ink", 0.2, 45 },
	},
	smoke = {
		{ 0.24, 0.34, 0.5, 0.5, "dim", 0.5 }, -- the bomb
		{ 0.34, 0.44, 0.13, 0.13, "ink", 0.5 },
		{ 0.45, 0.2, 0.08, 0.18, "cream", 0.3 }, -- fuse
		{ 0.4, 0.1, 0.18, 0.14, "amber", 0.5 },
	},
	haze = { -- over an enemy that a smoke bomb has blinded
		{ 0.02, 0.3, 0.52, 0.52, "ink", 0.5, 0, 0.35 },
		{ 0.4, 0.12, 0.56, 0.56, "ink", 0.5, 0, 0.35 },
		{ 0.34, 0.46, 0.58, 0.5, "ink", 0.5, 0, 0.35 },
	},
	slot = { -- an empty place in a HUD row
		{ 0.36, 0.36, 0.28, 0.28, "wall", 0.5 },
	},
	wall = {
		{ 0.02, 0.02, 0.96, 0.96, "wall", 0.16 },
		{ 0.02, 0.02, 0.96, 0.36, "wallTop", 0.16 },
		{ 0.02, 0.24, 0.96, 0.14, "wall", 0 },
	},
	floor = {
		{ 0.03, 0.03, 0.94, 0.94, "floor", 0.1 },
	},
	doorLocked = {
		{ 0.08, 0.04, 0.84, 0.94, "roseDark", 0.14 },
		{ 0.17, 0.13, 0.66, 0.85, "rose", 0.12 },
		{ 0.4, 0.3, 0.2, 0.2, "night", 0.5 }, -- padlock
		{ 0.34, 0.42, 0.32, 0.26, "night", 0.2 },
	},
	doorOpen = {
		{ 0.08, 0.04, 0.84, 0.94, "teal", 0.14 },
		{ 0.17, 0.13, 0.66, 0.85, "night", 0.12 },
		{ 0.38, 0.3, 0.24, 0.24, "teal", 0.12, 45 }, -- the way out
	},
	laserOff = {
		{ 0.4, 0.03, 0.2, 0.12, "roseDark", 0.3 },
		{ 0.4, 0.85, 0.2, 0.12, "roseDark", 0.3 },
	},
	laserWarn = { -- fires next turn
		{ 0.4, 0.03, 0.2, 0.12, "amber", 0.3 },
		{ 0.4, 0.85, 0.2, 0.12, "amber", 0.3 },
		{ 0.47, 0.12, 0.06, 0.76, "amber", 0.5, 0, 0.3 },
	},
	laserOn = {
		{ 0.4, 0.03, 0.2, 0.12, "rose", 0.3 },
		{ 0.4, 0.85, 0.2, 0.12, "rose", 0.3 },
		{ 0.36, 0.1, 0.28, 0.8, "rose", 0.5 },
		{ 0.46, 0.1, 0.08, 0.8, "ink", 0.5 },
	},
	laserJammed = { -- a jammer holds it dark
		{ 0.4, 0.03, 0.2, 0.12, "steel", 0.3 },
		{ 0.4, 0.85, 0.2, 0.12, "steel", 0.3 },
	},
	drone = {
		{ 0.06, 0.2, 0.26, 0.26, "wallTop", 0.5 }, -- rotors
		{ 0.68, 0.2, 0.26, 0.26, "wallTop", 0.5 },
		{ 0.14, 0.3, 0.72, 0.1, "ink", 0.5 },
		{ 0.24, 0.3, 0.52, 0.5, "steel", 0.4 },
		{ 0.38, 0.46, 0.24, 0.2, "night", 0.5 }, -- lens
		{ 0.45, 0.51, 0.1, 0.1, "rose", 0.5 },
	},
	mimic = { -- the thief's own shape in the wrong colour
		{ 0.2, 0.14, 0.6, 0.74, "lime", 0.35 },
		{ 0.2, 0.3, 0.6, 0.22, "night", 0.3 },
		{ 0.31, 0.36, 0.11, 0.11, "rose", 0.5 },
		{ 0.58, 0.36, 0.11, 0.11, "rose", 0.5 },
	},
	cloak = {
		{ 0.2, 0.12, 0.6, 0.6, "ink", 0.5 }, -- hood
		{ 0.2, 0.42, 0.6, 0.46, "ink", 0.15 },
		{ 0.34, 0.26, 0.32, 0.36, "night", 0.5 },
	},
	jammer = {
		{ 0.46, 0.14, 0.08, 0.34, "steel", 0.3 }, -- aerial
		{ 0.39, 0.06, 0.22, 0.16, "rose", 0.5 },
		{ 0.2, 0.44, 0.6, 0.42, "steel", 0.2 },
		{ 0.3, 0.56, 0.14, 0.14, "night", 0.5 },
		{ 0.56, 0.56, 0.14, 0.14, "night", 0.5 },
	},
	pad = { -- one of a pair of teleport pads
		{ 0.1, 0.1, 0.8, 0.8, "steel", 0.5 },
		{ 0.2, 0.2, 0.6, 0.6, "floor", 0.5 },
		{ 0.36, 0.36, 0.28, 0.28, "steel", 0.5 },
	},
	veil = { -- over the thief while the cloak lasts
		{ 0.06, 0.06, 0.88, 0.88, "night", 0.5, 0, 0.4 },
	},
	done = { -- a vault already cleared, in the heist plan
		{ 0.2, 0.2, 0.6, 0.6, "teal", 0.5 },
		{ 0.38, 0.38, 0.24, 0.24, "night", 0.5 },
	},
	here = { -- the vault being robbed now
		{ 0.2, 0.2, 0.6, 0.6, "amber", 0.5 },
	},
}

function Draw.sprite(kind, parent) -- thief, guard, hound, wraith, key, gem, door, laser: own art
	local sprite = Draw.layer(parent, 1)
	sprite.Name = kind
	for _, shape in SHAPES[kind] do
		local x, y, width, height, colorName, corner, rotation, transparency = table.unpack(shape)
		local part = Draw.frame(
			sprite,
			Draw.colors[colorName],
			UDim2.fromScale(x + width / 2, y + height / 2),
			UDim2.fromScale(width, height),
			corner
		)
		part.AnchorPoint = Vector2.new(0.5, 0.5)
		part.Rotation = rotation or 0
		part.BackgroundTransparency = transparency or 0
	end
	return sprite
end

-- A square cell holding one sprite, for rows of pieces outside the board.
function Draw.icon(kind, parent, position, size)
	local cell = Draw.make("Frame", parent, { BackgroundTransparency = 1, Position = position, Size = size })
	Draw.make("UIAspectRatioConstraint", cell, { AspectRatio = 1 })
	Draw.sprite(kind, cell)
	return cell
end

function Draw.make(className, parent, properties)
	local instance = Instance.new(className)
	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
	end
	for name, value in properties do
		instance[name] = value
	end
	instance.Parent = parent
	return instance
end

function Draw.frame(parent, color, position, size, corner)
	local frame = Draw.make("Frame", parent, { BackgroundColor3 = color, Position = position, Size = size })
	Draw.make("UICorner", frame, { CornerRadius = UDim.new(corner or 0, 0) })
	return frame
end

function Draw.layer(parent, zIndex)
	return Draw.make("Frame", parent, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex,
	})
end

function Draw.label(parent, text, color, position, size, font)
	return Draw.make("TextLabel", parent, {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		TextScaled = true,
		Font = font or Draw.textFont,
		Position = position,
		Size = size,
	})
end

function Draw.button(parent, text, color, position, size, onPress)
	local button = Draw.make("TextButton", parent, {
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = text,
		TextColor3 = Draw.colors.night,
		TextScaled = true,
		Font = Draw.titleFont,
		Position = position,
		Size = size,
	})
	Draw.make("UICorner", button, { CornerRadius = UDim.new(0.25, 0) })
	Draw.make("UIPadding", button, {
		PaddingTop = UDim.new(0.14, 0),
		PaddingBottom = UDim.new(0.14, 0),
		PaddingLeft = UDim.new(0.06, 0),
		PaddingRight = UDim.new(0.06, 0),
	})
	button.Activated:Connect(function()
		button.BackgroundColor3 = Draw.colors.ink
		Draw.tween(button, 0.3, { BackgroundColor3 = color })
		onPress()
	end)
	return button
end

function Draw.tween(instance, seconds, goal)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

return Draw
