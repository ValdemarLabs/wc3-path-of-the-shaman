/**
    ProfessionsFishing

    Author: Valdemar
    Version: 1.0

    Description: Extension point for future Fishing recipe and station registrations.

    Credits:

    How to install:
    Import this library after Professions. Add Fishing recipe registrations here once a non-gather crafting flow is defined.

    API:
    call ProfessionsFishing_Init()

**/

library ProfessionsFishing initializer AutoInit requires Professions, GatherNodeSkills

globals
    // Runtime guard.
    private boolean PF_Initialized = false

    // Sound labels. Empty labels intentionally mean no sound until a Fishing craft flow exists.
    private constant string PF_SOUND_START = ""
    private constant string PF_SOUND_LOOP = ""
    private constant string PF_SOUND_FINISH = ""
endglobals

public function Init takes nothing returns nothing
    if PF_Initialized then
        return
    endif
    set PF_Initialized = true

    call Professions_SetProfessionSoundLabels(GNS_PROF_FISHING, PF_SOUND_START, PF_SOUND_LOOP, PF_SOUND_FINISH)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
