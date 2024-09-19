-- Module for drawing damage text numbers that appear when something takes or heals damage.

local util = require'util'

local M = {} -- each NPC that can be damaged has an entry, keyed by the NPC's uid

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
-- args:
-- npcList(table): megalist of NPCs from NPC module
M.drawDamageNumberEvents = function(npcList)
  love.graphics.setColor(1, 1, 1, 0.8)
  for npcUid, damageText in pairs(M.damageNumEventList) do
    love.graphics.print("-"..tostring(damageText.totalDamage), npcList[npcUid]:getX(), npcList[npcUid]:getY())
  end
end

-- update drawing timer for damage text
M.updateDamageNumberEvents = function(dt)
  for npcUid, damageText in pairs(M.damageNumEventList) do
    if damageText.remainingDrawTime <= 0 then
      M.damageNumEventList[npcUid] = nil
    else
      damageText.remainingDrawTime = damageText.remainingDrawTime - dt
    end
  end
end

return M
-- vim: foldmethod=marker
