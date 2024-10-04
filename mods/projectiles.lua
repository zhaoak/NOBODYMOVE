-- The data for all "shoot projectile" mods (see todo.md in docs for details) are defined here.
-- Random variance in individual instances of shoot projectile mods' stats will be implemented later.

local M = { }

M.templateShootProjectileMod = function()
  local modTable = {}

  -- All mods should have these three fields, regardless of type:
  -- Category of the 
  modTable.modCategory = "projectile"
  -- Name of this mod as displayed to the player in the UI
  modTable.displayName = "Example Shoot Projectile Mod"
  -- Description of this mod, also visible in UI
  modTable.description = "Template for projectile-spawning mods"

  -- the projShapeData table defines the hitbox shape and size of the projectile
  -- `hitboxShape` determines the type of shape, and must be one of: "circle", "polygon", "rectangle"
  -- Each permitted shape requires specific fields in addition to `hitboxShape`, used for Box2D to create the shape
  -- These fields are:
  -- for hitboxShape == "circle" : `radius` : the circle shape's radius in pixels at camera scale 1
  -- for hitboxShape == "polygon" : `x1`, `y1`, `x2`, `y2`...up to `x8`, `y8` : x and y positions of the vertices of the shape, relative to the attached body
  -- for hitboxShape == "rectangle" : `width`, `height` : the width and height of the rectangle
  modTable.shapeData = { hitboxShape="circle", radius=2 }

  -- A unique string used to identify the type of projectile this function generates
  modTable.projectileType = "demoshot"

  -- shoot projectile mods must include _all_ of the following values,
  -- as these values are changed by projectileModifier mods

  -- How much this mod contributes to a gun's per-shoot-event cooldown timer
  modTable.cooldownCost = 0.5
  -- How much backward force this mod applies to the shooter when shot
  modTable.holderKnockback = 5
  -- How much force _one_ projectile spawned by this mod should apply to a hit target
  modTable.hitKnockback = 5
  -- How much damage _one_ projectile spawned by this mod does on hit
  modTable.projectileDamage = 3
  -- The default maximum angle of inaccuracy of this gun in radians
  -- (If you'd prefer to use degrees, simply convert a degree value using math.rad)
  -- Example: a value of `math.rad(15)` means the fired shot can be fired clockwise or counterclockwise
  -- up to 15 degrees off from the angle you're aiming at, determined at random.
  -- This means that at inaccuracy of 15 degrees, the shot can go anywhere in a 30 degree cone.
  modTable.inaccuracy = math.rad(1)
  -- How much velocity to apply to the projectile upon spawning it
  modTable.speed = 100
  -- How long the projectile is allowed to exist before being forcibly despawned, in seconds
  modTable.maxLifetime = 10
  -- If the projectile ever drops below this speed in any direction, despawn it
  -- (if nil, the projectile will never despawn based on speed)
  modTable.despawnBelowVelocity = nil
  -- The linear damping of the projectile (meaning its innate deceleration rate)
  modTable.linearDamping = 0
  -- A multiplier value for how much the physics world's gravity should apply to the projectile
  modTable.gravityScale = 0
  -- The projectile's mass value: note that this is not used for knockback-on-hit calculations
  modTable.mass = 0.2
  -- How many copies of the projectile to create when shooting this mod
  modTable.spawnCount = 1
  return modTable
end

-- Small caliber bullet: low cooldown/knockback/damage, medium speed, poor accuracy
M.smallBullet = function()
  local modTable = M.templateShootProjectileMod()
  modTable.displayName = "Shoot small bullet"
  modTable.description = "lore goes here ig"
  modTable.projectileType = "smallbullet"
  modTable.shapeData = { hitboxShape="circle", radius=3 }
  modTable.cooldownCost = 0.10
  modTable.holderKnockback = 2
  modTable.hitKnockback = 20
  modTable.projectileDamage = 3
  modTable.inaccuracy = math.rad(5)
  modTable.speed = 250
  modTable.linearDamping = 0
  modTable.gravityScale = 0
  modTable.mass = 0.2
  return modTable
end

-- Medium caliber bullet: low-mid cooldown/knockback/damage, med-high speed, decent accuracy
M.mediumBullet = function()
  local modTable = M.templateShootProjectileMod()
  modTable.displayName = "Shoot medium bullet"
  modTable.description = "lore goes here ig"
  modTable.projectileType = "mediumbullet"
  modTable.shapeData = { hitboxShape="circle", radius=5 }
  modTable.cooldownCost = 0.20
  modTable.holderKnockback = 25
  modTable.hitKnockback = 50
  modTable.projectileDamage = 5
  modTable.inaccuracy = math.rad(2)
  modTable.speed = 350
  modTable.mass = 0.3
  return modTable
end

-- Large caliber bullet: medium cooldown/knockback/damage, high speed, great accuracy
M.largeBullet = function()
  local modTable = M.templateShootProjectileMod()
  modTable.displayName = "Shoot large bullet"
  modTable.description = "lore goes here ig"
  modTable.projectileType = "largebullet"
  modTable.shapeData = { hitboxShape="circle", radius=7 }
  modTable.cooldownCost = 0.35
  modTable.holderKnockback = 50
  modTable.hitKnockback = 250
  modTable.projectileDamage = 10
  modTable.inaccuracy = math.rad(0.5)
  modTable.speed = 500
  modTable.mass = 0.5
  return modTable
end

-- Oversize caliber bullet: high cooldown/knockback/damage/speed, great accuracy
M.oversizeBullet = function()
  local modTable = M.templateShootProjectileMod()
  modTable.displayName = "Shoot oversize bullet"
  modTable.description = "lore goes here ig"
  modTable.projectileType = "oversizebullet"
  modTable.shapeData = { hitboxShape="circle", radius=9 }
  modTable.cooldownCost = 0.7
  modTable.holderKnockback = 400
  modTable.hitKnockback = 500
  modTable.projectileDamage = 30
  modTable.inaccuracy = math.rad(0.5)
  modTable.speed = 1500 
  modTable.mass = 0.8
  return modTable
end

return M
