-- Data for all "modify projectiles" mods is defined here.
-- See todo.md for more details on mod types.

local M = { }

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
