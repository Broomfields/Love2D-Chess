local Theme = {}

local function hex(h)
    h = h:gsub("#", "")
    return {
        tonumber("0x" .. h:sub(1, 2)) / 255,
        tonumber("0x" .. h:sub(3, 4)) / 255,
        tonumber("0x" .. h:sub(5, 6)) / 255,
    }
end

-- Board
Theme.boardLight     = hex("#EBECD3")
Theme.boardDark      = hex("#7D945D")
Theme.border         = hex("#453643")
Theme.background     = hex("#B4C098")

-- General UI
Theme.text           = {1, 1, 1}
Theme.hoverOrange    = {1, 0.5, 0, 0.5}
Theme.selectBlue     = {0, 0.75, 1}
Theme.checkRed       = {1, 0, 0}
Theme.moveAmber      = {1, 0.75, 0}
Theme.buttonGreen    = {0.2, 0.6, 0.2}
Theme.buttonGreenHov = {0.3, 0.7, 0.3}
Theme.buttonRed      = {0.8, 0.1, 0.1}
Theme.buttonRedHov   = {0.9, 0.2, 0.2}
Theme.checkBadge     = {0.85, 0.1, 0.1}

-- Popup
Theme.popupPanel     = {0.22, 0.21, 0.27}
Theme.popupTitle     = {0.27, 0.20, 0.26}
Theme.popupDim       = {0, 0, 0, 0.5}
Theme.popupItemHov   = {1, 1, 1, 0.2}
Theme.popupItemBg    = {0.65, 0.65, 0.65}

-- Call once from love.load() to initialise font resources.
function Theme.load()
    Theme.boldFont    = love.graphics.newFont("assets/fonts/OpenDyslexic-Bold.otf", 14)
    Theme.regularFont = love.graphics.newFont("assets/fonts/OpenDyslexic-Regular.otf", 14)
end

return Theme
