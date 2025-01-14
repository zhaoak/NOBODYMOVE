-- Module for making UI windows that render above ingame graphics and can be interactable.
-- Windows are responsible for resizing in response to window size changes.
-- They also can have callbacks for specific input interactions (assuming the `interactable` flag is set.)

local M = {}

-- defines {{{
M.thisFrameGameResolutionX = 800
M.thisFrameGameResolutionY = 600
M.lastFrameGameResolutionX = 800
M.lastFrameGameResolutionY = 600
-- }}}

M.uiWindowList = {} -- table holding data for every UiWindow curently rendered onscreen, keyed by name

-- create a new uiWindow
-- if the UiWindow with the specified key 'name' already exists, it gets overwritten by the newly created one
-- args:
-- originX(num): x-coordinate of top left corner of window
-- originY(num): y-coordinate of top left corner of window
-- width(num): width in pixels of the window
-- height(num): height in pixels of the window
-- name(string): non-player visible name for the UI window, used as key in M.uiWindowList
-- createFunc(func): function to call to recreate window when window size changes
-- drawFunc(func): a function to call to draw the contents of the window
-- onClick(func): a callback function triggered when player clicks on the UiWindow
-- shouldRender(bool): whether window should render this frame: may be changed anytime
-- interactable(bool): whether player can click on, navigate with gamepad or otherwise interact with the window
M.create = function(originX, originY, width, height, name, createFunc, drawFunc, shouldRender, interactable)
  local newUiWindow = {}
  newUiWindow.shouldRender = shouldRender -- whether the window should render this frame
  newUiWindow.interactable = interactable -- whether the window should listen and respond to kb/mouse/controller inputs
  newUiWindow.borderColor = {1, 1, 1, 1} -- table containing RGBA value for color of window border
  newUiWindow.originX = originX
  newUiWindow.originY = originY
  newUiWindow.width = width
  newUiWindow.height = height
  newUiWindow.name = name
  newUiWindow.create = createFunc
  newUiWindow.draw = drawFunc
  -- `children` is a table of additional UiWindows that are contained within this UiWindow;
  -- think of them like selectable list items contained within a parent UiWindow,
  -- where each child can have children of its own.
  newUiWindow.children = {}
  M.uiWindowList[name] = newUiWindow
end

M.destroy = function(uiWindowUid)
  table.remove(M.uiWindowList, uiWindowUid)
end

M.update = function (dt)
  -- cache last frame's and the current frame's window size
  M.lastFrameWindowSizeX, M.lastFrameWindowSizeY = M.thisFrameGameResolutionX, M.thisFrameGameResolutionY
  M.thisFrameGameResolutionX, M.thisFrameGameResolutionY = love.graphics.getDimensions()

  -- check if the window size has changed, and if it has, recreate the uiwindow for new windowsize before next draw
  if M.lastFrameWindowSizeX ~= M.thisFrameGameResolutionX or M.lastFrameWindowSizeY ~= M.thisFrameGameResolutionY then
    for i,window in pairs(M.uiWindowList) do
      window:create()
    end
  end
end

return M
-- vim: foldmethod=marker
