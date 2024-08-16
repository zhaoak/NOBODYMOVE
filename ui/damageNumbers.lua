local util = require'util'
local npc = require'npc.npc'

local M = {}

-- defines {{{
-- how many seconds must pass before more damage on the same target from the same source
-- is displayed as a new num starting from zero, rather than adding to existing damage number display
M.damageEventTimerReset = 0.5

-- how many seconds damage text stays on the screen for before disappearing
M.damageTextDrawDuration = 1
-- }}}

-- table holding data for recent damage events
M.damageNumEventList = {}

M.damageNumberEvent = function(damageAmount, targetHitUid)
  if M.damageNumEventList[targetHitUid] == nil then
    M.damageNumEventList[targetHitUid] = {totalDamage = damageAmount, remainingDrawTime = M.damageTextDrawDuration}
  else
    M.damageNumEventList[targetHitUid].totalDamage = M.damageNumEventList[targetHitUid].totalDamage + damageAmount
    M.damageNumEventList[targetHitUid].remainingDrawTime = M.damageTextDrawDuration
  end
end

M.drawDamageNumberEvents = function()
  love.graphics.setColor(1, 1, 1, 1)
  for npcUid, damageText in ipairs(M.damageNumEventList) do
    if damageText.remainingDrawTime <= 0 then
      M.damageNumEventList[npcUid] = nil
    else
      love.graphics.print("-"..tostring(damageText.totalDamage), npc.npcList[npcUid]:getX(), npc.npcList[npcUid]:getY())
    end
  end
end

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
