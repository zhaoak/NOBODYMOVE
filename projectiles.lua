-- Module for any projectiles spawned and/or shot by a gun that exist as Box2D physics objects.
-- Handles creating physics data, drawing projectiles, and resolving projectile collisions.

local M = { }

M.projectileList = {} -- megalist of all projectiles existing in world

local util = require'util'
local filterVals = require'filterValues'

M.setup = function(world) -- {{{
  -- cache world for later
  M.world = world
end -- }}}

-- create projectile functions {{{
M.createHitscanShot = function(gun, shotWorldOriginX, shotWorldOriginY, worldRelativeAimAngle)

end

-- Create a circular explosion at a specific location in the world.
-- Explosions always have zero velocity and angle and do varying damage and knockback,
-- based on how close to the center of the explosion the target is.
-- This "splash damage" and knockback scales linearly with the target's distance from the explosion center.
-- They can't deal damage through (non-background-and-climbable) terrain, however.
-- args:
-- originX(num): world X-coordinate of center of explosion
-- originY(num): world Y-coordinate of center of explostion
-- radius(num): radius of the explosion hitbox
-- minDamage(num): minimum damage dealt by explosion (when hit target is at very edge of explosion hitbox)
-- maxDamage(num): maximum damage dealt by explosion (when hit target is at center of explosion hitbox)
-- minKnockback(num): minimum knockback dealt by explosion (when hit target is at very edge of explosion hitbox)
-- maxKnockback(num): max knockback dealt by explosion (when hit target is at center of explosion hitbox)
-- lifetime(num): length of time in seconds that the explosion exists and can deal damage
-- team(string): what team the explosion is on, one of: "friendly", "neutral", "enemy"
M.createExplosion = function(originX, originY, radius, minDamage, maxDamage, minKnockback, maxKnockback, lifetime, team)

end

-- Projectiles are Box2D bodies that spawn with nonzero velocity,
-- plus any other Box2D properties a dynamic physics object has.
-- The vast majority of things a player can shoot from a gun are spawned by this function.
-- This function creates the projectiles from a single barrel mod,
-- including any multishots if present.
-- args:
-- gunFiringProjectileUid(num): uid of gun firing these projectiles
-- barrelMod(table): the mod table of the mod being fired
-- shotWorldOriginX(num): X world coordinate where the shot should spawn
-- shotWorldOriginY(num): Y world coordinate where the shot should spawn
-- worldRelativeAimAngle(num): angle the projectiles should travel towards, in radians
-- shotByTeam(string): which team the projectiles belong to, one of: "friendly", "enemy", "neutral"
M.createProjectile = function(gunFiringProjectileUid, barrelMod, shotWorldOriginX, shotWorldOriginY, worldRelativeAimAngle, shotByTeam)
  while barrelMod.spawnCount > 0 do
    -- create physics object for new projectile
    local newProj = {}
    newProj.body = love.physics.newBody(M.world, shotWorldOriginX, shotWorldOriginY, "dynamic")
    if barrelMod.shapeData.hitboxShape == "circle" then
      newProj.shape = love.physics.newCircleShape(barrelMod.shapeData.radius)
    end
    newProj.fixture = love.physics.newFixture(newProj.body, newProj.shape, 1)
    newProj.fixture:setUserData{
      name="projectile",
      type="projectile",
      team=shotByTeam,
      projectileType=barrelMod.projectileType,
      maxLifetime=barrelMod.maxLifetime,
      currentLifetime=0,
      hitKnockback=barrelMod.hitKnockback,
      despawnBelowVelocity=barrelMod.despawnBelowVelocity,
      damage=barrelMod.projectileDamage,
      firedByGun=gunFiringProjectileUid,
      traits=barrelMod.traits,
      uid=util.gen_uid("projectile")
    }
    newProj.fixture:setRestitution(0)
    newProj.body:setBullet(true) -- this is Box2D's CCD (continuous collision detection) flag
    newProj.body:setGravityScale(barrelMod.gravityScale)
    newProj.body:setMass(barrelMod.mass)

    -- set filterdata for new projectile
    -- currently, player-fired projectiles never collide with each other, but we may change that
    -- because core nukes are cool

    if shotByTeam == "friendly" then
      -- this projectile has the category:
      newProj.fixture:setCategory(filterVals.category.projectile_player)
      -- this projectile should NOT collide with:
      newProj.fixture:setMask(
        filterVals.category.friendly,
        filterVals.category.player_hardbox,
        filterVals.category.projectile_player,
        filterVals.category.terrain_bg)
    elseif shotByTeam == "enemy" then
      -- this projectile has the category:
      newProj.fixture:setCategory(filterVals.category.projectile_enemy)
      -- this projectile should NOT collide with:
      newProj.fixture:setMask(
        filterVals.category.enemy,
        filterVals.category.projectile_enemy,
        filterVals.category.terrain_bg)
    elseif shotByTeam == "neutral" then
      -- this projectile has the category:
      newProj.fixture:setCategory(filterVals.category.neutral)
      -- this projectile should NOT collide with:
      newProj.fixture:setMask(
        filterVals.category.neutral,
        filterVals.category.terrain_bg)
    end

    -- this projectile is in group:
    newProj.fixture:setGroupIndex(0)

    -- adjust shot angle to account for gun inaccuracy
    local rand = math.random()
    -- give us a random modifier for the shot angle from -1*gun.inaccuracy to 1*gun.inaccuracy
    local inaccuracyAngleAdjustment = barrelMod.inaccuracy - (rand * barrelMod.inaccuracy * 2)
    -- print(inaccuracyAngleAdjustment)
    -- then, apply the inaccuracy modifier and recoil modifier to the angle of the shot
    -- we're dummying out the accuracy penalty on shot for now
    -- local adjustedShotAngle = worldRelativeAimAngle + inaccuracyAngleAdjustment + gun.current.recoilAimPenaltyOffset
    local adjustedShotAngle = util.addToAimAngle(worldRelativeAimAngle, inaccuracyAngleAdjustment)

    -- apply velocity to projectile
    local projectileVelocityX, projectileVelocityY = util.getUnitVectorFromAimAngle(adjustedShotAngle)
    projectileVelocityX = projectileVelocityX * barrelMod.speed
    projectileVelocityY = projectileVelocityY * barrelMod.speed

    newProj.body:applyLinearImpulse(projectileVelocityX, projectileVelocityY)

    -- apply projectile's linear damping
    newProj.body:setLinearDamping(barrelMod.linearDamping)

    M.projectileList[newProj.fixture:getUserData().uid] = newProj

    -- decrement stat used for spawning multiple projectiles
    barrelMod.spawnCount = barrelMod.spawnCount - 1
  end
end
-- }}}

