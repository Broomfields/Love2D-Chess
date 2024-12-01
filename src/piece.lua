local Piece = {}

-- Constructor
function Piece.new(type, colour, row, col)
    local self = {
        type = type, -- e.g., "pawn", "rook", "knight"
        colour = colour, -- "white" or "black"
        row = row, -- Current row on the board
        col = col -- Current column on the board
    }
    
    setmetatable(self, { __index = Piece })
    return self
end

-- Check if the move is valid for the piece type
function Piece:isValidMove(targetRow, targetCol, board)
    local dx = math.abs(targetCol - self.col)
    local dy = math.abs(targetRow - self.row)
    
    if self.type == "pawn" then
        return self:isValidPawnMove(targetRow, targetCol, board)
    elseif self.type == "rook" then
        return self:isValidRookMove(targetRow, targetCol, board, dx, dy)
    elseif self.type == "knight" then
        return dx == 2 and dy == 1 or dx == 1 and dy == 2
    elseif self.type == "bishop" then
        return self:isValidBishopMove(targetRow, targetCol, board, dx, dy)
    elseif self.type == "queen" then
        return self:isValidQueenMove(targetRow, targetCol, board, dx, dy)
    elseif self.type == "king" then
        return dx <= 1 and dy <= 1
    end
    
    return false
end

-- Pawn movement rules
function Piece:isValidPawnMove(targetRow, targetCol, board)
    local direction = self.colour == "white" and 1 or -1
    local startRow = self.colour == "white" and 2 or 7
    
    -- Move forward
    if targetCol == self.col and board[targetRow][targetCol] == nil then
        if targetRow == self.row + direction then
            return true
        elseif self.row == startRow and targetRow == self.row + 2 * direction then
            return board[self.row + direction][targetCol] == nil -- Check intermediate square
        end
    end
    
    -- Capture diagonally
    if math.abs(targetCol - self.col) == 1 and targetRow == self.row + direction then
        local targetPiece = board[targetRow][targetCol]
        return targetPiece and targetPiece.colour ~= self.colour
    end
    
    return false
end

-- Rook movement rules
function Piece:isValidRookMove(targetRow, targetCol, board, dx, dy)
    if dx == 0 or dy == 0 then
        return not self:isBlocked(targetRow, targetCol, board)
    end
    return false
end

-- Bishop movement rules
function Piece:isValidBishopMove(targetRow, targetCol, board, dx, dy)
    if dx == dy then
        return not self:isBlocked(targetRow, targetCol, board)
    end
    return false
end

-- Queen movement rules
function Piece:isValidQueenMove(targetRow, targetCol, board, dx, dy)
    return self:isValidRookMove(targetRow, targetCol, board, dx, dy) or
           self:isValidBishopMove(targetRow, targetCol, board, dx, dy)
end

-- Check if there are pieces blocking the path
function Piece:isBlocked(targetRow, targetCol, board)
    local dx = targetCol > self.col and 1 or (targetCol < self.col and -1 or 0)
    local dy = targetRow > self.row and 1 or (targetRow < self.row and -1 or 0)
    
    local x, y = self.col + dx, self.row + dy
    while x ~= targetCol or y ~= targetRow do
        if board[y][x] then
            return true
        end
        x = x + dx
        y = y + dy
    end
    
    return false
end

return Piece