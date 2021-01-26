Solver = Class{}

function Solver:init(map)
    if map ~= nil then 
        self.map = self:copyTable(map)
        self.solution = self:copyTable(map)
        self.timer = 0

        self.showIndex = 0
        self.showThreadMap = self:copyTable(map)
        self.searcherThreadStatus = 'notCalled'
        self.showThreadStatus = 'notCalled'
    end
end

function Solver:set_map(map)
    self.map = map
end

function Solver:copyTable(original)
    copy = {}
    for i=1, #original do
        table.insert(copy, original[i])
    end
    return copy
end

function Solver:solveSingle()
    self.timer = love.timer.getTime()

    -- check if the initial position is valid
    for i=1, #self.map do
        if self.map[i] ~= 0 then
            if not self:followsRules(i, self.map[i], self.map) then
                self.solution = nil
                return
            end
        end
    end

    self:elimination()

    -- store solution how it is to send to the searcherThread to make it faster
    self.afterEliminationMap = self:copyTable(self.solution)

    -- may not have a solution
    if self.solution == nil then return end

    if not self:search(self:copyTable(self.solution), 1) then self.solution = nil end

    -- if self.n_solutions == 0 then self.solution = nil end
    self.timer = love.timer.getTime() - self.timer
end

function Solver:solve()
    self.timer = love.timer.getTime()

    -- check if the initial position is valid
    for i=1, #self.map do
        if self.map[i] ~= 0 then
            if not self:followsRules(i, self.map[i], self.map) then
                self.solution = nil
                return
            end
        end
    end

    self:elimination()

    -- store solution how it is to send to the searcherThread to make it faster
    self.afterEliminationMap = self:copyTable(self.solution)

    -- may not have a solution
    if self.solution == nil then return end

    if not self:search(self:copyTable(self.solution), 1) then self.solution = nil end

    -- if self.n_solutions == 0 then self.solution = nil end
    self.timer = love.timer.getTime() - self.timer

    self:startSearcherThread(self.possibilities)
end


-- Constraint Propagation
function Solver:elimination()
    -- create all possibilities from self.solution
    self.possibilities = {}
    for i=1, #self.solution do
        if self.solution[i] == 0 then -- the square is empty
            local_possibilities = {0}

            -- create possibilities
            for j=1, 9 do
                if self:followsRules(i, j, self.map) then
                    table.insert(local_possibilities, j)
                end
            end

            -- if a square is empty there is no possible solution
            if #local_possibilities == 1 then -- remember we are including the 0
                self.solution = nil
                return
            end

            table.insert(self.possibilities, local_possibilities)
        else
            table.insert(self.possibilities, {})
        end
    end
                    -- EMPTY POSSIBILITIES ARE NUMBERS FIXED IN THE SOLUTION
                        -- IF THERE IS ONLY A 0 THEN THE SOLUTION IS INCORRECT
    stuck = false
    while not stuck do
        -- iterate through the possibilities
        ::redo::
        for i=1, #self.solution do
            -- check for empty boxes
            if #self.possibilities[i] == 1 then
                self.solution = nil
                return

            -- set in self.solution all squares which only have one possibility
            elseif #self.possibilities[i] == 2 then
                self.solution[i] = self.possibilities[i][2]

                --function that removes the number, from a certain quadrant
                self.possibilities = self:removeQuadrant(self.possibilities[i][2], self:quadrant(i), self.possibilities)

                -- remove the number from x, y
                self.possibilities = self:removeXY(self.possibilities[i][2], i, self.possibilities)

                self.possibilities[i] = {}
                goto redo
            end
        end
        -- if the sudoku remains the same there are no more solutions ( reaching this point )
        stuck = true
    end
    return
end

-- Depth First Search
function Solver:search(map, i)
    -- base case
    if i > #map then
        self.solution = self:copyTable(map)
        return true

    -- iteration cases
    elseif map[i] ~= 0 then
        if self:search(map, (i+1)) then
            return true
        end
    else
        for j=2, #self.possibilities[i] do
            if self:followsRules(i, self.possibilities[i][j], map) then
                map[i] = self.possibilities[i][j]
                if self:search(map, (i+1)) then
                    return true
                end
            end
        end
        map[i] = 0
    end
    return false
end

-- used for possible solutions
function Solver:isComplete(table)
    for i=1, #map do
        if map[i] == 0 then
            return false
        end
    end
    return true
end

function Solver:placeToGrid(i)
    y = math.ceil(i / 9)
    x = i - ((y - 1) * 9)
    return {x, y}
end

function Solver:gridToPlace(x, y)
    return (((y - 1) * 9) + x)
end


-- function to return the quadrant a square is in from the x, y position:
    --      1  |  2  |  3
    --      4  |  5  |  6
    --      7  |  8  |  9
function Solver:quadrant(i)
    x_y = self:placeToGrid(i)
    x = x_y[1]
    y = x_y[2]
    y_quadrant = math.ceil(y / 3)
    x_quadrant = math.ceil(x / 3)

    return x_quadrant + ((y_quadrant - 1) * 3)
end

