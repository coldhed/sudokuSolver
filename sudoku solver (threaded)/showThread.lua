local map = ...
require 'love.timer'
soc = require('socket')
timer = 0
speeds = {
    ['slow'] = 0.30,
    ['default'] = 0.15,
    ['fast'] = 0.00001,
}
speed = 'default'
currentSpeed = speeds[speed]



function copyTable(original)
    copy = {}
    for i=1, #original do
        table.insert(copy, original[i])
    end
    return copy
end

function solve()

    -- check if the initial position is valid
    for i=1, #map do
        if map[i] ~= 0 then
            if not followsRules(i, map[i], map) then
                solution = nil
                return
            end
        end
    end

    elimination()


    -- may not have a solution
    if solution == nil then return end

    search(solution, 1)
end


-- Constraint Propagation
function elimination()

    -- create all possibilities from solution
    possibilities = {}
    for i=1, #solution do
        if solution[i] == 0 then -- the square is empty
            local_possibilities = {0}

            -- create possibilities
            for j=1, 9 do
                if followsRules(i, j, map) then
                    table.insert(local_possibilities, j)
                end
            end

            -- if a square is empty there is no possible solution
            if #local_possibilities == 1 then -- remember we are including the 0
                solution = nil
                return
            end

            table.insert(possibilities, local_possibilities)
        else
            table.insert(possibilities, {})
        end
    end
                    -- EMPTY POSSIBILITIES ARE NUMBERS FIXED IN THE SOLUTION
                        -- IF THERE IS ONLY A 0 THEN THE SOLUTION IS INCORRECT
    stuck = false
    while not stuck do
        -- iterate through the possibilities
        ::redo::
        for i=1, #solution do
            -- check for empty boxes
            if #possibilities[i] == 1 then
                solution = nil
                return

            -- set in solution all squares which only have one possibility
            elseif #possibilities[i] == 2 then
                solution[i] = possibilities[i][2]

                communicate(i)

                --function that removes the number, from a certain quadrant
                possibilities = removeQuadrant_f(possibilities[i][2], quadrant_f(i), possibilities)

                -- remove the number from x, y
                possibilities = removeXY(possibilities[i][2], i, possibilities)

                possibilities[i] = {}
                goto redo
            end
        end
        -- if the sudoku remains the same there are no more solutions ( reaching this point )
        stuck = true
    end
    return
end

-- Depth First Search
function search(map, i)
    -- base case
    if i > #map then
        solution = copyTable(map)
        return true

    -- iteration cases
    elseif map[i] ~= 0 then
        if search(map, (i+1)) then
            return true
        end
    else
        for j=2, #possibilities[i] do
            if followsRules(i, possibilities[i][j], map) then
                map[i] = possibilities[i][j]
                
                communicate(i, map)

                if search(map, (i+1)) then
                    return true
                end
            end
        end
        map[i] = 0

        communicate(i, map)
    end
    return false
end

function communicate(i, searchMap)
    local currentMap = searchMap or solution
    updateSpeed()

    love.thread.getChannel('showThreadMap'):supply({copyTable(currentMap), i}) -- send the updated solution

    if speed ~= 'fast' then
        soc.sleep(currentSpeed)
    end
end

function updateSpeed()
    local speed_test = love.thread.getChannel('speed'):pop()

    if speed_test then
        currentSpeed = speeds[speed_test]
    end
end

-- used for possible solutions
function isComplete(table)
    for i=1, #map do
        if map[i] == 0 then
            return false
        end
    end
    return true
end

function placeToGrid(i)
    y = math.ceil(i / 9)
    x = i - ((y - 1) * 9)
    return {x, y}
end

function gridToPlace(x, y)
    return (((y - 1) * 9) + x)
end


-- function to return the quadrant a square is in from the x, y position:
    --      1  |  2  |  3
    --      4  |  5  |  6
    --      7  |  8  |  9
function quadrant_f(i)
    x_y = placeToGrid(i)
    x = x_y[1]
    y = x_y[2]
    y_quadrant = math.ceil(y / 3)
    x_quadrant = math.ceil(x / 3)

    return x_quadrant + ((y_quadrant - 1) * 3)
end

function followsRules(position, number, map)
            -- check if number is in quadrant
    quadrant = quadrant_f(position)

    -- transform the quadrant index into cartesian quadrant positions
    y = math.ceil(quadrant / 3)
    x = quadrant - (y - 1) * 3

    -- transform the quadrant cartestian positions into the 9x9 grid cartesian positions
    y = (y * 3) - 2
    x = (x * 3) - 2

    for y_count=y, (y + 2) do
        for x_count=x, (x + 2) do
            local index = gridToPlace(x_count, y_count)
            if map[index] == number and index ~= position then
                return false
            end
        end
    end

    x_y = placeToGrid(position)
    x = x_y[1]
    y = x_y[2]

    -- check x
    for x_count=1, 9 do
        if map[gridToPlace(x_count, y)] == number and x_count ~= x then
            return false
        end
    end

    -- check y
    for y_count=1, 9 do
        if map[gridToPlace(x, y_count)] == number and y_count ~= y then
            return false
        end
    end

    return true
end

-- removes number from from possibilities in a certain quadrant
function removeQuadrant_f(number, quadrant, possibilities)
    y = math.ceil(quadrant / 3)
    x = quadrant - (y - 1) * 3

    -- transform the quadrant cartestian positions into the 9x9 grid cartesian positions
    y = (y * 3) - 2
    x = (x * 3) - 2

    for y_count=y, (y + 2) do
        for x_count=x, (x + 2) do
            i = gridToPlace(x_count, y_count)
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
function removeXY(number, position, possibilities)

    x_y = placeToGrid(position)
    x = x_y[1]
    y = x_y[2]
    -- remove x
    for x_count=1, 9 do
        i = gridToPlace(x_count, y)
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
        i = gridToPlace(x, y_count)
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


--- BODY OF THREAD -----------------
timer = 0
solution = copyTable(map)
solve()

love.thread.getChannel('showThreadMap'):supply({solution, 0})
love.thread.getChannel('showThreadStatus'):supply('finished')