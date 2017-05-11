-- meta server game coordinator for octosoccer

sock = require "pong_server/libraries/sock"
bitser = require "pong_server/libraries/bitser"


function love.load()
	-- victor's house
	-- server = sock.newServer("192.168.1.11", 22123, 16)
	-- ryan's house
	--server = sock.newServer("192.168.0.103", 22120, 32)
	server = sock.newServer("10.0.20.182", 22120, 32)
	server:setSerialization(bitser.dumps, bitser.loads)
	myIP = server:getSocketAddress()
	serverList = {}
	clientList = {}
	print(my_ip)

	server:on("connect", function(data, client)
		-- When a game client is launched, it is directed to this ip address.
		clientList[client:getIndex()] = client:getIndex()	
	end)

	server:on("requestServerList", function(data, client)
		-- Send the active server list to a client.
		server:sendToPeer(server:getPeerByIndex(client:getIndex()), "serverList", serverList)
	end)

	server:on("newServer", function(data, client)
		local ip = data.ip
		local port = data.port
		serverList[client:getIndex()] = {ip = ip, port = port, index = client:getIndex()}
	end)

	server:on("disconnect", function(data, client)
		serverList[client:getIndex()] = nil
		clientList[client:getIndex()] = nil
	end)
end

function love.update()
	server:update()
end

function love.draw()
	local count = 0
    for i, v in pairs(serverList) do
        local server = ("Server IP: %s - Port: %d"):format(v.ip, v.port)
        love.graphics.print(server, 5, 65 + 20 * count)
        count = count + 1
    end
    love.graphics.print(("Number of clients (game client + servers): %d"):format(#clientList), 5, 45)
end