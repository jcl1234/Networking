local Player = class({
	players = {},
	init = function(self, x, y, id)
		self.width = 10
		self.height = 10

		self.pos = {x=x, y=y}

		self.speed = 3

		self.id = id

		self.players[self.id] = self
	end,

	remove = function(self)
		self.players[self.id] = nil
	end,

	--Info to be networked
	netInfo = function(self)
		local t = {}
		t.pos = self.pos

		return t
	end,

	--Incremental move based on speed
	move = function(self, xDir, yDir, speed)
		speed = speed or self.speed
		yDir = yDir or 0
		if xDir == -1 then
			self.pos.x = self.pos.x - self.speed
		elseif xDir == 1 then
			self.pos.x = self.pos.x + self.speed
		end

		if yDir == -1 then
			self.pos.y = self.pos.y - self.speed
		elseif yDir == 1 then
			self.pos.y = self.pos.y + self.speed
		end
	end,

	--CLASMETHODS
	getById = function(cls, id)
		return cls.players[id]
	end,

	})

return Player