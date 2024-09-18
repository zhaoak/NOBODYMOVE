-- Player module containing all the code for handling player movement, shooting, etc.
-- The player, NPC, and item modules have some overlap in functions, 
-- specifically for applying and calculating knockback from shooting guns.
-- That's because the gun objects call these specific functions on their wielders,
-- and players, NPCs, and items can all wield guns.

local gunlib = require'guns'
local util = require'util'
local filterVals = require'filterValues'
local input = require'input'

-- {{{ defines
local M = {reach={}, hardbox={}, latchbox={}}

M.color = {0.5,1,1,1}
M.hardboxRadius = 20
M.latchboxRadius = M.hardboxRadius * 1.5
M.reachRadius = M.hardboxRadius * 3
M.maxWalkingSpeed = 300
M.startingHealth = 100
M.playerAcceleration = 10
M.playerLatchedKnockbackReduction = 0.5
M.ragdoll = true
M.team = "friendly" -- relative to the player, yes, the player is friendly to itself
-- relative to world; i.e. 0 means aiming straight down from player perspective of world
-- increases counterclockwise, decreases clockwise, i.e. aiming left is angle -pi/2, aiming right is pi/2
M.currentAimAngle = 0
M.playerMaxGuns = 8 -- the absolute cap on how many guns a player is allowed to hold at once
-- the amount of time in seconds you have for control on the X-axis like you're grabbed even after you stop grabbing
-- think of how in most platformers, you can jump even if you're a bit late and your character is no longer standing on the ground after running off an edge
-- this also lets you dash/jump for a short period after leaving a grab
M.ungrabGracePeriod = 0.1
M.ungrabGraceTimer = M.ungrabGracePeriod

-- player jump/dash ability: can only be used when grabbed+0.1s after, recharges when grabbing again
M.dashUsed = false -- whether or not the player has used their dash
M.dashForce = 115 -- how much force to apply on each axis when player uses dash
M.dashCooldownPeriod = 0.5 -- how long in seconds it takes for the dash to be available after being used

M.thisTickTotalKnockbackX = 0
M.thisTickTotalKnockbackY = 0

M.rayImpactOffsetXCache = 0
M.rayImpactOffsetYCache = 0
M.rayImpactFractionCache = 0
M.latchedSurfaceNormalXCache = 0
M.latchedSurfaceNormalYCache = 0

M.terrainInRange = {} -- using collision callbacks, when terrain enters/exits latchrange, it's added/removed here

M.guns = {} -- a list of gun UIDs, representing the guns the player is holding

-- }}}

