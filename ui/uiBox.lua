-- Module for making rectangular menus or UI boxes that render above everything else and can be focusable/interactable
-- UiBoxes are responsible for resizing in response to window size changes
local M = {}

-- defines {{{
M.thisFrameWindowSizeX = 800
M.thisFrameWindowSizeY = 600
M.lastFrameWindowSizeX = 800
M.lastFrameWindowSizeY = 600
-- }}}

M.uiBoxList = {} -- table holding data for every UI box curently rendered onscreen, keyed by name

-- create a new UI box
-- if the uibox with the specified key 'name' already exists, it gets overwritten by the newly created one
-- args:
-- originX(num): x-coordinate of top left corner of box
-- originY(num): y-coordinate of top left corner of box
-- width(num): width in pixels of the box
-- height(num): height in pixels of the box
-- name(string): non-player visible name for the UI box, used as key in M.uiBoxList
-- createFunc(func): function to call to recreate uibox when window size changes
-- drawFunc(func): a function to call to draw the contents of the box
-- shouldRender(bool): whether uibox should render this frame: may be changed anytime
-- focusable(bool): whether player can click on, navigate with gamepad or otherwise interact with the box
M.create = function(originX, originY, width, height, name, createFunc, drawFunc, shouldRender, focusable, focused)
  local newUiBox = {}
  newUiBox.shouldRender = shouldRender -- whether the box should render this frame
  newUiBox.focusable = focusable -- whether the box can listen and respond to kb/mouse/controller inputs
  newUiBox.focused = false -- whether the box is currently listening to kb/mouse/controller inputs
  newUiBox.borderColor = {1, 1, 1, 1} -- table containing RGBA value for color of box border
  newUiBox.originX = originX
  newUiBox.originY = originY
  newUiBox.width = width
  newUiBox.height = height
  newUiBox.name = name
  newUiBox.create = createFunc
  newUiBox.draw = drawFunc
  M.uiBoxList[name] = newUiBox
end

M.destroy = function(uiBoxUid)
  table.remove(M.uiBoxList, uiBoxUid)
end

M.update = function (dt)
  -- cache last frame's and the current frame's window size
  M.lastFrameWindowSizeX, M.lastFrameWindowSizeY = M.thisFrameWindowSizeX, M.thisFrameWindowSizeY
  M.thisFrameWindowSizeX, M.thisFrameWindowSizeY = love.graphics.getDimensions()

  -- check if the window size has changed, and if it has, recreate the uibox for new windowsize before next draw
  if M.lastFrameWindowSizeX ~= M.thisFrameWindowSizeX or M.lastFrameWindowSizeY ~= M.thisFrameWindowSizeY then
    for i,box in pairs(M.uiBoxList) do
      box:create()
    end
  end
end

return M
-- vim: foldmethod=marker
