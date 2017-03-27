Camera = {}

function Camera.new()
  camera = {}
  setmetatable(camera, {__index = Camera})
  camera.x = 0
  camera.y = 0
  camera.scaleX = 1
  camera.scaleY = 1
  camera.rotation = 0
  camera.panSpeed = 1000
  return camera
end

function Camera:set()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(self.scaleX, self.scaleY)
  love.graphics.translate(-self.x, -self.y)
end

function Camera:unset()
  love.graphics.pop()
end

function Camera:update(dt)
  --[[
  local value = {x = love.mouse.getX(), y = love.mouse.getY()}
  if value.x > window_width - 32 then
      self:move(self.panSpeed * dt, 0)
  end
  if value.y > window_height - 32 then
      self:move(0, self.panSpeed * dt)
  end
  if value.x < 0 + 32 then
      self:move(-self.panSpeed * dt, 0)
  end
  if value.y < 0 + 32 then
      self:move(0, -self.panSpeed * dt)
  end
  --]]
  if love.keyboard.isDown('left') then
    self:move(-self.panSpeed * dt, 0)
  end
  if love.keyboard.isDown('right') then
    self:move(self.panSpeed * dt, 0)
  end
  if love.keyboard.isDown('up') then
    self:move(0, -self.panSpeed*dt)
  end
  if love.keyboard.isDown('down') then
    self:move(0, self.panSpeed*dt)
  end
end

function Camera:move(dx, dy)
  self.x = self.x + (dx or 0)
  self.y = self.y + (dy or 0)
end

function Camera:rotate(dr)
  self.rotation = self.rotation + dr
end

function Camera:scale(sx, sy)
  sx = sx or 1
  self.scaleX = self.scaleX * sx
  self.scaleY = self.scaleY * (sy or sx)
end

function Camera:getMouseX()
  return self.x + love.mouse.getX() * 1/self.scaleX
end

function Camera:getMouseY()
  return self.y + love.mouse.getY() * 1/self.scaleY
end

function Camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function Camera:setScale(sx, sy)
  self.scaleX = sx or self.scaleX
  self.scaleY = sy or self.scaleY
end