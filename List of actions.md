==================================================================================================================================================
Epic Quests 21.6.2025 - List of actions:

- Testing UnitHider1.1
-- whether it even works AND if memory leaks are reduced
-- Results: it does not work AND it lags even more!
-- Reverting to UnitHider1.0

Added units in WE:
- Core Hound
- NorthrendskeletonmaleBosses (Skullreaver)
- Valkier (Seralyth)

Terrain / doodads
- Added altar of storms to Dragonfire Peaks
- Added fel orcs at the altar of storms, some quest related to multiple Altar of Storms located in multiple locations in the map
- Sirensong terraining forward slightly
-- Sirensong Orc base edited forward
-- Sirensong orc base doodads some may require some editing (black textures when viewed from afar

Issues after testing:
- Valkier model bad; in air + changing stand animation to flying

Orc doodads (zeppelin):
- Tried to use UV remapping on black/glitchy orc zeppelin -> did not work
- Tried to use wrap width & wrap height on orc zeppelin and re-import the model (without re-importing textures) -> did not work, maybe need to re-import textures or related to Material filter modes

- Progressive lag / memory leak; gets bad quite quickly; 
-- To test in next revision:
--- Disable UnitHider
--- Disable DestructibleHider
--- Disable AI hero spawning >> a)
--- Disable AI hero spawning, but leave UnitHider enabled >> b)

==================================================================================================================================================

Epic Quests 24.6.2025 - List of actions:

- Crash after doing countless regions for zones + some STV/jungle like doodad search, nothing fully inserted
-- Crash caused by STV_root01, could be others that may cause similar crash, or its related to the weirdly huge sizes, but most likely texture issue.
- modify Valkier to be "on foot" instead of on air, still need to fix her stand animation OR remove
- Stats check 2 -trigger disabled temporally
-- To check if this is causing lag / memory leak
--- seemed to be better, but needs more testing, still some minor peaks not that bad?

==================================================================================================================================================

Epic Quests 25.6.2025 - List of actions:

- Note on textures: lots of imported duplicate textures with path war3mapImported / war3campImported .blp files that should be removed 
- Note on re-imported textures:
---> Now black / glitching occurs also on orc hut!!!!!! Previous textures worked better!
- Sirensong:
-- Continued terraining southern end of the map, sea shore area

- Note on lag issues:
-- Previously disabled Stats check 2 -trigger was not the (main) cause of lag, still getting laggier after some time
-- Also; when units shown? or area near at water elemental boss caused fps to drop to 2 fps, could also be because of overlapping of Unit hider on AI / other units??
-- Now testing: 
----- disabled UnitHider + related triggers and functions in CinematicON, CinematicOFF, Intro Cinematic Cleanup
----- disabled DestructibleHider
