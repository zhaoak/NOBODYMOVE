local M = { }

M.gunlist = {} -- data for every gun existing in world, held by player or enemy, lives here

local projectileLib = require'projectiles'
local util = require'util'


-- The shoot function for shooting a specific gun, which is passed in via arg.
-- This function handles creating the projectiles from the gun,
-- as well as returns the knockback force, so whoever shot the gun can calculate the knockback force.
-- The code calling this function should fetch the gun they want to shoot from the gun masterlist via ID,
-- then pass that gun in as an argument.
local function shoot (gun, x, y, worldRelativeAimAngle) -- {{{
  gun.current.cooldown = gun.cooldown
  -- store the state of the shot, so mods can modify it as they go
  -- adding more chaos each time, hopefully
  local shot = {holderKnockback=gun.holderKnockback, damage=gun.hitDamage} -- stuff like spread, pellets, speed, etc everything idk yet

  -- for _, mod in ipairs(gun.mods) do
  --   shot = mod:apply(shot)
  -- end

  if gun.type == "hitscan" then
    -- cast a ray etc
  end

  if gun.type == "bullet" then
    projectileLib.createBulletShot(gun, x, y, worldRelativeAimAngle)
  end

  -- apply recoil penalty to gun's aim
  -- randomly select either -1 or +1, to randomly select if recoil will apply clockwise or counterclockwise
  local randTable = { [1] = -1, [2] = 1 }
  local rand = math.random(2)
  local recoilAimPenalty = gun.recoil * randTable[rand]
  -- then apply the penalty
  gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset + recoilAimPenalty

  return shot.holderKnockback
end -- }}}

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
    -- draws the angle where the player is aiming with their mouse in red
    love.graphics.setColor(1,0,0,1)
    love.graphics.circle("fill", player.body:getX()+(math.sin(player.currentAimAngle) * player.reachRadius), player.body:getY()+(math.cos(player.currentAimAngle) * player.reachRadius), 5)
    -- draws the gun's current aim angle, factoring in recoil penalty, in orange
    love.graphics.setColor(1,0.5,0,0.6)
    love.graphics.circle("fill", player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, 5)
  end

  -- reset the colors so gun sprite uses proper palette
  love.graphics.setColor(1,1,1,1)

  -- draw the gun sprite
  -- y-origin arg has a small positive offset to line up testgun sprite's barrel with actual aim angle, this is temporary and will need to vary with other guns
  love.graphics.draw(gun.gunSprite, player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, (math.pi/2) - adjustedAimAngle, 0.3, 0.3*flipGunSprite, 0, 15)
end -- }}}

-- This function creates a gun, adds it to `gunlist`, and returns its UID.
-- Whoever is using the gun should then add that UID to a list of gun UIDs they own.
-- To shoot/render the gun from outside this file, use `gunlib.gunlist[gunUID]:shoot()`.
M.equipGun = function(gunName) -- {{{
-- find gundef file by name
  local gun = dofile('gundefs/'..gunName..".lua")

  -- set cooldown of new gun
  gun.current = {}
  gun.current.cooldown = gun.cooldown

  -- set recoil penalty state of new gun to zero on equip (no penalty)
  gun.current.recoilAimPenaltyOffset = 0

  -- set UID of new gun
  gun.uid = util.gen_uid("guns")

  -- add methods
  gun.shoot = shoot
  gun.draw = draw
  -- gun.modify = modify

  -- add it to the list of all guns in world, then return its uid
  M.gunlist[gun.uid] = gun
  return gun.uid
end -- }}}

M.setup = function()
  M.gunlist = {}
end

-- assorted utility functions {{{
local function recoverFromRecoilPenalty(dt, gun)
  if gun.current.recoilAimPenaltyOffset > (gun.recoilRecoverySpeed * dt) then
    gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset - (gun.recoilRecoverySpeed * dt)
  elseif gun.current.recoilAimPenaltyOffset < (-gun.recoilRecoverySpeed * dt) then
    gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset + (gun.recoilRecoverySpeed * dt)
  else
    gun.current.recoilAimPenaltyOffset = 0
  end
end
-- }}}
M.update = function (dt)
  for _,gun in pairs(M.gunlist) do
    gun.current.cooldown = gun.current.cooldown - dt

    -- if player has managed to get recoil aim penalty past a full rotation counterclockwise or clockwise (impressive),
    -- modulo the value so the recoil recovery doesn't spin more than a full rotation
    if gun.current.recoilAimPenaltyOffset > math.pi*2 then
      gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset % (2*math.pi)
    elseif gun.current.recoilAimPenaltyOffset < -math.pi*2 then
      gun.current.recoilAimPenaltyOffset = gun.current.recoilAimPenaltyOffset % (-2*math.pi)
    end

    recoverFromRecoilPenalty(dt, gun)
    -- print(gun.uid.." : "..gun.current.recoilAimPenaltyOffset)
  end
end

-- debug functions {{{
M.dumpGunTable = function()
  print("master gunlist: "..util.tprint(M.gunlist))
end
-- }}}

return M
-- vim: foldmethod=marker
