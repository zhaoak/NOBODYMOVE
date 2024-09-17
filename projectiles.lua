-- Module for any projectiles spawned and/or shot by a gun.
-- Handles creating projectile physics objects, drawing projectiles, and resolving projectile collisions.

local M = { }

M.projectileList = {}

local util = require'util'
local filterVals = require'filterValues'

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

-- Projectiles are Box2D bodies with position, angle, and velocity,
-- plus any other Box2D properties a dynamic physics object has.
-- This function creates the projectiles from a single shoot projectile mod,
-- including any multishots if present.
-- args:
-- gunFiringProjectileUid(num): uid of gun firing these projectiles
-- projMod(mod): the mod table of the mod being fired
-- shotWorldOriginX(num): X world coordinate where the shot should spawn
-- shotWorldOriginY(num): Y world coordinate where the shot should spawn
-- worldRelativeAimAngle(num): angle the projectiles should travel towards, in radians
-- shotByTeam(string): which team the projectiles belong to, one of: "friendly", "enemy", "neutral"
M.createProjectile = function(gunFiringProjectileUid, projMod, shotWorldOriginX, shotWorldOriginY, worldRelativeAimAngle, shotByTeam)
  while projMod.bulletCount > 0 do
    -- create physics object for new projectile
    local newProj = {}
    newProj.body = love.physics.newBody(M.world, shotWorldOriginX, shotWorldOriginY, "dynamic")
    if projMod.shapeData.hitboxShape == "circle" then
      newProj.shape = love.physics.newCircleShape(projMod.shapeData.radius)
    end
    newProj.fixture = love.physics.newFixture(newProj.body, newProj.shape, 1)
    newProj.fixture:setUserData{
      name="projectile",
      type="projectile",
      team=shotByTeam,
      damage=projMod.projectileDamage,
      firedByGun=gunFiringProjectileUid,
      uid=util.gen_uid("projectile")
    }
    newProj.fixture:setRestitution(0)
    newProj.body:setBullet(true) -- this is Box2D's CCD (continuous collision detection) flag
    newProj.body:setGravityScale(projMod.gravityScale)
    newProj.body:setMass(projMod.mass)

    -- set filterdata for new projectile
    -- currently, player-fired projectiles never collide with each other, but we may change that
    -- because core nukes are cool

    -- this projectile has the category:
    newProj.fixture:setCategory(filterVals.category.projectile_player)
    -- this projectile should NOT collide with:
    newProj.fixture:setMask(
      filterVals.category.friendly,
      filterVals.category.player_hardbox,
      filterVals.category.projectile_player,
      filterVals.category.terrain_bg)

    -- this projectile is in group:
    newProj.fixture:setGroupIndex(0)

    -- adjust shot angle to account for gun inaccuracy
    local rand = math.random()
    -- give us a random modifier for the shot angle from -1*gun.inaccuracy to 1*gun.inaccuracy
    local inaccuracyAngleAdjustment = projMod.inaccuracy - (rand * projMod.inaccuracy * 2)
    -- print(inaccuracyAngleAdjustment)
    -- then, apply the inaccuracy modifier and recoil modifier to the angle of the shot
    -- we're dummying out the accuracy penalty on shot for now
    -- local adjustedShotAngle = worldRelativeAimAngle + inaccuracyAngleAdjustment + gun.current.recoilAimPenaltyOffset
    local adjustedShotAngle = worldRelativeAimAngle + inaccuracyAngleAdjustment


    -- apply velocity to projectile
    local projectileVelocityX = math.sin(adjustedShotAngle)*projMod.speed
    local projectileVelocityY = math.cos(adjustedShotAngle)*projMod.speed
    newProj.body:applyLinearImpulse(projectileVelocityX, projectileVelocityY)

    -- apply projectile's linear damping
    newProj.body:setLinearDamping(projMod.linearDamping)

    M.projectileList[newProj.fixture:getUserData().uid] = newProj

    -- decrement stat used for spawning multiple projectiles
    projMod.bulletCount = projMod.bulletCount - 1
  end
end
-- }}}

-- projectile collision handling {{{
M.handleProjectileCollision = function(a, b, contact, npcList)
  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- if the things that collided are on the same team, cancel the collision, we're done here
  if fixtureAUserData.team == fixtureBUserData.team then contact:setEnabled(false) return end

  -- otherwise, start by determining which of the fixtures is the projectile, cache them and their values
  local projectileFixture, otherFixture, projFixData, otherFixData
  -- if fixture A is projectile
  if fixtureAUserData.type == "projectile" and fixtureBUserData.type ~= "projectile" then
    projectileFixture = a
    projFixData = a:getUserData()
    otherFixture = b
    otherFixData = b:getUserData()
  -- if fixture B is projectile
  elseif fixtureBUserData.type == "projectile" and fixtureAUserData.type ~= "projectile" then
    projectileFixture = b
    projFixData = b:getUserData()
    otherFixture = a
    otherFixData = a:getUserData()
  else
    -- both A and B are projectiles
    print("ow!! the bullets are touching!!")
    contact:setEnabled(false)
  end

  if otherFixData.type == "terrain" then
    -- TODO: create impact decal/animation at terrain location
    -- then delete bullet from world and projectile list (unless it's a bouncy kind but stay basic for now)
    M.projectileList[projFixData.uid] = nil
    projectileFixture:getBody():destroy()
  elseif otherFixData.type == "npc" and otherFixData.team == "enemy" then
    -- deal damage, destroy the projectile, and update damage numbers
    npcList[otherFixData.uid]:hurt(projFixData.damage)
    M.projectileList[projFixData.uid] = nil
    projectileFixture:getBody():destroy()
  end
end
-- }}}

M.draw = function() -- {{{
  for i, proj in pairs(M.projectileList) do
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.circle("fill", proj.body:getX(), proj.body:getY(), proj.shape:getRadius())
  end
end -- }}}

-- for checking timed explosives, other effects
M.update = function (dt)
  for i, proj in pairs(M.projectileList) do
    if proj.fixture:getUserData().name == "projectile" then
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