-- projectile collision handling {{{
M.handleProjectileCollision = function(a, b, contact, npcList, player)
  local fixtureAUserData = a:getUserData()
  local fixtureBUserData = b:getUserData()

  -- if the things that collided are on the same team, ignore the collision and return, we're done here
  if fixtureAUserData.team == fixtureBUserData.team then contact:setEnabled(false) return end

  -- always disable the contact, regardless of what got hit;
  -- we do this so Box2D doesn't apply any forces as a result of the collision automatically,
  -- since we want to handle all that ourselves for projectile hits
  contact:setEnabled(false)

  -- start by determining which of the fixtures is the projectile, cache them and their values
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
  -- both A and B are projectiles
  elseif fixtureBUserData.type == "projectile" and fixtureAUserData.type == "projectile" then
    print("ow!! the bullets are touching!!")
    contact:setEnabled(false)
    return
  end

  -- iterate through each trait the projectile has
  for _, trait in pairs(projFixData.traits) do
    if trait.onCollision ~= nil then
      trait.onCollision(projectileFixture, otherFixture)
    end
  end
  -- for each trait that has an `onCollision` callback, run it

  -- if the hit thing was non-background terrain...
  if otherFixData.type == "terrain" then
    -- TODO: create impact decal/animation at terrain location
    -- then delete bullet from world and projectile list (unless it's a bouncy kind but stay basic for now)
    M.projectileList[projFixData.uid] = nil
    projectileFixture:getBody():destroy()

  -- if the hit thing was an NPC on another team...
  elseif otherFixData.type == "npc" and otherFixData.team ~= projFixData.team then
    -- get the contact position and linear velocity of both bodies at that point
    local cPosX, cPosY = contact:getPositions()
    local projCPointVelocityX, projCPointVelocityY = projectileFixture:getBody():getLinearVelocityFromWorldPoint(cPosX, cPosY)
    local npcCPointVelocityX, npcCPointVelocityY = otherFixture:getBody():getLinearVelocityFromWorldPoint(cPosX, cPosY)
    -- then use those values to find the impact velocity
    local relativeCPointVelocityX, relativeCPointVelocityY = projCPointVelocityX-npcCPointVelocityX, projCPointVelocityY-npcCPointVelocityY
    -- convert the impact velocity to a world-relative impact angle
    local angle = (util.angleBetweenVectors(0, 1, relativeCPointVelocityX, relativeCPointVelocityY) - (math.pi/2))
    -- then calculate the hit projectile's knockback from its set knockback value and the impact angle
    local xKnockback, yKnockback = npcList[otherFixData.uid]:calculateShotKnockback(projFixData.hitKnockback, angle)
    -- negative yKnockback because in love Y increases downward
    -- finally, apply the knockback at the contact position to get that angular velocity S P I N
    npcList[otherFixData.uid]:addToThisTickKnockbackAtWorldPosition(xKnockback, yKnockback, cPosX, cPosY)
    -- then apply damag and destroy the projectile
    npcList[otherFixData.uid]:hurt(projFixData.damage)
    M.projectileList[projFixData.uid] = nil
    projectileFixture:getBody():destroy()

  -- if the hit thing was a player...
  elseif otherFixData.type == "player_hardbox" and otherFixData.team ~= projFixData.team then
    -- get the linear velocity of the projectile that hit the player
    local projVelocityX, projVelocityY = projectileFixture:getBody():getLinearVelocity()
    -- convert it to a world-relative impact angle
    local angle = (util.angleBetweenVectors(0, 1, projVelocityX, projVelocityY) - (math.pi/2))
    -- then calculate the hit projectile's knockback from its set knockback value and the impact angle
    local xKnockback, yKnockback = player:calculateShotKnockback(projFixData.hitKnockback, angle)
    -- apply the knockback to player center of mass, not impact location: 
    -- we want the knockback when the player gets hit to be predictable, so no spin
    player:addToThisTickKnockback(xKnockback, yKnockback)
    -- apply damage, destroy projectile
    player.hurt(projFixData.damage)
    M.projectileList[projFixData.uid] = nil
    projectileFixture:getBody():destroy()
  end
end
-- }}}

M.draw = function() -- {{{
  for i, proj in pairs(M.projectileList) do
    local projUserData = proj.fixture:getUserData()
    love.graphics.setColor(1, 1, 1, 1)
    if projUserData.team == "friendly" then love.graphics.setColor(0, 1, 1, 1) end
    if projUserData.team == "enemy" then love.graphics.setColor(1, 0, 0, 1) end
    if projUserData.projectileType ~= "explosion" then
      love.graphics.circle("fill", proj.body:getX(), proj.body:getY(), proj.shape:getRadius())
    end
  end
end -- }}}

M.update = function (dt) -- {{{
  -- iterate through all existing projectiles
  for _, proj in pairs(M.projectileList) do
    local destroyed = false
    local projUserData = proj.fixture:getUserData()

    -- increment the projectile's lifetime timer
    projUserData.currentLifetime = projUserData.currentLifetime + dt

    -- if the projectile has been alive for longer than its max lifetime, despawn it
    if projUserData.currentLifetime > projUserData.maxLifetime then
      local projectileToDestroy = proj
      M.projectileList[projUserData.uid] = nil
      projectileToDestroy.body:destroy()
      destroyed = true
    end

    -- if the projectile has a despawn-below-speed value set, check its speed
    -- and despawn it if below the value
    if projUserData.despawnBelowVelocity ~= nil then
      local despawnSpeed = math.abs(projUserData.despawnBelowVelocity)
      local bulletLinearVelocityX, bulletLinearVelocityY = proj.body:getLinearVelocity()
      if bulletLinearVelocityX < despawnSpeed and
         bulletLinearVelocityY < despawnSpeed and
         bulletLinearVelocityX > -despawnSpeed and
         bulletLinearVelocityY > -despawnSpeed then
        local projectileToDestroy = proj
        M.projectileList[projUserData.uid] = nil
        projectileToDestroy.body:destroy()
        destroyed = true
      end
    end

    -- iterate through the projectiles traits, if any,
    -- and run the `onUpdate` callback for each if one is present
    for _, trait in pairs(projUserData.traits) do
      if trait.onUpdate ~= nil then
        trait.onUpdate(projUserData)
      end
    end
    -- write the lifetime and any other updated values to the projectile's userdata,
    -- but only if it wasn't destroyed
    if not destroyed then proj.fixture:setUserData(projUserData) end
  end
end -- }}}

return M
-- vim: foldmethod=marker
