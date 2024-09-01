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
    - a gun's mod screen looks like a series of rows of _sequences_ of _mod slots_ the player can slot mods they pick up into
    - each row of _mod slots_ is "read" left to right in a _sequence_, and the order of mods determines the order the gun performs each action
        - a _sequence_ is a chain of mods triggered by an initial "on-event" mod, which is always the first mod in the sequence
        - see mod categories section for details on mod types and how they interact
        - so for example, a simple mod sequence that makes a gun's bullets shoot when clicked and explode when they hit terrain would go: `on-press-shoot event mod --> projectile-on-hit-terrain projectile event mod --> projectile-action-explode projectile action mod --> shoot-bullet-mod`
        - sequences _probably_ should have their effects on gun stats, next fired projectiles, etc, always end when the sequence finishes executing, effects from the previously executed sequence should not persist when the same first on-event mod is triggered again
            - while this is cool metaknowledge in noita it's also wiki shit that's obtuse if you don't look it up and not immediately obvious that it works like that
        - mod effects in sequences should never be able to directly change other guns, only the one the mod is installed in
        - all guns have a locked "on press shoot" mod in the first row of sequences, this is the only mod all guns always come with (but is not the only event mod that can be chained off of)

    - All mod slots can have one of three states, dictating how the player can interact with them: stock, locked, and open   
        - _all_ projectiles/multishot/burstfire/other unique gun behavior is implemented as mods preinstalled on guns you find, these are _stock_ mods and only apply if the player doesn't put another mod in the same slot on top of them; player's also can't remove stock mods from the gun and take them
            - for example, a shotgun would have its first slot be a locked "on press shoot" on-event mod, then the next slots after it would define what the gun does when you press shoot, with stock behavior being to multishot a few bullets, and the player can add more stuff after/over/before the multishot
        - some guns have _locked_ mod slots that are part of sequences which cannot be changed at all; this is for guns that the designer (me) wants to force to have specific traits, like a minigun that always takes time to rev up or the dueling pistol that aims on pressing shoot and fires on release
            - in sandbox/spidergrind, these can of course be unlocked/changed
        - otherwise, a mod/mod slot is _open_, meaning any mod can be swapped in/out of it freely when editing
            - open mods are the ones collected and used by the player
    - all guns have infinite mod slots, but all mods have a _point cost_ that subtracts from a gun's total mod point capacity
        - ooor maybe there should be limited slots? not sure yet, we'll have to work that out when it's time to actually balance things
    - separate mods into categories depending on how they change behavior, categories don't have to be always mutually exclusive necessarily
    - categories allow mods to know which mods they should be applying their own effects to (eg. projectile tweak/on-event/action mods, on trigger, look for the next mod with the "shoot projectile mod" category in the sequence, ignoring non-applicable mods that come before it)
        - mods can be "hybrids", meaning they have multiple categories and do one or more things from both categories while only taking one mod slot
            - examples in the categories below list some possible hybrids

        - broad ideas for categories:

            - non-projectile "event trigger" mods, that trigger the next mod in the sequence's action upon the event listed on the mod happening
                - event mods can be either "on-event" (the triggering event on them _starts_ the effects of a sequence of mods and cannot be triggered by a previous mod) or "chained" (the event can't trigger on its own, it needs a triggering event on its left-hand side to trigger its effect)
                - when an event mod triggers, it looks to the mod to its right to find out what action to actually perform
                - it's looking for the next shoot, tweak, or action mod
                - these "on-event" gun mods are usually tied to a method the gun owns in code (like `shoot()` or `releaseShoot()`, meaning they're what will start mod sequence execution, only on-event mods can start a sequence
                - examples of "on-event" gun mods:
                    - an "on cooldown refresh" mod, triggers sequence when gun's cooldown is done
                    - the locked "on press shoot" mod every gun has is also an on-event mod, just an always-present one
                    - an "on player releases shoot button" mod, triggers sequence when shoot button released
                - examples of "chained-event" gun mods: 
                    - a "do after delay" mod that queues the gun to do the next mod action after waiting X amount of time, timer starts when "do after delay" event mod executes
                    - a hybrid chained-event gun mod and projectile-tweak mod that delays execution of the next mod by two seconds, but increases the next projectile's speed and damage
                    - a "apply effect of (next tweak mod's stats*5) in sequence for two seconds when this event mod triggered" mod

            - "shoot projectile of type X" mods (bullet, laser, grenade, etc)
                - this resets the gun's cooldown timer whenever it executes
                - if cooldown isn't over before gun tries to execute shoot mod, entire sequence fails and sequence execution is aborted
                - the same type of "shoot projectile" mods stack if put in the same mod slot; so multiple standard "shoot +1 projectile of X type" mods combine to multishot that type of projectile, multiple "burst fire +1 projectile of X type" stack to burst fire more and more shots
                - if there are multiple "shoot projectile of X type" mods after one event triggers both of them and the shoot projectile mods _don't_ stack, they'll both trigger on the same event
                    - this means that it's possible to have a gun shoot both a grenade and bullet when you press shoot, meaning the bullet hits the grenade immediately and explodes it directly in the player's face
                        - this is intended behavior
                - projectiles of each type have default stats, i.e. every bullet spawned by any gun with only the mods `on-press-shoot gun mod --> shoot +1 bullet mod` will have the same size, shape, etc
                    - players can change projectile stats with "projectile tweak" mods 
                    - game design wise, we can build in unique projectile properties per-gun by adding stock and locked mod slots with projectile tweak/event mods to guns

            - "gun action" mods, which make the gun perform a unique effect when triggered
                - example:
                    - "explode all bullets", which makes all projectiles of bullet type fired from that gun immediately explode when the mod is triggered 
                        - you could put that mod to trigger on release shoot button, for example

            - "gun tweak" mods that alter a gun's number stats for everything coming after them in the executed mod sequence
                - tweak mods can change multiple stats in one mod in tradeoffs, like slower but larger projectiles or faster cooldown but less damage, or even have multiple positive changes
                - tweak mods can even have only negative effects but have negative mod point costs so you _gain_ points by equipping them
                    - ig there needs to be a way to keep people from just slapping negative modpoint cost mods on last in the sequence to get free points

            - "projectile tweak" mods that change the number values for the projectiles spawned in the next "shoot projectiles" mod slot in the sequence
                - some projectile tweak mods are only useful with specific projectile types (for example, increased explosion radius does nothing if the projectile doesn't cause an explosion)
                - examples: more damage on hit, less knockback on hit, more launch velocity but smaller projectile size, etc

            - "projectile on-event" mods that look for the next "shoot projectiles" mod in the sequence and load themselves "into" the projectile(s), making the projectile(s) trigger the next non-event (meaning action, tweak, or shoot projectiles) mod also loaded into the projectile(s) when the condition on the projectile on-event mod is met
                - watching for conditions being met is done by checking during update tick and listening to collision callbacks
                - examples:
                - on projectile hits enemy, execute next mod loaded into projectile
                - on projectile hits terrain, execute next mod loaded into projectile
                - on projectile hits another projectile, this projectile explodes for 150% normal damage (this one is a hybrid projectile on-event/action mod)
            - "projectile chained-event" mods, adds extra triggering event conditions for executing next shoot-projectile mods like chained event mods
                - examples:
                    - after one second of projectile's lifetime, execute next mod (does nothing if projectile destroyed before 1s)
                    
            - "projectile action" mods, are also loaded "into" the next fired projectile(s) in the sequence, makes the projectiles _do_ something specific immediately on projectile action mod trigger, must be triggered by a projectile on-event/chained-event mod to activate
                - likely implemented as function calls on the projectile itself in code
                - examples:
                    - projectile explodes in AOE when mod triggered
                    - projectile accelerates when mod triggered
                    - projectile immediately flips velocity and retargets gun holder when mod triggered
                - these can also be a hybrid of "projectile effect" and "shoot projectile" and "projectile action" mods, where the hybrid mod, since it spawns new projectiles, can have projectile modifiers or even more projectile on-event triggers applied to the secondary projectiles
                - example:
                    - projectile splits into multiple flak shards when mod triggered, these flak shards explode when hitting enemies
                        - the sequence for this could be: `on-press-shoot (starts sequence) --> next-projectile-explodes-on-hitting-terrain (looks for next shoot-projectile mod, finds and applies to flak-shard hybrid mod) --> next-projectile-splits-into-multiple-flak-projectiles (looks for next shoot-projectile mod) --> on-projectile-hits-terrain (looks for next shoot-projectile mod) --> shoot bullet`
                    - congratulations on designing bullet callback hell
