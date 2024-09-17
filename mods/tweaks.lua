-- Data for all "modify projectiles" mods is defined here.
-- See todo.md for more details on mod types.
--
local util = require'util'

local M = { }

M.exampleProjectileTweakMod = function()
  local modTable = {}
  -- all mods, regardless of type, have these three fields
  modTable.modCategory = "tweak"
  -- Name of this mod as displayed to the player in the UI
  modTable.displayName = "Example Projectile Tweak Mod"
  modTable.description = "Commented demonstration of projectile tweak mod format, increases cooldown by 50%"
  -- during the triggerEvent function call, a copy of all the event's "shoot projectile" mods are run through this function in a single table
  -- the passed-in shoot mods are modified and returned, and then from there,
  -- triggerEvent() calls the gun's shoot function, passing it the processed shoot mods
   modTable.apply = function(shootProjectileMods)
    for _, shootMod in ipairs(shootProjectileMods) do
      shootMod.cooldownCost = shootMod.cooldownCost * 1.5
    end
    return shootProjectileMods
  end
  return modTable
end

M.shotgunify = function()
  local modTable = {}
  modTable.modCategory = "tweak"
  modTable.displayName = "Shotgunify"
  modTable.description = "Shoot three of every projectile, but with much lower range, accuracy and a longer cooldown"

  modTable.apply = function(gun, shootProjectileMods)
    -- for each shoot mod in the event...
    for _, shootMod in ipairs(shootProjectileMods) do
      -- tweak its stats like so...
      shootMod.linearDamping = shootMod.linearDamping + 3 -- slow down over time
      shootMod.despawnBelowVelocity = 250 -- once it gets too slow, despawn it
      shootMod.inaccuracy = shootMod.inaccuracy + math.rad(15)
      shootMod.holderKnockback = shootMod.holderKnockback * 2
      -- and make it multishot two more projectiles per shot
      shootMod.spawnCount = shootMod.spawnCount + 2
    end
    -- then return the new table of shoot mods
    return shootProjectileMods
  end
  return modTable

end

M.burstFire = function()
  local modTable = {}
  modTable.modCategory = "tweak"
  modTable.displayName = "Burst fire"
  modTable.description = "Projectiles in this event rapid-fire sequentially with longer cooldown, rather than all at once"

  modTable.apply = function(gun, shootProjectileMods)
    local cumulativeShotTimer = 0 -- for tracking the summed cooldown from every shot in burst
    if gun.current.cooldown > 0 then return {} end -- if gun is on cooldown, do nothing
    for _, mod in ipairs(shootProjectileMods) do
      if mod.modCategory == "projectile" then
        -- queue each projectile to fire sequentially after cooldown of previous shot is done
        local queuedShot = {}
        queuedShot.firesIn = cumulativeShotTimer
        cumulativeShotTimer = cumulativeShotTimer + (mod.cooldownCost / 2)
        queuedShot.fromGunWithUid = gun.uid
        queuedShot.ignoreCooldown = true
        queuedShot.projectiles = {mod}
        table.insert(gun.current.shootQueue, queuedShot)
      end
    end
    -- set gun's cooldown to the sum of every projectile in the burst times 1.5;
    -- since we halved every individual cooldown, we do *3 instead of *1.5 here
    gun.current.cooldown = cumulativeShotTimer * 3
    gun.current.lastSetCooldownValue = cumulativeShotTimer * 3
    -- don't return any of the projectiles to be shot in this burst, they're all queued instead
    return {}
  end

  return modTable
end

return M
-- vim: foldmethod=marker
