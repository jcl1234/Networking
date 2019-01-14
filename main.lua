require("console.console")
enet = require("enet")
--------------------------
s = require('serialize')
server = require("server")

function love.load()

end

function love.update(dt)

end

function love.draw()

end


--Console-------------------------------
function love.keypressed(key)
	if key == '`' then console.Show() end
end