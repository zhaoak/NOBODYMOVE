-- Module for handling inputs from gamepad/mouse/keyboard and translating them into game inputs.
-- Also handles gamepad connection/disconnection and storing key/button binding settings.
-- The player module uses the functions here to check what inputs are being pressed.

local M = {}
local camera = require'camera'

-- Table contining currently connected controllers
-- key is a number representing which player,
-- value is the joystick assigned to that player
M.connectedControllers = {
  [1] = nil,
  [2] = nil
}

-- since mouse position is always present, we need a way to tell when to use controller rstick vs mouse aim
M.mouseAimDisabled = false

-- joystick deadzone settings
M.movementJoystickThresholdX = 0.30
M.movementJoystickThresholdY = 0.30
M.aimJoystickThresholdX = 0.05
M.aimJoystickThresholdY = 0.05

-- hair trigger threshold settings
M.gamepadTriggerActivationThreshold = 0.1

-- counter tracking how many times the mousewheel has moved in the last frame
M.scrollDistance = 0


-- File for handling keyboard and gamepad inputs and translating them into game inputs.
M.kbMouseBinds = {
  up = 'w',
  down = 's',
  left = 'a',
  right = 'd',
  ragdoll = "space",
  shootFG1 = 1, -- "FG" is short for firegroup
  shootFG2 = 2,
  shootFG3 = 3,
  shootFG4 = nil,
  shootFG5 = nil,
  shootFG6 = nil,
  shootFG7 = nil,
  shootFG8 = nil,
  toggleGunEditMenu = "tab",
  uiActionPrimary = 1,
  uiActionSecondary = 3,
  uiActionTertiary = "lshift",
  uiActionCancel = 2,
  incSpread = 'wheelup',
  decSpread = 'wheeldown',
}

-- Same, but for gamepad buttons.
-- Note that the gamepad triggers are treated as two-state buttons,
-- even though they return floating-point axis values.
M.gamepadButtonBinds = {
  ragdoll = "leftshoulder",
  shootFG1 = "triggerleft",
  shootFG2 = "triggerright",
  shootFG3 = "rightshoulder",
  shootFG4 = nil,
  shootFG5 = nil,
  shootFG6 = nil,
  shootFG7 = nil,
  shootFG8 = nil,
  uiActionPrimary = "a",
  uiActionSecondary = "x",
  uiActionTertiary = "y",
  uiActionCancel = "b",
  toggleGunEditMenu = "back",
  reset = "y"
}

-- Table for tracking state of each "shoot firegroup X" input each update, regardless of what it's bound to.
-- Why use this table and not just `getShootDown()`? Because `getShootDown()` only returns a bool for a bind being pressed/not pressed,
-- and we want guns to be able to respond to multiple types of _input events_ on a binary button,
-- not just binary shooting/not shooting inputs.
-- Be aware that "pressed" and "held" values will only ever be active for one update per shoot input state change
-- (meaning, "onPressShoot" and "onReleaseShoot" events will only trigger once per press/release of the shoot input.)
-- This is intentional; if you want a gun to shoot continuously while its input is held, use the "onHoldShoot" event.
-- The possible values for each button are as follows:
-- "pressed": the shoot button is being pressed and was _not_ being pressed or held the previous update.
-- "held": the shoot button is being pressed and _was_ being either pressed or held the previous update.
-- "released": the shoot button is _not_ being pressed, and _was_ being pressed or held the previous update.
-- "notheld": the shoot button is _not_ being pressed, and was _not_ being pressed or held the previous update.
M.shootButtonStates = {
  shootFG1 = "notheld",
  shootFG2 = "notheld",
  shootFG3 = "notheld",
  shootFG4 = "notheld",
  shootFG5 = "notheld",
  shootFG6 = "notheld",
  shootFG7 = "notheld",
  shootFG8 = "notheld"
}

