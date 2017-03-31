ChatLog = {}

function ChatLog.new()
	chatlog = {}
	setmetatable(chatlog, {__index = ChatLog})
	chatlog.typing = false
	chatlog.fadeTime = 5
	chatlog.messages = {}
	chatlog.messagePointer = 1
	chatlog.newMessage = {}
	chatlog.chars = {} --when keys shifted
	chatlog.chars["1"]="!";chatlog.chars["a"]="A";chatlog.chars["k"]="K";chatlog.chars["u"]="U";chatlog.chars["]"]="}"
	chatlog.chars["2"]="@";chatlog.chars["b"]="B";chatlog.chars["l"]="L";chatlog.chars["v"]="V";chatlog.chars["\\"]="|"
	chatlog.chars["3"]="#";chatlog.chars["c"]="C";chatlog.chars["m"]="M";chatlog.chars["w"]="W";chatlog.chars[";"]=":"
	chatlog.chars["4"]="$";chatlog.chars["d"]="D";chatlog.chars["n"]="N";chatlog.chars["x"]="X";chatlog.chars["'"]="\""
	chatlog.chars["5"]="%";chatlog.chars["e"]="E";chatlog.chars["o"]="O";chatlog.chars["y"]="Y";chatlog.chars[","]="<"
	chatlog.chars["6"]="^";chatlog.chars["f"]="F";chatlog.chars["p"]="P";chatlog.chars["z"]="Z";chatlog.chars["."]=">"
	chatlog.chars["7"]="&";chatlog.chars["g"]="G";chatlog.chars["q"]="Q";chatlog.chars["`"]="~";chatlog.chars["/"]="?"
	chatlog.chars["8"]="*";chatlog.chars["h"]="H";chatlog.chars["r"]="R";chatlog.chars["-"]="_";
	chatlog.chars["9"]="(";chatlog.chars["i"]="I";chatlog.chars["s"]="S";chatlog.chars["="]="+";
	chatlog.chars["0"]=")";chatlog.chars["j"]="J";chatlog.chars["t"]="T";chatlog.chars["["]="{";
	chatlog.logPointer = 1
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
	        if #myMessage > 0 then
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
    	local keystring = ""
    	-- if escape end and return
    	if key == "escape" then
    		self.typing = false
    		self.newMessage = {}
    		self.messagePointer = 1
    		return
    	end
    	-- otherwise, take the key and convert to the proper keystring
    	if key == "space" then
    		keystring = " "
    	elseif string.len(key) == 1 then
    		print(key)
    		if love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift") then
    			keystring = self.chars[key]
    		else
    			keystring = key
    		end
    	end

    	if keystring ~= "" then 
	    	self.newMessage[self.messagePointer] = keystring
	    	self.messagePointer = self.messagePointer + 1
	    end
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
	self.messages[self.logPointer] = {message = message, fadeTime = 5}
	self.logPointer = self.logPointer + 1
end

function ChatLog:draw()
	local count = 0
	if self.typing then
		for i = #self.messages, 1, -1 do
			local v = self.messages[i]
			if count < 10 then
				love.graphics.print(("%s: %s"):format(v.message.name, v.message.text), camera.x + window_width / 2, (camera.y + 94 * window_height / 100) - count * (window_height / 40))
				count = count + 1
			end
		end
		love.graphics.setColor(0,0,0, 128)
		love.graphics.rectangle('fill', camera.x + window_width / 2, camera.y + 97 * window_height / 100, 200, 20)
		love.graphics.setColor(255,255,255)
        local myMessage = ""
        for i = 1, #self.newMessage, 1 do
        	myMessage = myMessage .. tostring(self.newMessage[i])
        end
		love.graphics.print(("%s"):format(myMessage), camera.x + window_width / 2, camera.y + 97 * window_height / 100)
	else
		for i = #self.messages, 1, -1 do
			local v = self.messages[i]
			if v.fadeTime > 0 then
				love.graphics.print(("%s: %s"):format(v.message.name, v.message.text), camera.x + window_width / 2, (camera.y + 94 * window_height / 100) - count * (window_height / 40))
				count = count + 1
			end
		end
	end
end