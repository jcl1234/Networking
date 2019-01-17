local Button = class{
	buttons = {},

	init = function(self, x, y, width, height, color, hoverColor)
		self.x = x
		self.y = y
		self.width = width
		self.height = height

		self.color = color or {.8,.3,.3}
		if color == false then self.color = nil end
		self.hoverColor = hoverColor or {1,1,1}
		if hoverColor == false then self.hoverColor = nil end

		self.hovered = false
		self.active = true

		self.round = 5

		table.insert(self.buttons, self)
	end,

	remove = function(self)
		for k, v in pairs(self.buttons) do
			if v == self then
				table.remove(self.buttons, k)
			end
		end
	end,

	inBounds = function(self, x, y)
		if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
			return true
		end
	end,

	onClick = function(self)
	end,

	onHover = function(self)
	end,

	--CLASSMETHODS
	pressed = function(cls, x, y)
		for k, button in pairs(cls.buttons) do
			if button.hovered then
				if button.onClick then button:onClick() end
			end
		end
	end,

	update = function(cls, dt)
		local mouseX, mouseY = love.mouse.getPosition()
		for k, button in pairs(cls.buttons) do
			button.hovered = false
			if button.active then
				if button:inBounds(mouseX, mouseY) then
					button.hovered = true
					if button.onHover then button:onHover() end
				end
			end
		end
	end,


	--Draw
	draw = function(cls)
		for k, button in pairs(cls.buttons) do
			if button.active then
				if button.color then
					love.graphics.setColor(button.color)
					love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, button.round, button.round)
				end
				--Outline
				if button.hoverColor and button.hovered then
					love.graphics.setColor(button.hoverColor)
					love.graphics.rectangle("line", button.x, button.y, button.width, button.height, button.round, button.round)
				end
			end
		end
	end,
}

return Button