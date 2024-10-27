-- Module for guns and the various things you can do with them.
-- Gun objects, as defined in this module, are strictly data and function-bearing constructs;
-- no code for making them exist as a physics object in the world is present here.
-- To be an interactable part of the game world, a gun must have a `wielder`, that is:
-- a player, NPC, or item that "owns" the gun object.
-- The wielder is responsible for determining and updating the gun's position and aim in the world.
-- To make a gun that exists on its own in the game world as an item a player can pick up and has physics properties,
-- create a gun and have an item (as defined in `items.lua`) take ownership of it.

local M = { }

M.gunlist = {} -- data for every gun created lives here, indexed by UID

local projectileLib = require'projectiles'
local util = require'util'

-- Event trigger/add/modify/remove code {{{
-- The function called when an event is triggered, which evaluates and executes its mods.
-- This means all mods, including barrel ones; when an event is triggered,
-- this function will either call the gun's `shoot()` method or add shots to its queue as appropriate.
-- This function is set as a method of every gun object in createGun functions.
-- Thus, it can be called with colon syntax to skip the first arg, e.g. `gunObj:triggerEvent(eventString, modsInEvent)`
-- args:
-- gunContainingEvent(gun obj): the gun containing the event you want to trigger.
-- eventName(string): the string key for the event you want to trigger, most commonly "onPressShoot"
local function triggerEvent (gun, eventName) -- {{{
  -- iterate through the gun's events and find the one we're looking for, then cache its mods
  local event
  if gun.events[eventName] then
    event = gun.events[eventName]
  else
    return
  end

  -- find and cache barrel mods
  local thisEventBarrelMods = {}
  for _,mod in ipairs(event.mods) do
    local thisMod = mod()
    if thisMod.modCategory == "barrel" then
      table.insert(thisEventBarrelMods, thisMod)
    end
  end

  -- find ammo mods; for each one found, apply its effects to each barrel mod
  for _,mod in ipairs(event.mods) do
    local thisMod = mod()
    if thisMod.modCategory == "ammo" then
      -- some ammo mods (like burst fire) need to access the gun's shoot queue,
      -- which is why we pass the gun in as an arg
      thisEventBarrelMods = thisMod.apply(gun, thisEventBarrelMods)
    end
  end

  -- find action mods; for each found, run it
  for _,mod in ipairs(event.mods) do
    local thisMod = mod()
    if thisMod.modCategory == "action" then
      if thisMod.onActivation ~= nil then
        thisMod.onActivation()
      end
    end
  end

  -- trigger mods don't live in events--only in guns
  -- thus, they don't trigger via triggerEvent

  -- call the gun's shoot function with the freshly modified barrel mods
  gun:shoot(thisEventBarrelMods, true, false)
end -- }}}

-- function for adding a new event to an existing gun
-- args:
-- gun(gun obj): existing gun to add the event to
-- eventName(string): a string used as the key for the event in the gun's events table
-- modsInEvent(table): a table containing mods to put into the event at creation time (optional)
-- returns true if successfully created, false if failed because event already exists on gun
local function addEvent(gun, eventName, modsInEvent, setArmed) -- {{{
  if gun.events[eventName] ~= nil then return false end
  if modsInEvent == nil then modsInEvent = {} end
  gun.events[eventName].mods = modsInEvent
  gun.events[eventName].armed = setArmed
  return true
end -- }}}

-- function for modifying an existing event on an existing gun
-- `newModList` completely overwrites the existing event modlist;
-- no previously existing mods on the event are preserved
-- if `newModList` is nil, an empty table is used
-- args:
-- gun(gun obj): existing gun to modify the events of
-- eventName(string): string key of the event to modify
-- newModList(table): table containing full list of mods to replace old event modlist with
-- returns true if successfully modified, false if failed because event doesn't exist on gun
local function modifyEvent(gun, eventName, newModList) -- {{{
  if gun.events[eventName] == nil then return false end
  if newModList == nil then newModList = {} end
  gun.events[eventName].mods = newModList
  return true
end -- }}}

-- event arming getters/setters {{{
-- function for getting whether or not a specific event is armed on a gun
local function getArmed(gun, eventName)
  return gun.events[eventName].armed
end

-- function for toggling whether an event is armed or not
local function toggleArmed(gun, eventName)
  gun.events[eventName].armed = not gun.events[eventName].armed
end -- }}}

-- function for removing an existing event on an existing gun
-- the list of mods in the event are lost upon event removal;
-- if the mods in the event need to be placed in the player's inventory, do that before removing the event
-- args:
-- gun(gun obj): existing gun to remove the event from
-- eventName(string): string key of the event to remove
-- returns true if successfully removed, false if event doesn't exist on gun
local function removeEvent(gun, eventName) -- {{{
  if gun.events[eventName] == nil then return false end
  gun.events[eventName] = nil
  return true
end -- }}}
-- }}}

