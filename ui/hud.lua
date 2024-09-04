local gunlib = require'guns'
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

-- gunlist on hud draw functions {{{
M.drawGunList = function(gunList)
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  local gunListYPosOffset = 100
  for i, gunId in pairs(gunList) do
    M.drawGunListItem(gunlib.gunlist[gunId], 0, gunListYPosOffset)
    gunListYPosOffset = gunListYPosOffset + 110
  end
end

M.drawGunListItem = function(gun, topLeftPosX, topLeftPosY)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.line(topLeftPosX, topLeftPosY, topLeftPosX+(gun.current.cooldown/gun.current.lastSetCooldownValue)*100, topLeftPosY)
  love.graphics.setColor(1, 1, 1, 1)
  if gun.current.cooldown >= 0 then love.graphics.setColor(0.6, 0.6, 0.6, 0.3) end
  love.graphics.print(gun.name, topLeftPosX, topLeftPosY+5)
  local gunSprite = love.graphics.newImage("assets/generic_gun.png")
  love.graphics.draw(gunSprite, topLeftPosX, topLeftPosY+25)
end
-- }}}


return M
-- vim: foldmethod=marker
