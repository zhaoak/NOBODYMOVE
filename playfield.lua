local util = require'util'
local filterVals = require'filterValues'

local M = { }


M.color = {1,1,1,1}

local function addLine(x1,y1, x2,y2) -- {{{
  local line = {}
  line.shape = love.physics.newEdgeShape(x1,y1, x2,y2)
  line.fixture = love.physics.newFixture(M.body, line.shape)
  return line
end -- }}}

M.setup = function (world) -- {{{
  M.fixtureUIDCounter = 0

  M.world = world -- stash for laters
  -- create the lines with the current window size
  M.resize(love.graphics.getDimensions())

  -- create tilted platform
  local windowSizeX, windowSizeY = love.graphics.getDimensions()
  M.tiltedPlatform = {}
  M.tiltedPlatform.shape = love.physics.newRectangleShape(windowSizeX/3, windowSizeY/2, windowSizeX/3, windowSizeY/5, 50)
  M.tiltedPlatform.fixture = love.physics.newFixture(M.body, M.tiltedPlatform.shape)
  M.tiltedPlatform.fixture:setUserData{name = "tiltedplatform", type = "terrain", uid = util.gen_uid("terrain")}
  M.tiltedPlatform.fixture:setCategory(filterVals.category.terrain)
  M.tiltedPlatform.fixture:setMask()
  M.tiltedPlatform.fixture:setGroupIndex(0)

  -- more testing platforms
  M.platform2 = {}
  M.platform2.shape = love.physics.newRectangleShape(200, 400, 100, 200, 0)
  M.platform2.fixture = love.physics.newFixture(M.body, M.platform2.shape)
  M.platform2.fixture:setUserData{name = "platform2", type = "terrain", uid = util.gen_uid("terrain")}
  M.platform2.fixture:setCategory(filterVals.category.terrain)
  M.platform2.fixture:setMask()
  M.platform2.fixture:setGroupIndex(0)

  -- testing circle
  M.circle = {}
  M.circle.shape = love.physics.newCircleShape(600, 400, 50)
  M.circle.fixture = love.physics.newFixture(M.body, M.circle.shape)
  M.circle.fixture:setUserData{name = "circle", type = "terrain", uid = util.gen_uid("terrain")}
  M.circle.fixture:setCategory(filterVals.category.terrain)
  M.circle.fixture:setMask()
  M.circle.fixture:setGroupIndex(0)
end -- }}}

M.draw = function() -- {{{
  -- draw borders
  love.graphics.setColor(M.color)
  love.graphics.line(M.body:getWorldPoints(M.top.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.bottom.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.left.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.right.shape:getPoints()))

  -- draw tilted platform
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
  drawRotatedRectange("line", topLeftWorldPointX, topLeftWorldPointY, windowSizeX/3, windowSizeY/5, 50)

  -- draw other platforms
  love.graphics.polygon("line", M.body:getWorldPoints(M.platform2.shape:getPoints()))
  local circleX, circleY = M.circle.shape:getPoint()
  love.graphics.circle("line", circleX, circleY, M.circle.shape:getRadius())
end -- }}}

-- playfield utility functions {{{

M.resize = function(width, height) -- {{{
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
end -- }}}


-- }}}
return M
-- vim: foldmethod=marker
