require("server.console.console")
enet = require("enet")
--------------------------
require 'server.class'
require 'server.util'
Player = require 'player'
tween = require 'tween'
s = require 'server.serialize'
net = require 'server.net'
------------------------------
local isDown = love.keyboard.isDown
localPlayer = nil

local function connect()
	net.connect("192.168.0.72", "2212")
end

function love.load()
	love.window.setTitle("client")
	connect()
end

function love.update(dt)
	net.update(dt)
	tween.update(dt)
	--Controls
	if localPlayer and not console.is_open then
		local ply = localPlayer
		ply.xDesDir, ply.yDesDir = 0, 0
		if isDown("a") then
			ply:move(-1)
		elseif isDown("d") then
			ply:move(1)
		end

		if isDown("w") then
			ply:move(0, -1)
		elseif isDown("s") then
			ply:move(0, 1)
		end
		net.send(ply:netInfo())
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
				if v.pos and v.pos.x and v.pos.y then
					tween.new(1/net.tickRate, ply.pos,  v.pos)
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
		love.graphics.rectangle("fill", player.pos.x, player.pos.y, player.width, player.height)
	end
end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end
