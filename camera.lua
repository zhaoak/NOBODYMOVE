-- Camera module shamelessly stolen from:
-- https://ebens.me/posts/cameras-in-love2d-part-1-the-basics
-- Thanks, Michael!

local M = { }

-- defines {{{
M.thisFrameWindowSizeX = 800
M.thisFrameWindowSizeY = 600
M.playerObj = nil
M.followAimMaxOffsetDistance = 500 -- how far cam is allowed to move from player in "followAim" mode
-- }}}

M.x = 0 -- current x pos of camera
M.y = 0 -- current y pos of camera
M.targetXPos = nil -- target x pos of camera, only used in specific behavior modes
M.targetYPos = nil -- target y pos of camera, only used in specific behavior modes
M.maxPanSpeed = 3 -- how fast camera is allowed to move on each axis per second
M.scaleX = 1
M.scaleY = 1
M.rotation = 0
M.currentBehaviorMode = "none"

-- list of camera behavior mode update functions {{{
-- keep camera centered on player perfectly at all times
local function centerPlayer()
  local adjustedCamPositionX = M.playerObj.getX() - ((M.thisFrameWindowSizeX / 2) * M.scaleX)
  local adjustedCamPositionY = M.playerObj.getY() - ((M.thisFrameWindowSizeY / 2) * M.scaleY)
  M.setPosition(adjustedCamPositionX, adjustedCamPositionY)
end

-- follow player, but pan toward their aim, up to a limited distance away from the player
local function followAim()
  -- find camera position where player is perfectly centered
  local adjustedCamPositionX = M.playerObj.getX() - ((M.thisFrameWindowSizeX / 2) * M.scaleX)
  local adjustedCamPositionY = M.playerObj.getY() - ((M.thisFrameWindowSizeY / 2) * M.scaleY)
  -- get distance between player center and crosshair location
  local aimDistance = math.sqrt((M.playerObj.crosshairCacheX - M.playerObj.getX())^2 + (M.playerObj.crosshairCacheY - M.playerObj.getY())^2)
  -- find whether it's farther or closer than the max leashing distance
  -- whichever is smaller, use that value as the camera distance offset
  local offsetDistance = math.min(M.followAimMaxOffsetDistance, aimDistance)
  local angle
  -- make positive y up and negative y down, for ease of calculations
  angle = M.playerObj.currentAimAngle + math.pi
  -- then calculate the offset for X and Y axes
  local camOffsetX, camOffsetY
  if angle <= 0 then
    camOffsetX = math.sin(angle)*offsetDistance*(offsetDistance/M.thisFrameWindowSizeX)
    camOffsetY = math.cos(angle)*offsetDistance*(offsetDistance/M.thisFrameWindowSizeY)
  else
    camOffsetX = math.sin(angle)*offsetDistance*-1*(offsetDistance/M.thisFrameWindowSizeX)
    camOffsetY = math.cos(angle)*offsetDistance*-1*(offsetDistance/M.thisFrameWindowSizeY)
 end
  M.panToPosition(adjustedCamPositionX+camOffsetX, adjustedCamPositionY+camOffsetY, 5)
end
-- }}}

M.behaviorModes = {
  ["centerPlayer"] = centerPlayer,
  ["followAim"] = followAim,
}

M.update = function (dt, player)
  M.thisFrameWindowSizeX, M.thisFrameWindowSizeY = love.graphics.getDimensions()
  M.playerObj = player
  if M.currentBehaviorMode ~= "none" then
    M.behaviorModes[M.currentBehaviorMode]()
  end
  if M.targetXPos ~= nil and M.targetYPos ~= nil then
    -- pan camera towards target position
    M.x = (M.targetXPos-M.x)*(M.maxPanSpeed*dt)+M.x
    M.y = (M.targetYPos-M.y)*(M.maxPanSpeed*dt)+M.y
  end
end

-- Set the camera's behavior mode. The mode determines what the camera will try to do automatically (follow player, etc.)
-- Behavior modes are functions called every update that decide what camera transforms to apply that frame.
-- The default mode is "none", meaning the camera will stay in one place and do nothing,
-- unless camera transformation functions are explicitly called elsewhere in the same update.
-- args:
-- newMode(string): the new mode string, used as a key to find the correct function
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

-- pan the camera to a target position, moving at a max of maxPanSpeed pixels per second
M.panToPosition = function(xTarget, yTarget, maxPanSpeed)
  M.targetXPos = xTarget
  M.targetYPos = yTarget
  M.maxPanSpeed = maxPanSpeed
end

-- immediately set the camera to a specific world coordinate position
M.setPosition = function(x, y)
  M.x = x or M.x
  M.y = y or M.y
  M.targetXPos = nil
  M.targetYPos = nil
end

M.setScale = function(sx, sy)
  M.scaleX = sx or M.scaleX
  M.scaleY = sy or M.scaleY
end

return M
-- vim: foldmethod=marker
