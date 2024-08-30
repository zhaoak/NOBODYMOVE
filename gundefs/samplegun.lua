-- sample gun with very boring values,
-- also includes comments explaining what each value does
-- Note that most of these values can be changed by the player via mods
--
-- GENERAL NOTES ON GUNS:
--    - if the fire button is held down, all guns fire as soon as their cooldown timer is off.
--    - this basically means all guns are automatic.
--    - to limit how fast a gun can shoot, use the cooldown stat.

local M = { }

-- Name of gun, used as the gun's primary identifier when calling equipGun()
M.name = "samplegun"

-- Type of gun, defines how its projectiles behave before mods
-- (normal bullet vs laser vs explosive projectile, etc)
M.type = "bullet"

-- How many projectiles are created and fired simultaneously on every shoot event
-- This stat is what shotguns use to fire multiple projectiles per shot
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

-- How much the aim offset from recoil is recovered from every second.
-- For example, if a gun has 5 degrees of recoil and 2.5 degrees of recoil recovery,
-- the player's next shot will be unaffected by recoil after two seconds.
-- Obviously, if cooldown is greater than recoil/recoilRecoverySpeed,
-- recoil will never be a factor.
M.recoilRecoverySpeed = math.rad(2.5)

-- How quickly the gun can spin around the spooder in radians/second.
-- Players can aim at any angle any time--
-- but if their gun's aim hasn't caught up to their mouse/controller aim position yet,
-- it won't shoot the right place!
-- [not yet implemented]
M.aimSpeed = math.rad(360)

-- Burst fire settings
-- A burst is a finite number of shoot events queued to fire one after the other when the player shoots once
-- Unlike multishot, each projectile is shot following the previous in the burst after a short delay, whose length is specified by burstDelay
-- This is independent of multishot: if multishot is 4 and burstCount is 3, the gun will shoot 3 bursts of four projectiles per shot
-- To make a gun not burstfire multiple times, simply set its burstCount to 1
-- Even if a gun's burstCount is 1, it must have a burstDelay property, as players can modify the gun's burstCount
-- =============================================================

-- How many projectiles to fire per burst
M.burstCount = 1

-- How long delay between shots in a burst is in seconds
M.burstDelay = .2

-- The delay time between bursts in seconds, timer starts once player shoots
-- this essentially acts as both reload and fire rate
-- Not to be confused with burstDelay; burstDelay is the delay between shots in a burst,
-- whereas this is how long the delay between bursts of shots is 
-- This timer is reset after every shot, including shots triggered as part of bursts
-- Therefore, the _last_ shot in a burst is when the cooldown starts counting down, not the first
M.cooldown = 1

-- How much backwards force is applied to the player when shooting this gun
M.holderKnockback = 25

-- How much force is applied to players/objects hit by one of this gun's projectiles
M.hitKnockback = 25

-- How much damage a single projectile fired from this gun does
M.hitDamage = 20

-- Default mods applied to gun, before any player mods
-- (some stock gun behavior is defined as mods)
-- [not yet implemented]
M.mods = {}

-- How far in pixels to position gun away from player hardbox
-- Hardbox radius is added when drawing gun so gun doesn't render inside player sprite.
-- So if the radius is 20 and this value is 5, gun will render 25 pixels away from player body center
M.playerHoldDistance = 5

-- Image file to use when drawing gun sprite
-- Make sure to include the `love.graphics.newImage()` call here, otherwise drawing sprite will fail
M.gunSprite = love.graphics.newImage("assets/generic_gun.png")

return M
