-- Module for enemies, which are an extension of the NPC class.

local util = require("util")
local npc = require("npc.npc")

-- defining a class for all enemies, extended from NPC class
local M = { }

M.__index = M

setmetatable(M, {
  __index = npc,
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:constructor(...)
  end
})

-- everything here is the same as the npc constructor, except we don't need to know the team,
-- since we know this is an enemy npc
-- so userDataTable is just missing the team key/val pair
-- this returns the new enemy's UID
function M:constructor(initialXPos, initialYPos, physicsData, userDataTable, spriteData)
  local enemyTeamUserDataTable = {team="enemy",name=userDataTable.name,health=userDataTable.health}
  return npc:constructor(initialXPos, initialYPos, physicsData, enemyTeamUserDataTable, spriteData)
end



return M
-- vim: foldmethod=marker
