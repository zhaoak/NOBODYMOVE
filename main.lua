-- nobody move prototype

-- utilities
local util = require'util'


-- filewide vars
local obj = {} -- all physics objects
local phys = {} -- physics handlers
local world -- the physics world
local nextFrameActions = {} -- uhhh ignore for now pls

-- import physics objects
obj.playfield = require("playfield")
obj.player = require("player")
local gunlib = require'guns'


-- functions
-- draw
function love.draw() -- {{{
  obj.playfield.draw()
  obj.player.draw()
end  -- }}}

-- step
function love.update(dt) -- {{{
  -- reset spood on rightclick
  if love.mouse.isDown(2) then
    obj.player.setup(world)
  end

  gunlib.update(dt)
  obj.player.update(dt)

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
  world:setCallbacks( beginContact, endContact, preSolve, postSolve )

  obj.playfield.setup(world)
  obj.player.setup(world)
end -- }}}

-- catch resize
love.resize = function (width,height)
  obj.playfield.resize(width,height)
end

-- physics collision callbacks {{{

function beginContact(a, b, contact) -- {{{
  -- print(a:getUserData().." colliding with "..b:getUserData()..", vector normal: "..x..", "..y)

  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- if terrain comes in range of spooder's reach...
  if (fixtureAUserData.name == "reach" and fixtureBUserData.type == "terrain") or (fixtureBUserData.name == "reach" and fixtureAUserData.type == "terrain") then
    -- ...then add the terrain to the cache of terrain items in latching range
    if fixtureAUserData.name == "reach" then
      obj.player.terrainInRange[fixtureBUserData.uid] = b
    else
      obj.player.terrainInRange[fixtureAUserData.uid] = a
    end
    util.printTerrainInRangeUserData(obj.player.terrainInRange)
  end

  -- print(tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
end -- }}}

function endContact(a, b, contact) -- {{{
  -- print(a:getUserData().." and "..b:getUserData().." no longer colliding")

  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- when terrain leaves range of spooder's reach...
  if (fixtureAUserData.name == "reach" and fixtureBUserData.type == "terrain") or (fixtureBUserData.name == "reach" and fixtureAUserData.type == "terrain") then
    -- ...remove the terrain from the cache of terrain items in latching range
    if fixtureAUserData.name == "reach" then
      print(fixtureBUserData.name.." leaving latchrange")
      obj.player.terrainInRange[fixtureBUserData.uid] = nil
    else
      print(fixtureAUserData.name.." leaving latchrange")
      obj.player.terrainInRange[fixtureAUserData.uid] = nil
    end
  end
end -- }}}

function preSolve(a, b, contact) -- {{{
  -- Since 'sensors' senselessly sense solely shapes sharing space, shan't share specifics, shove sensors.
  -- Silly sensors, surely sharing shouldn't stress software simulation?
  -- So, set shapes: "sure, sharing space shouldn't shove shapes", so seeing spots shapes share shall succeed shortly.

  -- ...

  -- um. i meant. fixtures set to be sensors only track the fact that they're colliding, not anything about it
  -- so instead of making e.g. the player's reach box a sensor, just cancel the contact from doing anything with physics every time it gets created
  -- then in code when we grab the contact we can use methods like getPositions
  if a:getUserData().semisensor or b:getUserData().semisensor then
    contact:setEnabled(false)
  end
  -- local cx1, cy1, cx2, cy2 = contact:getPositions()
  -- print("presolve: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
  -- print(a:getUserData().." colliding with "..b:getUserData())
end -- }}}

function postSolve(a, b, contact, normalimpulse, tangentimpulse) -- {{{
  -- local cx1, cy1, cx2, cy2 = contact:getPositions()
  -- print("postsolve: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
end -- }}}

-- }}}


-- vim: foldmethod=marker
