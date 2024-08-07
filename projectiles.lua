local M = { }
local projectileList = {}

-- {{{ defines
M.bulletRadius = 2 -- how wide radius of bullet hitbox is
M.bulletLaunchVelocity = 10 -- muzzle velocity of bullet projectiles
-- }}}

M.setup = function(world) -- {{{
  -- cache world for later
  M.world = world
end -- }}}

M.createHitscanShot = function(gun, shotWorldOriginX, shotWorldOriginY, worldRelativeAimAngle)
  
end

M.createBulletShot = function(gun, shotWorldOriginX, shotWorldOriginY, worldRelativeAimAngle)
  local newProjectiles = {}
  for i = 1, gun.multishot do
    -- create physics object for new bullet
    local newBullet = {}
    newBullet.body = love.physics.newBody(M.world, shotWorldOriginX, shotWorldOriginY, "dynamic")
    newBullet.shape = love.physics.newCircleShape(M.bulletRadius)
    newBullet.fixture = love.physics.newFixture(newBullet.body, newBullet.shape, 1)
    newBullet.fixture:setUserData({name="bullet",type="projectile_bullet"})
    newBullet.body:setBullet(true)
    newBullet.body:setGravityScale(0)
    table.insert(newProjectiles, newBullet)

    -- calculate shot angle and randomness, apply forces to bullet
    local bulletVelocityX = math.sin(worldRelativeAimAngle)*M.bulletLaunchVelocity
    local bulletVelocityY = math.cos(worldRelativeAimAngle)*M.bulletLaunchVelocity
    newBullet.body:applyLinearImpulse(bulletVelocityX, bulletVelocityY)
  end

  for _, bullet in ipairs(newProjectiles) do
    table.insert(projectileList, bullet)
  end
end

M.draw = function() -- {{{
  for i, proj in pairs(projectileList) do
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.circle("fill", proj.body:getX(), proj.body:getY(), M.bulletRadius)
  end
end -- }}}

-- for checking timed explosives, other effects
M.update = function (dt)
  for i, proj in pairs(projectileList) do
    -- print(proj.fixture:getUserData())
  end
end

return M
-- vim: foldmethod=marker
