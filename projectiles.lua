local M = { }

M.projectileList = {}

local util = require'util'

-- {{{ defines
M.bulletRadius = 5 -- how wide radius of bullet hitbox is
M.bulletLaunchVelocity = 300 -- muzzle velocity of bullet projectiles
M.bulletMass = 0.2
-- }}}

M.setup = function(world) -- {{{
  -- cache world for later
  M.world = world
end -- }}}

-- create projectile functions {{{
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
    newBullet.fixture:setUserData({name="bullet",type="projectile", uid=util.gen_uid()})
    newBullet.fixture:setRestitution(0)
    newBullet.body:setBullet(true)
    newBullet.body:setGravityScale(0)
    newBullet.body:setMass(M.bulletMass)
    table.insert(newProjectiles, newBullet)

    -- calculate shot angle and randomness, apply forces to bullet
    local bulletVelocityX = math.sin(worldRelativeAimAngle)*M.bulletLaunchVelocity
    local bulletVelocityY = math.cos(worldRelativeAimAngle)*M.bulletLaunchVelocity
    newBullet.body:applyLinearImpulse(bulletVelocityX, bulletVelocityY)
  end

  for _, bullet in ipairs(newProjectiles) do
    M.projectileList[bullet.fixture:getUserData().uid] = bullet
  end
end
-- }}}

-- projectile collision handling {{{
M.handleProjectileCollision = function(a, b, contact)
  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()
  -- determine which of the fixtures is the projectile
  if fixtureAUserData.type == "projectile" and fixtureBUserData.type ~= "projectile" then
    -- fixture A is projectile
    if fixtureBUserData.type == "terrain" then
      -- TODO: create impact decal/animation at terrain location
      -- then delete bullet from world and projectile list (unless it's a bouncy kind but stay basic for now)
      M.projectileList[fixtureAUserData.uid] = nil
      a:getBody():destroy()
    end
  elseif fixtureBUserData.type == "projectile" and fixtureAUserData.type ~= "projectile" then
    -- fixture B is projectile
    if fixtureAUserData.type == "terrain" then
      -- TODO: create impact decal/animation at terrain location
      -- then delete bullet from world (unless it's a bouncy kind but stay basic for now)
      M.projectileList[fixtureBUserData.uid] = nil
      b:getBody():destroy()
    end
  else
    -- both A and B are projectiles

  end
end
-- }}}

M.draw = function() -- {{{
  for i, proj in pairs(M.projectileList) do
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.circle("fill", proj.body:getX(), proj.body:getY(), M.bulletRadius)
  end
end -- }}}

-- for checking timed explosives, other effects
M.update = function (dt)
  for i, proj in pairs(M.projectileList) do
    -- print(proj.fixture:getUserData())
  end
end

return M
-- vim: foldmethod=marker
