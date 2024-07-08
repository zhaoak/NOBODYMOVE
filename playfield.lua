local M = { }

M.color = {1,1,1,1}
local function addLine(x1,y1, x2,y2) -- {{{
  local line = {}
  line.shape = love.physics.newEdgeShape(x1,y1, x2,y2)
  line.fixture = love.physics.newFixture(M.body, line.shape)
  line.fixture:setUserData("border")


  return line
end -- }}}


M.setup = function (world) -- {{{
  M.world = world -- stash for laters
  -- create the lines with the current window size
  M.resize(love.graphics.getDimensions())
end -- }}}

M.draw = function() -- {{{
  love.graphics.setColor(M.color)
  love.graphics.line(M.body:getWorldPoints(M.top.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.bottom.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.left.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.right.shape:getPoints()))
end -- }}}

M.resize = function(width, height) -- {{{
  if M.body then M.body:destroy() end
  M.body = love.physics.newBody(M.world, 0,0, "static")

  M.top = addLine(0,0, width,0)
  M.bottom = addLine(0,height, width,height)
  M.left = addLine(0,0, 0,height)
  M.right = addLine(width,0, width,height)
end -- }}}

return M
-- vim: foldmethod=marker
