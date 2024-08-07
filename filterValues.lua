-- To help manage collisions, Box2D/Love uses a feature called "filter data".
-- These are specific flags each fixture uses to determine whether or not two fixtures should collide.
--
-- Bit confusing, but in short: every fixture has three flag values set, `category`, `mask`, and `group`.
-- `group` takes the highest priority; if two colliding fixtures have positive matching group values, they'll always collide.
-- If they have negative matching group values, they'll never collide. 
-- If `group` is zero for both or they don't match, then it uses `category` and `mask`.
--
-- `category` and `mask` are two 16-bit unsigned ints that are bitwise AND-ed together to determine if they collide or not.
-- This means that you have access to 16 category/mask bits to set for filtering what should collide with what.
-- (The exact behavior is this.)
--
--  bool collide =
--           (filterA.maskBits & filterB.categoryBits) != 0 &&
--          (filterA.categoryBits & filterB.maskBits) != 0;
--
-- Box2D docs suggest you utilize this by using the `category` flag to describe what a fixture is,
-- while setting a fixture's `mask` flag to the result of a bitwise OR of all the category values you want the fixture to collide with.
-- For an example, see: http://www.iforce2d.net/b2dtut/collision-filtering

local M = { }

M.category = {}

M.category.terrain =       0x0001
M.category.friendly =      0x0002
M.category.enemy =         0x0004
M.category.projectile =    0x0008

return M
