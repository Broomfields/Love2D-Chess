local Chess  = require("chess")
local Theme  = require("theme")
local Popup  = require("ui")
local Popups = require("popups")
local Layout = require("layout")
local Audio  = require("audio")

local Game = {}

-- ── Game-state locals ─────────────────────────────────────────────────────────
local board, pieces, pieceImages
local selectedPiece
local selectedX, selectedY
local hoveredX, hoveredY
local currentPlayer, validMoves
local gameStartTime, turnStartTime
local latestMove, inCheck, gameOverResult
local enPassantTarget
local castlingRights
local hoveredButton
local onTransition  -- callback(state) → signals main.lua of a screen change

-- ── Initialisation ────────────────────────────────────────────────────────────

-- opts.onTransition(state) is called when the game needs to change screen.
function Game.init(opts)
    onTransition = opts and opts.onTransition

    board = {}
    for i = 1, 8 do
        board[i] = {}
        for j = 1, 8 do
            board[i][j] = {
                piece  = nil,
                colour = (i + j) % 2 == 0 and Theme.boardLight or Theme.boardDark
            }
        end
    end

    selectedPiece    = nil
    selectedX, selectedY = nil, nil
    hoveredX,  hoveredY  = nil, nil
    currentPlayer    = "white"
    validMoves       = {}
    gameStartTime    = love.timer.getTime()
    turnStartTime    = love.timer.getTime()
    latestMove       = ""
    inCheck          = false
    gameOverResult   = ""
    enPassantTarget  = nil
    castlingRights   = {
        white = { kingSide = true, queenSide = true },
        black = { kingSide = true, queenSide = true },
    }
    hoveredButton    = nil

    Audio.load("pieceMoved",  "assets/sounds/pieceMoved.ogg")
    Audio.load("pieceTaken",  "assets/sounds/pieceTaken.ogg")
    Audio.load("buttonClick", "assets/sounds/buttonClick.ogg")
    Audio.load("inCheck",     "assets/sounds/inCheck.ogg")

    pieceImages = {
        white_pawn   = love.graphics.newImage("assets/images/white_pawn.png"),
        white_rook   = love.graphics.newImage("assets/images/white_rook.png"),
        white_knight = love.graphics.newImage("assets/images/white_knight.png"),
        white_bishop = love.graphics.newImage("assets/images/white_bishop.png"),
        white_queen  = love.graphics.newImage("assets/images/white_queen.png"),
        white_king   = love.graphics.newImage("assets/images/white_king.png"),
        black_pawn   = love.graphics.newImage("assets/images/black_pawn.png"),
        black_rook   = love.graphics.newImage("assets/images/black_rook.png"),
        black_knight = love.graphics.newImage("assets/images/black_knight.png"),
        black_bishop = love.graphics.newImage("assets/images/black_bishop.png"),
        black_queen  = love.graphics.newImage("assets/images/black_queen.png"),
        black_king   = love.graphics.newImage("assets/images/black_king.png"),
    }

    pieces = {
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

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function isValidMove(i, j)
    for _, move in ipairs(validMoves) do
        if move[1] == i and move[2] == j then return true end
    end
    return false
end

local function switchPlayer()
    currentPlayer = currentPlayer == "white" and "black" or "white"
    turnStartTime = love.timer.getTime()
    inCheck       = Chess.isKingInCheck(pieces, currentPlayer)

    if inCheck then
        Audio.play("inCheck")
    end

    if not Chess.hasLegalMoves(pieces, enPassantTarget, currentPlayer, castlingRights) then
        if inCheck then
            gameOverResult = (currentPlayer == "white" and "Black" or "White") .. " wins by checkmate!"
        else
            gameOverResult = "Draw by stalemate!"
        end
        local cfg = Popups.gameOver(gameOverResult, inCheck)
        cfg.onButton = function(label)
            Audio.play("buttonClick")
            if label == "Main Menu" then
                Popup.hide()
                if onTransition then onTransition("menu") end
            end
        end
        hoveredButton = nil
        Popup.show(cfg)
    end
end

local function drawCornerLines(x, y, size, width, length)
    love.graphics.line(x,        y,        x + length,        y)
    love.graphics.line(x,        y,        x,                 y + length)
    love.graphics.line(x + size, y,        x + size - length, y)
    love.graphics.line(x + size, y,        x + size,          y + length)
    love.graphics.line(x,        y + size, x + length,        y + size)
    love.graphics.line(x,        y + size, x,                 y + size - length)
    love.graphics.line(x + size, y + size, x + size - length, y + size)
    love.graphics.line(x + size, y + size, x + size,          y + size - length)
end

local function drawBoard(boardX, boardY, squareSize, boardSize)
    local borderWidth  = 5
    local cornerLength = 20

    -- Oak border
    love.graphics.setColor(Theme.border)
    love.graphics.rectangle("fill",
        boardX - Theme.borderSize, boardY - Theme.borderSize,
        boardSize + 2 * Theme.borderSize, boardSize + 2 * Theme.borderSize)

    -- Chess notation coordinates
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Theme.regularFont)
    for i = 1, 8 do
        local letter = string.char(96 + i):upper()
        local number = tostring(9 - i)
        love.graphics.print(letter, boardX + (i-1)*squareSize + squareSize/2, boardY - Theme.borderSize/2, 0,1,1,6,6)
        love.graphics.print(letter, boardX + (i-1)*squareSize + squareSize/2, boardY + boardSize + Theme.borderSize/2, 0,1,1,6,6)
        love.graphics.print(number, boardX - Theme.borderSize/2, boardY + (i-1)*squareSize + squareSize/2, 0,1,1,6,6)
        love.graphics.print(number, boardX + boardSize + Theme.borderSize/2, boardY + (i-1)*squareSize + squareSize/2, 0,1,1,6,6)
    end

    -- Squares and pieces
    for i = 1, 8 do
        for j = 1, 8 do
            love.graphics.setColor(board[i][j].colour)
            love.graphics.rectangle("fill",
                boardX + (j-1)*squareSize, boardY + (i-1)*squareSize, squareSize, squareSize)

            if pieces[i][j] ~= "" then
                local img    = pieceImages[pieces[i][j]]
                local iw, ih = img:getWidth(), img:getHeight()
                local scale  = 0.9 * squareSize / math.max(iw, ih)
                local offX   = (squareSize - iw * scale) / 2
                local offY   = (squareSize - ih * scale) / 2
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(img,
                    boardX + (j-1)*squareSize + offX,
                    boardY + (i-1)*squareSize + offY,
                    0, scale, scale)
            end
        end
    end

    -- Hover highlight
    if hoveredX and hoveredY then
        love.graphics.setColor(Theme.hoverOrange)
        love.graphics.rectangle("fill",
            boardX + (hoveredY-1)*squareSize, boardY + (hoveredX-1)*squareSize, squareSize, squareSize)
    end

    -- Selection outline
    if selectedX and selectedY then
        love.graphics.setColor(Theme.selectBlue)
        love.graphics.setLineWidth(borderWidth)
        love.graphics.rectangle("line",
            boardX + (selectedY-1)*squareSize + borderWidth/2,
            boardY + (selectedX-1)*squareSize + borderWidth/2,
            squareSize - borderWidth, squareSize - borderWidth)
    end

    -- Check outline on king
    if inCheck then
        for i = 1, 8 do
            for j = 1, 8 do
                if pieces[i][j] == currentPlayer .. "_king" then
                    love.graphics.setColor(Theme.checkRed)
                    love.graphics.setLineWidth(borderWidth)
                    love.graphics.rectangle("line",
                        boardX + (j-1)*squareSize + borderWidth/2,
                        boardY + (i-1)*squareSize + borderWidth/2,
                        squareSize - borderWidth, squareSize - borderWidth)
                    break
                end
            end
        end
    end

    -- Valid move indicators
    local isCastlingMove = selectedPiece and selectedPiece:match("king")
    for _, move in ipairs(validMoves) do
        local targetPiece = pieces[move[1]][move[2]]
        local isEpCapture = enPassantTarget and selectedPiece and selectedPiece:match("pawn") and
                            move[1] == enPassantTarget[1] and move[2] == enPassantTarget[2]
        local isCastle    = isCastlingMove and math.abs(move[2] - selectedY) == 2
        if isCastle or isEpCapture then
            love.graphics.setColor(Theme.castlePurple)
        elseif targetPiece ~= "" and Chess.getPieceColour(targetPiece) ~= currentPlayer then
            love.graphics.setColor(Theme.checkRed)
        else
            love.graphics.setColor(Theme.moveAmber)
        end
        love.graphics.setLineWidth(borderWidth)
        drawCornerLines(
            boardX + (move[2]-1)*squareSize + borderWidth/2,
            boardY + (move[1]-1)*squareSize + borderWidth/2,
            squareSize - borderWidth, borderWidth, cornerLength)

        -- Draw a purple outline on the other piece involved in a special move
        if isCastle then
            local rookCol = move[2] > selectedY and 8 or 1
            love.graphics.setColor(Theme.castlePurple)
            love.graphics.setLineWidth(borderWidth)
            love.graphics.rectangle("line",
                boardX + (rookCol-1)*squareSize + borderWidth/2,
                boardY + (move[1]-1)*squareSize + borderWidth/2,
                squareSize - borderWidth, squareSize - borderWidth)
        elseif isEpCapture then
            -- Captured pawn sits on the moving pawn's row, at the destination column
            love.graphics.setColor(Theme.castlePurple)
            love.graphics.setLineWidth(borderWidth)
            love.graphics.rectangle("line",
                boardX + (move[2]-1)*squareSize + borderWidth/2,
                boardY + (selectedX-1)*squareSize + borderWidth/2,
                squareSize - borderWidth, squareSize - borderWidth)
        end
    end
