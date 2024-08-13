local M = { }

M.drawHealthBar = function(playerCurrentHealth) -- {{{
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
  local healthNumberDisplay = {{0.65,0.15,0.15,0.5}, tostring(playerCurrentHealth)}
  love.graphics.print("health: ", 5, windowSizeY - 60, 0, 2, 2, 0, 0)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(healthNumberDisplay, 100, windowSizeY - 60, 0, 2, 2, 0, 0)
end
-- }}}

return M
-- vim: foldmethod=marker
