local Board = {}

-- Constants for board size
local BOARD_SIZE = 8

-- Constructor
function Board.new()
    local self = {
        grid = {}, -- 2D array for the board
        selectedPiece = nil, -- Currently selected piece (if any)
        turn = "white", -- Tracks whose turn it is
        pieces = {} -- Stores all active pieces
    }
    
    -- Initialise the board grid
    for row = 1, BOARD_SIZE do
        self.grid[row] = {}
        for col = 1, BOARD_SIZE do
            self.grid[row][col] = nil -- Empty square
        end
    end
    
    -- Add methods to self
    setmetatable(self, { __index = Board })
    self:setupBoard()
    return self
end

-- Set up initial positions for all pieces
function Board:setupBoard()
    local Piece = require("src.piece")
    
    -- Place pawns
    for col = 1, BOARD_SIZE do
        self.grid[2][col] = Piece.new("pawn", "white", 2, col)
        self.grid[7][col] = Piece.new("pawn", "black", 7, col)
    end
    
    -- Place rooks
    self.grid[1][1] = Piece.new("rook", "white", 1, 1)
    self.grid[1][8] = Piece.new("rook", "white", 1, 8)
    self.grid[8][1] = Piece.new("rook", "black", 8, 1)
    self.grid[8][8] = Piece.new("rook", "black", 8, 8)
    
    -- Place other pieces (knights, bishops, king, queen)...
    -- Add more setup here
end

-- Update logic (if any time-based actions are needed)
function Board:update(dt)
    -- No updates needed for a static board, but placeholder for future
end

-- Draw the board and pieces
function Board:draw()
    local Renderer = require("src.renderer")
    
    -- Draw the chessboard
    Renderer:drawBoard()
    
    -- Draw pieces
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local piece = self.grid[row][col]
            if piece then
                Renderer:drawPiece(piece)
            end
        end
    end
end

-- Handle input on the board (e.g., selecting and moving pieces)
function Board:mousepressed(x, y, button)
    local col, row = self:screenToBoard(x, y)
    
    if self:isValidPosition(row, col) then
        local clickedPiece = self.grid[row][col]
        
        if self.selectedPiece then
            -- Attempt to move the selected piece
            if self:movePiece(self.selectedPiece, row, col) then
                self.selectedPiece = nil -- Deselect after successful move
            else
                -- Invalid move, reselect
                self.selectedPiece = clickedPiece
            end
        elseif clickedPiece and clickedPiece.colour == self.turn then
            -- Select the piece if it belongs to the current player
            self.selectedPiece = clickedPiece
        end
    end
end

-- Convert screen coordinates to board coordinates
function Board:screenToBoard(x, y)
    local squareSize = 64 -- Example size; match this with your rendering logic
    local col = math.floor(x / squareSize) + 1
    local row = math.floor(y / squareSize) + 1
    return col, row
end

-- Check if a board position is valid
function Board:isValidPosition(row, col)
    return row >= 1 and row <= BOARD_SIZE and col >= 1 and col <= BOARD_SIZE
end

-- Attempt to move a piece; returns true if successful
function Board:movePiece(piece, targetRow, targetCol)
    local targetPiece = self.grid[targetRow][targetCol]
    
    -- Check if the move is valid
    if piece:isValidMove(targetRow, targetCol, self.grid) then
        -- Capture the target piece if present
        if targetPiece then
            table.remove(self.pieces, targetPiece)
        end
        
        -- Update the grid
        self.grid[piece.row][piece.col] = nil
        self.grid[targetRow][targetCol] = piece
        
        -- Update piece position
        piece.row = targetRow
        piece.col = targetCol
        
        -- Change the turn
        self.turn = (self.turn == "white") and "black" or "white"
        return true
    end
    
    return false
end

return Board