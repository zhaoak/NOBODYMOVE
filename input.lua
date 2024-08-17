local M = {}
local camera = require'camera'

-- Table holding this tick's axis/trigger values
M.gamepadAxisTriggerValues = {
  leftStickX = 0,
  leftStickY = 0,
  rightStickX = 0,
  rightStickY = 0,
  leftTrigger = -1,
  rightTrigger = -1
}

-- Table contining currently connected controllers
M.connectedControllers = {
  player1Joy = nil,
  player2Joy = nil
}

-- File for handling keyboard and gamepad inputs and translating them into game inputs.
M.kbMouseBinds = {
  up = 'w',
  down = 's',
  left = 'a',
  right = 'd',
  ragdoll = "space",
  shoot = 1,
  reset = 2,
}

-- Same, but for gamepad buttons.
M.gamepadButtonBinds = {
  ragdoll = "leftstick",
  shoot = "rightshoulder",
  reset = "y"
}

-- input-device-specific input checks {{{
-- check if a mouse button or keyboard key is down
M.keyDown = function (bind)
  if type(M.kbMouseBinds[bind]) == "string" then
    return love.keyboard.isDown(M.kbMouseBinds[bind])
  else
    return love.mouse.isDown(M.kbMouseBinds[bind])
  end
end

-- check if a gamepad button is down
M.gamepadButtonDown = function (bind, joystick)
  if joystick == nil then return false end
  return joystick:isGamepadDown(M.gamepadButtonBinds[bind])
end
-- }}}

-- Game input check functions {{{
-- get if shoot input is currently down
M.getShootDown = function()
  if M.keyDown("shoot") or M.gamepadButtonDown("shoot", M.connectedControllers.player1Joy) then
    return true
  else
    return false
  end
end

-- get if ragdoll input is currently down
M.getRagdollDown = function()
  if M.keyDown("ragdoll") or M.gamepadButtonDown("ragdoll", M.connectedControllers.player1Joy) then
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
  else
    -- if no kb+mouse X-axis movement input, use controller value
    return M.gamepadAxisTriggerValues.leftStickX
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
  else
    -- if no kb+mouse Y-axis movement input, use controller value
    return M.gamepadAxisTriggerValues.leftStickY
  end
end
-- }}}

-- mous for now, add controller later
M.getCrossHair = function ()
  return camera.getCameraRelativeMousePos()
end

-- get current gamepad stick values
M.updateGamepadAxisTriggerInputs = function (joystick)
  local lStickX, lStickY, lTrigger, rStickX, rStickY, rTrigger = joystick:getAxes()
  M.gamepadAxisTriggerValues.leftStickX = lStickX or 0
  M.gamepadAxisTriggerValues.leftStickY = lStickY or 0
  M.gamepadAxisTriggerValues.rightStickX = rStickX or 0
  M.gamepadAxisTriggerValues.rightStickY = rStickY or 0
  M.gamepadAxisTriggerValues.leftTrigger = lTrigger or -1
  M.gamepadAxisTriggerValues.rightTrigger = rTrigger or -1
end

-- input callback functions {{{
-- gamepad
function love.gamepadpressed(joystick, button)
  -- printCurrentJoystickInputs(joystick)
  printGamepadButtonInputs(joystick, button)
  -- joystick:setVibration(1, 1) -- vrrrrrr
end

-- gamepad connected/present on application start
function love.joystickadded(joystick)
  if M.connectedControllers.player1Joy == nil then
    M.connectedControllers.player1Joy = joystick
  end
end
-- }}}

-- debug functions {{{
function printCurrentJoystickInputs(joystick)
  print("lstick X / lstick Y / ltrigger / rightstick x / rightstick y / righttrigger")
  print(M.gamepadAxisTriggerValues.leftStickX.." / "..M.gamepadAxisTriggerValues.leftStickY.." / "..M.gamepadAxisTriggerValues.leftTrigger.." / "..M.gamepadAxisTriggerValues.rightStickX.." / "..M.gamepadAxisTriggerValues.rightStickY.." / "..M.gamepadAxisTriggerValues.rightTrigger)
end

function printGamepadButtonInputs(joystick, button)
  print("button: "..button)
end
-- }}}

return M
-- vim: foldmethod=marker
