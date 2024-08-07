local gunlib = require'guns'
local modlib = require'mods'

-- {{{ defines
local M = {reach={}, hardbox={}, latchbox={}}

M.color = {0.5,1,1,1}
M.hardboxRadius = 20
M.latchboxRadius = M.hardboxRadius * 1.5
M.reachRadius = M.hardboxRadius * 3
M.maxWalkingSpeed = 300
M.playerAcceleration = 20
M.ragdoll = true
M.currentAimAngle = 0 -- relative to world; i.e. 0 means aiming straight down from player perspective of world

M.rayImpactOffsetXCache = 0
M.rayImpactOffsetYCache = 0
M.rayImpactFractionCache = 0
M.latchedSurfaceNormalXCache = 0
M.latchedSurfaceNormalYCache = 0

M.terrainInRange = {} -- using collision callbacks, when terrain enters/exits latchrange, it's added/removed here

M.guns = {}

-- }}}

M.setup = function (world) -- {{{
  -- tmp code for guns, player just has one test gun for now
  for i = 0,1 do
    M.guns[i] = gunlib.equipGun("samplegun")
    -- add mods
    for j = 0,3 do
      M.guns[i].mods[j] = modlib.create()
    end
  end

  M.world = world -- stash for laters
  if M.body then M.body:destroy() end
  M.contact = 0

  -- add texture
  M.sprite = love.graphics.newImage("assets/playernormal.png")

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
  M.reach.fixture:setUserData{name = "reach", semisensor=true}

  -- set angular damping for spooder spinning
  M.body:setAngularDamping(0.1)


end -- }}}

M.draw = function () -- {{{

  -- draw the sprite

  -- reset the colors
  love.graphics.setColor(1,1,1,1)
  -- love.graphics.draw(M.sprite, x, y, angle, scale, scale, offset, offset)
  love.graphics.draw(M.sprite, M.body:getX(), M.body:getY(), M.body:getAngle(), 40/271, 40/276, 271/2, 276/2)

  -- tmp leg
  for leg = 0,7 do
    -- angle is octants of the spood (for now, later maybe skew them to more natural positions
    local angle = (math.pi / 4) * leg
    -- and offset by a 16th to not have leg straight up and down (the spider isn't straight this is cannon)
    angle = angle + math.pi / 8
    -- drawn at reach range
    local x,y
    x = -math.sin(angle)*M.reachRadius
    y = -math.cos(angle)*M.reachRadius

    x, y = M.body:getWorldPoint(x, y)
    love.graphics.circle("fill", x, y, 3)

    -- try to find where foot go
    -- naive approach: shoot a ray down from the each spread leg, check if leg can reach, and if so, we know where footie should go

    love.graphics.setColor(0, 0, 0)
    if M.grab then
      -- use world so she can grab whatever's near
      M.world:rayCast(x, y, x + -M.grab.normalX*200, y + -M.grab.normalY*200, function(fixture, colX,colY)
        local name = fixture:getUserData().name
        if name == "reach" or name == "hardbox" then
          return 1
        else
          -- love.graphics.line(x, y, colX, colY)
          -- love.graphics.setColor(100, 0, 0)
          -- love.graphics.circle("fill", colX, colY, 3)
          return 0
        end
      end)
    end

  end

  -- draw guns
  for _,gun in ipairs(M.guns) do
    gun.draw(gun, M)
  end

  -- debug rendering {{{
  if arg[2] == 'debug' then

    -- -- the body
    love.graphics.setColor(M.color)
    love.graphics.circle("fill", M.body:getX(), M.body:getY(), M.hardbox.shape:getRadius())
    --
    -- -- the eyes
    -- love.graphics.setColor(0,0,0)
    local eyePos1X, eyePos1Y = M.body:getLocalCenter()
    eyePos1X, eyePos1Y = M.body:getWorldPoint(eyePos1X - 3, eyePos1Y - 5)
    local eyePos2X, eyePos2Y = M.body:getLocalCenter()
    eyePos2X, eyePos2Y = M.body:getWorldPoint(eyePos2X + 3, eyePos2Y - 5)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", eyePos1X, eyePos1Y, 3)
    love.graphics.circle("fill", eyePos2X, eyePos2Y, 3)

    -- the reach circle
    if not M.ragdoll then
      love.graphics.setColor(0,0,20,1)
      love.graphics.circle("line", M.body:getX(), M.body:getY(), M.reach.shape:getRadius())
    end

    -- gun debug
    local gunNameDebugList = ""
    for i, gun in ipairs(M.guns) do
      gunNameDebugList = gunNameDebugList..gun.name
      if i ~= table.getn(M.guns) then
        gunNameDebugList = gunNameDebugList..", "
      end
    end

    -- various debug info
    love.graphics.setColor(1, 1, 1)
    local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
    local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))
    love.graphics.print("spooder velocity, x/y/total/angular: "..tostring(spoodCurrentLinearVelocityX).." / "..tostring(spoodCurrentLinearVelocityY).." / "..tostring(spoodCurrentLinearVelocity).." / "..tostring(M.body:getAngularVelocity()))
    love.graphics.print("grabbing? "..tostring(M.grab), 0, 20)
    love.graphics.print("world-relative aim angle (0 = directly down, pi = directly up): "..tostring(M.currentAimAngle), 0, 40)
    love.graphics.setColor(0, .75, .25)
    love.graphics.print("current guns: "..gunNameDebugList, 0, 60)

    if M.grab then
      local distance, x1, y1, x2, y2 = love.physics.getDistance(M.hardbox.fixture, M.grab.fixture)
      love.graphics.print("distance between hardbox and closest fixture and their closest points (displayed in orange): "..tostring(math.floor(distance))..", ("..tostring(math.floor(x1))..", "..tostring(math.floor(y1))..") / ("..tostring(math.floor(x2))..", "..tostring(math.floor(y2))..")", 0, 80)
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
      love.graphics.setColor(.95, .65, .77, .6)
      love.graphics.circle("fill", x2, y2, 4)

      -- contact points of two colliding fixtures, whatever that actually means
      love.graphics.setColor(.95, 0, .25, .7)
      love.graphics.circle("fill", M.grab.p.x1, M.grab.p.y1, 4)
      if M.grab.p.x2 then --not always second point
        love.graphics.circle("fill", M.grab.p.x2, M.grab.p.y2, 4)
      end
    end
  end 

  -- }}}

end -- }}}

