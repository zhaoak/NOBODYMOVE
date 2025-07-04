-- Module for drawing all UI present during normal gameplay.
-- This includes the HUD, gun/event editing screen, and more.
-- Each UI element (examples: health display, gun status display) gets its own uiWindow.
-- See `uiWindow.lua` for how they work.

local uiWindow = require'ui.uiWindow'
local elements = require'ui.uiElements'
local util = require'util'
local state = require'gamestate'
local M = { }

-- defines {{{
-- Pixel width/height values for various UI elements when uiScale = 1.
-- In other words, the defaults.
M.gunHudListItemHeight = 110
M.gunHudListItemWidth = 150
M.healthDisplayWidth = 250
M.healthDisplayHeight = 50
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

local function drawTestWindow()
  local thisWindowUid = uiWindow.getWindowUid("testSubWin1")
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
  local newWindowUid = uiWindow.new(targetX, targetY, targetWidth, targetHeight, "gunEditMenu", drawGunEditMenu, false, false, false)
  M.uiWindowUidCache["gunEditMenu"] = newWindowUid

  -- create left and right subwindows of edit window
  local lSubTargetX, lSubTargetY = 0, 0
  local lSubTargetWidth, lSubTargetHeight = 0.19, 1 
  local leftSubWindowUid = uiWindow.new(lSubTargetX, lSubTargetY, lSubTargetWidth, lSubTargetHeight, "gunEditMenu-LeftSplit", drawGunEditLSplit, false, false, false)
  uiWindow.addItem(newWindowUid, uiWindow.uiWindowList[leftSubWindowUid])
  M.uiWindowUidCache["gunEditMenu-LeftSplit"] = leftSubWindowUid

  local rSubTargetX, rSubTargetY = 0.2, 0
  local rSubTargetWidth, rSubTargetHeight = 0.8, 1
  local rightSubWindowUid = uiWindow.new(rSubTargetX, rSubTargetY, rSubTargetWidth, rSubTargetHeight, "gunEditMenu-RightSplit", drawGunEditRSplit, false, false, false)
  uiWindow.addItem(newWindowUid, uiWindow.uiWindowList[rightSubWindowUid])
  M.uiWindowUidCache["gunEditMenu-RightSplit"] = rightSubWindowUid

  -- test code

  local testText = {textTable={{1,0,0,1},"[",{0,1,0,1},"print function test",{1,0,0,1},"]"}}
  local testText2 = {textTable={{1,1,0,1},"[",{0,1,1,1},"print function test",{1,1,0,1},"]"}}
  local testLabelUid = elements.createTextBox(0.01, 0.01, 0.9, 0.1, "testLabel", testText, false, false)
  uiWindow.addItem(rightSubWindowUid, elements.uiElementList[testLabelUid])
  local testLabel2Uid = elements.createTextBox(0.01, 0.05, 0.9, 0.1, "testLabel2", testText2, false, false)
  uiWindow.addItem(rightSubWindowUid, elements.uiElementList[testLabel2Uid])
  local testButtonText = {textTable={{1,0,0,1},"[",{0,1,0,1},"button test",{1,0,0,1},"]"}, align = "center"}
  local testButtonCallbackTest = {primary = function() print("button pressed using primary!") end,
                                  secondary = function() print("button pressed using secondary!") end,
                                  tertiary = function() print("button pressed using tertiary!") end,
                                  cancel = function() print("button pressed using cancel!") end}
  local testButtonUid = elements.createButton(0.01, 0.1, 0.2, 0.05, "testButton", testButtonText, false, false, testButtonCallbackTest)
  uiWindow.addItem(rightSubWindowUid, elements.uiElementList[testButtonUid])
  local testButtonUid2 = elements.createButton(0.01, 0.2, 0.2, 0.05, "testButton2", testButtonText, false, false, testButtonCallbackTest)
  uiWindow.addItem(rightSubWindowUid, elements.uiElementList[testButtonUid2])
  local testButtonUid3 = elements.createButton(0.01, 0.3, 0.2, 0.05, "testButton3", testButtonText, false, false, testButtonCallbackTest)
  uiWindow.addItem(rightSubWindowUid, elements.uiElementList[testButtonUid3])

  local testSubWin1 = uiWindow.new(0.1, 0.5, 1, 0.5, "testSubWin1", drawTestWindow, false, false, true)
  uiWindow.addItem(rightSubWindowUid, uiWindow.uiWindowList[testSubWin1])
  M.uiWindowUidCache["testSubWin1"] = testSubWin1

  local testSubButton1 = elements.createButton (0.01, 0.1, 0.2, 0.05, "testSubButton1", testButtonText, false, false, testButtonCallbackTest)
  uiWindow.addItem(testSubWin1, elements.uiElementList[testSubButton1])
end

M.toggleGunEditMenuOpen = function()
  uiWindow.toggleRendering(M.uiWindowUidCache["gunEditMenu"])
  uiWindow.toggleInteractable(M.uiWindowUidCache["gunEditMenu-RightSplit"])
  state.gunEditMenuOpen = not state.gunEditMenuOpen
  if state.gunEditMenuOpen == true then
    uiWindow.setNavigating(M.uiWindowUidCache["gunEditMenu-RightSplit"])
  else
    uiWindow.setNavigating(-1)
  end
end
-- }}}

-- player's per-run mod stash {{{

-- }}}

-- primary functions for creating/drawing/updating hud
-- these are the ones that get called directly in main.lua 
-- {{{
M.draw = function(player, gunList)
  -- uiWindow.uiWindowList["hudGunList"]:draw(player, gunList)
  -- uiWindow.uiWindowList["hudHealthBar"]:draw(player)
  -- uiWindow.uiWindowList["gunEditMenu"]:draw(player, gunList)

  -- draw all uiWindows, as well as the selection border for any selected items
  for _,v in pairs(M.uiWindowUidCache) do
    uiWindow.uiWindowList[v]:draw(player, gunList)
    if uiWindow.uiWindowList[v].navigating == true then
      uiWindow.drawSelectionBorder(v)
    end
    -- util.shallowTPrint(uiWindow.uiWindowList[v])
  end
  
  -- draw all uiElements
  for _, v in ipairs(elements.uiElementList) do
    -- util.shallowTPrint(v)
    v:draw()
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
