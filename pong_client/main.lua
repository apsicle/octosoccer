--package.path = package.path .. ";libraries/?.lua"
sock = require "libraries/sock"
bitser = require "libraries/bitser"
require "libraries/scripts"

--package.path = package.path .. ";classes/?.lua"
require "classes/Ball"
require "classes/Player"
Menu = require "classes/Menu"
require "classes/Camera"

function love.load()
    -- how often an update is sent out
    tickRate = 1/60
    tick = 0
    time = {ballState = 0, playerState = 0}

    global_obj_array = {}
    global_obj_pointer = 1
    local marginX = 50
    scores = {0, 0}

    -- new Client. This has listeners
    client = sock.newClient("192.168.0.103", 22122)
    client:setSerialization(bitser.dumps, bitser.loads)

    -- store the client's index
    -- playerNumber is nil otherwise
    -- adds a new callback (function (num) playerNumber = num) to the listener trigger (client.listener.trigger[event]) for the event "playerNum"
    client:on("playerNum", function(num)
        playerNumber = num
    end)

    -- receive player list on connection.
    -- players are populated and your player is set to active.
    client:on("playerList", function(playerList)
        players = {}
        print_table(playerList)
        for i, playerState in ipairs(playerList) do
            players[i] = Player.new()
            players[i]:setState(playerState)
            players[i].id = i
            if i == playerNumber then
                players[i].active = true
            end
        end
    end)

    -- receive info on where the players are located
    client:on("stateUpdate", function(data)
        -- only take the most recent update
        if data.time >= time.ballState and data.time >= time.playerState then
            -- perform the right update
            if data.eventType == "playerState" then
                local index = data.index
                local playerState = data.playerState

                -- only accept updates for the other player
                if playerNumber and index ~= playerNumber then
                    if players[index] ~= nil then
                        players[index]:setState(playerState)
                    else
                        players[index] = Player.new()
                        players[index]:setState(playerState)
                    end
                end
                time.playerState = data.time
            elseif data.eventType == "ballState" then
                local ballState = data.ballState

                if ball then
                    ball:setState(ballState)    
                else
                    ball = Ball.new()
                    ball:setState(ballState)
                end
                time.ballState = data.time
            end
            
        end
    end)

    client:on("removePlayer", function(index)
        if players[index].hasBall then
            global_obj_array[players[index].global_index] = nil
            players[index] = nil
            ball.owner = nil
        else
            global_obj_array[players[index].global_index] = nil
            players[index] = nil
        end
    end)
    
    client:on("scores", function(data)
        scores = data
    end)

    client:connect()

-- Audio Setup
    music_src1 = love.audio.newSource("audio/hey_ya.mp3")
    music_src1:setVolume(0.3)
    music_src1:play()

    music_src2 = love.audio.newSource("audio/ada.mp3")
    music_src2:setVolume(0.3)

    pass1 = love.audio.newSource("audio/pass.ogg")
    pass1:setVolume(1.2)

-- Visuals Setup
    field = love.graphics.newImage("sprites/field.png")
    camera = Camera.new()
    global_width = field:getWidth()
    global_height = field:getHeight()
    window_width = love.graphics.getWidth()
    window_height = love.graphics.getHeight()


