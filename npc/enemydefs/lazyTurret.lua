local gunlib = require("guns")

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
  local terrainFract = 1
  local playerFract = 0
  -- this callback func is called during raycast, when the ray hits any fixture
  -- BTW THE CALLBACKS AREN'T ORDERED, the ray could hit a farther fixture before a closer one
  local rayHitCallback = function(fixture, x, y, xn, yn, fraction)
    if fixture:getUserData().type == "terrain" then
      if terrainFract > fraction then terrainFract = fraction end
      return -1
    end
    if fixture:getUserData().type == "player_hardbox" then
      playerFract = fraction
      return -1
    end
    return -1
  end
  -- cast a ray to see if there's any shot-blocking terrain in the way
  world:rayCast(self:getX(), self:getY(), playerObj.getX(), playerObj.getY(), rayHitCallback)
  -- if we have an unobstructed shot, shoot your gun
  if playerFract > terrainFract then
    print("no see u :(")
  else
    print("i see uu!!!!")
  end
end

M.guns = {gunlib.createGunFromDefinition("burstpistol_medcal")}

return M
