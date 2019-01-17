require("console.console")
enet = require("enet")
--------------------------
s = require 'serialize'
require 'util'
net = require 'net'
--------------------------

local positions = {}
function net.receive(t, client)
	positions[client.id] = t
end



function love.load()
	love.window.setMode(400,300)
	love.window.setTitle("server")
	console.Show()
	net.create("192.168.0.72", "2212")
	print("started server with a tickrate of "..net.tickRate)
end

function love.update(dt)
	net.update(dt)
	net.send({positions=positions})
end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end