local Menu = {}
local gameState

-- Menu options
local options = { "Start Game", "Settings", "Quit" }
local selectedOption = 1 -- Currently highlighted option

-- Fonts and visual styles
local font
local titleFont

function Menu:init(stateMachine)
    gameState = stateMachine -- Store the reference
end

-- Menu state initialisation
function Menu:enter()
    font = love.graphics.newFont(24) -- Standard font for menu items
    titleFont = love.graphics.newFont(36) -- Larger font for the title
end

-- Update logic (if needed for animations or input delays)
function Menu:update(dt)
    -- No dynamic updates needed for static menu
end

-- Draw the menu
function Menu:draw()
    -- Background colour
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Chess Game", 0, 50, love.graphics.getWidth(), "center")

    -- Menu options
    love.graphics.setFont(font)
    for i, option in ipairs(options) do
        if i == selectedOption then
            love.graphics.setColor(0, 1, 0) -- Highlight selected option
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.printf(option, 0, 150 + i * 40, love.graphics.getWidth(), "center")
    end
end

-- Handle keyboard input
function Menu:keypressed(key)
    if key == "up" then
        selectedOption = selectedOption - 1
        if selectedOption < 1 then
            selectedOption = #options
        end
    elseif key == "down" then
        selectedOption = selectedOption + 1
        if selectedOption > #options then
            selectedOption = 1
        end
    elseif key == "return" or key == "enter" then
        self:selectOption()
    elseif key == "escape" then
        love.event.quit() -- Quit on Escape
    end
end

-- Handle mouse input (optional)
function Menu:mousepressed(x, y, button)
    -- Detect clicks on menu options if implemented
    local menuStartY = 150
    for i, _ in ipairs(options) do
        local optionY = menuStartY + i * 40
        if y >= optionY and y <= optionY + 30 then -- Check if mouse is over an option
            selectedOption = i
            self:selectOption()
            break
        end
    end
end

-- Handle selected option
function Menu:selectOption()
    if options[selectedOption] == "Start Game" then
        gameState:switch("gameplay")
    elseif options[selectedOption] == "Settings" then
        gameState:switch("settings") -- Requires a "settings" state
    elseif options[selectedOption] == "Quit" then
        love.event.quit()
    end
end

return Menu