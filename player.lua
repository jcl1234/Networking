local Player = class({
	players = {},
	init = function(self, x, y, id)
		self.width = 10
		self.height = 10

		self.x = x
		self.y = y

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
		t.x = self.x
		t.y = self.y

		return t
	end,

	--Incremental move based on speed
	move = function(self, xDir, yDir, speed)
		speed = speed or self.speed
		yDir = yDir or 0
		if xDir == -1 then
			self.x = self.x - self.speed
		elseif xDir == 1 then
			self.x = self.x + self.speed
		end

		if yDir == -1 then
			self.y = self.y - self.speed
		elseif yDir == 1 then
			self.y = self.y + self.speed
		end
	end,

	--CLASMETHODS
	getById = function(cls, id)
		return cls.players[id]
	end,

	})

return Player