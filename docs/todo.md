# Todo

List of features still needing to be added to spoodergame

## The list

- Gun firegroups
    - Firegroup binds
    - Current guns UI showing cooldown, names, firegroups, etc
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