-- Game command check functions {{{
-- get if a specific shoot input is currently down
-- args:
-- `firegroup`(number): the firegroup of the shoot input you want to check, 1-8
M.getShootDown = function(firegroup)
  if M.keyDown("shootFG"..firegroup) or M.gamepadButtonDown("shootFG"..firegroup, 1) then
    return true
  else
    return false
  end
end

-- Check the event state of a specific shoot input this update
-- args:
-- firegroup(num): the firegroup of the shoot input you want to check, 1-8
M.getShootBindState = function(firegroup)
  return M.shootButtonStates["shootFG"..tostring(firegroup)]
end

-- get if ragdoll input is currently down
M.getRagdollDown = function()
  if M.keyDown("ragdoll") or M.gamepadButtonDown("ragdoll", 1) then
    return true
  else
    return false
  end
end

-- get if gun menu toggle button input is currently down
M.getGunMenuToggleDown = function()
  if M.keyDown("toggleGunEditMenu") or M.gamepadButtonDown("toggleGunEditMenu", 1) then
    return true
  else
    return false
  end
end

-- get if the player is currently trying to move on the X-axis
-- checks both kb/mouse and gamepad inputs, and returns a value from -1 to 1 for left to right
-- obviously, kb inputs will only ever return -1, 0, or 1
-- kb also always overrides gamepad
M.getMovementXAxisInput = function()
  -- if both left and right keys held, they cancel each other
  if M.keyDown("left") and M.keyDown("right") then
    return 0
  elseif M.keyDown("left") then
    return -1
  elseif M.keyDown("right") then
    return 1
  elseif M.connectedControllers[1] == nil then
    return 0
  else
    -- if no kb+mouse X-axis movement input, use controller value
    return M.gamepadAxisValue("leftx", 1)
  end
end

-- get if the player is currently trying to move on the Y-axis
-- checks both kb/mouse and gamepad inputs, and returns a value from -1 to 1 for up to down
-- obviously, kb inputs will only ever return -1, 0, or 1
-- kb also always overrides gamepad
M.getMovementYAxisInput = function()
  if M.keyDown("up") then
    return -1
  elseif M.keyDown("down") then
    return 1
  elseif M.connectedControllers[1] == nil then
    return 0
  else
    -- if no kb+mouse Y-axis movement input, use controller value
    return M.gamepadAxisValue("lefty", 1)
  end
end

local fakeAimAngleCacheX, fakeAimAngleCacheY = 1, 0
-- Returns coordinates of where the player is currently aiming with the mouse.
-- Since player distance from target doesn't affect aim, this function also handles aiming with a gamepad analog stick.
-- Aiming with analog stick is faked by simply returning mouse coords in a circle around spood body,
-- with where on the circle based on controller stick position.
-- args:
-- playerPosX(number): the player's x-coordinate in the world. Used for faking controller aim location.
-- playerPosY(number): the player's y-coordinate in the world. Used for faking controller aim location.
M.getCrossHair = function (playerPosX, playerPosY)
  if M.mouseAimDisabled then
    local fakeAimX, fakeAimY = playerPosX, playerPosY
    if M.gamepadAxisValue("rightx", 1) ~= 0 and M.gamepadAxisValue("righty", 1) ~= 0 then
      fakeAimAngleCacheX, fakeAimAngleCacheY = M.gamepadAxisValue("rightx", 1), M.gamepadAxisValue("righty", 1)
    end
    fakeAimX = fakeAimX + ((fakeAimAngleCacheX or M.gamepadAxisValue("rightx", 1)) * 1000)
    fakeAimY = fakeAimY + ((fakeAimAngleCacheY or M.gamepadAxisValue("righty", 1)) * 1000)
    return fakeAimX, fakeAimY
  else
    -- if mouseaim not disabled, just use mouse position
    return camera.getCameraRelativeMousePos()
  end
end
-- }}}

-- Update functions {{{
-- Update shoot bind states, this function is called each update
-- See `M.shootButtonStates` at the top of this file for definitions of each state,
-- and an explanation of why transitioning state from "pressed" and "released" doesn't check the shoot inputs.
M.updateShootBindStates = function ()
  for i,shootBindVal in pairs(M.shootButtonStates) do
    if shootBindVal == "pressed" then
      M.shootButtonStates[i] = "held"
    elseif shootBindVal == "released" then
      M.shootButtonStates[i] = "notheld"
    elseif shootBindVal == "held" and not (M.keyDown(i) or M.gamepadButtonDown(i, 1)) then
      M.shootButtonStates[i] = "released"
    elseif shootBindVal == "notheld" and (M.keyDown(i) or M.gamepadButtonDown(i, 1)) then
      M.shootButtonStates[i] = "pressed"
    end
  end
end


-- Update everything in input that needs to be updated every tick
M.update = function ()
  M.updateShootBindStates()
end
-- }}}

