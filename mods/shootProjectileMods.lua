-- The traits of all "shoot projectile" mods (see todo.md in docs for details) are defined here.
-- Random variance in individual instances of shoot projectile mods' stats will be implemented later.

local M = { }

-- Small caliber bullet: low cooldown/knockback/damage, medium speed, okay accuracy
M.createSmallBulletStats = function()
  local projectileTable = {}
  projectileTable.cooldown = 0.05
  projectileTable.holderKnockback = 2
  projectileTable.hitKnockback = 2
  projectileTable.hitDamage = 3
  projectileTable.inaccuracy = math.rad(5)
  projectileTable.launchVelocity = 250
  projectileTable.linearDamping = 0
  return projectileTable
end

-- Medium caliber bullet: low-mid cooldown/knockback/damage, med-high speed, decent accuracy
M.createMediumBulletStats = function()
  local projectileTable = {}
  projectileTable.cooldown = 0.15
  projectileTable.holderKnockback = 4
  projectileTable.hitKnockback = 6
  projectileTable.hitDamage = 5
  projectileTable.inaccuracy = math.rad(2)
  projectileTable.launchVelocity = 350
  projectileTable.linearDamping = 0
  return projectileTable
end

-- Large caliber bullet: medium cooldown/knockback/damage, high speed, great accuracy 
M.createLargeBulletStats = function()
  local projectileTable = {}
  projectileTable.cooldown = 0.35
  projectileTable.holderKnockback = 8
  projectileTable.hitKnockback = 10
  projectileTable.hitDamage = 10
  projectileTable.inaccuracy = math.rad(0.5)
  projectileTable.launchVelocity = 500
  projectileTable.linearDamping = 0
  return projectileTable
end

-- Oversize caliber bullet: high cooldown/knockback/damage/speed, great accuracy
M.createOversizeBulletStats = function()
  local projectileTable = {}
  projectileTable.cooldown = 0.7
  projectileTable.holderKnockback = 30
  projectileTable.hitKnockback = 45
  projectileTable.hitDamage = 30
  projectileTable.inaccuracy = math.rad(0.5)
  projectileTable.launchVelocity = 700
  projectileTable.linearDamping = 0
  return projectileTable
end

return M
