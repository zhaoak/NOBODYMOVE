local util = require'util'
local filterVals = require'filterValues'
local npc = require'npc.npc'
local enemy = require'npc.enemy'
local targetDummy = require'npc.enemydefs.targetDummy'

local M = { }

M.color = {0.5,0.5,0.5,1}

local width = 3000
local height = 2000

local function addLine(x1,y1, x2,y2) -- {{{
  local line = {}
  line.shape = love.physics.newEdgeShape(x1,y1, x2,y2)
  line.fixture = love.physics.newFixture(M.body, line.shape)
  return line
end -- }}}

M.setup = function (world) -- {{{
  M.fixtureUIDCounter = 0

  M.world = world

  if M.body then M.body:destroy() end

  M.body = love.physics.newBody(M.world, 0,0, "static")

  M.top = addLine(0,0, width,0)
  M.top.fixture:setUserData{name = "topborder", type = "terrain", uid = util.gen_uid("terrain")}
  M.top.fixture:setCategory(filterVals.category.terrain)
  M.top.fixture:setMask()
  M.top.fixture:setGroupIndex(0)

  M.bottom = addLine(0,height, width,height)
  M.bottom.fixture:setUserData{name = "bottomborder", type = "terrain", uid = util.gen_uid("terrain")}
  M.bottom.fixture:setCategory(filterVals.category.terrain)
  M.bottom.fixture:setMask()
  M.bottom.fixture:setGroupIndex(0)

  M.left = addLine(0,0, 0,height)
  M.left.fixture:setUserData{name = "leftborder", type = "terrain", uid = util.gen_uid("terrain")}
  M.left.fixture:setCategory(filterVals.category.terrain)
  M.left.fixture:setMask()
  M.left.fixture:setGroupIndex(0)

  M.right = addLine(width,0, width,height)
  M.right.fixture:setUserData{name = "rightborder", type = "terrain", uid = util.gen_uid("terrain")}
  M.right.fixture:setCategory(filterVals.category.terrain)
  M.right.fixture:setMask()
  M.right.fixture:setGroupIndex(0)

  M.tiltedPlatform = {}
  M.tiltedPlatform.shape = love.physics.newRectangleShape(width/5, height*0.8, width/3, height*0.5, math.rad(30))
  M.tiltedPlatform.fixture = love.physics.newFixture(M.body, M.tiltedPlatform.shape)
  M.tiltedPlatform.fixture:setUserData{name = "tiltedplatform", type = "terrain", uid = util.gen_uid("terrain")}
  M.tiltedPlatform.fixture:setCategory(filterVals.category.terrain)
  M.tiltedPlatform.fixture:setMask()
  M.tiltedPlatform.fixture:setGroupIndex(0)

  M.circle = {}
  M.circle.shape = love.physics.newCircleShape(width*0.75, height*0.5, 200)
  M.circle.fixture = love.physics.newFixture(M.body, M.circle.shape)
  M.circle.fixture:setUserData{name = "circle", type = "terrain", uid = util.gen_uid("terrain")}
  M.circle.fixture:setCategory(filterVals.category.terrain)
  M.circle.fixture:setMask()
  M.circle.fixture:setGroupIndex(0)

  M.polygon = {}
  M.polygon.shape = love.physics.newPolygonShape(width*0.2,0, width*0.25,height*0.15, width*0.4,height*0.3, width*0.45,height*0.5, width*0.5,height*0.3, width*0.65,height*0.15, width*0.7,0, width*0.2,0)
  M.polygon.fixture = love.physics.newFixture(M.body, M.polygon.shape)

  M.polygon.fixture:setUserData{name = "polygon", type = "terrain", uid = util.gen_uid("terrain")}
  M.polygon.fixture:setCategory(filterVals.category.terrain)
  M.polygon.fixture:setMask()
  M.polygon.fixture:setGroupIndex(0)

  M.climbableBg = {}
  M.climbableBg.shape = love.physics.newRectangleShape(1600, height-800, width*0.2, height*0.3, 0)
  M.climbableBg.fixture = love.physics.newFixture(M.body, M.climbableBg.shape)
  M.climbableBg.fixture:setUserData{name = "climbableBg", type = "terrain_bg", uid = util.gen_uid("terrain")}
  M.climbableBg.fixture:setCategory(filterVals.category.terrain_bg)
  M.climbableBg.fixture:setMask(filterVals.category.player_hardbox)
  M.climbableBg.fixture:setGroupIndex(0)

  M.dummyNpcUid = enemy(2000, 200, targetDummy.physicsData, targetDummy.userDataTable, targetDummy.spriteData)
end -- }}}

M.draw = function() -- {{{
  -- draw borders
  love.graphics.setColor(M.color)
  love.graphics.line(M.body:getWorldPoints(M.top.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.bottom.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.left.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.right.shape:getPoints()))

  -- draw platforms
  local platformTopLeftPointX, platformTopLeftPointY = M.tiltedPlatform.shape:getPoints()
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  local topLeftWorldPointX, topLeftWorldPointY = M.body:getWorldPoints(platformTopLeftPointX, platformTopLeftPointY)
  local function drawRotatedRectange(mode, x, y, width, height, angle)
    -- We cannot rotate the rectangle directly, but we
    -- can move and rotate the coordinate system.
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.rectangle(mode, 0, 0, width, height) -- origin in the top left corner
    love.graphics.pop()
  end
  drawRotatedRectange("fill", topLeftWorldPointX, topLeftWorldPointY, width/3, height*0.5, math.rad(30))

  local circleX, circleY = M.circle.shape:getPoint()
  love.graphics.circle("fill", circleX, circleY, M.circle.shape:getRadius())

  love.graphics.polygon("fill", M.body:getWorldPoints(M.polygon.shape:getPoints()))

  love.graphics.polygon("line", M.body:getWorldPoints(M.climbableBg.shape:getPoints()))
end -- }}}

return M
-- vim: foldmethod=marker
