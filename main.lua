-- nobody move prototype



-- filewide vars
local obj = {} -- all physics objects
local phys = {} -- physics handlers
local world -- the physics world
local cooldown = 0 -- player shoot cooldown (very tmp)

-- import physics objects
obj.playfield = require("playfield")
obj.player = require("player")


-- functions
-- draw
function love.draw() -- {{{
  obj.playfield.draw()
  obj.player.draw()

  -- various debug info
  love.graphics.print("airborne: "..tostring(obj.player.airborne), 0, 0)
  love.graphics.print("shouldLatch: "..tostring(obj.player.shouldLatch), 0, 20)
end  -- }}}

-- step
function love.update(dt) -- {{{
  -- reset spood
  if love.mouse.isDown(2) then
    obj.player.setup(world)
  end

  -- recoil the player away from the mouse
  if love.mouse.isDown(1) and cooldown <= 0 then
    cooldown = 0.4
    obj.player.recoil(love.mouse:getX(), love.mouse:getY())
  end
  cooldown = cooldown - dt -- decrement the cooldown

  obj.player.update()
  world:update(dt)

  -- if stan

  -- update latching state
  if love.keyboard.isDown("space") then
    obj.player.shouldLatch = true
  else
    obj.player.shouldLatch = false
  end

  -- air keeb controls
  if love.keyboard.isDown('a') and obj.player.shouldLatch == false then
    obj.player.body:applyForce(-50, 0)
  end

  if love.keyboard.isDown('d') and obj.player.shouldLatch == false then
    obj.player.body:applyForce(50, 0)
  end


end -- }}}

-- init
function love.load() -- {{{
  love.graphics.setBackgroundColor(.2,.2,.2)
  love.window.setMode(1000,1000)
  love.window.setVSync(true)

  love.physics.setMeter(64)

  -- create the physics world
  world = love.physics.newWorld(0,10*64, false)
  world:setCallbacks( beginContact, endContact, preSolve, postSolve )

  obj.playfield.setup(world)
  obj.player.setup(world)
end -- }}}

-- catch resize
love.resize = function (width,height)
  obj.playfield.resize(width,height)
end

function beginContact(a, b, coll)
  local x, y = coll:getNormal()
  local cx1, cy1, cx2, cy2 = coll:getPositions()
  print(a:getUserData().." colliding with "..b:getUserData()..", vector normal: "..x..", "..y)

  local obja = a:getUserData()
  local objb = b:getUserData()

  if ((obja == "reach" and objb == "border") or (obja == "border" and objb == "reach")) then
    obj.player.airborne = false
  end

  -- if player is holding shouldLatch key when they collide with a border, latch to it
  if obj.player.shouldLatch == true and obja == "border" and objb == "reach" then
    print(tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
    obj.player.latchToTerrain(cx1, cy1, cx2, cy2, coll)
  end
end

function endContact(a, b, coll)
  print(a:getUserData().." and "..b:getUserData().." no longer colliding")

  local obja = a:getUserData()
  local objb = b:getUserData()

  if ((obja == "reach" and objb == "border") or (obja == "border" and objb == "reach")) then
    obj.player.airborne = true
  end
end

function preSolve(a, b, coll)

end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)

end
-- vim: foldmethod=marker
