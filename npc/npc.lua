local util = require("util")

-- defining a class for all NPCs
local M = { }

M.__index = M
M.npcList = {}

setmetatable(M, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:constructor(...)
    return self
  end,
})

-- Create a new NPC instance, give it a UID, and add it to the list of NPCs in the world.
-- This constructor is also called by the enemy and friendly constructors, since they are extended from the npc class.
-- Arguments:
-- initialXPos, initialYPos (numbers): initial X and Y positions of the NPC in the world.
-- physicsData(table): all data needed to initialize the npc in the world using Box2D. Format of the table:
--   { 
--     shapeType (string): must be one of "circle", "polygon", "rectangle". Determines the size/shape of the enemy's hitbox.
function M:constructor(initialXPos, initialYPos, physicsData, userDataTable, filterDataTable)
  self.body = love.physics.newBody(util.world, initialXPos, initialYPos, "dynamic")
  self.shape = love.physics.newCircleShape(50)
  self.fixture = love.physics.newFixture(self.body, self.shape, 1)
  self.fixture:setUserData{name = "dummy", type = "npc"}
  self.uid = util.gen_uid("npc")
  M.npcList[self.uid] = self
end

function M:draw()
  love.graphics.setColor(0.8, 0.3, 0.24, 1)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
end

function M:drawAllNpcs()
  for uid, npc in pairs(M.npcList) do
    npc:draw()
  end
end

return M
-- vim: foldmethod=marker