-- Input-device-specific game input checks {{{
-- check if a specific game input is down on mouse and keyboard
-- args:
-- bind(string): string representing a game input and index in `M.kbMouseBinds`
M.keyDown = function (bind)
  if M.kbMouseBinds[bind] == nil then return false end

  if type(M.kbMouseBinds[bind]) == "string" then
    -- handle scrollwheel, return a number as well as the bool
    local x = M.scrollDistance
    if M.kbMouseBinds[bind] == "wheelup" then
      if x > 0 then M.scrollDistance = 0 end -- this 'consumes' the scroll distance, so reset it
      return x > 0, x
    elseif M.kbMouseBinds[bind] == "wheeldown" then
      if x < 0 then M.scrollDistance = 0 end
      return x < 0, x
    end
    return love.keyboard.isDown(M.kbMouseBinds[bind])
  else
    return love.mouse.isDown(M.kbMouseBinds[bind])
  end
end

-- Check if a specific game input is down for a specific player.
-- The gamepad analog triggers are also treated as binary on/off buttons,
-- with the threshold between on/off determined by `M.gamepadTriggerActivationThreshold`
-- args:
-- bind(string): string representing a game input and index in `M.gamepadButtonBinds`
-- player(num): number 1-4 representing which player's gamepad to check
M.gamepadButtonDown = function (bind, player)
  if M.connectedControllers[player] == nil then return false end
  if M.gamepadButtonBinds[bind] == nil then return false end

  if M.gamepadButtonBinds[bind] == "triggerright" or M.gamepadButtonBinds[bind] == "triggerleft" then
    if M.gamepadButtonBinds[bind] == "triggerright" then
      if M.gamepadTriggerPulled("triggerright", 1) then return true else return false end
    elseif M.gamepadButtonBinds[bind] == "triggerleft" then
      if M.gamepadTriggerPulled("triggerleft", 1) then return true else return false end
    end
  else
    return M.connectedControllers[player]:isGamepadDown(M.gamepadButtonBinds[bind])
  end
end

-- check whether a gamepad trigger is pulled, as determined by the customizable threshold
M.gamepadTriggerPulled = function(triggerBind, player)
  if M.gamepadAxisValue(triggerBind, player) >= M.gamepadTriggerActivationThreshold then
    return true
  else
    return false
  end
end

-- gets the value of a specific gamepad axis
-- `axis` should be a string containing one of the constant values on this page:
-- https://www.love2d.org/wiki/Joystick:getGamepadAxis
M.gamepadAxisValue = function(axis, player)
  -- if gamepad not connected, return a value meaning "no input"
  if M.connectedControllers[player] == nil then return 0 end
  -- otherwise, get and return the value
  return M.connectedControllers[player]:getGamepadAxis(axis)
end
-- }}}

-- Input callback functions {{{
-- on gamepad connected or present on application start
function love.joystickadded(joystick)
  -- for now, autoassign to player 1
  if joystick:isGamepad() then
    if M.connectedControllers[1] == nil then
      M.connectedControllers[1] = joystick
    end
  end
end

-- on gamepad removed
function love.joystickremoved(joystick)
  -- on removal, remove joystick from table of connected controllers
  M.connectedControllers[1] = nil
end

-- on mouse movement
function love.mousemoved()
  -- if player moves mouse, assume they want to use mouseaim
  M.mouseAimDisabled = false
  love.mouse.setVisible(true)
end

-- on any keyboard keypress
function love.keypressed(key)

end

-- on any keyboard key release
function love.keyreleased(key)

end

-- on any mouse button click event
function love.mousepressed(x, y, button)

end

-- on any mouse button release event
function love.mousereleased(x, y, button)

end

-- on any gamepad button press
function love.gamepadpressed(joystick, button)

end

-- on any gamepad button release
function love.gamepadreleased(joystick, button)

end

-- on any change in a gamepad axis value
-- An axis value is any gamepad input that returns an analog input rather than binary
-- See here for more info:
-- https://www.love2d.org/wiki/GamepadAxis
function love.gamepadaxis(joystick, axis, value)
  -- if player moves the right stick, disable mouseaim
  if axis == "rightx" or axis == "righty" then M.mouseAimDisabled = true end
  love.mouse.setVisible(false)
end

-- bind mousewheel callback
love.wheelmoved = function (_,y)
  M.scrollDistance = M.scrollDistance + y
end
-- }}}

-- Debug functions {{{
function printCurrentJoystickInputs(joystick)
  print("lstick X / lstick Y / ltrigger / rightstick x / rightstick y / rtrigger")
end

function printGamepadButtonInputs(joystick, button)
  print("button: "..button)
end
-- }}}

return M
-- vim: foldmethod=marker
