-- sample gun with very boring values,
-- also includes comments explaining what each value does
-- Note that most of these values can be changed by the player via mods

local M = { }

-- Name of gun, used as the gun's primary identifier when calling equipGun()
M.name = "samplegun"

-- Type of gun, defines how its projectiles behave by default before mods
-- (normal bullet vs laser vs explosive projectile, etc)
M.type = "bullet"

-- The delay time between shots in seconds
M.cooldown = 1

-- Not sure what this one is tbh, lemme know pls spooder
M.maxCooldown = 5

-- How much backwards force is applied to the player when shooting this gun
M.holderKnockback = 100

-- How much force is applied to players/objects hit by this gun's projectile
M.hitKnockback = 25

-- How much damage a single projectile fired from this gun does
M.hitDamage = 20

-- Default mods applied to gun, before any player mods
-- (some stock gun behavior is defined as mods)
M.mods = {}

-- How far in pixels to position gun away from player hardbox
-- Hardbox radius is added when drawing gun so gun doesn't render inside player sprite.
-- So if the radius is 20 and this value is 5, gun will render 25 pixels away from player body center
M.playerHoldDistance = 5

-- Image file to use when drawing gun sprite
-- Make sure to include the `love.graphics.newImage()` call here, otherwise drawing sprite will fail
M.gunSprite = love.graphics.newImage("assets/generic_gun.png")

return M
