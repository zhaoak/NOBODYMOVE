-- Data for all "modify projectiles" mods is defined here.
-- See todo.md for more details on mod types.

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

M.projectileDiffractor = function()
  local modTable = {}
  modTable.modCategory = "projectileModifier"
  modTable.displayName = "Bullet Diffractor"
  modTable.description = "Shoot three of every projectile, but with much lower range, accuracy and a longer cooldown"
  modTable.apply = function(shootProjectileMods)
    local alteredShootMods = {}
    for _, shootMod in ipairs(shootProjectileMods) do
      shootMod.projCooldown = shootMod.projCooldown * 1.5
      shootMod.projLinearDamping = shootMod.projLinearDamping + 5
      shootMod.projInaccuracy = shootMod.projInaccuracy + math.rad(15)
      shootMod.holderKnockback = shootMod.holderKnockback * 5
      table.insert(alteredShootMods, shootMod)
      table.insert(alteredShootMods, shootMod)
      table.insert(alteredShootMods, shootMod)
    end
    return alteredShootMods
  end
  return modTable
end


-- M.burstFire = function()
--   local modTable = {}
--   modTable.modCategory = "projectileModifier"
--   modTable.displayName = "Burst fire"
--   modTable.description = "Shots in this event fire sequentially, rather than all at once"
--   modTable.apply = function(gun, eventModList)
--     local cumulativeCooldown = 0
--     for _, mod in ipairs(eventModList) do
--       if mod.modCategory == "shoot" then
--         local queuedShot = {}
--         queuedShot.firesIn = cumulativeCooldown
--         cumulativeCooldown = cumulativeCooldown + mod.projCooldown
--         queuedShot.shotBy = gun.current.wielder
--         table.insert(gun.current.shootQueue, queuedShot)
--       end
--     end
--   end
--   return modTable
-- end

return M
-- vim: foldmethod=marker
