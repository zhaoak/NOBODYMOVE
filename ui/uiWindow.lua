-- Module for making UI windows that render above ingame graphics and can contain interactable elements.
-- Examples of uiWindows include: the pause menu, HUD health display, and gun status HUD display.
-- Windows are responsible for resizing in response to window size changes.

local M = {}

local util = require'util'

-- defines {{{
M.thisFrameGameResolutionX = 800
M.thisFrameGameResolutionY = 600
M.lastFrameGameResolutionX = 800
M.lastFrameGameResolutionY = 600
M.uiScale = 1 -- scaling factor to use for all uiWindows; 1 is normal size
-- }}}

M.uiWindowList = {} -- list with data for every uiWindow created, keyed by UID

-- create a new uiWindow and add it to the tracked list of uiWindows
--
-- args:
-- originX(num): x-coordinate of top left corner of window
-- originY(num): y-coordinate of top left corner of window
-- width(num): width in pixels of the window
-- height(num): height in pixels of the window
-- name(string): non-player visible name for the UI window, for programmer use
-- createFunc(func): "creator" function for uiWindow from `gameUi.lua`
-- drawFunc(func): rendering function for uiWindow from `gameUi.lua` 
-- onClick(func): a callback function triggered when player clicks on the UiWindow
-- shouldRender(bool): whether window should render this frame: may be changed anytime
-- interactable(bool): whether player can click on, navigate with gamepad or otherwise interact with the window
--
-- returns: UID for newly created window
M.new = function(originX, originY, width, height, name, createFunc, drawFunc, shouldRender, interactable)
  local newUiWindow = {}
  newUiWindow.shouldRender = shouldRender or false -- whether the window should render this frame
  newUiWindow.interactable = interactable or false -- whether the window should listen and respond to kb/mouse/controller inputs
  newUiWindow.scrollable = false -- whether the window's contents should be scrollable vertically
  newUiWindow.currentScrollOffset = 0 -- how many pixels down the window's contents are currently scrolled
  newUiWindow.borderColor = {1, 1, 1, 1} -- table containing RGBA value for color of window border
  newUiWindow.originX = originX
  newUiWindow.originY = originY
  newUiWindow.width = width
  newUiWindow.height = height
  newUiWindow.name = name
  newUiWindow.create = createFunc
  newUiWindow.draw = drawFunc
  -- `contains` contains all ui elements (defined in `uiElements.lua`) within the window
  newUiWindow.contains = {}
  newUiWindow.windowUid = util.gen_uid("uiWindows")
  M.uiWindowList[newUiWindow.windowUid] = newUiWindow
  return newUiWindow.windowUid
end

-- Add an element or window to a window's `contains` list. The window will render the element each frame,
-- as well as dynamically resize and reposition it.
M.addItem = function(uiWindowUid, item)
  table.insert(M.uiWindowList[uiWindowUid].contains, item)
end

-- Call the draw functions of each element or window in the window's `contains` table.
M.drawChildren = function(uiWindowUid)
  for i,child in pairs(M.uiWindowList[uiWindowUid].contains) do
    child.drawFunc()
  end
end

-- Resize a window in response to the game's output resolution changing.
M.resize = function(uiWindowUid, scalingRatioX, scalingRatioY)
  local window = M.uiWindowList[uiWindowUid]
  -- get sizes appropriate sizes for new resolution
  local originX, originY, width, height = M.uiWindowList[uiWindowUid]:create()
  -- set window's new screen coordinates, width/height
  window.originX = originX
  window.originY = originY
  window.width = width
  window.height = height
  -- TODO: set new screen coords/width/height for elements inside window being resized

end

-- Gets a window's UID by its programmer-visible name.
M.getWindowUid = function(windowName)
  for _, v in ipairs(M.uiWindowList) do
    if v.name == windowName then return v.windowUid end
  end
end

-- Checks if a window with a given internal name exists already.
M.namedWindowExists = function(windowName)
  for _, v in ipairs(M.uiWindowList) do
    if v.name == windowName then return true end -- window exists!
  end
  return false -- window doesn't exist
end

M.destroy = function(uiWindowUid)
  table.remove(M.uiWindowList, uiWindowUid)
end

M.update = function (dt)
  -- cache last frame's and the current frame's window size
  M.lastFrameWindowSizeX, M.lastFrameWindowSizeY = M.thisFrameGameResolutionX, M.thisFrameGameResolutionY
  M.thisFrameGameResolutionX, M.thisFrameGameResolutionY = love.graphics.getDimensions()

  -- check if the window size has changed, and if it has, resize each uiwindow for new resolution before next draw
  if M.lastFrameWindowSizeX ~= M.thisFrameGameResolutionX or M.lastFrameWindowSizeY ~= M.thisFrameGameResolutionY then
    local scalingRatioX, scalingRatioY = M.thisFrameGameResolutionX/M.lastFrameWindowSizeX, M.thisFrameGameResolutionY/M.lastFrameWindowSizeY
    for i,window in ipairs(M.uiWindowList) do
      M.resize(i, scalingRatioX, scalingRatioY)
    end
  end

  -- 
end

return M
-- vim: foldmethod=marker
