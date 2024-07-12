local M = {reach={}, hardbox={}, latchbox={}}

M.color = {0.5,1,1,1}

M.setup = function (world) -- {{{
  M.contact = 0
  if M.body then M.body:destroy() end

  M.body = love.physics.newBody(world, 100,100, "dynamic")
  -- hardbox is the physical collision box of the spooder
  M.hardbox.shape = love.physics.newCircleShape(20)
  M.hardbox.fixture = love.physics.newFixture(M.body, M.hardbox.shape)
  M.hardbox.fixture:setUserData("hardbox")
  -- a lil bounce, as a treat
  M.hardbox.fixture:setRestitution(0.2)

  -- latchbox is the collision circle of hold on lemme work something out
  M.latchbox.shape = love.physics.newCircleShape(25)
  M.latchbox.fixture = love.physics.newFixture(M.body, M.latchbox.shape)
  M.latchbox.fixture:setUserData("latchbox")
  M.latchbox.fixture:setRestitution(0)

  -- latchbox should start as a sensor
  M.latchbox.fixture:setSensor(true)

  M.reach.shape = love.physics.newCircleShape(20 * 4)
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
  M.standingDistance = 20 * 1.5


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

M.latchToTerrain = function (cx1, cy1, cx2, cy2, contactObj)
  print("LATCH")
  -- cancel all velocity on latch, disable gravity too
  M.body:setLinearVelocity(0, 0)
  M.body:setGravityScale(0)
  M.latched = true

  -- set position to standingDistance from collided-with object
  -- do this by calculating distance from object using contact points between player and terrain
  local interceptionMidpointX, interceptionMidpointY
  if cx2 and cy2 then
    -- if circle intersecting line at two points and not just one
    interceptionMidpointX = (math.abs(cx2) - math.abs(cx1)) / 2
    interceptionMidpointY = (math.abs(cy2) - math.abs(cy1)) / 2
  else
    interceptionMidpointX = cx1
    interceptionMidpointY = cy1
  end


  print(tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
  print(tostring(interceptionMidpointX)..", "..tostring(interceptionMidpointY).." -- "..tostring(contactObj))

  local spoodCenterPosX, spoodCenterPosY = M.body:getWorldCenter()
  if interceptionMidpointX > spoodCenterPosX then
    M.body:setPosition(interceptionMidpointX - M.standingDistance, spoodCenterPosY)
  end
  if interceptionMidpointX < spoodCenterPosX then
    M.body:setPosition(interceptionMidpointX + M.standingDistance, spoodCenterPosY)
  end

  if interceptionMidpointY > spoodCenterPosY then
    M.body:setPosition(spoodCenterPosX, interceptionMidpointY - M.standingDistance)
  end
  if interceptionMidpointY < spoodCenterPosY then
    M.body:setPosition(spoodCenterPosX, interceptionMidpointY + M.standingDistance)
  end
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
