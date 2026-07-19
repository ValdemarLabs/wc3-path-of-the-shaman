/**
    ProfessionsLeatherworking

    Author: Valdemar
    Version: 1.0

    Description: Registers the Leatherworking workstation hook for the shared Professions crafting engine.

    Credits:

    How to install:
    Import this library after Professions. Leatherworking recipes can be registered against the Tannery unit ('n625').

    API:
    call ProfessionsLeatherworking_Init()

**/

library ProfessionsLeatherworking initializer AutoInit requires Professions, GatherNodeSkills

globals
    private boolean PL_Initialized = false
    private constant integer PL_STATION_TANNERY = 'n625'
endglobals

public function Init takes nothing returns nothing
    if PL_Initialized then
        return
    endif
    set PL_Initialized = true

    call Professions_RegisterStationType(GNS_PROF_LEATHERWORKING, PL_STATION_TANNERY, "Tannery")
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
