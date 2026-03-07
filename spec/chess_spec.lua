-- Resolve the project root from this file's location so require("chess") works
-- regardless of what directory busted is invoked from (e.g. VS Code extension).
local specPath = debug.getinfo(1, "S").source:sub(2)  -- strip leading '@'
local projectRoot = specPath:match("(.*[/\\])spec[/\\]")
if projectRoot then
    package.path = projectRoot .. "?.lua;" .. package.path
end

local Chess = require("chess")

-- Board helpers — return a fresh pieces table each call; no _G mutation needed.
local function emptyBoard()
    local p = {}
    for i = 1, 8 do
        p[i] = {}
        for j = 1, 8 do
            p[i][j] = ""
        end
    end
    return p
end

local function startingPosition()
    return {
        {"black_rook", "black_knight", "black_bishop", "black_queen", "black_king", "black_bishop", "black_knight", "black_rook"},
        {"black_pawn", "black_pawn", "black_pawn", "black_pawn", "black_pawn", "black_pawn", "black_pawn", "black_pawn"},
        {"", "", "", "", "", "", "", ""},
        {"", "", "", "", "", "", "", ""},
        {"", "", "", "", "", "", "", ""},
        {"", "", "", "", "", "", "", ""},
        {"white_pawn", "white_pawn", "white_pawn", "white_pawn", "white_pawn", "white_pawn", "white_pawn", "white_pawn"},
        {"white_rook", "white_knight", "white_bishop", "white_queen", "white_king", "white_bishop", "white_knight", "white_rook"}
    }
end

-- Scholar's Mate position after Qxf7#
-- Board layout (row 1 = rank 8, col 1 = file A):
--   A8=black_rook, C8=black_bishop, D8=black_queen, E8=black_king, F8=black_bishop, H8=black_rook
--   A7-D7=black_pawns, F7=white_queen, G7-H7=black_pawns
--   C6=black_knight, F6=black_knight
--   E5=black_pawn
--   C4=white_bishop
--   A2-D2,F2-H2=white_pawns
--   A1=white_rook, B1=white_knight, C1=white_bishop, E1=white_king, G1=white_knight, H1=white_rook
local function scholarsMatePosision()
    return {
        {"black_rook", "",            "black_bishop", "black_queen", "black_king", "black_bishop", "",             "black_rook"},
        {"black_pawn", "black_pawn",  "black_pawn",   "black_pawn",  "",           "white_queen",  "black_pawn",   "black_pawn"},
        {"",           "",            "black_knight", "",            "",            "black_knight", "",             ""},
        {"",           "",            "",             "",            "black_pawn",  "",             "",             ""},
        {"",           "",            "white_bishop", "",            "",            "",             "",             ""},
        {"",           "",            "",             "",            "",            "",             "",             ""},
        {"white_pawn", "white_pawn",  "white_pawn",   "white_pawn",  "",            "white_pawn",   "white_pawn",   "white_pawn"},
        {"white_rook", "white_knight","white_bishop", "",            "white_king",  "",             "white_knight", "white_rook"}
    }
end

-- ─────────────────────────────────────────────
describe("getPieceColour", function()
    it("returns white for white pieces", function()
        assert.equal("white", Chess.getPieceColour("white_pawn"))
        assert.equal("white", Chess.getPieceColour("white_king"))
        assert.equal("white", Chess.getPieceColour("white_queen"))
    end)

    it("returns black for black pieces", function()
        assert.equal("black", Chess.getPieceColour("black_pawn"))
        assert.equal("black", Chess.getPieceColour("black_king"))
        assert.equal("black", Chess.getPieceColour("black_knight"))
    end)
end)

