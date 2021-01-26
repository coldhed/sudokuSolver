WIDTH, HEIGHT = 630, 730

Class = require 'class'

require 'ColorTheme'
require 'Solver'
require 'Button'
require 'Wrong'

function love.load() 
    utility = Solver()

    -- map = { 
    --     8, 0, 0, 0, 0, 0, 0, 0, 0,
    --     0, 0, 3, 6, 0, 0, 0, 0, 0,
    --     0, 7, 0, 0, 9, 0, 2, 0, 0,
    --     0, 5, 0, 0, 0, 7, 0, 0, 0,
    --     0, 0, 0, 0, 4, 5, 7, 0, 0,
    --     0, 0, 0, 1, 0, 0, 0, 3, 0,
    --     0, 0, 1, 0, 0, 0, 0, 6, 8,
    --     0, 0, 8, 5, 0, 0, 0, 1, 0,
    --     0, 9, 0, 0, 0, 0, 4, 0, 0,   
    -- } 

    -- map = {
    --     0,3,0,0,1,0,0,6,0,
    --     7,5,0,0,3,0,0,4,8,
    --     0,0,6,9,8,4,3,0,0,
    --     0,0,3,0,0,0,8,0,0,
    --     9,1,2,0,0,0,6,7,4,
    --     0,0,4,0,0,0,5,0,0,
    --     0,0,1,6,7,5,2,0,0,
    --     6,8,0,0,9,0,0,1,5,
    --     0,9,0,0,4,0,0,3,0,
    -- }
    
    -- map = {
    --     9,2,6,5,7,1,4,8,3,3,5,1,4,8,6,2,7,9,8,7,4,9,2,3,5,1,6,5,8,2,3,6,7,1,9,4,1,4,9,2,5,8,3,6,7,7,6,3,1,0,0,8,2,5,2,3,8,7,0,0,6,5,1,6,1,7,8,3,5,9,4,2,4,9,5,6,1,2,7,3,8,
    -- } 

    map = { 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
    }
    
    state = 'start'

    colorThemes = {
        -- purple
        [1] = ColorTheme {
            background = {167, 153, 183},
            thin = {152, 136, 165},
            thick = {119, 100, 114},          
        },
        -- blue
        [2] = ColorTheme {
            background = {142, 164, 210},
            thin = {98, 121, 184},
            thick = {73, 81, 111},
        },
        -- green
        [3] = ColorTheme {
            background = {181, 202, 141},
            thin = {139, 177, 116},
            thick = {66, 107, 105},
        },
        -- orange_blue
        [4] = ColorTheme {
            background = {164, 176, 245},
            thin = {68, 100, 173},
            thick = {245, 143, 41},
        },
        -- dessert
        [5] = ColorTheme {
            background = {247, 212, 136},
            thin = {101, 104, 57},
            thick = {24, 29, 39},
        },
        -- baby_pink
        [6] = ColorTheme {
            background = {239, 211, 215},
            thin = {203, 192, 211},
            thick = {142, 154, 175},
            },
        -- classic
        [7] = ColorTheme {
            background = {255,255,255},
            thin = {49,51,53},
            thick = {49,51,53},
            },          
        --[[
            prototype:
                ['color'] = ColorTheme {
                background = {},
                thin = {},
                thick = {},
                    },
        ]]
    }
    color = 5
    currentTheme = colorThemes[color]

    love.window.setMode(WIDTH, HEIGHT, {
        vsync=true,
    })

    -- meta information
    love.window.setTitle('Sudoku')
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- fonts and lines
    numbers_font = love.graphics.newFont('assets/sans_thin.ttf', 60)
    love.graphics.setFont(numbers_font)
    love.graphics.setLineStyle("smooth")

    -- buttons
    solve_button = Button(0, 10, 'right', 'Solve', numbers_font,  WIDTH)
    
    random_button = Button(0, 10, 'left', 'Random', numbers_font, WIDTH)
    set_button = Button(0, 10, 'right', 'Set', numbers_font, WIDTH)
    start_buttons = {random_button, set_button}

    slow_button = Button(0, 10, 'left', 'Slow', numbers_font, WIDTH)
    default_button = Button(0, 10, 'center', 'Default', numbers_font, WIDTH)
    fast_button = Button(0, 10, 'right', 'Fast', numbers_font, WIDTH)
    skip_button = Button(0, 10, 'right', 'Skip', numbers_font, WIDTH)
    solving_buttons = {slow_button, default_button, fast_button}
    solving_fast = {slow_button, default_button, skip_button}

    -- mouse selection info
    selected = {['x'] = nil, ['y'] = nil}
    selected_state = 'none'
    selected_number = nil

    -- table for objects
    wrongs = {}

    -- game variables
    game_time = 0
    countTimer = false
    errors = 0

    debug = false
end

