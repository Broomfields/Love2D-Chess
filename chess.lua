-- chess.lua
-- Pure chess logic with no Love2D dependencies.
-- All public functions take explicit `pieces` and `enPassantTarget` parameters.

local Chess = {}

local BOARD_MIN = 1
local BOARD_MAX = 8

-- Shared helper: add {i, j} to moves if in bounds and not occupied by a friendly piece.
local function addMoveIfValid(moves, pieces, pieceColour, i, j)
    if i >= BOARD_MIN and i <= BOARD_MAX and j >= BOARD_MIN and j <= BOARD_MAX then
        if pieces[i][j] == "" or Chess.getPieceColour(pieces[i][j]) ~= pieceColour then
            table.insert(moves, {i, j})
        end
    end
end

-- Walk in direction (dx, dy) from (x, y) up to 7 squares, stopping at a blocker.
local function addRayMoves(moves, pieces, pieceColour, x, y, dx, dy)
    for i = 1, 7 do
        local nx, ny = x + dx * i, y + dy * i
        if nx < BOARD_MIN or nx > BOARD_MAX or ny < BOARD_MIN or ny > BOARD_MAX then break end
        addMoveIfValid(moves, pieces, pieceColour, nx, ny)
        if pieces[nx][ny] ~= "" then break end
    end
end

local function getPawnMoves(pieces, enPassantTarget, x, y, pieceColour)
    local moves = {}
    local direction = pieceColour == "white" and -1 or 1
    local startRow  = pieceColour == "white" and 7 or 2

    -- Forward move(s)
    if x + direction >= BOARD_MIN and x + direction <= BOARD_MAX
            and pieces[x + direction][y] == "" then
        addMoveIfValid(moves, pieces, pieceColour, x + direction, y)
        if x == startRow and x + 2 * direction >= BOARD_MIN and x + 2 * direction <= BOARD_MAX
                and pieces[x + 2 * direction][y] == "" then
            addMoveIfValid(moves, pieces, pieceColour, x + 2 * direction, y)
        end
    end

    -- Diagonal captures
    if x + direction >= BOARD_MIN and x + direction <= BOARD_MAX then
        if y > BOARD_MIN and pieces[x + direction][y - 1] ~= ""
                and Chess.getPieceColour(pieces[x + direction][y - 1]) ~= pieceColour then
            addMoveIfValid(moves, pieces, pieceColour, x + direction, y - 1)
        end
        if y < BOARD_MAX and pieces[x + direction][y + 1] ~= ""
                and Chess.getPieceColour(pieces[x + direction][y + 1]) ~= pieceColour then
            addMoveIfValid(moves, pieces, pieceColour, x + direction, y + 1)
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

local function getRookMoves(pieces, x, y, pieceColour)
    local moves = {}
    for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        addRayMoves(moves, pieces, pieceColour, x, y, d[1], d[2])
    end
    return moves
end

local function getKnightMoves(pieces, x, y, pieceColour)
    local moves = {}
    local offsets = {
        {x + 2, y + 1}, {x + 2, y - 1}, {x - 2, y + 1}, {x - 2, y - 1},
        {x + 1, y + 2}, {x + 1, y - 2}, {x - 1, y + 2}, {x - 1, y - 2},
    }
    for _, o in ipairs(offsets) do
        addMoveIfValid(moves, pieces, pieceColour, o[1], o[2])
    end
    return moves
end

local function getBishopMoves(pieces, x, y, pieceColour)
    local moves = {}
    for _, d in ipairs({{1,1},{1,-1},{-1,1},{-1,-1}}) do
        addRayMoves(moves, pieces, pieceColour, x, y, d[1], d[2])
    end
    return moves
end

local function getKingMoves(pieces, x, y, pieceColour)
    local moves = {}
    local offsets = {
        {x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1},
        {x + 1, y + 1}, {x + 1, y - 1}, {x - 1, y + 1}, {x - 1, y - 1},
    }
    for _, o in ipairs(offsets) do
        addMoveIfValid(moves, pieces, pieceColour, o[1], o[2])
    end
    return moves
end

local function getQueenMoves(pieces, x, y, pieceColour)
    local moves = {}
    for _, m in ipairs(getRookMoves(pieces, x, y, pieceColour)) do
        table.insert(moves, m)
    end
    for _, m in ipairs(getBishopMoves(pieces, x, y, pieceColour)) do
        table.insert(moves, m)
    end
    return moves
end

-- Returns raw (pre-filter) moves for a piece; used for check detection and testing.
-- Note: en passant is excluded from raw moves (it is not an attack on the king).
local function getRawMoves(pieces, x, y)
    local piece       = pieces[x][y]
    local pieceColour = Chess.getPieceColour(piece)
    if piece:match("pawn")   then return getPawnMoves(pieces, nil, x, y, pieceColour) end
    if piece:match("rook")   then return getRookMoves(pieces, x, y, pieceColour) end
    if piece:match("knight") then return getKnightMoves(pieces, x, y, pieceColour) end
    if piece:match("bishop") then return getBishopMoves(pieces, x, y, pieceColour) end
    if piece:match("queen")  then return getQueenMoves(pieces, x, y, pieceColour) end
    if piece:match("king")   then return getKingMoves(pieces, x, y, pieceColour) end
    return {}
