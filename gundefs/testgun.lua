-- it's a lazey beam!!
local M = { }

M.type = "hitscan"
M.cooldown = 0.2 -- in seconds
M.name = "testgun"
M.mods = {} -- may define some default gun behavior as hidden mods
M.gunSprite = love.graphics.newImage("assets/generic_gun.png")

return M
-- vim: foldmethod=marker
