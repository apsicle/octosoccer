Button = {}

function Button.new(x, y, width, height)
	button = {}
	setmetatable(button, {__index = Button})
	button.x = x or 0
	button.y = y or 0
	button.width = width or 50
	button.height = height or 50
	button.action = action or function() end

	button.global_index = 
end