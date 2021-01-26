Button = Class {}

function Button:init(x, y, align, text, font, limit)
    self.x = x
    self.y = y
    self.align = align
    self.text = text
    self.font = font
    self.limit = limit

    self.height = self.font:getHeight(self.text)
    self.width = self.font:getWidth(self.text)

    self.cushion = 10

    if align == 'right' then
        self.x = self.limit - self.width - self.cushion
    elseif align == 'center' then
        self.x = (self.limit / 2) - (self.width / 2)
    else -- align == 'left'
        self.x = self.cushion
    end

    self.limit = self.width
end

function Button:is_pressed(x, y)
    return (x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height)
end

function Button:get_position()
    return {self.x, self.y}
end