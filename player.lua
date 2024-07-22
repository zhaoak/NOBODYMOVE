local gunlib = require'guns'
local modlib = require'mods'

-- {{{ defines
local M = {reach={}, hardbox={}, latchbox={}}

M.color = {0.5,1,1,1}
M.hardboxRadius = 20
M.latchboxRadius = M.hardboxRadius * 1.5
M.reachRadius = M.hardboxRadius * 3
M.maxWalkingSpeed = 300
M.playerAcceleration = 50
M.currentlyLatchedFixture = nil
M.ragdoll = true

M.rayImpactOffsetXCache = 0
M.rayImpactOffsetYCache = 0
M.rayImpactFractionCache = 0
M.latchedSurfaceNormalXCache = 0
M.latchedSurfaceNormalYCache = 0

M.terrainInRange = {} -- using collision callbacks, when terrain enters/exits latchrange, it's added/removed here

M.guns = {}

-- }}}

M.setup = function (world) -- {{{
  -- tmp code for guns
  for i = 0,1 do
    -- M.guns[i] = gunlib.create("hitscan", i+1)
    M.guns[i] = gunlib.create("hitscan", 0.5)
    -- add mods
    for j = 0,3 do
      M.guns[i].mods[j] = modlib.create()
    end
  end

  M.contact = 0
  if M.body then M.body:destroy() end

  M.body = love.physics.newBody(world, 100,100, "dynamic")
  -- hardbox is the physical collision box of the spooder
  M.hardbox.shape = love.physics.newCircleShape(M.hardboxRadius)
  M.hardbox.fixture = love.physics.newFixture(M.body, M.hardbox.shape)
  M.hardbox.fixture:setUserData{name = "hardbox"}
  -- a lil bounce, as a treat
  M.hardbox.fixture:setRestitution(0.2)

  -- reach is how far away the spood will latch to terrain from
  M.reach.shape = love.physics.newCircleShape(M.reachRadius)
  M.reach.fixture = love.physics.newFixture(M.body, M.reach.shape, 0)
  -- the reach shape is just to detect when the spood can reach the wall
  -- you'd think we'd use a sensor, but no, check out preSolve in main.lua for where we handle that
  M.reach.fixture:setUserData{name = "reach", simisensor=true}


end -- }}}

M.draw = function () -- {{{
  -- the body
  love.graphics.setColor(M.color)
  love.graphics.circle("fill", M.body:getX(), M.body:getY(), M.hardbox.shape:getRadius())

  -- the eyes
  love.graphics.setColor(0,0,0)
  local eyePos1X, eyePos1Y = M.body:getLocalCenter()
  eyePos1X, eyePos1Y = M.body:getWorldPoint(eyePos1X - 3, eyePos1Y - 5)
  local eyePos2X, eyePos2Y = M.body:getLocalCenter()
  eyePos2X, eyePos2Y = M.body:getWorldPoint(eyePos2X + 3, eyePos2Y - 5)
  love.graphics.circle("fill", eyePos1X, eyePos1Y, 3)
  love.graphics.circle("fill", eyePos2X, eyePos2Y, 3)

  -- debug rendering {{{
  if arg[2] == 'debug' then
    -- the reach circle
    if not M.ragdoll then
      love.graphics.circle("line", M.body:getX(), M.body:getY(), M.reach.shape:getRadius())
    end

    -- various debug info
    love.graphics.setColor(1, 1, 1)
    local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
    local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))
    love.graphics.print("spooder velocity, x/y/total/angular: "..tostring(spoodCurrentLinearVelocityX).." / "..tostring(spoodCurrentLinearVelocityY).." / "..tostring(spoodCurrentLinearVelocity).." / "..tostring(M.body:getAngularVelocity()))
    love.graphics.print("grabbing? "..tostring(M.grab), 0, 20)
    if M.grab then
      local distance, x1, y1, x2, y2 = love.physics.getDistance(M.hardbox.fixture, M.grab.fixture)
      love.graphics.print("distance between hardbox and closest fixture and their closest points (displayed in orange): "..tostring(math.floor(distance))..", ("..tostring(math.floor(x1))..", "..tostring(math.floor(y1))..") / ("..tostring(math.floor(x2))..", "..tostring(math.floor(y2))..")", 0, 60)
      love.graphics.setColor(0, .5, 0, 0.3)
      if M.grab.x ~= nil and M.grab.y ~= nil then
        love.graphics.circle("fill", M.grab.x, M.grab.y, 4)
      end

      if M.grab.normalX ~= nil and M.grab.y ~= nil then
        -- We also get the surface normal of the edge the ray hit. Here drawn in green
        love.graphics.setColor(0, 255, 0)
        love.graphics.line(M.grab.x, M.grab.y, M.grab.x + M.grab.normalX * 25, M.grab.y + M.grab.normalY * 25)
        -- print(tostring(debugRayNormalX).." / "..tostring(debugRayNormalY))
      end
      love.graphics.setColor(.95, .65, .25, .3)
      love.graphics.circle("fill", x1, y1, 4)
      love.graphics.circle("fill", x2, y2, 4)
    end
  end -- }}}

end -- }}}

