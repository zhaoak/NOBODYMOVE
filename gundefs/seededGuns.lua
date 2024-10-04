-- This file contains definitions for guns that will spawn with preset combinations of mods ingame.
-- They're classed with their tier; higher tier entries appear later in the game.
-- Tier 1 guns are generally fairly "conventional", by video game gun standards--
-- these are the guns that players will first encounter, so they should be as straightforward as possible to understand
-- All "default" gun events (press/hold/release/unhold/throw) should always be armed,
-- because they respond directly to player input

local proj = require'mods.projectiles'
local projTweak = require'mods.tweaks'

local M = {}

M.seededGuns = {
  -- tier 1 guns
  { name = "smg_lowcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {proj.smallBullet},
        armed = true}
    }
  },

  { name = "burstpistol_medcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {projTweak.burstFire,proj.mediumBullet,proj.mediumBullet,proj.mediumBullet},
        armed = true}
    }
  },

  { name = "shotgun_medcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {projTweak.shotgunify,proj.mediumBullet,proj.mediumBullet,proj.mediumBullet},
        armed = true}
    }
  },

  { name = "burstsmg_lowcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {projTweak.burstFire,proj.smallBullet,proj.smallBullet,proj.smallBullet,proj.smallBullet,proj.smallBullet,proj.smallBullet},
        armed = true}
    }
  },

  -- tier 2 guns
  { name = "machinegun_medcal",
    tier = 2,
    events = {
      onHoldShoot = {
        mods = {proj.mediumBullet},
        armed = true}
    }
  },

  { name = "doublesniper_overcal",
    tier = 2,
    events = {
      onPressShoot = {
        mods = {proj.oversizeBullet},
        armed = true},
      onReleaseShoot = {
        mods = {proj.oversizeBullet},
        armed = true}
    }
  },
}

return M
-- vim: foldmethod=marker
