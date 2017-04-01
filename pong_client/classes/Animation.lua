Animation = {}

function Animation.new(image, x, y, rate, lifetime, onLoop)
	animation = {}
	setmetatable(animation, {__index = Animation})
	animation.x = x
	animation.y = y
	animation.rate = rate or 10
	animation.image = image
	animation.x_offset = animation.image:getHeight() / 2
	animation.y_offset = animation.image:getHeight() / 2
	animation.onLoop = onLoop or "pauseAtEnd"
	animation.lifetime = lifetime or rate
	animation.object = create_animation(animation.image, animation.rate, animation.onLoop)
	animation.global_index = add_object_animation(global_animation_array, global_animation_pointer, animation)
end

function Animation:update(dt)
	self.object:update(1)
	self.lifetime = self.lifetime - dt
	if self.lifetime < 0 then
		self:removeSelf()
	end
end

function Animation:draw()
	self.object:draw(self.image, self.x, self.y, 0, 1, 1, self.x_offset, self.y_offset)
end

function Animation:removeSelf()
	global_animation_array[self.global_index] = nil
end