-- Projectiles ingame can have _traits_,
-- which are essentially a way of specifying that certain custom callbacks should be run for each projectile.
-- This enables projectiles to have unique behavior--exploding, homing onto targets, or more.
-- Traits are binary--a projectile either has or doesn't have a trait at any given moment.
-- If the projectile has a trait, its callback should always trigger when appropriate.
-- The possible callbacks that can trigger for a trait are:
--    - `onUpdate` : called during projectile update step
--        - args: 
--            - figuring it out
--
--    - `onCollision` : called when the projectile registers a Box2D collision with another body
--        - args:
--            - projectileFixture : Box2D fixture for the projectile with this trait
--            - otherFixture : Box2D fixture for the thing the projectile hit

local M = {}

M.exampleTrait = function()
  

end
return M
