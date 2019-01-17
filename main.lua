require("server.console.console")
enet = require("enet")
--------------------------
require 'conf'
require 'util'
require 'server.class'
require 'server.util'
Player = require 'player'
tween = require 'tween'
s = require 'server.serialize'
net = require 'server.net'
------------------------------
local isDown = love.keyboard.isDown
function localPlayer()
	if net.localClient then return Player.players[net.localClient.id] end
end

function connect()
	net.connect("192.168.0.72", "2212")
end

function love.load()
	console.Show()
	console.Hide()
	love.window.setTitle("client")
	connect()
end

-----------------------------------
--Update player positions
function net.receive(t)
	--Positions
	if t.positions then
		for k,v in pairs(t.positions) do
			local ply = Player:getById(k)
			if ply and ply.id ~= localPlayer().id then
				if v.pos and v.pos.x and v.pos.y then
					if conf.tween then
						ply.realPos = v.pos
						table.insert(ply.positions, v.pos)
					else
						ply.pos = v.pos
					end
				end
			end
		end
	end
end

local tweenTime = 1/(net.tickRate)
local lastTween = 0
function love.update(dt)
	net.update(dt)
	tween.update(dt)
	--Do tweens
	lastTween = lastTween + dt
	if lastTween >= tweenTime and conf.tween then
		for k, ply in pairs(Player.players) do
			if ply ~= localPlayer() then
				local posLength = #ply.positions
				if posLength >= conf.tweenDelay then
					local newPos = ply.positions[(posLength+1)-conf.tweenDelay]
					tween.new(tweenTime, ply.pos,  newPos)
				end

				if posLength > conf.tweenDelay then
					removeFirst(ply.positions, posLength-conf.tweenDelay)
				end
			end
		end

		lastTween = 0
	end

	--Controls
	if localPlayer() and not console.is_open then
		local ply = localPlayer()
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

--Create player
function net.onConnect(client)
	Player:new(100, 100, client.id)
end
--Delete player
function net.onDisconnect(client)
	Player:getById(client.id):disconnect()
end

--Create local player on server join
function net.onJoin(id)
	Player:new(100, 100, id)
end

love.graphics.setBackgroundColor(.3,.3,.4)
local playerColor = {1,1,1}
function love.draw()
	--Draw players
	for k, player in pairs(Player.players) do
		love.graphics.setColor(playerColor)
		love.graphics.rectangle("fill", player.pos.x, player.pos.y, player.width, player.height)
		--Draw real
		if conf.tween and conf.drawTween and player ~= localPlayer() then
			love.graphics.setColor(factorTable(playerColor, .5))
			love.graphics.rectangle("line", player.realPos.x, player.realPos.y, player.width, player.height)
		end
	end
end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end
-- tween = require 'tween'

-- orig = {x=1}
-- new = {x=2}

-- tween.new(1/64, orig, new)

-- -- local printed = false
-- function love.update(dt)
-- 	tween.update(dt)
-- 	-- if not printed then
-- 	-- 	print("actual:", orig.x)

-- 	-- 	if orig.x == new.x then
-- 	-- 		printed = true
-- 	-- 	end
-- 	-- end
-- end