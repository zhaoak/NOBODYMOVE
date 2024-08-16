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



-- check if a mouse button or keyboard key is down
M.keyDown = function (bind)
  if type(M.kbMouseBinds[bind]) == "string" then
    return love.keyboard.isDown(M.kbMouseBinds[bind])
  else
    return love.mouse.isDown(M.kbMouseBinds[bind])
  end
end

-- check if a gamepad button is down
M.gamepadButtonDown = function (bind)
  return love.joystick:isDown(M.gamepadButtonBinds[bind])
end

-- get current gamepad stick values

-- mous for now, add controller later
M.getCrossHair = function ()
  return camera.getCameraRelativeMousePos()
end

M.updateGamepadAxisTriggerInputs = function ()
  local lStickX, lStickY, lTrigger, rStickX, rStickY, rTrigger = joystick:getAxes()
  M.gamepadAxisTriggerValues.leftStickX = lStickX
  M.gamepadAxisTriggerValues.leftStickY = lStickY
  M.gamepadAxisTriggerValues.rightStickX = rStickX
  M.gamepadAxisTriggerValues.rightStickY = rStickY
  M.gamepadAxisTriggerValues.leftTrigger = lTrigger
  M.gamepadAxisTriggerValues.leftStickX = rTrigger
end

-- input callback functions {{{
-- gamepad
function love.gamepadpressed(joystick, button)
  printJoystickInputs(joystick)
  printGamepadButtonInputs(joystick, button)
  -- joystick:setVibration(0.3, 0.5) vrrrrrr
end
-- }}}

-- debug functions {{{
function printJoystickInputs(joystick)
  local lStickX, lStickY, lTrigger, rStickX, rStickY, rTrigger = joystick:getAxes()
  print("lstick X / lstick Y / ltrigger / rightstick x / rightstick y / righttrigger")
  print(lStickX.." / "..lStickY.." / "..lTrigger.." / "..rStickX.." / "..rStickY.." / "..rTrigger)
end

function printGamepadButtonInputs(joystick, button)
  print("button: "..button)
end
-- }}}

return M
