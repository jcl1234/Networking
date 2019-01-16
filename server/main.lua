require("console.console")
enet = require("enet")
--------------------------
s = require 'serialize'
require 'util'
require 'class'
net = require 'net'
--------------------------
function create()
	net.create()
	-- net.create("192.168.0.72", "2212")
end

function net.onConnect(client)

end


function love.load()
	love.window.setMode(400,300)
	love.window.setTitle("server")
	console.Show()
	create()
end

function love.update(dt)
	net.update(dt)
end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end