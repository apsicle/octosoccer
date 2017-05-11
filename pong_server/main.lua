package.path = package.path .. ";libraries/?.lua"
sock = require "sock"
bitser = require "bitser"
require "scripts"

package.path = package.path .. ";classes/?.lua"
require "Ball"
require "Player"
menu = require "Menu"
require "Camera"
require "Pause"

function love.load()
    -- how often an update is sent out
    tickRate = 1/60
    time = 0
    tick = 0

    -- Setup Globals
    scores = {0, 0}
    field = love.graphics.newImage("sprites/field.png")
    octopus_sprite = love.graphics.newImage("sprites/octopus.png")
    shark_sprite = love.graphics.newImage("sprites/shark.png")
    global_obj_array = {}
    global_obj_pointer = 1
    window_width = love.graphics.getWidth()
    window_height = love.graphics.getHeight()
    global_width = field:getWidth()
    global_height = field:getHeight()
    margin_width = global_width * .0133
    margin_height = global_height * .02
    game_started = false

    -- this part needs to be set dynamically, can probaby be done in lua
    -- This is the client that connects the new game server to the meta game server
    --local myIp = "192.168.0.103"
    --local myPort = 22121
    --local metaServerIp = "192.168.0.105"
    --local metaServerPort = 22122
    --*************SET META SERVER INFO**************
    local myIp = "10.0.20.182"
    local myPort = 22121
    local metaServerIp = "10.0.20.182"
    local metaServerPort = 22120

    serverClient = sock.newClient(metaServerIp, metaServerPort)
    serverClient:setSerialization(bitser.dumps, bitser.loads)
    serverClient:on("connect", function(data, client)
        print("connected!")
        serverClient:send("newServer", {ip = myIp, port = myPort})
    end)
    serverClient:connect()


    -- queue for functions like team switching that get down when the round ends
    toDo = {}
    
    camera = Camera.new()
    camera:setScale(window_width / global_width, window_height / global_height)

    
    ball = Ball.new()
    ball:reset()
    players = {
    }
    round_paused = Pause.new(3, roundStart)
    -- %% Server on any IP, port 22122, with 8 max peers
    server = sock.newServer(myIp, myPort, 8)
    --server = sock.newServer("192.168.1.11", 22122, 8)
    -- %% Assign bitser as serialization and deserialization functions (dumps and loads respectively)
    server:setSerialization(bitser.dumps, bitser.loads)

    -- Players are being indexed by peer index here, definitely not a good idea
    -- for a larger game, but it's good enough for this application.
    -- %% server:on(event, callback)
    server:on("connect", function(data, client)
        -- tell the peer what their playerNumber is, create a player object in our server list
        -- assign it the proper team, sprite, and update the playerList and send it back to the new client
        local index = client:getIndex()
        client:send("playerNum", index)
        players[index] = Player.new()
        players[index].id = index
        players[index].team = index % 2
        if players[index].team == 0 then
            players[index].sprite = love.graphics.newImage("sprites/shark.png")
        end
        server:sendToPeer(server:getPeerByIndex(index), "playerList", map(function(a) return a:getState() end, players))
    end)

    server:on("disconnect", function(data, client)
        -- remove the player from the players
        print("DISCONNECTING")
        print_table(players)
        local index = client:getIndex()

        if players[index].hasBall then
            global_obj_array[players[index].global_index] = nil
            players[index] = nil
            ball.owner = nil
        else
            global_obj_array[players[index].global_index] = nil
            players[index] = nil
        end
        server:sendToAll("removePlayer", index)
    end)
    -- receive info on where a player is located
    server:on("clientPlayerState", function(clientPlayerState, client)
        local index = client:getIndex()
        players[index]:setState(clientPlayerState)
    end)

    server:on("clientChatMessage", function(data)
        local name_message = {name = data.name, text = data.text}
        server:sendToAll("newMessage", name_message)
    end)

    server:on("clientDestination", function(data)
        local id = data.id
        players[id]:setDestination(data.x, data.y)
    end)

    server:on("clientDestinationAngle", function(data)
        local id = data.id
        players[id]:setDestinationAngle(data.x, data.y)
    end)

    server:on("clientNameChange", function(data)
        local id = data.id
        if players[id].name then
            players[id].name = data.name
        end
    end)

    server:on("requestPass", function(data)
        local id = data.id
        server:sendToAll("requestPass", data)
    end)

    server:on("shoot", function(data)
        -- acceleration is the frictional force, opposes motion
        local acceleration = -90
        ball.speed = data.speed
        local x_dist = data.x - ball.x
        local y_dist = data.y - ball.y
        local angle = math.atan2(y_dist, x_dist)
        local x_factor = math.cos(angle)
        local y_factor = math.sin(angle)
        local t = math.abs(data.speed / (acceleration))
        ball.vx = x_factor * data.speed
        ball.vy = y_factor * data.speed
        ball.ax = x_factor * acceleration
        ball.ay = y_factor * acceleration
        ball.t = t
        ball.owner = nil
        players[data.id]:setDestination(nil, nil)
        players[data.id].hasBall = false
    end)

    server:on("sprinting", function(data)
        local id = data.id
        players[id].sprinting_cooldown = 10
        players[id].sprinting = 3
    end)

    server:on("select_team", function(data)
        table.insert(toDo, function() local id = data.id; if players[id] then players[id].team = data.team end end)
    end)

    server:on("stop", function(data)
        local id = data.id
        players[id]:setDestination(nil, nil)
        players[id]:setDestinationAngle(nil, nil)
    end)
