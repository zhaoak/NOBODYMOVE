local gunlib = require'guns'
-- local modlib = require'mods'
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
M.playerAcceleration = 15
M.playerLatchedKnockbackReduction = 0.5
M.ragdoll = true
M.currentAimAngle = 0 -- relative to world; i.e. 0 means aiming straight down from player perspective of world
M.playerMaxGuns = 8 -- the absolute cap on how many guns a player is allowed to hold at once
-- the amount of time in seconds you have for controlling like you're grabbed even after you stop grabbing
-- think of how in most platformers, you can jump even if you're a bit late and your character is no longer standing on the ground after running off an edge
M.ungrabGracePeriod = 0.3
M.ungrabGraceTimer = M.ungrabGracePeriod

-- experimental player airdash ability: recovers after grabbing terrain and cooldown done
M.dashUsed = false -- whether or not the player has used their dash 
M.dashForce = 115 -- how much force to apply on each axis when player uses dash
M.dashCooldownPeriod = 1 -- how long in seconds it takes for the dash to be available after being used

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
  -- tmp code for guns, player just has one test gun for now
  M.guns = {}

  -- table.insert(M.guns, gunlib.equipGun("sawedoff", 1))
  -- table.insert(M.guns, gunlib.equipGun("sawedoff", 1))
  -- table.insert(M.guns, gunlib.equipGun("smg", 2))
  -- table.insert(M.guns, gunlib.equipGun("smg", 2))
  -- table.insert(M.guns, gunlib.equipGun("burstpistol", 3))
  gunlib.createGunFromDefinition(nil, 1)
  

  if M.body then M.body:destroy() end
  M.contact = 0

  M.current = {}
  M.current.health = M.startingHealth

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

end -- }}}

-- shooting-related functions {{{
-- The spooder's shoot function. Called every tick, so long as a shoot button for a particular firegroup is down.
-- Tells the spooder to shoot every gun it has in a given firegroup that isn't on cooldown.
-- Also calculates knockback on player from shooting spooder's guns, which is applied in the update step.
-- x and y are the positions of the crosshair at time of shooting
M.shoot = function (x, y, firegroup)
  firegroup = firegroup or 1 -- if no firegroup provided, default to 1

  -- table for storing knockback values from each gun fired this tick
  local knockbackValues = {}

  -- attempt to fire every gun
  for i,gunId in pairs(M.guns) do
    -- get gun from master gunlist by UID
    local gun = gunlib.gunlist[gunId]

    if gun.current.cooldown < 0 and gun.current.firegroup == firegroup then
      -- find the world origin location of each shot
      -- this does not currently factor in recoil aim offset, but that's gonna get reworked anyway, so
      local shotWorldOriginX = math.sin(M.currentAimAngle) * (gun.playerHoldDistance + M.hardboxRadius)
      local shotWorldOriginY = math.cos(M.currentAimAngle) * (gun.playerHoldDistance + M.hardboxRadius)

      -- gun's shoot function returns the amount of knockback on holder
      local playerKnockback = gun:shoot(M.body:getX()+shotWorldOriginX, M.body:getY()+shotWorldOriginY, M.currentAimAngle, true)
      local knockbackX, knockbackY = M.calculateShotKnockback(playerKnockback, x, y)

      -- convert the angle back into points at a fixed distance from the boll, and multiply by knockback
      M.addToThisTickPlayerKnockback(knockbackX, knockbackY)

      -- if the gun should burst-fire multiple shots, add the future shots to its burstQueue
      if gun.burstCount > 1 then
        for queuedBurstShot = gun.burstCount - 1, 1, -1 do
          table.insert(gun.current.shootQueue, {firesIn=gun.burstDelay*queuedBurstShot, shotBy=M})
        end
      end

    end
  end
end

-- calculate the knockback from a shot
M.calculateShotKnockback = function (gunKnockbackOnPlayer, crosshairPosX, crosshairPosY)
  -- normalize the points of the spood and target together
  local normalizedX = crosshairPosX - M.body:getX()
  local normalizedY = crosshairPosY - M.body:getY()

  -- get the angle of the crosshair from the gun
  local angle = math.atan2(normalizedX,normalizedY)

  -- calculate and return knockback on X and Y axes
  local knockbackX = -math.sin(angle)*gunKnockbackOnPlayer
  local knockbackY = -math.cos(angle)*gunKnockbackOnPlayer
  return knockbackX, knockbackY
end

-- apply knockback from shots to player
-- if player shoots multiple guns per tick, each of those shots will call this function
-- then, the total knockback will applied in the update tick
M.addToThisTickPlayerKnockback = function(knockbackX, knockbackY)
  M.thisTickTotalKnockbackX = M.thisTickTotalKnockbackX + knockbackX
  M.thisTickTotalKnockbackY = M.thisTickTotalKnockbackY + knockbackY
end -- }}}

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
    M.ungrabGraceTimer = -1
    if M.dashUsed == false and M.dashTimer <= 0 and (input.getMovementXAxisInput() ~= 0 or input.getMovementYAxisInput() ~= 0) then
      M.dashUsed = true
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

local function findFeetPos()
  local naturalFeetPos = {}
  for leg = 0,8 do
    local angle = (math.pi / 8) * leg
    -- print(angle)
  end
end
findFeetPos()

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

  -- check if player currently trying to shoot, iterating thru all 8 firegroups
  for fg=1, M.playerMaxGuns, 1 do
    if input.getShootDown(fg) then
      M.shoot(aimX, aimY, fg)
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
  -- If not doing any movement inputs while grabbed on terrain, decelerate to a stop.
  if M.grab and input.getMovementXAxisInput() == 0 and input.getMovementYAxisInput() == 0 then
    if math.abs(spoodCurrentLinearVelocity) < 1 and not input.getShotGunThisTick() then -- stinky! hacky: the recoil impulse gets canceled without this
      M.body:setLinearVelocity(0, 0)
    else
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

-- debug functions {{{
M.dumpPlayerGunIdTable = function()
  print("player gun ids: "..util.tprint(M.guns))
end
-- }}}

return M
-- vim: foldmethod=marker
