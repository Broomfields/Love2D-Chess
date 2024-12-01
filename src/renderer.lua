local Renderer = {}

-- Assets
local squareSize = 64 -- Size of each board square
local colours = { light = {0.9, 0.9, 0.9}, dark = {0.3, 0.3, 0.3} } -- Board colours
local pieceSprites = {}

-- Load assets
function Renderer:loadAssets()
    -- Load white pieces
    pieceSprites["white_pawn"] = love.graphics.newImage("assets/images/white_pawn.png")
    pieceSprites["white_rook"] = love.graphics.newImage("assets/images/white_rook.png")
    pieceSprites["white_knight"] = love.graphics.newImage("assets/images/white_knight.png")
    pieceSprites["white_bishop"] = love.graphics.newImage("assets/images/white_bishop.png")
    pieceSprites["white_queen"] = love.graphics.newImage("assets/images/white_queen.png")
    pieceSprites["white_king"] = love.graphics.newImage("assets/images/white_king.png")
    
    -- Load black pieces
    pieceSprites["black_pawn"] = love.graphics.newImage("assets/images/black_pawn.png")
    pieceSprites["black_rook"] = love.graphics.newImage("assets/images/black_rook.png")
    pieceSprites["black_knight"] = love.graphics.newImage("assets/images/black_knight.png")
    pieceSprites["black_bishop"] = love.graphics.newImage("assets/images/black_bishop.png")
    pieceSprites["black_queen"] = love.graphics.newImage("assets/images/black_queen.png")
    pieceSprites["black_king"] = love.graphics.newImage("assets/images/black_king.png")
end

-- Draw the chessboard
function Renderer:drawBoard()
    for row = 1, 8 do
        for col = 1, 8 do
            local isLightSquare = (row + col) % 2 == 0
            local colour = isLightSquare and colours.light or colours.dark
            love.graphics.setColor(colour)
            love.graphics.rectangle("fill", (col - 1) * squareSize, (row - 1) * squareSize, squareSize, squareSize)
        end
    end
end

-- Draw a single piece
function Renderer:drawPiece(piece)
    local spriteKey = piece.colour .. "_" .. piece.type
    local sprite = pieceSprites[spriteKey]
    if sprite then
        local x = (piece.col - 1) * squareSize
        local y = (piece.row - 1) * squareSize
        love.graphics.draw(sprite, x, y, 0, squareSize / sprite:getWidth(), squareSize / sprite:getHeight())
    else
        -- Debug fallback if sprite is missing
        love.graphics.setColor(1, 0, 0) -- Red
        love.graphics.rectangle("fill", (piece.col - 1) * squareSize + 10, (piece.row - 1) * squareSize + 10, squareSize - 20, squareSize - 20)
    end
end

-- Highlight a square (e.g., for selected piece or valid moves)
function Renderer:highlightSquare(row, col, colour)
    local x = (col - 1) * squareSize
    local y = (row - 1) * squareSize
    love.graphics.setColor(colour or {1, 1, 0, 0.5}) -- Default yellow highlight
    love.graphics.rectangle("fill", x, y, squareSize, squareSize)
end

return Renderer