-- nobody move prototype


-- tables
local obj = {}
local world



local function setup_world() -- {{{
  obj.ground = {}
  obj.ground.body = love.physics.newBody(world, 0,0, "static")
  obj.ground.shape = love.physics.newEdgeShape(0,800, 1000,1000)
  obj.ground.fixture = love.physics.newFixture(obj.ground.body, obj.ground.shape)

  obj.ground.color = { 1,1,1, 1 }
end -- }}}

-- functions
local function setup_spood() -- {{{
  if obj.spood then obj.spood.body:destroy() end
  obj.spood = {}

  obj.spood.body = love.physics.newBody(world, 100,100, "dynamic")
  obj.spood.shape = love.physics.newCircleShape(20)
  obj.spood.fixture = love.physics.newFixture(obj.spood.body, obj.spood.shape)

end -- }}}

function love.draw() -- {{{
  love.graphics.setColor(1,1,1)
  love.graphics.line(obj.ground.body:getWorldPoints(obj.ground.shape:getPoints()))

  love.graphics.setColor(0.5,1,1)
  love.graphics.circle("fill", obj.spood.body:getX(), obj.spood.body:getY(), obj.spood.shape:getRadius())
end  -- }}}

-- step
  local cooldown = 1
function love.update(dt)
  if love.mouse.isDown(2) then
    setup_spood()
  end

  if love.mouse.isDown(1) and cooldown < 0 then
    cooldown = 1
    local x = (love.mouse:getX() - obj.spood.body:getX()) * 10
    local y = (love.mouse:getY() - obj.spood.body:getY()) * 10
    -- love.mouse:getY()


    obj.spood.body:applyLinearImpulse(-x, -y)
  end
  cooldown = cooldown - dt

  world:update(dt)
end -- }}}

-- init
function love.load() -- {{{
  love.graphics.setBackgroundColor(.2,.2,.2)
  love.window.setMode(1000,1000)
  love.window.setVSync(true)

  love.physics.setMeter(64)

  world = love.physics.newWorld(0,10*64, false)

  setup_world()
  setup_spood()
end -- }}}


-- vim: foldmethod=marker
