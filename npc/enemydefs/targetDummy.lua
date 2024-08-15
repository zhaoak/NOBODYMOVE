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

M.name = "Target Dummy"

M.spriteData = nil

return M
