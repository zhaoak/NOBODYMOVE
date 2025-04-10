-- Module for creating UI elements (buttons, sliders, etc.)
-- Elements must live inside a uiWindow.
-- Note that all elements' positioning is stored as an offset from the position values
-- (originX and originY) of the element's containing uiWindow.
-- That is, when rendered, the element's position is calculated by treating its' parent uiWindow's
-- position values as (0, 0).

local M = {}

local util = require'util'

M.uiElementList = {} -- List containing every uiElement created, keyed by name

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
  -- x(number): text position on x-axis
  -- y(number): text position on y-axis
  -- lineLimit(number): wrap the line after this many horizontal pixels
  -- align(string): alignment mode of text, one of: "center", "left", "right", "justify"
  -- angle(number): rotation of text in radians; 0 is normal, un-rotated text
  -- sx,sy(numbers): x/y scale factors for text
  -- ox,oy(numbers): x/y origin offsets for text
  -- kx, ky(numbers): x/y shearing factors
M.drawText = function(values)
  local textTable
  if values.textTable then
    textTable = values.textTable
  else
    textTable = {values.color or {1,0,0,1}, values.text or "HEY YOU DIDNT PUT TEXT TO DRAW IN THE FUNCTIONG THAT DRQWS IT"}
  end
  local font = values.font or love.graphics.getFont() -- come back once there is a custom font implemented at all
  local x = values.x or 0
  local y = values.y or 0
  local lineLimit = values.lineLimit or 500
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
  love.graphics.printf(textTable, font, x, y, lineLimit, align, angle, sx, sy, ox, oy, kx, ky)
  love.graphics.setColor(colorCacheR, colorCacheG, colorCacheB, colorCacheA)
end
--- }}}

-- extra is for any custom data needed by specific elements (slider values, checkbox status, etc)
M.newElement = function(name, originX, originY, width, height, shouldRender, interactable, selectable, extra)
  local newUiElement = {}
  newUiElement.name = name
  newUiElement.elementUid = util.gen_uid("uiElements")
  newUiElement.originX = originX
  newUiElement.originY = originY
  newUiElement.width = width
  newUiElement.height = height
  newUiElement.shouldRender = shouldRender or false
  newUiElement.interactable = interactable or false
  newUiElement.selectable = selectable or false
  M.uiElementList[name] = newUiElement
  return newUiElement
end

-- List of element creation functions {{{

-- Text display of arbitrary size and length.
--
-- args:
-- name(string): internal name of element, used for human identification of item.
-- x,y(numbers): screen coords of top-right corner of label, offset from originX/originY of containing uiWindow
-- width,height(nums): in pixels, height/width of label
-- values(table): a table that gets directly passed to `drawText` as its argument.
--                See the `drawText` function in this file for table format.
--
-- returns: table containing data for new label
M.createLabel = function(name, x, y, width, height, values)
  local newLabel = {}
  newLabel.name = name
  newLabel.x = x or 0
  newLabel.y = y or 0
  newLabel.width = width or 100
  newLabel.height = height or 20
  newLabel.values = values
  newLabel.values.x = newLabel.x
  newLabel.values.y = newLabel.y
  newLabel.values.lineLimit = newLabel.width
  newLabel.drawFunc = function() M.drawText(newLabel.values) end
  return newLabel
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
M.createButton = function (name, x, y, width, height, drawFunc, onActivation)
  local newButton = {}
  newButton.x = x
  newButton.y = y
  newButton.name = name
  newButton.width = width or 100
  newButton.height = height or 30
  newButton.drawFunc = drawFunc
  newButton.onActivation = onActivation
  return newButton
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

return M
-- vim: foldmethod=marker
