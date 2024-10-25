-- The callbacks and data for all stock trigger mods.
-- Trigger mods are mods that can add a new event to a gun, which is triggered and run when its trigger occurs (hence the name.)
-- The callbacks that trigger mods have access to are:
--    - `onGunUpdate` -- called during update step for gun the mod is contained in

local M = {}

M.templateTriggerMod = function()
  local modTable = {}
  -- all mods, regardless of type, have these three fields
  modTable.modCategory = "event"
  -- Name of this mod as displayed to the player in the UI
  modTable.displayName = "Template Trigger Mod"
  modTable.description = "Commented demonstration of trigger event mod format"

  -- the list of events this mod adds to guns it's equipped on
  modTable.triggersEvents = {
  }

  return modTable
end
return M
-- vim: foldmethod=marker
