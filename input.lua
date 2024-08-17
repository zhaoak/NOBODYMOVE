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

-- since mouse position is always present, we need a way to tell when to use controller rstick vs mouse aim
M.mouseAimDisabled = false

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
  elseif M.connectedControllers.player1Joy == nil then
    return 0
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
  elseif M.connectedControllers.player1Joy == nil then
    return 0
  else
    -- if no kb+mouse Y-axis movement input, use controller value
    return M.gamepadAxisTriggerValues.leftStickY
  end
end
-- }}}

-- aiming with controller stick is faked by simply returning mouse coords in a circle around spood body,
-- with where on the circle based on controller stick position
local fakeAimAngleCacheX, fakeAimAngleCacheY = 1, 0
M.getCrossHair = function (playerPosX, playerPosY)
  if M.mouseAimDisabled then
    local fakeAimX, fakeAimY = playerPosX, playerPosY
    if M.gamepadAxisTriggerValues.rightStickX ~= 0 and M.gamepadAxisTriggerValues.rightStickY ~= 0 then
      fakeAimAngleCacheX, fakeAimAngleCacheY = M.gamepadAxisTriggerValues.rightStickX, M.gamepadAxisTriggerValues.rightStickY
    end
    fakeAimX = fakeAimX + ((fakeAimAngleCacheX or M.gamepadAxisTriggerValues.rightStickX) * 4)
    fakeAimY = fakeAimY + ((fakeAimAngleCacheY or M.gamepadAxisTriggerValues.rightStickY) * 4)
    return fakeAimX, fakeAimY
  else
    -- if mouseaim not disabled, just use mouse position
    return camera.getCameraRelativeMousePos()
  end
end

-- get current gamepad stick values
M.updateGamepadAxisTriggerInputs = function (joystick)
  if joystick ~= nil then
    local lStickX, lStickY, lTrigger, rStickX, rStickY, rTrigger = joystick:getAxes()
    M.gamepadAxisTriggerValues.leftStickX = lStickX
    M.gamepadAxisTriggerValues.leftStickY = lStickY
    M.gamepadAxisTriggerValues.rightStickX = rStickX
    M.gamepadAxisTriggerValues.rightStickY = rStickY
    M.gamepadAxisTriggerValues.leftTrigger = lTrigger
    M.gamepadAxisTriggerValues.rightTrigger = rTrigger
  end

  -- if a joystick is connected, and being used for aim this tick, disable mouseaim
  if joystick ~= nil and (M.gamepadAxisTriggerValues.rightStickX ~= 0 or M.gamepadAxisTriggerValues.rightStickY ~= 0) and M.mouseAimDisabled == false then
    M.mouseAimDisabled = true
  end
  print(M.mouseAimDisabled)
end

-- input callback functions {{{
-- gamepad
function love.gamepadpressed(joystick, button)
  printCurrentJoystickInputs(joystick)
  -- printGamepadButtonInputs(joystick, button)
  -- joystick:setVibration(1, 1) -- vrrrrrr
end

-- gamepad connected/present on application start
function love.joystickadded(joystick)
  -- for now, autoassign to player 1
  if M.connectedControllers.player1Joy == nil then
    M.connectedControllers.player1Joy = joystick
  end
end

-- gamepad removed
function love.joystickremoved(joystick)
  -- on removal, remove joystick from table of connected controllers
  M.connectedControllers.player1Joy = nil
end

-- if player moves mouse, assume they want to use mouseaim
function love.mousemoved()
  M.mouseAimDisabled = false
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
