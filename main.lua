require("server.console.console")
enet = require("enet")
--------------------------
require 'server.class'
require 'server.util'
Player = require 'player'
s = require 'server.serialize'
net = require 'server.net'
------------------------------
local isDown = love.keyboard.isDown
local localPlayer = nil

local function connect()
	net.connect("192.168.0.72", "2212")
end

function love.load()
	connect()
end

function love.update(dt)
	net.update(dt)
	--Controls
	if localPlayer then
		if isDown("a") then
			localPlayer.x = localPlayer.x - localPlayer.speed
		elseif isDown("d") then
			localPlayer.x = localPlayer.x + localPlayer.speed
		end

		if isDown("w") then
			localPlayer.y = localPlayer.y - localPlayer.speed
		elseif isDown("s") then
			localPlayer.y = localPlayer.y + localPlayer.speed
		end
		net.send({x=localPlayer.x, y=localPlayer.y})
	end
end
-----------------------------------
--Update player positions
function net.receive(t)
	--Positions
	if t.positions then
		for k,v in pairs(t.positions) do
			local ply = Player:getById(k)
			if ply and ply.id ~= localPlayer.id then
				if v.x and v.y then
					ply.x = v.x
					ply.y = v.y
				end
			end
		end
	end
end

--Create player
function net.onConnect(client)
	Player:new(100, 100, client.id)
end
--Delete player
function net.onDisconnect(client)
	Player:getById(client.id):remove()
end

--Create local player on server join
function net.onJoin(id)
	localPlayer = Player:new(100, 100, id)
end

love.graphics.setBackgroundColor(.3,.3,.4)
local playerColor = {1,1,1}
function love.draw()
	--Draw players
	love.graphics.setColor(playerColor)
	for k, player in pairs(Player.players) do
		love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
	end
end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end
