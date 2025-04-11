-- Module for drawing all UI present during normal gameplay.
-- This includes the HUD, gun/event editing screen, and more.
-- Each UI element (examples: health display, gun status display) gets its own uiWindow.
-- See `uiWindow.lua` for how they work.

local uiWindow = require'ui.uiWindow'
local elements = require'ui.uiElements'
local util = require'util'
local M = { }

-- defines {{{
-- Pixel width/height values for various UI elements when uiScale = 1.
-- In other words, the defaults.
M.gunHudListItemHeight = 110
M.gunHudListItemWidth = 150
M.healthDisplayWidth = 250
M.healthDisplayHeight = 50
M.gunEditMenuOpen = false
-- }}}

-- UI event callbacks {{{
  local function testCallback()
    print("Test callback triggered.")
  end
-- }}}

M.uiWindowUidCache = {} -- cache of all window UIDs, keyed by their internal name

-- health and status bar {{{
local function drawHealthBar(self, player)
  local thisWindowUid = uiWindow.getWindowUid("hudHealthBar")
  local thisWindow = uiWindow.uiWindowList[thisWindowUid]
  if thisWindow.shouldRender == false then return end

  -- if position/size values aren't set, calculate them based on parent container's values
  -- if thisWindow.originX == nil or thisWindow.originY == nil or thisWindow.width == nil or thisWindow.height == nil then
  --   uiWindow.resizeWindow(thisWindowUid)
  -- end

  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the uiWindow
  love.graphics.translate(thisWindow.originX, thisWindow.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisWindow.width, thisWindow.height, 20, 20, 20)
  love.graphics.setColor(0.8, 0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", 5, 5, (thisWindow.width-10) * (player.current.health/player.current.maxHealth), thisWindow.height - 10, 10, 10, 5)
  local healthNumberDisplay = {{0.65,0.15,0.15,0.9},tostring(player.current.health)}
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(healthNumberDisplay, 40, 10, 0, 2, 2, 0, 0)
  love.graphics.pop()
end

local function createHealthBar()
  local targetX, targetY = 0.01, 0.95
  local targetWidth, targetHeight = 0.20, 0.07
  local newWindowUid
  newWindowUid = uiWindow.new(targetX, targetY, targetWidth, targetHeight, "hudHealthBar", drawHealthBar, true, false)
  M.uiWindowUidCache["hudHealthBar"] = newWindowUid
end
-- }}}

-- gunlist on hud when gun editing menu closed {{{
local function drawHudGunList(self, player, gunList)
  local thisWindowUid = uiWindow.getWindowUid("hudGunList")
  local thisWindow = uiWindow.uiWindowList[thisWindowUid]
  if thisWindow.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the uiWindow
  love.graphics.translate(thisWindow.originX, thisWindow.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisWindow.width, #player.guns*M.gunHudListItemHeight, 20, 20, 20)
  local gunListYPosOffset = 0
  for i, gunId in pairs(player.guns) do
    M.drawHudGunListItem(gunList[gunId], 5, gunListYPosOffset)
    gunListYPosOffset = gunListYPosOffset + M.gunHudListItemHeight
  end
  love.graphics.pop() -- return back to previous transformation state
end

local function createHudGunList()
  local targetX, targetY = 0.01, 0.15
  local targetWidth, targetHeight = 0.07, 0.4
  local newWindowUid = uiWindow.new(targetX, targetY, targetWidth, targetHeight, "hudGunList", drawHudGunList, true, false)
  M.uiWindowUidCache["hudGunList"] = newWindowUid
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
  local thisWindowUid = uiWindow.getWindowUid("gunEditMenu")
  local thisWindow = uiWindow.uiWindowList[thisWindowUid]
  if thisWindow.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the uiWindow
  love.graphics.translate(thisWindow.originX, thisWindow.originY)
  -- draw the window shape
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisWindow.width, thisWindow.height, 20, 20, 20)

  -- draw all of this window's children
  -- uiWindow.drawChildren(thisWindowUid)

  -- iterate through all the player's guns, creating UI elements within the window for each one
    for i,gunId in ipairs(player.guns) do
      -- get the data for the currently-examined gun
      local thisGun = gunList[gunId]
      -- determine how much space to allocate for the gun's UI elements

      -- draw the gun sprite display panel

      -- draw the gun mod capacity display panel

      -- draw the gun stat display panel

      -- draw the gun lore display panel

      -- iterate through the gun's events, drawing an editable element for each

        -- draw event's mod list

        -- draw event's trigger condition display
    end
  love.graphics.pop()
end

local function drawGunEditLSplit()
  local thisWindowUid = uiWindow.getWindowUid("gunEditMenu-LeftSplit")
  local thisWindow = uiWindow.uiWindowList[thisWindowUid]
  if thisWindow.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the uiWindow
  love.graphics.translate(thisWindow.originX, thisWindow.originY)
  -- draw the window shape
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisWindow.width, thisWindow.height, 20, 20, 20)
  love.graphics.pop()
end

local function drawGunEditRSplit()
  local thisWindowUid = uiWindow.getWindowUid("gunEditMenu-RightSplit")
  local thisWindow = uiWindow.uiWindowList[thisWindowUid]
  if thisWindow.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the uiWindow
  love.graphics.translate(thisWindow.originX, thisWindow.originY)
  -- draw the window shape
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisWindow.width, thisWindow.height, 20, 20, 20)
  love.graphics.pop()
end


local function createGunEditMenu()
  -- set correct origin point/width/height
  local targetX, targetY = 0.1, 0.1
  local targetWidth, targetHeight = 0.8, 0.8

  -- if editing window hasn't been created yet, create it
  local newWindowUid = uiWindow.new(targetX, targetY, targetWidth, targetHeight, "gunEditMenu", drawGunEditMenu, false, false)
  M.uiWindowUidCache["gunEditMenu"] = newWindowUid

  -- create left and right subwindows of edit window
  local lSubTargetX, lSubTargetY = 0, 0
  local lSubTargetWidth, lSubTargetHeight = 0.19, 1 
  local leftSubWindowUid = uiWindow.new(lSubTargetX, lSubTargetY, lSubTargetWidth, lSubTargetHeight, "gunEditMenu-LeftSplit", drawGunEditLSplit, false, false)
  uiWindow.addItem(newWindowUid, uiWindow.uiWindowList[leftSubWindowUid])
  M.uiWindowUidCache["gunEditMenu-LeftSplit"] = leftSubWindowUid

  local rSubTargetX, rSubTargetY = 0.2, 0
  local rSubTargetWidth, rSubTargetHeight = 0.8, 1
  local rightSubWindowUid = uiWindow.new(rSubTargetX, rSubTargetY, rSubTargetWidth, rSubTargetHeight, "gunEditMenu-RightSplit", drawGunEditRSplit, false, false)
  uiWindow.addItem(newWindowUid, uiWindow.uiWindowList[rightSubWindowUid])
  M.uiWindowUidCache["gunEditMenu-RightSplit"] = rightSubWindowUid

  -- test code
  -- local testText = {textTable={{1,0,0,1},"[",{0,1,0,1},"print function test",{1,0,0,1},"]"}}
  -- local testText2 = {textTable={{1,1,0,1},"[",{0,1,1,1},"print function test",{1,1,0,1},"]"}}
  -- local testLabel = elements.createLabel("testLabel", 5, 5, 500, 20, testText)
  -- uiWindow.addItem(newWindowUid, testLabel)
  -- local testLabel2 = elements.createLabel("testLabel2", 300, 100, 500, 20, testText2)
  -- uiWindow.addItem(newWindowUid, testLabel2)
end

M.toggleGunEditMenuOpen = function()
  uiWindow.toggleRendering(M.uiWindowUidCache["gunEditMenu"])
  uiWindow.toggleRendering(M.uiWindowUidCache["gunEditMenu-LeftSplit"])
  uiWindow.toggleRendering(M.uiWindowUidCache["gunEditMenu-RightSplit"])
  uiWindow.toggleInteractable(M.uiWindowUidCache["gunEditMenu"])
  M.gunEditMenuOpen = not M.gunEditMenuOpen
end
-- }}}

-- player's per-run mod collection {{{

-- }}}

-- primary functions for creating/drawing/updating hud
-- these are the ones that get called directly in main.lua 
-- {{{
M.draw = function(player, gunList)
  -- uiWindow.uiWindowList["hudGunList"]:draw(player, gunList)
  -- uiWindow.uiWindowList["hudHealthBar"]:draw(player)
  -- uiWindow.uiWindowList["gunEditMenu"]:draw(player, gunList)

  for _,v in pairs(M.uiWindowUidCache) do
    util.shallowTPrint(uiWindow.uiWindowList[v])
    uiWindow.uiWindowList[v]:draw(player, gunList)
  end
end

-- for creating uiWindow for hud before first drawcall
M.setup = function()
  createHudGunList()
  createHealthBar()
  createGunEditMenu()
end

M.update = function(dt)
  -- util.shallowTPrint(uiWindow.uiWindowList)

  -- update all uiWindows
  uiWindow.update(dt)

  -- update all uiElements
  
end -- }}}



return M
-- vim: foldmethod=marker
