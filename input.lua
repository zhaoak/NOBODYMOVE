local M = {}
local camera = require'camera'

-- File for handling keyboard and gamepad inputs and translating them into game inputs.
M.binds = {
  up = 'w',
  down = 's',
  left = 'a',
  right = 'd',
  ragdoll = "space",
  shoot = 1,
  reset = 2,
}

-- check if a mouse button or keyboard key is down
M.keyDown = function (bind)
  if type(M.binds[bind]) == "string" then
    return love.keyboard.isDown(M.binds[bind])
  else
    return love.mouse.isDown(M.binds[bind])
  end
end

-- mous for now, add controller later
M.getCrossHair = function ()
  return camera.getCameraRelativeMousePos()
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
  local joy
  print("button: "..button)
end
-- }}}

return M
