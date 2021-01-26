ColorTheme = Class{}

function ColorTheme:init(params)
    self.background = params.background
    self.thick = params.thick
    self.thin = params.thin
    self.highlight = {}
    
    -- fill highlight
    for i=1, 3 do
        self.highlight[i] = self.background[i] - 30
    end
end

function ColorTheme:setBackground()
    love.graphics.setBackgroundColor(self.background[1] / 255, self.background[2] / 255, self.background[3] / 255)
end

function ColorTheme:setThick()
    love.graphics.setColor(self.thick[1] / 255, self.thick[2] / 255, self.thick[3] / 255)
    love.graphics.setLineWidth(4)
end

function ColorTheme:setThin()
    love.graphics.setColor(self.thin[1] / 255, self.thin[2] / 255, self.thin[3] / 255)
    love.graphics.setLineWidth(2)
end

function ColorTheme:setHighlight()
    love.graphics.setColor(self.highlight[1] / 255, self.highlight[2] / 255, self.highlight[3] / 255)
end