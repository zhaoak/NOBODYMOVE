local util = require("util")
local npc = require("npc")

-- defining a class for all enemies, extended from NPC class
local M = { }

M.enemy = {}
M.enemy.__index = M.enemy

setmetatable(M.enemy, {
  __index = npc,
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:constructor(...)
  end
})

function M:constructor(initialXPos, initialYPos, sprite)
  npc:construct(initialXPos, initialYPos, sprite)
end



return M
-- vim: foldmethod=marker
