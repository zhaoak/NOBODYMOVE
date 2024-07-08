local M = {reach={}, hardbox={}}

-- hardbox is the physical collision box of the spooder
-- the reach is the max legs reach
-- in between is the target distance from the ground
M.color = {0.5,1,1,1}

M.setup = function (world) -- {{{
  M.contact = 0
  if M.body then M.body:destroy() end

  M.body = love.physics.newBody(world, 100,100, "dynamic")
  M.hardbox.shape = love.physics.newCircleShape(20)
  M.hardbox.fixture = love.physics.newFixture(M.body, M.hardbox.shape)
  M.hardbox.fixture:setUserData("hardbox")

  -- a lil bounce
  M.hardbox.fixture:setRestitution(0.2)


  M.reach.shape = love.physics.newCircleShape(20 * 4)
  M.reach.fixture = love.physics.newFixture(M.body, M.reach.shape, 0)
  M.reach.fixture:setUserData("reach")
  M.reach.fixture:setRestitution(-100.2)

  -- the reach shape is just to detect when the spood can reach the wall
  -- M.reach.fixture:setSensor(true)
  -- connect it to the hardbox
  -- M.reach.weld = love.physics.newWeldJoint(M.body, M.reach.body, M.body:getX(), M.body:getY())

end -- }}}

M.draw = function () -- {{{
  love.graphics.setColor(M.color)
  if M.contact > 0 then
    love.graphics.setColor(1,0,0)
  end
  love.graphics.circle("fill", M.body:getX(), M.body:getY(), M.hardbox.shape:getRadius())

  if arg[2] == 'debug' then
    love.graphics.circle("line", M.body:getX(), M.body:getY(), M.reach.shape:getRadius())
  end
end -- }}}

M.recoil = function (x, y) -- {{{
    -- normalize the points of the ball and target together
    x = x - M.body:getX()
    y = y - M.body:getY()

    -- get the angle of the mouse from the ball
    local angle = math.atan2(x,y)

    -- convert the angle back into points at a fixed distance from the boll, and push
    M.body:applyLinearImpulse(-math.sin(angle)*700, -math.cos(angle)*700)
end -- }}}

M.update = function()
  if M.contact > 0 then
    for _,contact in ipairs(M.body:getContacts()) do
      local x,y = contact:getNormal()
      -- M.body:applyLinearImpulse(x*2,y*2)
    for _,fixture in ipairs(M.body:getFixtures()) do
      print(fixture:getUserData())
      end
    end
  end
end

return M
-- vim: foldmethod=marker
