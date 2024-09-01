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

- uwoooaaaaaaaah hey we're revising the gun mod system, here's notes on that -- ALL THE STUFF ABT THE GUN MOD SYSTEM BELOW IS ROUGH DRAFT STUFF, THIS ONE IS THE ACTUAL PLAN
    - guns themselves are just things that hold mods; guns have no underlying stats, the mods determine all stats
        - guns do spawn in roguelike mode with mods already in them, these will probably be mostly preset to show player how to make different kinds of guns, but players can edit them
    - _shoot projectile_ mods of different types each have their own cooldown, accuracy, and some other stats, which are all combined and applied when shot in a single event
        - these stats can vary with rarity, get dem purples
        - these types of mods will probably be named and styled to appear to be actual gun parts, like a new barrel slapped onto the gun sprite for a "shoot a bullet" mod
    - in the gun mod UI, what you see is rows of _events_, each of which is labelled with a _trigger event_ and contains individual _mods_
        - when an event's _trigger event_ occurs, every _mod_ in the event is evaluated and runs; order of mods in an event does not matter
            - if the _event_ contains multiple _shoot projectile_ mods, all of them will be shot at once
            - if the _event_ contains any _trigger event_ mods, those mods are _armed_, meaning the game starts listening for when their conditions are met
                - once an _armed_ trigger event mod's condition is met, it runs the new _event_ it's set to trigger
                - when you put a _trigger event_ mod in a mod slot in an event, it creates a new _event_ that will be triggered by that mod; you can put mods in the newly created event
                - this is to allow the player to create chain reactions, for example:
                    - `on click fire event triggers --> 
                        - "shoot bullet" mod and "trigger on projectile hits terrain" mod triggers event
                    - "trigger on projectile hits terrain" event -->
                        - "projectile explodes" mod
                - this would make the gun shoot a bullet on pressing fire, and that bullet will explode upon hitting terrain.
            - if the _event_ contains _projectile tweak_ mods, they'll apply to all the projectiles shot in the event, but not to projectiles in any subsequently triggered events (the functions have scope)
                - projectile tweaks include exploding on hit, status effects on hit, ricochet off terrain, etc
            - if the _event_ contains _misc effect_ mods, their effects activate when the event triggers
    - so, our categories of mods are:
        - _shoot projectile_ mods, which create projectile(s)
            - example: "shoot bullet (0.3s cooldown, 3 deg. inaccuracy, 300 launch velocity, 3 damage)
            - projectiles of different types have very differently skewed stats, with bullets doing low damage with low cooldown, 
        - _trigger event_ mods, which activate another event when their specified condition is met
            - example: "on projectile hits terrain, trigger new event"
        - _projectile tweak_ mods, which change the behavior and stats of projectiles fired in the same event as the tweak mod
            - example: "in this event: +100% projectile damage, -50% projectile speed"
        - _misc effect_ mods, which do unique things that aren't specific enough to fall into another category
            - example: "make all projectiles of type bullet fired from this gun explode on activation"

- ALL THIS STUFF IS OLD I"M JUST LEAVING IT HERE FOR IF WE WANNA REFER TO IT LATER
- gun mod system implementation here is some ideas
    - a gun's mod screen looks like a series of rows, where each row is a _sequence_ of _mod slots_ the player can slot mods they pick up into
    - each sequence of _mod slots_ is "read" left to right, and the order of mods determines the order the gun performs each action
        - a _sequence_ is a chain of mods triggered by an initial "on-gun-event" mod, which is always the first mod in the sequence
        - see mod categories section for details on mod types and how they interact
        - so for example, a simple mod sequence that makes a gun's bullets shoot when clicked and explode when they hit terrain would go: `on-press-shoot gun event mod --> projectile-on-hit-terrain projectile event mod --> projectile-action-explode projectile action mod --> shoot-bullet-mod`
        - sequences _probably_ should have their effects on gun stats, next sequence's fired projectiles, etc, always end when the sequence finishes executing, effects from the previously executed sequence should not persist when the same first on-event mod is triggered again
            - while this is cool metaknowledge in noita it's also wiki shit that's obtuse if you don't look it up and not immediately obvious that it works like that
        - mod effects in sequences should never be able to directly change other guns, only the one the mod is installed in
        - all guns have a locked "on press shoot" mod as their first sequence, this is the only mod/sequence all guns always come with (but is not the only event mod that can be chained off of)

    - All mod slots can have one of three states, dictating how the player can interact with them: stock, locked, and open   
        - _all_ projectiles/multishot/burstfire/other unique gun behavior is implemented as mods preinstalled on guns you find, these are _stock_ mods and only apply if the player doesn't put another mod in the same slot on top of them; player's also can't remove stock mods from the gun and take them
            - for example, a shotgun would have its first slot be a locked "on press shoot" on-event mod, then the next slots after it would define what the gun does when you press shoot, with stock behavior being to multishot a few bullets, and the player can add more stuff after/over/before the multishot
        - some guns have _locked_ mod slots/sequences containing specific mods which cannot be changed at all; this is for guns that the designer (me) wants to force to have specific traits, like a minigun that always takes time to rev up before shooting or the dueling pistol that aims on pressing shoot and fires on release
            - in sandbox/spidergrind, these can of course be unlocked/changed
        - otherwise, a mod/mod slot is _open_, meaning any mod can be swapped in/out of it freely when editing
            - open mods are the ones collected and used by the player
    - all guns have infinite mod slots, but all mods have a _point cost_ that subtracts from a gun's total mod point capacity
        - ooor maybe there should be limited slots? not sure yet, we'll have to work that out when it's time to actually balance things
    - separate mods into categories depending on what they do, categories don't have to be one-per-mod
    - categories allow mods to know which mods they should be applying their own effects to (eg. projectile tweak/on-event/action mods, on trigger, look for the next mod with the "shoot projectile mod" category in the sequence, ignoring non-applicable mods that come before it)
        - mods can be "hybrids", meaning they have multiple categories and do one or more things from both categories while only taking one mod slot
            - examples in the categories below list some possible hybrids

        - broad ideas for categories:

            - non-projectile "event trigger" mods, that trigger the next mod in the sequence's action upon the event listed on the mod happening
                - event mods can be either "on-event" (the triggering event on them _starts_ the effects of a sequence of mods and cannot be triggered by a previous mod) or "chained" (the event can't trigger on its own, it needs a triggering event on its left-hand side to trigger its effect)
                - when an event mod triggers, it looks to the mod to its right to find out what to do next
                - these "on-event" gun mods are usually tied to a method the gun owns in code (like `shoot()` or `releaseShoot()`, meaning they're what will start mod sequence execution, only on-event mods can start a sequence
                - examples of "on-event" gun mods:
                    - an "on cooldown refresh" mod, triggers sequence when gun's cooldown is done
                    - the locked "on press shoot" mod every gun has is also an on-event mod, just an always-present one
                    - an "on player releases shoot button" mod, triggers sequence when shoot button released
                - examples of "chained-event" gun mods: 
                    - a "do after delay" mod that queues the gun to do the next mod action after waiting X amount of time, timer starts when "do after delay" event mod executes
                    - a hybrid chained-event gun mod and projectile-tweak mod that delays execution of the next mod by two seconds, but increases the next projectile's speed and damage
                    - a "apply effect of (next tweak mod's stats*5) in sequence for two seconds when this event mod triggered" mod

            - "shoot projectile of type X" and "burst-fire projectile of type X" mods (bullet, laser, grenade, etc)
                - anytime the gun shoots a projectile, its cooldown resets 
                - if cooldown isn't over before gun tries to execute shoot mod, entire sequence fails and sequence execution is aborted
                - the same type of "shoot projectile" mods stack if put in the same mod slot; so multiple standard "shoot +1 projectile of X type" mods combine to multishot that type of projectile, multiple "burst fire +1 projectile of X type" stack to burst fire more and more shots in the burst
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


