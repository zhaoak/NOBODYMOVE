-- Gun objects.
local M = { }

M.gunlist = {} -- data for every gun existing in world, held by player or enemy, lives here

local projectileLib = require'projectiles'
local util = require'util'

-- The function called when an event is triggered, which evaluates and executes its mods.
-- This means all mods, including shoot projectile ones; when an event is triggered,
-- this function will either call the gun's `shoot()` method or add shots to its queue as appropriate.
-- This function is set as a method of every gun object in createGun functions.
-- Thus, it can be called with colon syntax to skip the first arg, e.g. `gunObj:triggerEvent(eventString, modsInEvent)`
-- args:
-- gunContainingEvent(gun obj): the gun containing the event you want to trigger. 
-- eventString(string): the string identifier of the event you want to trigger, most commonly "onPressShoot"
local function triggerEvent (gunContainingEvent, eventString)
  -- iterate through the gun's events and find the one we're looking for, then cache its mods
  local thisShotMods
  for i, event in ipairs(gunContainingEvent.events) do
    if event.trigger_event == eventString then
      thisShotMods = event.triggers_mods
    else
      -- if the gun doesn't contain this event trigger, do nothing
      return
    end
  end

  -- find and cache "shoot projectile" mods
  local thisEventShootProjectileMods = util.cloneTable(thisShotMods)
  for i, mod in ipairs(thisEventShootProjectileMods) do
    if mod.modCategory ~= "shoot" then
      table.remove(thisEventShootProjectileMods, i)
    end
  end

  print(util.tprint(thisEventShootProjectileMods))

  -- find "projectile modifier" mods; for each one found, apply its effects to each projectile-spawning mod
  for i, mod in ipairs(thisShotMods) do
    if mod.modCategory == "projectileModifier" then
      thisEventShootProjectileMods = mod.apply(thisEventShootProjectileMods)
    end
  end

  print(util.tprint(thisEventShootProjectileMods))

  -- call the gun's shoot function
  gunContainingEvent:shoot(thisEventShootProjectileMods, true, false)
end

-- The shoot function for shooting a specific gun, which is passed in via arg.
-- This function handles creating the projectiles from the gun's mods and resetting its cooldown,
-- as well as returning the knockback force, so whoever shot the gun can apply it to themself.
-- The code calling this function should fetch the gun they want to shoot from the gun masterlist via ID,
-- then pass that gun in as an argument.
-- args:
-- gun (gun object): the gun to shoot
-- shootMods(table): an iterable table of every shoot mod to spawn a projectile for in the event
-- triggerCooldown(bool): whether or not to reset the gun's cooldown timer; some shots triggered by events are 'bonus' shots and don't reset cooldown
-- ignoreCooldown(bool): whether or not to bypass the gun checking its cooldown before shooting: true makes the gun always shoot
local function shoot (gun, shootMods, triggerCooldown, ignoreCooldown) -- {{{

  if not ignoreCooldown and gun.current.cooldown >= 0 then
    return
  end
  -- spawn projectiles for every shoot projectile mod in the event, incrementing total cooldown with each projectile's contribution
  local totalCooldown = 0
  local totalKnockback = 0
  for _, mod in ipairs(shootMods) do
    if mod.modCategory == "shoot" then
      totalCooldown = totalCooldown + mod.projCooldown
      totalKnockback = totalKnockback + mod.holderKnockback
      projectileLib.createProjectile(gun.uid, mod, gun.current.projectileSpawnPosX, gun.current.projectileSpawnPosY, gun.current.absoluteAimAngle)
    end
  end

  -- calculate and apply knockback from the shot to whatever physics object in the world is wielding it
  local wielderKnockbackX, wielderKnockbackY = gun.current.wielder.calculateShotKnockback(totalKnockback, gun.current.absoluteAimAngle)
  gun.current.wielder.addToThisTickPlayerKnockback(wielderKnockbackX, wielderKnockbackY)

  -- if a not a bonus shot, reset the cooldown
  if triggerCooldown then gun.current.cooldown = totalCooldown end

  -- regardless of whether shot is bonus shot, cache the cumulative cooldown
  gun.current.totalCooldown = totalCooldown

end -- }}}

