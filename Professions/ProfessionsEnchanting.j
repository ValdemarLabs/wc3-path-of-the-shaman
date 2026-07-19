/**
    ProfessionsEnchanting

    Author: Valdemar
    Version: 1.0

    Description: Extension point for future Enchanting recipe and station registrations.

    Credits:

    How to install:
    Import this library after Professions. Add Enchanting station and recipe registrations here once the flow is defined.

    API:
    call ProfessionsEnchanting_Init()

**/

library ProfessionsEnchanting initializer AutoInit requires Professions, GatherNodeSkills

globals
    // Runtime guard.
    private boolean PE_Initialized = false
    private constant boolean PE_AI_CHEAT_CRAFTING = true
    private constant string PE_CRAFTER_ANIMATION_PRIMARY = "spell"
    private constant string PE_CRAFTER_ANIMATION_FALLBACK = "stand"

    // Sound labels. Empty labels intentionally mean no sound until Enchanting assets are chosen.
    private constant string PE_SOUND_START = ""
    private constant string PE_SOUND_LOOP = ""
    private constant string PE_SOUND_FINISH = ""
endglobals

public function Init takes nothing returns nothing
    if PE_Initialized then
        return
    endif
    set PE_Initialized = true

    call Professions_SetProfessionSoundLabels(GNS_PROF_ENCHANTING, PE_SOUND_START, PE_SOUND_LOOP, PE_SOUND_FINISH)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_ENCHANTING, PE_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_ENCHANTING, PE_CRAFTER_ANIMATION_PRIMARY, PE_CRAFTER_ANIMATION_FALLBACK)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
