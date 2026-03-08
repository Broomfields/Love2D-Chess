local Theme  = require("theme")
local Layout = require("layout")
local Audio  = require("audio")

local Menu          = {}
local hoveredButton = nil

function Menu.draw()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonLayout = Layout.getMenuButtons(windowWidth, windowHeight)

    love.graphics.clear(Theme.background)
    love.graphics.setFont(Theme.boldFont)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("Basic Chess Game", 0, windowHeight / 4, windowWidth, "center")

    love.graphics.setFont(Theme.regularFont)
    local buttonFontHeight = Theme.regularFont:getHeight()

    -- Play Game button
    love.graphics.setColor(hoveredButton == "play" and Theme.buttonGreenHov or Theme.buttonGreen)
    love.graphics.rectangle("fill", buttonLayout.x, buttonLayout.playY, buttonLayout.w, buttonLayout.h)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("Play Game", buttonLayout.x, buttonLayout.playY + (buttonLayout.h - buttonFontHeight) / 2, buttonLayout.w, "center")

    -- Options button
    love.graphics.setColor(hoveredButton == "options" and Theme.buttonGreenHov or Theme.buttonGreen)
    love.graphics.rectangle("fill", buttonLayout.x, buttonLayout.optionsY, buttonLayout.w, buttonLayout.h)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("Options", buttonLayout.x, buttonLayout.optionsY + (buttonLayout.h - buttonFontHeight) / 2, buttonLayout.w, "center")

    -- Exit button
    love.graphics.setColor(hoveredButton == "exit" and Theme.buttonRedHov or Theme.buttonRed)
    love.graphics.rectangle("fill", buttonLayout.x, buttonLayout.exitY, buttonLayout.w, buttonLayout.h)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("Exit", buttonLayout.x, buttonLayout.exitY + (buttonLayout.h - buttonFontHeight) / 2, buttonLayout.w, "center")
end

function Menu.handleHover(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonLayout = Layout.getMenuButtons(windowWidth, windowHeight)

    if     Layout.hit(x, y, buttonLayout.x, buttonLayout.playY,    buttonLayout.w, buttonLayout.h) then hoveredButton = "play"
    elseif Layout.hit(x, y, buttonLayout.x, buttonLayout.optionsY, buttonLayout.w, buttonLayout.h) then hoveredButton = "options"
    elseif Layout.hit(x, y, buttonLayout.x, buttonLayout.exitY,    buttonLayout.w, buttonLayout.h) then hoveredButton = "exit"
    else   hoveredButton = nil
    end
end

-- Returns "play" | "options" | "exit" | nil
function Menu.handleClick(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonLayout = Layout.getMenuButtons(windowWidth, windowHeight)

    if Layout.hit(x, y, buttonLayout.x, buttonLayout.playY,    buttonLayout.w, buttonLayout.h) then Audio.play("buttonClick"); return "play"    end
    if Layout.hit(x, y, buttonLayout.x, buttonLayout.optionsY, buttonLayout.w, buttonLayout.h) then Audio.play("buttonClick"); return "options" end
    if Layout.hit(x, y, buttonLayout.x, buttonLayout.exitY,    buttonLayout.w, buttonLayout.h) then Audio.play("buttonClick"); return "exit"    end
end

return Menu
