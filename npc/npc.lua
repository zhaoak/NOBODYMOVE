local util = require("util")
local filterValues = require("filterValues")

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

-- Create a new NPC instance, give it a UID, and add it to the list of NPCs in the world. Returns the new npc's UID.
-- This constructor is also called by the enemy and friendly constructors, since they are extended from the npc class.
-- Arguments:
-- initialXPos, initialYPos (numbers, required): initial X and Y positions of the NPC in the world.
-- physicsData(table): all data needed to initialize the npc in the world using Box2D.
-- Table format:
-- { 
--    body (table): table containing all data for setting Box2D body properties of npc. See https://www.love2d.org/wiki/Body
--    Table format:
--    {
--      angularDamping (number, default=0): angular damping value
--      fixedRotation (bool, default=false): whether the body should ever rotate or not
--      gravityScale (number, default=1): how much the body should be affected by gravity
--      inertia (number, default=generated by Box2D): the body's inertia
--      linearDamping (number, default=0): linear damping value
--      mass (number, default=generated from shape data by Box2D): how thicc the npc is
--    },
--    shape (table): table containing all data for setting Box2D shape properties of npc. See https://www.love2d.org/wiki/Shape
--    Table format:
--    {
--      shapeType (string, default="circle"): must be one of "circle", "polygon", "rectangle". What type of hitbox the enemy should have.
--      ADDITIONAL REQUIRED KEYS/VALUES FOR shapeType="circle":
--        radius (number, default=20): radius of circle hitbox of npc
--      ADDITIONAL REQUIRED KEYS/VALUES FOR shapeType="polygon":
--        a table `points` containing: {x1, y1, x2, y2, x3...} and so on: the points of the polygon shape. max 8 vertices, must form a convex shape.
--      ADDITIONAL REQUIRED KEYS/VALUES FOR shapeType="rectangle:
--        width, height: width and height of rectangle shape
--    },
--    fixture (table): table containing all data for setting Box2D fixture properties of npc. See https://www.love2d.org/wiki/Shape
--    Table format:
--    {
--      density (number, default=1): the fixture's density in kg/square meter
--      friction (number 0.0-1.0, default=~0.2 apparently, 1=max friction, 0=min friction): how much friction the npc generates when bumping and grinding
--      restitution (number, default=0): multiplier for bounciness, so 0=lose all velocity on collision, 1=retain all velocity, >1=GAIN velocity on collision
--    }
-- }
-- userDataTable (table): table containing userdata to set for npc.
-- Table format:
-- {
--    name (string, required): name property to set in userdata
--    team (string, required): who the npc is allied to, relative to the player. Must be one of: "friendly", "enemy", "neutral"
--    health (number, required): how much health to give this npc
-- }
-- spriteData (table): sprite data. we don't have art yet so i'll get back to this
function M:constructor(initialXPos, initialYPos, physicsData, userDataTable, spriteData) -- {{{
  -- set default values
  physicsData = physicsData or {
    body={angularDamping=0,fixedRotation=false,gravityScale=1,linearDamping=0},
    shape={shapeType="circle",radius=20},
    fixture={restitution=0,density=1}
  }
  userDataTable = userDataTable or {
    {name="someone forgot to name me",team="enemy",health=100}
  }

  -- create physics objects for new npc
  self.body = love.physics.newBody(util.world, initialXPos, initialYPos, "dynamic")
  if physicsData.shape.shapeType == "circle" then
    self.shape = love.physics.newCircleShape(physicsData.shape.radius)
  elseif physicsData.shape.shapeType == "polygon" then
    self.shape = love.physics.newPolygonShape(unpack(physicsData.shape.points))
  elseif physicsData.shape.shapeType == "rectangle" then
    self.shape = love.physics.newRectangleShape(physicsData.shape.width, physicsData.shape.height)
  end
  self.fixture = love.physics.newFixture(self.body, self.shape, physicsData.fixture.density)

  if physicsData.body.angularDamping ~= nil then self.body:setAngularDamping(physicsData.body.angularDamping) end
  if physicsData.body.fixedRotation ~= nil then self.body:setFixedRotation(physicsData.body.fixedRotation) end
  if physicsData.body.gravityScale ~= nil then self.body:setGravityScale(physicsData.body.gravityScale) end
  if physicsData.body.inertia ~= nil then self.body:setInertia(physicsData.body.inertia) end
  if physicsData.body.linearDamping ~= nil then self.body:setLinearDamping(physicsData.body.linearDamping) end
  if physicsData.body.mass ~= nil then self.body:setMass(physicsData.body.mass) end
  if physicsData.fixture.density ~= nil then self.fixture:setDensity(physicsData.fixture.density) end
  if physicsData.fixture.restitution ~= nil then self.fixture:setRestitution(physicsData.fixture.restitution) end
  if physicsData.fixture.friction ~= nil then self.fixture:setFriction(physicsData.fixture.friction) end

  -- set collision filter data
  if userDataTable.team == "enemy" then
    self.fixture:setCategory(filterValues.category.enemy)
    self.fixture:setMask(filterValues.category.enemy, filterValues.category.projectile_enemy)
    self.fixture:setGroupIndex(0)
  elseif userDataTable.team == "friendly" then
    self.fixture:setCategory(filterValues.category.friendly)
    self.fixture:setMask(filterValues.category.friendly, filterValues.category.projectile_player)
    self.fixture:setGroupIndex(0)
  elseif userDataTable.team == "neutral" then
    self.fixture:setCategory(filterValues.category.neutral)
    self.fixture:setMask()
    self.fixture:setGroupIndex(0)
  end

  -- generate and assign a UID and userdata, then add npc to npc list
  self.uid = util.gen_uid("npc")
  self.fixture:setUserData{name = userDataTable.name, type = "npc", team = userDataTable.team, health = userDataTable.health, uid = self.uid}
  M.npcList[self.uid] = self

  return self.uid
end -- }}}

function M:getX()
  return self.body:getX()
end

function M:getY()
  return self.body:getY()
end

function M:draw()
  love.graphics.setColor(0.8, 0.3, 0.24, 1)
  love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
end

-- damages NPC's health by damageAmount and triggers their pain animation.
-- Can accept negative values to heal, but will still trigger pain animation.
function M:hurt(damageAmount)
  local newUserData = self.fixture:getUserData()
  newUserData.health = newUserData.health - damageAmount
  -- also trigger pain animation (we odn't have those yet)
end

function M.drawAllNpcs()
  for uid, npc in pairs(M.npcList) do
    npc:draw()
  end
end

return M
-- vim: foldmethod=marker