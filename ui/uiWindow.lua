-- Module for making UI windows that render above ingame graphics and can contain interactable elements.
-- Examples of uiWindows include: the pause menu, HUD health display, and gun status HUD display.
-- Windows are responsible for resizing in response to window size changes.

local M = {}

local util = require'util'
local elements = require'ui.uiElements'
local input = require'input'

-- defines {{{
M.thisFrameGameResolutionX = 800
M.thisFrameGameResolutionY = 600
M.lastFrameGameResolutionX = 800
M.lastFrameGameResolutionY = 600
M.uiScale = 1 -- scaling factor to use for all uiWindows; 1 is normal size
-- }}}

M.uiInputCooldownPeriod = 0.20
M.uiInputCooldownTimer = 0

M.uiWindowList = {} -- list with data for every uiWindow created, keyed by UID

-- create a new uiWindow and add it to the tracked list of uiWindows
--
-- args:
-- originXTarget(num): accepts values of 0-1, representing at what point along parent's width to place origin
-- originYTarget(num): same as above, but for height value of parent
-- widthTarget(num): percentage of parent's width this window should take up
-- heightTarget(num): percentege of parent's height this window should take up
-- name(string): non-player visible name for the UI window, for programmer use
-- drawFunc(func): rendering function for uiWindow from `gameUi.lua` 
-- onClick(func): a callback function triggered when player clicks on the UiWindow
-- shouldRender(bool): whether window should render this frame: may be changed anytime
-- interactable(bool): whether window will run activation callbacks on click/controller activation input
-- selectable(bool): whether window can be highlighted and navigated to via controller inputs from parent window

--
-- returns: UID for newly created window
M.new = function(originXTarget, originYTarget, widthTarget, heightTarget, name, drawFunc, shouldRender, interactable, selectable)
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
  newUiWindow.parentWindowUid = -1 -- default to no parent; use addItem() to change this
  newUiWindow.selectable = selectable or false
  newUiWindow.selected = nil
  newUiWindow.navigating = false
  newUiWindow.onInput = {}
  newUiWindow.onInput.primary = function()
    M.setNavigating(newUiWindow.windowUid)
  end
  newUiWindow.onInput.cancel = function()
    if newUiWindow.parentWindowUid == -1 then return end
    if M.uiWindowList[newUiWindow.parentWindowUid].interactable == true then
      M.setNavigating(newUiWindow.parentWindowUid)
    else
      return
    end
  end
  newUiWindow.name = name
  newUiWindow.draw = drawFunc
  -- `contains` contains all ui elements (defined in `uiElements.lua`) within the window
  newUiWindow.contains = {}
  newUiWindow.windowUid = util.gen_uid("uiWindows")
  M.uiWindowList[newUiWindow.windowUid] = newUiWindow
  return newUiWindow.windowUid
end

-- Returns the UID of the window that currently has `navigating` set to true.
-- There should only be one window with that property set to true at a time.
-- If no window is currently navigable, return -1.
M.getNavigating = function()
  for i, window in ipairs(M.uiWindowList) do
    if window.navigating == true then return i end
  end
  return -1
end

-- Sets a specific window as the currently-navigated window, specified by UID,
-- then selects the first selectable child from its `contains` list.
-- Also sets all windows to navigating=false beforehand, so only one window is navigable at once.
-- If given -1 as the UID arg, unsets `navigating` for all windows.
M.setNavigating = function(windowUid)
  -- unset focus on all other windows
  for _, window in ipairs(M.uiWindowList) do
    window.navigating = false
  end
  if windowUid == -1 then return end -- if arg is -1, we're done here
  -- set specified window as currently navigated window
  local thisWindow = M.uiWindowList[windowUid]
  thisWindow.navigating = true
  -- select first selectable child from list of children as a default,
  -- but only if a previous value isn't already present
  if #thisWindow.contains == 0 or thisWindow.selected ~= nil then return end
  for childIndex, child in ipairs(thisWindow.contains) do
    if child.selectable == true then 
      thisWindow.selected = childIndex
      return
    end
  end
