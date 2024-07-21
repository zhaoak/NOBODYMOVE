local M = {reach={}, hardbox={}, latchbox={}}

M.color = {0.5,1,1,1}
M.hardboxRadius = 20
M.latchboxRadius = M.hardboxRadius * 1.5
M.reachRadius = M.hardboxRadius * 3
M.maxWalkingSpeed = 300
M.playerAcceleration = 50
M.currentlyLatchedFixture = nil
local cooldown = 0
M.wantsGrab = true

M.rayImpactOffsetXCache = 0
M.rayImpactOffsetYCache = 0
M.rayImpactFractionCache = 0
M.latchedSurfaceNormalXCache = 0
M.latchedSurfaceNormalYCache = 0

M.terrainInRange = {} -- using collision callbacks, when terrain enters/exits latchrange, it's added/removed here

local debugRayImpactX, debugRayImpactY -- don't mind my devcode pls
local debugRayNormalX, debugRayNormalY -- yep
local debugClosestFixture

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

  love.graphics.setColor(0,0,0)
  local eyePos1X, eyePos1Y = M.body:getLocalCenter()
  eyePos1X, eyePos1Y = M.body:getWorldPoint(eyePos1X - 3, eyePos1Y - 5)
  local eyePos2X, eyePos2Y = M.body:getLocalCenter()
  eyePos2X, eyePos2Y = M.body:getWorldPoint(eyePos2X + 3, eyePos2Y - 5)
  love.graphics.circle("fill", eyePos1X, eyePos1Y, 3)
  love.graphics.circle("fill", eyePos2X, eyePos2Y, 3)

  -- debug rendering {{{
  if arg[2] == 'debug' then
    if M.wantsGrab then
      love.graphics.circle("line", M.body:getX(), M.body:getY(), M.reach.shape:getRadius())
      love.graphics.circle("line", M.body:getX(), M.body:getY(), M.latchbox.shape:getRadius())
    end

    -- various debug info
    love.graphics.setColor(1, 1, 1)
    local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
    local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))
    love.graphics.print("spooder velocity, x/y/total: "..tostring(spoodCurrentLinearVelocityX).." / "..tostring(spoodCurrentLinearVelocityY).." / "..tostring(spoodCurrentLinearVelocity))
    love.graphics.print("shouldGrab? "..tostring(M.wantsGrab), 0, 20)
    if debugClosestFixture then
      local distance, x1, y1, x2, y2 = love.physics.getDistance(M.hardbox.fixture, debugClosestFixture)
      love.graphics.print("distance between hardbox and closest fixture and their closest points (displayed in orange): "..tostring(math.floor(distance))..", ("..tostring(math.floor(x1))..", "..tostring(math.floor(y1))..") / ("..tostring(math.floor(x2))..", "..tostring(math.floor(y2))..")", 0, 60)
      love.graphics.setColor(0, .5, 0, 0.3)
      if debugRayImpactX ~= nil and debugRayImpactY ~= nil then
        love.graphics.circle("fill", debugRayImpactX, debugRayImpactY, 4)
      end

      if debugRayNormalX ~= nil and debugRayImpactY ~= nil then
        -- We also get the surface normal of the edge the ray hit. Here drawn in green
        love.graphics.setColor(0, 255, 0)
        love.graphics.line(debugRayImpactX, debugRayImpactY, debugRayImpactX + debugRayNormalX * 25, debugRayImpactY + debugRayNormalY * 25)
        -- print(tostring(debugRayNormalX).." / "..tostring(debugRayNormalY))
      end
      love.graphics.setColor(.95, .65, .25, .3)
      love.graphics.circle("fill", x1, y1, 4)
      love.graphics.circle("fill", x2, y2, 4)
    end
  end -- }}}
end -- }}}

