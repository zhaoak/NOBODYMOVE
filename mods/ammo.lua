-- The callbacks and data for all stock ammo mods.
-- Ammo mods change the stats and traits of all projectiles spawned by barrel mods in the event the two share.
-- They're called ammo mods because they change how projectiles behave.
-- All of a projectile's base stats are defined in the barrel mod that spawns it; these are the stats that the ammo mod modifies.
-- Ammo mods can also add or remove traits from projectiles; see mods/traits.lua for more info on traits.
-- Traits are how projectiles run any complex or custom-coded behavior (via callbacks.)

local util = require'util'
local trait = require'mods.traits'

local M = { }

M.exampleAmmoMod = function()
  local modTable = {}
  -- all mods, regardless of type, have these three fields
  modTable.modCategory = "ammo"
  -- Name of this mod as displayed to the player in the UI
  modTable.displayName = "Example Ammo Mod"
  modTable.description = "Commented demonstration of ammo mod format, increases cooldown by 500% and applies exampleTrait"
  -- during the triggerEvent function call, a copy of all the event's barrel mods are run through this function in a single table
  -- the passed-in barrel are modified and returned, and then from there,
  -- triggerEvent() calls the gun's shoot function, passing it the processed barrel mods
   modTable.apply = function(gun, barrelMods)
    for _, barrelMod in ipairs(barrelMods) do
      barrelMod.cooldownCost = barrelMod.cooldownCost * 5
      if barrelMod.traits.exampleTrait == nil then
        -- note that we also apply a trait here, checking to make sure it isn't already defined
        barrelMod.traits.exampleTrait = trait.exampleTrait()
      end
    end
    return barrelMods
  end
  return modTable
end

M.shotgunify = function()
  local modTable = {}
  modTable.modCategory = "ammo"
  modTable.displayName = "Shotgunify"
  modTable.description = "Shoot three of every projectile, but with much lower range, accuracy and a longer cooldown"

  modTable.apply = function(gun, barrelMods)
    -- for each barrel mod in the event...
    for _, barrelMod in ipairs(barrelMods) do
      -- tweak its stats like so...
      barrelMod.linearDamping = barrelMod.linearDamping + 3 -- slow down over time
      barrelMod.despawnBelowVelocity = 250 -- once it gets too slow, despawn it
      barrelMod.inaccuracy = barrelMod.inaccuracy + math.rad(15)
      barrelMod.holderKnockback = barrelMod.holderKnockback * 2
      -- and make it multishot two more projectiles per shot
      barrelMod.spawnCount = barrelMod.spawnCount + 2
    end
    -- then return the new table of barrel mods
    return barrelMods
  end
  return modTable

end

M.burstFire = function()
  local modTable = {}
  modTable.modCategory = "ammo"
  modTable.displayName = "Burst fire"
  modTable.description = "Projectiles in this event rapid-fire sequentially with longer cooldown, rather than all at once"

  modTable.apply = function(gun, barrelMods)
    local cumulativeShotTimer = 0 -- for tracking the summed cooldown from every shot in burst
    if gun.current.cooldown > 0 then return {} end -- if gun is on cooldown, do nothing
    for _, mod in ipairs(barrelMods) do
      if mod.modCategory == "barrel" then
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
