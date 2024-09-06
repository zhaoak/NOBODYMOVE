-- The data for all "shoot projectile" mods (see todo.md in docs for details) are defined here.
-- Random variance in individual instances of shoot projectile mods' stats will be implemented later.

local M = { }

M.templateMod = function()
  local modTable = {}

  -- all mods should have these fields, regardless of type
  modTable.modCategory = "projectile"
  modTable.displayName = "Example Shoot Projectile Mod"
  modTable.description = "Template for projectile-spawning mods"

  -- a unique string used to identify the type of projectile this function generates
  modTable.type = "demoshot"

  -- the projShapeData table defines the hitbox shape and size of the projectile
  -- `hitboxShape` determines the type of shape, and must be one of: "circle", "polygon", "rectangle"
  -- Each permitted shape requires specific fields in addition to `hitboxShape`, used for Box2D to create the shape
  -- These fields are:
  -- for hitboxShape == "circle" : `radius` : the circle shape's radius in pixels at camera scale 1
  -- for hitboxShape == "polygon" : `x1`, `y1`, `x2`, `y2`...up to `x8`, `y8` : x and y positions of the vertices of the shape, relative to the attached body
  -- for hitboxShape == "rectangle" : `width`, `height` : the width and height of the rectangle
  modTable.shapeData = { hitboxShape="circle", radius=2 }

  -- shoot projectile mods must include _all_ of the following values,
  -- as these values are changed by projectileModifier mods
  modTable.cooldownCost = 0.5
  modTable.holderKnockback = 5
  modTable.hitKnockback = 5
  modTable.projectileDamage = 3
  modTable.inaccuracy = math.rad(1)
  modTable.speed = 100
  modTable.linearDamping = 0
  modTable.gravityScale = 0
  modTable.mass = 0.2
  modTable.bulletCount = 1
  return modTable
end

-- Small caliber bullet: low cooldown/knockback/damage, medium speed, poor accuracy
M.smallBullet = function()
  local modTable = M.templateMod()
  modTable.displayName = "Shoot small bullet"
  modTable.description = "lore goes here ig"
  modTable.type = "smallbullet"
  modTable.shapeData = { hitboxShape="circle", radius=3 }
  modTable.cooldownCost = 0.10
  modTable.holderKnockback = 2
  modTable.hitKnockback = 2
  modTable.projectileDamage = 3
  modTable.inaccuracy = math.rad(5)
  modTable.speed = 250
  modTable.linearDamping = 0
  modTable.gravityScale = 0
  modTable.mass = 0.2
  return modTable
end

M.threeSmallBullet = function()
  local modtable = M.smallBullet()
  modtable.bulletCount = 3
  return modtable
end

-- Medium caliber bullet: low-mid cooldown/knockback/damage, med-high speed, decent accuracy
M.mediumBullet = function()
  local modTable = M.templateMod()
  modTable.displayName = "Shoot medium bullet"
  modTable.description = "lore goes here ig"
  modTable.type = "mediumbullet"
  modTable.shapeData = { hitboxShape="circle", radius=5 }
  modTable.cooldownCost = 0.20
  modTable.holderKnockback = 4
  modTable.hitKnockback = 6
  modTable.projectileDamage = 5
  modTable.inaccuracy = math.rad(2)
  modTable.speed = 350
  modTable.mass = 0.3
  return modTable
end

-- Large caliber bullet: medium cooldown/knockback/damage, high speed, great accuracy
M.largeBullet = function()
  local modTable = M.templateMod()
  modTable.displayName = "Shoot large bullet"
  modTable.description = "lore goes here ig"
  modTable.type = "largebullet"
  modTable.shapeData = { hitboxShape="circle", radius=7 }
  modTable.cooldownCost = 0.35
  modTable.holderKnockback = 8
  modTable.hitKnockback = 10
  modTable.projectileDamage = 10
  modTable.inaccuracy = math.rad(0.5)
  modTable.speed = 500
  modTable.mass = 0.5
  return modTable
end

-- Oversize caliber bullet: high cooldown/knockback/damage/speed, great accuracy
M.oversizeBullet = function()
  local modTable = M.templateMod()
  modTable.displayName = "Shoot oversize bullet"
  modTable.description = "lore goes here ig"
  modTable.type = "oversizebullet"
  modTable.shapeData = { hitboxShape="circle", radius=9 }
  modTable.cooldownCost = 0.7
  modTable.holderKnockback = 75
  modTable.hitKnockback = 45
  modTable.projectileDamage = 30
  modTable.inaccuracy = math.rad(0.5)
  modTable.speed = 1500 
  modTable.mass = 0.8
  return modTable
end

return M
