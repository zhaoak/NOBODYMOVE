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