-- game event specific functions {{{
M.recoil = function (x, y)
  -- normalize the points of the ball and target together
  x = x - M.body:getX()
  y = y - M.body:getY()

  -- get the angle of the mouse from the ball
  local angle = math.atan2(x,y)

  -- convert the angle back into points at a fixed distance from the boll, and push
  M.body:applyLinearImpulse(-math.sin(angle)*700, -math.cos(angle)*700)
end

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

M.update = function(dt) -- {{{
  -- cache current frame spood velocity
  local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
  local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))

  -- Find closest grabbable point code {{{
  -- (in debug rendering, closest grabbable point is rendered in green)
  local closestGrabbableFixture = nil
  debugClosestFixture = nil

  -- shortestDistance on init should be larger than anything it'll be compared to,
  -- so that even a fixture on the edge of grab range is correctly recognized as the shortest,
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

  -- Variables used for calculating grab point
  local spoodWorldCenterX, spoodWorldCenterY = M.body:getWorldCenter()
  local rayImpactLocX, rayImpactLocY
  local normalVectX, normalVectY, fraction

  -- This second loop identifies and caches whichever fixture in range is the closest to spood
  for k, v in pairs(M.terrainInRange) do
    local thisFixtureUserData = v:getUserData()
    if thisFixtureUserData.distance == shortestDistance then
      closestGrabbableFixture = M.terrainInRange[thisFixtureUserData.uid]
      debugClosestFixture = closestGrabbableFixture
      -- print(util.tprint(closestFixture:getUserData()).." is closest")
      -- Raytrace from spood center position through previously cached getDistance contact point,
      -- checking for impact against the identified closest fixture;
      -- this will give us the "grab point" the spood is currently using.
      normalVectX, normalVectY, fraction = closestGrabbableFixture:rayCast(spoodWorldCenterX, spoodWorldCenterY, closestGrabbableFixture:getUserData().x1, closestGrabbableFixture:getUserData().y1, 10)
      -- sometimes the ray fails to hit on like, an exact edge case of aiming for a vertex with a 90 deg or less angle
      if fraction then
        rayImpactLocX, rayImpactLocY = spoodWorldCenterX + (closestGrabbableFixture:getUserData().x1 - spoodWorldCenterX) * fraction, spoodWorldCenterY + (closestGrabbableFixture:getUserData().y1 - spoodWorldCenterY) * fraction
        if M.wantsGrab then
          local newAngle = math.atan2(normalVectX, -normalVectY)
          M.body:setAngle(newAngle)
        end
        debugRayImpactX = rayImpactLocX
        debugRayImpactY = rayImpactLocY
        debugRayNormalX = normalVectX
        debugRayNormalY = normalVectY
      else -- cancel, raycast failed
        closestGrabbableFixture = nil
        debugClosestFixture = nil
      end
    end
  end
  -- }}}

  -- recoil the player away from the mouse
  if love.mouse.isDown(1) and cooldown <= 0 then
    cooldown = 0.4
    M.recoil(love.mouse:getX(), love.mouse:getY())
  end
  cooldown = cooldown - dt -- decrement the cooldown

  if love.keyboard.isDown("space") then
    M.wantsGrab = false
  else
    M.wantsGrab = true
  end

  -- While within grabbing range of terrain, spood can move any arbitrary direction in the air--
  -- but not when no terrain is in range. There's also a max speed you can accelerate to while grabbed.
  if closestGrabbableFixture then
    if love.keyboard.isDown('w') and M.wantsGrab then
      if spoodCurrentLinearVelocityY >= -M.maxWalkingSpeed then
        M.body:applyLinearImpulse(0, -M.playerAcceleration)
      end
    end
  else
      -- If player is in the air, reduce how much velocity they can apply
      M.playerAcceleration = M.playerAcceleration / 4
  end

  if love.keyboard.isDown('s') and M.wantsGrab then
    if spoodCurrentLinearVelocityY <= M.maxWalkingSpeed then
      M.body:applyLinearImpulse(0, M.playerAcceleration)
      print(spoodCurrentLinearVelocityY)
    end
  end

  if love.keyboard.isDown('a') and M.wantsGrab then
    if spoodCurrentLinearVelocityX >= -M.maxWalkingSpeed then
      M.body:applyLinearImpulse(-M.playerAcceleration, 0)
    end
  end
  if love.keyboard.isDown('d') and M.wantsGrab then
    if spoodCurrentLinearVelocityX <= M.maxWalkingSpeed then
      M.body:applyLinearImpulse(M.playerAcceleration, 0)
    end
  end

  -- Set velocity back to normal if it's been halved
  if not closestGrabbableFixture then
    M.playerAcceleration = M.playerAcceleration * 4
  end

  -- If not holding any movement keys while grabbed on terrain, decelerate.
  -- You'll skid if you have a lot of velocity, and stop moving entirely if you're slow enough.
  if closestGrabbableFixture and not love.keyboard.isDown('w') and not love.keyboard.isDown('a') and not love.keyboard.isDown('s') and not love.keyboard.isDown('d') and M.wantsGrab then
    local decelerationForceX = -(spoodCurrentLinearVelocityX * 0.05)
    local decelerationForceY = -(spoodCurrentLinearVelocityY * 0.05)
    M.body:applyLinearImpulse(decelerationForceX, decelerationForceY)
  end

  -- If you're not already moving up or down really fast and not actively climbing upward,
  -- cancel out the force of gravity. (it feels weird to climb without gravity)
  if closestGrabbableFixture and spoodCurrentLinearVelocityY < M.maxWalkingSpeed + 1 and not love.keyboard.isDown'w' and M.wantsGrab then
    local antigravX, antigravY = M.body:getWorld():getGravity()
    M.body:applyForce(-antigravX, -antigravY)
  end

end -- }}}

return M
-- vim: foldmethod=marker
