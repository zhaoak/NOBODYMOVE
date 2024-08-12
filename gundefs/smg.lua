local M = { }

M.name = "smg"
M.type = "bullet"
M.multishot = 1
M.projectileMaxLifetime = 5
M.projectileLaunchVelocity = 300
M.projectileLinearDamping = 0
M.inaccuracy = math.rad(8)
M.recoil = math.rad(0.5)
M.aimSpeed = math.rad(180)
M.fireMode = "auto"
M.burstCount = 1
M.burstDelay = .1
M.cooldown = 0.1
M.holderKnockback = 5
M.hitKnockback = 5
M.hitDamage = 3
M.mods = {}
M.playerHoldDistance = 5
M.gunSprite = love.graphics.newImage("assets/generic_gun.png")

return M
