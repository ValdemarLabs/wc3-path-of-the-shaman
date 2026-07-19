/**
    ProfessionsSkinning

    Author: Valdemar
    Version: 1.0

    Description: Extension point for future Skinning craft recipes; gathering behavior remains owned by the existing gather systems.

    Credits:

    How to install:
    Import this library after Professions. Add Skinning recipe registrations here when a station or recipe flow is defined.

    API:
    call ProfessionsSkinning_Init()

**/

library ProfessionsSkinning initializer AutoInit requires Professions, GatherNodeSkills

globals
    // Runtime guard.
    private boolean PS_Initialized = false

    // Sound labels. Empty labels intentionally mean no sound until a Skinning craft flow exists.
    private constant string PS_SOUND_START = ""
    private constant string PS_SOUND_LOOP = ""
    private constant string PS_SOUND_FINISH = ""
endglobals

public function Init takes nothing returns nothing
    if PS_Initialized then
        return
    endif
    set PS_Initialized = true

    call Professions_SetProfessionSoundLabels(GNS_PROF_SKINNING, PS_SOUND_START, PS_SOUND_LOOP, PS_SOUND_FINISH)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
