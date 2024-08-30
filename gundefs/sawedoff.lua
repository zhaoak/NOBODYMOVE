local M = { }

M.name = "sawedoff"
M.type = "bullet"
M.multishot = 6
M.projectileMaxLifetime = 5
M.projectileLaunchVelocity = 400
M.projectileLinearDamping = 5
M.inaccuracy = math.rad(5)
M.recoil = math.rad(30)
M.recoilRecoverySpeed = math.rad(10)
M.aimSpeed = math.rad(60)
M.burstCount = 1
M.burstDelay = .15
M.cooldown = 2
M.holderKnockback = 85
M.hitKnockback = 100
M.hitDamage = 8
M.mods = {}
M.playerHoldDistance = 0
M.gunSprite = love.graphics.newImage("assets/generic_gun.png")

return M
