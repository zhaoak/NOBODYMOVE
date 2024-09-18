local M = {}

M.physicsData = {
  body = {
    angularDamping = 0,
    fixedRotation = false,
    gravityScale = 1,
    linearDamping = 0,
    mass = 4
  },
  shape = {
    shapeType = "rectangle",
    width = 50,
    height = 50
  },
  fixture = {
    density = 1,
    restitution = 0.1,
    friction = 0.95
  }
}

M.userDataTable = {
  name = "Lazy Turret",
  health = 200,
  aiCycleInterval = 0.5 -- run ai function every 0.5 seconds
}

M.aiCycle = function(self, world, playerObj, npcList)
  -- find shortest route between player and self
  local distance, playerX, playerY, selfX, selfY = love.physics.getDistance(playerObj.hardbox.fixture, self.fixture)
  -- cast a ray to see if there's anything in the way
  print("eyyy")
  -- if there is, do nothing

  -- otherwise, aim and shoot at player's current position
end

M.guns = {}

return M
