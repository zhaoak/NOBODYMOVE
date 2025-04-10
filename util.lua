-- Assorted utility functions that are used in multiple other modules.

local M = {}

local uids = {}
M.gen_uid = function(namespace) -- {{{
  namespace = namespace or "global"
  if not uids[namespace] then -- create namespace if new
    uids[namespace] = 1
    return 1
  else
    uids[namespace] = uids[namespace]+1
    return uids[namespace]
  end
end -- }}}

-- find the angle between two vectors with the same origin
function M.angleBetweenVectors(x1, y1, x2, y2) return math.atan2(y2-y1, x2-x1) end

-- Given an aim crosshair position in world coordinates (where the player is aiming with their mouse)
-- and the origin position (the "center point" where aim should be calculated relative to),
-- returns an angle representing the angle the player is aiming at.
-- Note that this function assumes its args are given using Love's Y-coordinate weirdness,
-- where greater Y values mean something is farther _down_ rather than up.
-- For example: 
-- - if the aim point is _directly above_ the origin point, returns 0
-- - if the aim point is _directly to the right_ of the origin point, returns pi/2
-- - if the aim point is _directly underneath_ the origin point, returns pi
-- - if aim point is _directly to the left_ of the origin point, returns 3pi/2
-- Angles increase clockwise, with zero at 12 o'clock, in other words.
-- 3 o'clock is 90 degrees, 6 o'clock is 180, and 9 o'clock is 270 (though the value returned is always in radians.)
function M.getAimAngle(crosshairX, crosshairY, originX, originY)
  local aimAngle = math.atan2(crosshairX - (originX+1), crosshairY - (originY+1))
  return math.abs(aimAngle - math.pi)
end

-- Given an aim angle (like the one returned from getAimAngle),
-- add an angle to it. The added angle can be negative.
-- This function ensures the aim angle "wraps" correctly--
-- i.e. if the result is greater than 2pi or less than 0,
-- it "wraps around" the value so it's within that range again
function M.addToAimAngle(aimAngle, angleToAdd)
  local newAimAngle = aimAngle + angleToAdd
  if newAimAngle >= math.pi*2 then
    newAimAngle = newAimAngle - (math.pi*2)
  elseif newAimAngle < 0 then
    newAimAngle = newAimAngle + (math.pi*2)
  end
  return newAimAngle
end

-- Given an aim angle (like the one returned from getAimAngle),
-- get a unit vector representing its direction.
-- Does handle reversing the Y-axis, to work with Love's reversed Y-axis (why did they do that)
-- For example:
--  - if the aimAngle is 0, returns x=0, y=-1
--  - if the aimAngle is pi/2, returns x=1, y=0
--  - if the aimAngle is pi, returns x=0, y=1
--  - if the aimAngle is 3*pi/2, returns x=-1, y=0
function M.getUnitVectorFromAimAngle(aimAngle)
  local uVecX, uVecY
  if aimAngle >= 0 and aimAngle < math.pi/2 then
    uVecX = math.sin(aimAngle % (math.pi/2))
    uVecY = -math.cos(aimAngle % (math.pi/2))
  elseif aimAngle >= (math.pi/2) and aimAngle < math.pi then
    uVecX = math.cos(aimAngle % (math.pi/2))
    uVecY = math.sin(aimAngle % (math.pi/2))
  elseif aimAngle >= math.pi and aimAngle < (3*math.pi/2) then
    uVecX = -math.sin(aimAngle % (math.pi/2))
    uVecY = math.cos(aimAngle % (math.pi/2))
  else
    uVecX = -math.cos(aimAngle % (math.pi/2))
    uVecY = -math.sin(aimAngle % (math.pi/2))
  end
  return uVecX, uVecY
end

-- recursively go through a table and return a clone of it
function M.cloneTable (original) -- {{{
  local originalType = type(original)
  local copy
  if originalType == 'table' then
    copy = {}
    for originalKey, originalValue in next, original, nil do
      copy[M.cloneTable(originalKey)] = M.cloneTable(originalValue)
    end
  else
    copy = original
  end
  return copy
end -- }}}

-- shallowly copy a table
function M.shallowCopyTable (original)
  local originalType = type(original)
  local copy
  if originalType == 'table' then
    copy = {}
    for i,v in pairs(original) do
      copy[i] = v
    end
  else
    copy = original
  end
  return copy
end

-- print the keys/values of one table, skipping any nested tables
function M.shallowTPrint (tbl) -- {{{
  print("==============================")
  for k, v in pairs(tbl) do
    print(tostring(k).." : "..tostring(v))
  end
  print("==============================")
end -- }}}

-- recursively print table to console
function M.tprint (tbl, indent) -- {{{
  -- this one is stolen directly from stack overflow
  -- https://stackoverflow.com/questions/41942289/display-contents-of-tables-in-lua
  -- thanks, luiz
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. M.tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end -- }}}

function M.printTerrainInRangeUserData(TerrainInRange) -- {{{
  for _, v in pairs(TerrainInRange) do
    print(M.tprint(v:getUserData()))
  end
end -- }}}

return M
-- vim: foldmethod=marker
