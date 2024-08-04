local M = { }
local gunlist = {}

local function shoot (gun, x, y) -- {{{
  gun.cooldown = gun.maxCooldown
  -- store the state of the shot, so mods can modify it as they go
  -- adding more chaos each time, hopefully
  local shot = {recoil=gun.holderKnockback, damage=0} -- stuff like spread, pellets, speed, etc everything idk yet
    for _, mod in ipairs(gun.mods) do
      shot = mod:apply(shot)
    end

  if gun.type == "hitscan" then
    -- cast a ray etc
  end

  return shot.recoil
end -- }}}

local function draw (gun, player) -- {{{
  -- reset the colors
  love.graphics.setColor(1,1,1,1)

  local spriteLocationOffsetX = math.sin(player.currentAimAngle) * gun.playerHoldDistance
  local spriteLocationOffsetY = math.cos(player.currentAimAngle) * gun.playerHoldDistance
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


-- have each gun's base behaviors be secretly a mod (and not here)
-- would work great for grafting guns together
M.equipGun = function(gunName) -- {{{
-- find gundef file by name
  local gun = require('gundefs/'..gunName)

  -- -- not sure how we'll do this with mods, prob just recalculate it on each mod change
  -- -- tmp
  gun.maxCooldown = gun.cooldown

  -- add methods
  gun.shoot = shoot
  gun.draw = draw
  -- gun.modify = modify

  -- add it to the list
  table.insert(gunlist, gun)
  return gun
end -- }}}

M.update = function (dt)
  for _,gun in ipairs(gunlist) do
    gun.cooldown = gun.cooldown - dt
  end
end

return M
-- vim: foldmethod=marker
