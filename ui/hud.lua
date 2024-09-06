local gunlib = require'guns'
local player = require'player'
local uibox = require'ui.uiBox'
local M = { }

-- defines {{{
M.gunHudListItemHeight = 110
M.gunHudListItemWidth = 150
-- }}}

M.draw = function()
  uibox.uiBoxList["hudGunList"]:draw()
end

M.setup = function()
  M.createHudGunList()
end

M.update = function()

end

M.drawHealthBar = function(healthBarUiBox, playerCurrentHealth) -- {{{
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
  local healthNumberDisplay = {{0.65,0.15,0.15,0.5}, tostring(playerCurrentHealth)}
  love.graphics.print("health: ", 5, windowSizeY - 60, 0, 2, 2, 0, 0)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(healthNumberDisplay, 100, windowSizeY - 60, 0, 2, 2, 0, 0)
end
-- }}}

-- gunlist on hud present during normal gameplay {{{
local function drawHudGunList()
  local thisBox = uibox.uiBoxList["hudGunList"]
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the UIbox
  love.graphics.translate(thisBox.originX, thisBox.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisBox.width, thisBox.height, 20, 20, 20)
  local gunListYPosOffset = 10
  for i, gunId in pairs(player.guns) do
    M.drawHudGunListItem(gunlib.gunlist[gunId], 5, gunListYPosOffset)
    gunListYPosOffset = gunListYPosOffset + 110
  end
  love.graphics.pop() -- return back to previous transformation state
end

M.createHudGunList = function()
  local originX, originY = 5, uibox.thisFrameWindowSizeY * (1/10)
  local width, height = M.gunHudListItemWidth, M.gunHudListItemHeight * #player.guns
  local minWidth, minHeight = 200, 100
  uibox.create(originX, originY, width, height, minWidth, minHeight, "hudGunList", drawHudGunList, true, false)
end

M.drawHudGunListItem = function(gun, topLeftPosX, topLeftPosY)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.line(5, topLeftPosY, math.max(5, topLeftPosX+(gun.current.cooldown/gun.current.lastSetCooldownValue)*M.gunHudListItemWidth), topLeftPosY)
  love.graphics.setColor(1, 1, 1, 1)
  if gun.current.cooldown >= 0 then love.graphics.setColor(0.6, 0.6, 0.6, 0.3) end
  love.graphics.print(gun.name, topLeftPosX, topLeftPosY+5)
  local gunSprite = love.graphics.newImage("assets/generic_gun.png")
  love.graphics.draw(gunSprite, topLeftPosX, topLeftPosY+25)
end
-- }}}


return M
-- vim: foldmethod=marker
