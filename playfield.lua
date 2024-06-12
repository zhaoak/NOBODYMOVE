local M = { }

local function addLine(x1,y1, x2,y2) -- {{{
  local line = {}
  line.body = love.physics.newBody(M.world, 0,0, "static")
  line.shape = love.physics.newEdgeShape(x1,y1, x2,y2)
  line.fixture = love.physics.newFixture(line.body, line.shape)

  return line
end -- }}}


M.setup = function (world) -- {{{
  M.world = world -- stash for laters
  -- create the lines with the current window size
  M.resize(love.graphics.getDimensions())
end -- }}}

M.draw = function() -- {{{
  love.graphics.setColor(1,1,1)
  love.graphics.line(M.top.body:getWorldPoints(M.top.shape:getPoints()))
  love.graphics.line(M.bottom.body:getWorldPoints(M.bottom.shape:getPoints()))
  love.graphics.line(M.left.body:getWorldPoints(M.left.shape:getPoints()))
  love.graphics.line(M.right.body:getWorldPoints(M.right.shape:getPoints()))
end -- }}}

M.resize = function(width, height) -- {{{
  -- nuke the old lines
  if M.top then
    M.top.body:destroy()
    M.bottom.body:destroy()
    M.left.body:destroy()
    M.right.body:destroy()
  end

  M.top = addLine(0,0, width,0)
  M.bottom = addLine(0,height, width,height)
  M.left = addLine(0,0, 0,height)
  M.right = addLine(width,0, width,height)
end -- }}}

return M
-- vim: foldmethod=marker
