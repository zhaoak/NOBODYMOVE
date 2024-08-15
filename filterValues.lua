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
--  Basically: set a category on a fixture to describe what it _is_,
--  and pass args to it with `setMask` to describe what it should NOT collide with.
--  Calling `setMask` with no args makes the fixture have _no_ masks (a maskBits value of 0x0000).
--  Note that if you forget to call `setMask`, maskBits will be nil!
--
-- THE MOST IMPORTANT PART: Love's `setCategory` and `setMask` functions take number args that _represent_ the bitmasks,
-- i.e. 1 = 0x0001, 2 = 0x0002, 3 = 0x0004, 4 = 0x0008, 5 = 0x0010... you get the idea.
-- DON'T directly pass in bitmasks to them!
--
-- However, `Fixture:setFilterData()` *might* take bitmask values??? https://www.love2d.org/wiki/Fixture:setFilterData
-- ?????
-- ????????
-- ???????????
-- so basically, i'm avoiding using that one until i can test it
-- (figuring all this out burned me out too much today)

local M = { }

M.category = {}

M.category.terrain =            1
M.category.friendly =           2
M.category.enemy =              3
M.category.projectile_enemy =   4
M.category.projectile_player =  5
M.category.player =             6
M.category.neutral =            7

-- We might need the bitmask literal values for later (when using the dreaded `Fixture:setFilterData()`,
-- so here they are
M.bitmasks = {}

M.bitmasks.terrain =            0x0001
M.bitmasks.friendly =           0x0002
M.bitmasks.enemy =              0x0004
M.bitmasks.projectile_enemy =   0x0008
M.bitmasks.projectile_player =  0x0010
M.bitmasks.player =             0x0020

return M
