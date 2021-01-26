Wrong = Class{}
require 'math'

function Wrong:init(x, y, number)
    self.x = x
    self.y = y
    self.number = tostring(number)

    self.x_off = 18
    self.y_off = 6

    self.timer = 0
    self.move = 0.25 
    self.limit = self.move + 0.3

    self.amplitude = 3
end

-- return false to delete the object if time has expired
function Wrong:update(dt)
    self.timer = self.timer + dt
    if self.timer > self.limit then return false end

    if self.timer < self.move then
        self.x = self.x + self.amplitude * math.cos((math.pi * 2 / self.move) * self.timer)
    end
    return true
end

function Wrong:draw()
    love.graphics.print(self.number, self.x + self.x_off, self.y + self.y_off)
end