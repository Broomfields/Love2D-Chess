-- chess.lua
-- Pure chess logic with no Love2D dependencies.
-- All public functions take explicit `pieces`, `enPassantTarget`, and (optionally)
-- `castlingRights` parameters. Passing nil for castlingRights disables castling.

local Chess = {}

local BOARD_MIN = 1
local BOARD_MAX = 8

-- ── Shared move helpers ───────────────────────────────────────────────────────

-- Add {i, j} to moves if in bounds and not occupied by a friendly piece.
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

-- Return true if (row, col) is attacked by any piece of byColour.
local function isSquareAttackedBy(pieces, row, col, byColour)
    for i = BOARD_MIN, BOARD_MAX do
        for j = BOARD_MIN, BOARD_MAX do
            if pieces[i][j] ~= "" and Chess.getPieceColour(pieces[i][j]) == byColour then
                -- Use getRawMoves (forward-declared below)
                local moves = Chess._getRawMoves(pieces, i, j)
                for _, m in ipairs(moves) do
                    if m[1] == row and m[2] == col then return true end
                end
            end
        end
    end
    return false
end

-- ── Piece move generators ─────────────────────────────────────────────────────

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
        {x+2,y+1},{x+2,y-1},{x-2,y+1},{x-2,y-1},
        {x+1,y+2},{x+1,y-2},{x-1,y+2},{x-1,y-2},
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
        {x+1,y},{x-1,y},{x,y+1},{x,y-1},
        {x+1,y+1},{x+1,y-1},{x-1,y+1},{x-1,y-1},
    }
    for _, o in ipairs(offsets) do
        addMoveIfValid(moves, pieces, pieceColour, o[1], o[2])
    end
    return moves
end

local function getQueenMoves(pieces, x, y, pieceColour)
    local moves = {}
    for _, m in ipairs(getRookMoves(pieces, x, y, pieceColour)) do table.insert(moves, m) end
    for _, m in ipairs(getBishopMoves(pieces, x, y, pieceColour)) do table.insert(moves, m) end
    return moves
end

-- Returns raw (pre-filter) moves for a piece; used for check detection and testing.
-- Note: en passant excluded (it is not an attack on the king).
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

-- Bind _getRawMoves so isSquareAttackedBy can call it (forward reference resolved).
Chess._getRawMoves = getRawMoves

-- ── Castling ──────────────────────────────────────────────────────────────────

-- Returns castling destination squares available to the king at (x, y).
-- Temporarily removes the king from the board so it doesn't block its own path checks.
local function getCastlingMoves(pieces, castlingRights, x, y, pieceColour)
    local moves  = {}
    local rights = castlingRights and castlingRights[pieceColour]
    if not rights then return moves end

    local enemy = pieceColour == "white" and "black" or "white"

    -- King must not currently be in check
    if Chess.isKingInCheck(pieces, pieceColour) then return moves end

    local savedKing = pieces[x][y]
    pieces[x][y] = ""  -- temporarily remove king

    -- Kingside: empty F & G files, rook on H, F & G not attacked
    if rights.kingSide
            and pieces[x][y+1] == "" and pieces[x][y+2] == ""
            and pieces[x][BOARD_MAX] ~= "" and pieces[x][BOARD_MAX]:match("rook")
            and Chess.getPieceColour(pieces[x][BOARD_MAX]) == pieceColour
            and not isSquareAttackedBy(pieces, x, y+1, enemy)
            and not isSquareAttackedBy(pieces, x, y+2, enemy) then
        table.insert(moves, {x, y+2})
    end

    -- Queenside: empty B, C & D files, rook on A; D & C not attacked (B just needs to be empty)
    if rights.queenSide
            and pieces[x][y-1] == "" and pieces[x][y-2] == "" and pieces[x][y-3] == ""
            and pieces[x][BOARD_MIN] ~= "" and pieces[x][BOARD_MIN]:match("rook")
            and Chess.getPieceColour(pieces[x][BOARD_MIN]) == pieceColour
            and not isSquareAttackedBy(pieces, x, y-1, enemy)
            and not isSquareAttackedBy(pieces, x, y-2, enemy) then
        table.insert(moves, {x, y-2})
    end

    pieces[x][y] = savedKing
    return moves
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Chess.getPieceColour(piece)
    return piece:match("^white") and "white" or "black"
end

function Chess.isKingInCheck(pieces, player)
    local kingX, kingY
    for i = BOARD_MIN, BOARD_MAX do
        for j = BOARD_MIN, BOARD_MAX do
            if pieces[i][j] == player .. "_king" then kingX, kingY = i, j; break end
        end
    end

    for i = BOARD_MIN, BOARD_MAX do
        for j = BOARD_MIN, BOARD_MAX do
            if pieces[i][j] ~= "" and Chess.getPieceColour(pieces[i][j]) ~= player then
                for _, move in ipairs(getRawMoves(pieces, i, j)) do
                    if move[1] == kingX and move[2] == kingY then return true end
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

        -- For castling (king moves 2 squares sideways), also simulate the rook.
        local isCastling = savedFrom:match("king") and math.abs(toY - fromY) == 2
        local castleRookFromCol, castleRookToCol, savedCastleRook
        if isCastling then
            castleRookFromCol = toY > fromY and BOARD_MAX or BOARD_MIN
            castleRookToCol   = toY > fromY and toY - 1  or toY + 1
            savedCastleRook   = pieces[fromX][castleRookFromCol]
            pieces[fromX][castleRookToCol]   = savedCastleRook
            pieces[fromX][castleRookFromCol] = ""
        end

        local stillInCheck = Chess.isKingInCheck(pieces, pieceColour)
        pieces[fromX][fromY] = savedFrom
        pieces[toX][toY]     = savedTo
        if epRow then pieces[epRow][epCol] = savedEpPawn end
        if isCastling then
            pieces[fromX][castleRookFromCol] = savedCastleRook
            pieces[fromX][castleRookToCol]   = ""
        end

        if not stillInCheck then
            table.insert(legal, move)
        end
    end
    return legal
