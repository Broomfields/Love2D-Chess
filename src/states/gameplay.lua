local Gameplay = {}

function Gameplay:enter()
    self.board = require("src.board").new()
end

function Gameplay:update(dt)
    self.board:update(dt)
end

function Gameplay:draw()
    self.board:draw()
end

function Gameplay:mousepressed(x, y, button)
    -- Handle board interaction
    self.board:mousepressed(x, y, button)
end

function Gameplay:keypressed(key)
    -- Handle gameplay-specific input
    if key == "p" then
        gameState:switch("pause")
    end
end

return Gameplay