local Popups = {}

function Popups.gameOver(resultText, isCheckmate)
    return {
        type = "message",
        width = 320,
        height = 180,
        title = isCheckmate and "Checkmate!" or "Stalemate",
        message = resultText,
        messageColour = isCheckmate and {1, 0.25, 0.25} or {0.85, 0.85, 0.85},
        buttons = {
            {label = "Main Menu"},
        },
    }
end

function Popups.resignConfirm()
    return {
        type = "message",
        width = 320,
        height = 180,
        title = "Resign",
        message = "Are you sure you want to resign?",
        messageColour = {1, 1, 1},
        buttons = {
            {label = "Yes, Resign", style = "danger"},
            {label = "Cancel"},
        },
    }
end

function Popups.pawnPromotion(colour, pieceImages)
    return {
        type = "picker",
        width = 360,
        height = 150,
        title = "Promote Pawn",
        items = {
            {image = pieceImages[colour .. "_queen"],  value = colour .. "_queen"},
            {image = pieceImages[colour .. "_rook"],   value = colour .. "_rook"},
            {image = pieceImages[colour .. "_bishop"], value = colour .. "_bishop"},
            {image = pieceImages[colour .. "_knight"], value = colour .. "_knight"},
        },
    }
end

return Popups
