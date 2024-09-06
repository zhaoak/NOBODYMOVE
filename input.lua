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
M.gamepadTriggerActivationThreshold = 0.25

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
  shootFG4 = 4,
  shootFG5 = 5,
  shootFG6 = nil,
  shootFG7 = nil,
  shootFG8 = nil,
  reset = 'r',
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
  reset = "y"
}

-- Table for tracking state of each "shoot firegroup X" input each update, regardless of what it's bound to.
-- Why use this table and not just `getShootDown()`? Because `getShootDown()` only returns a bool for a bind being pressed/not pressed,
-- and we want guns to be able to respond to multiple types of _input events_ on a binary button,
-- not just binary shooting/not shooting inputs.
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
    fakeAimX = fakeAimX + ((fakeAimAngleCacheX or M.gamepadAxisValue("rightx", 1)) * 4)
    fakeAimY = fakeAimY + ((fakeAimAngleCacheY or M.gamepadAxisValue("righty", 1)) * 4)
    return fakeAimX, fakeAimY
  else
    -- if mouseaim not disabled, just use mouse position
    return camera.getCameraRelativeMousePos()
  end
end
-- }}}

-- Update functions {{{
-- Update shoot bind states, this function is called each update
-- See `M.shootButtonStates` at the top of this file for definitions of each state
M.updateShootBindStates = function ()
  for i,shootBindVal in pairs(M.shootButtonStates) do
    if shootBindVal == "pressed" and (M.keyDown(i) or M.gamepadButtonDown(i, 1)) then
      M.shootButtonStates[i] = "held"
    elseif shootBindVal == "released" and not (M.keyDown(i) or M.gamepadButtonDown(i, 1)) then
      M.shootButtonStates[i] = "notheld"
    end
  end
end

-- Update everything in input that needs to be updated every tick
M.update = function ()
  print(M.shootButtonStates["shootFG1"])
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
    return love.keyboard.isDown(M.kbMouseBinds[bind])
  else
    return love.mouse.isDown(M.kbMouseBinds[bind])
  end
end

-- check if a specific game input is down for a specific player
-- the gamepad analog triggers are also treated as binary on/off buttons,
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
end

-- on any keyboard keypress
function love.keypressed(key)
  for i,_ in pairs(M.shootButtonStates) do
    -- if the pressed key is bound to a shoot input...
    if key == M.kbMouseBinds[i] then
      -- update its corresponding state
      M.shootButtonStates[i] = "pressed"
    end
  end
end

-- on any keyboard key release
function love.keyreleased(key)
  -- update shoot input state
  for i,_ in pairs(M.shootButtonStates) do
    if key == M.kbMouseBinds[i] then
      M.shootButtonStates[i] = "released"
    end
  end
end

-- on any mouse button click event
function love.mousepressed(x, y, button)
  -- update shoot input event state
  for i,_ in pairs(M.shootButtonStates) do
    if button == M.kbMouseBinds[i] then
      M.shootButtonStates[i] = "pressed"
    end
  end
end

-- on any mouse button release event
function love.mousereleased(x, y, button)
  -- update shoot input event state
  for i,_ in pairs(M.shootButtonStates) do
    if button == M.kbMouseBinds[i] then
      M.shootButtonStates[i] = "released"
    end
  end
end

-- on any gamepad button press
function love.gamepadpressed(joystick, button)
  -- update shoot input event state
  for i,_ in pairs(M.shootButtonStates) do
    if button == M.gamepadButtonBinds[i] then
      M.shootButtonStates[i] = "pressed"
    end
  end
end

-- on any gamepad button release
function love.gamepadreleased(joystick, button)
  -- update shoot input event state
  for i,_ in pairs(M.shootButtonStates) do
    if button == M.gamepadButtonBinds[i] then
      M.shootButtonStates[i] = "released"
    end
  end
end

-- on any change in a gamepad axis value
-- An axis value is any gamepad input that returns an analog input rather than binary
-- See here for more info:
-- https://www.love2d.org/wiki/GamepadAxis
function love.gamepadaxis(joystick, axis, value)
  -- if player moves the right stick, disable mouseaim
  if axis == "rightx" or axis == "righty" then M.mouseAimDisabled = true end
  -- update shoot input event state based on how much the triggers are pulled back, but...
  for i,shootButtonState in pairs(M.shootButtonStates) do
    -- we need to be selective about whether to update state or not, based on current state
    if axis == M.gamepadButtonBinds[i] and value > M.gamepadTriggerActivationThreshold and (shootButtonState == "notheld" or shootButtonState == "released") then
      M.shootButtonStates[i] = "pressed"
    -- because with an analog input, if we don't track changes in state,
    -- we can't tell whether a greater-than-threshold value means the player has just now pulled trigger vs
    -- holding down the trigger
    elseif axis == M.gamepadButtonBinds[i] and value < M.gamepadTriggerActivationThreshold and (shootButtonState == "pressed" or shootButtonState == "held") then
      M.shootButtonStates[i] = "released"
    end
  end
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
