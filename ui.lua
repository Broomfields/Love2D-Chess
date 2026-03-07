local Theme = require("theme")

local Popup = {}

local TITLE_H  = 30
local PADDING  = 16
local BUTTON_H = 36
local BUTTON_W = 130
local ITEM_SIZE = 72
local ITEM_GAP  = 8
local CORNER_R  = 6

local active       = nil
local popupX, popupY = 0, 0
local dragging     = false
local dragOffsetX, dragOffsetY = 0, 0
local hoveredButton = nil
local hoveredItem   = nil

function Popup.isOpen()
    return active ~= nil
end

function Popup.show(config)
    local w, h = love.graphics.getDimensions()
    popupX = (w - config.width) / 2
    popupY = (h - config.height) / 2
    active = config
    dragging = false
    hoveredButton = nil
    hoveredItem = nil
end

function Popup.hide()
    active = nil
    dragging = false
    hoveredButton = nil
    hoveredItem = nil
end

function Popup.draw()
    if not active then return end

    local w, h = love.graphics.getDimensions()
    local cfg = active
    local px, py = popupX, popupY

    -- Dim overlay
    love.graphics.setColor(Theme.popupDim)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Panel background
    love.graphics.setColor(Theme.popupPanel)
    love.graphics.rectangle("fill", px, py, cfg.width, cfg.height, CORNER_R, CORNER_R)

    -- Title bar (drawn over panel so rounded corners only show at top)
    love.graphics.setColor(Theme.popupTitle)
    love.graphics.rectangle("fill", px, py, cfg.width, TITLE_H, CORNER_R, CORNER_R)
    love.graphics.rectangle("fill", px, py + TITLE_H - CORNER_R, cfg.width, CORNER_R)

    -- Title text
    love.graphics.setFont(boldFont)
    love.graphics.setColor(1, 1, 1)
    local titleFH = love.graphics.getFont():getHeight()
    love.graphics.printf(cfg.title, px, py + (TITLE_H - titleFH) / 2, cfg.width, "center")

    if cfg.type == "message" then
        -- Message text
        love.graphics.setFont(regularFont)
        love.graphics.setColor(cfg.messageColour or {1, 1, 1})
        love.graphics.printf(cfg.message, px + PADDING, py + TITLE_H + PADDING, cfg.width - 2 * PADDING, "center")

        -- Buttons
        local numButtons = #cfg.buttons
        local totalW = numButtons * BUTTON_W + (numButtons - 1) * PADDING
        local startX = px + (cfg.width - totalW) / 2
        local btnY = py + cfg.height - BUTTON_H - PADDING

        love.graphics.setFont(regularFont)
        local btnFH = love.graphics.getFont():getHeight()

        for idx, btn in ipairs(cfg.buttons) do
            local bx = startX + (idx - 1) * (BUTTON_W + PADDING)
            local isHov = (hoveredButton == idx)
            if btn.style == "danger" then
                love.graphics.setColor(isHov and Theme.buttonRedHov or Theme.buttonRed)
            else
                love.graphics.setColor(isHov and Theme.buttonGreenHov or Theme.buttonGreen)
            end
            love.graphics.rectangle("fill", bx, btnY, BUTTON_W, BUTTON_H, 4, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.label, bx, btnY + (BUTTON_H - btnFH) / 2, BUTTON_W, "center")
        end

    elseif cfg.type == "picker" then
        -- Item tiles
        local numItems = #cfg.items
        local totalW = numItems * ITEM_SIZE + (numItems - 1) * ITEM_GAP
        local startX = px + (cfg.width - totalW) / 2
        local itemY = py + TITLE_H + PADDING

        for idx, item in ipairs(cfg.items) do
            local ix = startX + (idx - 1) * (ITEM_SIZE + ITEM_GAP)

            -- Tile background
            love.graphics.setColor(Theme.popupItemBg)
            love.graphics.rectangle("fill", ix, itemY, ITEM_SIZE, ITEM_SIZE, 4, 4)

            -- Piece image
            if item.image then
                local iw = item.image:getWidth()
                local ih = item.image:getHeight()
                local scale = 0.85 * ITEM_SIZE / math.max(iw, ih)
                local ox = (ITEM_SIZE - iw * scale) / 2
                local oy = (ITEM_SIZE - ih * scale) / 2
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(item.image, ix + ox, itemY + oy, 0, scale, scale)
            end

            -- Hover highlight
            if hoveredItem == idx then
                love.graphics.setColor(Theme.popupItemHov)
                love.graphics.rectangle("fill", ix, itemY, ITEM_SIZE, ITEM_SIZE, 4, 4)
            end
        end
    end
