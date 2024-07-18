local M = { }

M.color = {1,1,1,1}

M.fixtureUIDCounter = 0

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
  M.tiltedPlatform.fixture:setUserData({["name"] = "tiltedplatform", ["type"] = "terrain"})
  M.assignFixtureUID(M.tiltedPlatform.fixture)
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
  drawRotatedRectange("fill", topLeftWorldPointX, topLeftWorldPointY, windowSizeX/3, windowSizeY/5, 50)
end -- }}}

-- playfield utility functions {{{

M.resize = function(width, height) -- {{{
  if M.body then M.body:destroy() end
  M.body = love.physics.newBody(M.world, 0,0, "static")

  M.top = addLine(0,0, width,0)
  M.top.fixture:setUserData({["name"] = "topborder", ["type"] = "terrain"})
  M.assignFixtureUID(M.top.fixture)
  M.bottom = addLine(0,height, width,height)
  M.bottom.fixture:setUserData({["name"] = "bottomborder", ["type"] = "terrain"})
  M.assignFixtureUID(M.bottom.fixture)
  M.left = addLine(0,0, 0,height)
  M.left.fixture:setUserData({["name"] = "leftborder", ["type"] = "terrain"})
  M.assignFixtureUID(M.left.fixture)
  M.right = addLine(width,0, width,height)
  M.right.fixture:setUserData({["name"] = "rightborder", ["type"] = "terrain"})
  M.assignFixtureUID(M.right.fixture)
end -- }}}

M.assignFixtureUID = function(fixture)
  local newFixtureUserData = fixture:getUserData()
  newFixtureUserData.uid = M.fixtureUIDCounter
  M.fixtureUIDCounter = M.fixtureUIDCounter + 1
  fixture:setUserData(newFixtureUserData)
end

-- }}}
return M
-- vim: foldmethod=marker
