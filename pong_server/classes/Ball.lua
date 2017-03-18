Ball = {}

function Ball.new () 
	ball = {}
	setmetatable(ball, {__index = Ball})
	ball.x = x or love.graphics.getWidth() / 2
	ball.y = y or love.graphics.getHeight() / 2
	ball.vx = 0
	ball.vy = 0
	ball.radius = 5;
	ball.ax = 0
	ball.ay = 0
	ball.speed = 0
	ball.angle = 0;
	ball.owner = nil;
	ball.z_index = 2;
	ball.cooldown = 60;
	ball.destination = {x = nil, y = nil}
	ball.collision_group = 1


	-- SPRITES / ANIMATIONS
	ball.sprite = love.graphics.newImage("sprites/ball.png")
	ball.x_offset = ball.sprite:getHeight() / 2
	ball.y_offset = ball.sprite:getHeight() / 2

	ball.global_index = add_object(global_obj_array, global_obj_pointer, ball)

	return ball
end

function Ball:update()
	self.cooldown = self.cooldown - 1;
	self:check_collisions()
end

function Ball:move()
	if self.owner ~= nil then
		self.x = self.owner.x
		self.y = self.owner.y
	end
	if self.destination.x == x and ball.destination.y == nil then
		return
	else
		move_constant_speed(self, self.destination.x, self.destination.y, self.speed)
	end
end

function Ball:draw()
	love.graphics.draw(self.sprite, self.x, self.y, 0, 0.025, 0.025, self.x_offset * 0.025, self.y_offset * 0.025)
end

function Ball:check_collisions()
	circle_cast(self, radcheck)
end

function Ball:resolve_collision(collider)
	if collider.isPlayer ~= nil then
		if self.cooldown <= 0 then
			collider.hasBall = true
			self.owner = collider
			self.cooldown = 60
		end
	end
end

function Ball:setDestination(x, y)
	self.destination.x = x
	self.destination.y = y
end