M.shoot = function (x, y) -- {{{
  local totalRecoil = 0
  -- attempt to fire every gun
  for i,gun in ipairs(M.guns) do
    if gun.cooldown < 0 then
      local playerKnockback = gun:shoot(x,y,M.currentAimAngle, gun)
      -- print("bang!!")
      -- normalize the points of the spood and target together
      x = x - M.body:getX()
      y = y - M.body:getY()

      -- get the angle of the mouse from the gun
      local angle = math.atan2(x,y)

      -- convert the angle back into points at a fixed distance from the boll, and multiply by knockback
      x = -math.sin(angle)*playerKnockback
      y = -math.cos(angle)*playerKnockback
      M.body:applyLinearImpulse(x,y)
      -- M.body:applyLinearImpulse(x,y, M.body:getX()+2, M.body:getY())

    end
  end
end -- }}}

local function getGrab() -- {{{
  -- find object grab point and determine if grabbing
  local grab = nil

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
        grab = {}
        grab.fixture = v
        grab.x = x
        grab.y = y
        grab.distance = distance
      end
    end
    -- }}}

    -- {{{ if we found a fixture to grab get normal
    if grab then
      -- get the normal by just asking the contact
      local contacts = M.body:getContacts()
      for _,contact in ipairs(contacts) do
        -- see if we have the right contact between reach and the grab fixture and set the normal
        local f1, f2 = contact:getFixtures()
        if (f1 == grab.fixture or f2 == grab.fixture) and (f1:getUserData().name == "reach" or f2:getUserData().name == "reach") then
          grab.normalX, grab.normalY = contact:getNormal()
          -- tmp debug
          grab.p = {}
          grab.p.x1, grab.p.y1, grab.p.x2, grab.p.x2 = contact:getPositions()
        end
      end
    end -- }}}

  end

  return grab
end -- }}}

local function findFeetPos()
  local naturalFeetPos = {}
  for leg = 0,8 do
    local angle = (math.pi / 8) * leg
    print(angle)
  end
end
findFeetPos()

M.update = function(dt) -- {{{
  -- cache current frame spood velocity
  local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
  local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))

  -- update current absolute aim angle
  M.currentAimAngle = math.atan2(love.mouse:getX() - M.body:getX(), love.mouse:getY() - M.body:getY())

  -- may be set later, reset every frame
  M.body:setGravityScale(1)
  M.body:setAngularDamping(0)
  M.grab = getGrab() -- find a grab point if a valid one exists

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
  -- if M.grab and --[[ spoodCurrentLinearVelocityY < M.maxWalkingSpeed + 1 and ]] not love.keyboard.isDown'w' then
  if M.grab and spoodCurrentLinearVelocityY < M.maxWalkingSpeed + 1 and  not love.keyboard.isDown'w' then
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

    -- the physics engine tracks total rotation-so if you rotate something ten times, it's 20pi
    -- so the weird math here is modulo-ing to within two rotations, one rotation and she can get fast enough to keep spinning forever
    -- that's dependant on the dampening though, so if that changes, we may need to change the rotation count

    if math.abs(M.body:getAngle() % (math.pi*4) - math.pi*2 - targetAngle) > 0.1 then -- stop spinning at all when close enough
      -- find which direction to rotate & do
      if (M.body:getAngle() % (math.pi*4)) - math.pi*2 - targetAngle >= 0 then
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