-- The shoot function for shooting a specific gun once, which is passed in via arg.
-- This function handles creating the projectiles from the gun's mods and resetting its cooldown,
-- as well as applying the knockback from the shot to the gun's wielder.
-- args:
-- gun (gun object): the gun to shoot
-- barrelMods(table): an iterable table of every barrel mod to spawn a projectile for in the event
-- triggerCooldown(bool): whether or not to reset the gun's cooldown timer; true makes the cooldown reset, false bypasses it
-- ignoreCooldown(bool): whether or not to bypass the pre-shot cooldown check: true makes the gun always shoot, even if still on cooldown
local function shoot (gun, barrelMods, triggerCooldown, ignoreCooldown) -- {{{
  -- if the cooldown isn't over and we're not ignoring it, cancel the shot
  if not ignoreCooldown and gun.current.cooldown >= 0 then
    return
  end
  -- spawn projectiles for every barrel mod in the event, incrementing total cooldown with each projectile's contribution
  local totalCooldown = 0
  local totalKnockback = 0
  for _, mod in ipairs(barrelMods) do
    if mod.modCategory == "barrel" then
      totalCooldown = totalCooldown + mod.cooldownCost
      totalKnockback = totalKnockback + mod.holderKnockback
      projectileLib.createProjectile(gun.uid, mod, gun.current.projectileSpawnPosX, gun.current.projectileSpawnPosY, gun.current.absoluteAimAngle, gun.current.wielder:getTeam())
    end
  end

  -- calculate and apply knockback from the shot to whatever physics object in the world is wielding it
  local wielderKnockbackX, wielderKnockbackY = gun.current.wielder:calculateShotKnockback(totalKnockback, gun.current.absoluteAimAngle)
  gun.current.wielder:addToThisTickKnockback(wielderKnockbackX, wielderKnockbackY)

  -- trigger the cooldown, if arg says we should
  if triggerCooldown then
    gun.current.cooldown = totalCooldown
    gun.current.lastSetCooldownValue = totalCooldown
  end
end -- }}}

-- update a gun instance's stored position and angle for this physics tick
local function updateGunPositionAndAngle (gun, x, y, angle)
  gun.current.x = x
  gun.current.y = y
  gun.current.angle = angle
  gun.current.flipped = false
  gun.current.projectileSpawnPosX = x -- i'm not sure how it's implemented, but it probably makes more
  gun.current.projectileSpawnPosY = y -- sense to just set gun pos and spawn bullets at the front?
  gun.current.absoluteAimAngle = angle
end

local function draw (gunId, player) -- {{{
  local gun = M.gunlist[gunId]
  love.graphics.setColor(1,1,1,1)

  local gunSprite = love.graphics.newImage("assets/generic_gun.png")
  love.graphics.draw(gunSprite, gun.current.x, gun.current.y, gun.current.absoluteAimAngle, 0.3, 0.3, 0, 15)

  -- the old code

  -- print("drawing gun w/id "..gunId)
  -- local gun = M.gunlist[gunId]
  -- local adjustedAimAngle = player.currentAimAngle + gun.current.recoilAimPenaltyOffset
  --
  -- local spriteLocationOffsetX = math.sin(adjustedAimAngle) * (gun.playerHoldDistance + player.hardboxRadius)
  -- local spriteLocationOffsetY = math.cos(adjustedAimAngle) * (gun.playerHoldDistance + player.hardboxRadius)
  -- -- if the player is aiming left, flip the gun sprite
  -- local flipGunSprite = 1
  -- if adjustedAimAngle < 0 then
  --   flipGunSprite = -1
  -- end
  -- if arg[2] == "debug" then
  --   -- draws the angle where the player is aiming with their mouse as a line in red
  --   love.graphics.setColor(1,0,0,1)
  --   local aimX1 = player.body:getX()+(math.sin(player.currentAimAngle) * player.hardboxRadius)
  --   local aimX2 = player.body:getX()+(math.sin(player.currentAimAngle) * player.reachRadius)
  --   local aimY1 = player.body:getY()+(math.cos(player.currentAimAngle) * player.hardboxRadius)
  --   local aimY2 = player.body:getY()+(math.cos(player.currentAimAngle) * player.reachRadius)
  --   love.graphics.line(aimX1, aimY1, aimX2, aimY2)
  --   -- draws the gun's current aim angle, factoring in recoil penalty, in orange
  --   love.graphics.setColor(1,0.5,0,0.6)
  --   local recoilX2 = player.body:getX()+(math.sin(player.currentAimAngle) * player.reachRadius)
  --   local recoilY2 = player.body:getY()+(math.cos(player.currentAimAngle) * player.reachRadius)
  --   love.graphics.line(player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, player.body:getX()+(spriteLocationOffsetX*2), player.body:getY()+(spriteLocationOffsetY*2))
  -- end
  --
  -- -- reset the colors so gun sprite uses proper palette
  -- love.graphics.setColor(1,1,1,1)
  --
  -- -- draw the gun sprite
  -- -- y-origin arg has a small positive offset to line up placeholder sprite's barrel with actual aim angle, this is temporary and will need to vary with other gun sprites
  -- local gunSprite = love.graphics.newImage("assets/generic_gun.png")
  -- love.graphics.draw(gunSprite, player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, (math.pi/2) - adjustedAimAngle, 0.3, 0.3*flipGunSprite, 0, 15)
end -- }}}

