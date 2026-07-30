# Arena plan

## Remaining functional gaps:
- Remaining functional gap: non-hero companion/pet revive needs a public revive/recreate API from Companions/Pet; the arena core currently revives/restores player heroes correctly, but does not safely recreate dead non-hero party units.

## General
- Create arena system(s)
  - Create Arena.j and nescessary sublibraries for arena. 
  - Arena modes selection can be its own sublibrary ArenaModes.j
  - Each arena mode to have its own sublibrary


## Arenas
- Two arenas
  - Circle of Blood (smaller arena)
    - shared by 'Horde' and 'Bonecrusher Clan' factions
  - Coliseum of Ages (bigger arena)
    - shared by 'Horde' and 'Satyr' and 'Riverbane' factions
    - Horde uses this arena for the more grander arena modes

## Arena modes
- Different arena modes
  - Waves
    - Difficulties
        - Easy
        - Medium
        - Hard
    - fight against waves of random enemies with seldom boss units among. Each wave should have similar creeps.
    - Start first wave after 60s of arena start
    - When wave is finished there 60s before the next wave starts.
    - last wave besides other creeps shall have stronger "boss" creep also.
  - Capture the Flag (CTF)
    - two teams with flag bases OR flag in the middle and must take to starting base
    - need AI CTF logic for both AI companions and also the arena units (opponent).
    - mode starts immediately. The team wins who has captured most flags (adjustable in arena mode selection after CTF mode is selected). 
    - Max time 10 min.
  - Team DM 
    - orcs vs humans/satyr/ogres/etc arena
    - that teams wins who defeats the other team's units.
  - Duel
    - Duel against chosen companion unit
    - Duel against player other hero
    - duel ends when the opponent is defeated.
  - Event/quest driven arena modes that are quest/event specific and cannot be normally started from arena master unless quest/even active - these can be ran with API without talking to arena master

## Player heroes, companions, pet
- the player hero is primary selected and and select the other hero and deselect also other hero but both or either hero must be selected.
- Any mode can on include all the companions and Pet and player heroes but each conpanion/pet/player hero member reduce the arena Mark gain amount by percentage 15% up to max 75 %. Chooce Will be made after mode selection. Use StatsUI as base to select the pet/companions or not to decide to not select anything but atleast 1 player hero. This might require integration into StatsUI and have StatsUI arena unit selection mode that allows multiselection of units and confirm/return buttons.

## Rects and locations
- 'Coliseum of Ages'
  - arena main area rect: 'gg_rct_018ColiseumOfAges'
  - Gate1 (player usual starting area depending on arena mode): 'gg_rct_Arena2Gate1'
  - Gate2 (creep usualstarting area depending on arena mode): 'gg_rct_Arena2Gate2'
  - Flag1: 'gg_rct_Arena2Flag1'
  - Flag2: 'gg_rct_Arena2Flag2'

- 'Circle of Blood'
  - arena main area rect: 'gg_rct_ArenaArea'
  - Gate1 (player starting area depending on arena mode): 'gg_rct_Arena1Gate1'
  - Gate2 (starting area depending on arena mode): 'gg_rct_Arena1Gate2'
  - Flag1: 'gg_rct_Arena1Flag1'
  - Flag2: 'gg_rct_Arena1Flag2'

## AI Additions
- Create AI for player shaman - main reason for arena Nazgrek vs Zulkis where the other Will be AI controlled
- Create/update generic AI logic for arena wave units. Arena AI logic must have moving to different location within the arena, not retreating fully but only partially. Primary focus of arena creep units is to kill player heroes and pet and companions.

## Revive
- Normal revive for player and companions/pet units in arena is disable during arena.
- Dead companions/pet/player heroes are revived in arena starting location if wave is finished.
- Pet normal revive after death is not enabled but however revive works and is run when the wave is finished

## Player hero death
- If hero dies (or both heroes depending on arena mode) in arena - there is message Defeat using RegionTitlesLightPots followed by small delay after which the arena ends and died heroes Will be respawned by the arenamaster 

## Item loot
- Item Loot drops are not allowed for any of arena units

## Powerup items during arena wave
- There can be random powerup health and mana items spawning randomly on arena rect during the waves. However there must be max allowed powerups and it must follow the arena wave strength

## XP gain
- XP gain is disabled for units in arena
- Pet xp still works in arena. This can be useful to train your pet.

## Rested bonus XP
- Rested bonux xp must not work for unit in arena.

## Arena marks
- Arena marks = Lumber (resource), lumber resource is renamed as 'Arena marks'
- Arena marks are gained after each wave and eventually if player succeeds finishing arena mode more arena marks are reward

## Arena start
- arena is started by talking to Arenamaster unit
  - there are several different arenamasters 
     - 'N60L' for Horde faction arenamaster
     - 'n62V' for Satyr faction arenamaster
     - add placeholders for Riverbane (human) and Bonecrusher Clan (ogre) faction arenamasters
  - arenamaster dialog shall utilize similar dialogue flow as AbilityTrainers as reference

## Arena end
- Arena ends when the mode is succesfully finished
- When arena ends there is slight delay before moving the companions/pet/player heroes that were on arena to the location of the Arenamaster_unit from which the arena started