end

-- castlingRights is optional (nil = no castling).
function Chess.getValidMoves(pieces, enPassantTarget, x, y, castlingRights)
    local piece       = pieces[x][y]
    local pieceColour = Chess.getPieceColour(piece)
    local candidates
    if piece:match("pawn") then
        candidates = getPawnMoves(pieces, enPassantTarget, x, y, pieceColour)
    else
        candidates = getRawMoves(pieces, x, y)
    end

    -- Append castling destinations when the piece is a king
    if piece:match("king") then
        for _, m in ipairs(getCastlingMoves(pieces, castlingRights, x, y, pieceColour)) do
            table.insert(candidates, m)
        end
    end

    return filterLegalMoves(pieces, enPassantTarget, x, y, candidates, pieceColour)
end

-- Exposed for tests that verify raw move counts (e.g. knight geometry).
Chess.getRawMoves = getRawMoves

-- castlingRights is optional (nil = no castling).
function Chess.hasLegalMoves(pieces, enPassantTarget, player, castlingRights)
    for i = BOARD_MIN, BOARD_MAX do
        for j = BOARD_MIN, BOARD_MAX do
            if pieces[i][j] ~= "" and Chess.getPieceColour(pieces[i][j]) == player then
                if #Chess.getValidMoves(pieces, enPassantTarget, i, j, castlingRights) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

-- Executes a move on the pieces table (mutates in place) and returns a result descriptor.
-- Handles en passant capture, castling, and notation.
-- Does NOT handle pawn promotion piece placement (caller does that via isPromotion).
-- castlingRights is optional; when provided, newCastlingRights is returned.
function Chess.executeMove(pieces, enPassantTarget, fromRow, fromCol, toRow, toCol, castlingRights)
    local movedPiece  = pieces[fromRow][fromCol]
    local targetPiece = pieces[toRow][toCol]
    pieces[toRow][toCol]     = movedPiece
    pieces[fromRow][fromCol] = ""

    -- En passant capture
    local isEnPassant = enPassantTarget and movedPiece:match("pawn") and
                        toRow == enPassantTarget[1] and toCol == enPassantTarget[2]
    if isEnPassant then
        pieces[fromRow][toCol] = ""  -- remove the captured pawn
    end

    -- Castling: move the rook when king jumps two squares sideways
    local isCastling = movedPiece:match("king") and math.abs(toCol - fromCol) == 2
    if isCastling then
        local rookFromCol = toCol > fromCol and BOARD_MAX or BOARD_MIN
        local rookToCol   = toCol > fromCol and toCol - 1 or toCol + 1
        pieces[toRow][rookToCol]    = pieces[fromRow][rookFromCol]
        pieces[fromRow][rookFromCol] = ""
    end

    -- Move notation
    local dest     = string.char(96 + toCol):upper() .. tostring(9 - toRow)
    local notation
    if isCastling then
        notation = toCol > fromCol and "Kingside castling" or "Queenside castling"
    elseif isEnPassant then
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

    -- Updated castling rights
    local newCastlingRights = nil
    if castlingRights then
        newCastlingRights = {
            white = { kingSide=castlingRights.white.kingSide,  queenSide=castlingRights.white.queenSide },
            black = { kingSide=castlingRights.black.kingSide,  queenSide=castlingRights.black.queenSide },
        }
        local colour = Chess.getPieceColour(movedPiece)
        if movedPiece:match("king") then
            newCastlingRights[colour].kingSide  = false
            newCastlingRights[colour].queenSide = false
        elseif movedPiece:match("rook") then
            if fromCol == BOARD_MAX then newCastlingRights[colour].kingSide  = false end
            if fromCol == BOARD_MIN then newCastlingRights[colour].queenSide = false end
        end
        -- Capturing an opponent's starting rook revokes that castling right
        if targetPiece ~= "" and targetPiece:match("rook") then
            local capColour = Chess.getPieceColour(targetPiece)
            if toCol == BOARD_MAX then newCastlingRights[capColour].kingSide  = false end
            if toCol == BOARD_MIN then newCastlingRights[capColour].queenSide = false end
        end
    end

    return {
        notation           = notation,
        captured           = isEnPassant and "en_passant" or targetPiece,
        isPromotion        = (movedPiece == "white_pawn" and toRow == BOARD_MIN)
                          or (movedPiece == "black_pawn" and toRow == BOARD_MAX),
        newEnPassantTarget = newEnPassantTarget,
        newCastlingRights  = newCastlingRights,
    }
end

return Chess
