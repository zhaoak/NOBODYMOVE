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
