ui = {}
ui.Logger = require 'ui.logger'
ui.Button = require 'ui.button'

function ui.mousepressed(x, y, button)
	ui.Button:pressed(x, y, button)
end

function ui.update(dt)
	ui.Logger:update(dt)
	ui.Button:update(dt)
end

function ui.draw()
	ui.Logger:draw()
	ui.Button:draw()
end

--[[
require 'class'
-----------------------
require 'conf'
require 'util'
require 'ui'

function love.load()
	love.window.setMode(conf.window.width, conf.window.height)
	love.window.setTitle(conf.window.title)

	local logWidth, logHeight = conf.logger.width, conf.logger.height
	local logX, logY = conf.window.width/2-logWidth/2, conf.window.height-logHeight-5
	logger = ui.Logger:new(logX, logY, logWidth, logHeight)

	but = ui.Button:new(0,0, 50, 20, {1,1,1,.3})
	but.onClick = function() logger:addLine("Nick: fag") end
end

--Input
function love.mousepressed(x, y, button)
	ui.mousepressed(x, y, button)
end

function love.update(dt)
	ui.update(dt)
end

function love.draw()
	ui.draw()
end
]]