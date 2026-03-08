local Theme  = require("theme")
local Layout = require("layout")
local Audio  = require("audio")

local Options       = {}
local hoveredButton = nil

function Options.draw()
    local w, h = love.graphics.getDimensions()
    local B    = Layout.getMenuButtons(w, h)

    love.graphics.clear(Theme.background)
    love.graphics.setFont(Theme.boldFont)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("Options", 0, h / 4, w, "center")

    love.graphics.setFont(Theme.regularFont)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("To Do", 0, h / 2, w, "center")

    -- Return button
    love.graphics.setColor(hoveredButton == "return" and Theme.buttonGreenHov or Theme.buttonGreen)
    love.graphics.rectangle("fill", B.x, B.returnY, B.w, B.h)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("Return", B.x, B.returnY + (B.h - Theme.regularFont:getHeight()) / 2, B.w, "center")
end

function Options.handleHover(x, y)
    local w, h = love.graphics.getDimensions()
    local B    = Layout.getMenuButtons(w, h)

    hoveredButton = Layout.hit(x, y, B.x, B.returnY, B.w, B.h) and "return" or nil
end

-- Returns "menu" | nil
function Options.handleClick(x, y)
    local w, h = love.graphics.getDimensions()
    local B    = Layout.getMenuButtons(w, h)

    if Layout.hit(x, y, B.x, B.returnY, B.w, B.h) then
        Audio.play("buttonClick")
        return "menu"
    end
end

return Options