-- ─────────────────────────────────────────────
describe("isKingInCheck", function()
    it("returns false for both sides at starting position", function()
        local pieces = startingPosition()
        assert.is_false(Chess.isKingInCheck(pieces, "white"))
        assert.is_false(Chess.isKingInCheck(pieces, "black"))
    end)

    it("returns true when king is attacked by a rook on the same rank", function()
        local pieces = emptyBoard()
        pieces[1][1] = "black_king"
        pieces[1][5] = "white_rook"
        pieces[8][5] = "white_king"  -- white king needed to avoid infinite loop edge cases
        assert.is_true(Chess.isKingInCheck(pieces, "black"))
    end)

    it("returns false when the check is blocked by an intervening piece", function()
        local pieces = emptyBoard()
        pieces[1][1] = "black_king"
        pieces[1][3] = "black_pawn"  -- blocker
        pieces[1][5] = "white_rook"
        pieces[8][5] = "white_king"
        assert.is_false(Chess.isKingInCheck(pieces, "black"))
    end)

    it("returns true when king is attacked by a bishop diagonally", function()
        local pieces = emptyBoard()
        pieces[1][1] = "black_king"
        pieces[4][4] = "white_bishop"
        pieces[8][8] = "white_king"
        assert.is_true(Chess.isKingInCheck(pieces, "black"))
    end)

    it("returns true when king is attacked by a knight", function()
        local pieces = emptyBoard()
        pieces[1][4] = "black_king"  -- D8
        pieces[3][3] = "white_knight"  -- C6, attacks D8 and B8
        pieces[8][5] = "white_king"
        assert.is_true(Chess.isKingInCheck(pieces, "black"))
    end)
end)

