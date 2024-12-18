function love.load()
    love.window.setTitle("Basic Chess Game")
    love.window.setMode(800, 800, {resizable = true, minwidth = 400, minheight = 400})
    board = {}
    for i = 1, 8 do
        board[i] = {}
        for j = 1, 8 do
            board[i][j] = {piece = nil, color = (i + j) % 2 == 0 and {1, 1, 1} or {0, 0, 0}}
        end
    end
    whiteColor = {1, 1, 1}
    blackColor = {0, 0, 0}
    backgroundColor = {0, 0, 0}
    borderColor = {0, 0, 0}
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
    pieceTakenSound = love.audio.newSource("assets/sounds/pieceTaken1.ogg", "static")
    regularFont = love.graphics.newFont("assets/fonts/OpenDyslexic-Regular.otf", 14)
    boldFont = love.graphics.newFont("assets/fonts/OpenDyslexic-Bold.otf", 14)
    gameStartTime = love.timer.getTime()
    turnStartTime = love.timer.getTime()
    latestMove = ""
    inCheck = false

    function love.mousepressed(x, y, button)
        if button == 1 then
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
                love.event.quit()
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
                    elseif pieces[i][j] ~= "" and getPieceColor(pieces[i][j]) == currentPlayer then
                        selectedPiece = pieces[i][j]
                        selectedX, selectedY = i, j
                        validMoves = getValidMoves(i, j)
                    else
                        selectedPiece = nil
                        selectedX, selectedY = nil, nil
                        validMoves = {}
                    end
                elseif pieces[i][j] ~= "" and getPieceColor(pieces[i][j]) == currentPlayer then
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
    end

    function love.mousemoved(x, y, dx, dy)
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
    end

    -- Example of changing colors using hex codes
    whiteColor = hexToRgb("#EBECD3")
    blackColor = hexToRgb("#7D945D")
    backgroundColor = hexToRgb("#B4C098")
    borderColor = hexToRgb("#453643")

    for i = 1, 8 do
        for j = 1, 8 do
            board[i][j].color = (i + j) % 2 == 0 and whiteColor or blackColor
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
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local squareSize = math.min((windowHeight - 2 * borderSize - 2 * uiHeight) / 8, (windowWidth - 2 * borderSize) / 8)
    local boardSize = squareSize * 8
    local boardX = (windowWidth - boardSize) / 2
    local boardY = (windowHeight - boardSize) / 2 + uiHeight / 2

    -- Set background color to Poker green
    love.graphics.clear(backgroundColor)

    -- Draw the board
    drawBoard(boardX, boardY, squareSize, boardSize)

    -- Draw UI elements
    drawUI(boardX, boardY, boardSize)
end

function drawBoard(boardX, boardY, squareSize, boardSize)
    local borderWidth = 5
    local cornerLength = 20

    -- Draw oak border around the board
    love.graphics.setColor(borderColor)
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
            love.graphics.setColor(board[i][j].color)
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

    for _, move in ipairs(validMoves) do
        local targetPiece = pieces[move[1]][move[2]]
        if targetPiece ~= "" and getPieceColor(targetPiece) ~= currentPlayer then
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
    love.graphics.setColor(0.8, 0.1, 0.1)
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

function getPieceColor(piece)
    return piece:match("^white") and "white" or "black"
end

function switchPlayer()
    currentPlayer = currentPlayer == "white" and "black" or "white"
    turnStartTime = love.timer.getTime()
end

function isValidMove(i, j)
    for _, move in ipairs(validMoves) do
        if move[1] == i and move[2] == j then
            -- print("Valid move to (" .. i .. ", " .. j .. ")")
            return true
        end
    end
    -- print("Invalid move to (" .. i .. ", " .. j .. ")")
    return false
end

function getValidMoves(x, y)
    local piece = pieces[x][y]
    local pieceColor = getPieceColor(piece)
    local moves = {}

    if piece:match("pawn") then
        moves = getPawnMoves(x, y, pieceColor)
    elseif piece:match("rook") then
        moves = getRookMoves(x, y, pieceColor)
    elseif piece:match("knight") then
        moves = getKnightMoves(x, y, pieceColor)
    elseif piece:match("bishop") then
        moves = getBishopMoves(x, y, pieceColor)
    elseif piece:match("queen") then
        moves = getQueenMoves(x, y, pieceColor)
    elseif piece:match("king") then
        moves = getKingMoves(x, y, pieceColor)
    end

    -- Debug print to check valid moves
    -- print("Valid moves for piece at (" .. x .. ", " .. y .. "):")
    -- for _, move in ipairs(moves) do
    --     print("Move to (" .. move[1] .. ", " .. move[2] .. ")")
    -- end

    return moves
end

function getPawnMoves(x, y, pieceColor)
    local moves = {}
    local direction = pieceColor == "white" and -1 or 1
    local startRow = pieceColor == "white" and 7 or 2

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColor(pieces[i][j]) ~= pieceColor then
                table.insert(moves, {i, j})
            end
        end
    end

    -- Normal move
    if pieces[x + direction][y] == "" then
        addMoveIfValid(x + direction, y)
        -- Double move from start position
        if x == startRow and pieces[x + 2 * direction][y] == "" then
            addMoveIfValid(x + 2 * direction, y)
        end
    end

    -- Captures
    if y > 1 and pieces[x + direction][y - 1] ~= "" and getPieceColor(pieces[x + direction][y - 1]) ~= pieceColor then
        addMoveIfValid(x + direction, y - 1)
    end
    if y < 8 and pieces[x + direction][y + 1] ~= "" and getPieceColor(pieces[x + direction][y + 1]) ~= pieceColor then
        addMoveIfValid(x + direction, y + 1)
    end

    -- En passant (not fully implemented, needs additional logic to track Latest Move)
    -- if enPassantCondition then
    --     addMoveIfValid(x + direction, enPassantColumn)
    -- end

    return moves
end

function getRookMoves(x, y, pieceColor)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColor(pieces[i][j]) ~= pieceColor then
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

function getKnightMoves(x, y, pieceColor)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColor(pieces[i][j]) ~= pieceColor then
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

function getBishopMoves(x, y, pieceColor)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColor(pieces[i][j]) ~= pieceColor then
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

function getQueenMoves(x, y, pieceColor)
    local moves = {}

    -- Combine rook and bishop moves
    local rookMoves = getRookMoves(x, y, pieceColor)
    local bishopMoves = getBishopMoves(x, y, pieceColor)

    for _, move in ipairs(rookMoves) do
        table.insert(moves, move)
    end
    for _, move in ipairs(bishopMoves) do
        table.insert(moves, move)
    end

    return moves
end

function getKingMoves(x, y, pieceColor)
    local moves = {}

    local function addMoveIfValid(i, j)
        if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
            if pieces[i][j] == "" or getPieceColor(pieces[i][j]) ~= pieceColor then
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