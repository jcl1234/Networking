require("server.console.console")
enet = require("enet")
--------------------------
require 'conf'
require 'server.class'
require 'server.util'
tween = require 'tween'
s = require 'server.serialize'
net = require 'server.net'
------------------------------
function connect()
	love.window.setMode(400,300)
	console.Show()
	net.connect()
	-- net.connect("192.168.0.72", "2212")
end

function love.load()
	love.window.setTitle("client")
	connect()
end

function love.update(dt)
	net.update(dt)
end
-----------------------------------
--Update player positions
function net.receive(t)
end

--Create player
function net.onConnect(client)
end
--Delete player
function net.onDisconnect(client)
end

--Create local player on server join
function net.onJoin(id)
end

love.graphics.setBackgroundColor(.8,.3,.3)
function love.draw()
end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end
