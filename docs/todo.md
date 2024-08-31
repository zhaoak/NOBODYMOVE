# Todo

List of features still needing to be added to spoodergame

## The list

- Gun firegroups
    - ~Firegroup binds~
    - ~Current guns UI showing cooldown, names, firegroups, etc~
    - Firegroup editing UI

- leg kinematics climbing/shooting code

- enemy design, AI

- map brush helper/generation functions

- fix bug w/aiming at terrain near npc at angle and doing way more damage but just with 8 guns as far as i can tell??
    - may be some weirdness with collision handling, try adding npc update func and summing all damage dealt to NPC in one tick rather than on collision

- implement grab "edgeguarding"--don't let player leave grabrange until they press ragdoll, to prevent falling off ledges while trying to climb them or move along ceilings
    - perhaps do this by adding a new circle shape to player body, radius between reach and hardbox, and make it so players can't exert movement force outside of that circle
        - so it would kinda work like reach does now except reach would then be grab+hold distance and the new circle would be movement range
    - ~alternately, use a dynamically updated-per-frame distanceJoint with minimum/maxiumum range values set so that spood cannot leave reach radius without ragdolling, which disables the joint~
        - nvm this was introduced in box2d 2.4.1 and love2d still uses 2.3
        - oh *ackshully* it looks like a RopeJoint would do what we want (enforces a maximum distance between points on two bodies) but it was removed in box2d 2.4 i think so if we version bump love and it uses a later box2d build we'd have to change it to a distance joint w/max range vals
    - could also just cancel out movement forces that would push spooder away from the closest grabpoint on the tick spooder tries to leave range ig
    - idea: once edgeguard is in place and you can't jump by just moving away from platform anymore, change ragdoll button so that when used while grabbed on something, it gives you a small burst of speed (not much, just a bit more than max walking speed) in your currently-held direction in addition to putting you in ragdoll mode (if used in air it still functions the same)
        - this is so you have a way to leave while latched to stuff, and is more analogous to a normal "jump" mechanic familiar to more players (but still preserves the complexity and utility of ragdoll mode)
- this may not be necessary if player has airdash available

- gun mod system implementation here is some ideas
    - a gun's mod screen looks like a series of rows of  _mod slots_ the player can slot mods they pick up into
    - each row of mod slots is "read" left to right in a _sequence_, and the order of mods determines the order the gun performs each action in
        - a "sequence" is a chain of events triggered by an "on-event" mod
        - see mod categories section for details on mod types and how they interact
        - this sequence generally goes `on-event mod --> chained-event mod if present --> projectile modifier mod --> shoot projectile mod`
        - sequences _probably_ should have their effects always end when the sequence finishes executing, effects from the previously executed sequence should not persist when the event is triggered again
            - while this is cool metaknowledge in noita it's also wiki shit that's obtuse if you don't look it up
    - all guns have a locked "on press shoot" mod in the first slot, this is the only mod all guns always come with (but is not the _only_ event mod that can be chained off of)
        - for example, a shotgun would have its first slot be an "on press shoot" on-event mod, then the next slots after it would define what the gun does when you press shoot, with stock behavior being to multishot a few bullets, and the player can add more stuff after/over the multishot
    - All mod slots can have one of three states, dictating how the player can interact with them: stock, locked, and open   
        - _all_ projectiles/multishot/burstfire/other unique gun behavior is implemented as mods preinstalled on guns you find, these are _stock_ mods and can be replaced by the player, but not removed from the gun and taken with them
        - some guns have _locked_ mod slots, which cannot be changed at all; this is for guns that the designer (me) wants to force to have specific traits, like a minigun that takes time to rev up or the dueling pistol that aims on pressing shoot and fires on release
            - in sandbox/spidergrind, these can of course be unlocked/changed
        - otherwise, a mod/mod slot is _open_, meaning any mod can be swapped in/out of it freely when editing
            - only open mods can be collected and used by the player
    - all guns have infinite mod slots, but all mods have a _point cost_ that subtracts from a gun's total mod point capacity
    - separate mods into categories depending on how they change behavior, categories don't have to be mutually exclusive per mod necessarily
        - think of how noita has projectiles, projectile modifiers, static projectiles, etc
        - broad ideas for categories:
            - "event" mods, that trigger the next mod in the list's action upon the event listed on the mod happening
                - event mods can be either "on-event" (the triggering event on them _starts_ the effects of a sequence of mods) or "chained" (the event can't trigger on its own, it needs a triggering event on its left-hand side to trigger its effect)
                - examples of "on-event" mods:
                    - an "on cooldown timer hits zero" mod, triggers next mods when gun's cooldown is done
                    - an "on player is reduced to less than 30% HP" mod, triggers next mods when...you get the idea
                    - the locked "on press shoot" mod every gun has is also an on-event mod, just an always-present one
                    - an "on player releases shoot button" mod
                - examples of chained mods: 
                    - a "do after delay" mod that queues the gun to do the next mod action after waiting X amount of time, timer starts after previous mod executes
                    - a "+2 seconds of next tweak mod's number effects times five when this event mod triggered" mod, for use with tweak mods after it
            - typical "shoot projectile" mods (bullet, laser, grenade, etc)
                - the same type of mods stack if put in the same mod slot; so multiple standard "shoot +1 projectile of X type" mods combine to multishot that type of projectile, multiple "burst fire +1 projectile of X type" stack to burst fire more and more shots
                - if there are multiple "shoot projectile of X type" triggered after one event that _don't_ stack, they'll both trigger on the same event
                    - this means that it's possible to have a gun shoot both a grenade and bullet when you press shoot, meaning the bullet hits the grenade immediately and explodes it directly in the player's face
                        - this is intended behavior
            - "gun tweak" mods that alter a gun's number stats for everything coming after them in the executed mod sequence
                - tweak mods can change multiple stats in one mod in tradeoffs, like slower but larger projectiles or faster cooldown but less damage, or even have multiple positive changes
                - tweak mods can even have only negative effects but have negative mod point costs so you _gain_ points by equipping them
            - "projectile tweak" mods that change the number values for the projectiles spawned in the next "shoot projectiles" mod slot in the sequence
                - some projectile tweak mods are only useful with specific projectile types (for example, increased explosion radius does nothing if the projectile doesn't cause an explosion)
                - examples: more damage on hit, less knockback on hit, more launch velocity but smaller projectile size, etc
            - "projectile on-event" mods that change the behavior of the projectiles spawned by the next shoot projectiles mod slot, these make the projectile do something when the event listed on the mod triggers
                - examples: on hit enemy execute next mod, on hit terrain execute next mod
            - "projectile chained-event" mods, adds extra triggering event conditions for executing next mods like chained event mods
                - examples:
                    - when projectile collides with enemy, execute next mod
                    - when projectile collides with terrain, execute next mod
            - "projectile action" mods, which make the projectile _do_ something specific, must be triggered by a projectile on/chained event mod to activate
                - examples:
                    - projectile explodes when mod triggered
                    - projectile bounces when mod triggers (only useful with on-collision events really)
                    - projectile explodes into flak when mod triggered
