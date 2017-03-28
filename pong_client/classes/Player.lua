--Overview of class architecture:
--keep track of x, y, color, angle, collision group, hp, etc...

--Each class has AT LEAST 3 functions, which are called in order each round as so:
-- update() all objects: do all "status checks" and update self values accordingly. If you're dead, you're removed here.
-- move() all objects: calculate where you are going next. Check for a collision there if you are moving incredibly fast (ie. bullet or other ray classes),
-- otherwise, move there.

Player = {}

function Player.new (x, y, collision_group, active) 
	player = {}
	setmetatable(player, {__index = Player})
	player.x = x or love.graphics.getWidth() / 2
	player.y = y or love.graphics.getHeight() / 2
	player.radius = 16;
	player.speed = 3.5;
	player.angle = 0;
	player.destinationAngle = 0;
	player.z_index = 2;
	player.destination = {x = nil, y = nil}
	player.facing = "down"
	player.state = "standing"
	player.active = active
	player.isPlayer = true
	player.turnRate = (2*math.pi)
	player.shooting = false
	player.hasBall = false
	player.collision_group = 1

	-- SPRITES / ANIMATIONS
	player.sprite = love.graphics.newImage("sprites/octopus.png")
	player.x_scale = 0.5
	player.y_scale = 0.5
	player.x_offset = (player.sprite:getHeight() / 2)
	player.y_offset = (player.sprite:getHeight() / 2)

	player.global_index = add_object(global_obj_array, global_obj_pointer, player)

	return player
end

function Player:shoot()
	if self.hasBall then
		if self.shooting then
			mouse_x = camera:getMouseX()
			mouse_y = camera:getMouseY()
			ball:setDestination(mouse_x, mouse_y)
			ball.speed = 250
			ball.cooldown = 1
			ball.owner = nil
			self.shooting = false
			self.hasBall = false
			pass1:play()
			client:send("shoot", {speed = ball.speed, x = mouse_x, y = mouse_y, id = self.id})
		end
	end
end

function Player:keypressed(key)
	if key == 'q' then
		self.shooting = true
	end
end

function Player:mousepressed(mouse)
	print(mouse)
	if mouse == 2 then
		mouse_x = camera:getMouseX()
		mouse_y = camera:getMouseY()
		self:setDestination(mouse_x, mouse_y)
		client:send("clientDestination", {id = self.id, x = mouse_x, y = mouse_y})
	end
	if mouse == 1 then
		if self.shooting == true then
			self:shoot()
		end
	end
end

function Player:update(dt)
	--f self.active == true then
		--print_table(self.status:get_status('invincible'))
	--[[if math.abs(self.destinationAngle - self.angle) > 2*math.pi / 360 then
		local smaller = math.min(self.destinationAngle, self.angle)
		local larger = math.max(self.destinationAngle, self.angle)
		local diff_1 = larger - smaller
		local diff_2 = 2 * math.pi - diff_1
		local min_diff = math.min(diff_1, diff_2)
		if math.abs((self.angle + min_diff) % (2 * math.pi) - self.destinationAngle) > 2*math.pi / 360 then
			self.angle = self.angle + self.turnRate * dt
		else
			self.angle = self.angle - self.turnRate * dt
		end
	end]]--
	if self.turning ~= nil then
		if self.turning == "clockwise" then
			--turn clockwise (the shorter side) until that fact is no longer true
			if (self.angle - self.destinationAngle) % (2*math.pi) < math.pi then
				self.angle = (self.angle - self.turnRate * dt) % (2*math.pi)
			else
				self.turning = nil
			end
		else
			--turn counterclockwise
			if (self.destinationAngle - self.angle) % (2*math.pi) < math.pi then
				self.angle = (self.angle + self.turnRate * dt) % (2*math.pi)
			else
				self.turning = nil
			end
		end
	end
end

function Player:move(dt)

	-- Player controls. I figure I'll just put this on the first layer, ie. in update, so there's the least overhead as possible?
	-- Movement:
    if self.destination.x == nil and self.destination.y == nil then
    	return
    else
		if not move_constant_speed(self, self.destination.x, self.destination.y, self.speed) then
			self.destination.x = nil
			self.destination.y = nil
		end
	end
end

function Player:draw(i) 
	
	if i == 3 then
		love.graphics.draw(self.sprite, self.x, self.y, self.angle, self.x_scale, self.y_scale, self.x_offset, self.y_offset)
	end
end

function Player:check_collisions()
	circle_cast(self, radcheck)
end

function Player:resolve_collision(collider)

end

function love.keyreleased(key) 
end

function Player:setDestination(x, y)
	self.destination.x = x
	self.destination.y = y
	self.destinationAngle = math.atan2(y - self.y, x - self.x)

	-- this expression gives the clockwise angle between a and b
	if (self.angle - self.destinationAngle) % (2*math.pi) < math.pi then
		self.turning = "clockwise"
	else
		self.turning = "counterclockwise"
	end
end

function Player:setState(playerState)
	self.x = playerState.x
	self.y = playerState.y
	self.destination = playerState.destination
	self.hasBall = playerState.hasBall
	self.angle = playerState.angle
end

function Player:getState()
	return {x = self.x, y = self.y, destination = self.destination, hasBall = self.hasBall, angle = self.angle}
end