function Solver:followsRules(position, number, map)
            -- check if number is in quadrant
    quadrant = self:quadrant(position)

    -- transform the quadrant index into cartesian quadrant positions
    y = math.ceil(quadrant / 3)
    x = quadrant - (y - 1) * 3

    -- transform the quadrant cartestian positions into the 9x9 grid cartesian positions
    y = (y * 3) - 2
    x = (x * 3) - 2

    for y_count=y, (y + 2) do
        for x_count=x, (x + 2) do
            local index = self:gridToPlace(x_count, y_count)
            if map[index] == number and index ~= position then
                return false
            end
        end
    end

    x_y = self:placeToGrid(position)
    x = x_y[1]
    y = x_y[2]

    -- check x
    for x_count=1, 9 do
        if map[self:gridToPlace(x_count, y)] == number and x_count ~= x then
            return false
        end
    end

    -- check y
    for y_count=1, 9 do
        if map[self:gridToPlace(x, y_count)] == number and y_count ~= y then
            return false
        end
    end

    return true
end

-- removes number from from possibilities in a certain quadrant
function Solver:removeQuadrant(number, quadrant, possibilities)
    y = math.ceil(quadrant / 3)
    x = quadrant - (y - 1) * 3

    -- transform the quadrant cartestian positions into the 9x9 grid cartesian positions
    y = (y * 3) - 2
    x = (x * 3) - 2

    for y_count=y, (y + 2) do
        for x_count=x, (x + 2) do
            i = self:gridToPlace(x_count, y_count)
            for p=1, #possibilities[i] do
                if possibilities[i][p] == number then
                    table.remove(possibilities[i], p)
                    goto continue
                end
            end
            ::continue::
        end
    end
    return possibilities
end

-- removes number based on a certain position from x, y lines in possibilities
function Solver:removeXY(number, position, possibilities)

    x_y = self:placeToGrid(position)
    x = x_y[1]
    y = x_y[2]
    -- remove x
    for x_count=1, 9 do
        i = self:gridToPlace(x_count, y)
        for p=1, #possibilities[i] do
            if possibilities[i][p] == number then
                table.remove(possibilities[i], p)
                goto continue_x
            end
            ::continue_x::
        end
    end

    -- remove y
    for y_count=1, 9 do
        i = self:gridToPlace(x, y_count)
        for p=1, #possibilities[i] do
            if possibilities[i][p] == number then
                table.remove(possibilities[i], p)
                goto continue_y
            end
            ::continue_y::
        end
    end

    return possibilities
end

function Solver:RandomPuzzle()
    ::restart::

    -- create a random - empty - map
    randomMap = {}
    indexes = {}
    for i=1, 81 do
        table.insert(randomMap, 0)

        -- list of numbers to remove from the sudoku at the end
        table.insert(indexes, i)
    end

    -- populate the table
    math.randomseed(os.time())
    for i=1, 1 do
        if math.random() < 1.2 then
            n = math.random(9)
            n = 1
            if self:followsRules(i, n, randomMap) then
                randomMap[i] = n
            end
        end
    end

    -- solve the puzzle
    local randomPuzzle = Solver(randomMap)
    randomPuzzle:solveSingle()
    if randomPuzzle.solution == nil then goto restart 
    else randomMap = randomPuzzle.solution end

    -- remove numbers from the puzzle
    for i=1, math.random(40, 46) do
        n = math.random(#indexes)
        random_index = indexes[n]
        randomMap[random_index] = 0
        table.remove(indexes, n)
    end

    self.map = randomMap
end

function Solver:startSearcherThread()
    self.solutions = {}
    -- send map, possibilities
    self.searcherThread = love.thread.newThread('searcherThread.lua')
    self.searcherThread:start(self.afterEliminationMap, self.possibilities)
    self.searcherThreadStatus = 'started'
end

function Solver:startShowThread(map)
    self:killThread()

    self.showThread = love.thread.newThread('showThread.lua')
    
    self.showThread:start(map)
    self.showThreadStatus = 'started'
end

function Solver:update()
    if self.searcherThreadStatus == 'started' then
        local newSolution = love.thread.getChannel('searcher_solutions'):pop()
        if newSolution then
            table.insert(self.solutions, newSolution)
        end

        local status = love.thread.getChannel('searcher_status'):pop()
        if status then
            self.searcherThreadStatus = 'finished'
        end
    elseif self.searcherThreadStatus == 'finished' then
        local newSolution = love.thread.getChannel('searcher_solutions'):pop()
        if newSolution then
            table.insert(self.solutions, newSolution)
        else
            self.searcherThreadStatus = 'complete'
        end
    end

    if self.showThreadStatus == 'started' then
        local message = love.thread.getChannel('showThreadMap'):pop()
        if message then
            self.showThreadMap = self:copyTable(message[1])
            self.showIndex = message[2]
        end

        local status2 = love.thread.getChannel('showThreadStatus'):pop()
        if status2 then
            self.showThreadStatus = 'finished'
        end

    elseif self.showThreadStatus == 'finished' then
        local map = love.thread.getChannel('showThreadMap'):pop()
        if map then
            self.showThreadMap = map
        else
            self.showThreadStatus = 'complete'
        end
    end
end

function Solver:searchSolutions(n, i)
    for j=1, #self.solutions do
        if self.solutions[j][i] == n then
            return true
        end
    end
    return false
end

function Solver:cleanSolutions(n, i)
    local j = 1
    while true do
        if j > #self.solutions then
            return
        elseif self.solutions[j][i] ~= n then
            table.remove(self.solutions, j)
        else
            j = j + 1
        end
    end
end

function Solver:killThread()
    love.thread.getChannel('kill'):push('kill')
    self.searcherThreadStatus = 'complete'
end