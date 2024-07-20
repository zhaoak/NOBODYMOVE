local M = {reach={}, hardbox={}, latchbox={}}

M.color = {0.5,1,1,1}
M.hardboxRadius = 20
M.latchboxRadius = M.hardboxRadius * 1.5
M.reachRadius = M.hardboxRadius * 3
M.maxWalkingSpeed = 300
M.currentlyLatchedFixture = nil
local cooldown = 0

M.rayImpactOffsetXCache = 0
M.rayImpactOffsetYCache = 0
M.rayImpactFractionCache = 0
M.latchedSurfaceNormalXCache = 0
M.latchedSurfaceNormalYCache = 0

M.terrainInRange = {} -- using collision callbacks, when terrain enters/exits latchrange, it's added/removed here

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

  -- latchbox is not actually used (but latchboxRadius is for latching)
  -- (it is currently used in debug drawcalls tho so don't comment it out yet)
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

  -- var tracking whether spood is currently walking on surface or not
  M.latched = false

  -- variable tracking whether spood should latch to walls or not
  -- controlled by player via keyboard
  -- when latched, spooder can skitter along surface much faster than air control allows
  M.shouldLatch = false

  -- the reach shape is just to detect when the spood can reach the wall
  M.reach.fixture:setSensor(true)

end -- }}}

M.draw = function () -- {{{
  love.graphics.setColor(M.color)
  love.graphics.circle("fill", M.body:getX(), M.body:getY(), M.hardbox.shape:getRadius())

  if arg[2] == 'debug' then
    love.graphics.circle("line", M.body:getX(), M.body:getY(), M.reach.shape:getRadius())
    love.graphics.circle("line", M.body:getX(), M.body:getY(), M.latchbox.shape:getRadius())
  end

  love.graphics.setColor(0,0,0)
  local eyePos1X, eyePos1Y = M.body:getLocalCenter()
  eyePos1X, eyePos1Y = M.body:getWorldPoint(eyePos1X - 3, eyePos1Y - 5)
  local eyePos2X, eyePos2Y = M.body:getLocalCenter()
  eyePos2X, eyePos2Y = M.body:getWorldPoint(eyePos2X + 3, eyePos2Y - 5)
  love.graphics.circle("fill", eyePos1X, eyePos1Y, 3)
  love.graphics.circle("fill", eyePos2X, eyePos2Y, 3)
end -- }}}

