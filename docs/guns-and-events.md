# Guns and events

This is how the gun and event system works

## the actual plan

- guns themselves are just things that hold mods and events w/triggers; guns have no underlying stats, the mods determine all stats
    - guns do spawn in roguelike mode with mods already in them, these will probably be mostly preset to show player how to make different kinds of guns, but players can edit them
- _shoot projectile_ mods of different types each have their own cooldown, accuracy, and some other stats, which are all combined and applied when shot in a single event
    - these stats can vary with rarity, get dem purples
    - these types of mods will probably be named and styled to appear to be actual gun parts, like a new barrel slapped onto the gun sprite for a "shoot a bullet" mod
- in the gun mod UI, what you see is rows of _events_, each of which is labelled with a _trigger event_ and contains individual _mods_
    - when an event's _trigger_ occurs, every _mod_ in the event is evaluated and runs; order of mods in an event does not matter
        - if the _event_ contains multiple _shoot projectile_ mods, all of them will be shot at once, but only if the gun's cooldown is over
            - _shoot projectile_ mods in subsequently triggered events will still shoot from the gun when triggered but are completely skipped over if the gun's cooldown isn't over
        - if the _event_ contains any _trigger_ mods, those mods are _armed_, meaning the game starts listening for when their conditions are met
            - once an _armed_ trigger mod's condition is met, it runs the new _event_ it's set to trigger
            - when you put a _trigger_ mod in a mod slot in an event, it creates a new _event_ that will be triggered by that mod; you can put mods in the newly created event
            - this is to allow the player to create chain reactions, for example:
                - `on click fire event triggers --> 
                    - "shoot bullet" mod and "trigger on projectile hits terrain" mod triggers event
                - "trigger on projectile hits terrain" event -->
                    - "projectile explodes" mod
            - this would make the gun shoot a bullet on pressing fire, and that bullet will explode upon hitting terrain
            - events trigger other events, and all chains of events are ultimately started by events triggered via player inputs (press/hold/release shoot or throwing guns)
        - if the _event_ contains _projectile tweak_ mods, they'll apply to all the projectiles shot in the event, but not to projectiles in any subsequently triggered events (the functions have scope)
            - projectile tweaks include exploding on hit, status effects on hit, ricochet off terrain, etc
            - since projectile tweaks only affect projectiles, if the event is triggered and the gun's cooldown isn't over, they get skipped too
        - if the _event_ contains _misc effect_ mods, their effects activate when the event triggers
            - like the other kinds of mods, misc effects still get skipped over if cooldown isn't over when they activate
- so, our categories of mods are:
    - _shoot projectile_ mods, which create projectile(s)
        - example: "shoot bullet (0.3s cooldown, 3 deg. inaccuracy, 300 launch velocity, 3 damage)
        - projectiles of different types have very differently skewed stats, with bullets doing low damage with low cooldown, 
    - _trigger_ mods, which activate another event when their specified condition is met
        - example: "on projectile hits terrain, trigger new event"
    - _projectile tweak_ mods, which change the behavior and stats of projectiles fired in the same event as the tweak mod
        - example: "in this event: +100% projectile damage, -50% projectile speed"
    - _misc effect_ mods, which do unique things that aren't specific enough to fall into another category
        - example: "make all projectiles of type bullet fired from this gun explode on activation"

- potentially, if another limiting mechanism on fire rate/clip size is needed:
    - give guns ammo capacity and ammo regen rate stats
    - and give all projectile shooty mods ammo consumption per shot stats
    - this would give guns an effective "clip" that would still be simpler to understand than noita's recharge/cast delay/mana max system

- also possible: give guns capacity stats for individual categories of mods, so for example a gun can hold 2 shoot mods, 2 projectile tweak mods, 1 misc effect mod, and 2 trigger mods
    - this lets guns start out with fewer mod slots at start of game so as not to overwhelm new players, like how noita keeps mod capacity low in wands spawned in the first few stages
    - however, we should let the player spend earned-per-run money to upgrade the gun's mod capacity in whichever category the player chooses
- this approach would benefit greatly from tightening the definitions for mod categories so i'm gonna try to do that quickly here
    - the simplified and renamed mod categories are:
        - _barrel_ mods, previously called _shoot projectile_ mods, are all the ones that spawn projectiles from your gun on activation and have stats that can be modified
            - they're called barrel mods because these are the mods that determine what barrels visually appear on the sprite of the gun ingame
            - barrel mods can cause projectiles to spawn with specific _traits_, for example a rocket that always spawns with the explosive trait
            - custom projectile behavior (explosions, homing, whatever) should be implemented as _traits_; barrel mods should contain no callbacks
        - _ammo_ mods, previously called _projectile tweak_ mods, which change the stats/traits of any _barrel_ mods fired in their shared event
            - _traits_ are any special behaviors that a projectile can do beyond just hitting an enemy and doing knockback and damage
                - for example, exploding, homing onto enemies, fragmenting into shrapnel, ricocheting off walls, applying a status effect to hit targets, and so on
                - traits should avoid being mutually exclusive whenever possible; having traits stack and chain off each others' effects is part of the fun
                - traits are implemented as either an `onUpdate` callback that gets run each update for each projectile tagged with that trait when the projectile update step runs
                - or an `onCollision` callback that gets run when the projectile hits something
                - more callbacks may be added if necessary, like an `onModTrigger` callback
        - _trigger_ mods, name unchanged from before, activate another event when their trigger condition is met; this new event is also editable in the gun mod ui by the player
            - trigger mods can do more than just add an event and listen for it--they also allow for mod-provided callbacks to be run in the gun's update step
                - this allows for complex behavior; for example, adding a laser tripwire effect to a gun's barrel (checking if an enemy passes in front of it in the gun's update callback) that sets off the trigger mod's associated event `onTripwireDetect`; putting barrel mods in the `onTripwireDetect` event will cause them to fire when the tripwire senses an enemy so the gun literally shoots on its own
            - considering completely abandoning the idea of having to "arm" trigger mods; cooldown already prevents quickly-chained events from creating projectile spam so only action mods could be quickly and repeatedly triggered, so probably action mods should avoid doing direct damage or stacking
            - alternately, just make action mods not trigger unless cooldown is done just like barrel/ammo mods
                - this doesn't even eliminate the possibility of chaining events because, remember, if an event has no barrel mods, it incurs no cooldown timer cost when run
        - _action_ mods, previously called _misc effect_ mods, which cause specific effects to happen _immediately_ when the event containing the action mod is triggered
            - this could be limited to only apply to projectiles with certain traits (e.g. "all explosive-trait projectiles detonate on activation")
            - or they could be exotic, broad, and ideally very stupid (e.g. "all projectiles fired from this mod's gun move at half speed for 2s on activation")
            - they can also have nothing to do with projectiles, e.g. "all enemies with `rust` effect are 50% slower for 5s on activation"
            - this category is the one that's the most ideal to put in chained events in most cases
            - this mod is basically just a callback function that gets run when the mod triggers

## first draft

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