end

-- Given the UID of a window or element,
-- moves UI navigation "up" one level (to the item's parent)
-- If both args are given, uses the windowUid and not elementUid.
M.navToParent = function(windowUid, elementUid)
  -- if item is window
  if windowUid then
    local currentWindow = M.uiWindowList[windowUid]
    -- if currentWindow is parentless, do nothing
    if currentWindow.parentWindowUid == -1 then return end
    local parentWindow = M.uiWindowList[currentWindow.parentWindowUid]
    -- ensure the window you want to select is selectable
    if parentWindow.interactable == true and parentWindow.selectable == true then
      -- if grandparent of currentWindow is parentless, do nothing
      if parentWindow.parentWindowUid == -1 then return end
      M.setNavigating(parentWindow.parentWindowUid)
    end
  else
    -- if item is element
    local currentElement = elements.uiElementList[elementUid]
    if currentElement.parentWindowUid == -1 then M.setNavigating(-1) end
    local parentWindow = M.uiWindowList[currentElement.parentWindowUid]
    if parentWindow.interactable == true and parentWindow.selectable == true then
      if parentWindow.parentWindowUid == -1 then M.setNavigating(-1); return end
      M.setNavigating(parentWindow.parentWindowUid)
    end
  end
end

-- Given a parent window's UID,
-- selects the next selectable child in the window's `contains` list of child items.
-- If last selectable child in list is selected, selects the first selectable child.
-- If no selectable children can be found, does nothing.
M.selectNextChild = function(parentUid)
  local thisWindow = M.uiWindowList[parentUid]
  local firstSelectableChildIndex = nil
  for i, child in ipairs(thisWindow.contains) do
    -- find first selectable child, cache its index
    if firstSelectableChildIndex == nil and child.selectable == true then
      firstSelectableChildIndex = i
    end
    -- find the next selectable child item farther down the list, set it as selected if found
    if thisWindow.selected < i and child.selectable == true then
      thisWindow.selected = i
      return
    end
  end
  -- if we couldn't find a selectable child farther down the list, select the first child in list instead
  if firstSelectableChildIndex ~= nil then
    thisWindow.selected = firstSelectableChildIndex
    return
  end
  -- ...and if there aren't any selectable children in the list at all, do nothing
end

-- Given a parent window's UID,
-- selects the previous selectable child in the window's `contains` list of child items.
-- If first selectable child in list is selected, selects the last selectable child.
-- If no selectable children can be found, does nothing.
M.selectPrevChild = function(parentUid)
  local thisWindow = M.uiWindowList[parentUid]
  local lastSelectableChildIndex, prevSelectableChildIndex = nil, nil

  -- iterate through children, find the last selectable child,
  -- and first selectable child before currently selected child, if it exists
  for i, child in ipairs(thisWindow.contains) do
    -- find last selectable child, if it exists
    if child.selectable == true then
      lastSelectableChildIndex = i
    end
    -- find previous selectable child, if it exists
    if child.selectable == true and i < thisWindow.selected then
      prevSelectableChildIndex = i
    end
  end

  -- if a previous selectable child exists, select it and return
  if prevSelectableChildIndex ~= nil then
    thisWindow.selected = prevSelectableChildIndex
    return
  end
  -- if no previous selectable child exists, select the last child in the list
  if prevSelectableChildIndex == nil and lastSelectableChildIndex ~= nil then
    thisWindow.selected = lastSelectableChildIndex
    return
  end
  -- if neither exist, do nothing
end

-- Add an element or window to a window's `contains` list. The window will render the element each frame,
-- as well as dynamically resize and reposition it.
M.addItem = function(uiWindowUid, item)
  table.insert(M.uiWindowList[uiWindowUid].contains, item)
  -- if adding a window as a child...
  if item.windowUid ~= nil then
    M.uiWindowList[item.windowUid].parentWindowUid = uiWindowUid
    -- add "back" callback for UI navigation
    if item.onInput == nil then item.onInput = {} end
    item.onInput.cancel = function() M.navToParent(item.windowUid, nil) end
  end
  -- if adding an element as a child...
  if item.elementUid ~= nil then
    elements.uiElementList[item.elementUid].parentWindowUid = uiWindowUid
    -- add "back" callback for UI navigation
    if item.onInput == nil then item.onInput = {} end
    item.onInput.cancel = function() M.navToParent(nil, item.elementUid) end
  end
end

-- Given the UID of a currently-navigable uiWindow,
-- draw the border indicating a selected item around the currently-selected child.
M.drawSelectionBorder = function(parentWindowUid)
  local thisParent = M.uiWindowList[parentWindowUid]
  for i, child in ipairs(thisParent.contains) do
    if i == thisParent.selected and thisParent.navigating == true then
      local colorCacheR,colorCacheG,colorCacheB,colorCacheA = love.graphics.getColor()
      love.graphics.setColor(1, 0, 0, 0.8)
      love.graphics.rectangle("line", child.originX, child.originY, child.width, child.height, 5, 5, 5)
      love.graphics.setColor(colorCacheR, colorCacheG, colorCacheB, colorCacheA)
    end
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

-- Recursive function used to toggle 
local function renderToggleRecurse(item, newValue)
  item.shouldRender = newValue
  -- if item is a window, it could have children to toggle, so do so 
  if item.windowUid ~= nil then
    for _, child in ipairs(item.contains) do
      renderToggleRecurse(child, newValue)
    end
  end
  -- otherwise, it's an element, and elements can't have children
  -- thus the recursion ends here
end

-- Toggles a window's `shouldRender` property, given its UID.
-- Also sets all the window's children, both direct and indirect, to match its `shouldRender` state.
M.toggleRendering = function(windowUid)
  local thisWindow = M.uiWindowList[windowUid]
  local newValue = not thisWindow.shouldRender
  renderToggleRecurse(thisWindow, newValue)
end

-- Recursive function used to toggle a window and all its children,
-- both direct and indirect, as interactable
local function interactableToggleRecurse(item, newValue)
  item.interactable = newValue
  -- if item is a window, it could have children to toggle, so do so 
  if item.windowUid ~= nil then
    for _, child in ipairs(item.contains) do
      interactableToggleRecurse(child, newValue)
    end
  end
  -- otherwise, it's an element, and elements can't have children
  -- thus the recursion ends here
end

-- Toggles a window's `interactable` property, given its UID,
-- plus the same property for all the window's children,
-- both direct and indirect
M.toggleInteractable = function(windowUid)
  local thisWindow = M.uiWindowList[windowUid]
  local newValue = not thisWindow.interactable
  interactableToggleRecurse(thisWindow, newValue)
end

-- Given the location of the mouse and the input pressed, calls the clicked-on thing's appropriate callback.
M.handleKBMUiInput = function(mouseX, mouseY, button)
  -- check through elements, see if any are set to interactable
  for _, element in ipairs(elements.uiElementList) do
    if element.interactable == true and element.onInput ~= nil then
      -- check if input was on the currently-interactable element
      if mouseX >= element.originX and mouseX <= (element.originX + element.width) and
         mouseY >= element.originY and mouseY <= (element.originY + element.height) then
        -- then, call the callback function associated with the input pressed
        if button == input.kbMouseBinds.uiActionPrimary then
          if element.onInput.primary ~= nil then element.onInput.primary() end
        end
        if button == input.kbMouseBinds.uiActionSecondary then
          if element.onInput.secondary ~= nil then element.onInput.secondary() end
        end
        if button == input.kbMouseBinds.uiActionTertiary then
          if element.onInput.tertiary ~= nil then element.onInput.tertiary() end
        end
        if button == input.kbMouseBinds.uiActionCancel then
          if element.onInput.cancel ~= nil then element.onInput.cancel() end
        end
      end
    end
  end

  -- reset input cooldown timer
  M.uiInputCooldownTimer = M.uiInputCooldownPeriod

  -- Note that we don't bother checking windows--
  -- uiWindows are for navigation via controller and holding elements,
  -- not being UI elements in their own right
end

M.handleGamepadUiInput = function(navigatingWindowUid, button)
  local navigatedWindow = M.uiWindowList[navigatingWindowUid]
  local selectedElement = navigatedWindow.contains[navigatedWindow.selected]
  if selectedElement == nil then return end
  if button == input.gamepadButtonBinds.uiNavUp then
    M.selectPrevChild(navigatingWindowUid)
  elseif button == input.gamepadButtonBinds.uiNavDown then
    M.selectNextChild(navigatingWindowUid)
  elseif button == input.gamepadButtonBinds.uiNavLeft then
    -- nav left action
  elseif button == input.gamepadButtonBinds.uiNavRight then
    -- nav right action
  elseif button == input.gamepadButtonBinds.uiActionPrimary then
    if selectedElement.onInput.primary ~= nil then selectedElement.onInput.primary() end
  elseif button == input.gamepadButtonBinds.uiActionSecondary then
    if selectedElement.onInput.secondary ~= nil then selectedElement.onInput.secondary() end
  elseif button == input.gamepadButtonBinds.uiActionTertiary then
    if selectedElement.onInput.tertiary ~= nil then selectedElement.onInput.tertiary() end
  elseif button == input.gamepadButtonBinds.uiActionCancel then
    if selectedElement.onInput.cancel ~= nil then selectedElement.onInput.cancel() end
  end

  -- reset input cooldown timer
  M.uiInputCooldownTimer = M.uiInputCooldownPeriod
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
M.resizeAll = function()
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
      M.resizeAll()
  end

  -- get currently-navigating uiWindow's UID
  local navigatingWindowUid = M.getNavigating()

  -- listen for player input on windows or elements,
  -- but only if it's been a short period since the last ui input
  -- keyboard+mouse
  if M.uiInputCooldownTimer < 0 and navigatingWindowUid ~= -1 then
    if input.keyDown("uiActionPrimary") then
      M.handleKBMUiInput(love.mouse.getX(), love.mouse.getY(), input.kbMouseBinds.uiActionPrimary)
    elseif input.keyDown("uiActionSecondary") then
      M.handleKBMUiInput(love.mouse.getX(), love.mouse.getY(), input.kbMouseBinds.uiActionSecondary)
    elseif input.keyDown("uiActionTertiary") then
      M.handleKBMUiInput(love.mouse.getX(), love.mouse.getY(), input.kbMouseBinds.uiActionTertiary)
    elseif input.keyDown("uiActionCancel") then
      M.handleKBMUiInput(love.mouse.getX(), love.mouse.getY(), input.kbMouseBinds.uiActionCancel)
    end

    -- gamepad
    if input.gamepadButtonDown("uiNavUp", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiNavUp)
    elseif input.gamepadButtonDown("uiNavDown", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiNavDown)
    elseif input.gamepadButtonDown("uiNavLeft", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiNavLeft)
    elseif input.gamepadButtonDown("uiNavRight", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiNavRight)
    elseif input.gamepadButtonDown("uiActionPrimary", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiActionPrimary)
    elseif input.gamepadButtonDown("uiActionSecondary", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiActionSecondary)
    elseif input.gamepadButtonDown("uiActionTertiary", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiActionTertiary)
    elseif input.gamepadButtonDown("uiActionCancel", 1) then
      M.handleGamepadUiInput(navigatingWindowUid, input.gamepadButtonBinds.uiActionCancel)
    end
  end

  -- decrement ui input anti-spam timer
  M.uiInputCooldownTimer = M.uiInputCooldownTimer - dt
end

return M
-- vim: foldmethod=marker