end

function Popup.mousepressed(x, y)
    if not active then return end

    local cfg = active
    local px, py = popupX, popupY

    -- Title bar → start drag
    if x >= px and x <= px + cfg.width and y >= py and y <= py + TITLE_H then
        dragging = true
        dragOffsetX = x - px
        dragOffsetY = y - py
        return
    end

    if cfg.type == "message" then
        local numButtons = #cfg.buttons
        local totalW = numButtons * BUTTON_W + (numButtons - 1) * PADDING
        local startX = px + (cfg.width - totalW) / 2
        local btnY = py + cfg.height - BUTTON_H - PADDING

        for idx, btn in ipairs(cfg.buttons) do
            local bx = startX + (idx - 1) * (BUTTON_W + PADDING)
            if x >= bx and x <= bx + BUTTON_W and y >= btnY and y <= btnY + BUTTON_H then
                if cfg.onButton then cfg.onButton(btn.label) end
                return
            end
        end

    elseif cfg.type == "picker" then
        local numItems = #cfg.items
        local totalW = numItems * ITEM_SIZE + (numItems - 1) * ITEM_GAP
        local startX = px + (cfg.width - totalW) / 2
        local itemY = py + TITLE_H + PADDING

        for idx, item in ipairs(cfg.items) do
            local ix = startX + (idx - 1) * (ITEM_SIZE + ITEM_GAP)
            if x >= ix and x <= ix + ITEM_SIZE and y >= itemY and y <= itemY + ITEM_SIZE then
                if cfg.onPick then cfg.onPick(item.value) end
                return
            end
        end
    end
end

function Popup.mousemoved(x, y)
    if not active then return end

    if dragging then
        popupX = x - dragOffsetX
        popupY = y - dragOffsetY
        return
    end

    local cfg = active
    local px, py = popupX, popupY
    hoveredButton = nil
    hoveredItem = nil

    if cfg.type == "message" then
        local numButtons = #cfg.buttons
        local totalW = numButtons * BUTTON_W + (numButtons - 1) * PADDING
        local startX = px + (cfg.width - totalW) / 2
        local btnY = py + cfg.height - BUTTON_H - PADDING

        for idx, btn in ipairs(cfg.buttons) do
            local bx = startX + (idx - 1) * (BUTTON_W + PADDING)
            if x >= bx and x <= bx + BUTTON_W and y >= btnY and y <= btnY + BUTTON_H then
                hoveredButton = idx
                break
            end
        end

    elseif cfg.type == "picker" then
        local numItems = #cfg.items
        local totalW = numItems * ITEM_SIZE + (numItems - 1) * ITEM_GAP
        local startX = px + (cfg.width - totalW) / 2
        local itemY = py + TITLE_H + PADDING

        for idx, item in ipairs(cfg.items) do
            local ix = startX + (idx - 1) * (ITEM_SIZE + ITEM_GAP)
            if x >= ix and x <= ix + ITEM_SIZE and y >= itemY and y <= itemY + ITEM_SIZE then
                hoveredItem = idx
                break
            end
        end
    end
end

function Popup.mousereleased()
    dragging = false
end

return Popup
