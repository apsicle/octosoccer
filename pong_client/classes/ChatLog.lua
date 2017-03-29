ChatLog = {}

function ChatLog.new()
	chatlog = {}
	setmetatable(chatlog, {__index = ChatLog})
	chatlog.typing = false
	chatlog.fadeTime = 5
	chatlog.messages = {}
	chatlog.messagePointer = 1
	chatlog.newMessage = {}
	return chatlog
end

function ChatLog:keypressed(key)
    if key == 'return' then
    	-- if you're typing a message, send it.
    	if self.typing then
	        -- chatlog.newMessage is a number indexed table (for editing purposes)
	        -- convert it into one long string
	        local myMessage = ""
	        for i = 1, #self.newMessage, 1 do
	        	myMessage = myMessage .. tostring(self.newMessage[i])
	        end
	        -- if the message was empty, ignore it and close the chat box.
	        -- else, send it to the server and then clear it and reset the pointer
	        if #myMessage > 1 then
		        client:send("clientChatMessage", {name = players[playerNumber].name, text = myMessage})
		        self.newMessage = {}
		        self.messagePointer = 1
		    else
		    	self.newMessage = {}
		    	self.messagePointer = 1
		    	self.typing = false
		    end
	    else
	    	self.typing = true
	    end   
	elseif key == "backspace" then
    	-- if your message is at least 1 long then delete the last character
        if #self.newMessage > 0 then 
        	self.newMessage[self.messagePointer - 1] = nil; 
        	self.messagePointer = self.messagePointer - 1 
        end
    elseif self.typing then
    	local keystring = key
    	if key == "space" then
    		keystring = " "
    	end

    	self.newMessage[self.messagePointer] = keystring
    	self.messagePointer = self.messagePointer + 1
    end
end

function ChatLog:update(dt)
	for i, v in pairs(self.messages) do
		if v.fadeTime > 0 then
			v.fadeTime = v.fadeTime - dt
		end
	end
end

function ChatLog:writeNewMessage(message)
	table.insert(self.messages, {message = message, fadeTime = 5})
end

function ChatLog:draw()
	local count = 0
	for i, v in pairs(self.messages) do
		if v.fadeTime > 0 then
			print_table(v.message)
			love.graphics.print(("%s: %s"):format(v.message.name, v.message.text), camera.x + window_width / 2, (camera.y + 94 * window_height / 100) - count * (window_height / 40))
			count = count + 1
		end
	end
	if self.typing then
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle('fill', camera.x + window_width / 2, camera.y + 97 * window_height / 100, 200, 20)
		love.graphics.setColor(255,255,255)
        local myMessage = ""
        for i = 1, #self.newMessage, 1 do
        	myMessage = myMessage .. tostring(self.newMessage[i])
        end
		love.graphics.print(("%s"):format(myMessage), camera.x + window_width / 2, camera.y + 97 * window_height / 100)
	end
end