end

local function drawUI(boardX, boardY, boardSize)
    love.graphics.setFont(Theme.regularFont)
    love.graphics.setColor(1, 1, 1)

    -- Current player
    love.graphics.print("Current Player: ", boardX, boardY - (Theme.uiHeight + 20))
    love.graphics.print(currentPlayer,       boardX, boardY - Theme.uiHeight + 10)

    -- Latest move
    love.graphics.print("Latest Move: ", boardX + 200, boardY - (Theme.uiHeight + 20))
    love.graphics.print(latestMove,      boardX + 200, boardY - Theme.uiHeight + 10)

    -- CHECK badge
    if inCheck then
        local badgeW = 80
        local badgeH = 28
        local badgeX = boardX + boardSize - badgeW
        local badgeY = boardY - Theme.uiHeight - 20
        love.graphics.setColor(Theme.checkBadge)
        love.graphics.rectangle("fill", badgeX, badgeY, badgeW, badgeH, 4, 4)
        love.graphics.setFont(Theme.boldFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("CHECK", badgeX, badgeY + (badgeH - Theme.boldFont:getHeight()) / 2, badgeW, "center")
    end

    -- Resign button
    local R = Layout.getResignButton(boardX, boardY, boardSize)
    love.graphics.setColor(hoveredButton == "resign" and Theme.buttonRedHov or Theme.buttonRed)
    love.graphics.rectangle("fill", R.x, R.y, R.w, R.h)
    love.graphics.setFont(Theme.regularFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Resign", R.x, R.y + (R.h - Theme.regularFont:getHeight()) / 2, R.w, "center")

    -- Timers
    love.graphics.setFont(Theme.regularFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Game Time: " .. string.format("%.2f", love.timer.getTime() - gameStartTime),
        boardX,       boardY + boardSize + Theme.borderSize / 2 + 30)
    love.graphics.print("Turn Time: " .. string.format("%.2f", love.timer.getTime() - turnStartTime),
        boardX + 200, boardY + boardSize + Theme.borderSize / 2 + 30)
end

-- ── Public interface ──────────────────────────────────────────────────────────

function Game.draw()
    local w, h = love.graphics.getDimensions()
    local L    = Layout.getBoard(w, h)

    love.graphics.clear(Theme.background)
    drawBoard(L.boardX, L.boardY, L.squareSize, L.boardSize)
    drawUI(L.boardX, L.boardY, L.boardSize)
    Popup.draw()
end

function Game.handleHover(x, y)
    local w, h = love.graphics.getDimensions()
    local L    = Layout.getBoard(w, h)

    hoveredX = math.floor((y - L.boardY) / L.squareSize) + 1
    hoveredY = math.floor((x - L.boardX) / L.squareSize) + 1
    if hoveredX < 1 or hoveredX > 8 or hoveredY < 1 or hoveredY > 8 then
        hoveredX, hoveredY = nil, nil
    end

    local R = Layout.getResignButton(L.boardX, L.boardY, L.boardSize)
    hoveredButton = Layout.hit(x, y, R.x, R.y, R.w, R.h) and "resign" or nil
end

function Game.handleClick(x, y)
    local w, h = love.graphics.getDimensions()
    local L    = Layout.getBoard(w, h)

    -- Resign button
    local R = Layout.getResignButton(L.boardX, L.boardY, L.boardSize)
    if Layout.hit(x, y, R.x, R.y, R.w, R.h) then
        Audio.play("buttonClick")
        local cfg = Popups.resignConfirm()
        cfg.onButton = function(label)
            Audio.play("buttonClick")
            Popup.hide()
            if label == "Yes, Resign" and onTransition then
                onTransition("menu")
            end
        end
        hoveredButton = nil
        Popup.show(cfg)
        return
    end

    -- Board click
    local i = math.floor((y - L.boardY) / L.squareSize) + 1
    local j = math.floor((x - L.boardX) / L.squareSize) + 1

    if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
        if selectedPiece then
            if isValidMove(i, j) then
                local fromRow, fromCol = selectedX, selectedY
                selectedPiece       = nil
                selectedX, selectedY = nil, nil
                validMoves          = {}

                local result = Chess.executeMove(pieces, enPassantTarget, fromRow, fromCol, i, j, castlingRights)
                latestMove      = result.notation
                enPassantTarget = result.newEnPassantTarget
                castlingRights  = result.newCastlingRights or castlingRights

                if result.captured ~= "" then
                    Audio.play("pieceTaken")
                else
                    Audio.play("pieceMoved")
                end

                if result.isPromotion then
                    local promRow, promCol = i, j
                    local cfg = Popups.pawnPromotion(currentPlayer, pieceImages)
                    cfg.onPick = function(value)
                        Audio.play("buttonClick")
                        pieces[promRow][promCol] = value
                        Popup.hide()
                        switchPlayer()
                    end
                    hoveredButton = nil
                    Popup.show(cfg)
                else
                    switchPlayer()
                end

            elseif selectedX == i and selectedY == j then
                selectedPiece       = nil
                selectedX, selectedY = nil, nil
                validMoves          = {}

            elseif pieces[i][j] ~= "" and Chess.getPieceColour(pieces[i][j]) == currentPlayer then
                selectedPiece       = pieces[i][j]
                selectedX, selectedY = i, j
                validMoves          = Chess.getValidMoves(pieces, enPassantTarget, i, j, castlingRights)

            else
                selectedPiece       = nil
                selectedX, selectedY = nil, nil
                validMoves          = {}
            end

        elseif pieces[i][j] ~= "" and Chess.getPieceColour(pieces[i][j]) == currentPlayer then
            selectedPiece       = pieces[i][j]
            selectedX, selectedY = i, j
            validMoves          = Chess.getValidMoves(pieces, enPassantTarget, i, j, castlingRights)

        else
            selectedPiece       = nil
            selectedX, selectedY = nil, nil
            validMoves          = {}
        end
    end
end

return Game
