-- Module for making rectangular menus or UI boxes that render above everything else and can be focusable/interactable
-- UiBoxes are responsible for resizing in response to window size changes
local M = {}

local util = require'util'
local hud = require'ui.hud'

-- defines {{{
M.thisFrameWindowSizeX = 800
M.thisFrameWindowSizeY = 600
M.lastFrameWindowSizeX = 800
M.lastFrameWindowSizeY = 600
-- }}}

M.uiBoxList = {} -- table holding data for every UI box curently rendered onscreen, keyed by UID

local function drawBox(uiBox)
  love.graphics.setColor(uiBox.borderColor)
  love.graphics.rectangle("line", uiBox.originX, uiBox.originY, uiBox.width, uiBox.height, 20, 20, 1)
end

-- create a new UI box
-- args:
-- originX(num): x-coordinate of top left corner of box
-- originY(num): y-coordinate of top left corner of box
-- width(num): width in pixels of the box
-- height(num): height in pixels of the box
-- minWidth(num): smallest possible width the uibox is allowed to shrink to
-- minHeight(num) smallest possible height the uibox is allowed to shrink to
-- name(string): non-player visible name for the UI box, for programmer organization
-- drawFunc(func): a function to call to draw the contents of the box
M.createUiBox = function(originX, originY, width, height, minWidth, minHeight, name, drawFunc)
  local newUiBox = {}
  newUiBox.shouldRender = true -- whether the box should render this frame
  newUiBox.focusable = false -- whether the box can listen and respond to kb/mouse/controller inputs
  newUiBox.focused = false -- whether the box is currently listening to kb/mouse/controller inputs
  newUiBox.borderColor = {1, 1, 1, 1} -- table containing RGBA value for color of box border
  newUiBox.originX = originX
  newUiBox.originY = originY
  newUiBox.width = width
  newUiBox.minWidth = minWidth
  newUiBox.height = height
  newUiBox.minHeight = minHeight
  newUiBox.name = name
  newUiBox.draw = drawBox
  M.uiBoxList[util.gen_uid("uibox")] = newUiBox
end

M.destroyUiBox = function(uiBoxUid)
  table.remove(M.uiBoxList, uiBoxUid)
end

M.drawAllUiBoxes = function()
  for i,box in ipairs(M.uiBoxList) do
    if box.shouldRender then
      box:draw()
    end
  end
end

M.update = function (dt)
  M.lastFrameWindowSizeX, M.lastFrameWindowSizeY = M.thisFrameWindowSizeX, M.thisFrameWindowSizeY
  M.thisFrameWindowSizeX, M.thisFrameWindowSizeY = love.graphics.getDimensions()
  for i,box in ipairs(M.uiBoxList) do
    -- resize ui boxes based on window size, respecting minimum width/height values
    box.width = math.max(box.minWidth, math.floor(box.width * (M.thisFrameWindowSizeX / M.lastFrameWindowSizeX)))
    box.height = math.max(box.minHeight, math.floor(box.height * (M.thisFrameWindowSizeY / M.lastFrameWindowSizeY)))
  end
end
return M
-- vim: foldmethod=marker
