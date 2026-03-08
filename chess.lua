-- chess.lua
-- Pure chess logic with no Love2D dependencies.
-- All public functions take explicit `pieces`, `enPassantTarget`, and (optionally)
-- `castlingRights` parameters. Passing nil for castlingRights disables castling.

local Chess = {}

local BOARD_MIN = 1
local BOARD_MAX = 8

Chess.BOARD_MIN = BOARD_MIN
Chess.BOARD_MAX = BOARD_MAX

Chess.PROMOTION_TARGETS = { "queen", "rook", "bishop", "knight" }

function Chess.startingPosition()
    return {
        {"black_rook","black_knight","black_bishop","black_queen","black_king","black_bishop","black_knight","black_rook"},
        {"black_pawn","black_pawn","black_pawn","black_pawn","black_pawn","black_pawn","black_pawn","black_pawn"},
        {"","","","","","","",""},
        {"","","","","","","",""},
        {"","","","","","","",""},
        {"","","","","","","",""},
        {"white_pawn","white_pawn","white_pawn","white_pawn","white_pawn","white_pawn","white_pawn","white_pawn"},
        {"white_rook","white_knight","white_bishop","white_queen","white_king","white_bishop","white_knight","white_rook"},
    }
end

function Chess.initialCastlingRights()
    return {
        white = { kingSide = true, queenSide = true },
        black = { kingSide = true, queenSide = true },
    }
end

function Chess.applyPromotion(pieces, row, col, newPiece)
    pieces[row][col] = newPiece
end

-- ── Shared move helpers ───────────────────────────────────────────────────────

-- Add {row, col} to moves if in bounds and not occupied by a friendly piece.
local function addMoveIfValid(moves, pieces, pieceColour, row, col)
    if row >= BOARD_MIN and row <= BOARD_MAX and col >= BOARD_MIN and col <= BOARD_MAX then
        if pieces[row][col] == "" or Chess.getPieceColour(pieces[row][col]) ~= pieceColour then
            table.insert(moves, {row, col})
        end
    end
end

-- Walk in direction (dirRow, dirCol) from (row, col) up to 7 squares, stopping at a blocker.
local function addRayMoves(moves, pieces, pieceColour, row, col, dirRow, dirCol)
    for step = 1, 7 do
        local nextRow, nextCol = row + dirRow * step, col + dirCol * step
        if nextRow < BOARD_MIN or nextRow > BOARD_MAX or nextCol < BOARD_MIN or nextCol > BOARD_MAX then break end
        addMoveIfValid(moves, pieces, pieceColour, nextRow, nextCol)
        if pieces[nextRow][nextCol] ~= "" then break end
    end
end

-- Return true if (row, col) is attacked by any piece of byColour.
local function isSquareAttackedBy(pieces, row, col, byColour)
    for scanRow = BOARD_MIN, BOARD_MAX do
        for scanCol = BOARD_MIN, BOARD_MAX do
            if pieces[scanRow][scanCol] ~= "" and Chess.getPieceColour(pieces[scanRow][scanCol]) == byColour then
                -- Use getRawMoves (forward-declared below)
                local moves = Chess._getRawMoves(pieces, scanRow, scanCol)
                for _, move in ipairs(moves) do
                    if move[1] == row and move[2] == col then return true end
                end
            end
        end
    end
    return false
end

-- ── Piece move generators ─────────────────────────────────────────────────────

local function getPawnMoves(pieces, enPassantTarget, row, col, pieceColour)
    local moves     = {}
    local direction = pieceColour == "white" and -1 or 1
    local startRow  = pieceColour == "white" and 7 or 2

    -- Forward move(s)
    if row + direction >= BOARD_MIN and row + direction <= BOARD_MAX
            and pieces[row + direction][col] == "" then
        addMoveIfValid(moves, pieces, pieceColour, row + direction, col)
        if row == startRow and row + 2 * direction >= BOARD_MIN and row + 2 * direction <= BOARD_MAX
                and pieces[row + 2 * direction][col] == "" then
            addMoveIfValid(moves, pieces, pieceColour, row + 2 * direction, col)
        end
    end

    -- Diagonal captures
    if row + direction >= BOARD_MIN and row + direction <= BOARD_MAX then
        if col > BOARD_MIN and pieces[row + direction][col - 1] ~= ""
                and Chess.getPieceColour(pieces[row + direction][col - 1]) ~= pieceColour then
            addMoveIfValid(moves, pieces, pieceColour, row + direction, col - 1)
        end
        if col < BOARD_MAX and pieces[row + direction][col + 1] ~= ""
                and Chess.getPieceColour(pieces[row + direction][col + 1]) ~= pieceColour then
            addMoveIfValid(moves, pieces, pieceColour, row + direction, col + 1)
        end
    end

    -- En passant
    if enPassantTarget then
        local epRow, epCol = enPassantTarget[1], enPassantTarget[2]
        if row + direction == epRow and math.abs(col - epCol) == 1 then
            table.insert(moves, {epRow, epCol})
        end
    end

    return moves