-- This function creates a gun with arg-specified mods installed, adds it to `gunlist`, and returns its UID.
-- args:
-- events(table): table of events to add to new gun, see seededGuns.lua file for format
M.createGun = function(events) -- {{{
  local gun = {}
  -- set cooldown of new gun
  -- `gun.current` holds all data about the gun that is modified by player actions during gameplay
  -- (cooldown, firegroup, etc)
  gun.current = {x = 0, y = 0}
  gun.current.lastSetCooldownValue = M.calculateShotCooldownFromGun(gun, "onPressShoot")

  -- create shootQueue for new gun
  -- the shootQueue is used for burst fire and other mods that create time-delayed shots
  gun.current.shootQueue = {}

  -- set recoil penalty state of new gun to zero on equip (no penalty)
  gun.current.recoilAimPenaltyOffset = 0

  -- load mods into new gun instance
  gun.events = events

  gun.current.lastSetCooldownValue = M.calculateShotCooldownFromGun(gun, "onPressShoot")

  gun.playerHoldDistance = 5

  -- set UID of new gun: this never changes once a gun is created
  gun.uid = util.gen_uid("guns")

  -- add methods
  gun.shoot = shoot
  gun.draw = draw
  gun.updateGunPositionAndAngle = updateGunPositionAndAngle
  gun.triggerEvent = triggerEvent
  gun.addEvent = addEvent
  gun.modifyEvent = modifyEvent
  gun.removeEvent = removeEvent
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
-- returns: UID of new gun instance if successful, -1 otherwise
M.createGunFromDefinition = function(byName, byTier) -- {{{
  local gunDefs = dofile("gundefs/seededGuns.lua")
  local foundGun
  if byName ~= nil then
    -- search by name
    for _, gun in ipairs(gunDefs.seededGuns) do
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
  foundGun.current.lastSetCooldownValue = M.calculateShotCooldownFromGun(foundGun, "onPressShoot")

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
  foundGun.addEvent = addEvent
  foundGun.modifyEvent = modifyEvent
  foundGun.removeEvent = removeEvent

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
-- wielder(ref): a reference to the entity wielding the gun; either a player, npc, or gun worlditem
-- returns: true if successful, false if gun with specified UID doesn't exist
M.equipGun = function(gunUid, firegroup, wielder) -- {{{
  if M.gunlist[gunUid] ~= nil then
    M.gunlist[gunUid].current.firegroup = firegroup or 1
    M.gunlist[gunUid].current.wielder = wielder
    return true
  else
    return false
  end
end -- }}}

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

-- From a event's current mod loadout in a given gun, calculate the shot cooldown
-- This only accounts for barrel mods in the event
-- args:
-- gun(gun object): the gun to calculate cooldown for
-- eventName (string): the event to calculate cooldown for, identified by its name
-- returns: total cooldown for that event in seconds
M.calculateShotCooldownFromGun = function(gun, eventName)
  local totalCooldown = 0
  -- iterate through gun's events, find the one we're looking for
  if gun.events[eventName] then
    local event = gun.events[eventName]
      -- iterate through that event's mods, summing the cooldown from all its shots
      for _, mod in ipairs(event) do
      local thisMod = mod()
        if thisMod.modCategory == "barrel" then
          totalCooldown = totalCooldown + thisMod.cooldownCost
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
    if next(gun.current.shootQueue) ~= nil then
      for i, queuedShot in ipairs(gun.current.shootQueue) do
        queuedShot.firesIn = queuedShot.firesIn - dt
        -- if queued shot is ready to fire...
        if queuedShot.firesIn <= 0 then
          -- then shoot the gun
          M.gunlist[queuedShot.fromGunWithUid]:shoot(queuedShot.projectiles, false, queuedShot.ignoreCooldown)
          -- finally, remove the fired shot from the queue
          table.remove(gun.current.shootQueue, i)
        end
      end
    end

    -- run any update callbacks for this gun's events
    -- loop through gun's events, checking for the presence of a callback on each
    --
    -- if there is one for that event, run it

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
  print("full gunlist: "..util.tprint(M.gunlist))
end
-- }}}

return M
-- vim: foldmethod=marker
