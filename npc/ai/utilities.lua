-- Module for functions commonly used in NPC AI processing.

local utils = require("util")

local M = {}

-- Check if the player can be seen from an NPC's body position (i.e. is the line between player and NPC unobstructed)
-- Returns false if any props or terrain are between NPC and player body positions, true otherwise
M.canNpcSeePlayer = function(npc, world, playerObj)
  local closestTerrainFract = 1
  local closestPropFract = 1
  local playerFract = 0
  -- this callback func is called during raycast, when the ray hits any fixture
  -- THE CALLBACKS AREN'T ORDERED, the ray could hit a farther fixture before a closer one
  -- That's why we're tracking distance values for the closest prop/terrain, to compare with player distance
  local rayHitCallback = function(fixture, x, y, xn, yn, fraction)
    if fixture:getUserData().type == "terrain" then
      if closestTerrainFract > fraction then closestTerrainFract = fraction end
      return -1
    end
    if fixture:getUserData().type == "prop" then
      closestPropFract = fraction
      return -1
    end
    if fixture:getUserData().type == "player_hardbox" then
      playerFract = fraction
      return -1
    end
    return -1
  end
  -- cast the ray, feeding it our callback
  world:rayCast(npc:getX(), npc:getY(), playerObj.getX(), playerObj.getY(), rayHitCallback)
  -- check fraction values of what we hit
  if playerFract > closestTerrainFract or playerFract > closestPropFract then
    return false
  else
    return true
  end
end

M.getAimAtPlayerAimAngle = function(npc, playerObj)
  return math.atan2(playerObj:getX() - npc:getX(), playerObj:getY() - npc:getY())
end

return M
-- vim: foldmethod=marker
