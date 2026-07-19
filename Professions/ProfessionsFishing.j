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
    private boolean PF_Initialized = false
endglobals

public function Init takes nothing returns nothing
    if PF_Initialized then
        return
    endif
    set PF_Initialized = true
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
