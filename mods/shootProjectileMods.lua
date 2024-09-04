-- The data for all "shoot projectile" mods (see todo.md in docs for details) are defined here.
-- Random variance in individual instances of shoot projectile mods' stats will be implemented later.

local M = { }

M.exampleShootProjectileMod = function()
  local modTable = {}

  -- all mods should have these fields, regardless of type
  modTable.modCategory = "shoot"
  modTable.displayName = "Example Shoot Projectile Mod"
  modTable.description = "Commented demonstration of shoot projectile mod format"
  
  -- a unique string used to identify the type of projectile this function generates
  modTable.projType = "demoshot"

  -- the projShapeData table defines the hitbox shape and size of the projectile
  -- `hitboxShape` determines the type of shape, and must be one of: "circle", "polygon", "rectangle"
  -- Each permitted shape requires specific fields in addition to `hitboxShape`, used for Box2D to create the shape
  -- These fields are:
  -- for hitboxShape == "circle" : `radius` : the circle shape's radius in pixels at camera scale 1
  -- for hitboxShape == "polygon" : `x1`, `y1`, `x2`, `y2`...up to `x8`, `y8` : x and y positions of the vertices of the shape, relative to the attached body
  -- for hitboxShape == "rectangle" : `width`, `height` : the width and height of the rectangle
  modTable.projShapeData = { hitboxShape="circle", radius=2 }

  -- shoot projectile mods must include _all_ of the following values,
  -- as these values are changed by projectileModifier mods
  modTable.projCooldown = 0.5
  modTable.holderKnockback = 5
  modTable.projHitKnockback = 5
  modTable.projHitDamage = 3
  modTable.projInaccuracy = math.rad(1)
  modTable.projLaunchVelocity = 100
  modTable.projLinearDamping = 0
  modTable.projGravityScale = 0
  modTable.projMass = 0.2
  return modTable
end

-- Small caliber bullet: low cooldown/knockback/damage, medium speed, poor accuracy
M.smallBullet = function()
  local modTable = {}
  modTable.modCategory = "shoot"
  modTable.displayName = "Shoot small bullet"
  modTable.description = "lore goes here ig"
  modTable.projType = "smallbullet"
  modTable.projShapeData = { hitboxShape="circle", radius=3 }
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
  modTable.description = "lore goes here ig"
  modTable.projType = "mediumbullet"
  modTable.projShapeData = { hitboxShape="circle", radius=5 }
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
  modTable.description = "lore goes here ig"
  modTable.projType = "largebullet"
  modTable.projShapeData = { hitboxShape="circle", radius=7 }
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
  modTable.description = "lore goes here ig"
  modTable.projType = "oversizebullet"
  modTable.projShapeData = { hitboxShape="circle", radius=9 }
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