-- ─────────────────────────────────────────────
describe("pawn moves", function()
    it("white pawn can move one or two squares from its starting row", function()
        local pieces = startingPosition()
        local moves = Chess.getValidMoves(pieces, nil, 7, 1)  -- white pawn at A2
        assert.equal(2, #moves)
    end)

    it("black pawn can move one or two squares from its starting row", function()
        local pieces = startingPosition()
        local moves = Chess.getValidMoves(pieces, nil, 2, 1)  -- black pawn at A7
        assert.equal(2, #moves)
    end)

    it("pawn cannot move if blocked by a piece directly in front", function()
        local pieces = emptyBoard()
        pieces[7][1] = "white_pawn"
        pieces[6][1] = "black_pawn"   -- blocking piece
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = Chess.getValidMoves(pieces, nil, 7, 1)
        assert.equal(0, #moves)
    end)

    it("white pawn can only move one square when not on starting row", function()
        local pieces = emptyBoard()
        pieces[5][4] = "white_pawn"  -- D4, not on starting row
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = Chess.getValidMoves(pieces, nil, 5, 4)
        assert.equal(1, #moves)
        assert.equal(4, moves[1][1])  -- moved to D5 (row 4)
        assert.equal(4, moves[1][2])
    end)

    it("white pawn can capture diagonally", function()
        local pieces = emptyBoard()
        pieces[5][4] = "white_pawn"   -- D4
        pieces[4][5] = "black_pawn"   -- E5, capturable
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = Chess.getValidMoves(pieces, nil, 5, 4)
        assert.equal(2, #moves)  -- forward + diagonal capture
    end)
end)

-- ─────────────────────────────────────────────
describe("knight moves", function()
    it("knight in the centre has up to 8 moves", function()
        local pieces = emptyBoard()
        pieces[4][4] = "white_knight"  -- D5
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = Chess.getRawMoves(pieces, 4, 4)
        assert.equal(8, #moves)
    end)

    it("knight in the corner has only 2 moves", function()
        local pieces = emptyBoard()
        pieces[1][1] = "white_knight"  -- A8
        pieces[8][5] = "white_king"
        pieces[1][5] = "black_king"
        local moves = Chess.getRawMoves(pieces, 1, 1)
        assert.equal(2, #moves)
    end)
end)

-- ─────────────────────────────────────────────
describe("Scholar's Mate", function()
    local pieces
    before_each(function()
        pieces = scholarsMatePosision()
    end)

    it("black king is in check from the white queen", function()
        assert.is_true(Chess.isKingInCheck(pieces, "black"))
    end)

    it("black has no legal moves (checkmate)", function()
        assert.is_false(Chess.hasLegalMoves(pieces, nil, "black"))
    end)

    it("white is not in check", function()
        assert.is_false(Chess.isKingInCheck(pieces, "white"))
    end)
end)

-- ─────────────────────────────────────────────
describe("pinned pieces", function()
    it("a piece pinned to its king cannot move", function()
        local pieces = emptyBoard()
        -- White king at E1, white rook at E4 (pinned), black rook at E8
        pieces[8][5] = "white_king"   -- E1
        pieces[5][5] = "white_rook"   -- E4 (pinned along E file)
        pieces[1][5] = "black_rook"   -- E8
        pieces[1][1] = "black_king"
        local moves = Chess.getValidMoves(pieces, nil, 5, 5)
        -- Pinned rook can only move along the pin ray (file E), not sideways
        for _, move in ipairs(moves) do
            assert.equal(5, move[2])  -- must stay on file E (column 5)
        end
    end)
end)

-- ─────────────────────────────────────────────
describe("en passant", function()
    -- Board coordinates: row 1 = rank 8 (black side), row 8 = rank 1 (white side)
    -- White pawns move in direction -1 (toward row 1); black pawns +1 (toward row 8)

    it("white pawn can capture en passant when target is set", function()
        local pieces = emptyBoard()
        -- White pawn at D5 (row 4, col 4), black pawn just double-advanced to E5 (row 4, col 5)
        -- En passant target = E6 (row 3, col 5) — the square the black pawn skipped
        pieces[4][4] = "white_pawn"
        pieces[4][5] = "black_pawn"
        pieces[8][5] = "white_king"   -- keep kings off the pin rays
        pieces[1][5] = "black_king"
        local enPassantTarget = {3, 5}
        local moves = Chess.getValidMoves(pieces, enPassantTarget, 4, 4)
        local hasEP = false
        for _, m in ipairs(moves) do
            if m[1] == 3 and m[2] == 5 then hasEP = true end
        end
        assert.is_true(hasEP)
    end)

    it("en passant move is absent when enPassantTarget is nil", function()
        local pieces = emptyBoard()
        pieces[4][4] = "white_pawn"
        pieces[4][5] = "black_pawn"
        pieces[8][5] = "white_king"
        pieces[1][5] = "black_king"
        local moves = Chess.getValidMoves(pieces, nil, 4, 4)
        for _, m in ipairs(moves) do
            assert.is_false(m[1] == 3 and m[2] == 5)
        end
    end)

    it("en passant is filtered out when it exposes the king to a horizontal pin", function()
        local pieces = emptyBoard()
        -- White king at A5 (row 4, col 1), white pawn at D5 (row 4, col 4),
        -- black pawn at E5 (row 4, col 5), black rook at H5 (row 4, col 8).
        -- Capturing en passant removes both pawns from rank 5, leaving the king
        -- exposed to the rook along the rank → must be filtered out.
        pieces[4][1] = "white_king"
        pieces[4][4] = "white_pawn"
        pieces[4][5] = "black_pawn"
        pieces[4][8] = "black_rook"
        pieces[1][1] = "black_king"
        local enPassantTarget = {3, 5}
        local moves = Chess.getValidMoves(pieces, enPassantTarget, 4, 4)
        for _, m in ipairs(moves) do
            assert.is_false(m[1] == 3 and m[2] == 5, "en passant should be filtered (exposes king)")
        end
    end)
end)

-- ─────────────────────────────────────────────
describe("stalemate detection", function()
    it("a player with no legal moves but not in check has no legal moves", function()
        -- Classic stalemate: black king at A8, white queen at B6, white king at C6
        local pieces = emptyBoard()
        pieces[1][1] = "black_king"   -- A8
        pieces[3][2] = "white_queen"  -- B6
        pieces[3][3] = "white_king"   -- C6
        assert.is_false(Chess.isKingInCheck(pieces, "black"))
        assert.is_false(Chess.hasLegalMoves(pieces, nil, "black"))
    end)
end)