end

local function getRookMoves(pieces, row, col, pieceColour)
    local moves = {}
    for _, direction in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        addRayMoves(moves, pieces, pieceColour, row, col, direction[1], direction[2])
    end
    return moves
end

local function getKnightMoves(pieces, row, col, pieceColour)
    local moves = {}
    local offsets = {
        {row+2,col+1},{row+2,col-1},{row-2,col+1},{row-2,col-1},
        {row+1,col+2},{row+1,col-2},{row-1,col+2},{row-1,col-2},
    }
    for _, offset in ipairs(offsets) do
        addMoveIfValid(moves, pieces, pieceColour, offset[1], offset[2])
    end
    return moves
end

local function getBishopMoves(pieces, row, col, pieceColour)
    local moves = {}
    for _, direction in ipairs({{1,1},{1,-1},{-1,1},{-1,-1}}) do
        addRayMoves(moves, pieces, pieceColour, row, col, direction[1], direction[2])
    end
    return moves
end

local function getKingMoves(pieces, row, col, pieceColour)
    local moves = {}
    local offsets = {
        {row+1,col},{row-1,col},{row,col+1},{row,col-1},
        {row+1,col+1},{row+1,col-1},{row-1,col+1},{row-1,col-1},
    }
    for _, offset in ipairs(offsets) do
        addMoveIfValid(moves, pieces, pieceColour, offset[1], offset[2])
    end
    return moves
end

local function getQueenMoves(pieces, row, col, pieceColour)
    local moves = {}
    for _, move in ipairs(getRookMoves(pieces, row, col, pieceColour))   do table.insert(moves, move) end
    for _, move in ipairs(getBishopMoves(pieces, row, col, pieceColour)) do table.insert(moves, move) end
    return moves
end

-- Returns raw (pre-filter) moves for a piece; used for check detection and testing.
-- Note: en passant excluded (it is not an attack on the king).
local function getRawMoves(pieces, row, col)
    local piece       = pieces[row][col]
    local pieceColour = Chess.getPieceColour(piece)
    if piece:match("pawn")   then return getPawnMoves(pieces, nil, row, col, pieceColour) end
    if piece:match("rook")   then return getRookMoves(pieces, row, col, pieceColour) end
    if piece:match("knight") then return getKnightMoves(pieces, row, col, pieceColour) end
    if piece:match("bishop") then return getBishopMoves(pieces, row, col, pieceColour) end
    if piece:match("queen")  then return getQueenMoves(pieces, row, col, pieceColour) end
    if piece:match("king")   then return getKingMoves(pieces, row, col, pieceColour) end
    return {}
end

-- Bind _getRawMoves so isSquareAttackedBy can call it (forward reference resolved).
Chess._getRawMoves = getRawMoves

-- ── Castling ──────────────────────────────────────────────────────────────────

-- Returns castling destination squares available to the king at (row, col).
-- Temporarily removes the king from the board so it doesn't block its own path checks.
local function getCastlingMoves(pieces, castlingRights, row, col, pieceColour)
    local moves  = {}
    local rights = castlingRights and castlingRights[pieceColour]
    if not rights then return moves end

    local enemy = pieceColour == "white" and "black" or "white"

    -- King must not currently be in check
    if Chess.isKingInCheck(pieces, pieceColour) then return moves end

    local savedKing = pieces[row][col]
    pieces[row][col] = ""  -- temporarily remove king

    -- Kingside: empty F & G files, rook on H, F & G not attacked
    if rights.kingSide
            and pieces[row][col+1] == "" and pieces[row][col+2] == ""
            and pieces[row][BOARD_MAX] ~= "" and pieces[row][BOARD_MAX]:match("rook")
            and Chess.getPieceColour(pieces[row][BOARD_MAX]) == pieceColour
            and not isSquareAttackedBy(pieces, row, col+1, enemy)
            and not isSquareAttackedBy(pieces, row, col+2, enemy) then
        table.insert(moves, {row, col+2})
    end

    -- Queenside: empty B, C & D files, rook on A; D & C not attacked (B just needs to be empty)
    if rights.queenSide
            and pieces[row][col-1] == "" and pieces[row][col-2] == "" and pieces[row][col-3] == ""
            and pieces[row][BOARD_MIN] ~= "" and pieces[row][BOARD_MIN]:match("rook")
            and Chess.getPieceColour(pieces[row][BOARD_MIN]) == pieceColour
            and not isSquareAttackedBy(pieces, row, col-1, enemy)
            and not isSquareAttackedBy(pieces, row, col-2, enemy) then
        table.insert(moves, {row, col-2})
    end

    pieces[row][col] = savedKing
    return moves
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Chess.getPieceColour(piece)
    return piece:match("^white") and "white" or "black"
end

