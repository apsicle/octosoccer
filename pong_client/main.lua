-- add switch sides
-- add 
--package.path = package.path .. ";libraries/?.lua"
sock = require "libraries/sock"
bitser = require "libraries/bitser"
require "libraries/scripts"
anim8 = require "libraries/anim8"

--package.path = package.path .. ";classes/?.lua"
require "classes/Ball"
require "classes/Player"
Menu = require "classes/Menu"
require "classes/Camera"
require "classes/Pause"
require "classes/ChatLog"
require "classes/Animation"

function love.load()

    -- read in the options from config.txt or create it (changing options saves to config.txt)
    if love.filesystem.exists("config.lua") then
        require("config")
    else
        options = {debug = false, windowed = false, player_name = "Player"}
        write_options()
    end

    -- create the window
    if options.windowed then
        -- set to windowed
        love.window.setMode(1280, 720, {fullscreen = false}) 
    else
        -- set to fullscreen
        love.window.setMode(0, 0, {fullscreen = true})
    end

    -- how often an update is sent out
    tickRate = 1/60
    tick = 0
    time = {ballState = 0, playerState = 0}

    global_obj_array = {}
    global_obj_pointer = 1
    global_animation_array = {}
    global_animation_pointer = 1
    local marginX = 50
    scores = {0, 0}
    chatLog = ChatLog.new()
    serverList = {}
    --metaServerClient = sock.newClient("192.168.1.11", 22122)
    --metaServerClient = sock.newClient("192.168.0.105", 22122)
    metaServerClient = sock.newClient("10.0.20.182", 22120)

    metaServerClient:setSerialization(bitser.dumps, bitser.loads)
    metaServerClient:on("serverList", function(data)
        serverList = data
    end)
    metaServerClient:connect()

    -- Visuals Setup
    font = love.graphics.newFont(14)
    kick_cursor = love.mouse.newCursor("sprites/kick_cursor.png", 16, 16)
    splash = love.graphics.newImage("sprites/splash.png")
    field = love.graphics.newImage("sprites/field.png")
    octopus_sprite = love.graphics.newImage("sprites/octopus.png")
    shark_sprite = love.graphics.newImage("sprites/shark.png")
    camera = Camera.new()
    global_width = field:getWidth()
    global_height = field:getHeight()
    window_width = love.graphics.getWidth()
    window_height = love.graphics.getHeight()
    connected = false

-- Audio Setup
    music_src1 = love.audio.newSource("audio/hey_ya.mp3")
    music_src1:setVolume(0.3)
    --music_src1:play()

    music_src2 = love.audio.newSource("audio/ada.mp3")
    music_src2:setVolume(0.3)

    pass1 = love.audio.newSource("audio/pass.ogg")
    pass1:setVolume(1.2)

