require("console.console")
enet = require("enet")
--------------------------
s = require 'serialize'
require 'util'
net = require 'net'
--------------------------

local positions = {}
function net.receive(t, client)
	positions[client.id] = positions[client.id] or {}
	positions[client.id].x = t.x
	positions[client.id].y = t.y
end



function love.load()
	console.Show()
	net.create("192.168.0.72", "2212")
end

function love.update(dt)
	net.update(dt)
	net.send({positions=positions})
end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end