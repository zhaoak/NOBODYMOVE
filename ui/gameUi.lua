-- Module for drawing all UI present during normal gameplay.
-- This includes the HUD, gun/event editing screen, and more.
-- Each UI element (examples: health display, gun status display) gets its own uiWindow.
-- See `uiWindow.lua` for how they work.

local uiWindow = require'ui.uiWindow'
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

-- health and status bar {{{
local function drawHealthBar(self, player)
  local thisWindow = uiWindow.uiWindowList["hudHealthBar"]
  if thisWindow.shouldRender == false then return end
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
  local originX, originY = 5, uiWindow.thisFrameGameResolutionY - M.healthDisplayHeight 
  local width, height = M.healthDisplayWidth*uiWindow.uiScale, M.healthDisplayHeight*uiWindow.uiScale
  uiWindow.create(originX, originY, width, height, "hudHealthBar", createHealthBar, drawHealthBar, true, false)
end
-- }}}

-- gunlist on hud when gun editing menu closed {{{
local function drawHudGunList(self, player, gunList)
  local thisWindow = uiWindow.uiWindowList["hudGunList"]
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
  local originX, originY = 5, uiWindow.thisFrameGameResolutionY * (1/10)
  local width, height = M.gunHudListItemWidth*uiWindow.uiScale, M.gunHudListItemHeight*uiWindow.uiScale*4 -- for four firegroups
  uiWindow.create(originX, originY, width, height, "hudGunList", createHudGunList, drawHudGunList, true, false)
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
  local thisWindow = uiWindow.uiWindowList["gunEditMenu"]
  if thisWindow.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the uiWindow
  love.graphics.translate(thisWindow.originX, thisWindow.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisWindow.width, thisWindow.height, 20, 20, 20)
  love.graphics.pop()
end

local function createGunEditMenu()
  local originX, originY = 5+(M.gunHudListItemWidth*uiWindow.uiScale), uiWindow.thisFrameGameResolutionY * (1/10)
  local width, height = uiWindow.thisFrameGameResolutionX-2*M.gunHudListItemWidth, uiWindow.thisFrameGameResolutionY - (uiWindow.thisFrameGameResolutionY*(1/5))
  uiWindow.create(originX, originY, width, height, "gunEditMenu", createGunEditMenu, drawGunEditMenu, false, false)
end

M.toggleGunEditMenuOpen = function()
  uiWindow.uiWindowList["gunEditMenu"].shouldRender = not uiWindow.uiWindowList["gunEditMenu"].shouldRender
  uiWindow.uiWindowList["hudGunList"].shouldRender = not uiWindow.uiWindowList["hudGunList"].shouldRender
  uiWindow.uiWindowList["gunEditMenu"].interactable = not uiWindow.uiWindowList["gunEditMenu"].interactable
  M.gunEditMenuOpen = not M.gunEditMenuOpen
end
-- }}}

-- player's per-run mod collection {{{

-- }}}

-- general ui elements -- text labels, mod slots, etc {{{

-- Draw text onscreen. Intended to be used for ingame UI.
-- Colors provided via `textTable` are *not* affected by color currently set via `love.graphics.setColor`.
-- args:
-- textTable(table): Table containing strings and colors to print them in in the following format:
--  `{color1, string1, color2, string2, ...}`
--    - color1(table): Table containing red, green, blue, and optional alpha values in format: `{r, g, b, a}`
--    - string1(table): String to render using the corresponding color1 values.
--    color2 and string2 correspond, as do any additional pairs provided.
-- font(Font): Love font object to use when drawing text.
-- x(number): text position on x-axis
-- y(number): text position on y-axis
-- lineLimit(number): wrap the line after this many horizontal pixels
-- align(string): alignment mode of text, one of: "center", "left", "right", "justify"
-- angle(number): rotation of text in radians; 0 is normal, un-rotated text
-- sx,sy(numbers): x/y scale factors for text
-- ox,oy(numbers): x/y origin offsets for text
-- kx, ky(numbers): x/y shearing factors
local function drawText(textTable, font, x, y, lineLimit, align, angle, sx, sy, ox, oy, kx, ky)
  local colorCacheR,colorCacheG,colorCacheB,colorCacheA = love.graphics.getColor()
  love.graphics.printf(textTable, font, x, y, lineLimit, align, angle, sx, sy, ox, oy, kx, ky)
  love.graphics.setColor(colorCacheR, colorCacheG, colorCacheB, colorCacheA)
end
-- }}}

-- test menu, for testing UI code {{{
local function drawTestUI(self)
  local thisWindow = uiWindow.uiWindowList["testUI"]
  if thisWindow.shouldRender == false then return end
  love.graphics.push() -- save previous transformation state
  -- then set 0,0 point for graphics calls to the top left corner of the uiWindow
  love.graphics.translate(thisWindow.originX, thisWindow.originY)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 0, 0, thisWindow.width, thisWindow.height, 20, 20, 20)
  love.graphics.pop()
end

local function createTestUI()
  local originX, originY = uiWindow.thisFrameGameResolutionX / 3, uiWindow.thisFrameGameResolutionY / 3
  local width, height = 300, 300
  uiWindow.create(originX, originY, width, height, "testUI", createTestUI, drawTestUI, true, true)
  uiWindow.uiWindowList["testUI"].onClick = function() print("test uiWindow clicked") end
end
-- }}}

-- primary functions for creating/drawing/updating hud
-- these are the ones that get called directly in main.lua 
-- {{{
M.draw = function(player, gunList)
  uiWindow.uiWindowList["hudGunList"]:draw(player, gunList)
  uiWindow.uiWindowList["hudHealthBar"]:draw(player)
  uiWindow.uiWindowList["gunEditMenu"]:draw(player, gunList)

  -- test code
  -- uiWindow.uiWindowList["testUI"]:draw()
end

-- for creating uiWindow for hud before first drawcall
M.setup = function()
  createHudGunList()
  createHealthBar()
  createGunEditMenu()

  -- test UI
  createTestUI()
end

M.update = function()

end -- }}}



return M
-- vim: foldmethod=marker
