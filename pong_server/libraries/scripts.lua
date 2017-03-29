--Collision groups: 0 - items/pickupable, 1 - player, 2 - standard enemies 
function add_object(array, pointer, object)
	--inserts an object in an table and returns the index at which it was inserted
	table.insert(array, pointer, object)
	global_obj_pointer = global_obj_pointer + 1;
	return pointer
end


function blend_colors(rgb1, rgb2, t)
	-- sqrt( [1-t]*rgb1^2 + [t]*rgb2^2)
	rgb3 = {}
	local t = t or 0.5;
	for key, value in pairs(rgb1) do
		color1 = value;
		color2 = rgb2[key];

		color3 = math.sqrt( (1-t)*color1*color1 + (t)*color2*color2 )

		table.insert(rgb3, color3)
	end
	return rgb3;
end


function check_collision(object) 
	if object.ray_class ~= nil then
		return raycast(object, object.d, object.e)
	else
	end
end

function circle_cast(self, collision_func, return_objs)
	-- use radcheck or in_my_radius. radcheck = if dist between < both radii combined then collide. In_my_radius = ... in your radius.
	local collidable_objs = {}
	local collided_objs = {}

	--Defaults to false. If this is true, this function does not perform collisions but instead
	--returns a table of objects you collided with and assumes you want to do special collision effects.
	local return_objs = return_objs or false


	--Find objects that can be collided with
	for key, value in pairs(global_obj_array) do
		if value ~= nil then
			table.insert(collidable_objs, value)
		end
	end

	--Check if you really did collide with them
	for key, value in pairs(collidable_objs, value) do
		if collision_func(self, value) then
			if return_objs == true then
				table.insert(collided_objs, value)
			else
				collide(self, value)
			end
		end
	end
	return collided_objs
end


function clamp(min, max, num)
	return math.max(math.min(num, max), min)
end

function Class(...)
	--takes 0 or 1 meaningful argument.
	--if given a class object, will return a class that inherits all metamethods and init values from that class.

	local t = {n=select('#',...),...}
	d_class = {}
	if t.n ~= 0
		then

		for k, v in pairs(t[1]) do
	  		d_class[k] = v
		end

		d_class.__index = d_class

		setmetatable(d_class, {
			__call = function(cls, ...)
				local self = setmetatable({}, cls)
				self:_init(...)
				return self
			end,
		})

		function d_class:_init(...)
			t[1]._init(self, ..., true)
			return
		end
	end
	

	return d_class
end

function clear_all(...)
	-- clears global object array except for player
	local t = {n=select('#', ...), ...}
	for ind, value in pairs(global_obj_array) do
		if value ~= player then
		global_obj_array[ind] = nil
		end
	end
end

function collide(obj_a, obj_b)
	obj_a:resolve_collision(obj_b)
	obj_b:resolve_collision(obj_a)
	return
end

function color_index(color) 
	for i, value in pairs(global_palette) do
		if color == value then
			return i
		end
	end
	return nil
end

function create_animation(image, rate)
	-- takes in a newImage var from love and a rate. Lower rate = faster animation
	local grid = anim8.newGrid(image:getHeight(), image:getHeight(), image:getWidth(), image:getHeight())
  	local animation = anim8.newAnimation(grid(tostring(1) .. '-' .. tostring(image:getWidth() / image:getHeight()),1), rate)
  	return animation
end

function distance_coord_sq(x1, y1, x2, y2) 
	return sq(x2 - x1) + sq(y2 - y1)
end

function distance_coord(x1, y1, x2, y2)
	return math.sqrt(sq(x2 - x1) + sq(y2 - y1))
end

function distance_obj_sq(obj1, obj2)
	return sq(obj1.x - obj2.x) + sq(obj1.y - obj2.y)
end

function distance_obj(obj1, obj2)
	return math.sqrt(sq(obj1.x - obj2.x) + sq(obj1.y - obj2.y))
end

function in_my_radius(self, obj)
	if distance_obj_sq(self, obj) < (sq(self.radius)) then
		return true
	end
	return false
end

function in_range(num, i, j)
	return i <= num and j >= num 
end

function map(func, array)
  local new_array = {}
  for i,v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end

function move_constant_speed(self, x2, y2, speed, dt)
	--for when you know only the magnitude to travel, and do not have access to vectorized (x, y) movement.
	local x_dist = x2 - self.x
	local y_dist = y2 - self.y
	local dt = dt or 1

	-- stops the movement at a certain distance from the other object for sanity's sake also because there's weird twitching when you don't do this.
	if sq(x_dist) + sq(y_dist) > 10 then
		
		-- if one or both of the displacements is 0 then the algorithm goes wonky because the divide by 0, so this covers that.
		if x_dist == 0 then
			if y_dist == 0 then
				return false
			else
				self.y = self.y + sign(y_dist)*speed
				return true
			end
		elseif	y_dist == 0 then
			self.x = self.x + sign(x_dist)*speed
			return true
		end
	
		-- Otherwise, move x and y proportionally according to speed.
		local k = y_dist / x_dist
		local theta = math.atan2(y_dist, x_dist);
		local a = math.sin(theta) * speed * dt
		local b = a / k
		self.x = self.x + b
		self.y = self.y + a;
		return true;
	end
	return false;
