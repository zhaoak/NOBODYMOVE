local M = {}

M.physicsData = {
  body = {
    angularDamping = 1,
    fixedRotation = true,
    gravityScale = 2,
    linearDamping = 1
  },
  shape = {
    shapeType = "rectangle",
    width = 100,
    height = 100
  },
  fixture = {
    density = 1,
    restitution = 0,
    friction = 1
  }
}

M.userDataTable = {
  name = "Target Dummy",
  health = 999999999
}

M.spriteData = nil

return M
