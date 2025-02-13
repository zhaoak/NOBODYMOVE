-- Module for creating UI elements (buttons, sliders, etc.)
-- Elements must live inside a uiWindow.

local M = {}

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

-- Button that does a thing once when pressed. Can be activated by mouse click or controller input.
-- args:
-- name(string): internal name of button. Used as key and identifier by the uiwindow containing the button.
-- x(number): 
local function createButton(name, x, y, drawFunc, onActivation)
  local newButton = {}
end


return M
-- vim: foldmethod=marker