M.setup = function () -- {{{
  M.guns = {}

  -- give player guns with preset mod loadouts
  table.insert(M.guns, gunlib.createGunFromDefinition("shotgun_medcal", nil))
  gunlib.equipGun(M.guns[1], 1, M)
  table.insert(M.guns, gunlib.createGunFromDefinition("burstpistol_medcal", nil))
  gunlib.equipGun(M.guns[2], 3, M)
  table.insert(M.guns, gunlib.createGunFromDefinition("doublesniper_overcal", nil))
  gunlib.equipGun(M.guns[3], 2, M)

  if M.body then M.body:destroy() end
  M.contact = 0

  M.current = {}
  M.current.health = M.startingHealth
  M.current.maxHealth = M.startingHealth

  M.dashUsed = false
  M.dashTimer = 0

  -- add texture
  M.sprite = love.graphics.newImage("assets/playernormal.png")

  M.body = love.physics.newBody(util.world, 100,100, "dynamic")
  -- hardbox is the physical collision box of the spooder
  M.hardbox.shape = love.physics.newCircleShape(M.hardboxRadius)
  M.hardbox.fixture = love.physics.newFixture(M.body, M.hardbox.shape)
  M.hardbox.fixture:setUserData{name = "hardbox", type = "player_hardbox"}
  M.hardbox.fixture:setRestitution(0.2)
  M.hardbox.fixture:setFriction(1)

  -- collision filter data
  M.hardbox.fixture:setCategory(filterVals.category.player_hardbox)
  M.hardbox.fixture:setMask(
    filterVals.category.friendly,
    filterVals.category.projectile_player,
    filterVals.category.terrain_bg)
  M.hardbox.fixture:setGroupIndex(0)

  -- reach is how far away the spood will latch to terrain from
  M.reach.shape = love.physics.newCircleShape(M.reachRadius)
  M.reach.fixture = love.physics.newFixture(M.body, M.reach.shape, 0)
  -- the reach shape is just to detect when the spood can reach the wall
  -- you'd think we'd use a sensor, but no, check out preSolve in main.lua for where we handle that
  M.reach.fixture:setUserData{name = "reach", semisensor=true, type = "player_reach"}
  -- reach should also collide with everything hardbox does because of the semisensor weirdness
  M.reach.fixture:setCategory(filterVals.category.player_reach)
  M.reach.fixture:setMask(
    filterVals.category.friendly,
    filterVals.category.projectile_player)
  M.reach.fixture:setGroupIndex(0)

  -- set angular damping for spooder spinning
  M.body:setAngularDamping(0.1)

  -- set spooder mass
  M.body:setMass(0.4)

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
      util.world:rayCast(x, y, x + -M.grab.normalX*200, y + -M.grab.normalY*200, function(fixture, colX,colY)
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
  for _,gunId in pairs(M.guns) do
    gunlib.gunlist[gunId].draw(gunId, M)
  end

  -- draw cursor
  if input.mouseAimDisabled then
    local x,y = input.getCrossHair(M.getX(), M.getY())
    love.graphics.circle("fill", x, y, 3)
  end

end -- }}}

-- shooting-related functions {{{
-- calculate the knockback from a shot
M.calculateShotKnockback = function (gunKnockbackOnPlayer, gunAimAngle)
  -- calculate and return knockback on X and Y axes
  local knockbackX = -math.sin(gunAimAngle)*gunKnockbackOnPlayer
  local knockbackY = -math.cos(gunAimAngle)*gunKnockbackOnPlayer
  return knockbackX, knockbackY
end

-- apply knockback from shots to player
-- if player shoots multiple guns per tick, each of those shots will call this function
-- then, the total knockback will applied in the update tick
M.addToThisTickKnockback = function(knockbackX, knockbackY)
  M.thisTickTotalKnockbackX = M.thisTickTotalKnockbackX + knockbackX
  M.thisTickTotalKnockbackY = M.thisTickTotalKnockbackY + knockbackY
end -- }}}

-- game utility methods {{{
-- damage player's health by a specific amount
M.hurt = function(damageAmount)
  M.current.health = M.current.health - damageAmount
end

-- get center-of-body X and Y world coordinates of player
M.getX = function()
  return M.body:getX()
end

M.getY = function()
  return M.body:getY()
end
-- }}}

-- Handlers for terrain entering/exiting player latch range {{{
M.handleTerrainEnteringRange = function(a, b, contact)
    local fixtureAUserData = a:getUserData()
    local fixtureBUserData = b:getUserData()

    if fixtureAUserData.name == "reach" then
      M.terrainInRange[fixtureBUserData.uid] = b
    else
      M.terrainInRange[fixtureAUserData.uid] = a
    end
    -- util.printTerrainInRangeUserData(M.terrainInRange)
end

M.handleTerrainLeavingRange = function(a, b, contact)
    local fixtureAUserData = a:getUserData()
    local fixtureBUserData = b:getUserData()

    if fixtureAUserData.name == "reach" then
      -- print(fixtureBUserData.name.." leaving latchrange")
      M.terrainInRange[fixtureBUserData.uid] = nil
    else
      -- print(fixtureAUserData.name.." leaving latchrange")
      M.terrainInRange[fixtureAUserData.uid] = nil
    end
end
-- }}}

local function getGrab() -- {{{
  -- find object grab point and determine if grabbing
  local grab = nil

  -- don't bother looking if in ragdoll mode
  if input.getRagdollDown() then
    M.ragdoll = true
    M.hardbox.fixture:setRestitution(0.5)
    -- only allow dashing if you're on terrain or the grace timer hasn't run out yet
    if M.dashUsed == false and M.dashTimer <= 0 and M.ungrabGraceTimer >= 0 then
      M.dashUsed = true
      M.ungrabGraceTimer = -1
      M.dashTimer = M.dashCooldownPeriod
      local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
      if spoodCurrentLinearVelocityY > 0 then
        M.body:setLinearVelocity(spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY*0.25)
      end
      M.body:applyLinearImpulse(M.dashForce * input.getMovementXAxisInput(), M.dashForce * input.getMovementYAxisInput())
    end
    return nil
  else
    M.ragdoll = false
    M.hardbox.fixture:setRestitution(0)

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
          M.dashUsed = false
        end
      end
    end -- }}}

  end

  return grab
end -- }}}

