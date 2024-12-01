local Pause = {}

-- Pause menu options
local options = { "Resume", "Main Menu", "Quit" }
local selectedOption = 1 -- Currently highlighted option

-- Fonts and styles
local font

-- Initialisation for the pause state
function Pause:enter()
    font = love.graphics.newFont(24) -- Standard font for menu items
end

-- Update logic (if needed for animations or input delays)
function Pause:update(dt)
    -- Pause state does not need continuous updates
end

-- Draw the pause menu
function Pause:draw()
    -- Dim the background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Menu title
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Paused", 0, 100, love.graphics.getWidth(), "center")
    
    -- Menu options
    for i, option in ipairs(options) do
        if i == selectedOption then
            love.graphics.setColor(0, 1, 0) -- Highlight selected option
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.printf(option, 0, 200 + i * 40, love.graphics.getWidth(), "center")
    end
end

-- Handle keyboard input
function Pause:keypressed(key)
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
        -- Resume the game when Escape is pressed
        gameState:switch("gameplay")
    end
end

-- Handle selected option
function Pause:selectOption()
    if options[selectedOption] == "Resume" then
        gameState:switch("gameplay") -- Resume the game
    elseif options[selectedOption] == "Main Menu" then
        gameState:switch("menu") -- Return to the main menu
    elseif options[selectedOption] == "Quit" then
        love.event.quit() -- Quit the application
    end
end

-- Handle mouse input (optional)
function Pause:mousepressed(x, y, button)
    local menuStartY = 200
    for i, _ in ipairs(options) do
        local optionY = menuStartY + i * 40
        if y >= optionY and y <= optionY + 30 then -- Check if mouse is over an option
            selectedOption = i
            self:selectOption()
            break
        end
    end
end

return Pause