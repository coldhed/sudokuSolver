local map, possibilities = ...


function copyTable(original)
    copy = {}
    for i=1, #original do
        table.insert(copy, original[i])
    end
    return copy
end

function quadrant_f(i)
    x_y = placeToGrid(i)
    x = x_y[1]
    y = x_y[2]
    y_quadrant = math.ceil(y / 3)
    x_quadrant = math.ceil(x / 3)

    return x_quadrant + ((y_quadrant - 1) * 3)
end

function placeToGrid(i)
    y = math.ceil(i / 9)
    x = i - ((y - 1) * 9)
    return {x, y}
end

function gridToPlace(x, y)
    return (((y - 1) * 9) + x)
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

function checkKill()
    local kill = love.thread.getChannel('kill'):pop()
    if kill == 'kill' then
        running = false
    end
end

function search(searching_map, i)
    if running == false then
        return
    end
    checkKill()
    
    
    -- base case
    if i > #searching_map then
        -- send the solution
        love.thread.getChannel('searcher_solutions'):push(searching_map)

    -- iteration cases
    elseif searching_map[i] ~= 0 then
        search(searching_map, (i+1))
    else
        for j=2, #possibilities[i] do
            if followsRules(i, possibilities[i][j], searching_map) then
                searching_map[i] = possibilities[i][j]
            
                 
                search(searching_map, (i+1)) 
            end
        end
        searching_map[i] = 0
    end
    return 
end

-- BODY OF THE THREAD ----------------------------------------------------------
running = true
search(copyTable(map), 1)
love.thread.getChannel('searcher_status'):push('something')