local gunlib = require("guns")
local aiUtils = require("npc.ai.utilities")

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

M.spriteData = nil

M.aiCycle = function(self, world, playerObj, npcList)
  -- this enemy:
  --   - only shoots if it has a clear shot to the player
  --   - shoots once every update where it has a clear shot

  -- check if we can see the player
  if aiUtils.canSeePlayer(self, world, playerObj) then
    print("i see uu!!!!")
  else
    print("no see u :(")
  end
end

M.guns = {gunlib.createGunFromDefinition("burstpistol_medcal")}

return M
