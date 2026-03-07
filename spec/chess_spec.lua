-- Resolve the project root from this file's location so require("chess") works
-- regardless of what directory busted is invoked from (e.g. VS Code extension).
local specPath = debug.getinfo(1, "S").source:sub(2)  -- strip leading '@'
local projectRoot = specPath:match("(.*[/\\])spec[/\\]")
if projectRoot then
    package.path = projectRoot .. "?.lua;" .. package.path
end

require("chess")

-- Helpers to set up board state
-- busted sandboxes spec files in their own _ENV; chess.lua uses _G,
-- so board helpers must write to _G.pieces explicitly.
local function emptyBoard()
    local p = {}
    for i = 1, 8 do
        p[i] = {}
        for j = 1, 8 do
            p[i][j] = ""
        end
    end
    _G.pieces = p
end

local function startingPosition()
    _G.pieces = {
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
    _G.pieces = {
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
        assert.equal("white", getPieceColour("white_pawn"))
        assert.equal("white", getPieceColour("white_king"))
        assert.equal("white", getPieceColour("white_queen"))
    end)

    it("returns black for black pieces", function()
        assert.equal("black", getPieceColour("black_pawn"))
        assert.equal("black", getPieceColour("black_king"))
        assert.equal("black", getPieceColour("black_knight"))
    end)
end)

-- ─────────────────────────────────────────────
describe("isKingInCheck", function()
    it("returns false for both sides at starting position", function()
        startingPosition()
        assert.is_false(isKingInCheck("white"))
        assert.is_false(isKingInCheck("black"))
    end)

    it("returns true when king is attacked by a rook on the same rank", function()
        emptyBoard()
        pieces[1][1] = "black_king"
        pieces[1][5] = "white_rook"
        pieces[8][5] = "white_king"  -- white king needed to avoid infinite loop edge cases
        assert.is_true(isKingInCheck("black"))
    end)

    it("returns false when the check is blocked by an intervening piece", function()
        emptyBoard()
        pieces[1][1] = "black_king"
        pieces[1][3] = "black_pawn"  -- blocker
        pieces[1][5] = "white_rook"
        pieces[8][5] = "white_king"
        assert.is_false(isKingInCheck("black"))
    end)

    it("returns true when king is attacked by a bishop diagonally", function()
        emptyBoard()
        pieces[1][1] = "black_king"
        pieces[4][4] = "white_bishop"
        pieces[8][8] = "white_king"
        assert.is_true(isKingInCheck("black"))
    end)

    it("returns true when king is attacked by a knight", function()
        emptyBoard()
        pieces[1][4] = "black_king"  -- D8
        pieces[3][3] = "white_knight"  -- C6, attacks D8 and B8
        pieces[8][5] = "white_king"
        assert.is_true(isKingInCheck("black"))
    end)
end)

-- ─────────────────────────────────────────────
describe("pawn moves", function()
    it("white pawn can move one or two squares from its starting row", function()
        startingPosition()
        local moves = getValidMoves(7, 1)  -- white pawn at A2
        assert.equal(2, #moves)
    end)

    it("black pawn can move one or two squares from its starting row", function()
        startingPosition()
        local moves = getValidMoves(2, 1)  -- black pawn at A7
        assert.equal(2, #moves)
    end)

    it("pawn cannot move if blocked by a piece directly in front", function()
        emptyBoard()
        pieces[7][1] = "white_pawn"
        pieces[6][1] = "black_pawn"   -- blocking piece
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = getValidMoves(7, 1)
        assert.equal(0, #moves)
    end)

    it("white pawn can only move one square when not on starting row", function()
        emptyBoard()
        pieces[5][4] = "white_pawn"  -- D4, not on starting row
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = getValidMoves(5, 4)
        assert.equal(1, #moves)
        assert.equal(4, moves[1][1])  -- moved to D5 (row 4)
        assert.equal(4, moves[1][2])
    end)

    it("white pawn can capture diagonally", function()
        emptyBoard()
        pieces[5][4] = "white_pawn"   -- D4
        pieces[4][5] = "black_pawn"   -- E5, capturable
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = getValidMoves(5, 4)
        assert.equal(2, #moves)  -- forward + diagonal capture
    end)
end)

-- ─────────────────────────────────────────────
describe("knight moves", function()
    it("knight in the centre has up to 8 moves", function()
        emptyBoard()
        pieces[4][4] = "white_knight"  -- D5
        pieces[1][5] = "black_king"
        pieces[8][5] = "white_king"
        local moves = getRawMoves(4, 4)
        assert.equal(8, #moves)
    end)

    it("knight in the corner has only 2 moves", function()
        emptyBoard()
        pieces[1][1] = "white_knight"  -- A8
        pieces[8][5] = "white_king"
        pieces[1][5] = "black_king"
        local moves = getRawMoves(1, 1)
        assert.equal(2, #moves)
    end)
end)

-- ─────────────────────────────────────────────
describe("Scholar's Mate", function()
    before_each(function()
        scholarsMatePosision()
    end)

    it("black king is in check from the white queen", function()
        assert.is_true(isKingInCheck("black"))
    end)

    it("black has no legal moves (checkmate)", function()
        assert.is_false(hasLegalMoves("black"))
    end)

    it("white is not in check", function()
        assert.is_false(isKingInCheck("white"))
    end)
end)

-- ─────────────────────────────────────────────
describe("pinned pieces", function()
    it("a piece pinned to its king cannot move", function()
        emptyBoard()
        -- White king at E1, white rook at E4 (pinned), black rook at E8
        pieces[8][5] = "white_king"   -- E1
        pieces[5][5] = "white_rook"   -- E4 (pinned along E file)
        pieces[1][5] = "black_rook"   -- E8
        pieces[1][1] = "black_king"
        local moves = getValidMoves(5, 5)
        -- Pinned rook can only move along the pin ray (file E), not sideways
        for _, move in ipairs(moves) do
            assert.equal(5, move[2])  -- must stay on file E (column 5)
        end
    end)
end)

-- ─────────────────────────────────────────────
describe("stalemate detection", function()
    it("a player with no legal moves but not in check has no legal moves", function()
        -- Classic stalemate: black king at A8, white queen at B6, white king at C6
        emptyBoard()
        pieces[1][1] = "black_king"   -- A8
        pieces[3][2] = "white_queen"  -- B6
        pieces[3][3] = "white_king"   -- C6
        assert.is_false(isKingInCheck("black"))
        assert.is_false(hasLegalMoves("black"))
    end)
end)
