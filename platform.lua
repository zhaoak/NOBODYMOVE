local M = { }

M.color = {1,1,1,1}

M.setup = function (world) -- {{{
  M.world = world -- stash for laters
  if M.body then M.body:destroy() end

  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  M.body = love.physics.newBody(M.world, windowSizeX/3, windowSizeY/2, "static")
  M.shape = love.physics.newRectangleShape(windowSizeX/3, windowSizeY/5)
  M.fixture = love.physics.newFixture(M.body, M.shape)
  M.fixture:setUserData("platform")

  -- create platform
end -- }}}

M.draw = function() -- {{{
  love.graphics.setColor(M.color)
  local platformTopLeftPointX, platformTopLeftPointY = M.shape:getPoints()
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  local topLeftWorldPointX, topLeftWorldPointY = M.body:getWorldPoints(platformTopLeftPointX, platformTopLeftPointY)
  love.graphics.rectangle("fill", topLeftWorldPointX, topLeftWorldPointY, windowSizeX/3, windowSizeY/5)
end -- }}}

return M
-- vim: foldmethod=marker
