package.path = package.path .. ";libraries/?.lua"
sock = require "sock"
bitser = require "bitser"
require "scripts"

package.path = package.path .. ";classes/?.lua"
require "Ball"
require "Player"
menu = require "Menu"


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
    tick = 0

    -- %% Server on any IP, port 22122, with 2 max peers
    server = sock.newServer("*", 22122, 2)
    -- %% Assign bitser as serialization and deserialization functions (dumps and loads respectively)
    server:setSerialization(bitser.dumps, bitser.loads)

    -- Players are being indexed by peer index here, definitely not a good idea
    -- for a larger game, but it's good enough for this application.
    -- %% server:on(event, callback)
    server:on("connect", function(data, client)
        -- tell the peer what their index is
        client:send("playerNum", client:getIndex())
        players[client:getIndex()] = Player.new()
        server:sendToAll("playerList", map(function(a) return a:getState() end, players))
    end)

    -- receive info on where a player is located
    server:on("clientPlayerState", function(clientPlayerState, client)
        local index = client:getIndex()
        players[index]:setState(clientPlayerState)
    end)

    server:on("shoot", function(data)
        ball.speed = data.speed
        ball.destination.x = data.x
        ball.destination.y = data.y
        ball.owner = nil
    end)

    --server:on("playerDestination", function(playerDestination, client))


    function newPlayer(x, y)
        return {
            x = x,
            y = y,
            w = 20,
            h = 100,
        }
    end

    function newBall(x, y)
        return {
            x = x,
            y = y,
            vx = 150,
            vy = 150,
            w = 15,
            h = 15,
        }
    end

    local marginX = 50

  

    scores = {0, 0}

    global_width = love.graphics.getWidth()
    global_height = love.graphics.getHeight()
    global_obj_array = {}
    global_obj_pointer = 1

    ball = Ball.new()
    players = {
    }
end

function love.update(dt)
    server:update()

    -- wait until 2 players connect to start playing
    local enoughPlayers = #server.clients >= 1
    if not enoughPlayers then return end

    -- Update moving objects
    update_objects();
    move_objects();

    -- Left/Right bounds
    tick = tick + dt

    if tick >= tickRate then
        tick = 0

        for i, player in pairs(players) do
            server:sendToAll("playerState", {index = i, playerState = player:getState()})
        end

        server:sendToAll("ballState", {x = ball.x, y = ball.y})
    end
end

function love.draw()
    draw_objects();

    love.graphics.setColor(255,255,255)

    local score = ("%d - %d"):format(scores[1], scores[2])
    love.graphics.print(score, 5, 5)
end

-- Unique loop functions
function draw_objects()
    for i = 1, 4, 1 do
        for key, value in pairs(global_obj_array) do    
            value:draw(i)
            love.graphics.ellipse('line', value.x, value.y, value.radius, value.radius)
        end
    end
end

function move_objects()
    for key, value in pairs(global_obj_array) do
        value:move()
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
    end
    --don't let objects move beyond walls
    
end
    
function update_objects()
    for key, value in pairs(global_obj_array) do
        value:update()
    end
end