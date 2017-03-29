Animation = {}

function Animation.new(x, y, image)
	animation = {}
	setmetatable(animation, {__index = Animation})
	animation.x = x
	animation.y = y
	animation.image = image
	animation.object = create_animation(animation.image, )

	animation.global_index = add_object(global_obj_array, global_obj_pointer, animation)
end

function Animation:update(dt)
	animation.object:update(1)