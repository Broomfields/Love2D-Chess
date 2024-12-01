local StateMachine = {}

function StateMachine.new()
    local self = {
        states = {},
        current = nil
    }
    
    function self:register(name, state, ...)
        if type(state) == "table" and state.init then
            state:init(...)
        end
        self.states[name] = state
    end
    
    function self:switch(name, ...)
        if self.current and self.states[self.current].exit then
            self.states[self.current]:exit()
        end
        self.current = name
        if self.states[name] and self.states[name].enter then
            self.states[name]:enter(...)
        end
    end
    
    function self:update(dt)
        if self.current and self.states[self.current].update then
            self.states[self.current]:update(dt)
        end
    end
    
    function self:draw()
        if self.current and self.states[self.current].draw then
            self.states[self.current]:draw()
        end
    end
    
    function self:mousepressed(x, y, button)
        if self.current and self.states[self.current].mousepressed then
            self.states[self.current]:mousepressed(x, y, button)
        end
    end
    
    function self:keypressed(key)
        if self.current and self.states[self.current].keypressed then
            self.states[self.current]:keypressed(key)
        end
    end
    
    return self
end

return StateMachine