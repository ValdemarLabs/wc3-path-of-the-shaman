/**
    ProfessionsCooking

    Author: Valdemar
    Version: 1.0

    Description: Registers the Cooking workstation hook for the shared Professions crafting engine.

    Credits:

    How to install:
    Import this library after Professions. Cooking recipes can be registered against the Camp Fire unit ('n61C').

    API:
    call ProfessionsCooking_Init()

**/

library ProfessionsCooking initializer AutoInit requires Professions, GatherNodeSkills

globals
    // Runtime guard.
    private boolean PC_Initialized = false

    // Workstation configuration.
    private constant integer PC_STATION_CAMP_FIRE = 'n61C'
    private constant boolean PC_AI_CHEAT_CRAFTING = true
    private constant string PC_CRAFTER_ANIMATION_PRIMARY = "stand"
    private constant string PC_CRAFTER_ANIMATION_FALLBACK = "spell"

    // Sound labels. Empty labels intentionally mean no sound until Cooking assets are chosen.
    private constant string PC_SOUND_START = ""
    private constant string PC_SOUND_LOOP = ""
    private constant string PC_SOUND_FINISH = ""
endglobals

public function Init takes nothing returns nothing
    if PC_Initialized then
        return
    endif
    set PC_Initialized = true

    call Professions_RegisterStationType(GNS_PROF_COOKING, PC_STATION_CAMP_FIRE, "Camp Fire")
    call Professions_SetProfessionSoundLabels(GNS_PROF_COOKING, PC_SOUND_START, PC_SOUND_LOOP, PC_SOUND_FINISH)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_COOKING, PC_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_COOKING, PC_CRAFTER_ANIMATION_PRIMARY, PC_CRAFTER_ANIMATION_FALLBACK)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
