local Chess  = require("chess")
local Theme  = require("theme")
local Popup  = require("ui")
local Popups = require("popups")
local Layout = require("layout")
local Audio  = require("audio")

local Game = {}

-- ── Layout constants ──────────────────────────────────────────────────────────
local LABEL_OFFSET_X = 200   -- x-offset for right-side UI labels (latest move, turn timer)
local BADGE_W        = 80    -- CHECK badge width
local BADGE_H        = 28    -- CHECK badge height
local BORDER_WIDTH   = 5     -- selection/check outline stroke width
local CORNER_LENGTH  = 20    -- corner bracket arm length for valid-move indicators

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
    for row = 1, 8 do
        board[row] = {}
        for col = 1, 8 do
            board[row][col] = {
                piece  = nil,
                colour = (row + col) % 2 == 0 and Theme.boardLight or Theme.boardDark
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
    castlingRights   = Chess.initialCastlingRights()
    hoveredButton    = nil

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

    pieces = Chess.startingPosition()
end

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function isValidMove(row, col)
    for _, move in ipairs(validMoves) do
        if move[1] == row and move[2] == col then return true end
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
        local popupConfig = Popups.gameOver(gameOverResult, inCheck)
        popupConfig.onButton = function(label)
            Audio.play("buttonClick")
            if label == "Main Menu" then
                Popup.hide()
                if onTransition then onTransition("menu") end
            end
        end
        hoveredButton = nil
        Popup.show(popupConfig)
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

    -- Oak border
    love.graphics.setColor(Theme.border)
    love.graphics.rectangle("fill",
        boardX - Theme.borderSize, boardY - Theme.borderSize,
        boardSize + 2 * Theme.borderSize, boardSize + 2 * Theme.borderSize)

    -- Chess notation coordinates
    love.graphics.setColor(Theme.text)
    love.graphics.setFont(Theme.regularFont)
    for fileIndex = 1, 8 do
        local letter = string.char(96 + fileIndex):upper()
        local number = tostring(9 - fileIndex)
        love.graphics.print(letter, boardX + (fileIndex-1)*squareSize + squareSize/2, boardY - Theme.borderSize/2, 0,1,1,6,6)
        love.graphics.print(letter, boardX + (fileIndex-1)*squareSize + squareSize/2, boardY + boardSize + Theme.borderSize/2, 0,1,1,6,6)
        love.graphics.print(number, boardX - Theme.borderSize/2, boardY + (fileIndex-1)*squareSize + squareSize/2, 0,1,1,6,6)
        love.graphics.print(number, boardX + boardSize + Theme.borderSize/2, boardY + (fileIndex-1)*squareSize + squareSize/2, 0,1,1,6,6)
    end

    -- Squares and pieces
    for row = 1, 8 do
        for col = 1, 8 do
            love.graphics.setColor(board[row][col].colour)
            love.graphics.rectangle("fill",
                boardX + (col-1)*squareSize, boardY + (row-1)*squareSize, squareSize, squareSize)

            if pieces[row][col] ~= "" then
                local pieceImage              = pieceImages[pieces[row][col]]
                local imageWidth, imageHeight = pieceImage:getWidth(), pieceImage:getHeight()
                local scale   = 0.9 * squareSize / math.max(imageWidth, imageHeight)
                local offsetX = (squareSize - imageWidth  * scale) / 2
                local offsetY = (squareSize - imageHeight * scale) / 2
                love.graphics.setColor(Theme.text)
                love.graphics.draw(pieceImage,
                    boardX + (col-1)*squareSize + offsetX,
                    boardY + (row-1)*squareSize + offsetY,
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
        love.graphics.setLineWidth(BORDER_WIDTH)
        love.graphics.rectangle("line",
            boardX + (selectedY-1)*squareSize + BORDER_WIDTH/2,
            boardY + (selectedX-1)*squareSize + BORDER_WIDTH/2,
            squareSize - BORDER_WIDTH, squareSize - BORDER_WIDTH)
    end

    -- Check outline on king
    if inCheck then
        for row = 1, 8 do
            for col = 1, 8 do
                if pieces[row][col] == currentPlayer .. "_king" then
                    love.graphics.setColor(Theme.checkRed)
                    love.graphics.setLineWidth(BORDER_WIDTH)
                    love.graphics.rectangle("line",
                        boardX + (col-1)*squareSize + BORDER_WIDTH/2,
                        boardY + (row-1)*squareSize + BORDER_WIDTH/2,
                        squareSize - BORDER_WIDTH, squareSize - BORDER_WIDTH)
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
        love.graphics.setLineWidth(BORDER_WIDTH)
        drawCornerLines(
            boardX + (move[2]-1)*squareSize + BORDER_WIDTH/2,
            boardY + (move[1]-1)*squareSize + BORDER_WIDTH/2,
            squareSize - BORDER_WIDTH, BORDER_WIDTH, CORNER_LENGTH)

        -- Draw a purple outline on the other piece involved in a special move
        if isCastle then
            local rookCol = move[2] > selectedY and Chess.BOARD_MAX or Chess.BOARD_MIN
            love.graphics.setColor(Theme.castlePurple)
            love.graphics.setLineWidth(BORDER_WIDTH)
            love.graphics.rectangle("line",
                boardX + (rookCol-1)*squareSize + BORDER_WIDTH/2,
                boardY + (move[1]-1)*squareSize + BORDER_WIDTH/2,
                squareSize - BORDER_WIDTH, squareSize - BORDER_WIDTH)
        elseif isEpCapture then
            -- Captured pawn sits on the moving pawn's row, at the destination column
            love.graphics.setColor(Theme.castlePurple)
            love.graphics.setLineWidth(BORDER_WIDTH)
            love.graphics.rectangle("line",
                boardX + (move[2]-1)*squareSize + BORDER_WIDTH/2,
                boardY + (selectedX-1)*squareSize + BORDER_WIDTH/2,
                squareSize - BORDER_WIDTH, squareSize - BORDER_WIDTH)
        end
    end
end

local function drawUI(boardX, boardY, boardSize)
    love.graphics.setFont(Theme.regularFont)
    love.graphics.setColor(Theme.text)

    -- Current player
    love.graphics.print("Current Player: ", boardX, boardY - (Theme.uiHeight + 20))
    love.graphics.print(currentPlayer,       boardX, boardY - Theme.uiHeight + 10)

    -- Latest move
    love.graphics.print("Latest Move: ", boardX + LABEL_OFFSET_X, boardY - (Theme.uiHeight + 20))
    love.graphics.print(latestMove,      boardX + LABEL_OFFSET_X, boardY - Theme.uiHeight + 10)

    -- CHECK badge
    if inCheck then
        local badgeX = boardX + boardSize - BADGE_W
        local badgeY = boardY - Theme.uiHeight - 20
        love.graphics.setColor(Theme.checkBadge)
        love.graphics.rectangle("fill", badgeX, badgeY, BADGE_W, BADGE_H, 4, 4)
        love.graphics.setFont(Theme.boldFont)
        love.graphics.setColor(Theme.text)
        love.graphics.printf("CHECK", badgeX, badgeY + (BADGE_H - Theme.boldFont:getHeight()) / 2, BADGE_W, "center")
    end

    -- Resign button
    local resignButton = Layout.getResignButton(boardX, boardY, boardSize)
    love.graphics.setColor(hoveredButton == "resign" and Theme.buttonRedHov or Theme.buttonRed)
    love.graphics.rectangle("fill", resignButton.x, resignButton.y, resignButton.w, resignButton.h)
    love.graphics.setFont(Theme.regularFont)
    love.graphics.setColor(Theme.text)
    love.graphics.printf("Resign", resignButton.x, resignButton.y + (resignButton.h - Theme.regularFont:getHeight()) / 2, resignButton.w, "center")

    -- Timers
    love.graphics.setFont(Theme.regularFont)
    love.graphics.setColor(Theme.text)
    love.graphics.print("Game Time: " .. string.format("%.2f", love.timer.getTime() - gameStartTime),
        boardX,       boardY + boardSize + Theme.borderSize / 2 + 30)
    love.graphics.print("Turn Time: " .. string.format("%.2f", love.timer.getTime() - turnStartTime),
        boardX + LABEL_OFFSET_X, boardY + boardSize + Theme.borderSize / 2 + 30)
end

-- ── Public interface ──────────────────────────────────────────────────────────

function Game.draw()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boardLayout = Layout.getBoard(windowWidth, windowHeight)

    love.graphics.clear(Theme.background)
    drawBoard(boardLayout.boardX, boardLayout.boardY, boardLayout.squareSize, boardLayout.boardSize)
    drawUI(boardLayout.boardX, boardLayout.boardY, boardLayout.boardSize)
    Popup.draw()
end

function Game.handleHover(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boardLayout = Layout.getBoard(windowWidth, windowHeight)

    hoveredX = math.floor((y - boardLayout.boardY) / boardLayout.squareSize) + 1
    hoveredY = math.floor((x - boardLayout.boardX) / boardLayout.squareSize) + 1
    if hoveredX < Chess.BOARD_MIN or hoveredX > Chess.BOARD_MAX or hoveredY < Chess.BOARD_MIN or hoveredY > Chess.BOARD_MAX then
        hoveredX, hoveredY = nil, nil
    end

    local resignButton = Layout.getResignButton(boardLayout.boardX, boardLayout.boardY, boardLayout.boardSize)
    hoveredButton = Layout.hit(x, y, resignButton.x, resignButton.y, resignButton.w, resignButton.h) and "resign" or nil
end

function Game.handleClick(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boardLayout = Layout.getBoard(windowWidth, windowHeight)

    -- Resign button
    local resignButton = Layout.getResignButton(boardLayout.boardX, boardLayout.boardY, boardLayout.boardSize)
    if Layout.hit(x, y, resignButton.x, resignButton.y, resignButton.w, resignButton.h) then
        Audio.play("buttonClick")
        local popupConfig = Popups.resignConfirm()
        popupConfig.onButton = function(label)
            Audio.play("buttonClick")
            Popup.hide()
            if label == "Yes, Resign" and onTransition then
                onTransition("menu")
            end
        end
        hoveredButton = nil
        Popup.show(popupConfig)
        return
    end

    -- Board click
    local clickedRow = math.floor((y - boardLayout.boardY) / boardLayout.squareSize) + 1
    local clickedCol = math.floor((x - boardLayout.boardX) / boardLayout.squareSize) + 1

    if clickedRow >= Chess.BOARD_MIN and clickedRow <= Chess.BOARD_MAX and clickedCol >= Chess.BOARD_MIN and clickedCol <= Chess.BOARD_MAX then
        if selectedPiece then
            if isValidMove(clickedRow, clickedCol) then
                local fromRow, fromCol = selectedX, selectedY
                selectedPiece        = nil
                selectedX, selectedY = nil, nil
                validMoves           = {}

                local result = Chess.executeMove(pieces, enPassantTarget, fromRow, fromCol, clickedRow, clickedCol, castlingRights)
                latestMove      = result.notation
                enPassantTarget = result.newEnPassantTarget
                castlingRights  = result.newCastlingRights or castlingRights

                if result.captured ~= "" then
                    Audio.play("pieceTaken")
                else
                    Audio.play("pieceMoved")
                end

                if result.isPromotion then
                    local promotionRow, promotionCol = clickedRow, clickedCol
                    local popupConfig = Popups.pawnPromotion(currentPlayer, pieceImages)
                    popupConfig.onPick = function(value)
                        Audio.play("buttonClick")
                        Chess.applyPromotion(pieces, promotionRow, promotionCol, value)
                        Popup.hide()
                        switchPlayer()
                    end
                    hoveredButton = nil
                    Popup.show(popupConfig)
                else
                    switchPlayer()
                end

            elseif selectedX == clickedRow and selectedY == clickedCol then
                selectedPiece        = nil
                selectedX, selectedY = nil, nil
                validMoves           = {}

            elseif pieces[clickedRow][clickedCol] ~= "" and Chess.getPieceColour(pieces[clickedRow][clickedCol]) == currentPlayer then
                selectedPiece        = pieces[clickedRow][clickedCol]
                selectedX, selectedY = clickedRow, clickedCol
                validMoves           = Chess.getValidMoves(pieces, enPassantTarget, clickedRow, clickedCol, castlingRights)

            else
                selectedPiece        = nil
                selectedX, selectedY = nil, nil
                validMoves           = {}
            end

        elseif pieces[clickedRow][clickedCol] ~= "" and Chess.getPieceColour(pieces[clickedRow][clickedCol]) == currentPlayer then
            selectedPiece        = pieces[clickedRow][clickedCol]
            selectedX, selectedY = clickedRow, clickedCol
            validMoves           = Chess.getValidMoves(pieces, enPassantTarget, clickedRow, clickedCol, castlingRights)

        else
            selectedPiece        = nil
            selectedX, selectedY = nil, nil
            validMoves           = {}
        end
    end
end

return Game
