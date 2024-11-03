-- Module for drawing all UI present during normal gameplay.
-- This includes the HUD, gun/event editing screen, and more.

local uibox = require'ui.uiBox'
local M = { }

-- defines {{{
M.gunHudListItemHeight = 110
M.gunHudListItemWidth = 150
M.healthDisplayWidth = 250
M.healthDisplayHeight = 50
M.gunEditMenuOpen = false
-- }}}

-- health and status bar {{{
local function drawHealthBar(self, player)
  local thisBox = uibox.uiBoxList["hudHealthBar"]
  if thisBox.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the UIbox
  love.graphics.translate(thisBox.originX, thisBox.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisBox.width, thisBox.height, 20, 20, 20)
  love.graphics.setColor(0.8, 0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", 5, 5, (thisBox.width-10) * (player.current.health/player.current.maxHealth), thisBox.height - 10, 10, 10, 5)
  local healthNumberDisplay = {{0.65,0.15,0.15,0.9},tostring(player.current.health)}
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(healthNumberDisplay, 40, 10, 0, 2, 2, 0, 0)
  love.graphics.pop()
end

local function createHealthBar()
  local originX, originY = 5, uibox.thisFrameWindowSizeY - 150
  local width, height = M.healthDisplayWidth, M.healthDisplayHeight
  uibox.create(originX, originY, width, height, "hudHealthBar", createHealthBar, drawHealthBar, true, false)
end
-- }}}

-- gunlist on hud when gun editing menu closed {{{
local function drawHudGunList(self, player, gunList)
  local thisBox = uibox.uiBoxList["hudGunList"]
  if thisBox.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the UIbox
  love.graphics.translate(thisBox.originX, thisBox.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisBox.width, #player.guns*M.gunHudListItemHeight, 20, 20, 20)
  local gunListYPosOffset = 0
  for i, gunId in pairs(player.guns) do
    M.drawHudGunListItem(gunList[gunId], 5, gunListYPosOffset)
    gunListYPosOffset = gunListYPosOffset + M.gunHudListItemHeight
  end
  love.graphics.pop() -- return back to previous transformation state
end

local function createHudGunList()
  local originX, originY = 5, uibox.thisFrameWindowSizeY * (1/10)
  local width, height = M.gunHudListItemWidth, M.gunHudListItemHeight * 4 -- for four firegroups
  uibox.create(originX, originY, width, height, "hudGunList", createHudGunList, drawHudGunList, true, false)
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

-- gun editing menu {{{
local function drawGunEditMenu(self, player, gunList)
  local thisBox = uibox.uiBoxList["gunEditMenu"]
  if thisBox.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the UIbox

  love.graphics.pop()
end

local function createGunEditMenu()
  local originX, originY = 5, uibox.thisFrameWindowSizeY * (1/10)
  local width, height = M.gunHudListItemWidth, M.gunHudListItemHeight * 4
  uibox.create(originX, originY, width, height, "gunEditMenu", createGunEditMenu, drawGunEditMenu, false, true, false)
end

M.toggleGunEditMenuOpen = function()

end
-- }}}

-- player's per-run mod collection {{{

-- }}}

-- test menu, for testing UI code {{{
local function drawTestUI(self)
  local thisBox = uibox.uiBoxList["testUI"]
  if thisBox.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the UIbox
  love.graphics.translate(thisBox.originX, thisBox.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisBox.width, thisBox.height, 20, 20, 20)
  love.graphics.pop()
end

local function createTestUI()
  local originX, originY = uibox.thisFrameWindowSizeX / 3, uibox.thisFrameWindowSizeY / 3
  local width, height = 300, 300
  uibox.create(originX, originY, width, height, "testUI", createTestUI, drawTestUI, true, false, true, false)
end
-- }}}

-- primary functions for creating/drawing/updating hud
-- these are the ones that get called directly in main.lua 
-- {{{
M.draw = function(player, gunList)
  uibox.uiBoxList["hudGunList"]:draw(player, gunList)
  uibox.uiBoxList["hudHealthBar"]:draw(player)
  uibox.uiBoxList["gunEditMenu"]:draw()

  -- test code
  -- uibox.uiBoxList["testUI"]:draw()
end

-- for creating uiboxes for hud before first drawcall
M.setup = function()
  createHudGunList()
  createHealthBar()
  createGunEditMenu()

  -- test UI
  -- createTestUI()
  
end

M.update = function()

end -- }}}



return M
-- vim: foldmethod=marker
