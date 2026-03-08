local Theme  = require("theme")
local Layout = {}

local MENU_BTN_W = 200
local MENU_BTN_H = 50

-- Returns board geometry for the current window size.
-- Fields: squareSize, boardSize, boardX, boardY
function Layout.getBoard(w, h)
    local sq = math.min(
        (h - 2 * Theme.borderSize - 2 * Theme.uiHeight) / 8,
        (w - 2 * Theme.borderSize) / 8
    )
    local bs = sq * 8
    return {
        squareSize = sq,
        boardSize  = bs,
        boardX     = (w - bs) / 2,
        boardY     = (h - bs) / 2 + Theme.uiHeight / 2,
    }
end

-- Returns menu/options button layout for the current window size.
-- Fields: w, h, x, playY, optionsY, exitY, returnY
function Layout.getMenuButtons(w, h)
    return {
        w        = MENU_BTN_W,
        h        = MENU_BTN_H,
        x        = (w - MENU_BTN_W) / 2,
        playY    = h / 2 - MENU_BTN_H - 10,
        optionsY = h / 2,
        exitY    = h / 2 + MENU_BTN_H + 10,
        returnY  = h / 2 + MENU_BTN_H + 10,
    }
end

-- Returns the resign button rect in game screen coordinates.
-- Fields: x, y, w, h
function Layout.getResignButton(boardX, boardY, boardSize)
    local w = 100
    return {
        x = boardX + boardSize - w,
        y = boardY + boardSize + Theme.borderSize / 2 + 30,
        w = w,
        h = 30,
    }
end

-- Point-in-rect hit test helper used by all screens.
function Layout.hit(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

return Layout
