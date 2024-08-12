-- sample gun with very boring values,
-- also includes comments explaining what each value does
-- Note that most of these values can be changed by the player via mods

local M = { }

-- Name of gun, used as the gun's primary identifier when calling equipGun()
M.name = "samplegun"

-- Type of gun, defines how its projectiles behave before mods
-- (normal bullet vs laser vs explosive projectile, etc)
M.type = "bullet"

-- How many projectiles are created for each shot before mods
M.multishot = 1

-- How long in seconds before the projectiles fired should despawn
-- (assuming they don't hit anything or aren't destroyed another way)
-- [not yet implemented]
M.projectileMaxLifetime = 30

-- The amount of velocity to apply to projectiles from this gun
M.projectileLaunchVelocity = 300

-- How much the projectile decelerates over time.
-- Useful for limiting the effective range of shotguns, for example.
M.projectileLinearDamping = 0

-- The default maximum angle of inaccuracy of this gun in radians
-- (If you'd prefer to use degrees, simply convert a degree value using math.rad)
-- Example: a value of `math.rad(15)` means the fired shot can be fired clockwise or counterclockwise
-- up to 15 degrees off from the angle you're aiming at, determined at random.
-- This means that at inaccuracy of 15 degrees, the shot can go anywhere in a 30 degree cone.
M.inaccuracy = math.rad(2)

-- How much this gun's aim is thrown off after each shot.
M.recoil = math.rad(5)

-- How quickly the gun can spin around the spooder in radians/second.
-- Players can aim at any angle any time--
-- but if their gun's aim hasn't caught up to their mouse/controller aim position yet,
-- it won't shoot the right place!
M.aimSpeed = math.rad(360)

-- The firing pattern of the gun, must be of a predefined type:
-- 'single' -- one click = gun shoots once per click
-- 'burst'  -- one click = gun shoots a fixed number of times, then stops
-- 'auto'   -- fires as long as shoot button held down
M.fireMode = "single"

-- How many projectiles to fire per burst if weapon has `fireMode = "burst"`
M.burstCount = 1

-- How long delay between shots in a burst is in seconds
-- Obviously, only applies if `firemode = "burst"`
M.burstDelay = .2

-- The delay time between shots in seconds, applies after each shot/burst
M.cooldown = 1

-- How much backwards force is applied to the player when shooting this gun
M.holderKnockback = 25

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
