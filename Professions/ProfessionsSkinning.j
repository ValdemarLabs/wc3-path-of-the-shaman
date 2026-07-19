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
    private boolean PS_Initialized = false
endglobals

public function Init takes nothing returns nothing
    if PS_Initialized then
        return
    endif
    set PS_Initialized = true
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
