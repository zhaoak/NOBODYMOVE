-- this file's code integrated into playfield.lua -- this file is no longer used
local M = { }

M.color = {1,1,1,1}

M.setup = function (world) -- {{{
  M.world = world -- stash for laters
  if M.body then M.body:destroy() end

  -- create platform
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  M.body = love.physics.newBody(M.world, windowSizeX/3, windowSizeY/2, "static")
  M.shape = love.physics.newRectangleShape(0, 0, windowSizeX/3, windowSizeY/5, 50)
  M.fixture = love.physics.newFixture(M.body, M.shape)
  M.fixture:setUserData("platform")
end -- }}}

M.draw = function() -- {{{
  love.graphics.setColor(M.color)
  local platformTopLeftPointX, platformTopLeftPointY = M.shape:getPoints()
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  local topLeftWorldPointX, topLeftWorldPointY = M.body:getWorldPoints(platformTopLeftPointX, platformTopLeftPointY)

  function drawRotatedRectange(mode, x, y, width, height, angle)
    -- We cannot rotate the rectangle directly, but we
    -- can move and rotate the coordinate system.
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.rectangle(mode, 0, 0, width, height) -- origin in the top left corner
    love.graphics.pop()
  end

  drawRotatedRectange("fill", topLeftWorldPointX, topLeftWorldPointY, windowSizeX/3, windowSizeY/5, 50)
  -- love.graphics.rectangle("fill", topLeftWorldPointX, topLeftWorldPointY, windowSizeX/3, windowSizeY/5)
end -- }}}


return M
-- vim: foldmethod=marker
