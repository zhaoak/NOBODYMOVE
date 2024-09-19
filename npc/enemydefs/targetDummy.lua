local M = {}

M.physicsData = {
  body = {
    angularDamping = 0,
    fixedRotation = false,
    gravityScale = 1,
    linearDamping = 0,
    mass = 2
  },
  shape = {
    shapeType = "rectangle",
    width = 50,
    height = 75
  },
  fixture = {
    density = 1,
    restitution = 0.3,
    friction = 0.75
  }
}

M.userDataTable = {
  name = "Target Dummy",
  health = 9999,
  aiCycleInterval = 1
}

M.spriteData = nil

M.aiCycle = function()
  return nil
end

M.guns = {}

return M
