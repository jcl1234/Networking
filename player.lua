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

	--CLASMETHODS
	getById = function(cls, id)
		return cls.players[id]
	end,

	})

return Player