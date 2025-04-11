-- Module for creating UI elements (buttons, sliders, etc.)
-- Elements must live inside a uiWindow.

local M = {}

local util = require'util'

M.uiElementList = {} -- List containing every uiElement created, keyed by UID

-- utility rendering functions {{{

-- Draw text onscreen. Intended to be used for ingame UI.
-- Colors provided via `textTable` are *not* affected by color currently set via `love.graphics.setColor`.
-- args:
-- values(table):
  -- textTable(table): Table containing string-color pairs to print in the following format:
  --  `{color1, string1, color2, string2, ...}`
  --    - color1(table): Table containing red, green, blue, and optional alpha values in format: `{r, g, b, a}`
  --    - string1(table): String to render using the corresponding color1 values.
  --    color2 and string2 correspond, as do any additional pairs provided.
  --    So, a textTable value of `{{1,0,0,1}, "horse", {0,1,0,1}, "crime"}` would print:
  --    "horsecrime" with "horse" in red and "crime" in green.
  -- font(Font): Love font object to use when drawing text. Defaults to currently set font.
  -- align(string): alignment mode of text, one of: "center", "left", "right", "justify"
  -- angle(number): rotation of text in radians; 0 is normal, un-rotated text
  -- sx,sy(numbers): x/y scale factors for text
  -- ox,oy(numbers): x/y origin offsets for text
  -- kx, ky(numbers): x/y shearing factors
-- x(number): text position on x-axis
-- y(number): text position on y-axis
-- lineLimit(number): wrap the line after this many horizontal pixels
M.drawText = function(values, x, y, lineLimit)
  local textTable
  if values.textTable then
    textTable = values.textTable
  else
    textTable = {values.color or {1,0,0,1}, values.text or "HEY YOU DIDNT PUT TEXT TO DRAW IN THE FUNCTIONG THAT DRQWS IT"}
  end
  local font = values.font or love.graphics.getFont() -- come back once there is a custom font implemented at all
  local widthLimit = lineLimit
  local align = values.align or "left"
  local angle = values.angle or 0
  local sx = values.sx or 1
  local sy = values.sy or 1
  local ox = values.ox or 0
  local oy = values.oy or 0
  local kx = values.kx or 0
  local ky = values.ky or 0
  local colorCacheR,colorCacheG,colorCacheB,colorCacheA = love.graphics.getColor()
  love.graphics.setColor(1,1,1,1)
  love.graphics.printf(textTable, font, x, y, widthLimit, align, angle, sx, sy, ox, oy, kx, ky)
  love.graphics.setColor(colorCacheR, colorCacheG, colorCacheB, colorCacheA)
end
--- }}}

-- Create a new uiElement and add it to the tracked list of uiElements
-- 
-- args:
-- 
-- originXTarget(num): accepts values of 0-1, representing at what point along parent's width to place origin
-- originYTarget(num): same as above, but for height value of parent
-- widthTarget(num): percentage of parent's width this element should take up
-- heightTarget(num): percentege of parent's height this element should take up
-- name(string): non-player visible name for the element, for programmer use
-- drawFunc(func): rendering function for element, passed in by an element's more specific constructor 
-- shouldRender(bool): whether element should render this frame: may be changed anytime
-- interactable(bool): whether player can click on, navigate with gamepad or otherwise interact with the element
-- extra(tbl): Holds any state data needed by specific elements (slider values, checkbox status, etc)
--
-- returns: UID for newly created element
M.newElement = function(originXTarget, originYTarget, widthTarget, heightTarget, name, drawFunc, shouldRender, interactable, extra)
  local newUiElement = {}
  newUiElement.elementUid = util.gen_uid("uiElements")
  newUiElement.originXTarget = originXTarget
  newUiElement.originYTarget = originYTarget
  newUiElement.widthTarget = widthTarget
  newUiElement.heightTarget = heightTarget
  newUiElement.shouldRender = shouldRender or false
  newUiElement.interactable = interactable or false
  -- newUiElement.selectable = selectable or false
  newUiElement.draw = function() drawFunc(newUiElement.elementUid) end
  newUiElement.name = name
  newUiElement.extra = extra
  M.uiElementList[newUiElement.elementUid] = newUiElement
  return newUiElement.elementUid
end

-- Create/draw functions for individual element types  {{{

M.drawTextBox = function(textBoxUid)
  local thisTextBox = M.uiElementList[textBoxUid]
  if thisTextBox.shouldRender == false then return end
  M.drawText(thisTextBox.extra.textContent, thisTextBox.originX, thisTextBox.originY, thisTextBox.width)
end

-- Text display of arbitrary size and length.
--
-- args:
-- originXTarget(num): accepts values of 0-1, representing at what point along parent's width to place origin
-- originYTarget(num): same as above, but for height value of parent
-- widthTarget(num): percentage of parent's width this element should take up
-- heightTarget(num): percentege of parent's height this element should take up
-- name(string): non-player visible name for the element, for programmer use
-- values(table): a table that gets directly passed to `drawText` as its argument.
--                Specifies what text to draw, as well as how to format it.
--                See the `drawText` function in this file for table format.
-- shouldRender(bool): whether element should render this frame: may be changed anytime
-- interactable(bool): whether player can click on, navigate with gamepad or otherwise interact with the element
--
-- returns: UID for newly created element
M.createTextBox = function(originXTarget, originYTarget, widthTarget, heightTarget, name, values, shouldRender, interactable)
  local drawFunc = M.drawTextBox
  local extra = {textContent = values}
  local newElementUid = M.newElement(originXTarget, originYTarget, widthTarget, heightTarget, name, drawFunc, shouldRender, interactable, extra)
  return newElementUid
end

-- Button that does a thing once when pressed. Can be activated by mouse click or controller input.
--
-- args:
-- name(string): internal name of button. Used as key and identifier by the uiwindow containing the button.
-- x,y(numbers): screen coordinates of the top-right corner of the button,
--               *relative to `originX` and `originY` values of the containing `uiWindow`*
-- width,height(nums): in pixels, width/height of button
-- drawFunc(func): callback function for rendering this specific button
-- onActivation(func): callback function to run once when button is pressed
--
-- returns: table containing data for new button
-- M.createButton = function (name, x, y, width, height, drawFunc, onActivation)
--   local newButton = {}
--   newButton.x = x
--   newButton.y = y
--   newButton.name = name
--   newButton.width = width or 100
--   newButton.height = height or 30
--   newButton.drawFunc = drawFunc
--   newButton.onActivation = onActivation
--   return newButton
-- end

-- }}}

-- Get an element's UID by its programmer-visible name
M.getElementUid = function(elementName)
  for _, v in ipairs(M.uiElementList) do
    if v.name == elementName then return v.elementUid end
  end
end

-- Checks if an element with a given internal name exists already
M.namedElementExists = function(elementName)
  for _, v in ipairs(M.uiElementList) do
    if v.name == elementName then return true end
  end
  return false
end

-- Toggles a element's `shouldRender` property, given its UID.
M.toggleRendering = function(elementUid)
  M.uiElementList[elementUid].shouldRender = not M.uiElementList[elementUid].shouldRender
end

-- Toggles a element's `interactable` property, given its UID.
M.toggleInteractable = function(elementUid)
  M.uiElementList[elementUid].interactable = not M.uiElementList[elementUid].interactable
end

return M
-- vim: foldmethod=marker
