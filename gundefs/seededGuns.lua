-- This file contains definitions for guns that will spawn with preset combinations of mods ingame.
-- They're classed with their tier; higher tier entries appear later in the game.
-- Tier 1 guns are generally fairly "conventional", by video game gun standards--
-- these are the guns that players will first encounter, so they should be as straightforward as possible to understand

local barrelMod = require'mods.barrel'
local ammoMod = require'mods.ammo'
local triggerMod = require'mods.trigger'
local actionMod = require'mods.action'

local M = {}

M.seededGuns = {
  -- debug and other guns
  { name = "mod_testing_gun",
    tier = -1,
    events = {
      onPressShoot = {
        mods = {ammoMod.exampleAmmoMod,actionMod.exampleActionMod,barrelMod.mediumBullet},
        bonus = false} -- bonus events bypass the gun's cooldown, meaning they always fire
    },
    stats = {
      barrelModCapacity = 2,
      ammoModCapacity = 2,
      actionModCapacity = 2,
      eventCapacity = 2
    },
  },

  -- tier 1 guns
  { name = "smg_lowcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {barrelMod.smallBullet},
        bonus = false}
    },
    stats = {
      barrelModCapacity = 2,
      ammoModCapacity = 2,
      actionModCapacity = 2,
      eventCapacity = 2
    }
  },

  { name = "burstpistol_medcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {ammoMod.burstFire,barrelMod.mediumBullet,barrelMod.mediumBullet,barrelMod.mediumBullet},
        bonus = false}
    },
    stats = {
      barrelModCapacity = 2,
      ammoModCapacity = 2,
      actionModCapacity = 2,
      eventCapacity = 2
    }
  },

  { name = "shotgun_medcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {ammoMod.shotgunify,barrelMod.mediumBullet,barrelMod.mediumBullet,barrelMod.mediumBullet},
        bonus = false}
    },
    stats = {
      barrelModCapacity = 2,
      ammoModCapacity = 2,
      actionModCapacity = 2,
      eventCapacity = 2
    }
  },

  { name = "burstsmg_lowcal",
    tier = 1,
    events = {
      onHoldShoot = {
        mods = {ammoMod.burstFire,barrelMod.smallBullet,barrelMod.smallBullet,barrelMod.smallBullet,barrelMod.smallBullet,barrelMod.smallBullet,barrelMod.smallBullet},
        bonus = false}
    },
    stats = {
      barrelModCapacity = 2,
      ammoModCapacity = 2,
      actionModCapacity = 2,
      eventCapacity = 2
    }
  },

  -- tier 2 guns
  { name = "machinegun_medcal",
    tier = 2,
    events = {
      onHoldShoot = {
        mods = {barrelMod.mediumBullet},
        bonus = false}
    },
    stats = {
      barrelModCapacity = 2,
      ammoModCapacity = 2,
      actionModCapacity = 2,
      eventCapacity = 2
    }
  },

  { name = "doublesniper_overcal",
    tier = 2,
    events = {
      onPressShoot = {
        mods = {barrelMod.oversizeBullet},
        bonus = false},
      onReleaseShoot = {
        mods = {barrelMod.oversizeBullet},
        bonus = false}
    },
    stats = {
      barrelModCapacity = 2,
      ammoModCapacity = 2,
      actionModCapacity = 2,
      eventCapacity = 2
    }
  },
}

return M
-- vim: foldmethod=marker