end

function Chess.getPieceColour(piece)
    return piece:match("^white") and "white" or "black"
end

function Chess.isKingInCheck(pieces, player)
    local kingX, kingY
    for i = BOARD_MIN, BOARD_MAX do
        for j = BOARD_MIN, BOARD_MAX do
            if pieces[i][j] == player .. "_king" then
                kingX, kingY = i, j
                break
            end
        end
    end

    for i = BOARD_MIN, BOARD_MAX do
        for j = BOARD_MIN, BOARD_MAX do
            if pieces[i][j] ~= "" and Chess.getPieceColour(pieces[i][j]) ~= player then
                local moves = getRawMoves(pieces, i, j)
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

local function filterLegalMoves(pieces, enPassantTarget, fromX, fromY, candidates, pieceColour)
    local legal = {}
    for _, move in ipairs(candidates) do
        local toX, toY  = move[1], move[2]
        local savedFrom = pieces[fromX][fromY]
        local savedTo   = pieces[toX][toY]
        pieces[toX][toY]     = savedFrom
        pieces[fromX][fromY] = ""

        -- Temporarily remove en-passant-captured pawn to test for horizontal pins.
        local epRow, epCol, savedEpPawn
        if enPassantTarget and savedFrom:match("pawn") and
                toX == enPassantTarget[1] and toY == enPassantTarget[2] then
            epRow, epCol = fromX, toY
            savedEpPawn  = pieces[epRow][epCol]
            pieces[epRow][epCol] = ""
        end

        local stillInCheck = Chess.isKingInCheck(pieces, pieceColour)
        pieces[fromX][fromY] = savedFrom
        pieces[toX][toY]     = savedTo
        if epRow then pieces[epRow][epCol] = savedEpPawn end

        if not stillInCheck then
            table.insert(legal, move)
        end
    end
    return legal
end

function Chess.getValidMoves(pieces, enPassantTarget, x, y)
    local piece       = pieces[x][y]
    local pieceColour = Chess.getPieceColour(piece)
    local candidates
    if piece:match("pawn") then
        candidates = getPawnMoves(pieces, enPassantTarget, x, y, pieceColour)
    else
        candidates = getRawMoves(pieces, x, y)
    end
    return filterLegalMoves(pieces, enPassantTarget, x, y, candidates, pieceColour)
end

-- Exposed for tests that verify raw move counts (e.g. knight geometry).
Chess.getRawMoves = getRawMoves

function Chess.hasLegalMoves(pieces, enPassantTarget, player)
    for i = BOARD_MIN, BOARD_MAX do
        for j = BOARD_MIN, BOARD_MAX do
            if pieces[i][j] ~= "" and Chess.getPieceColour(pieces[i][j]) == player then
                if #Chess.getValidMoves(pieces, enPassantTarget, i, j) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

-- Executes a move on the pieces table (mutates in place) and returns a result descriptor.
-- Handles en passant capture and notation. Does NOT handle pawn promotion placement.
function Chess.executeMove(pieces, enPassantTarget, fromRow, fromCol, toRow, toCol)
    local movedPiece  = pieces[fromRow][fromCol]
    local targetPiece = pieces[toRow][toCol]
    pieces[toRow][toCol]     = movedPiece
    pieces[fromRow][fromCol] = ""

    local isEnPassant = enPassantTarget and movedPiece:match("pawn") and
                        toRow == enPassantTarget[1] and toCol == enPassantTarget[2]
    if isEnPassant then
        pieces[fromRow][toCol] = ""  -- remove the captured pawn
    end

    -- Move notation
    local dest     = string.char(96 + toCol):upper() .. tostring(9 - toRow)
    local notation
    if isEnPassant then
        notation = movedPiece .. " takes " .. dest .. " e.p."
    elseif targetPiece ~= "" then
        notation = movedPiece .. " takes " .. dest
    else
        notation = movedPiece .. " to " .. dest
    end

    -- New en passant target (set when a pawn double-advances)
    local newEnPassantTarget = nil
    if movedPiece:match("pawn") and math.abs(toRow - fromRow) == 2 then
        newEnPassantTarget = {(toRow + fromRow) / 2, toCol}
    end

    return {
        notation           = notation,
        captured           = isEnPassant and "en_passant" or targetPiece,
        isPromotion        = (movedPiece == "white_pawn" and toRow == BOARD_MIN)
                          or (movedPiece == "black_pawn" and toRow == BOARD_MAX),
        newEnPassantTarget = newEnPassantTarget,
    }
end

return Chess
