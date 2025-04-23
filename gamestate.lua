-- Module for storing state data that any module can access or write to.
-- Particularly useful for storing data that needs to be globally accessible,
-- like whether the game is paused, for example.

local M = {}

-- {{{ Whether the pause menu is open and interactive.
M.pauseMenuOpen = false
-- }}}

-- {{{ Whether the game is currently paused. 
M.gamePaused = false
-- }}}

-- {{{ Whether the gun edit menu is open and interactive.
M.gunEditMenuOpen = false
-- }}}

return M
-- vim: foldmethod=marker