-- Menu Setup
    paused = true
    options = {debug = false, windowed = true}
    main_menu = Menu.new()
        main_menu:addItem{
            name = 'Start Game',
            action = function()
                paused = false
                music_src1:pause()
                --music_src2:play()
            end
        }
        main_menu:addItem{
            name = 'Options',
            action = function()
                active_menu = options_menu
            end
        }
        main_menu:addItem{
            name = 'Quit',
            action = function()
                love.event.push('quit')
            end
        }
    main_menu.parent = main_menu
    active_menu = main_menu

    options_menu = Menu.new(main_menu)
        options_menu:addItem{
            name = 'Toggle debug mode',
            action = function()
                options['debug'] = not options['debug']
            end
        }
        options_menu:addItem{
            name = 'Controls',
            action = function()
                active_menu = controls_menu
            end
        }
        options_menu:addItem{
            name = 'Switch windowed mode',
            action = function()
                if options.windowed then
                    love.window.setMode(0, 0, {fullscreen = true})
                    options.windowed = false
                    window_width = love.graphics.getWidth()
                    window_height = love.graphics.getHeight()
                else
                    love.window.setMode(800, 600, {fullscreen = false})
                    options.windowed = true
                    window_width = love.graphics.getWidth()
                    window_height = love.graphics.getHeight()
                end
            end
        }

    controls_menu = Menu.new(options_menu)
        controls_menu:addItem{
            name = 'Jebaited you can\'t actually change any of these'
        }
        controls_menu:addItem{
            name = 'Movement - Arrow Keys'
        }
        controls_menu:addItem{
            name = 'Boomerang - W'
        }
        controls_menu:addItem{
            name = 'Attack - A'
        }
        controls_menu:addItem{
            name = 'Freezing Field - F'
        }
        controls_menu:addItem{
            name = 'Jump up a long way then fall down - R'
        }

    --ball = newBall(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
end

function love.update(dt)
    -- if paused, just update the menu
    if paused == true then
        active_menu:update(dt)
    else
        -- update client info... check for connection
        client:update()
        camera:update(dt)

        if client:getState() == "connected" then
            tick = tick + dt
        end

        -- update to the next frame if set amount of time (tickRate) has passed
        -- also check that the player list has been successfuly created
        if tick >= tickRate and playerNumber then
            tick = 0
            update_objects(dt);
            move_objects(dt);

            -- Update our own player position and send it to the server
            client:send("clientPlayerState", players[playerNumber]:getState())
        end
    end
end

function love.draw()
    if paused == true then
        active_menu:draw(100, 200)
    else
        camera:set();
        draw_field();
        draw_objects();
        love.graphics.setColor(255,255,255);
        camera:unset();
        --love.graphics.draw(image, x_pos, y_pos, rotation, scalex, scaley, xoffset, yoffset from origin)
    end

    love.graphics.print(client:getState(), 5, 5)
    love.graphics.print('client ' .. client:getIndex(), 5, 65)
    if players ~= nil then
        love.graphics.print('has ball ' .. tostring(players[playerNumber].hasBall))
    end
    if playerNumber then
        love.graphics.print("Player " .. playerNumber, 5, 25)
    else
        love.graphics.print("No player number assigned", 5, 25)
    end
    local score = ("%d - %d"):format(scores[1], scores[2])
    love.graphics.print(score, 5, 45)
end

function love.keypressed(key)
    active_menu:keypressed(key)
end

-- Unique loop functions
function draw_objects()
    if options['debug'] == true then
        for i = 1, 4, 1 do
            for key, value in pairs(global_obj_array) do
                value:draw(i)

                -- This section of code shows collision circles for debugging
                if value.radius ~= nil then
                    love.graphics.ellipse('line', value.x, value.y, value.radius, value.radius)
                end
            end
        end
    else
        for i = 1, 4, 1 do
            for key, value in pairs(global_obj_array) do    
                value:draw(i)
            end
        end
    end
end

function move_objects(dt)
    for key, value in pairs(global_obj_array) do
        value:move(dt)

        -- if it's not the ball, just move it back into boundaries
        if value.isBall == nil then
            if value.x > global_width - 32 then
                value.x = global_width - 32
            end
            if value.y > global_height - 32 then
                value.y = global_height - 32
            end
            if value.x < 0 + 32 then
                value.x = 0 + 32
            end
            if value.y < 0 + 32 then
                value.y = 0 + 32
            end
        -- if it is the ball, make it bounce off the walls
        else
            if value.x > global_width - 32 then
                value.vx = value.vx * -1
                value.ax = value.ax * -1
            end
            if value.y > global_height - 32 then
                value.vy = value.vy * -1
                value.ay = value.ay * -1
            end
            if value.x < 0 + 32 then
                value.vx = value.vx * -1
                value.ax = value.ax * -1
            end
            if value.y < 0 + 32 then
                value.vy = value.vy * -1
                value.ay = value.ay * -1
            end
        end
    end
end
    
function update_objects(dt)
    for key, value in pairs(global_obj_array) do
        value:update(dt)
    end
end

function draw_field()
    local num_cols = 20
    local col_width = global_width / num_cols
    local col_height = global_height * .9
    love.graphics.draw(field, 0, 0)
end