-- Camera module shamelessly stolen from:
-- https://ebens.me/posts/cameras-in-love2d-part-1-the-basics
-- Thanks, Michael!

local M = { }


-- defines {{{
M.thisFrameWindowSizeX = 800
M.thisFrameWindowSizeY = 600
M.playerObj = nil
-- }}}

M.x = 0
M.y = 0
M.scaleX = 1
M.scaleY = 1
M.rotation = 0
M.currentBehaviorMode = "none"

-- list of camera behavior mode update functions {{{
local function centerPlayer()
  local adjustedCamPositionX = M.playerObj.getX() - ((M.thisFrameWindowSizeX / 2) * M.scaleX)
  local adjustedCamPositionY = M.playerObj.getY() - ((M.thisFrameWindowSizeY / 2) * M.scaleY)
  M.setPosition(adjustedCamPositionX, adjustedCamPositionY)
end

local function delayedFollowPlayer()

end
-- }}}

M.behaviorModes = {
  ["centerPlayer"] = centerPlayer,
  ["delayedFollowPlayer"] = delayedFollowPlayer
}

M.update = function (dt, player)
  M.thisFrameWindowSizeX, M.thisFrameWindowSizeY = love.graphics.getDimensions()
  M.playerObj = player
  if M.currentBehaviorMode ~= "none" then
    M.behaviorModes[M.currentBehaviorMode]()
  end
end

-- Set the camera's behavior mode. The mode determines what the camera will try to do automatically (follow player, etc.)
-- Behavior modes are functions called every update that decide what camera transforms to apply that frame.
-- The default mode is "none", meaning the camera will stay in one place and do nothing,
-- unless camera transformation functions are explicitly called elsewhere in the same update.
M.setBehaviorMode = function(newMode)
  M.currentBehaviorMode = newMode or "none"
end

-- `set` should be called in `love.draw()` before all of your drawcalls;
-- it's what applies all the transformations for the drawcalls.
-- Then, once you're done drawing everything that moves with the camera,
-- call `unset` to not use the camera's coordinate transforms anymore.
M.set = function()
  love.graphics.push()
  love.graphics.rotate(-M.rotation)
  love.graphics.scale(1 / M.scaleX, 1 / M.scaleY)
  love.graphics.translate(-M.x, -M.y)
end

M.unset = function()
  love.graphics.pop()
end

-- Gets the current mouse position, adjusted by the currently applied camera transformations.
-- You must use this instead of "get mouse location" calls whenever a camera transformation is applied!
-- Otherwise, Love won't account for the camera transforms and your aim will be offset.
-- Does not account for rotation! Some more complex vector rotation will be needed for that.
M.getCameraRelativeMousePos = function()
  return love.mouse.getX() * M.scaleX + M.x, love.mouse.getY() * M.scaleY + M.y
end

-- Returns the X and Y value of arbitrary world coordinates, adjusted by the current camera transformations.
M.getCameraAdjustedWorldPosition = function(worldPosX, worldPosY)
  return worldPosX * M.scaleX + M.x, worldPosY * M.scaleY + M.y
end

-- All the functions below this point should only be called in `love.update()`,
-- and are used to manipulate the camera.
-- ==============================================

-- Move the camera by dx and dy pixels.
-- Remember that Y increases positively moving down, not up.
M.move = function(dx, dy)
  M.x = M.x + (dx or 0)
  M.y = M.y + (dy or 0)
end

-- Probably won't use this, but if we need it...
-- M.rotate = function(dr)
--   M.rotation = M.rotation + dr
-- end

M.scale = function(sx, sy)
  sx = sx or 1
  M.scaleX = M.scaleX * sx
  M.scaleY = M.scaleY * (sy or sx)
end

M.setPosition = function(x, y)
  M.x = x or M.x
  M.y = y or M.y
end

M.setScale = function(sx, sy)
  M.scaleX = sx or M.scaleX
  M.scaleY = sy or M.scaleY
end

return M
-- vim: foldmethod=marker
