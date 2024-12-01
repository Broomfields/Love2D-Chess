-- Load necessary modules and initialise global state
local states = require("src.states") -- State machine module
local board = require("src.board")   -- Game board logic
local renderer = require("src.renderer") -- Rendering logic
local input = require("src.input")   -- Input handling

-- Global variables for convenience
local gameState

-- LOVE2D Callbacks
function love.load()
    -- Initialise state machine
    gameState = states.new()
    
    -- Register states, passing gameState itself
    gameState:register("menu", require("src.states.menu"), gameState)
    gameState:register("gameplay", require("src.states.gameplay"), gameState)
    gameState:register("pause", require("src.states.pause"), gameState)
    
    -- Start in the menu state
    gameState:switch("menu")
end

function love.update(dt)
    -- Update the current state
    gameState:update(dt)
end

function love.draw()
    -- Draw the current state
    gameState:draw()
end

function love.mousepressed(x, y, button)
    -- Delegate input to the current state
    gameState:mousepressed(x, y, button)
end

function love.keypressed(key)
    -- Handle global shortcuts (e.g., quit game)
    if key == "escape" then
        love.event.quit()
    end
    
    -- Delegate input to the current state
    gameState:keypressed(key)
end