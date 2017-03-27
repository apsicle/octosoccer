Pause = {}

function Pause.new(max, callback)
	pause = {}
	setmetatable(pause, {__index = Pause})
	pause.time = 0
	pause.max = max
	pause.callback = callback
	pause.active = false
	return pause
end

function Pause:update(dt)
	if self.active then
		self.time = self.time + dt
		if self.time > self.max then
			if self.callback then 
				self.callback()
				self.callback = nil
			end
			self:reset()
		end
	end
end

function Pause:reset()
	self.time = 0
	self.active = false
end

function Pause:start(max, callback)
	self.max = max
	self.active = true
	self.callback = callback
end