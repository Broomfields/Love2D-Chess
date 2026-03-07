-- chess.lua
-- Pure chess logic with no Love2D dependencies.
-- All functions operate on the global `pieces` table (8x8 array of strings).

function getPieceColour(piece)
    return piece:match("^white") and "white" or "black"
end

function isKingInCheck(player)
    local kingX, kingY
    for i = 1, 8 do
        for j = 1, 8 do
            if pieces[i][j] == player .. "_king" then
                kingX, kingY = i, j
                break
            end
        end
    end

    for i = 1, 8 do
        for j = 1, 8 do
            if pieces[i][j] ~= "" and getPieceColour(pieces[i][j]) ~= player then
                local moves = getRawMoves(i, j)
                for _, move in ipairs(moves) do
                    if move[1] == kingX and move[2] == kingY then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function hasLegalMoves(player)
    for i = 1, 8 do
        for j = 1, 8 do
            if pieces[i][j] ~= "" and getPieceColour(pieces[i][j]) == player then
                if #getValidMoves(i, j) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function getRawMoves(x, y)
    local piece = pieces[x][y]
    local pieceColour = getPieceColour(piece)
    local moves = {}

    if piece:match("pawn") then
        moves = getPawnMoves(x, y, pieceColour)
    elseif piece:match("rook") then
        moves = getRookMoves(x, y, pieceColour)
    elseif piece:match("knight") then
        moves = getKnightMoves(x, y, pieceColour)
    elseif piece:match("bishop") then
        moves = getBishopMoves(x, y, pieceColour)
    elseif piece:match("queen") then
        moves = getQueenMoves(x, y, pieceColour)
    elseif piece:match("king") then
        moves = getKingMoves(x, y, pieceColour)
    end

    return moves
end

function filterLegalMoves(fromX, fromY, candidates, pieceColour)
    local legal = {}
    for _, move in ipairs(candidates) do
        local toX, toY = move[1], move[2]
        local savedFrom = pieces[fromX][fromY]
        local savedTo   = pieces[toX][toY]
        pieces[toX][toY]     = savedFrom
        pieces[fromX][fromY] = ""

        -- En passant: temporarily remove the captured pawn (at {fromX, toY})
        -- so the legality check correctly detects horizontal pins.
        local epCaptureRow, epCaptureCol, savedEpPawn
        if enPassantTarget and savedFrom:match("pawn") and
           toX == enPassantTarget[1] and toY == enPassantTarget[2] then
            epCaptureRow, epCaptureCol = fromX, toY
            savedEpPawn = pieces[epCaptureRow][epCaptureCol]
            pieces[epCaptureRow][epCaptureCol] = ""
        end

        local stillInCheck = isKingInCheck(pieceColour)
        pieces[fromX][fromY] = savedFrom
        pieces[toX][toY]     = savedTo
        if epCaptureRow then
            pieces[epCaptureRow][epCaptureCol] = savedEpPawn
        end

        if not stillInCheck then
            table.insert(legal, move)
        end
    end
    return legal
end

function getValidMoves(x, y)
    local piece = pieces[x][y]
    local pieceColour = getPieceColour(piece)
    local candidates = getRawMoves(x, y)
    return filterLegalMoves(x, y, candidates, pieceColour)
end

function getPawnMoves(x, y, pieceColour)
    local moves = {}
    local direction = pieceColour == "white" and -1 or 1
    local startRow = pieceColour == "white" and 7 or 2

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColour(pieces[i][j]) ~= pieceColour then
                table.insert(moves, {i, j})
            end
        end
    end

    -- Normal move
    if x + direction >= 1 and x + direction <= 8 and pieces[x + direction][y] == "" then
        addMoveIfValid(x + direction, y)
        -- Double move from start position
        if x == startRow and x + 2 * direction >= 1 and x + 2 * direction <= 8 and pieces[x + 2 * direction][y] == "" then
            addMoveIfValid(x + 2 * direction, y)
        end
    end

    -- Captures
    if x + direction >= 1 and x + direction <= 8 then
        if y > 1 and pieces[x + direction][y - 1] ~= "" and getPieceColour(pieces[x + direction][y - 1]) ~= pieceColour then
            addMoveIfValid(x + direction, y - 1)
        end
        if y < 8 and pieces[x + direction][y + 1] ~= "" and getPieceColour(pieces[x + direction][y + 1]) ~= pieceColour then
            addMoveIfValid(x + direction, y + 1)
        end
    end

    -- En passant
    if enPassantTarget then
        local epRow, epCol = enPassantTarget[1], enPassantTarget[2]
        if x + direction == epRow and math.abs(y - epCol) == 1 then
            table.insert(moves, {epRow, epCol})
        end
    end

    return moves
