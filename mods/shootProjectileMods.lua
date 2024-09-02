-- The data for all "shoot projectile" mods (see todo.md in docs for details) are defined here.
-- Random variance in individual instances of shoot projectile mods' stats will be implemented later.

local M = { }

-- Small caliber bullet: low cooldown/knockback/damage, medium speed, poor accuracy
M.smallBullet = function()
  local modTable = {}
  modTable.modCategory = "shoot"
  modTable.displayName = "Shoot small bullet"
  modTable.projType = "smallbullet"
  modTable.projShapeType = "circle"
  modTable.projShapeData = { radius=3 }
  modTable.projCooldown = 0.05
  modTable.holderKnockback = 2
  modTable.projHitKnockback = 2
  modTable.projHitDamage = 3
  modTable.projInaccuracy = math.rad(5)
  modTable.projLaunchVelocity = 250
  modTable.projLinearDamping = 0
  modTable.projGravityScale = 0
  modTable.projMass = 0.2
  return modTable
end

-- Medium caliber bullet: low-mid cooldown/knockback/damage, med-high speed, decent accuracy
M.mediumBullet = function()
  local modTable = {}
  modTable.modCategory = "shoot"
  modTable.displayName = "Shoot medium bullet"
  modTable.projType = "mediumbullet"
  modTable.projShapeType = "circle"
  modTable.projShapeData = { radius=5 }
  modTable.projCooldown = 0.15
  modTable.holderKnockback = 4
  modTable.projHitKnockback = 6
  modTable.projHitDamage = 5
  modTable.projInaccuracy = math.rad(2)
  modTable.projLaunchVelocity = 350
  modTable.projLinearDamping = 0
  modTable.projGravityScale = 0
  modTable.projMass = 0.3
  return modTable
end

-- Large caliber bullet: medium cooldown/knockback/damage, high speed, great accuracy 
M.largeBullet = function()
  local modTable = {}
  modTable.modCategory = "shoot"
  modTable.displayName = "Shoot large bullet"
  modTable.projType = "largebullet"
  modTable.projShapeType = "circle"
  modTable.projShapeData = { radius=7 }
  modTable.projCooldown = 0.35
  modTable.holderKnockback = 8
  modTable.projHitKnockback = 10
  modTable.projHitDamage = 10
  modTable.projInaccuracy = math.rad(0.5)
  modTable.projLaunchVelocity = 500
  modTable.projLinearDamping = 0
  modTable.projGravityScale = 0
  modTable.projMass = 0.5
  return modTable
end

-- Oversize caliber bullet: high cooldown/knockback/damage/speed, great accuracy
M.oversizeBullet = function()
  local modTable = {}
  modTable.modCategory = "shoot"
  modTable.displayName = "Shoot oversize bullet"
  modTable.projType = "oversizebullet"
  modTable.projShapeType = "circle"
  modTable.projShapeData = { radius=9 }
  modTable.projCooldown = 0.7
  modTable.holderKnockback = 30
  modTable.projHitKnockback = 45
  modTable.projHitDamage = 30
  modTable.projInaccuracy = math.rad(0.5)
  modTable.projLaunchVelocity = 700
  modTable.projLinearDamping = 0
  modTable.projGravityScale = 0
  modTable.projMass = 0.8
  return modTable
end

return M
