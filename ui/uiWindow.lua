-- Module for making UI windows that render above ingame graphics and can contain interactable elements.
-- Examples of uiWindows include: the pause menu, HUD health display, and gun status HUD display.
-- Windows are responsible for resizing in response to window size changes.

local M = {}

local util = require'util'
local elements = require'ui.uiElements'

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
-- drawFunc(func): rendering function for uiWindow from `gameUi.lua` 
-- onClick(func): a callback function triggered when player clicks on the UiWindow
-- shouldRender(bool): whether window should render this frame: may be changed anytime
-- interactable(bool): whether player can click on, navigate with gamepad or otherwise interact with the window
--
-- returns: UID for newly created window
M.new = function(originXTarget, originYTarget, widthTarget, heightTarget, name, drawFunc, shouldRender, interactable)
  local newUiWindow = {}
  newUiWindow.shouldRender = shouldRender or false -- whether the window should render this frame
  newUiWindow.interactable = interactable or false -- whether the window should listen and respond to kb/mouse/controller inputs
  newUiWindow.scrollable = false -- whether the window's contents should be scrollable vertically
  newUiWindow.currentScrollOffset = 0 -- how many pixels down the window's contents are currently scrolled
  newUiWindow.borderColor = {1, 1, 1, 1} -- table containing RGBA value for color of window border
  newUiWindow.originXTarget = originXTarget
  newUiWindow.originYTarget = originYTarget
  newUiWindow.widthTarget = widthTarget
  newUiWindow.heightTarget = heightTarget
  -- newUiWindow.originX = originX
  -- newUiWindow.originY = originY
  -- newUiWindow.width = width
  -- newUiWindow.height = height
  newUiWindow.parentWindowUid = -1 -- default to no parent; use addItem() to change this
  newUiWindow.name = name
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
  -- if adding a window as a child...
  if item.windowUid ~= nil then
    M.uiWindowList[item.windowUid].parentWindowUid = uiWindowUid
  end
  -- if adding an element as a child...
  --
end

-- Call the draw functions of each element or window in the window's `contains` table.
M.drawChildren = function(uiWindowUid)
  for i,child in pairs(M.uiWindowList[uiWindowUid].contains) do
    child.drawFunc()
  end
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

-- Gets the originX, originY, width, and height values for a given window, specified by window UID.
-- If given -1 as a UID, returns 0 for originX/originY and the current screen dimensions for width/height.
-- (-1 is the value used to specify that a window has no parent.)
M.getWindowDimensions = function(windowUid)
  if windowUid == -1 then
    return 0, 0, M.thisFrameGameResolutionX, M.thisFrameGameResolutionY
  else
    return M.uiWindowList[windowUid].originX, M.uiWindowList[windowUid].originY, M.uiWindowList[windowUid].width, M.uiWindowList[windowUid].height
  end
end

M.destroy = function(uiWindowUid)
  table.remove(M.uiWindowList, uiWindowUid)
end

-- Resize a single window, identified by its UID.
-- Uses the parent's dimension values to calculate the specified window's size and position.
-- This means that parent windows must be resized before their children.
-- If the window has no parent (a parentWindowUid value of -1),
-- this function uses the current screen resolution and 0,0 as values.
M.resizeWindow = function(uiWindowUid)
  local thisWindow = M.uiWindowList[uiWindowUid]
  if thisWindow.parentWindowUid == -1 then
    -- if window has no parent, base on game resolution
    thisWindow.originX = thisWindow.originXTarget* M.thisFrameGameResolutionX
    thisWindow.originY = thisWindow.originYTarget * M.thisFrameGameResolutionY
    thisWindow.width = thisWindow.widthTarget * M.thisFrameGameResolutionX
    thisWindow.height = thisWindow.heightTarget * M.thisFrameGameResolutionY
  else
    -- otherwise, use the parent window's values
    local parentX, parentY, parentWidth, parentHeight = M.getWindowDimensions(thisWindow.parentWindowUid)
    thisWindow.originX = parentX + (thisWindow.originXTarget*parentWidth)
    thisWindow.originY = parentY + (thisWindow.originYTarget*parentHeight)
    thisWindow.width = parentWidth * thisWindow.widthTarget
    thisWindow.height = parentHeight * thisWindow.heightTarget
  end
end

-- Resize all windows and elements in response to the game's output resolution changing.
M.resizeAll = function(newResX, newResY)
  -- Starting with windows that are parentless, adjust their dimensions to fit the new resolution.
  -- Then, check the children of those parentless windows and update their dimensions,
  -- since the children's dimensions depend on the parent's dimensions.
  -- Then do the children's children, and so on, until all items have been resized.
  local windowsToResize = util.shallowCopyTable(M.uiWindowList)
  local parentExaminationQueue = {-1}

  while #windowsToResize > 0 do
    for uid, window in ipairs(M.uiWindowList) do
      if window.parentWindowUid == parentExaminationQueue[1] then
        M.resizeWindow(uid)
        table.remove(windowsToResize, 1)
        table.insert(parentExaminationQueue, uid)
      end
    end
    table.remove(parentExaminationQueue, 1)
  end

  -- once all the windows are resized, elements can be safely batch-resized
  -- (since elements can be children of windows, but not vice versa)
  for _, element in ipairs(elements.uiElementList) do
    if element.parentWindowUid == -1 then
      -- if element has no parent, base on game resolution
      element.originX = element.originXTarget * M.thisFrameGameResolutionX
      element.originY = element.originYTarget * M.thisFrameGameResolutionY
      element.width = element.widthTarget * M.thisFrameGameResolutionX
      element.height = element.heightTarget * M.thisFrameGameResolutionY
    else
      -- otherwise, use the parent window's values
      local parentX, parentY, parentWidth, parentHeight = M.getWindowDimensions(element.parentWindowUid)
      element.originX = parentX + (element.originXTarget*parentWidth)
      element.originY = parentY + (element.originYTarget*parentHeight)
      element.width = parentWidth * element.widthTarget
      element.height = parentHeight * element.heightTarget
    end
  end
end

M.update = function (dt)
  -- cache last frame's and the current frame's window size
  M.lastFrameWindowSizeX, M.lastFrameWindowSizeY = M.thisFrameGameResolutionX, M.thisFrameGameResolutionY
  M.thisFrameGameResolutionX, M.thisFrameGameResolutionY = love.graphics.getDimensions()

  -- check if the window size has changed, and if it has, resize all windows for new resolution before next draw
  if M.lastFrameWindowSizeX ~= M.thisFrameGameResolutionX or M.lastFrameWindowSizeY ~= M.thisFrameGameResolutionY then
      M.resizeAll(M.thisFrameGameResolutionX, M.thisFrameGameResolutionY)
  end

  -- 
end

return M
-- vim: foldmethod=marker
