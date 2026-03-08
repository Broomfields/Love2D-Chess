local Theme = require("theme")

local Popup = {}

local TITLE_H   = 30
local PADDING   = 16
local BUTTON_H  = 36
local BUTTON_W  = 130
local ITEM_SIZE = 72
local ITEM_GAP  = 8
local CORNER_R  = 6

local function getButtonRect(popupConfig, panelX, panelY, buttonIndex)
    local numButtons = #popupConfig.buttons
    local totalW     = numButtons * BUTTON_W + (numButtons - 1) * PADDING
    local startX     = panelX + (popupConfig.width - totalW) / 2
    local buttonX    = startX + (buttonIndex - 1) * (BUTTON_W + PADDING)
    local buttonY    = panelY + popupConfig.height - BUTTON_H - PADDING
    return buttonX, buttonY, BUTTON_W, BUTTON_H
end

local function getItemRect(popupConfig, panelX, panelY, itemIndex)
    local numItems = #popupConfig.items
    local totalW   = numItems * ITEM_SIZE + (numItems - 1) * ITEM_GAP
    local startX   = panelX + (popupConfig.width - totalW) / 2
    local itemX    = startX + (itemIndex - 1) * (ITEM_SIZE + ITEM_GAP)
    local itemY    = panelY + TITLE_H + PADDING
    return itemX, itemY, ITEM_SIZE, ITEM_SIZE
end

local active                   = nil
local popupX, popupY           = 0, 0
local dragging                 = false
local dragOffsetX, dragOffsetY = 0, 0
local hoveredButton            = nil
local hoveredItem              = nil

function Popup.isOpen()
    return active ~= nil
end

function Popup.show(config)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    popupX    = (windowWidth  - config.width)  / 2
    popupY    = (windowHeight - config.height) / 2
    active    = config
    dragging  = false
    hoveredButton = nil
    hoveredItem   = nil
end

function Popup.hide()
    active        = nil
    dragging      = false
    hoveredButton = nil
    hoveredItem   = nil
end

function Popup.draw()
    if not active then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local popupConfig               = active
    local panelX, panelY            = popupX, popupY

    -- Dim overlay
    love.graphics.setColor(Theme.popupDim)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

    -- Panel background
    love.graphics.setColor(Theme.popupPanel)
    love.graphics.rectangle("fill", panelX, panelY, popupConfig.width, popupConfig.height, CORNER_R, CORNER_R)

    -- Title bar (drawn over panel so rounded corners only show at top)
    love.graphics.setColor(Theme.popupTitle)
    love.graphics.rectangle("fill", panelX, panelY, popupConfig.width, TITLE_H, CORNER_R, CORNER_R)
    love.graphics.rectangle("fill", panelX, panelY + TITLE_H - CORNER_R, popupConfig.width, CORNER_R)

    -- Title text
    love.graphics.setFont(Theme.boldFont)
    love.graphics.setColor(Theme.text)
    local titleFontHeight = love.graphics.getFont():getHeight()
    love.graphics.printf(popupConfig.title, panelX, panelY + (TITLE_H - titleFontHeight) / 2, popupConfig.width, "center")

    if popupConfig.type == "message" then
        -- Message text
        love.graphics.setFont(Theme.regularFont)
        love.graphics.setColor(popupConfig.messageColour or Theme.text)
        love.graphics.printf(popupConfig.message, panelX + PADDING, panelY + TITLE_H + PADDING, popupConfig.width - 2 * PADDING, "center")

        -- Buttons
        love.graphics.setFont(Theme.regularFont)
        local buttonFontHeight = love.graphics.getFont():getHeight()

        for buttonIndex, button in ipairs(popupConfig.buttons) do
            local buttonX, buttonY, buttonWidth, buttonHeight = getButtonRect(popupConfig, panelX, panelY, buttonIndex)
            local isHovered = (hoveredButton == buttonIndex)
            if button.style == "danger" then
                love.graphics.setColor(isHovered and Theme.buttonRedHov or Theme.buttonRed)
            else
                love.graphics.setColor(isHovered and Theme.buttonGreenHov or Theme.buttonGreen)
            end
            love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 4, 4)
            love.graphics.setColor(Theme.text)
            love.graphics.printf(button.label, buttonX, buttonY + (buttonHeight - buttonFontHeight) / 2, buttonWidth, "center")
        end

    elseif popupConfig.type == "picker" then
        -- Item tiles
        for itemIndex, item in ipairs(popupConfig.items) do
            local itemX, itemY, itemSize = getItemRect(popupConfig, panelX, panelY, itemIndex)

            -- Tile background
            love.graphics.setColor(Theme.popupItemBg)
            love.graphics.rectangle("fill", itemX, itemY, itemSize, itemSize, 4, 4)

            -- Piece image
            if item.image then
                local imageWidth  = item.image:getWidth()
                local imageHeight = item.image:getHeight()
                local scale   = 0.85 * itemSize / math.max(imageWidth, imageHeight)
                local offsetX = (itemSize - imageWidth  * scale) / 2
                local offsetY = (itemSize - imageHeight * scale) / 2
                love.graphics.setColor(Theme.text)
                love.graphics.draw(item.image, itemX + offsetX, itemY + offsetY, 0, scale, scale)
            end

            -- Hover highlight
            if hoveredItem == itemIndex then
                love.graphics.setColor(Theme.popupItemHov)
                love.graphics.rectangle("fill", itemX, itemY, itemSize, itemSize, 4, 4)
            end
        end
    end
end

function Popup.mousepressed(x, y)
    if not active then return end

    local popupConfig    = active
    local panelX, panelY = popupX, popupY

    -- Title bar → start drag
    if x >= panelX and x <= panelX + popupConfig.width and y >= panelY and y <= panelY + TITLE_H then
        dragging    = true
        dragOffsetX = x - panelX
        dragOffsetY = y - panelY
        return
    end

    if popupConfig.type == "message" then
        for buttonIndex, button in ipairs(popupConfig.buttons) do
            local buttonX, buttonY, buttonWidth, buttonHeight = getButtonRect(popupConfig, panelX, panelY, buttonIndex)
            if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
                if popupConfig.onButton then popupConfig.onButton(button.label) end
                return
            end
        end

    elseif popupConfig.type == "picker" then
        for itemIndex, item in ipairs(popupConfig.items) do
            local itemX, itemY, itemSize = getItemRect(popupConfig, panelX, panelY, itemIndex)
            if x >= itemX and x <= itemX + itemSize and y >= itemY and y <= itemY + itemSize then
                if popupConfig.onPick then popupConfig.onPick(item.value) end
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

    local popupConfig    = active
    local panelX, panelY = popupX, popupY
    hoveredButton        = nil
    hoveredItem          = nil

    if popupConfig.type == "message" then
        for buttonIndex, button in ipairs(popupConfig.buttons) do
            local buttonX, buttonY, buttonWidth, buttonHeight = getButtonRect(popupConfig, panelX, panelY, buttonIndex)
            if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
                hoveredButton = buttonIndex
                break
            end
        end

    elseif popupConfig.type == "picker" then
        for itemIndex, item in ipairs(popupConfig.items) do
            local itemX, itemY, itemSize = getItemRect(popupConfig, panelX, panelY, itemIndex)
            if x >= itemX and x <= itemX + itemSize and y >= itemY and y <= itemY + itemSize then
                hoveredItem = itemIndex
                break
            end
        end
    end
end

function Popup.mousereleased()
    dragging = false
end

return Popup
