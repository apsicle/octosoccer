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
			server:sendToAll("unpaused")
			self:reset()
			if self.callback then 
				self.callback()
				self.callback = nil
			end
		end
	end
end

function Pause:reset()
	self.time = 0
	self.active = false
end

function Pause:start(max, callback)
	server:sendToAll("paused")
	self.max = max
	self.active = true
	self.callback = callback
end