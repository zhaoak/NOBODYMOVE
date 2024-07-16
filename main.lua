-- nobody move prototype



-- filewide vars
local obj = {} -- all physics objects
local phys = {} -- physics handlers
local world -- the physics world
local cooldown = 0 -- player shoot cooldown (very tmp)
local nextFrameActions = {} -- uhhh ignore for now pls
local debugRayImpactX, debugRayImpactY -- don't mind my devcode pls
local debugRayNormalX, debugRayNormalY -- yep

-- import physics objects
obj.playfield = require("playfield")
obj.player = require("player")
obj.platform = require("platform")


-- functions
-- draw
function love.draw() -- {{{
  obj.playfield.draw()
  obj.player.draw()
  obj.platform.draw()

  -- various debug info
  -- love.graphics.print("airborne: "..tostring(obj.player.airborne), 0, 0)
  love.graphics.print("shouldLatch: "..tostring(obj.player.shouldLatch), 0, 20)
  love.graphics.print("spood touching how many bodies??: "..tostring(obj.player.bodiesInRange), 0, 40)
  local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.reach.fixture, obj.platform.fixture)
  love.graphics.print("distance between range and platform and their closest points (displayed in orange): "..tostring(math.floor(distance))..", ("..tostring(math.floor(x1))..", "..tostring(math.floor(y1))..") / ("..tostring(math.floor(x2))..", "..tostring(math.floor(y2))..")", 0, 60)
  love.graphics.setColor(.95, .65, .25)
  love.graphics.circle("fill", x1, y1, 4)
  love.graphics.circle("fill", x2, y2, 4)
  love.graphics.setColor(0, .5, 0)
  if debugRayImpactX ~= nil and debugRayImpactY ~= nil then
    love.graphics.circle("fill", debugRayImpactX, debugRayImpactY, 4)
  end

  if debugRayNormalX ~= nil and debugRayImpactY ~= nil then
    -- We also get the surface normal of the edge the ray hit. Here drawn in green
    love.graphics.setColor(0, 255, 0)
    love.graphics.line(debugRayImpactX, debugRayImpactY, debugRayImpactX + debugRayNormalX * 25, debugRayImpactY + debugRayNormalY * 25)
  end
end  -- }}}

-- step
function love.update(dt) -- {{{
  -- iterate thru spood collisions; if one is between 
  local playerBodyContacts = obj.player.body:getContacts()
  local cx1, cy1, cx2, cy2;
  for k, v in ipairs(playerBodyContacts) do
    local fixt1, fixt2 = v:getFixtures()
    cx1, cy1, cx2, cy2 = v:getPositions()
    -- print("reach is sensor? "..tostring(obj.player.reach.fixture:isSensor()))
    -- print("playercollision! fixtures: "..fixt1:getUserData()..", "..fixt2:getUserData())
    -- print("contact points: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
  end

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

  if love.keyboard.isDown("space") then
    obj.player.shouldLatch = true
    -- if within range of wall and not already latched, latch to it
    local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.reach.fixture, obj.platform.fixture)
    if not obj.player.latched and distance == 0 then
      -- raytrace from spood center position through getDistance contact point, find the point where spood is touching terrain
      local spoodWorldCenterX, spoodWorldCenterY = obj.player.body:getWorldCenter()
      local normalVectX, normalVectY, fraction = obj.platform.fixture:rayCast(spoodWorldCenterX, spoodWorldCenterY, x1, y1, 5)
      local rayImpactLocX, rayImpactLocY = spoodWorldCenterX + (x1 - spoodWorldCenterX) * fraction, spoodWorldCenterY + (y1 - spoodWorldCenterY) * fraction
      debugRayImpactX = rayImpactLocX
      debugRayImpactY = rayImpactLocY
      debugRayNormalX = normalVectX
      debugRayNormalY = normalVectY
      
      obj.player.latchToTerrain(x1, y1)
    end
  else
    obj.player.shouldLatch = false
    if obj.player.latched == true then
      obj.player.unlatchFromTerrain()
    end
  end


  -- air keeb controls
  if love.keyboard.isDown('a') and obj.player.shouldLatch == false then
    obj.player.body:applyForce(-50, 0)
  end

  if love.keyboard.isDown('d') and obj.player.shouldLatch == false then
    obj.player.body:applyForce(50, 0)
  end

  obj.player.update()

  world:update(dt)
end -- }}}

-- init
function love.load() -- {{{
  love.graphics.setBackgroundColor(.2,.2,.2)
  love.window.setMode(1000,1000)
  love.window.setVSync(true)

  love.physics.setMeter(64)

  -- create the physics world
  world = love.physics.newWorld(0,5*64, false)
  world:setCallbacks( beginContact, endContact, preSolve, postSolve )

  obj.playfield.setup(world)
  obj.player.setup(world)
  obj.platform.setup(world)
end -- }}}

-- catch resize
love.resize = function (width,height)
  obj.playfield.resize(width,height)
end

function beginContact(a, b, coll)
  -- print(tprint(obj.player.body:getContacts()))
  local x, y = coll:getNormal()
  local cx1, cy1, cx2, cy2 = coll:getPositions()
  -- print(a:getUserData().." colliding with "..b:getUserData()..", vector normal: "..x..", "..y)

  local obja = a:getUserData()
  local objb = b:getUserData()

  if ((obja == "reach" and objb == "border") or (obja == "border" and objb == "reach")) then
    obj.player.bodiesInRange = obj.player.bodiesInRange + 1
  end

  -- print(tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
end

function endContact(a, b, coll)
  -- print(a:getUserData().." and "..b:getUserData().." no longer colliding")

  local obja = a:getUserData()
  local objb = b:getUserData()

  if ((obja == "reach" and objb == "border") or (obja == "border" and objb == "reach")) then
    obj.player.airborne = true
    obj.player.bodiesInRange = obj.player.bodiesInRange - 1
  end
end

function preSolve(a, b, coll)
  local cx1, cy1, cx2, cy2 = coll:getPositions()
  -- print("presolve: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
  -- print(a:getUserData().." colliding with "..b:getUserData())
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
  -- local cx1, cy1, cx2, cy2 = coll:getPositions()
  -- print("postsolve: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2 
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "   
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

-- vim: foldmethod=marker
