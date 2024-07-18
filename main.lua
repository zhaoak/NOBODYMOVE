-- nobody move prototype



-- filewide vars
local obj = {} -- all physics objects
local phys = {} -- physics handlers
local world -- the physics world
local cooldown = 0 -- player shoot cooldown (very tmp)
local nextFrameActions = {} -- uhhh ignore for now pls
local TerrainInRange = {} -- using collision callbacks, when terrain enters/exits latchrange, it's added/removed here
local LastFramePositionX, LastFramePositionY
local LastFrameVelocityX, LastFrameVelocityY, LastFrameVelocity
local debugRayImpactX, debugRayImpactY -- don't mind my devcode pls
local debugRayNormalX, debugRayNormalY -- yep

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
  love.graphics.print("shouldLatch: "..tostring(obj.player.shouldLatch), 0, 20)
  if debugClosestFixture then
    local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.reach.fixture, debugClosestFixture)
    love.graphics.print("distance between range and closest fixture and their closest points (displayed in orange): "..tostring(math.floor(distance))..", ("..tostring(math.floor(x1))..", "..tostring(math.floor(y1))..") / ("..tostring(math.floor(x2))..", "..tostring(math.floor(y2))..")", 0, 60)
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
  -- iterate thru spood collisions, report their contact points
  -- debug stuff basically
  local playerBodyContacts = obj.player.body:getContacts()
  local cx1, cy1, cx2, cy2;
  for k, v in ipairs(playerBodyContacts) do
    local fixt1, fixt2 = v:getFixtures()
    cx1, cy1, cx2, cy2 = v:getPositions()
    -- print("playercollision! fixtures: "..fixt1:getUserData()..", "..fixt2:getUserData())
    -- print("contact points: "..tostring(cx1)..", "..tostring(cy1).." / "..tostring(cx2)..", "..tostring(cy2))
  end

  -- cache current frame spood velocity
  local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = obj.player.body:getLinearVelocity()
  local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))

  -- if not latched, iterate through all terrain in range this frame, find the closest fixture
  -- the closest fixture is the one that should be latched to
  local closestFixture = nil
  debugClosestFixture = nil
  if not obj.player.latched then
    local shortestDistance = obj.player.reachRadius + 1
    for k, v in pairs(TerrainInRange) do
      local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.hardbox.fixture, v)
      if distance < shortestDistance then shortestDistance = distance end
      local newUserData = v:getUserData()
      newUserData.distance = distance
      newUserData.x1 = x1
      newUserData.y1 = y1
      newUserData.x2 = x2
      newUserData.y2 = y2
      v:setUserData(newUserData)
    end
    for k, v in pairs(TerrainInRange) do
      local thisFixtureUserData = v:getUserData()
      if thisFixtureUserData.distance == shortestDistance then
        closestFixture = TerrainInRange[thisFixtureUserData.uid]
        debugClosestFixture = closestFixture
        print(tprint(closestFixture:getUserData()).." is closest")
      end
    end
  end

  local spoodWorldCenterX, spoodWorldCenterY = obj.player.body:getWorldCenter()
  local rayImpactLocX, rayImpactLocY = 50, 50
  local normalVectX, normalVectY = 50, 50
  if closestFixture then
    -- raytrace from spood center position through previously calculated getDistance contact point on closest fixture,
    -- using raytrace to find the point where spood is touching terrain
    normalVectX, normalVectY, fraction = closestFixture:rayCast(spoodWorldCenterX, spoodWorldCenterY, closestFixture:getUserData().x1, closestFixture:getUserData().y1, 10)
    rayImpactLocX, rayImpactLocY = spoodWorldCenterX + (closestFixture:getUserData().x1 - spoodWorldCenterX) * fraction, spoodWorldCenterY + (closestFixture:getUserData().y1 - spoodWorldCenterY) * fraction
    debugRayImpactX = rayImpactLocX
    debugRayImpactY = rayImpactLocY
    debugRayNormalX = normalVectX
    debugRayNormalY = normalVectY
  end

  -- reset spood on rightclick
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
    -- if latchable fixture within range, latch to closest one
    -- local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.reach.fixture, obj.playfield.tiltedPlatform.fixture)
    if not obj.player.latched and closestFixture then
      print(tostring(rayImpactLocX))
      -- then latch to it
      -- obj.player.latchToTerrain(rayImpactLocX, rayImpactLocY, normalVectX, normalVectY, fraction, closestFixture)
    end
  else
    obj.player.shouldLatch = false
    if obj.player.latched == true then
      obj.player.unlatchFromTerrain()
    end
  end


  -- left/right controls
  if love.keyboard.isDown('a') and love.keyboard.isDown('d') == false then
    if obj.player.latched == true then
      -- if latched, move along surface
      -- to tell what direction to move, use same raytrace technique as above,
      -- rotate the returned normal vector by 90 degrees, then use a multiple of that value to apply force in that direction
      if spoodCurrentLinearVelocity <= obj.player.maxWalkingSpeed then
        debugRayNormalX = normalVectX
        debugRayNormalY = normalVectY
        local directionVectorX = normalVectY
        local directionVectorY = normalVectX * -1
        -- check if spooder has actually walked off of latched surface
        -- edit: it DOESN"T WORK
        if normalVectX == nil or normalVectY == nil then
          obj.player.unlatchFromTerrain()
        else
          obj.player.body:applyLinearImpulse(50 * directionVectorX, 50 * directionVectorY)
        end
      end
    else
      -- otherwise, use air controls
      obj.player.body:applyForce(-100, 0)
    end
  end

  if love.keyboard.isDown('d') and love.keyboard.isDown('a') == false then
    if obj.player.latched == true then
      -- if latched and below max walking speed, move along surface
      -- to tell what direction to move, use same raytrace technique as above,
      -- rotate the returned normal vector by 90 degrees, then use a multiple of that value to apply force in that direction
      if spoodCurrentLinearVelocity <= obj.player.maxWalkingSpeed then
        debugRayNormalX = normalVectX
        debugRayNormalY = normalVectY
        local directionVectorX = normalVectY * -1
        local directionVectorY = normalVectX
        -- check if spooder has walked off latched surface
        -- this doesn't work btw
        if normalVectX == nil or normalVectY == nil then
          obj.player.unlatchFromTerrain()
        else
          obj.player.body:applyLinearImpulse(50 * directionVectorX, 50 * directionVectorY)
        end
      end
    else
      -- otherwise, use air controls
      obj.player.body:applyForce(100, 0)
    end
  end

  -- if l/r keys are pressed simultaneously while latched, cancel movement
  if obj.player.latched and love.keyboard.isDown('d') and love.keyboard.isDown('a') then
    local newLinearVelocityX, newLinearVelocityY = obj.player.body:getLinearVelocity()
    newLinearVelocityX = newLinearVelocityX * .7
    newLinearVelocityY = newLinearVelocityY * .7
    obj.player.body:setLinearVelocity(newLinearVelocityX, newLinearVelocityY)
  end

  -- if walking on surface and no keys are pressed, decelerate
  if obj.player.latched and love.keyboard.isDown('d') == false and love.keyboard.isDown('a') == false then
    local newLinearVelocityX, newLinearVelocityY = obj.player.body:getLinearVelocity()
    newLinearVelocityX = newLinearVelocityX * .7
    newLinearVelocityY = newLinearVelocityY * .7
    obj.player.body:setLinearVelocity(newLinearVelocityX, newLinearVelocityY)
  end

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
      TerrainInRange[fixtureBUserData.uid] = b
    else
      TerrainInRange[fixtureAUserData.uid] = a
    end
    printTerrainInRangeUserData()
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
      TerrainInRange[fixtureBUserData.uid] = nil 
    else
      print(fixtureAUserData.name.." leaving latchrange")
      TerrainInRange[fixtureAUserData.uid] = nil 
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

-- misc utility garbage {{{
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

function printTerrainInRangeUserData()
  for k, v in pairs(TerrainInRange) do
    print(tprint(v:getUserData()))
  end
end
-- }}}

-- vim: foldmethod=marker