end

function love.update(dt)
    server:update()
    serverClient:update()

    if round_paused.active then
        round_paused:update(dt)
    else
        camera:update(dt)
        -- wait until 2 players connect to start playing
        local enoughPlayers = #server.clients >= 2
        if not enoughPlayers then return end

        -- we have enough players
        if not game_started then
            roundStart()
            game_started = true
        end
        -- Update moving objects
        update_objects(dt);
        move_objects(dt);

        -- Left/Right bounds
        tick = tick + dt
        time = time + dt

        if tick >= tickRate then
            tick = 0

            for i, player in pairs(players) do
                server:sendToAll("stateUpdate", {time = time, index = player.id, eventType = "playerState", playerState = player:getState()})
            end

            server:sendToAll("stateUpdate", {time = time, eventType = "ballState", ballState = ball:getState()})
            
        end
    end
end

function love.draw()
    camera:set()
    draw_field();
    draw_objects();
    camera:unset();
    love.graphics.setColor(255,255,255)

    local score = ("%d - %d"):format(scores[1], scores[2])
    local clients = ("# Clients: %d"):format(#server.clients)
    local players = ("# Players: %d"):format(#players)
    local objects = ("# Objects: %d"):format(#global_obj_array)
    love.graphics.print(score, 5, 5)
    love.graphics.print(clients, 5, 65)
    love.graphics.print(players, 5, 85)
    love.graphics.print(objects, 5, 105)
end

-- Unique loop functions
function draw_objects()
    for i = 1, 4, 1 do
        for key, value in pairs(global_obj_array) do 
            love.graphics.setColor(255,255,255)   
            value:draw(i)
            love.graphics.setColor(255,0,0)
            love.graphics.ellipse('line', value.x, value.y, value.radius, value.radius)
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
                if in_range(value.y, 526, 974) then
                    round_paused:start(3, roundStart)
                    server:sendToAll("goal", 1)
                    scores[1] = scores[1] + 1
                else
                    value.vx = value.vx * -1
                    value.ax = value.ax * -1
                end
            end
            if value.y > global_height - 32 then
                value.vy = value.vy * -1
                value.ay = value.ay * -1
            end
            if value.x < 0 + 32 then
                if in_range(value.y, 526, 974) then
                    round_paused:start(3, roundStart)
                    server:sendToAll("goal", 2)
                    scores[2] = scores[2] + 1
                else
                    value.vx = value.vx * -1
                    value.ax = value.ax * -1
                end
            end
            if value.y < 0 + 32 then
                value.vy = value.vy * -1
                value.ay = value.ay * -1
            end
        end
    end
    --don't let objects move beyond walls
    
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

function roundStart(reset)
    if reset then
        scores = {0, 0}
        server:sendToAll("scores", scores)
        toDo = {}
    end
    for i, v in pairs(toDo) do
        v()
        v = nil
    end
    round_paused:start(3)
    local x_1 = 200
    local x_2 = global_width - 200
    local y_1 = 300
    local y_2 = 300
    for i, v in pairs(players) do
        if v.team == 1 then
            v.x = x_1
            v.y = y_1
            y_1 = y_1 + 300
        else
            v.x = x_2
            v.y = y_2
            y_2 = y_2 + 300
            v.angle = math.pi
        end
        v.destination = {x = nil, y = nil}
    end
    ball:reset()
    for i, player in pairs(players) do
        server:sendToAll("stateUpdate", {time = time, index = i, eventType = "playerState", playerState = player:getState()})
    end
    server:sendToAll("stateUpdate", {time = time, eventType = "ballState", ballState = ball:getState()})
    server:sendToAll("centerCamera")  
end

function love.keypressed(key)
    if key == "r" then
        roundStart(true)
    end
end