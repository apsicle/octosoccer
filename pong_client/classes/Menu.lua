--[[
Simple Menu Library
by nkorth

Requires: love2d
Recommended: hump.gamestate

Public Domain - feel free to hack and redistribute this as much as you want.
]]--
function Screen(parent, screenType)
	-- Define new screen types in code here.
	-- all features, update, draw, attributes, can be customized within a screenType.

	if screenType == "nameInput" then
		chars = {}
		chars["1"]="!";chars["a"]="A";chars["k"]="K";chars["u"]="U";chars["]"]="}"
		chars["2"]="@";chars["b"]="B";chars["l"]="L";chars["v"]="V";chars["\\"]="|"
		chars["3"]="#";chars["c"]="C";chars["m"]="M";chars["w"]="W";chars[";"]=":"
		chars["4"]="$";chars["d"]="D";chars["n"]="N";chars["x"]="X";chars["'"]="\""
		chars["5"]="%";chars["e"]="E";chars["o"]="O";chars["y"]="Y";chars[","]="<"
		chars["6"]="^";chars["f"]="F";chars["p"]="P";chars["z"]="Z";chars["."]=">"
		chars["7"]="&";chars["g"]="G";chars["q"]="Q";chars["`"]="~";chars["/"]="?"
		chars["8"]="*";chars["h"]="H";chars["r"]="R";chars["-"]="_";
		chars["9"]="(";chars["i"]="I";chars["s"]="S";chars["="]="+";
		chars["0"]=")";chars["j"]="J";chars["t"]="T";chars["["]="{";
		draw = function(self, x, y)
			local height = window_height / 20
			local width = window_width / 6
			local myInput = ""
	        for i = 1, #self.newInput, 1 do
	        	myInput = myInput .. tostring(self.newInput[i])
	        end
	        love.graphics.print('Input below, press enter when finished', window_width / 2 - width / 2 - 100, window_height / 4 - height / 2 - 50, 0, 2, 2)
			love.graphics.setColor(0, 0, 0, 192)
			love.graphics.rectangle('fill', window_width / 2 - width / 2, window_height / 4 - height / 2, width, height)
			love.graphics.setColor(255,255,255)
			love.graphics.print(myInput, window_width / 2 - width / 2, window_height / 4 - height / 2)
		end
		keypressed = function(self, key)
			if in_menu then
				if key == 'return' then
					if #self.newInput > 0 then
						local myInput = ""
				        for i = 1, #self.newInput, 1 do
				        	myInput = myInput .. tostring(self.newInput[i])
				        end
						options.player_name = myInput
						write_options()
						if connected then
							players[playerNumber].name = myInput
							client:send("clientNameChange", {id = playerNumber, name = myInput})
						end
						self.newInput = {}
						self.inputPointer = 1
						active_menu = main_menu
					end
				elseif key == "backspace" then
			    	-- if your message is at least 1 long then delete the last character
			        if #self.newInput > 0 then 
			        	self.newInput[self.inputPointer - 1] = nil; 
			        	self.inputPointer = self.inputPointer - 1  
			        end
				else
					local keystring = ""
			    	-- if escape end and return
			    	if key == "escape" then
			    		self.newInput = {}
						self.inputPointer = 1
						active_menu = self.parent
			    	end
			    	-- otherwise, take the key and convert to the proper keystring
			    	if key == "space" then
			    		keystring = " "
			    	elseif string.len(key) == 1 then
			    		if love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift") then
			    			keystring = self.chars[key]
			    		else
			    			keystring = key
			    		end
			    	end

			    	if keystring ~= "" then 
				    	self.newInput[self.inputPointer] = keystring
				    	self.inputPointer = self.inputPointer + 1
				    end
				end
			else
				if key == 'escape' then
					in_menu = true
				else
					return false
				end
			end
			return true
		end
	elseif screenType == "standard" then
		draw = function(self, x, y)
			local height = 20
			local width = 150
			
			love.graphics.setColor(255, 255, 255, 128)
			if #self.items > 0 then
				love.graphics.rectangle('fill', x, y + height*(self.selected-1) + (self.animOffset * height), width, height)
			end

			for i, item in ipairs(self.items) do
				if self.selected == i then
					love.graphics.setColor(255, 255, 255)
				else
					love.graphics.setColor(255, 255, 255, 128)
				end
				love.graphics.print(item.name, x + 5, y + height*(i-1) + 5)
			end
		end
		keypressed = function(self, key)
			-- if not, the key inputs are used to scroll along the menu
			if in_menu then
				if key == 'up' then
					if self.selected > 1 then
						self.selected = self.selected - 1
						self.animOffset = self.animOffset + 1
					else
						self.selected = #self.items
						self.animOffset = self.animOffset - (#self.items-1)
					end
				elseif key == 'down' then
					if self.selected < #self.items then
						self.selected = self.selected + 1
						self.animOffset = self.animOffset - 1
					else
						self.selected = 1
						self.animOffset = self.animOffset + (#self.items-1)
					end
				elseif key == 'return' then
					if self.items[self.selected].action then
						self.items[self.selected]:action()
					end
				elseif key == 'escape' then
					if active_menu == main_menu then
						in_menu = false
					end
					active_menu = self.parent
				end
			else
				if key == 'escape' then
					in_menu = true
				else
					return false
				end
			end
			return true
		end
	elseif screenType == "serverList" then
		draw = function(self, x, y)
			local height = window_height / 2
			local width = window_width / 2
			local x = (window_width - width) / 2
			local y = (window_height - height) / 2
			local count = 0

			-- draw the box containing the listings
			love.graphics.setColor(128, 128, 128, 128)
			love.graphics.rectangle("fill", x, y, width, height)

			-- draw the listings starting at the top left corner of the server box.
			love.graphics.setColor(255, 255, 255)
		    for i, v in ipairs(serverList) do
		        local server = ("Server IP: %s - Port: %d"):format(v.ip, v.port)
		        love.graphics.print(server, x + 15, y + 15 + count * 20)
		        if self.selected and self.selected == (count + 1) then
		        	-- draw the box highlighting the current selection
		        	love.graphics.setColor(255, 255, 255, 128)
		        	love.graphics.rectangle("fill", x + 15, y + 15 + count * 20, width, 20)
		        	love.graphics.setColor(255, 255, 255)
		        end
		    end
		    if #serverList == 0 then
		    	love.graphics.print("No games found", x + 15, y + 15 + count * 20)
		    end

		    -- draw the buttons for "Refresh" and "Connect"
		    love.graphics.setColor(128, 128, 128, 192)
		    love.graphics.rectangle("fill", x + 100, y + height - 50, 150, 50)
		    love.graphics.rectangle("fill", x + width - 250, y + height - 50, 150, 50)
		    love.graphics.setColor(255, 255, 255, 192)
		    love.graphics.print("Refresh", x + 115, y + height - 35)
		    love.graphics.print("Connect", x + width - 235, y + height - 35)
		end
		mousepressed = function(self, x, y, mouse)
			local height = window_height / 2
			local width = window_width / 2
			-- this is the topleft corner of the server list box
			local x2 = (window_width - width) / 2
			local y2 = (window_height - height) / 2
			if mouse == 1 then
				local count = 0
				for i, v in ipairs(serverList) do
					if in_rectangle(x, y, x2, y2 + count * 20, 100, 20) then
						self.selectedServer = v
						self.selected = count + 1
						count = count + 1
						return true
					end
				end
				--if in_rectangle(x, y, )
			end
			return true
		end

		keypressed = function(self, key)
			-- if not, the key inputs are used to scroll along the menu
			if in_menu then
				if key == 'up' then
					if self.selected > 1 then
						self.selected = self.selected - 1
						self.animOffset = self.animOffset + 1
					else
						self.selected = #self.items
						self.animOffset = self.animOffset - (#self.items-1)
					end
				elseif key == 'down' then
					if self.selected < #self.items then
						self.selected = self.selected + 1
						self.animOffset = self.animOffset - 1
					else
						self.selected = 1
						self.animOffset = self.animOffset + (#self.items-1)
					end
				elseif key == 'return' then
					if self.items[self.selected].action then
						self.items[self.selected]:action()
					end
				elseif key == 'escape' then
					if active_menu == main_menu then
						in_menu = false
					end
					active_menu = self.parent
				end
			else
				if key == 'escape' then
					in_menu = true
				else
					return false
				end
			end
			return true
		end
	end

	return {
		parent = parent,
		items = {},
		newInput = {},
		inputPointer = 1,
		chars = chars,
		selected = 1,
		animOffset = 0,
		addItem = function(self, item)
			table.insert(self.items, item)
		end,
		update = update or function(self, dt)
			self.animOffset = self.animOffset / (1 + dt*10)
		end,
		draw = draw,
		keypressed = keypressed,
		mousepressed = mousepressed or function(self, x, y, mouse) return true; end
	}
end

return {
	new = function(parent, screenType)
		return Screen(parent, screenType)
	end
}