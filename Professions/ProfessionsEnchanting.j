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
    private boolean PE_Initialized = false
endglobals

public function Init takes nothing returns nothing
    if PE_Initialized then
        return
    endif
    set PE_Initialized = true
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
