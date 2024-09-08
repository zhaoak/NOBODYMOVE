local gunlib = require'guns'
local player = require'player'
local uibox = require'ui.uiBox'
local M = { }

-- defines {{{
M.gunHudListItemHeight = 110
M.gunHudListItemWidth = 150
M.healthDisplayWidth = 250
M.healthDisplayHeight = 50
-- }}}

-- health and status bar {{{
local function drawHealthBar()
  local thisBox = uibox.uiBoxList["hudHealthBar"]
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the UIbox
  love.graphics.translate(thisBox.originX, thisBox.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisBox.width, thisBox.height, 20, 20, 20)
  love.graphics.setColor(0.8, 0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", 5, 5, thisBox.width - 10 * (player.current.health/player.startingHealth), thisBox.height - 10, 30, 30, 20)
  local healthNumberDisplay = {{0.65,0.15,0.15,0.9},tostring(player.current.health)}
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(healthNumberDisplay, 40, 10, 0, 2, 2, 0, 0)
  love.graphics.pop()
end

local function createHealthBar()
  local originX, originY = 5, uibox.thisFrameWindowSizeY - 150
  local width, height = M.healthDisplayWidth, M.healthDisplayHeight
  local minWidth, minHeight = 100, 25
  uibox.create(originX, originY, width, height, minWidth, minHeight, "hudHealthBar", createHealthBar, drawHealthBar, true, false)
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
  local gunListYPosOffset = 0
  for i, gunId in pairs(player.guns) do
    M.drawHudGunListItem(gunlib.gunlist[gunId], 5, gunListYPosOffset)
    gunListYPosOffset = gunListYPosOffset + M.gunHudListItemHeight
  end
  love.graphics.pop() -- return back to previous transformation state
end

local function createHudGunList()
  local originX, originY = 5, uibox.thisFrameWindowSizeY * (1/10)
  local width, height = M.gunHudListItemWidth, M.gunHudListItemHeight * #player.guns
  local minWidth, minHeight = 200, 100
  uibox.create(originX, originY, width, height, minWidth, minHeight, "hudGunList", createHudGunList, drawHudGunList, true, false)
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

-- primary functions for creating/drawing/updating hud
-- these are the ones that get called directly in main.lua {{{
M.draw = function()
  uibox.uiBoxList["hudGunList"]:draw()
  uibox.uiBoxList["hudHealthBar"]:draw()
end

-- for creating uiboxes for hud before first drawcall
M.setup = function()
  createHudGunList()
  createHealthBar()
end

M.update = function()

end -- }}}


return M
-- vim: foldmethod=marker
