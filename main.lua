-- nobody move prototype

-- utilities
local util = require'util'


-- filewide vars
local obj = {} -- all physics objects
local phys = {} -- physics handlers
local world -- the physics world
local nextFrameActions = {} -- uhhh ignore for now pls
local LastFramePositionX, LastFramePositionY
local LastFrameVelocityX, LastFrameVelocityY, LastFrameVelocity

local debugRayImpactX, debugRayImpactY -- don't mind my devcode pls
local debugRayNormalX, debugRayNormalY -- yep
local debugClosestFixture

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
  -- if currently latched, check if still in valid position to be latched
  -- if obj.player.latched then
  --   obj.player.checkIfLatchStillValid(obj.playfield.tiltedPlatform.fixture)
  -- end

  -- cache this frame's playervalues for comparison next frame
  LastFramePositionX = spoodWorldCenterX
  LastFramePositionY = spoodWorldCenterY
  LastFrameVelocityX = spoodCurrentLinearVelocityX
  LastFrameVelocityY = spoodCurrentLinearVelocityY
  LastFrameVelocity = spoodCurrentLinearVelocity

  -- reset spood on rightclick
  if love.mouse.isDown(2) then
    obj.player.setup(world)
  end

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
function beginContact(a, b, coll)
  -- print(a:getUserData().." colliding with "..b:getUserData()..", vector normal: "..x..", "..y)

  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- if terrain comes in range of spooder's reach...
  if (fixtureAUserData == "reach" and fixtureBUserData.type == "terrain") or (fixtureBUserData == "reach" and fixtureAUserData.type == "terrain") then
    -- ...then add the terrain to the cache of terrain items in latching range
    if fixtureAUserData == "reach" then
      obj.player.terrainInRange[fixtureBUserData.uid] = b
    else
      obj.player.terrainInRange[fixtureAUserData.uid] = a
    end
    util.printTerrainInRangeUserData(obj.player.terrainInRange)
  end

  -- print(tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
end

function endContact(a, b, coll)
  -- print(a:getUserData().." and "..b:getUserData().." no longer colliding")

  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- when terrain leaves range of spooder's reach...
  if (fixtureAUserData == "reach" and fixtureBUserData.type == "terrain") or (fixtureBUserData == "reach" and fixtureAUserData.type == "terrain") then
    -- ...remove the terrain from the cache of terrain items in latching range
    if fixtureAUserData == "reach" then
      print(fixtureBUserData.name.." leaving latchrange")
      obj.player.terrainInRange[fixtureBUserData.uid] = nil
    else
      print(fixtureAUserData.name.." leaving latchrange")
      obj.player.terrainInRange[fixtureAUserData.uid] = nil
    end
  end
end

function preSolve(a, b, coll)
  -- local cx1, cy1, cx2, cy2 = coll:getPositions()
  -- print("presolve: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
  -- print(a:getUserData().." colliding with "..b:getUserData())
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
  -- local cx1, cy1, cx2, cy2 = coll:getPositions()
  -- print("postsolve: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
end
-- }}}


-- vim: foldmethod=marker
