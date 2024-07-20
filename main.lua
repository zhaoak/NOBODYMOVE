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

  -- various debug info
  love.graphics.setColor(1, 1, 1)
  local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = obj.player.body:getLinearVelocity()
  local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))
  love.graphics.print("spooder velocity, x/y/total: "..tostring(spoodCurrentLinearVelocityX).." / "..tostring(spoodCurrentLinearVelocityY).." / "..tostring(spoodCurrentLinearVelocity))
  love.graphics.print("latched? "..tostring(obj.player.latched), 0, 20)
  if debugClosestFixture then
    local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.hardbox.fixture, debugClosestFixture)
    love.graphics.print("distance between hardbox and closest fixture and their closest points (displayed in orange): "..tostring(math.floor(distance))..", ("..tostring(math.floor(x1))..", "..tostring(math.floor(y1))..") / ("..tostring(math.floor(x2))..", "..tostring(math.floor(y2))..")", 0, 60)
    love.graphics.setColor(0, .5, 0)
    if debugRayImpactX ~= nil and debugRayImpactY ~= nil then
      love.graphics.circle("fill", debugRayImpactX, debugRayImpactY, 4)
    end

    if debugRayNormalX ~= nil and debugRayImpactY ~= nil then
      -- We also get the surface normal of the edge the ray hit. Here drawn in green
      love.graphics.setColor(0, 255, 0)
      love.graphics.line(debugRayImpactX, debugRayImpactY, debugRayImpactX + debugRayNormalX * 25, debugRayImpactY + debugRayNormalY * 25)
      -- print(tostring(debugRayNormalX).." / "..tostring(debugRayNormalY))
    end
    love.graphics.setColor(.95, .65, .25)
    love.graphics.circle("fill", x1, y1, 4)
    love.graphics.circle("fill", x2, y2, 4)
  end
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
