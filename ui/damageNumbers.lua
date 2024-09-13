-- Module for drawing damage text numbers that appear when something takes or heals damage.

local util = require'util'
local npc = require'npc.npc'

local M = {}

-- defines {{{
-- how many seconds damage text stays on the screen for before disappearing
M.damageTextDrawDuration = 1
-- }}}

-- table holding data for recent damage events
M.damageNumEventList = {}

-- Notify damageText module whenever an NPC has taken damage and should display damageText
M.damageNumberEvent = function(damageAmount, npcHitUid)
  if M.damageNumEventList[npcHitUid] == nil then
    M.damageNumEventList[npcHitUid] = {totalDamage = damageAmount, remainingDrawTime = M.damageTextDrawDuration}
  else
    M.damageNumEventList[npcHitUid].totalDamage = M.damageNumEventList[npcHitUid].totalDamage + damageAmount
    M.damageNumEventList[npcHitUid].remainingDrawTime = M.damageTextDrawDuration
  end
end

-- draw all damageText events
M.drawDamageNumberEvents = function()
  love.graphics.setColor(1, 0, 0, 1)
  for npcUid, damageText in ipairs(M.damageNumEventList) do
    love.graphics.print("-"..tostring(damageText.totalDamage), npc.npcList[npcUid]:getX(), npc.npcList[npcUid]:getY())
  end
end

-- update drawing timer for damage text
M.updateDamageNumberEvents = function(dt)
  for npcUid, damageText in ipairs(M.damageNumEventList) do
    if damageText.remainingDrawTime <= 0 then
      M.damageNumEventList[npcUid] = nil
    else
      damageText.remainingDrawTime = damageText.remainingDrawTime - dt
    end
  end
end

return M
-- vim: foldmethod=marker
