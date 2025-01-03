local gameState = "menu"
local hoveredButton = nil

function love.load()
    love.window.setTitle("Basic Chess Game")
    love.window.setMode(800, 800, {resizable = true, minwidth = 400, minheight = 400})
    initialiseGame()
end

function initialiseGame()
    board = {}
    for i = 1, 8 do
        board[i] = {}
        for j = 1, 8 do
            board[i][j] = {piece = nil, colour = (i + j) % 2 == 0 and {1, 1, 1} or {0, 0, 0}}
        end
    end
    whiteColour = {1, 1, 1}
    blackColour = {0, 0, 0}
    backgroundColour = {0, 0, 0}
    borderColour = {0, 0, 0}
    function hexToRgb(hex)
        hex = hex:gsub("#", "")
        return {tonumber("0x" .. hex:sub(1, 2)) / 255, tonumber("0x" .. hex:sub(3, 4)) / 255, tonumber("0x" .. hex:sub(5, 6)) / 255}
    end
    selectedPiece = nil
    selectedX, selectedY = nil, nil
    hoveredX, hoveredY = nil, nil
    currentPlayer = "white"
    validMoves = {}

    borderSize = 40
    uiHeight = borderSize * 2
    pieceMovedSound = love.audio.newSource("assets/sounds/pieceMoved.ogg", "static")
    pieceTakenSound = love.audio.newSource("assets/sounds/pieceTaken.ogg", "static")
    buttonClickSound = love.audio.newSource("assets/sounds/buttonClick.ogg", "static")
    regularFont = love.graphics.newFont("assets/fonts/OpenDyslexic-Regular.otf", 14)
    boldFont = love.graphics.newFont("assets/fonts/OpenDyslexic-Bold.otf", 14)
    gameStartTime = love.timer.getTime()
    turnStartTime = love.timer.getTime()
    latestMove = ""
    inCheck = false

    -- Example of changing colours using hex codes
    whiteColour = hexToRgb("#EBECD3")
    blackColour = hexToRgb("#7D945D")
    backgroundColour = hexToRgb("#B4C098")
    borderColour = hexToRgb("#453643")

    for i = 1, 8 do
        for j = 1, 8 do
            board[i][j].colour = (i + j) % 2 == 0 and whiteColour or blackColour
        end
    end

    pieceImages = {
        white_pawn = love.graphics.newImage("assets/images/white_pawn.png"),
        white_rook = love.graphics.newImage("assets/images/white_rook.png"),
        white_knight = love.graphics.newImage("assets/images/white_knight.png"),
        white_bishop = love.graphics.newImage("assets/images/white_bishop.png"),
        white_queen = love.graphics.newImage("assets/images/white_queen.png"),
        white_king = love.graphics.newImage("assets/images/white_king.png"),
        black_pawn = love.graphics.newImage("assets/images/black_pawn.png"),
        black_rook = love.graphics.newImage("assets/images/black_rook.png"),
        black_knight = love.graphics.newImage("assets/images/black_knight.png"),
        black_bishop = love.graphics.newImage("assets/images/black_bishop.png"),
        black_queen = love.graphics.newImage("assets/images/black_queen.png"),
        black_king = love.graphics.newImage("assets/images/black_king.png")
    }

    pieces = {
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

function love.draw()
    if gameState == "menu" then
        drawMenu()
    elseif gameState == "playing" then
        drawGame()
    elseif gameState == "options" then
        drawOptions()
    end
end

function drawMenu()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    love.graphics.clear(backgroundColour)
    love.graphics.setFont(boldFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Basic Chess Game", 0, windowHeight / 4, windowWidth, "center")

    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = (windowWidth - buttonWidth) / 2

    -- Play Game button
    local playButtonY = windowHeight / 2 - buttonHeight - 10
    if hoveredButton == "play" then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.2, 0.6, 0.2)
    end
    love.graphics.rectangle("fill", buttonX, playButtonY, buttonWidth, buttonHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Play Game", buttonX, playButtonY + 15, buttonWidth, "center")

    -- Options button
    local optionsButtonY = windowHeight / 2
    if hoveredButton == "options" then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.2, 0.6, 0.2)
    end
    love.graphics.rectangle("fill", buttonX, optionsButtonY, buttonWidth, buttonHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Options", buttonX, optionsButtonY + 15, buttonWidth, "center")

    -- Exit button
    local exitButtonY = windowHeight / 2 + buttonHeight + 10
    if hoveredButton == "exit" then
        love.graphics.setColor(0.9, 0.2, 0.2)
    else
        love.graphics.setColor(0.8, 0.1, 0.1)
    end
    love.graphics.rectangle("fill", buttonX, exitButtonY, buttonWidth, buttonHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Exit", buttonX, exitButtonY + 15, buttonWidth, "center")
end

function drawOptions()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    love.graphics.clear(backgroundColour)
    love.graphics.setFont(boldFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Options", 0, windowHeight / 4, windowWidth, "center")
    love.graphics.setFont(regularFont)
    love.graphics.printf("To Do", 0, windowHeight / 2, windowWidth, "center")

    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = (windowWidth - buttonWidth) / 2

    -- Return button
    local returnButtonY = windowHeight / 2 + buttonHeight + 10
    if hoveredButton == "return" then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.2, 0.6, 0.2)
    end
    love.graphics.rectangle("fill", buttonX, returnButtonY, buttonWidth, buttonHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Return", buttonX, returnButtonY + 15, buttonWidth, "center")
end

function drawGame()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local squareSize = math.min((windowHeight - 2 * borderSize - 2 * uiHeight) / 8, (windowWidth - 2 * borderSize) / 8)
    local boardSize = squareSize * 8
    local boardX = (windowWidth - boardSize) / 2
    local boardY = (windowHeight - boardSize) / 2 + uiHeight / 2

    -- Set background colour to Poker green
    love.graphics.clear(backgroundColour)

    -- Draw the board
    drawBoard(boardX, boardY, squareSize, boardSize)

    -- Draw UI elements
    drawUI(boardX, boardY, boardSize)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if gameState == "menu" then
            handleMenuClick(x, y)
        elseif gameState == "playing" then
            handleGameClick(x, y)
        elseif gameState == "options" then
            handleOptionsClick(x, y)
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if gameState == "menu" then
        handleMenuHover(x, y)
    elseif gameState == "playing" then
        handleGameHover(x, y)
    elseif gameState == "options" then
        handleOptionsHover(x, y)
    end
end

function handleMenuHover(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = (windowWidth - buttonWidth) / 2

    -- Play Game button
    local playButtonY = windowHeight / 2 - buttonHeight - 10
    if x >= buttonX and x <= buttonX + buttonWidth and y >= playButtonY and y <= playButtonY + buttonHeight then
        hoveredButton = "play"
        return
    end

    -- Options button
    local optionsButtonY = windowHeight / 2
    if x >= buttonX and x <= buttonX + buttonWidth and y >= optionsButtonY and y <= optionsButtonY + buttonHeight then
        hoveredButton = "options"
        return
    end

    -- Exit button
    local exitButtonY = windowHeight / 2 + buttonHeight + 10
    if x >= buttonX and x <= buttonX + buttonWidth and y >= exitButtonY and y <= exitButtonY + buttonHeight then
        hoveredButton = "exit"
        return
    end

    hoveredButton = nil
end

function handleOptionsHover(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = (windowWidth - buttonWidth) / 2

    -- Return button
    local returnButtonY = windowHeight / 2 + buttonHeight + 10
    if x >= buttonX and x <= buttonX + buttonWidth and y >= returnButtonY and y <= returnButtonY + buttonHeight then
        hoveredButton = "return"
        return
    end

    hoveredButton = nil
end

function handleGameHover(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local squareSize = math.min((windowHeight - 2 * borderSize - 2 * uiHeight) / 8, (windowWidth - 2 * borderSize) / 8)
    local boardSize = squareSize * 8
    local boardX = (windowWidth - boardSize) / 2
    local boardY = (windowHeight - boardSize) / 2 + uiHeight / 2

    hoveredX = math.floor((y - boardY) / squareSize) + 1
    hoveredY = math.floor((x - boardX) / squareSize) + 1

    if hoveredX < 1 or hoveredX > 8 or hoveredY < 1 or hoveredY > 8 then
        hoveredX, hoveredY = nil, nil
    end

    -- Check if the resign button is hovered
    local resignButtonWidth = 100
    local resignButtonX = boardX + boardSize - resignButtonWidth
    local resignButtonY = boardY + boardSize + borderSize / 2 + 30
    if x >= resignButtonX and x <= resignButtonX + resignButtonWidth and y >= resignButtonY and y <= resignButtonY + 30 then
        hoveredButton = "resign"
    else
        hoveredButton = nil
    end
end

function handleMenuClick(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = (windowWidth - buttonWidth) / 2
    -- Play Game button
    local playButtonY = windowHeight / 2 - buttonHeight - 10
    if x >= buttonX and x <= buttonX + buttonWidth and y >= playButtonY and y <= playButtonY + buttonHeight then
        -- Play Button Click Sound
        buttonClickSound:setPitch(math.random(8, 32) / 16) -- Randomly shift pitch by an octave or two
        love.audio.play(buttonClickSound)

        initialiseGame()
        gameState = "playing"
    end

    -- Options button
    local optionsButtonY = windowHeight / 2
    if x >= buttonX and x <= buttonX + buttonWidth and y >= optionsButtonY and y <= optionsButtonY + buttonHeight then
        -- Play Button Click Sound
        buttonClickSound:setPitch(math.random(8, 32) / 16) -- Randomly shift pitch by an octave or two
        love.audio.play(buttonClickSound)

        gameState = "options"
    end

    -- Exit button
    local exitButtonY = windowHeight / 2 + buttonHeight + 10
    if x >= buttonX and x <= buttonX + buttonWidth and y >= exitButtonY and y <= exitButtonY + buttonHeight then
        -- Play Button Click Sound
        buttonClickSound:setPitch(math.random(8, 32) / 16) -- Randomly shift pitch by an octave or two
        love.audio.play(buttonClickSound)
        
        love.event.quit()
    end
end

function handleOptionsClick(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = (windowWidth - buttonWidth) / 2

    -- Return button
    local returnButtonY = windowHeight / 2 + buttonHeight + 10
    if x >= buttonX and x <= buttonX + buttonWidth and y >= returnButtonY and y <= returnButtonY + buttonHeight then
        -- Play Button Click Sound
        buttonClickSound:setPitch(math.random(8, 32) / 16) -- Randomly shift pitch by an octave or two
        love.audio.play(buttonClickSound)
        
        gameState = "menu"
    end
end

function handleGameClick(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local squareSize = math.min((windowHeight - 2 * borderSize - 2 * uiHeight) / 8, (windowWidth - 2 * borderSize) / 8)
    local boardSize = squareSize * 8
    local boardX = (windowWidth - boardSize) / 2
    local boardY = (windowHeight - boardSize) / 2 + uiHeight / 2

    local i = math.floor((y - boardY) / squareSize) + 1
    local j = math.floor((x - boardX) / squareSize) + 1

    -- Check if the resign button is clicked
    local resignButtonWidth = 100
    local resignButtonX = boardX + boardSize - resignButtonWidth
    local resignButtonY = boardY + boardSize + borderSize / 2 + 30
    if x >= resignButtonX and x <= resignButtonX + resignButtonWidth and y >= resignButtonY and y <= resignButtonY + 30 then
        -- Play Button Click Sound
        buttonClickSound:setPitch(math.random(8, 32) / 16) -- Randomly shift pitch by an octave or two
        love.audio.play(buttonClickSound)

        gameState = "menu"
        return
    end

    if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
        if selectedPiece then
            if isValidMove(i, j) then
                local targetPiece = pieces[i][j]
                pieces[i][j] = selectedPiece
                pieces[selectedX][selectedY] = ""                        
                selectedPiece = nil
                selectedX, selectedY = nil, nil
                validMoves = {}
                if targetPiece ~= "" then
                    latestMove = pieces[i][j] .. " takes " .. string.char(96 + j):upper() .. tostring(9 - i)
                    pieceTakenSound:setPitch(math.random(8, 32) / 16) -- Randomly shift pitch by an octave or two
                    love.audio.play(pieceTakenSound)
                else
                    latestMove = pieces[i][j] .. " to " .. string.char(96 + j):upper() .. tostring(9 - i)
                    pieceMovedSound:setPitch(math.random(8, 32) / 16) -- Randomly shift pitch by an octave or two
                    love.audio.play(pieceMovedSound)
                end
                switchPlayer()
            elseif selectedX == i and selectedY == j then
                selectedPiece = nil
                selectedX, selectedY = nil, nil
                validMoves = {}
            elseif pieces[i][j] ~= "" and getPieceColour(pieces[i][j]) == currentPlayer then
                selectedPiece = pieces[i][j]
                selectedX, selectedY = i, j
                validMoves = getValidMoves(i, j)
            else
                selectedPiece = nil
                selectedX, selectedY = nil, nil
                validMoves = {}
            end
        elseif pieces[i][j] ~= "" and getPieceColour(pieces[i][j]) == currentPlayer then
            selectedPiece = pieces[i][j]
            selectedX, selectedY = i, j
            validMoves = getValidMoves(i, j)
        else
            selectedPiece = nil
            selectedX, selectedY = nil, nil
            validMoves = {}
        end
    end
end

function drawBoard(boardX, boardY, squareSize, boardSize)
    local borderWidth = 5
    local cornerLength = 20

    -- Draw oak border around the board
    love.graphics.setColor(borderColour)
    love.graphics.rectangle("fill", boardX - borderSize, boardY - borderSize, boardSize + 2 * borderSize, boardSize + 2 * borderSize)

    -- Draw chess notation coordinates
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(regularFont)
    for i = 1, 8 do
        local letter = string.char(96 + i):upper()
        local number = tostring(9 - i)
        love.graphics.print(letter, boardX + (i - 1) * squareSize + squareSize / 2, boardY - borderSize / 2, 0, 1, 1, 6, 6)
        love.graphics.print(letter, boardX + (i - 1) * squareSize + squareSize / 2, boardY + boardSize + borderSize / 2, 0, 1, 1, 6, 6)
        love.graphics.print(number, boardX - borderSize / 2, boardY + (i - 1) * squareSize + squareSize / 2, 0, 1, 1, 6, 6)
        love.graphics.print(number, boardX + boardSize + borderSize / 2, boardY + (i - 1) * squareSize + squareSize / 2, 0, 1, 1, 6, 6)
    end

    for i = 1, 8 do
        for j = 1, 8 do
            love.graphics.setColor(board[i][j].colour)
            love.graphics.rectangle("fill", boardX + (j - 1) * squareSize, boardY + (i - 1) * squareSize, squareSize, squareSize)
            if pieces[i][j] ~= "" then
                local pieceImage = pieceImages[pieces[i][j]]
                local pieceWidth = pieceImage:getWidth()
                local pieceHeight = pieceImage:getHeight()
                local scale = 0.9 * squareSize / math.max(pieceWidth, pieceHeight)
                local offsetX = (squareSize - pieceWidth * scale) / 2
                local offsetY = (squareSize - pieceHeight * scale) / 2
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(pieceImage, boardX + (j - 1) * squareSize + offsetX, boardY + (i - 1) * squareSize + offsetY, 0, scale, scale)
            end
        end
    end

    if hoveredX and hoveredY then
        love.graphics.setColor(1, 0.5, 0, 0.5) -- Translucent orange
        love.graphics.rectangle("fill", boardX + (hoveredY - 1) * squareSize, boardY + (hoveredX - 1) * squareSize, squareSize, squareSize)
    end

    if selectedX and selectedY then
        love.graphics.setColor(0, 0.75, 1) -- Sky blue
        love.graphics.setLineWidth(borderWidth)
        love.graphics.rectangle("line", boardX + (selectedY - 1) * squareSize + borderWidth / 2, boardY + (selectedX - 1) * squareSize + borderWidth / 2, squareSize - borderWidth, squareSize - borderWidth)
    end

    if inCheck then
        local kingX, kingY
        for i = 1, 8 do
            for j = 1, 8 do
                if pieces[i][j] == currentPlayer .. "_king" then
                    kingX, kingY = i, j
                    break
                end
            end
        end
        if kingX and kingY then
            love.graphics.setColor(1, 0, 0) -- Red
            love.graphics.setLineWidth(borderWidth)
            love.graphics.rectangle("line", boardX + (kingY - 1) * squareSize + borderWidth / 2, boardY + (kingX - 1) * squareSize + borderWidth / 2, squareSize - borderWidth, squareSize - borderWidth)
        end
    end

    for _, move in ipairs(validMoves) do
        local targetPiece = pieces[move[1]][move[2]]
        if targetPiece ~= "" and getPieceColour(targetPiece) ~= currentPlayer then
            love.graphics.setColor(1, 0, 0) -- Red
        else
            love.graphics.setColor(1, 0.75, 0) -- Amber
        end
        love.graphics.setLineWidth(borderWidth)
        drawCornerLines(boardX + (move[2] - 1) * squareSize + borderWidth / 2, boardY + (move[1] - 1) * squareSize + borderWidth / 2, squareSize - borderWidth, borderWidth, cornerLength)
    end
end

function drawUI(boardX, boardY, boardSize)
    -- Draw current player
    love.graphics.setFont(regularFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Current Player: ", boardX, boardY - (uiHeight + 20))
    love.graphics.print(currentPlayer, boardX, boardY - uiHeight + 10)
    
    -- Draw Latest Move
    love.graphics.setFont(regularFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Latest Move: ", boardX + 200, boardY - (uiHeight + 20))
    love.graphics.print(latestMove, boardX + 200, boardY - uiHeight + 10)
    if inCheck then
        love.graphics.setFont(boldFont)
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("CHECK", boardX, boardY - uiHeight + 10, boardSize, "center")
    end

    -- Draw resign button
    local resignButtonWidth = 100
    local resignButtonX = boardX + boardSize - resignButtonWidth
    local resignButtonY = boardY + boardSize + borderSize / 2 + 30
    if hoveredButton == "resign" then
        love.graphics.setColor(0.9, 0.2, 0.2)
    else
        love.graphics.setColor(0.8, 0.1, 0.1)
    end
    love.graphics.rectangle("fill", resignButtonX, resignButtonY, resignButtonWidth, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Resign", resignButtonX, resignButtonY + 7, resignButtonWidth, "center")

    -- Draw game time and turn time
    love.graphics.setFont(regularFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Game Time: " .. string.format("%.2f", love.timer.getTime() - gameStartTime), boardX, boardY + boardSize + borderSize / 2 + 30)
    love.graphics.print("Turn Time: " .. string.format("%.2f", love.timer.getTime() - turnStartTime), boardX + 200, boardY + boardSize + borderSize / 2 + 30)
end

function drawCornerLines(x, y, size, width, length)
    love.graphics.line(x, y, x + length, y) -- Top-left horizontal
    love.graphics.line(x, y, x, y + length) -- Top-left vertical
    love.graphics.line(x + size, y, x + size - length, y) -- Top-right horizontal
    love.graphics.line(x + size, y, x + size, y + length) -- Top-right vertical
    love.graphics.line(x, y + size, x + length, y + size) -- Bottom-left horizontal
    love.graphics.line(x, y + size, x, y + size - length) -- Bottom-left vertical
    love.graphics.line(x + size, y + size, x + size - length, y + size) -- Bottom-right horizontal
    love.graphics.line(x + size, y + size, x + size, y + size - length) -- Bottom-right vertical
end

function getPieceColour(piece)
    return piece:match("^white") and "white" or "black"
end

function switchPlayer()
    currentPlayer = currentPlayer == "white" and "black" or "white"
    turnStartTime = love.timer.getTime()
    inCheck = isKingInCheck(currentPlayer)
end

function isValidMove(i, j)
    for _, move in ipairs(validMoves) do
        if move[1] == i and move[2] == j then
            return true
        end
    end
    return false
end

function getValidMoves(x, y)
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

    -- En passant (not fully implemented, needs additional logic to track Latest Move)
    -- if enPassantCondition then
    --     addMoveIfValid(x + direction, enPassantColumn)
    -- end

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

    -- Horizontal and vertical moves
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

    -- L-shaped moves
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

    -- Diagonal moves
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

    -- Combine rook and bishop moves
    local rookMoves = getRookMoves(x, y, pieceColour)
    local bishopMoves = getBishopMoves(x, y, pieceColour)

    for _, move in ipairs(rookMoves) do
        table.insert(moves, move)
    end
    for _, move in ipairs(bishopMoves) do
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

    -- One-square moves in any direction
    local kingMoves = {
        {x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1},
        {x + 1, y + 1}, {x + 1, y - 1}, {x - 1, y + 1}, {x - 1, y - 1}
    }
    for _, move in ipairs(kingMoves) do
        addMoveIfValid(move[1], move[2])
    end

    -- Castling (not fully implemented, needs additional logic to track rook and king moves)
    -- if castlingCondition then
    --     addMoveIfValid(castlingRow, castlingColumn)
    -- end

    return moves
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
                local moves = getValidMoves(i, j)
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