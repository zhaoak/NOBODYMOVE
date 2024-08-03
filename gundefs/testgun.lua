-- it's a lazey beam!!
local M = { }

M.name = "testgun"
M.type = "hitscan"
M.cooldown = 0.2 -- in seconds
M.maxCooldown = 0.8
M.holderKnockback = 1 -- how much backward force applied to player shooting gun on shoot
M.hitKnockback = 1 -- how much force to apply to objects hit by shot
M.mods = {} -- may define some default gun behavior as hidden mods
M.playerHoldDistance = 25 -- how many pixels away from center of player body to render gun
M.gunSprite = love.graphics.newImage("assets/generic_gun.png")

return M
-- vim: foldmethod=marker