-- Menu Setup
    in_menu = true

    main_menu = Menu.new(nil, "standard")
        main_menu:addItem{
            name = 'Find Game',
            action = function()
                --in_menu = false
                active_menu = find_game_menu
                music_src1:pause()
                metaServerClient:send("requestServerList")
                --client = createClient('74.96.117.110', 22123)
            end
        }
        main_menu:addItem{
            name = 'Select Team',
            action = function()
                active_menu = teams_menu
            end
        }
        main_menu:addItem{
            name = 'Change Name',
            action = function()
                -- if you're not connected to the server, save the name locally (it gets sent when you connect)
                active_menu = name_menu
                -- if you have already connected send the name change to the server as a "clientNameChange" event
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
    name_menu = Menu.new(main_menu, "nameInput")
    find_game_menu = Menu.new(main_menu, "serverList")

    options_menu = Menu.new(main_menu, "standard")
        options_menu:addItem{
            name = 'Toggle debug mode',
            action = function()
                options['debug'] = not options['debug']
                write_options()
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
                    love.window.setMode(1280, 720, {fullscreen = false})
                    options.windowed = true
                    window_width = love.graphics.getWidth()
                    window_height = love.graphics.getHeight()
                end
                write_options()
            end
        }

    controls_menu = Menu.new(options_menu, "standard")
        controls_menu:addItem{
            name = 'You can\'t change these'
        }
        controls_menu:addItem{
            name = 'Right Click - Move'
        }
        controls_menu:addItem{
            name = 'Q + click - Kick ball'
        }
        controls_menu:addItem{
            name = 'E - Sprint'
        }
        controls_menu:addItem{
            name = 'D - Request Pass'
        }
        controls_menu:addItem{
            name = '1 - Re-center camera'
        }
        controls_menu:addItem{
            name = 'Enter - Chat'
        }

    teams_menu = Menu.new(main_menu, "standard")
        teams_menu:addItem{
            name = 'Octopirates',
            action = function()
                if players[playerNumber] then  
                    client:send("select_team", {id = players[playerNumber].id, team = 1})
                    active_menu:keypressed('esc')
                end
            end
        }
        teams_menu:addItem{
            name = 'Sharkpedoes',
            action = function()
                if players[playerNumber] then
                    client:send("select_team", {id = players[playerNumber].id, team = 0})
                    active_menu:keypressed('esc')
                end
            end
        }
    --ball = newBall(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
end

function love.update(dt)
    -- update the client if it's there
    metaServerClient:update()
    if client then
        client:update(dt)
    end
    -- Always update the menu if it's active
    if in_menu == true then
        active_menu:update(dt)
    end
    -- if the server is paused, only update the client
    if server_paused then
        return
    elseif connected then
        camera:update(dt)
        chatLog:update(dt)

        if client:getState() == "connected" then
            tick = tick + dt
        end

        -- update to the next frame if set amount of time (tickRate) has passed
        -- also check that the player list has been successfuly created
        if tick >= tickRate and playerNumber then
            tick = 0
            update_objects(dt);
            move_objects(dt);
            update_animations(dt);

            -- Update our own player position and send it to the server
            --client:send("clientPlayerState", players[playerNumber]:getState())
        end
    end
end

function love.draw()
    if in_menu == true then
        local sx = love.graphics.getWidth() / splash:getWidth()
        local sy = love.graphics.getHeight() / splash:getHeight()
        love.graphics.setColor(255,255,255, 192);
        love.graphics.draw(splash, (window_width - sy * splash:getWidth()) / 2, 0, 0, sy, sy)
        active_menu:draw(100, 200)
    else
        love.graphics.setColor(255,255,255);
        camera:set();
        draw_field();
        draw_objects();
        draw_animations();
        chatLog:draw();
        camera:unset();
        --love.graphics.draw(image, x_pos, y_pos, rotation, scalex, scaley, xoffset, yoffset from origin)
    end

    love.graphics.setColor(255,255,255)
    if playerNumber then
        love.graphics.print("Player " .. playerNumber, 5, 25)
    else
        love.graphics.print("No player number assigned", 5, 25)
    end
    local score = ("%d - %d"):format(scores[1], scores[2])
    love.graphics.print(score, 5, 45)
end

function love.keypressed(key)
    -- if you're typing, typing takes key input precedence
    local inputConsumed = false
    if chatLog then
        -- chatLog takes precedence. if you're typing, any keyboard input is taken by chatLog
        inputConsumed = chatLog:keypressed(key)
    end
    if not inputConsumed and playerNumber then
        -- if you're in the game, player uses input. otherwise, input is not consumed
        inputConsumed = players[playerNumber]:keypressed(key)
    end
    if not inputConsumed and camera then
        inputConsumed = camera:keypressed(key)
    end
    -- lastly, send it to the active menu. (this checks if you're in a menu or not before doing stuff,
    -- but needs to be put here in in case the key is pressed 'esc' to activate the menu)
    if not inputConsumed and active_menu then
        active_menu:keypressed(key)
    end
end

function love.mousepressed(x, y, mouse)
    local inputConsumed = false
    if playerNumber then
        inputConsumed = players[playerNumber]:mousepressed(mouse)
    elseif in_menu then
        inputConsumed = active_menu:mousepressed(x, y, mouse)
    end
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

function draw_animations()
    for key, value in pairs(global_animation_array) do
        value:draw()
    end
end

function update_animations(dt)
    for key, value in pairs(global_animation_array) do
        value:update(dt)
    end
end

function draw_field()
    local num_cols = 20
    local col_width = global_width / num_cols
    local col_height = global_height * .9
    love.graphics.draw(field, 0, 0)
end

function write_options()
    local config_file = io.open('config.lua', 'w')
    config_file:write("options = {}\n")
    for i, v in pairs(options) do
        if type(v) == "string" then
            config_file:write(("options.%s=\'%s\'\n"):format(i,v))
        else
            config_file:write(("options.%s=%s\n"):format(i,v))
        end
    end
    config_file:close()
end

function createClient(ip, port)
    -- this function will be called to create a client when an ip / port of a server has been identified.
    -- new Client. This has listeners
    --client = sock.newClient("192.168.0.103", 22122)
    -- to create listeners, you have to have created a client. 
    -- we don't create client on launch, but rather only when we have identified an ip to connect to.
    local client = sock.newClient(tostring(ip), port)
    --client = sock.newClient("192.168.1.11", 22122)
    client:setSerialization(bitser.dumps, bitser.loads)

    client:on("connect", function()
        connected = true
        print("connected")
    end)

    client:on("centerCamera", function(obj)
        if obj then
            if camera then
                camera:center(obj)
            end
        else
            if camera and playerNumber then
                camera:center(players[playerNumber])
            end
        end
    end)

    client:on("goal", function(team)
        scores[team] = scores[team] + 1
    end)

    client:on("newMessage", function(data)
        chatLog:writeNewMessage(data)
    end)


    client:on("paused", function()
        server_paused = true
        print("pausing")
    end)

    client:on("unpaused", function()
        server_paused = false
        print("unpausing")
    end)
    -- store the client's index
    -- playerNumber is nil otherwise
    -- adds a new callback (function (num) playerNumber = num) to the listener trigger (client.listener.trigger[event]) for the event "playerNum"
    client:on("playerNum", function(num)
        playerNumber = num
        team = playerNumber % 2
        client:send("clientNameChange", {id = playerNumber, name = options.player_name or "Player"})
    end)

    -- receive player list on connection.
    -- players are populated and your player is set to active.
    client:on("playerList", function(playerList)
        players = {}
        for i, playerState in ipairs(playerList) do
            players[i] = Player.new()
            players[i]:setState(playerState)
            players[i].id = i
            players[i].team = i % 2
            if players[i].team == 0 then
                players[i].sprite = shark_sprite
            end
            if i == playerNumber then
                players[i].active = true
                players[i].name = options.player_name or "Player"
            end
        end
    end)

    client:on("requestPass", function(data)
        local id = data.id
        Animation.new(love.graphics.newImage("sprites/passme.png"), players[id].x, players[id].y - 75, 1, 1, "pauseAtEnd")
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
                if playerNumber then
                    if players[index] ~= nil then
                        players[index]:setState(playerState)
                    else
                        players[index] = Player.new()
                        players[index]:setState(playerState)
                        players[index].id = index
                        players[index].team = index % 2
                        if players[index].team == 0 then
                            players[index].sprite = shark_sprite
                        end
                        if index == playerNumber then
                            players[index].active = true
                        end
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
        
        else
            print('Dropped packet type: ', data.eventType)
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

    --client:connect()
    return client
end