M.shoot = function (x, y) -- {{{
  local totalRecoil = 0
  -- attempt to fire every gun
  for i,gun in ipairs(M.guns) do
    if gun.cooldown < 0 then
      local recoil = gun:shoot(x,y)

      -- normalize the points of the spood and target together
      x = x - M.body:getX()
      y = y - M.body:getY()

      -- get the angle of the mouse from the gun
      local angle = math.atan2(x,y)

      -- convert the angle back into points at a fixed distance from the boll, and multiply by recoil
      x = -math.sin(angle)*recoil
      y = -math.cos(angle)*recoil
      M.body:applyLinearImpulse(x,y)
      -- M.body:applyLinearImpulse(x,y, M.body:getX()+2, M.body:getY())

    end
  end
end -- }}}

-- depricated latch code {{{
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

-- {{{ find object grab point and determine if grabbing
local checkGrab = function ()
  -- don't bother looking if in ragdoll mode
  if love.keyboard.isDown("space") then
    M.ragdoll = true
  else
    M.ragdoll = false

    -- {{{ find closest reachable object
    -- shortestDistance on init should be larger than anything it'll be compared to,
    -- so that even a fixture on the edge of grab range is correctly recognized as the shortest,
    -- so long as it's the only fixture in range.
    -- This loop measures the distance from the player for each fixture in range,
    -- as well as "bubbles" it to the top (like bubbleSort does)
    local shortestDistance = math.huge
    for _, v in pairs(M.terrainInRange) do
      -- get distance from spood
      local distance, x, y = love.physics.getDistance(M.hardbox.fixture, v)
      -- check if it's the new closest and save
      if distance < shortestDistance then
        -- set the new threshold
        shortestDistance = distance

        -- set it as the grab point and that we're grabbing
        M.grab = {}
        M.grab.fixture = v
        M.grab.x = x
        M.grab.y = y
      end
    end
    -- }}}

    -- {{{ if we found a fixture to grab get normal
    if M.grab then

      -- get the normal by just asking the contact
      local contacts = M.body:getContacts()
      for _,contact in ipairs(contacts) do
        -- get fixtures, one is spood, one is not
        local f1, f2 = contact:getFixtures()
        -- see if we have the right contact
        if (f1 == M.grab.fixture) or (f2 == M.grab.fixture) then
          if (f1:getUserData().name == "reach") or (f2:getUserData().name == "reach") then
            -- set the normal
            M.grab.normalX, M.grab.normalY = contact:getNormal()
          end
        end
      end
    end -- }}}

  end
end -- }}}

M.update = function(dt) -- {{{
  -- cache current frame spood velocity
  local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
  local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))

  -- may be set later, reset every frame {{{
  M.body:setGravityScale(1)
  M.body:setAngularDamping(0)
  M.grab = nil
  -- }}}

  -- find a grab point if a valid one exists
  checkGrab()

  -- {{{ player input and movement

  -- shoot guns!
  if love.mouse.isDown(1) then
    M.shoot(love.mouse:getX(), love.mouse:getY())
  end

  -- {{{ wasd movement
  -- While within grabbing range of terrain, spood can move any arbitrary direction in the air--
  -- but not when no terrain is in range. There's also a max speed you can accelerate to while grabbed.

  if not M.grab then -- If player is in the air, reduce how much velocity they can apply
    M.playerAcceleration = M.playerAcceleration / 4
  end

  -- up
  if M.grab and love.keyboard.isDown'w' then -- only allowed while grabbing
    if spoodCurrentLinearVelocityY >= -M.maxWalkingSpeed then
      M.body:applyLinearImpulse(0, -M.playerAcceleration)
    end
  end

  -- down
  if love.keyboard.isDown's' and not M.ragdoll then
    if spoodCurrentLinearVelocityY <= M.maxWalkingSpeed then
      M.body:applyLinearImpulse(0, M.playerAcceleration)
    end
  end

  -- left
  if love.keyboard.isDown'a' and not M.ragdoll then
    if spoodCurrentLinearVelocityX >= -M.maxWalkingSpeed then
      M.body:applyLinearImpulse(-M.playerAcceleration, 0)
    end
  end

  -- right
  if love.keyboard.isDown'd' and not M.ragdoll then
    if spoodCurrentLinearVelocityX <= M.maxWalkingSpeed then
      M.body:applyLinearImpulse(M.playerAcceleration, 0)
    end
  end

  -- Set velocity back to normal if it's been halved for air movement
  if not M.grab then
    M.playerAcceleration = M.playerAcceleration * 4 -- this is some accelerated backhop type code
  end
  -- }}}

  -- {{{ counter external forces

  -- If you're not already moving up or down really fast and not actively climbing upward
  -- cancel out the force of gravity. (it feels weird to climb without gravity)

  -- commented out section is the speed cap: revist this later but it feels weird to move downward that fast
  -- possibly we'll just lower the move down speed
  -- but works for now
  if M.grab and --[[ spoodCurrentLinearVelocityY < M.maxWalkingSpeed + 1 and ]] not love.keyboard.isDown'w' then
    M.body:setGravityScale(0)
  end

  -- {{{ linear damping
  -- If not holding any movement keys while grabbed on terrain, decelerate.
  -- You'll skid if you have a lot of velocity, and stop moving entirely if you're slow enough.
  if M.grab and not love.keyboard.isDown'w' and not love.keyboard.isDown'a' and not love.keyboard.isDown's' and not love.keyboard.isDown'd' then
    if math.abs(spoodCurrentLinearVelocity) < 1 and not love.mouse.isDown(1) then -- stinky! hacky: the recoil impulse gets canceled without this
      M.body:setLinearVelocity(0, 0)
    else
      local decelerationForceX = -(spoodCurrentLinearVelocityX * 0.05)
      local decelerationForceY = -(spoodCurrentLinearVelocityY * 0.05)
      M.body:applyLinearImpulse(decelerationForceX, decelerationForceY)
    end
  end
  -- }}}

  -- {{{ handle rotating to surface
  if M.grab then
    M.body:setAngularDamping(5) -- spin less
    -- clamp spin, in fact
    if math.abs(M.body:getAngularVelocity()) < 2 then
      M.body:setAngularVelocity(0, 0)
    end

    local targetAngle = math.atan2(M.grab.normalX, -M.grab.normalY)
    -- phys tracks total rotation which is kind of weird?? if you spin something long enough it goes up forever and hits inf and the
    -- object fucking dies
    -- got annoyed with weird behaviors with the modulo to fix that so ig the spood keeps track of how many times she's spun
    -- it's cute so
    if math.abs(M.body:getAngle() - targetAngle) > 0.1 then -- stop spinning when close enough
      -- have the spood rotate towards the target angle
      if M.body:getAngle() - targetAngle >= 0 then
        M.body:applyTorque(-20000)
      else
        M.body:applyTorque(20000)
      end
    end
  end -- }}}

  -- }}} counter ext forces

  -- }}} input/movement

end -- }}}

-- i live in spain withut the a
function love.wheelmoved(_,y)
  if M.ragdoll then
    M.body:applyAngularImpulse(-y*1000)
  end
end

return M
-- vim: foldmethod=marker