end

function getRookMoves(x, y, pieceColour)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColour(pieces[i][j]) ~= pieceColour then
                table.insert(moves, {i, j})
            end
        end
    end

    for i = x + 1, 8 do
        if pieces[i][y] == "" then
            addMoveIfValid(i, y)
        else
            addMoveIfValid(i, y)
            break
        end
    end
    for i = x - 1, 1, -1 do
        if pieces[i][y] == "" then
            addMoveIfValid(i, y)
        else
            addMoveIfValid(i, y)
            break
        end
    end
    for j = y + 1, 8 do
        if pieces[x][j] == "" then
            addMoveIfValid(x, j)
        else
            addMoveIfValid(x, j)
            break
        end
    end
    for j = y - 1, 1, -1 do
        if pieces[x][j] == "" then
            addMoveIfValid(x, j)
        else
            addMoveIfValid(x, j)
            break
        end
    end

    return moves
end

function getKnightMoves(x, y, pieceColour)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColour(pieces[i][j]) ~= pieceColour then
                table.insert(moves, {i, j})
            end
        end
    end

    local knightMoves = {
        {x + 2, y + 1}, {x + 2, y - 1}, {x - 2, y + 1}, {x - 2, y - 1},
        {x + 1, y + 2}, {x + 1, y - 2}, {x - 1, y + 2}, {x - 1, y - 2}
    }
    for _, move in ipairs(knightMoves) do
        addMoveIfValid(move[1], move[2])
    end

    return moves
end

function getBishopMoves(x, y, pieceColour)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColour(pieces[i][j]) ~= pieceColour then
                table.insert(moves, {i, j})
            end
        end
    end

    for i = 1, 7 do
        if x + i <= 8 and y + i <= 8 then
            if pieces[x + i][y + i] == "" then
                addMoveIfValid(x + i, y + i)
            else
                addMoveIfValid(x + i, y + i)
                break
            end
        end
    end
    for i = 1, 7 do
        if x + i <= 8 and y - i >= 1 then
            if pieces[x + i][y - i] == "" then
                addMoveIfValid(x + i, y - i)
            else
                addMoveIfValid(x + i, y - i)
                break
            end
        end
    end
    for i = 1, 7 do
        if x - i >= 1 and y + i <= 8 then
            if pieces[x - i][y + i] == "" then
                addMoveIfValid(x - i, y + i)
            else
                addMoveIfValid(x - i, y + i)
                break
            end
        end
    end
    for i = 1, 7 do
        if x - i >= 1 and y - i >= 1 then
            if pieces[x - i][y - i] == "" then
                addMoveIfValid(x - i, y - i)
            else
                addMoveIfValid(x - i, y - i)
                break
            end
        end
    end

    return moves
end

function getQueenMoves(x, y, pieceColour)
    local moves = {}
    for _, move in ipairs(getRookMoves(x, y, pieceColour)) do
        table.insert(moves, move)
    end
    for _, move in ipairs(getBishopMoves(x, y, pieceColour)) do
        table.insert(moves, move)
    end
    return moves
end

function getKingMoves(x, y, pieceColour)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColour(pieces[i][j]) ~= pieceColour then
                table.insert(moves, {i, j})
            end
        end
    end

    local kingMoves = {
        {x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1},
        {x + 1, y + 1}, {x + 1, y - 1}, {x - 1, y + 1}, {x - 1, y - 1}
    }
    for _, move in ipairs(kingMoves) do
        addMoveIfValid(move[1], move[2])
    end

    return moves
end
