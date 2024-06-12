local M = { ground = {} }

M.setup = function (world) -- {{{
  M.resize()
  M.ground.body = love.physics.newBody(world, 0,0, "static")
  M.ground.shape = love.physics.newEdgeShape(0,800, 1000,1000)
  M.ground.fixture = love.physics.newFixture(M.ground.body, M.ground.shape)

end -- }}}

M.draw = function() -- {{{
  love.graphics.setColor(1,1,1)
  love.graphics.line(M.ground.body:getWorldPoints(M.ground.shape:getPoints()))
end

M.resize = function()
end -- }}}

return M
-- vim: foldmethod=marker