function Chess.isKingInCheck(pieces, player)
    local kingRow, kingCol
    for scanRow = BOARD_MIN, BOARD_MAX do
        for scanCol = BOARD_MIN, BOARD_MAX do
            if pieces[scanRow][scanCol] == player .. "_king" then kingRow, kingCol = scanRow, scanCol; break end
        end
    end

    for scanRow = BOARD_MIN, BOARD_MAX do
        for scanCol = BOARD_MIN, BOARD_MAX do
            if pieces[scanRow][scanCol] ~= "" and Chess.getPieceColour(pieces[scanRow][scanCol]) ~= player then
                for _, move in ipairs(getRawMoves(pieces, scanRow, scanCol)) do
                    if move[1] == kingRow and move[2] == kingCol then return true end
                end
            end
        end
    end
    return false
end

local function filterLegalMoves(pieces, enPassantTarget, fromRow, fromCol, candidates, pieceColour)
    local legal = {}
    for _, move in ipairs(candidates) do
        local toRow, toCol  = move[1], move[2]
        local savedFrom = pieces[fromRow][fromCol]
        local savedTo   = pieces[toRow][toCol]
        pieces[toRow][toCol]     = savedFrom
        pieces[fromRow][fromCol] = ""

        -- Temporarily remove en-passant-captured pawn to test for horizontal pins.
        local epRow, epCol, savedEpPawn
        if enPassantTarget and savedFrom:match("pawn") and
                toRow == enPassantTarget[1] and toCol == enPassantTarget[2] then
            epRow, epCol = fromRow, toCol
            savedEpPawn  = pieces[epRow][epCol]
            pieces[epRow][epCol] = ""
        end

        -- For castling (king moves 2 squares sideways), also simulate the rook.
        local isCastling = savedFrom:match("king") and math.abs(toCol - fromCol) == 2
        local castleRookFromCol, castleRookToCol, savedCastleRook
        if isCastling then
            castleRookFromCol = toCol > fromCol and BOARD_MAX or BOARD_MIN
            castleRookToCol   = toCol > fromCol and toCol - 1  or toCol + 1
            savedCastleRook   = pieces[fromRow][castleRookFromCol]
            pieces[fromRow][castleRookToCol]   = savedCastleRook
            pieces[fromRow][castleRookFromCol] = ""
        end

        local stillInCheck = Chess.isKingInCheck(pieces, pieceColour)
        pieces[fromRow][fromCol] = savedFrom
        pieces[toRow][toCol]     = savedTo
        if epRow then pieces[epRow][epCol] = savedEpPawn end
        if isCastling then
            pieces[fromRow][castleRookFromCol] = savedCastleRook
            pieces[fromRow][castleRookToCol]   = ""
        end

        if not stillInCheck then
            table.insert(legal, move)
        end
    end
    return legal
end

-- castlingRights is optional (nil = no castling).
function Chess.getValidMoves(pieces, enPassantTarget, row, col, castlingRights)
    local piece       = pieces[row][col]
    local pieceColour = Chess.getPieceColour(piece)
    local candidates
    if piece:match("pawn") then
        candidates = getPawnMoves(pieces, enPassantTarget, row, col, pieceColour)
    else
        candidates = getRawMoves(pieces, row, col)
    end

    -- Append castling destinations when the piece is a king
    if piece:match("king") then
        for _, castleMove in ipairs(getCastlingMoves(pieces, castlingRights, row, col, pieceColour)) do
            table.insert(candidates, castleMove)
        end
    end

    return filterLegalMoves(pieces, enPassantTarget, row, col, candidates, pieceColour)
end

-- Exposed for tests that verify raw move counts (e.g. knight geometry).
Chess.getRawMoves = getRawMoves

-- castlingRights is optional (nil = no castling).
function Chess.hasLegalMoves(pieces, enPassantTarget, player, castlingRights)
    for scanRow = BOARD_MIN, BOARD_MAX do
        for scanCol = BOARD_MIN, BOARD_MAX do
            if pieces[scanRow][scanCol] ~= "" and Chess.getPieceColour(pieces[scanRow][scanCol]) == player then
                if #Chess.getValidMoves(pieces, enPassantTarget, scanRow, scanCol, castlingRights) > 0 then
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
        pieces[toRow][rookToCol]     = pieces[fromRow][rookFromCol]
        pieces[fromRow][rookFromCol] = ""
    end

    -- Move notation
    local destinationSquare = string.char(96 + toCol):upper() .. tostring(9 - toRow)
    local notation
    if isCastling then
        notation = toCol > fromCol and "Kingside castling" or "Queenside castling"
    elseif isEnPassant then
        notation = movedPiece .. " takes " .. destinationSquare .. " e.p."
    elseif targetPiece ~= "" then
        notation = movedPiece .. " takes " .. destinationSquare
    else
        notation = movedPiece .. " to " .. destinationSquare
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
            local capturedColour = Chess.getPieceColour(targetPiece)
            if toCol == BOARD_MAX then newCastlingRights[capturedColour].kingSide  = false end
            if toCol == BOARD_MIN then newCastlingRights[capturedColour].queenSide = false end
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
