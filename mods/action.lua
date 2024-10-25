-- The callbacks and data for all stock action mods.
-- Action mods are callbacks that are run immediately when the event containing them is triggered.
-- They're called action mods because they immediately do stuff on activation.
-- The one callback action mods have access to is `onActivation`.
-- args:
--      - uhhh working on it

local M = {}

M.exampleActionMod = function()
  local modTable = {}
  modTable.modCategory = "action"
  modTable.displayName = "Example Action Mod"
  modTable.description = "Example action mod that announces it in the console when it runs"

  modTable.onActivation = function()
    print("Example Action mod's activation callback triggered!")
  end

  return modTable
end

return M
-- vim: foldmethod=marker
