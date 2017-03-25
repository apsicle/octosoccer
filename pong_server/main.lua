package.path = package.path .. ";libraries/?.lua"
sock = require "sock"
bitser = require "bitser"
require "scripts"

package.path = package.path .. ";classes/?.lua"
require "Ball"
require "Player"
menu = require "Menu"
require "Camera"

-- Utility functions
function isColliding(this, other)
    return  this.x < other.x + other.w and
            this.y < other.y + other.h and
            this.x + this.w > other.x and
            this.y + this.h > other.y
end

function love.load()
    -- how often an update is sent out
    tickRate = 1/60
    time = 0
    tick = 0

    -- define globals
    local marginX = 50
    scores = {0, 0}
    global_obj_array = {}
    global_obj_pointer = 1
    window_width = love.graphics.getWidth()
    window_height = love.graphics.getHeight()

    ball = Ball.new()
    players = {
    }

    -- %% Server on any IP, port 22122, with 2 max peers
    server = sock.newServer("192.168.0.103", 22122, 2)
    -- %% Assign bitser as serialization and deserialization functions (dumps and loads respectively)
    server:setSerialization(bitser.dumps, bitser.loads)

    -- Players are being indexed by peer index here, definitely not a good idea
    -- for a larger game, but it's good enough for this application.
    -- %% server:on(event, callback)
    server:on("connect", function(data, client)
        -- tell the peer what their index is
        local index = client:getIndex()
        client:send("playerNum", index)
        players[index] = Player.new()
        players[index].id = index
        server:sendToAll("playerList", map(function(a) return a:getState() end, players))
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

    server:on("shoot", function(data)
        -- acceleration is the frictional force, opposes motion
        local acceleration = -75
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
    end)

    -- Setup Visuals
    field = love.graphics.newImage("sprites/field.png")
    camera = Camera.new()
    global_width = field:getWidth()
    global_height = field:getHeight()

end

function love.update(dt)
    server:update()
    camera:update(dt)
    -- wait until 2 players connect to start playing
    local enoughPlayers = #server.clients >= 1
    if not enoughPlayers then return end

    -- Update moving objects
    update_objects(dt);
    move_objects(dt);

    -- Left/Right bounds
    tick = tick + dt
    time = time + dt

    if tick >= tickRate then
        tick = 0

        for i, player in pairs(players) do
            server:sendToAll("stateUpdate", {time = time, index = i, eventType = "playerState", playerState = player:getState()})
        end

        server:sendToAll("stateUpdate", {time = time, eventType = "ballState", ballState = ball:getState()})
        
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