local Theme  = require("theme")
local Layout = {}

local MENU_BTN_W = 200
local MENU_BTN_H = 50

-- Returns board geometry for the current window size.
-- Fields: squareSize, boardSize, boardX, boardY
function Layout.getBoard(windowWidth, windowHeight)
    local squareSize = math.min(
        (windowHeight - 2 * Theme.borderSize - 2 * Theme.uiHeight) / 8,
        (windowWidth  - 2 * Theme.borderSize) / 8
    )
    local boardSize = squareSize * 8
    return {
        squareSize = squareSize,
        boardSize  = boardSize,
        boardX     = (windowWidth  - boardSize) / 2,
        boardY     = (windowHeight - boardSize) / 2 + Theme.uiHeight / 2,
    }
end

-- Returns menu/options button layout for the current window size.
-- Fields: w, h, x, playY, optionsY, exitY, returnY
function Layout.getMenuButtons(windowWidth, windowHeight)
    return {
        w        = MENU_BTN_W,
        h        = MENU_BTN_H,
        x        = (windowWidth - MENU_BTN_W) / 2,
        playY    = windowHeight / 2 - MENU_BTN_H - 10,
        optionsY = windowHeight / 2,
        exitY    = windowHeight / 2 + MENU_BTN_H + 10,
        returnY  = windowHeight / 2 + MENU_BTN_H + 10,
    }
end

-- Returns the resign button rect in game screen coordinates.
-- Fields: x, y, w, h
function Layout.getResignButton(boardX, boardY, boardSize)
    local buttonWidth = 100
    return {
        x = boardX + boardSize - buttonWidth,
        y = boardY + boardSize + Theme.borderSize / 2 + 30,
        w = buttonWidth,
        h = 30,
    }
end

-- Point-in-rect hit test helper used by all screens.
function Layout.hit(pointX, pointY, rectX, rectY, rectWidth, rectHeight)
    return pointX >= rectX and pointX <= rectX + rectWidth
       and pointY >= rectY and pointY <= rectY + rectHeight
end

return Layout
