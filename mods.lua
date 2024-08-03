local M = { }


local function apply (mod, shot) -- {{{
  shot.recoil = shot.recoil + mod.recoil
  return shot
end -- }}}

M.create = function() -- {{{
-- create a mod
  local mod = {}

  -- tmp
  mod.recoil = 0

  -- add methods
  mod.apply = apply

  return mod
end -- }}}


return M
-- vim: foldmethod=marker
