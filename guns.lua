local M = { }
local gunlist = {}

local function shoot (gun, x, y) -- {{{
  gun.cooldown = gun.maxCooldown
  -- store the state of the shot, so mods can modify it as they go
  -- adding more chaos each time, hopefully
  local shot = {recoil=0, damage=0} -- stuff like spread, pellets, speed, etc everything idk yet
    for _, mod in ipairs(gun.mods) do
      shot = mod:apply(shot)
    end

  if gun.type == "hitscan" then
    -- cast a ray etc
  end

  return shot.recoil
end -- }}}

-- have each gun's base behaviors be secretly a mod (and not here)
-- would work great for grafting guns together
M.create = function(type, cooldown) -- {{{
-- create test gun
  local gun = require'gundefs/testgun'

  -- -- not sure how we'll do this with mods, prob just recalculate it on each mod change
  -- -- tmp
  gun.maxCooldown = cooldown
  -- gun.cooldown = cooldown

  -- add methods
  gun.shoot = shoot
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
