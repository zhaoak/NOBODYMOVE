local M = {}

M.setup = function (world) -- {{{
  if M.body then M.body:destroy() end
  M = {}

  M.body = love.physics.newBody(world, 100,100, "dynamic")
  M.shape = love.physics.newCircleShape(20)
  M.fixture = love.physics.newFixture(M.body, M.shape)

end -- }}}

M.draw = function () -- {{{
  love.graphics.setColor(0.5,1,1)
  love.graphics.circle("fill", M.body:getX(), M.body:getY(), M.shape:getRadius())
end -- }}}

M.recoil = function (x, y) -- {{{
    -- normalize the points of the ball and target together
    x = x - M.body:getX()
    y = y - M.body:getY()

    -- get the angle of the mouse from the ball
    local angle = math.atan2(x,y)

    -- convert the angle back into points at a fixed distance from the boll, and push
    M.body:applyLinearImpulse(-math.sin(angle)*200, -math.cos(angle)*200)
end -- }}}

return M
-- vim: foldmethod=marker
