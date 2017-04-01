--[[
Simple Menu Library
by nkorth

Requires: love2d
Recommended: hump.gamestate

Public Domain - feel free to hack and redistribute this as much as you want.
]]--
return {
	new = function(parent, inputScreen)
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
		return {
			parent = parent,
			items = {},
			inputScreen = inputScreen or false,
			newInput = {},
			chars = chars,
			inputPointer = 1,
			selected = 1,
			animOffset = 0,
			addItem = function(self, item)
				table.insert(self.items, item)
			end,
			update = function(self, dt)
				self.animOffset = self.animOffset / (1 + dt*10)
			end,
			draw = function(self, x, y)
				if inputScreen then
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
				else
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
			end,
			keypressed = function(self, key)
				if in_menu then
					-- if its an input screen, accepting text input is your job
					if self.inputScreen then
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
								active_menu = main_menu
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
							local keystring = key
							if key == "space" then
								keystring = " "
							end
						end
					else
					-- if not, the key inputs are used to scroll along the menu
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
							active_menu = self.parent
							if active_menu == main_menu then
								in_menu = false
							end
						end
					end
				else
					if key == 'escape' then
						in_menu = true
						active_menu = main_menu
					else
						return false
					end
				end
				-- if this returns true, it means the keyboard input was consumed by the menu
				return true
			end
		}
	end
}