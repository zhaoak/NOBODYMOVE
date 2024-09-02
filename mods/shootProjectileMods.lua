-- The data for all "shoot projectile" mods (see todo.md in docs for details) are defined here.
-- Random variance in individual instances of shoot projectile mods' stats will be implemented later.

local M = { }

-- Small caliber bullet: low cooldown/knockback/damage, medium speed, poor accuracy
M.smallBullet = function()
  local projectileTable = {}
  projectileTable.modCategory = "shoot"
  projectileTable.projectileType = "smallbullet"
  projectileTable.shapeType = "circle"
  projectileTable.shapeData = { radius=3 }
  projectileTable.cooldown = 0.05
  projectileTable.holderKnockback = 2
  projectileTable.hitKnockback = 2
  projectileTable.hitDamage = 3
  projectileTable.inaccuracy = math.rad(5)
  projectileTable.launchVelocity = 250
  projectileTable.linearDamping = 0
  projectileTable.gravityScale = 0
  projectileTable.mass = 0.2
  return projectileTable
end

-- Medium caliber bullet: low-mid cooldown/knockback/damage, med-high speed, decent accuracy
M.mediumBullet = function()
  local projectileTable = {}
  projectileTable.modCategory = "shoot"
  projectileTable.projectileType = "mediumbullet"
  projectileTable.shapeType = "circle"
  projectileTable.shapeData = { radius=5 }
  projectileTable.cooldown = 0.15
  projectileTable.holderKnockback = 4
  projectileTable.hitKnockback = 6
  projectileTable.hitDamage = 5
  projectileTable.inaccuracy = math.rad(2)
  projectileTable.launchVelocity = 350
  projectileTable.linearDamping = 0
  projectileTable.gravityScale = 0
  projectileTable.mass = 0.3
  return projectileTable
end

-- Large caliber bullet: medium cooldown/knockback/damage, high speed, great accuracy 
M.largeBullet = function()
  local projectileTable = {}
  projectileTable.modCategory = "shoot"
  projectileTable.type = "largebullet"
  projectileTable.shapeType = "circle"
  projectileTable.shapeData = { radius=7 }
  projectileTable.cooldown = 0.35
  projectileTable.holderKnockback = 8
  projectileTable.hitKnockback = 10
  projectileTable.hitDamage = 10
  projectileTable.inaccuracy = math.rad(0.5)
  projectileTable.launchVelocity = 500
  projectileTable.linearDamping = 0
  projectileTable.gravityScale = 0
  projectileTable.mass = 0.5
  return projectileTable
end

-- Oversize caliber bullet: high cooldown/knockback/damage/speed, great accuracy
M.oversizeBullet = function()
  local projectileTable = {}
  projectileTable.modCategory = "shoot"
  projectileTable.type = "oversizebullet"
  projectileTable.shapeType = "circle"
  projectileTable.shapeData = { radius=9 }
  projectileTable.cooldown = 0.7
  projectileTable.holderKnockback = 30
  projectileTable.hitKnockback = 45
  projectileTable.hitDamage = 30
  projectileTable.inaccuracy = math.rad(0.5)
  projectileTable.launchVelocity = 700
  projectileTable.linearDamping = 0
  projectileTable.gravityScale = 0
  projectileTable.mass = 0.8
  return projectileTable
end

return M
