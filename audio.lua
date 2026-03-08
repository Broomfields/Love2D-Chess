local Audio   = {}
local sources = {}

local function randomPitch()
    return math.random(8, 32) / 16
end

-- Register a named sound source. Call during initialisation.
function Audio.load(name, path)
    sources[name] = love.audio.newSource(path, "static")
end

-- Play a named sound with a random pitch variation.
function Audio.play(name)
    local s = sources[name]
    if s then
        s:setPitch(randomPitch())
        love.audio.play(s)
    end
end

return Audio
