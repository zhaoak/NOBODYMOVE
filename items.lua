-- Module for items existing in the game world as Box2D physics objects.
-- Items can be used by players by moving near them and pressing the "interact" key/button.
-- This is in opposition to a prop, which also exists in the game world as a physics object,
-- but cannot be interacted with (besides having physics forces applied to it.)

local M = { }

M.itemList = {} -- every item currently existing in the world, indexed by UID

M.update = function(dt)

end

return M
-- vim: foldmethod=marker
