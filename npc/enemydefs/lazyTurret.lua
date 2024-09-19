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

  local hasClearShot = false
  -- this callback func is called during raycast, when the ray hits any fixture
  local rayHitCallback = function(fixture, x, y, xn, yn, fraction)
    if fixture:getUserData().type == "terrain" then
      return 0 -- returning 0 makes the raycast terminate
    elseif fixture:getUserData().type == "player_hardbox" then
      hasClearShot = true
      return 0
    else return -1 --returning -1 makes the raycast ignore this callback and continue
    end
  end
  -- cast a ray to see if there's any shot-blocking terrain in the way
  world:rayCast(self:getX(), self:getY(), playerObj.getX(), playerObj.getY(), rayHitCallback)
  -- if we have an unobstructed shot, shoot your gun
  if hasClearShot then
    print("i see uu!!!!")
  end
end

M.guns = {}

return M
