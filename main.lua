local Theme   = require("theme")
local Audio   = require("audio")
local Popup   = require("ui")
local Menu    = require("screens/menu")
local Options = require("screens/options")
local Game    = require("screens/game")

local gameState = "menu"

function love.load()
    Theme.load()
    Audio.load("pieceMoved",  "assets/sounds/pieceMoved.ogg")
    Audio.load("pieceTaken",  "assets/sounds/pieceTaken.ogg")
    Audio.load("buttonClick", "assets/sounds/buttonClick.ogg")
    Audio.load("inCheck",     "assets/sounds/inCheck.ogg")
    love.window.setTitle("Basic Chess Game")
    love.window.setMode(800, 800, {resizable = true, minwidth = 400, minheight = 400})
end

function love.draw()
    if      gameState == "menu"    then Menu.draw()
    elseif  gameState == "options" then Options.draw()
    elseif  gameState == "playing" then Game.draw()
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    if Popup.isOpen() then Popup.mousepressed(x, y); return end

    if gameState == "menu" then
        local ev = Menu.handleClick(x, y)
        if ev == "play" then
            Game.init({ onTransition = function(s) gameState = s end })
            gameState = "playing"
        elseif ev == "options" then
            gameState = "options"
        elseif ev == "exit" then
            love.event.quit()
        end

    elseif gameState == "options" then
        if Options.handleClick(x, y) == "menu" then gameState = "menu" end

    elseif gameState == "playing" then
        Game.handleClick(x, y)
    end
end

function love.mousemoved(x, y)
    if Popup.isOpen() then Popup.mousemoved(x, y); return end
    if      gameState == "menu"    then Menu.handleHover(x, y)
    elseif  gameState == "options" then Options.handleHover(x, y)
    elseif  gameState == "playing" then Game.handleHover(x, y)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then Popup.mousereleased() end
end
