local M = { }

M.gunlist = {} -- data for every gun existing in world, player or enemy, lives here

local projectileLib = require'projectiles'
local util = require'util'

local function shoot (gun, x, y, worldRelativeAimAngle) -- {{{
  gun.current.cooldown = gun.cooldown
  -- store the state of the shot, so mods can modify it as they go
  -- adding more chaos each time, hopefully
  local shot = {recoil=gun.holderKnockback, damage=0} -- stuff like spread, pellets, speed, etc everything idk yet

  -- for _, mod in ipairs(gun.mods) do
  --   shot = mod:apply(shot)
  -- end

  if gun.type == "hitscan" then
    -- cast a ray etc
  end

  if gun.type == "bullet" then
    projectileLib.createBulletShot(gun, x, y, worldRelativeAimAngle)
  end

  return shot.recoil
end -- }}}

local function draw (gunId, player) -- {{{
  local gun = M.gunlist[gunId]
  -- reset the colors
  love.graphics.setColor(1,1,1,1)

  local spriteLocationOffsetX = math.sin(player.currentAimAngle) * (gun.playerHoldDistance + player.hardboxRadius)
  local spriteLocationOffsetY = math.cos(player.currentAimAngle) * (gun.playerHoldDistance + player.hardboxRadius)
  -- if the player is aiming left, flip the gun sprite
  local flipGunSprite = 1
  if player.currentAimAngle < 0 then
    flipGunSprite = -1
  end
  if arg[2] == "debug" then
    love.graphics.circle("fill", player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, 5)
  end

  -- draw the gun sprite
  -- y-origin arg has a small positive offset to line up testgun sprite's barrel with actual aim angle, this is temporary and will need to vary with other guns
  love.graphics.draw(gun.gunSprite, player.body:getX()+spriteLocationOffsetX, player.body:getY()+spriteLocationOffsetY, (math.pi/2) - player.currentAimAngle, 0.3, 0.3*flipGunSprite, 0, 15)
end -- }}}

-- This function creates a gun, adds it to `gunlist`, and returns its UID.
-- Whoever is using the gun should then add that UID to a list of gun UIDs they own.
-- To shoot/render the gun from outside this file, use `gunlib.gunlist[gunUID]:shoot()`.
M.equipGun = function(gunName) -- {{{
-- find gundef file by name
  local gun = require('gundefs/'..gunName)

  -- set cooldown of new gun
  gun.current = {}
  gun.current.cooldown = gun.cooldown

  -- set UID of new gun
  gun.uid = util.gen_uid("guns")

  -- set default aim angle for gun
  gun.current.aimAngle = 0

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

M.update = function (dt)
  for _,gun in pairs(M.gunlist) do
    gun.current.cooldown = gun.current.cooldown - dt
  end
end

return M
-- vim: foldmethod=marker
