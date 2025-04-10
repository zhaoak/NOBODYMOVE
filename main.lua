-- nobody move
-- a video game
-- by Allie Zhao and Spider Forrest

-- utilities
local util = require'util'

-- filewide vars
local obj = {} -- all physics objects
local phys = {} -- physics handlers

-- import physics objects
obj.playfield = require("maps.debugmap")
obj.player = require("player")
obj.projectiles = require("projectiles")
obj.npc = require("npc.npc")

-- import required modules
local gunlib = require'guns'
local cam = require'camera'
local gameUi = require'ui.gameUi'
local dmgText = require'ui.damageNumbers'
local input = require'input'

function love.load() -- {{{ init
  local optionsTable = {
    fullscreen = false,
    fullscreentype = "desktop",
    vsync = true,
    resizable = true,
    borderless = false,
    display = 1,
    minwidth = 800,
    minheight = 600
  }

  love.window.setMode(1000,1000, optionsTable)
  love.graphics.setBackgroundColor(.2,.2,.2)
  love.window.setVSync(true)
  love.window.setTitle("NOBODY MOVE")

  love.physics.setMeter(64)

  -- tumbledryer that randomness seed baby
  math.randomseed(os.time())

  -- create the physics world stored in util and accessable everywhere
  util.world = love.physics.newWorld(0,10*64, false)
  util.world:setCallbacks( beginContact, endContact, preSolve, postSolve )

  obj.playfield.setup(util.world)
  obj.player.setup(util.world)
  obj.projectiles.setup(util.world)

  cam.scale(1.25)

  gameUi.setup()

end -- }}}

function love.update(dt) -- {{{
  cam.update(dt, obj.player) -- passing the cam module player data for follow functions
  cam.setBehaviorMode("followAim")
  input.update()
  obj.player.update(dt) 
  gunlib.update(dt)
  obj.projectiles.update(dt)
  dmgText.updateDamageNumberEvents(dt)
  gameUi.update(dt)
  obj.npc.updateAllNpcs(dt, util.world, obj.player, obj.npc.npcList, gunlib.gunlist)

  util.world:update(dt)
end -- }}}

