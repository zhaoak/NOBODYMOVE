-- This file contains definitions for guns that will spawn with preset combinations of mods ingame.
-- They're classed with their tier; higher tier entries appear later in the game.
-- Tier 1 guns are generally fairly "conventional", by video game gun standards--
-- these are the guns that players will first encounter, so they should be as straightforward as possible to understand

local proj = require'mods.shootProjectileMods'
local projTweak = require'mods.projectileTweakMods'

local M = {}

M.seededGuns = {
  -- tier 1 guns
  { name = "smg_lowcal",
    tier = 1,
    events = {
      { trigger_event="onPressShoot",
        triggers_mods={proj.smallBullet()}
      },
    }
  },

  { name = "pistol_medcal",
    tier = 1,
    events = {
      { trigger_event="onPressShoot",
        triggers_mods={proj.mediumBullet()}
      },
    }
  },

  { name = "shotgun_medcal",
    tier = 1,
    events = {
      { trigger_event="onPressShoot",
        triggers_mods={projTweak.projectileDiffractor(),proj.mediumBullet(),proj.mediumBullet(),proj.mediumBullet()}
      },
    }
  },

  -- { name = "burstsmg_lowcal",
  --   tier = 1,
  --   events = {
  --     { trigger_event="onPressShoot",
  --       triggers_mods={projTweak.burstFire(),proj.smallBullet(),proj.smallBullet(),proj.smallBullet()}
  --     },
  --   }
  -- },

  -- tier 2 guns
  { name = "machinegun_medcal",
    tier = 2,
    events = {
      { trigger_event="onPressShoot",
        triggers_mods={proj.mediumBullet()}
      },
    }
  },
}

return M
-- vim: foldmethod=marker
