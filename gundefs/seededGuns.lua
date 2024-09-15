-- This file contains definitions for guns that will spawn with preset combinations of mods ingame.
-- They're classed with their tier; higher tier entries appear later in the game.
-- Tier 1 guns are generally fairly "conventional", by video game gun standards--
-- these are the guns that players will first encounter, so they should be as straightforward as possible to understand

local proj = require'mods.projectiles'
local projTweak = require'mods.tweaks'

local M = {}

M.seededGuns = {
  -- tier 1 guns
  { name = "smg_lowcal",
    tier = 1,
    events = {
      onHoldShoot={proj.smallBullet}
    }
  },

  { name = "burstpistol_medcal",
    tier = 1,
    events = {
      onHoldShoot={projTweak.burstFire,proj.mediumBullet,proj.mediumBullet,proj.mediumBullet}
    }
  },

  { name = "shotgun_medcal",
    tier = 1,
    events = {
      onHoldShoot={projTweak.shotgunify,proj.mediumBullet,proj.mediumBullet,proj.mediumBullet}
    }
  },

  { name = "burstsmg_lowcal",
    tier = 1,
    events = {
      onHoldShoot={projTweak.burstFire,proj.smallBullet,proj.smallBullet,proj.smallBullet,proj.smallBullet,proj.smallBullet,proj.smallBullet}
    }
  },

  -- tier 2 guns
  { name = "machinegun_medcal",
    tier = 2,
    events = {
      onHoldShoot={proj.mediumBullet}
    }
  },

  { name = "doublesniper_overcal",
    tier = 2,
    events = {
      onPressShoot={proj.oversizeBullet},
      onReleaseShoot={proj.oversizeBullet}
    }
  },
}

return M
-- vim: foldmethod=marker