function love.draw() -- {{{
  -- draw everything whose screen position should move with the camera
  -- (everything in the world, essentially)
  cam.set()
  obj.playfield.draw()
  obj.player.draw()
  obj.npc.drawAllNpcs()
  dmgText.drawDamageNumberEvents(obj.npc.npcList)

  -- draw existing bullets and other projectiles
  obj.projectiles.draw()

  -- draw effects (explosions, impacts, etc)

  -- camera-affected debug rendering -- {{{
  if arg[2] == 'debug' then
    -- -- the body
    love.graphics.setColor(obj.player.color)
    love.graphics.circle("line", obj.player.body:getX(), obj.player.body:getY(), obj.player.hardbox.shape:getRadius())
    --
    -- -- the eyes
    -- love.graphics.setColor(0,0,0)
    local eyePos1X, eyePos1Y = obj.player.body:getLocalCenter()
    eyePos1X, eyePos1Y = obj.player.body:getWorldPoint(eyePos1X - 3, eyePos1Y - 5)
    local eyePos2X, eyePos2Y = obj.player.body:getLocalCenter()
    eyePos2X, eyePos2Y = obj.player.body:getWorldPoint(eyePos2X + 3, eyePos2Y - 5)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", eyePos1X, eyePos1Y, 3)
    love.graphics.circle("fill", eyePos2X, eyePos2Y, 3)

    -- the reach circle
    if not obj.player.ragdoll then
      love.graphics.setColor(0,0,20,1)
      love.graphics.circle("line", obj.player.body:getX(), obj.player.body:getY(), obj.player.reach.shape:getRadius())
    end

    if obj.player.grab then
      local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.hardbox.fixture, obj.player.grab.fixture)
      love.graphics.setColor(0, .5, 0, 0.3)
      if obj.player.grab.x ~= nil and obj.player.grab.y ~= nil then
        love.graphics.circle("fill", obj.player.grab.x, obj.player.grab.y, 4)
      end

      if obj.player.grab.normalX ~= nil and obj.player.grab.y ~= nil then
        -- We also get the surface normal of the edge the ray hit. Here drawn in green
        love.graphics.setColor(0, 255, 0)
        love.graphics.line(obj.player.grab.x, obj.player.grab.y, obj.player.grab.x + obj.player.grab.normalX * 25, obj.player.grab.y + obj.player.grab.normalY * 25)
        -- print(tostring(debugRayNormalX).." / "..tostring(debugRayNormalY))
      end
      love.graphics.setColor(.95, .65, .25, .3)
      love.graphics.circle("fill", x1, y1, 4)
      love.graphics.setColor(.95, .65, .77, .6)
      love.graphics.circle("fill", x2, y2, 4)

      -- contact points of two colliding fixtures, whatever that actually means
      love.graphics.setColor(.95, 0, .25, .7)
      love.graphics.circle("fill", obj.player.grab.p.x1, obj.player.grab.p.y1, 4)
      if obj.player.grab.p.x2 then --not always second point
        love.graphics.circle("fill", obj.player.grab.p.x2, obj.player.grab.p.y2, 4)
      end
    end
  end
  -- }}}

  cam.unset()

  -- draw everything that doesn't move with the camera
  -- (HUD, other UI elements, etc)
  gameUi.draw(obj.player, gunlib.gunlist)

  -- non-camera affected debug rendering {{{
  if arg[2] == 'debug' then


    -- gun debug
    local gunNameDebugList = ""
    for _, gunId in pairs(obj.player.guns) do
      gunNameDebugList = gunNameDebugList.."["..gunId.."]"..gunlib.gunlist[gunId].name.." ("..string.format("%.2f",gunlib.gunlist[gunId].current.cooldown)..")"..", "
    end

    -- various debug info
    -- top left debug info
    love.graphics.setColor(1, 1, 1)
    local spoodCurrentLinearVelocityX, spoodCurrentLinearVelocityY = obj.player.body:getLinearVelocity()
    local spoodCurrentLinearVelocity = math.sqrt((spoodCurrentLinearVelocityX^2) + (spoodCurrentLinearVelocityY^2))
    love.graphics.print("spooder velocity, x/y/total/angular: "..string.format("%.2f", spoodCurrentLinearVelocityX).." / "..string.format("%.2f", spoodCurrentLinearVelocityY).." / "..string.format("%.2f", spoodCurrentLinearVelocity).." / "..string.format("%.2f", obj.player.body:getAngularVelocity()))
    love.graphics.print("grabbing? "..tostring(obj.player.grab), 0, 20)
    love.graphics.print("world-relative aim angle (0 = directly down, pi = directly up): "..string.format("%.2f", obj.player.currentAimAngle), 0, 40)
    -- love.graphics.print("current guns: "..gunNameDebugList, 0, 60) -- commenting out bc hud shows this info now
    love.graphics.print("camera position x/y/xtarget/ytarget: "..string.format("%.2f", cam.x).." / "..string.format("%.2f", cam.y).." / "..(cam.targetXPos or "nil").." / "..(cam.targetYPos or "nil"), 0, 60)
    love.graphics.setColor(0, .75, .25)
    if obj.player.grab then
      local distance, x1, y1, x2, y2 = love.physics.getDistance(obj.player.hardbox.fixture, obj.player.grab.fixture)
      love.graphics.print("distance between hardbox and closest fixture and their closest points (displayed in orange): "..tostring(math.floor(distance))..", ("..tostring(math.floor(x1))..", "..tostring(math.floor(y1))..") / ("..tostring(math.floor(x2))..", "..tostring(math.floor(y2))..")", 0, 80)
    end
    if obj.player.ungrabGraceTimer <= 0 then love.graphics.setColor(.75, .05, .05, 1) end
    love.graphics.print("leave-grab grace timer: "..obj.player.ungrabGraceTimer, 0, 100)

    love.graphics.setColor(0.75, .05, .05)
    if obj.player.dashTimer <= 0 and obj.player.dashUsed == false then love.graphics.setColor(0, .75, .25, 1) end
    love.graphics.print("dash cooldown timer: "..obj.player.dashTimer, 0, 120)

    -- bottom left debug info
    local windowSizeX, windowSizeY = love.graphics.getDimensions()
    love.graphics.setColor(1,1,1)
    love.graphics.print("world coordinates x/y: "..string.format("%.2f",obj.player.body:getX()).." / "..string.format("%.2f",obj.player.body:getY()), 0, windowSizeY - 20)
    love.graphics.print("FPS over last second: "..tostring(love.timer.getFPS()), 0, windowSizeY - 40)
  end

  -- }}}
end  -- }}}

-- physics collision callbacks {{{

function beginContact(a, b, contact) -- {{{
  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- if climbable terrain comes in range of spooder's reach...
  if (fixtureAUserData.name == "reach" and (fixtureBUserData.type == "terrain" or fixtureBUserData.type == "terrain_bg")) or (fixtureBUserData.name == "reach" and (fixtureAUserData.type == "terrain" or fixtureAUserData.type == "terrain_bg")) then
    -- ...then add the terrain to the cache of terrain items in latching range
    obj.player.handleTerrainEnteringRange(a, b, contact)
  end
end -- }}}

function endContact(a, b, contact) -- {{{
  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- when climbable terrain leaves range of spooder's reach...
  if (fixtureAUserData.name == "reach" and (fixtureBUserData.type == "terrain" or fixtureBUserData.type == "terrain_bg")) or (fixtureBUserData.name == "reach" and (fixtureAUserData.type == "terrain" or fixtureAUserData.type == "terrain_bg")) then
    -- ...remove the terrain from the cache of terrain items in latching range
    obj.player.handleTerrainLeavingRange(a, b, contact)
  end
end -- }}}

function preSolve(a, b, contact) -- {{{
  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()
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

  -- projectile impact handling
  if fixtureAUserData.type == "projectile" or fixtureBUserData.type == "projectile" then
    obj.projectiles.handleProjectileCollision(a, b, contact, obj.npc.npcList, obj.player)
  end
end -- }}}

function postSolve(a, b, contact, normalimpulse, tangentimpulse) -- {{{
end -- }}}

-- }}}

-- vim: foldmethod=marker
