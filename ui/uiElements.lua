-- Module for creating UI elements (buttons, sliders, etc.)
-- Elements must live inside a uiWindow.

local M = {}

local util = require'util'

M.uiElementList = {} -- List containing every uiElement created, keyed by UID

-- utility rendering functions {{{

-- Draw text onscreen at an arbitrary location. Intended to be used for ingame UI.
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
    textTable = {values.color or {1,0,0,1}, values.text or "YOU DIDNT SAY WHAT TEXT TO DRAW BUDDY"}
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
-- selectable(bool): whether element can be highlighted and navigated to via controller inputs from parent window
-- extra(tbl): Holds any state data needed by specific elements (slider values, checkbox status, etc)
-- onInput(tbl): List of callback functions for different types of player input on element
--
-- returns: UID for newly created element
M.newElement = function(originXTarget, originYTarget, widthTarget, heightTarget, name, drawFunc, shouldRender, interactable, selectable, extra, onInput)
  local newUiElement = {}
  newUiElement.elementUid = util.gen_uid("uiElements")
  newUiElement.originXTarget = originXTarget
  newUiElement.originYTarget = originYTarget
  newUiElement.widthTarget = widthTarget
  newUiElement.heightTarget = heightTarget
  newUiElement.shouldRender = shouldRender or false
  newUiElement.interactable = interactable or false
  newUiElement.selectable = selectable or false
  newUiElement.draw = function() drawFunc(newUiElement.elementUid) end
  newUiElement.parentWindowUid = -1
  newUiElement.name = name
  newUiElement.extra = extra
  newUiElement.onInput = onInput
  M.uiElementList[newUiElement.elementUid] = newUiElement
  return newUiElement.elementUid
end

-- Create/draw functions for individual element types  {{{

-- Text display of arbitrary size and length.
--
-- args:
-- originXTarget(num): accepts values of 0-1, representing at what point along parent's width to place origin
-- originYTarget(num): same as above, but for height value of parent
-- widthTarget(num): percentage of parent's width this element should take up
-- heightTarget(num): percentege of parent's height this element should take up
-- name(string): non-player visible name for the element, for programmer use
-- textContent(table): a table that gets directly passed to `drawText` as its argument.
--                Specifies what text to draw, as well as how to format it.
--                See the `drawText` function in this file for table format.
-- shouldRender(bool): whether element should render this frame: may be changed anytime
-- interactable(bool): whether player can click on, navigate with gamepad or otherwise interact with the element
--
-- returns: UID for newly created element
M.createTextBox = function(originXTarget, originYTarget, widthTarget, heightTarget, name, textContent, shouldRender, interactable)
  local drawFunc = M.drawTextBox
  local extra = {textContent = textContent}
  local newElementUid = M.newElement(originXTarget, originYTarget, widthTarget, heightTarget, name, drawFunc, shouldRender, interactable, false, extra, nil)
  return newElementUid
end

M.drawTextBox = function(textBoxUid)
  local thisTextBox = M.uiElementList[textBoxUid]
  if thisTextBox.shouldRender == false then return end
  M.drawText(thisTextBox.extra.textContent, thisTextBox.originX, thisTextBox.originY, thisTextBox.width)
end


-- Button that does a thing once when pressed. Can be activated by mouse click or controller input.
--
-- args:
-- originXTarget(num): accepts values of 0-1, representing at what point along parent's width to place origin
-- originYTarget(num): same as above, but for height value of parent
-- widthTarget(num): percentage of parent's width this element should take up
-- heightTarget(num): percentege of parent's height this element should take up
-- name(string): non-player visible name for the element, for programmer use
-- textContent(table): a table that gets directly passed to `drawText` as its argument.
--                Specifies what text to draw, as well as how to format it.
--                See the `drawText` function in this file for table format.
-- shouldRender(bool): whether element should render this frame: may be changed anytime
-- interactable(bool): whether player can click on, navigate with gamepad or otherwise interact with the element
-- onInput(tbl): table of callback functions to be triggered when element recieves specific inputs
--               see `windowing.lua` for how to format this table
--
-- returns: uid for new button element
M.createButton = function (originXTarget, originYTarget, widthTarget, heightTarget, name, textContent, shouldRender, interactable, onInput)
  local drawFunc = M.drawButton
  local extra = {uiState = "normal", textContent = textContent}
  local newButtonUid = M.newElement(originXTarget, originYTarget, widthTarget, heightTarget, name, drawFunc, shouldRender, interactable, true, extra, onInput)
  return newButtonUid
end

M.drawButton = function(buttonUid)
  local thisButton = M.uiElementList[buttonUid]
  if thisButton.shouldRender == false then return end
  love.graphics.push()
  love.graphics.translate(thisButton.originX, thisButton.originY)
  love.graphics.setColor(1, 1, 1, 0.5)
  if thisButton.extra.uiState == "normal" then
    love.graphics.rectangle("line", 0, 0, thisButton.width, thisButton.height, 5, 5, 5)
  end
  love.graphics.pop()
  M.drawText(thisButton.extra.textContent, thisButton.originX, thisButton.originY, thisButton.width)
end

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
