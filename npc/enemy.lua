-- Module for enemies, which are an extension of the NPC class.

local util = require("util")
local npc = require("npc.npc")

-- defining a class for all enemies, extended from NPC class
local enemyClass = { }

enemyClass.__index = enemyClass

setmetatable(enemyClass, {
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
-- args:
-- enemyData(table): pass in the entire table returned by the enemydef file you want to use
function enemyClass:constructor(initialXPos, initialYPos, enemyData)
  local enemyTeamUserData = {team="enemy",name=enemyData.userDataTable.name,health=enemyData.userDataTable.health, aiCycleInterval=enemyData.userDataTable.aiCycleInterval}
  return npc.constructor(self, initialXPos, initialYPos, enemyData.physicsData, enemyTeamUserData, enemyData.spriteData, enemyData.aiCycle, enemyData.guns)
end



return enemyClass
-- vim: foldmethod=marker
