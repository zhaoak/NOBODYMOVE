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
  health = 999999999
}

M.spriteData = nil

return M
