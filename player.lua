local M = {reach={}, hardbox={}, latchbox={}}

M.color = {0.5,1,1,1}
M.hardboxRadius = 20
M.latchboxRadius = M.hardboxRadius * 1.5
M.reachRadius = M.hardboxRadius * 3

M.setup = function (world) -- {{{
  M.contact = 0
  if M.body then M.body:destroy() end

  M.body = love.physics.newBody(world, 100,100, "dynamic")
  -- hardbox is the physical collision box of the spooder
  M.hardbox.shape = love.physics.newCircleShape(M.hardboxRadius)
  M.hardbox.fixture = love.physics.newFixture(M.body, M.hardbox.shape)
  M.hardbox.fixture:setUserData("hardbox")
  -- a lil bounce, as a treat
  M.hardbox.fixture:setRestitution(0.2)

  -- latchbox is not actually used so you can ignore this
  -- (it is currently used in drawcalls tho so don't comment it out yet)
  M.latchbox.shape = love.physics.newCircleShape(M.latchboxRadius)
  M.latchbox.fixture = love.physics.newFixture(M.body, M.latchbox.shape)
  M.latchbox.fixture:setUserData("latchbox")
  M.latchbox.fixture:setRestitution(0)
  M.latchbox.fixture:setSensor(true)

  -- reach is how far away the spood will latch to terrain from
  M.reach.shape = love.physics.newCircleShape(M.reachRadius)
  M.reach.fixture = love.physics.newFixture(M.body, M.reach.shape, 0)
  M.reach.fixture:setUserData("reach")
  M.reach.fixture:setRestitution(0)

  -- variable tracking whether or not spood is currently walking or in air
  -- wasd input handling varies based on whether you're walking on surface or airborne
  M.airborne = true

  -- var tracking whether spood is currently walking on surface or not
  M.latched = false

  -- variable tracking whether spood should latch to walls or not
  -- controlled by player via keyboard
  -- when latched, spooder can skitter along surface much faster than air control allows
  M.shouldLatch = false

  -- tracks how many terrain objects spood is currently within range of
  M.bodiesInRange = 0

  -- standing distance is how far spooder should hold itself from the nearest wall when latched


  -- the reach shape is just to detect when the spood can reach the wall
  M.reach.fixture:setSensor(true)
  -- connect it to the hardbox
  -- M.reach.weld = love.physics.newWeldJoint(M.body, M.reach.body, M.body:getX(), M.body:getY())

end -- }}}

M.draw = function () -- {{{
  love.graphics.setColor(M.color)
  if not M.airborne then
    love.graphics.setColor(1,0,0)
  end
  love.graphics.circle("fill", M.body:getX(), M.body:getY(), M.hardbox.shape:getRadius())

  if arg[2] == 'debug' then
    love.graphics.circle("line", M.body:getX(), M.body:getY(), M.reach.shape:getRadius())
    love.graphics.circle("line", M.body:getX(), M.body:getY(), M.latchbox.shape:getRadius())
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

-- latch to terrain at the given coordinates; given coords must have latchable object at them
M.latchToTerrain = function (contactLocationX, contactLocationY, terrainSurfaceNormalX, terrainSurfaceNormalY)
  print("LATCH")
  -- cancel all velocity on latch, disable gravity too
  M.body:setLinearVelocity(0, 0)
  M.body:setGravityScale(0)
  M.latched = true

  -- set position to latchboxRadius from collided-with object
  M.body:setPosition(contactLocationX + terrainSurfaceNormalX * M.latchboxRadius, contactLocationY + terrainSurfaceNormalY * M.latchboxRadius)
end

-- unlatch from terrain (making normal physics apply to spood again)
M.unlatchFromTerrain = function ()
  print("UNLATCH")
  M.body:setGravityScale(1)
  M.latched = false
end

M.update = function()
  if M.contact > 0 then
    for _,contact in ipairs(M.body:getContacts()) do
      local x,y = contact:getNormal()
    for _,fixture in ipairs(M.body:getFixtures()) do
      -- print(fixture:getUserData())
      end
    end
  end
end

return M
-- vim: foldmethod=marker