M.update = function(dt) -- {{{
  -- cache current frame spood velocity
  local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = M.body:getLinearVelocity()
  local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))

  M.dashTimer = M.dashTimer - dt

  -- update grace period timer, reset if grabbing
  if not M.grab then
    M.ungrabGraceTimer = M.ungrabGraceTimer - dt
  else
    M.ungrabGraceTimer = M.ungrabGracePeriod
  end

  M.body:setLinearDamping(0)

  -- update current absolute aim angle, cache of current crosshair position
  local aimX, aimY = input.getCrossHair(M.body:getX(), M.body:getY())
  M.crosshairCacheX = aimX
  M.crosshairCacheY = aimY
  M.currentAimAngle = math.atan2(aimX - M.body:getX(), aimY - M.body:getY())

  -- update each gun's info
  for _,gunId in pairs(M.guns) do
    -- get gun's data from full gunlist by UID
    local gun = gunlib.gunlist[gunId]

    -- find the the world coords for where projectiles should spawn from this gun
    local projSpawnFromPlayerOffsetX = math.sin(M.currentAimAngle) * (gun.playerHoldDistance + M.hardboxRadius)
    local projSpawnFromPlayerOffsetY = math.cos(M.currentAimAngle) * (gun.playerHoldDistance + M.hardboxRadius)

    -- update gun
    gun:updateGunPositionAndAngle(M.body:getX()+projSpawnFromPlayerOffsetX, M.body:getY()+projSpawnFromPlayerOffsetY, M.currentAimAngle)
  end

  -- may be set later, reset every frame
  M.body:setGravityScale(1)
  M.body:setAngularDamping(0)
  M.grab = getGrab() -- find a grab point if a valid one exists

  -- {{{ player input and movement

  -- reset spood
  if input.keyDown'reset' then
    gunlib.setup()
    M.setup()
  end

  -- check state of player shoot buttons, triggering events as appropriate
  for fg=1, M.playerMaxGuns, 1 do
    -- on button press from unpressed state
    if input.getShootBindState(fg) == "pressed" then
      for _, gunId in pairs(M.guns) do
        if gunlib.gunlist[gunId].current.firegroup == fg then
          gunlib.gunlist[gunId]:triggerEvent("onPressShoot")
        end
      end
    end
    -- on holding button down for at least two updates
    if input.getShootBindState(fg) == "held" then
      for _, gunId in pairs(M.guns) do
        if gunlib.gunlist[gunId].current.firegroup == fg then
          gunlib.gunlist[gunId]:triggerEvent("onHoldShoot")
        end
      end
    end
    -- on button release from pressed or held state
    if input.getShootBindState(fg) == "released" then
      for _, gunId in pairs(M.guns) do
        if gunlib.gunlist[gunId].current.firegroup == fg then
          gunlib.gunlist[gunId]:triggerEvent("onReleaseShoot")
        end
      end
    end
    -- on not holding down button for at least two updates
    if input.getShootBindState(fg) == "notheld" then
      for _, gunId in pairs(M.guns) do
        if gunlib.gunlist[gunId].current.firegroup == fg then
          gunlib.gunlist[gunId]:triggerEvent("onNotHoldShoot")
        end
      end
    end
  end

  -- {{{ directional movement
  -- While within grabbing range of terrain, spood can move any arbitrary direction in the air--
  -- but not when no terrain is in range. There's also a max speed you can accelerate to while grabbed.
  --
  -- if grabbed, set damping value
  if M.grab then M.body:setLinearDamping(2.5) end

  if not M.grab and M.ungrabGraceTimer <= 0 then -- If player is in the air and grace timer has run out, reduce how much velocity they can apply
    M.playerAcceleration = M.playerAcceleration / 4
  end

  -- up
  if M.grab and input.getMovementYAxisInput() < 0 then -- only allowed while grabbing
    if spoodCurrentLinearVelocityY >= -M.maxWalkingSpeed then
      M.body:applyLinearImpulse(0, M.playerAcceleration*input.getMovementYAxisInput())
    end
  end

  -- down
  if input.getMovementYAxisInput() > 0 and not M.ragdoll then
    if spoodCurrentLinearVelocityY <= M.maxWalkingSpeed then
      M.body:applyLinearImpulse(0, M.playerAcceleration*input.getMovementYAxisInput())
    end
  end

  -- left
  if input.getMovementXAxisInput() < 0 and not M.ragdoll then
    if spoodCurrentLinearVelocityX >= -M.maxWalkingSpeed then
      M.body:applyLinearImpulse(M.playerAcceleration*input.getMovementXAxisInput(), 0)
    end
  end

  -- right
  if input.getMovementXAxisInput() > 0 and not M.ragdoll then
    if spoodCurrentLinearVelocityX <= M.maxWalkingSpeed then
      M.body:applyLinearImpulse(M.playerAcceleration*input.getMovementXAxisInput(), 0)
    end
  end

  -- Set velocity back to normal if it's been halved for air movement
  if not M.grab and M.ungrabGraceTimer <= 0 then
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

  -- if you're currently grabbed and not already climbing, cancel gravity when grabbed this tick
  if (M.grab and spoodCurrentLinearVelocityY < M.maxWalkingSpeed + 1) then
    M.body:setGravityScale(0)
  end

  -- {{{ brakes
  -- If not doing any movement inputs while grabbed on terrain, decelerate
  if M.grab and input.getMovementXAxisInput() == 0 and input.getMovementYAxisInput() == 0 then
    -- if you have less than 1 velocity in any direction, drop your velocity to zero
    if math.abs(spoodCurrentLinearVelocity) < 1 then
      M.body:setLinearVelocity(0, 0)
    else
      -- otherwise, decelerate
      local decelerationForceX = -(spoodCurrentLinearVelocityX * 0.03)
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

  -- player knockback calculation+application {{{

  -- if player is currently latched to something, greatly reduce knockback
  if M.grab then
    M.thisTickTotalKnockbackX = M.thisTickTotalKnockbackX * M.playerLatchedKnockbackReduction
    M.thisTickTotalKnockbackY = M.thisTickTotalKnockbackY * M.playerLatchedKnockbackReduction
  end

  -- apply the combined impulse
  M.body:applyLinearImpulse(M.thisTickTotalKnockbackX,M.thisTickTotalKnockbackY)

  -- finally, reset the knockback to zero for the next tick's calculations
  M.thisTickTotalKnockbackX = 0
  M.thisTickTotalKnockbackY = 0
  -- }}}

end -- }}}

return M
-- vim: foldmethod=marker
