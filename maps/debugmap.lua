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

  M.world = world

  local width = 3000
  local height = 1080

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

M.draw = function() -- {{{
  -- draw borders
  love.graphics.setColor(M.color)
  love.graphics.line(M.body:getWorldPoints(M.top.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.bottom.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.left.shape:getPoints()))
  love.graphics.line(M.body:getWorldPoints(M.right.shape:getPoints()))
end -- }}}

return M
-- vim: foldmethod=marker