end

function move_to_obj(obj_a, obj_b)
	obj_a.x = obj_b.x
	obj_a.y = obj_b.y
end

function on_tile(obj, x, y)
	return in_range(obj.x, x * 32, x * 32 + 32) and in_range(obj.y, y * 32, y * 32 + 32)
end

function place_player()
	local direction = player.facing
	if direction == 'right' then
        --move to left side of map
        player.x = 0
        player.y = (global_height_tiles - 1)*32 / 2
    elseif direction == 'down' then
        --move to top of map
        player.x = (global_width_tiles - 1) * 32 / 2
        player.y = 0
    elseif direction == 'left' then
        --move to right of map
        player.x = (global_width_tiles - 1) * 32
        player.y = (global_height_tiles - 1) * 32 / 2
    elseif direction == 'up' then
        --move to bottom of map
        player.x = (global_width_tiles - 1) * 32 / 2
        player.y = (global_height_tiles - 1) * 32
    end
end

function print_table(table)
	print("PRINTING - ", table)
	for i, v in pairs(table) do
		print(i, v)
	end
	if(#table == 0) then
		print('Table is empty!')
	end
end

function radcheck(self, obj)
	if distance_obj_sq(self, obj) < (sq(self.radius) + sq(obj.radius)) then
		return true
	end
	return false
end

function raycast(self, d, e)
	-- raycast from an object
	local x_0 = self.x;
	local y_0 = self.y;
	local x_1 = self.x + d;
	local y_1 = self.y + e;

	--[[Parametric equations for bullet trajectory:
	Eq(1): x_1 = d*t + x_0
	Eq(2): y_1 = e*t + y_0
	where equations are parameterized by t and x_0 and y_0 is the starting point of the ray

	Equation for the object to check collision with is a circle:
	Eq(3): (x-h)^2 + (y-k)^2 = r^2

	Plugging eq(1) and (2) into Eq(3) for x and y is asserting that point (x_1, y_1) is on the circle 
	described by eq(3), ie. it intersects it. This results in equation 4 in one variable, t.
	Eq(4): (d^2 + e^2)t^2 + (-2dh + 2dx_0 - 2ek + 2ey_0)t + (x_0^2 + h^2 - 2x_0h + y_0^2 + k^2 - 2y_0k - r^2) = 0

	This is a polynomial in standard form At^2 + Bt + C = 0. To find the roots we apply the quadratic equation.
	There is no intersection when the discriminant is <0 (total miss), or t > 1 (since we travel t = 1 units at a time).
	If 0 < t <= 1, then we are about to hit the object, and we call the collision script. If t < 0, then the object is behind us
	or we are already inside it.
	]] 
	
	local collidable_objs = {}
	for key, value in pairs(global_obj_array) do
		if value.noncollidable == nil then
			if (value.collision_group ~= self.collision_group) then
			-- if any of these except 'else', don't even try to collide


				if value.is_shard ~= nil then


				elseif value.status ~= nil then
					if value.status:check_status("jaunted") then
					end


				else
					--you may be able to collide, but check here.
					if value.color ~= self.color then
						table.insert(collidable_objs, value)
					end
				end
			end
		end
	end

	local min_t = math.huge
	local colliding_obj = nil

	for key, value in pairs(collidable_objs) do
		local h = value.x
		local k = value.y
		local r = value.radius

		local A = d*d + e*e;
		local B = 2*(-d*h + d*x_0 - e*k + e*y_0)
		local C = x_0*x_0 + h*h - 2*x_0*h + y_0*y_0 + k*k - 2*y_0*k - r*r

		local discriminant = B*B - 4*A*C

		if discriminant > 0 then
			local t_0 = (-B + math.sqrt(discriminant)) / (2*A)
			local t_1 = (-B - math.sqrt(discriminant)) / (2*A)
			if sign(t_0) == -1 then
				t_0 = math.huge
			end
			if sign(t_1) == -1 then
				t_1 = math.huge
			end
			if min_t > math.min(t_0, t_1) then
				min_t = math.min(t_0, t_1)
				colliding_obj = value
			end
		end
	end

	return colliding_obj, min_t
end

function green_red_gradient(a, b)
	-- returns the color at step a along the gradient 0, 255, 0 to 255, 0, 0
	-- where there are a total of b steps. Note this is an HSV gradient algorithm
	local r = 0
	local g = 255
	local blue = 0
	local total_steps = b
	local step_size = 510 / total_steps

	local to_r = math.min(a, b / 2) * step_size
	local from_g = math.max(0, a - b / 2) * step_size
	local r = r + to_r
	local g = g - from_g

	return r, g, blue
end

function sample(arr) 
	sum = 0
	my_rand = love.math.random()
	for i, val in pairs(arr) do
		sum = sum + val[2]
		if my_rand <= sum then
			return val[1]
		end
	end
end

function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

function sq(num)
	return num * num
end