-- update a gun instance's stored position and angle for this physics tick
local function updateGunPositionAndAngle (gun, posX, posY, absoluteAimAngle)
  gun.current.projectileSpawnPosX = posX
  gun.current.projectileSpawnPosY = posY
  gun.current.absoluteAimAngle = absoluteAimAngle
end


local function draw (gunId, player) -- {{{
  -- print("drawing gun w/id "..gunId)
  local gun = M.gunlist[gunId]
  local adjustedAimAngle = player.currentAimAngle + gun.current.recoilAimPenaltyOffset

  local spriteLocationOffsetX = math.sin(adjustedAimAngle) * (gun.playerHoldDistance + player.hardboxRadius)
  local spriteLocationOffsetY = math.cos(adjustedAimAngle) * (gun.playerHoldDistance + player.hardboxRadius)
  -- if the player is aiming left, flip the gun sprite
  local flipGunSprite = 1
  if adjustedAimAngle < 0 then
    flipGunSprite = -1
  end
  if arg[2] == "debug" then
    -- draws the angle where the player is aiming with their mouse as a line in red
    love.graphics.setColor(1,0,0,1)
    local aimX1 = player.body:getX()+(math.sin(player.currentAimAngle) * player.hardboxRadius)
    local aimX2 = player.body:getX()+(math.sin(player.currentAimAngle) * player.reachRadius)
    local aimY1 = player.body:getY()+(math.cos(player.currentAimAngle) * player.hardboxRadius)
    local aimY2 = player.body:getY()+(math.cos(player.currentAimAngle) * player.reachRadius)
    love.graphics.line(aimX1, aimY1, aimX2, aimY2)
    -- draws the gun's current aim angle, factoring in recoil penalty, in orange
    love.graphics.setColor(1,0.5,0,0.6)
    local recoilX2 = player.body:getX()+(math.sin(player.currentAimAngle) * player.reachRadius)
    local recoilY2 = player.body:getY()+(math.cos(player.currentAimAngle) * player.reachRadius)
    love.graphics.line(player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, player.body:getX()+(spriteLocationOffsetX*2), player.body:getY()+(spriteLocationOffsetY*2))
  end

  -- reset the colors so gun sprite uses proper palette
  love.graphics.setColor(1,1,1,1)

  -- draw the gun sprite
  -- y-origin arg has a small positive offset to line up placeholder sprite's barrel with actual aim angle, this is temporary and will need to vary with other gun sprites
  local gunSprite = love.graphics.newImage("assets/generic_gun.png")
  love.graphics.draw(gunSprite, player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, (math.pi/2) - adjustedAimAngle, 0.3, 0.3*flipGunSprite, 0, 15)
end -- }}}

-- This function creates a gun with arg-specified mods installed, adds it to `gunlist`, and returns its UID.
-- args:
-- events(table): table of events to add to new gun, see seededGuns.lua file for format
-- firegroup(num): the firegroup to put the new gun in, defaults to 1 if not specified
M.createGun = function(events, firegroup) -- {{{
  local gun = {}
  -- set cooldown of new gun
  -- `gun.current` holds all data about the gun that is modified by player actions during gameplay
  -- (cooldown, firegroup, etc)
  gun.current = {}
  gun.current.totalCooldown = M.calculateShotCooldownFromGun(gun, "onPressShoot")

  -- set firegroup of new gun, default to 1 if not specified
  gun.current.firegroup = firegroup or 1

  -- create shootQueue for new gun
  -- the shootQueue is used for burst fire and other mods that create time-delayed shots
  gun.current.shootQueue = {}

  -- set recoil penalty state of new gun to zero on equip (no penalty)
  gun.current.recoilAimPenaltyOffset = 0

  -- load mods into new gun instance
  gun.events = events

  gun.current.totalCooldown = M.calculateShotCooldownFromGun(gun, "onPressShoot")

  gun.playerHoldDistance = 5

  -- set UID of new gun: this never changes once a gun is created
  gun.uid = util.gen_uid("guns")

  -- add methods
  gun.shoot = shoot
  gun.draw = draw
  foundGun.updateGunPositionAndAngle = updateGunPositionAndAngle
  foundGun.triggerEvent = triggerEvent
  -- gun.modify = modify

  -- add it to the list of all guns in world, then return its uid
  M.gunlist[gun.uid] = gun
  return gun.uid
end -- }}}

