local M = {}
local camera = require'camera'

-- Whether the player is shooting or not this tick
M.shootingThisTick = false

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

-- joystick deadzone settings
M.movementJoystickThresholdX = 0.30
M.movementJoystickThresholdY = 0.30
M.aimJoystickThresholdX = 0.05
M.aimJoystickThresholdY = 0.05

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
M.gamepadButtonBinds = {
  ragdoll = "leftshoulder",
  shootFG1 = "rightshoulder",
  shootFG2 = "righttrigger",
  shootFG3 = "lefttrigger",
  shootFG4 = nil,
  shootFG5 = nil,
  shootFG6 = nil,
  shootFG7 = nil,
  shootFG8 = nil,
  reset = "y"
}

-- Input-device-specific input checks {{{
-- check if a mouse button or keyboard key is down
M.keyDown = function (bind)
  if M.kbMouseBinds[bind] == nil then return false end

  if type(M.kbMouseBinds[bind]) == "string" then
    return love.keyboard.isDown(M.kbMouseBinds[bind])
  else
    return love.mouse.isDown(M.kbMouseBinds[bind])
  end
end

-- check if a gamepad button is down
M.gamepadButtonDown = function (bind, joystick)
  if joystick == nil then return false end
  if M.gamepadButtonBinds[bind] == nil then return false end

  if M.gamepadButtonBinds[bind] == "righttrigger" or M.gamepadButtonBinds[bind] == "lefttrigger" then
    if M.gamepadButtonBinds[bind] == "righttrigger" then
      if M.gamepadAxisTriggerValues.rightTrigger >= 0 then return true else return false end
    elseif M.gamepadButtonBinds[bind] == "lefttrigger" then
      if M.gamepadAxisTriggerValues.leftTrigger >= 0 then return true else return false end
    end
  else
    return joystick:isGamepadDown(M.gamepadButtonBinds[bind])
  end
end
-- }}}

-- Game command check functions {{{
-- get if shoot input is currently down
-- args:
-- `firegroup`(number): the firegroup the player is attempting to shoot, 1-8
M.getShootDown = function(firegroup)
  if M.keyDown("shootFG"..firegroup) or M.gamepadButtonDown("shootFG"..firegroup, M.connectedControllers.player1Joy) then
    M.shootingThisTick = true
    return true
  else
    return false
  end
end

-- get if player has shot a gun this tick
M.getShotGunThisTick = function()
  return M.shootingThisTick
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
-- }}}

-- Update functions {{{

-- get a specific gamepad's current stick values
-- if an axis is within deadzone threshold, returns zero
-- (although currently only one gamepad at a time is supported)
M.updateGamepadAxisTriggerInputs = function (joystick)
  if joystick ~= nil then
    local lStickX, lStickY, lTrigger, rStickX, rStickY, rTrigger = joystick:getAxes()
    
    if lStickX < M.movementJoystickThresholdX and lStickX > -M.movementJoystickThresholdX then lStickX = 0 end
    M.gamepadAxisTriggerValues.leftStickX = lStickX
    if lStickY < M.movementJoystickThresholdY and lStickY > -M.movementJoystickThresholdY then lStickY = 0 end
    M.gamepadAxisTriggerValues.leftStickY = lStickY
    if rStickX < M.aimJoystickThresholdX and rStickX > -M.aimJoystickThresholdX then rStickX = 0 end
    M.gamepadAxisTriggerValues.rightStickX = rStickX
    if rStickY < M.aimJoystickThresholdY and rStickY > -M.aimJoystickThresholdY then rStickY = 0 end
    M.gamepadAxisTriggerValues.rightStickY = rStickY
    M.gamepadAxisTriggerValues.leftTrigger = lTrigger
    M.gamepadAxisTriggerValues.rightTrigger = rTrigger
  end

  -- if a joystick for P1 is connected, and being used for aim this tick, disable mouseaim
  if joystick == M.connectedControllers.player1Joy and (M.gamepadAxisTriggerValues.rightStickX ~= 0 or M.gamepadAxisTriggerValues.rightStickY ~= 0) and M.mouseAimDisabled == false then
    M.mouseAimDisabled = true
  end
end

-- Update all joysticks axis values for this tick
M.updateJoystickInputs = function ()
  for playerController, joystick in pairs(M.connectedControllers) do
    M.updateGamepadAxisTriggerInputs(joystick)
  end
end

-- Reset to false every tick
-- (when the player shoots a gun, the var is set to true)
M.updateShootingThisTick = function ()
  M.shootingThisTick = false
end

-- Update everything in input that needs to be updated every tick
M.update = function ()
  M.updateShootingThisTick()
  M.updateJoystickInputs()
end
-- }}}

-- Input callback functions {{{
-- gamepad
function love.gamepadpressed(joystick, button)
  -- printCurrentJoystickInputs(joystick)
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

-- Debug functions {{{
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
