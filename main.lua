-- nobody move prototype



-- filewide vars
local obj = {} -- all physics objects
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

  -- recoil the player away from the mouse
  if love.mouse.isDown(1) and cooldown <= 0 then
    cooldown = 0.4
    obj.player.recoil(love.mouse:getX(), love.mouse:getY())
  end
  cooldown = cooldown - dt -- decrement the cooldown

  world:update(dt)
end -- }}}

-- init
function love.load() -- {{{
  love.graphics.setBackgroundColor(.2,.2,.2)
  love.window.setMode(1000,1000)
  love.window.setVSync(true)

  love.physics.setMeter(64)

  -- create the physics world
  world = love.physics.newWorld(0,10*64, false)

  obj.playfield.setup(world)
  obj.player.setup(world)
end -- }}}


-- vim: foldmethod=marker