function love.draw()
    -- background
    currentTheme:setBackground()

    -- highlight selected square
        -- empty square
    currentTheme:setHighlight()
    -- highlight the solving animation
    if state == 'solving' then
        local i = solver.showIndex
    
        local y = math.ceil(i / 9) - 1
        local x = (i - ((y)* 9) - 1) * 70
        y = y * 70 + 100
        love.graphics.rectangle("fill", x, y, WIDTH / 9, WIDTH / 9)
        

    else
        if selected_state == 'empty' then
            local position = gridToPixel(selected['x'], selected['y'])
            local x = position[1]
            local y = position[2]
            love.graphics.rectangle("fill", x, y, WIDTH / 9, WIDTH / 9)
        elseif selected_state == 'number' then
            for i=1, 81 do
                if map[i] == selected_number then
                    local y = math.ceil(i / 9) - 1
                    local x = (i - ((y)* 9) - 1) * 70
                    y = y * 70 + 100
                    love.graphics.rectangle("fill", x, y, WIDTH / 9, WIDTH / 9)
                end
            end
        end
    end

    

    -- square dividing lines
    currentTheme:setThin()

        -- horizontal
    love.graphics.line(0,170, WIDTH,170)
    love.graphics.line(0,240, WIDTH,240)
    love.graphics.line(0,380, WIDTH,380)
    love.graphics.line(0,450, WIDTH,450)
    love.graphics.line(0,590, WIDTH,590)
    love.graphics.line(0,660, WIDTH,660)
        -- vertical
    love.graphics.line(70,100, 70, HEIGHT)
    love.graphics.line(140,100, 140, HEIGHT)
    love.graphics.line(280,100, 280, HEIGHT)
    love.graphics.line(350,100, 350, HEIGHT)
    love.graphics.line(490,100, 490, HEIGHT)
    love.graphics.line(560,100, 560, HEIGHT)

    currentTheme:setThick()
    -- block dividing lines
    love.graphics.line(0,310, WIDTH,310)
    love.graphics.line(0,520, WIDTH,520)
    love.graphics.line(210,100, 210,HEIGHT)
    love.graphics.line(420,100, 420,HEIGHT)
  
    -- start sudoku area
    love.graphics.line(0,100, WIDTH,100)

    -- if no solution is found
    if state == 'no solution' then
        love.graphics.print("This board has no solution", 10, 10)
    
    elseif state == 'start' then
        for i, button in pairs(start_buttons) do
            love.graphics.printf(button.text, button.x, button.y, button.limit, button.align)
        end
        -- love.graphics.print(tostring(test_timer), 10, 10)
    
    elseif state == 'play' then
       
        -- game info
        love.graphics.print("Mistakes: " .. tostring(errors), 10, 10)

        -- love.graphics.print("Solutions: " .. tostring(#solver.solutions), 10, 10)
        --love.graphics.print("Status: " .. tostring(solver.searcherThreadStatus), 10, 50)

        -- objects (wrong animations)
        for i=1, #wrongs do
            wrongs[i]:draw()
        end

        -- buttons
        button = solve_button
        love.graphics.printf(button.text, button.x, button.y, button.limit, button.align)
    
    elseif state == 'solved' then
        love.graphics.printf("Puzzle solved in "..game_time,0,10,WIDTH,'center')
    
    elseif state == 'solving' then
        --love.graphics.print("State: "..tostring(solver.showThreadStatus), 10, 10)
        -- love.graphics.print(tostring(solver.showThreadMap[2]), 10, 10)
        if solvingState == 'default' then
            for i, button in pairs(solving_buttons) do
                love.graphics.printf(button.text, button.x, button.y, button.limit, button.align)
            end
        else -- state = fast
            for i, button in pairs(solving_fast) do
                love.graphics.printf(button.text, button.x, button.y, button.limit, button.align)
            end 
        end
    end

     -- fill the grid
     for i=1, #map do
        if map[i] ~= 0 then
            local y = math.ceil(i / 9) - 1
            local x = (i - ((y)* 9) - 1) * 70
            y = y * 70 + 100
            love.graphics.print(tostring(map[i]), math.floor(x + 18), math.floor(y + 6))
        end
    end
end

function love.update(dt)
    currentTheme = colorThemes[color]
    
    ::reset_update::
    for i=1, #wrongs do
        if not wrongs[i]:update(dt) then
            table.remove(wrongs, i)
            goto reset_update
        end
    end

    if countTimer then
        game_time = game_time + dt
    end
    
    if state == 'play' then
        solver:update()
    end
    

    if state == 'solving' then
        solver:update()
        
        map = solver.showThreadMap

        if solver.showThreadStatus == 'complete' then
            state = 'solved'
        end
    end
    
end


function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    -- PLAY
    if selected_state == 'empty' and isDigit(tonumber(key)) and state == 'play' then
        local i = ((selected['y'] - 1) * 9) + selected['x']
        

        wrong = false
        -- only one solution to the puzzle
        if #solver.solutions == 1 and solver.searcherThreadStatus == 'complete' then
            -- got the number correct
            if solver.solutions[1][i] == tonumber(key) then
                map[i] = tonumber(key)
                selected_state = 'number'
                selected_number = tonumber(key)

                -- completed the puzzle
                if isComplete() then
                    state = 'solved'
                    countTimer = false
                    formatTime()
                end
            else wrong = true end
        elseif solver.searcherThreadStatus == 'complete' then -- search all the solutions
            if solver:searchSolutions(tonumber(key), i) then -- found another solution
                map[i] = tonumber(key)
                selected_state = 'number'
                selected_number = tonumber(key)
                solver:cleanSolutions(tonumber(key), i)
            else wrong = true end
        else -- searcher has not finished
            copy = utility:copyTable(map)
            copy[i] = tonumber(key)
            diff_solution = Solver(copy)
            diff_solution:solveSingle()
            
            if diff_solution.solution ~= nil then -- There is another solution
                solver:killThread()
                solver = diff_solution
                solver:startSearcherThread() -- start looking for new solutions based on the new map
                -- update main map
                map[i] = tonumber(key)
                selected_state = 'number'
                selected_number = tonumber(key)
            else wrong = true end
        end
        if wrong == true then
            local x_y = gridToPixel(selected['x'], selected['y'])
            table.insert(wrongs, Wrong(x_y[1], x_y[2], key))
            errors = errors + 1
        end
    end

    -- START
    if selected_state == 'empty' and isDigit(tonumber(key)) and state == 'start' then
        local i = ((selected['y'] - 1) * 9) + selected['x']
        map[i] = tonumber(key)
        selected_state = 'number'
        selected_number = tonumber(key)
    end

    -- DELETE | for START and NO SOLUTION
    if selected_state == 'number' and key == 'backspace' and (state == 'start' or state == 'no solution') then
        map[((selected['y'] - 1) * 9) + selected['x']] = 0
        selected_state = 'empty'
        state = 'start'
    end

    if key == 'c' then
        color = color + 1
        if color > #colorThemes then
            color = 1
        end
    end

end

function isDigit(key)
    digits = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
    result = false
    for i=1, #digits do
        if digits[i] == key then
            result = true
        end
    end
    return result
end

function love.mousepressed(x, y)
    grid = pixelToGrid(x, y)
    if selected['x'] == grid[1] and selected['y'] == grid[2] and (state == 'play' or state == 'start') then
        selected['x'] = nil
        selected['y'] = nil
        selected_state = 'none'
    else
        selected['x'] = grid[1]
        selected['y'] = grid[2]

        updateState()
    end

    --buttons
    if state == 'solving' then
        if slow_button:is_pressed(x, y) then -- SLOW
            love.thread.getChannel('speed'):push('slow')
            solvingState = 'default'

        elseif default_button:is_pressed(x, y) then -- DEFAULT
            love.thread.getChannel('speed'):push('default')
            solvingState = 'default'

        elseif solvingState == 'default' and fast_button:is_pressed(x, y) then -- FAST
            love.thread.getChannel('speed'):push('fast')
            solvingState = 'fast'
        
        elseif solvingState == 'fast' and skip_button:is_pressed(x, y) then -- SKIP
            state = 'solved'
            map = solver.solution
        end
    end

    if state == 'play' and solve_button:is_pressed(x, y) then
        
        state = 'solving'
        solvingState = 'default'
        solver:startShowThread(map)

        countTimer = false
        game_time = solver.timer * 1000
        game_time = string.format("%.2f ms", game_time)
    end    

    if state == 'start' then
        if random_button:is_pressed(x, y) then
            local randomPuzzle = Solver()
            randomPuzzle:RandomPuzzle()
            map = randomPuzzle.map
            state = 'play'
        elseif set_button:is_pressed(x, y) then
            state = 'play'
        end

        if state == 'play' then
            solver = Solver(map)
            solver:solve()
            if solver.solution == nil then state = 'no solution' end
            countTimer = true
        end
    end

    
end

function pixelToGrid(x, y)
    x = math.ceil(x / (WIDTH / 9))
    y = math.ceil((y - 100) / ((HEIGHT - 100) / 9))

    return {x, y}
end

function gridToPixel(x, y)
    x = (x - 1) * (WIDTH / 9)
    y = (y - 1) * ((HEIGHT - 100) / 9) + 100
    return {x, y}
end

function updateState()
    selected_number = nil
    number = map[((selected['y'] - 1) * 9) + selected['x']]
    if number == 0 then
        selected_state = 'empty'
    else
        selected_state = 'number'
        selected_number = number
    end
end

function isComplete()
    for i=1, 81 do
        if map[i] == 0 then return false end
    end
    return true
end

function formatTime()
    game_time = math.ceil(game_time)
    if game_time >= 60 then
        minutes = math.floor(game_time / 60)
        seconds = game_time - (minutes * 60)
        
        game_time = string.format("%d", minutes)..':'..string.format("%02d", seconds)
    else
        game_time = tostring(game_time) .. 's'
    end
end