-- game event specific functions {{{
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
M.latchToTerrain = function (contactLocationX, contactLocationY, terrainSurfaceNormalX, terrainSurfaceNormalY, rayImpactFraction, fixtureLatchedTo)
  print("LATCH")
  -- cache offset from ray impact location, as well as raycast fraction value and surface normal
  local spoodWorldCenterX, spoodWorldCenterY = M.body:getWorldCenter()
  M.rayImpactOffsetXCache = contactLocationX - spoodWorldCenterX
  M.rayImpactOffsetYCache = contactLocationY - spoodWorldCenterY
  M.rayImpactFractionCache = rayImpactFraction
  M.latchedSurfaceNormalXCache = terrainSurfaceNormalX
  M.latchedSurfaceNormalYCache = terrainSurfaceNormalY

  -- cache fixture spood is latched to
  M.currentlyLatchedFixture = fixtureLatchedTo

  -- cancel all linear+angular velocity on latch, disable gravity too,
  -- set angle, and update state
  M.body:setLinearVelocity(0, 0)
  M.body:setAngularVelocity(0)
  M.body:setGravityScale(0)
  -- Here we calculate the angle to set spood to so that it "stands" on terrain correctly
  -- (with its butt towards the surface it's latched to.)
  -- `atan2` finds the correct angle for this and takes care of the oddities with converting negative/positive vectors
  -- to the appropriate angle.
  -- The negative sign before `terrainSurfaceNormalY` is because in Love, (0,0) is at the top left corner and
  -- Y increases when moving _down_ rather than up--
  -- whereas `atan2` expects four quadrants where (0,0) is the intersection of all of them.
  local newAngle = math.atan2(terrainSurfaceNormalX, -terrainSurfaceNormalY)
  M.body:setAngle(newAngle)
  M.latched = true

  -- set position to latchboxRadius from collided-with object
  M.body:setPosition(contactLocationX + terrainSurfaceNormalX * M.latchboxRadius, contactLocationY + terrainSurfaceNormalY * M.latchboxRadius)
end

-- unlatch from terrain (making gravity apply to spood again)
M.unlatchFromTerrain = function ()
  print("UNLATCH")
  M.body:setGravityScale(1)
  M.latched = false
  M.currentlyLatchedFixture = nil
  M.latchedSurfaceNormalXCache = nil
  M.latchedSurfaceNormalYCache = nil
end

-- Called every frame when latched to surface in order to check if player is
-- still in valid position to walk on latched surface.
-- If not, unlatches them.
M.checkIfLatchStillValid = function (checkedFixture)
  local spoodWorldCenterX, spoodWorldCenterY = M.body:getWorldCenter()
  local checkedNormalVectX, checkedNormalVectY, fraction = checkedFixture:rayCast(spoodWorldCenterX, spoodWorldCenterY, spoodWorldCenterX+M.rayImpactOffsetXCache, spoodWorldCenterY+M.rayImpactOffsetYCache, 5)
  print(tostring(checkedNormalVectX).." / "..tostring(checkedNormalVectY).." vs: "..tostring(M.latchedSurfaceNormalXCache).." / "..tostring(M.latchedSurfaceNormalYCache))
  print(tostring(fraction).." vs: "..tostring(M.rayImpactFractionCache))
  if checkedNormalVectX == M.latchedSurfaceNormalXCache and
     checkedNormalVectY == M.latchedSurfaceNormalYCache then
     -- fraction == M.rayImpactFractionCache then
    return
  else
    M:unlatchFromTerrain()
  end
end
-- }}}

M.update = function(dt)
  -- cache current frame spood velocity
  local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
  local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))

  -- if not latched, iterate through all terrain in range this frame, find the closest fixture
  -- the closest fixture is the one that should be latched to
  local closestFixture = nil
  debugClosestFixture = nil
  if not M.latched then
    -- shortestDistance on init should be larger than anything it'll be compared to,
    -- so that even a fixture on the edge of latchrange is correctly recognized as the shortest,
    -- so long as it's the only fixture in range.
    -- This first loop measures the distance from the player for each fixture in range,
    -- as well as "bubbles" the shortest distance to the top (like bubbleSort does)
    local shortestDistance = M.reachRadius + 1
    for k, v in pairs(M.terrainInRange) do
      local distance, x1, y1, x2, y2 = love.physics.getDistance(M.hardbox.fixture, v)
      if distance < shortestDistance then shortestDistance = distance end
      local newUserData = v:getUserData()
      newUserData.distance = distance
      newUserData.x1 = x1
      newUserData.y1 = y1
      newUserData.x2 = x2
      newUserData.y2 = y2
      v:setUserData(newUserData)
    end
    -- This second loop identifies and caches whichever fixture in range is the closest to spood
    for k, v in pairs(M.terrainInRange) do
      local thisFixtureUserData = v:getUserData()
      if thisFixtureUserData.distance == shortestDistance then
        closestFixture = M.terrainInRange[thisFixtureUserData.uid]
        debugClosestFixture = closestFixture
        -- print(util.tprint(closestFixture:getUserData()).." is closest")
      end
    end
  end

  -- Variables used for calculating latchpoint
  local spoodWorldCenterX, spoodWorldCenterY = M.body:getWorldCenter()
  local rayImpactLocX, rayImpactLocY
  local normalVectX, normalVectY

  -- If a closest fixture exists (which it will, so long as any latchable terrain is in range),
  -- raytrace from spood center position through previously cached getDistance contact point,
  -- checking for impact against the identified closest fixture;
  -- this will give us the location on the edge of the closest fixture to latch to.
  if closestFixture then
    normalVectX, normalVectY, fraction = closestFixture:rayCast(spoodWorldCenterX, spoodWorldCenterY, closestFixture:getUserData().x1, closestFixture:getUserData().y1, 10)
    rayImpactLocX, rayImpactLocY = spoodWorldCenterX + (closestFixture:getUserData().x1 - spoodWorldCenterX) * fraction, spoodWorldCenterY + (closestFixture:getUserData().y1 - spoodWorldCenterY) * fraction
    debugRayImpactX = rayImpactLocX
    debugRayImpactY = rayImpactLocY
    debugRayNormalX = normalVectX
    debugRayNormalY = normalVectY
  end

  -- reset spood on rightclick
  if love.mouse.isDown(2) then
    M.setup(world)
  end

  -- recoil the player away from the mouse
  if love.mouse.isDown(1) and cooldown <= 0 then
    cooldown = 0.4
    M.recoil(love.mouse:getX(), love.mouse:getY())
  end
  cooldown = cooldown - dt -- decrement the cooldown

  if love.keyboard.isDown("space") then
    M.shouldLatch = true
    -- If in latching range, and there's a fixture to latch to, do so!
    if not M.latched and closestFixture then
      M.latchToTerrain(rayImpactLocX, rayImpactLocY, normalVectX, normalVectY, fraction, closestFixture)
    end
  else
    -- If the player lets go of latch key, let go of current latch
    M.shouldLatch = false
    if M.latched == true then
      M.unlatchFromTerrain()
    end
  end

 -- if love.keyboard.isDown('w') then
 --    M.body:applyLinearImpulse(0, 50)
 --  end
 -- if love.keyboard.isDown('s') then
 --    M.body:applyLinearImpulse(50, 0)
 --  end
 -- if love.keyboard.isDown('a') then
 --    M.body:applyLinearImpulse(-50, 0)
 --  end
 -- if love.keyboard.isDown('d') then
 --    M.body:applyLinearImpulse(-50, 0)
 --  end
 --

  -- left/right controls
  if love.keyboard.isDown('a') and love.keyboard.isDown('d') == false then
    if M.latched == true then
      -- If latched and below max walking speed, move along surface
      -- To tell what direction to move, use cached data from the raytrace performed on initial latch,
      -- rotate the returned normal vector by 90 degrees,
      -- then use a multiple of that value to apply force in that direction.
      if spoodCurrentLinearVelocity <= M.maxWalkingSpeed then
        local directionVectorX = M.latchedSurfaceNormalYCache
        local directionVectorY = M.latchedSurfaceNormalXCache * -1
        M.body:applyLinearImpulse(50 * directionVectorX, 50 * directionVectorY)
      end
    else
      -- otherwise, use air controls
      if spoodCurrentLinearVelocityX >= -1 * M.maxWalkingSpeed then
        M.body:applyLinearImpulse(-50, 0)
      end
    end
  end

  if love.keyboard.isDown('d') and love.keyboard.isDown('a') == false then
    if M.latched == true then
      -- If latched and below max walking speed, move along surface.
      -- To tell what direction to move, use cached data from the raytrace performed on initial latch,
      -- rotate the returned normal vector by 90 degrees,
      -- then use a multiple of that value to apply force in that direction.
      if spoodCurrentLinearVelocity <= M.maxWalkingSpeed then
        local directionVectorX = M.latchedSurfaceNormalYCache * -1
        local directionVectorY = M.latchedSurfaceNormalXCache
        M.body:applyLinearImpulse(50 * directionVectorX, 50 * directionVectorY)
      end
    else
      -- Otherwise, use air controls
      if spoodCurrentLinearVelocityX <= M.maxWalkingSpeed then
        M.body:applyLinearImpulse(50, 0)
      end
    end
  end

  -- If l/r keys are pressed simultaneously while latched, stop moving.
  if M.latched and love.keyboard.isDown('d') and love.keyboard.isDown('a') then
    local newLinearVelocityX, newLinearVelocityY = M.body:getLinearVelocity()
    newLinearVelocityX = newLinearVelocityX * .7
    newLinearVelocityY = newLinearVelocityY * .7
    M.body:setLinearVelocity(newLinearVelocityX, newLinearVelocityY)
  end

  -- If walking on surface and no keys are pressed, slow to a stop.
  if M.latched and love.keyboard.isDown('d') == false and love.keyboard.isDown('a') == false then
    local newLinearVelocityX, newLinearVelocityY = M.body:getLinearVelocity()
    newLinearVelocityX = newLinearVelocityX * .7
    newLinearVelocityY = newLinearVelocityY * .7
    M.body:setLinearVelocity(newLinearVelocityX, newLinearVelocityY)
  end
end

return M
-- vim: foldmethod=marker
