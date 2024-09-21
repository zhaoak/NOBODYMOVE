# Todo

List of things still needing to be done for spoodergame

## The list

- design ui for gun mod screen
    - bite the bullet and just use a ui lib for now, it's not worth writing your own until you figure out what you're looking for

- Gun firegroups
    - ~Firegroup binds~
    - ~Current guns UI showing cooldown, names, firegroups, etc~
    - Firegroup editing UI

- leg kinematics climbing/shooting code

- fix bug w/aiming at terrain near npc at angle and doing way more damage but just with 8 guns as far as i can tell??
    - may be some weirdness with collision handling, try adding npc update func and summing all damage dealt to NPC in one tick rather than on collision
    - this behavior is probably from box2d handling physics results automatically from projectile collisions, so probably...
        - ~custom physics handling for projectiles hitting player/npcs~

- enemy design, AI, enemies shooting back

- item module, throw gun/item player command

- ~camera-follow-player-aim code~
- ~camera ease-to-position code (camera damping)~

- map brush helper/generation functions

- implement grab "edgeguarding"--don't let player leave grabrange until they press ragdoll, to prevent falling off ledges while trying to climb them or move along ceilings
    - perhaps do this by adding a new circle shape to player body, radius between reach and hardbox, and make it so players can't exert movement force outside of that circle
        - so it would kinda work like reach does now except reach would then be grab+hold distance and the new circle would be movement range
    - ~alternately, use a dynamically updated-per-frame distanceJoint with minimum/maxiumum range values set so that spood cannot leave reach radius without ragdolling, which disables the joint~
        - nvm this was introduced in box2d 2.4.1 and love2d still uses 2.3
        - oh *ackshully* it looks like a RopeJoint would do what we want (enforces a maximum distance between points on two bodies) but it was removed in box2d 2.4 i think so if we version bump love and it uses a later box2d build we'd have to change it to a distance joint w/max range vals
    - use applyForce over multiple ticks and increase the pull-to-surface force as spood gets farther from grab point
        - force would need to be weak enough to be overcome by dashing, but strong enough to make it hard to fall off accidentally when on a flat, upside-down ceiling
    - idea: once edgeguard is in place and you can't jump by just moving away from platform anymore, change ragdoll button so that when used while grabbed on something, it gives you a small burst of speed (not much, just a bit more than max walking speed) in your currently-held direction in addition to putting you in ragdoll mode (if used in air it still functions the same)
        - this is so you have a way to leave while latched to stuff, and is more analogous to a normal "jump" mechanic familiar to more players (but still preserves the complexity and utility of ragdoll mode)
- this may not be necessary if player has airdash available
