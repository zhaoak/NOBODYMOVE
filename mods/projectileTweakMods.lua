-- Data for all "modify projectiles" mods is defined here.
-- See todo.md for more details on mod types.
--
local util = require'util'

local M = { }

M.exampleProjectileTweakMod = function()
  local modTable = {}
  -- all mods, regardless of type, have these three fields
  modTable.modCategory = "projectileModifier"
  modTable.displayName = "Example Projectile Tweak Mod"
  modTable.description = "Commented demonstration of projectile tweak mod format, increases cooldown by 50%"
  -- during the triggerEvent function call, a copy of all the event's "shoot projectile" mods are run through this function in a single table
  -- the passed-in shoot mods are modified and returned, and then from there,
  -- triggerEvent() calls the gun's shoot function, passing it the processed shoot mods
   modTable.apply = function(shootProjectileMods)
    for _, shootMod in ipairs(shootProjectileMods) do
      shootMod.projCooldown = shootMod.projCooldown * 1.5
    end
    return shootProjectileMods
  end
  return modTable
end

M.shotgunify = function()
  local modTable = {}
  modTable.modCategory = "projectileModifier"
  modTable.displayName = "Bullet Diffractor"
  modTable.description = "Shoot three of every projectile, but with much lower range, accuracy and a longer cooldown"

  modTable.apply = function(gun, shootProjectileMods)
    local alteredShootMods = {}
    -- for each shoot mod in the event...
    for _, shootMod in ipairs(shootProjectileMods) do
      -- tweak its stats like so...
      shootMod.projLinearDamping = shootMod.projLinearDamping + 3
      shootMod.projInaccuracy = shootMod.projInaccuracy + math.rad(15)
      shootMod.holderKnockback = shootMod.holderKnockback * 5
      -- and create two additional copies of itself
      table.insert(alteredShootMods, shootMod)
      table.insert(alteredShootMods, shootMod)
      table.insert(alteredShootMods, shootMod)
    end
    -- then return the new table of shoot mods
    return alteredShootMods
  end
  return modTable

end

M.burstFire = function()
  local modTable = {}
  modTable.modCategory = "projectileModifier"
  modTable.displayName = "Burst fire"
  modTable.description = "Shots in this event fire sequentially, rather than all at once"

  modTable.apply = function(gun, shootProjectileMods)
    local cumulativeShotTimer = 0 -- for tracking the summed cooldown from every shot in burst
    if gun.current.cooldown > 0 then return {} end -- if gun is on cooldown, do nothing
    for _, mod in ipairs(shootProjectileMods) do
      if mod.modCategory == "shoot" then
        -- queue each projectile to fire sequentially after cooldown of previous shot is done
        local queuedShot = {}
        queuedShot.firesIn = cumulativeShotTimer
        cumulativeShotTimer = cumulativeShotTimer + mod.projCooldown
        queuedShot.fromGunWithUid = gun.uid
        queuedShot.ignoreCooldown = true
        queuedShot.projectiles = {mod}
        table.insert(gun.current.shootQueue, queuedShot)
      end
    end
    -- set gun's cooldown to the sum of every projectile in the burst times 2
    gun.current.cooldown = cumulativeShotTimer * 2
    gun.current.lastSetCooldownValue = cumulativeShotTimer * 2
    -- don't return any of the projectiles to be shot in this burst, they're all queued instead
    return {}
  end

  return modTable
end

return M
-- vim: foldmethod=marker
