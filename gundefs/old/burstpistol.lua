-- HEY YOU: this file is from before guns were reworked to be statless holders for mods,
-- so don't use this file
local M = { }

M.name = "burstpistol"
M.type = "bullet"
M.multishot = 1
M.projectileMaxLifetime = 30
M.projectileLaunchVelocity = 300
M.projectileLinearDamping = 0
M.inaccuracy = math.rad(4)
M.recoil = math.rad(5)
M.recoilRecoverySpeed = math.rad(30)
M.aimSpeed = math.rad(360)
M.burstCount = 3
M.burstDelay = 0.03
M.cooldown = 0.3
M.holderKnockback = 15
M.hitKnockback = 15
M.hitDamage = 8
M.mods = {}
M.playerHoldDistance = 5
M.gunSprite = love.graphics.newImage("assets/generic_gun.png")

return M
