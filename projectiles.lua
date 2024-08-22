local M = { }

M.projectileList = {}

local util = require'util'
local filterVals = require'filterValues'
local npc = require'npc.npc'
local dmgText = require'ui.damageNumbers'

-- {{{ defines
M.bulletRadius = 5 -- how wide radius of bullet hitbox is
M.bulletMass = 0.2
-- if a bullet is traveling less than this fast in on the X or Y axis,
-- it will be destroyed that frame
M.bulletDestructionVelocityThreshold = 250
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
    newBullet.fixture:setUserData({name="bullet",type="projectile",damage=gun.hitDamage,firedFrom=gun.uid,uid=util.gen_uid("projectile")})
    newBullet.fixture:setRestitution(0)
    newBullet.body:setBullet(true)
    newBullet.body:setGravityScale(0)
    newBullet.body:setMass(M.bulletMass)

    -- set filterdata for new bullet
    -- currently, player-fired projectiles never collide with each other, but we may change that
    -- because core nukes are cool

    -- this bullet has the category:
    newBullet.fixture:setCategory(filterVals.category.projectile_player)
    -- this bullet should NOT collide with:
    newBullet.fixture:setMask(
      filterVals.category.friendly,
      filterVals.category.player_hardbox,
      filterVals.category.projectile_player,
      filterVals.category.terrain_bg)

    -- this bullet is in group:
    newBullet.fixture:setGroupIndex(0)

    -- adjust shot angle to account for gun inaccuracy
    local rand = math.random()
    -- give us a random modifier for the shot angle from -1*gun.inaccuracy to 1*gun.inaccuracy
    local inaccuracyAngleAdjustment = gun.inaccuracy - (rand * gun.inaccuracy * 2)
    -- print(inaccuracyAngleAdjustment)
    -- then, apply the inaccuracy modifier and recoil modifier to the angle of the shot
    local adjustedShotAngle = worldRelativeAimAngle + inaccuracyAngleAdjustment + gun.current.recoilAimPenaltyOffset

    -- apply velocity to bullet
    local bulletVelocityX = math.sin(adjustedShotAngle)*gun.projectileLaunchVelocity
    local bulletVelocityY = math.cos(adjustedShotAngle)*gun.projectileLaunchVelocity
    newBullet.body:applyLinearImpulse(bulletVelocityX, bulletVelocityY)

    -- apply projectile's linear damping
    newBullet.body:setLinearDamping(gun.projectileLinearDamping)

    table.insert(newProjectiles, newBullet)
  end

  for _, bullet in ipairs(newProjectiles) do
    M.projectileList[bullet.fixture:getUserData().uid] = bullet
  end
end
-- }}}

M.hitctr = 0
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
    elseif fixtureBUserData.type == "npc" and fixtureBUserData.team == "enemy" then
      -- deal damage, destroy the projectile, and update damage numbers
      dmgText.damageNumberEvent(fixtureAUserData.damage, fixtureBUserData.uid)
      npc.npcList[fixtureBUserData.uid]:hurt(fixtureAUserData.damage)
      M.projectileList[fixtureAUserData.uid] = nil
      M.hitctr = M.hitctr + 1
      print(M.hitctr )
      a:getBody():destroy()
    end

  elseif fixtureBUserData.type == "projectile" and fixtureAUserData.type ~= "projectile" then
    -- fixture B is projectile
    if fixtureAUserData.type == "terrain" then
      -- TODO: create impact decal/animation at terrain location
      -- then delete bullet from world (unless it's a bouncy kind but stay basic for now)
      M.projectileList[fixtureBUserData.uid] = nil
      b:getBody():destroy()
    elseif fixtureAUserData.type == "npc" and fixtureAUserData.team == "enemy" then
      -- deal damage, destroy projectile, update damage numbers
      dmgText.damageNumberEvent(fixtureBUserData.damage, fixtureAUserData.uid)
      npc.npcList[fixtureAUserData.uid]:hurt(fixtureBUserData.damage)
      M.projectileList[fixtureBUserData.uid] = nil
      M.hitctr = M.hitctr + 1
      print("hit!!")
      b:getBody():destroy()
    end
  else
    -- both A and B are projectiles
    print("ow!! the bullets are touching!!")
    contact:setEnabled(false)
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
    if proj.fixture:getUserData().name == "bullet" then
      -- if a bullet is travelling below a specific speed (see defines), destroy it
      local bulletLinearVelocityX, bulletLinearVelocityY = proj.body:getLinearVelocity()
      if bulletLinearVelocityX < M.bulletDestructionVelocityThreshold and 
         bulletLinearVelocityY < M.bulletDestructionVelocityThreshold and
         bulletLinearVelocityX > -M.bulletDestructionVelocityThreshold and
         bulletLinearVelocityY > -M.bulletDestructionVelocityThreshold then
        local bulletToDestroy = proj
        M.projectileList[proj.fixture:getUserData().uid] = nil
        bulletToDestroy.body:destroy()
      end
    end
    -- print(proj.fixture:getUserData())
  end
end

return M
-- vim: foldmethod=marker
