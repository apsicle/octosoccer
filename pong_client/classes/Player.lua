--Overview of class architecture:
--keep track of x, y, color, angle, collision group, hp, etc...

--Each class has AT LEAST 3 functions, which are called in order each round as so:
-- update() all objects: do all "status checks" and update self values accordingly. If you're dead, you're removed here.
-- move() all objects: calculate where you are going next. Check for a collision there if you are moving incredibly fast (ie. bullet or other ray classes),
-- otherwise, move there.

Player = {}

function Player.new (x, y, N, collision_group, active) 
	player = {}
	setmetatable(player, {__index = Player})
	player.x = x or love.graphics.getWidth() / 2
	player.y = y or love.graphics.getHeight() / 2
	player.N = N or 4
	player.radius = 16;
	player.speed = 3.5;
	player.damage = 0;
	player.angle = 0;
	player.z_index = 2;
	player.destination = {x = nil, y = nil}
	player.facing = "down"
	player.state = "standing"
	player.active = active
	player.isPlayer = true
	player.shooting = false
	player.hasBall = false
	player.collision_group = 1

	-- HUD status
	player.hp = 5
	player.max_hp = 5
	player.mp = {11, 11, 0, 0}
	player.max_mp = 100
	-- red, blue, green, purple

	-- SPRITES / ANIMATIONS
	player.sprite = love.graphics.newImage("sprites/octopus.png")
	player.x_offset = player.sprite:getHeight() / 2
	player.y_offset = player.sprite:getHeight() / 2

	player.global_index = add_object(global_obj_array, global_obj_pointer, player)

	return player
end

function Player:shoot()
	if self.hasBall then
		if self.shooting then
			mouse_x = love.mouse.getX()
			mouse_y = love.mouse.getY()
			ball:setDestination(mouse_x, mouse_y)
			ball.speed = 6
			ball.cooldown = 60
			ball.owner = nil
			self.shooting = false
			client:send("shoot", {speed = 6, x = mouse_x, y = mouse_y})
		end
	end
end

function Player:update()
	if self.active == true then
		--print_table(self.status:get_status('invincible'))
		if love.mouse.isDown(2) then
			mouse_x = love.mouse.getX()
			mouse_y = love.mouse.getY()
			self:setDestination(mouse_x, mouse_y)
		end
		if love.keyboard.isDown('q') then
			self.shooting = true
		end
		if self.shooting == true then
			if love.mouse.isDown(1) then
				self:shoot()
			end
		end
	end
end

function Player:move()

	-- Player controls. I figure I'll just put this on the first layer, ie. in update, so there's the least overhead as possible?
	-- Movement:
    if self.destination.x == nil and self.destination.y == nil then
    	return
    else
		move_constant_speed(self, self.destination.x, self.destination.y, self.speed)
	end

end

function Player:draw(i) 
	
	if i == 3 then
		love.graphics.draw(self.sprite, self.x, self.y, 0, 0.5, 0.5, self.x_offset*0.5, self.y_offset*0.5)
	end
end

function Player:check_collisions()
	circle_cast(self, radcheck)
end

function Player:resolve_collision(collider)

end

function love.keyreleased(key) 
	if key == "up" or key == "down" or key == "left" or key == "right" then
		self.state = "standing"
	end
end

function Player:setDestination(x, y)
	self.destination.x = x
	self.destination.y = y
end

function Player:setState(playerState)
	self.x = playerState.x
	self.y = playerState.y
	self.destination = playerState.destination
end

function Player:getState()
	return {x = self.x, y = self.y, destination = self.destination}
end