-- Create an instance of one of the pre-defined guns specified in `gundefs/seededGuns.lua`
-- args:
-- byName(string): find and create a gun, specified by its name property in the seeded guns list
-- byTier(number): create a random gun from the list with a specified tier
-- (if both byName and byTier are specified, searching by name takes priority)
-- firegroup(num): the firegroup the created gun should have
-- returns: UID of new gun instance if successful, -1 otherwise
M.createGunFromDefinition = function(byName, byTier, firegroup) -- {{{
  local gunDefs = dofile("gundefs/seededGuns.lua")
  local foundGun
  if byName ~= nil then
    -- search by name
    for _, gun in ipairs(gunDefs.seededGuns) do
      print("byName: "..gun.name)
      if gun.name == byName then foundGun = gun end
    end
    -- if can't find gun with that name, return fail
    if foundGun == nil then return -1 end

  elseif byTier ~= nil then
    -- select randomly by tier
    local gunsMatchingTier = {}
    for _, gun in ipairs(gunDefs.seededGuns) do
      if gun.tier == byTier then
        table.insert(gunsMatchingTier, gun)
      end
    end
    local randIndex = math.random(1, #gunsMatchingTier)
    -- if can't find any guns of the specified tier, return fail
    if gunsMatchingTier[randIndex] ~= nil then
      foundGun = gunsMatchingTier[randIndex]
    else return -1 end
  end

  foundGun.current = {}
  foundGun.current.cooldown = 0
  foundGun.current.totalCooldown = M.calculateShotCooldownFromGun(foundGun, "onPressShoot")

  foundGun.current.firegroup = firegroup or 1

  foundGun.current.recoilAimPenaltyOffset = 0

  foundGun.current.shootQueue = {}

  -- load mods into new gun instance
  foundGun.events = foundGun.events

  foundGun.playerHoldDistance = 5

  foundGun.uid = util.gen_uid("guns")

  foundGun.shoot = shoot
  foundGun.draw = draw
  foundGun.updateGunPositionAndAngle = updateGunPositionAndAngle
  foundGun.triggerEvent = triggerEvent

  -- add it to the list of all guns in world, then return its uid
  M.gunlist[foundGun.uid] = foundGun
  return foundGun.uid
end -- }}}

-- Function players, enemies, and gun items call to equip (or "wield", if you will) a gun.
-- The gun must already exist, and is identified by its UID.
-- Using this function allows the gunlib to keep track of who is using what gun.
-- Only one entity can wield a gun at a time; if a new entity calls equipGun on an already-wielded gun,
-- ownership will transfer to the newly specified wielder.
-- Whoever is using the gun should then add that UID to a list of gun UIDs they own.
-- To shoot/render the gun from outside this file, use `gunlib.gunlist[gunUID]:shoot()`.
-- args:
-- gunUid (num): UID of gun to equip
-- firegroup(num): firegroup to set for gun
-- wielder(ref): a reference to the entity wielding the gun; either a player, npc, or gun worlditem
-- returns: true if successful, false if gun with specified UID doesn't exist
M.equipGun = function(gunUid, firegroup, wielder)
  if M.gunlist[gunUid] ~= nil then
    M.gunlist[gunUid].current.firegroup = firegroup or 1
    M.gunlist[gunUid].current.wielder = wielder
    return true
  else
    return false
  end
end

M.setup = function()
  M.gunlist = {}
end

-- assorted utility functions {{{
local function recoverFromRecoilPenalty(dt, gun)
  -- if gun.current.recoilAimPenaltyOffset > (gun.recoilRecoverySpeed * dt) then
  --   gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset - (gun.recoilRecoverySpeed * dt)
  -- elseif gun.current.recoilAimPenaltyOffset < (-gun.recoilRecoverySpeed * dt) then
  --   gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset + (gun.recoilRecoverySpeed * dt)
  -- else
  --   gun.current.recoilAimPenaltyOffset = 0
  -- end
end

-- From a gun's current mod loadout, calculate the shot cooldown triggered by a specific event
-- args:
-- gun(gun object): the gun to calculate cooldown for
-- eventTrigger (string): the event to calculate cooldown for, identified by its name
-- returns: total cooldown for that event in seconds
M.calculateShotCooldownFromGun = function(gun, eventTrigger)
  local totalCooldown = 0
  -- iterate through gun's events, find the one we're looking for
  for _, event in ipairs(gun.events) do
    if event.trigger_event == eventTrigger then
      -- iterate through that event's mods, summing the cooldown from all its shots
      for _, mod in ipairs(event) do
        if mod.modCategory == "shoot" then
          totalCooldown = totalCooldown + mod.projCooldown
        end
      end
    end
  end
  return totalCooldown
end
-- }}}

M.update = function (dt) -- {{{
  for _,gun in pairs(M.gunlist) do
    -- decrement each gun's cooldown timer
    gun.current.cooldown = gun.current.cooldown - dt

    -- iterate through each gun's shootQueue, decrementing timers and shooting the gun if timer is up
    local next = next
    if next(gun.current.shootQueue) ~= nil then
      for i, queuedShot in ipairs(gun.current.shootQueue) do
        queuedShot.firesIn = queuedShot.firesIn - dt
        -- if queued shot is ready to fire...
        if queuedShot.firesIn <= 0 then
          -- print(queuedShot.shotBy)
          -- then calculate where it should spawn the projectile(s)
          -- local shotWorldOriginX = math.sin(queuedShot.shotBy.currentAimAngle) * (gun.playerHoldDistance + queuedShot.shotBy.hardboxRadius)
          -- local shotWorldOriginY = math.cos(queuedShot.shotBy.currentAimAngle) * (gun.playerHoldDistance + queuedShot.shotBy.hardboxRadius)
          -- then shoot the gun and apply the knockback to whoever shot it
          -- local shotKnockback = gun:shoot("onPressShoot", queuedShot.shotBy.body:getX()+shotWorldOriginX, queuedShot.shotBy.body:getY()+shotWorldOriginY, queuedShot.shotBy.currentAimAngle, true)
          -- projectileLib.createProjectile(gun.uid, mod, x, y, worldRelativeAimAngle)
          -- local knockbackX, knockbackY = queuedShot.shotBy.calculateShotKnockback(shotKnockback, queuedShot.shotBy.crosshairCacheX, queuedShot.shotBy.crosshairCacheY)
          -- queuedShot.shotBy.addToThisTickPlayerKnockback(knockbackX, knockbackY)
          -- finally, remove the fired shot from the queue
          -- gun.current.shootQueue[i] = nil
        end
      end
    end

    -- if player has managed to get recoil aim penalty past a full rotation counterclockwise or clockwise (impressive),
    -- modulo the value so the recoil recovery doesn't spin more than a full rotation
    -- if gun.current.recoilAimPenaltyOffset > math.pi*2 then
    --   gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset % (2*math.pi)
    -- elseif gun.current.recoilAimPenaltyOffset < -math.pi*2 then
    --   gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset % (-2*math.pi)
    -- end
    -- recoverFromRecoilPenalty(dt, gun)

    -- print(gun.uid.." : "..gun.current.recoilAimPenaltyOffset)
  end
end -- }}}

-- debug functions {{{
M.dumpGunTable = function()
  print("master gunlist: "..util.tprint(M.gunlist))
end
-- }}}

return M
-- vim: foldmethod=marker
