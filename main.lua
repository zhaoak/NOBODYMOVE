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
end  -- }}}

-- step
function love.update(dt) -- {{{
  -- reset spood
  if love.mouse.isDown(2) then
    obj.player.setup(world)
  end

  if love.mouse.isDown(3) then
    obj.mous = love.physics.newMouseJoint(obj.player.hardbox.body, love.mouse:getX(), love.mouse:getY())
  end

  -- recoil the player away from the mouse
  if love.mouse.isDown(1) and cooldown <= 0 then
    cooldown = 0.4
    obj.player.recoil(love.mouse:getX(), love.mouse:getY())
  end
  cooldown = cooldown - dt -- decrement the cooldown

  if obj.player.mous then obj.player.mous:setTarget(love.mouse.getPosition()) end
  obj.player.update()
  world:update(dt)

  if love.keyboard.isDown('a') then
    obj.player.body:applyForce(-50, 0)
  end

  if love.keyboard.isDown('d') then
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
  x, y = coll:getNormal()
  print(a:getUserData().." colliding with "..b:getUserData()..", vector normal: "..x..", "..y)
end

function endContact(a, b, coll)
  print(a:getUserData().." and "..b:getUserData().." no longer colliding")
end

function preSolve(a, b, coll)

end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)

end
-- vim: foldmethod=marker
