local Theme  = require("theme")
local Layout = require("layout")
local Audio  = require("audio")

local Menu          = {}
local hoveredButton = nil

function Menu.draw()
    local w, h = love.graphics.getDimensions()
    local B    = Layout.getMenuButtons(w, h)

    love.graphics.clear(Theme.background)
    love.graphics.setFont(Theme.boldFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Basic Chess Game", 0, h / 4, w, "center")

    love.graphics.setFont(Theme.regularFont)
    local btnFH = Theme.regularFont:getHeight()

    -- Play Game button
    love.graphics.setColor(hoveredButton == "play" and Theme.buttonGreenHov or Theme.buttonGreen)
    love.graphics.rectangle("fill", B.x, B.playY, B.w, B.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Play Game", B.x, B.playY + (B.h - btnFH) / 2, B.w, "center")

    -- Options button
    love.graphics.setColor(hoveredButton == "options" and Theme.buttonGreenHov or Theme.buttonGreen)
    love.graphics.rectangle("fill", B.x, B.optionsY, B.w, B.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Options", B.x, B.optionsY + (B.h - btnFH) / 2, B.w, "center")

    -- Exit button
    love.graphics.setColor(hoveredButton == "exit" and Theme.buttonRedHov or Theme.buttonRed)
    love.graphics.rectangle("fill", B.x, B.exitY, B.w, B.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Exit", B.x, B.exitY + (B.h - btnFH) / 2, B.w, "center")
end

function Menu.handleHover(x, y)
    local w, h = love.graphics.getDimensions()
    local B    = Layout.getMenuButtons(w, h)

    if     Layout.hit(x, y, B.x, B.playY,    B.w, B.h) then hoveredButton = "play"
    elseif Layout.hit(x, y, B.x, B.optionsY, B.w, B.h) then hoveredButton = "options"
    elseif Layout.hit(x, y, B.x, B.exitY,    B.w, B.h) then hoveredButton = "exit"
    else   hoveredButton = nil
    end
end

-- Returns "play" | "options" | "exit" | nil
function Menu.handleClick(x, y)
    local w, h = love.graphics.getDimensions()
    local B    = Layout.getMenuButtons(w, h)

    if Layout.hit(x, y, B.x, B.playY,    B.w, B.h) then Audio.play("buttonClick"); return "play"    end
    if Layout.hit(x, y, B.x, B.optionsY, B.w, B.h) then Audio.play("buttonClick"); return "options" end
    if Layout.hit(x, y, B.x, B.exitY,    B.w, B.h) then Audio.play("buttonClick"); return "exit"    end
end

return Menu
