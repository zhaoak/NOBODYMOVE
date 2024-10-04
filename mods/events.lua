-- Data for all "trigger event" mods is defined here.
-- See todo.md for more details on mod types.

local M = {}

M.templateTriggerEventMod = function()
  local modTable = {}
  -- all mods, regardless of type, have these three fields
  modTable.modCategory = "event"
  -- Name of this mod as displayed to the player in the UI
  modTable.displayName = "Template Trigger Event Mod"
  modTable.description = "Commented demonstration of trigger event mod format"

  -- the list of events this mod adds to guns it's equipped on
  modTable.triggersEvents = {
  }

  return modTable
end
return M
-- vim: foldmethod=marker
