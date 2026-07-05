/**
    AI_Scripted

    Author: Valdemar
    Version:

    Description:
    Generic scripted-unit AI profile factory for quest and cinematic units that
    should be registered in `AI.j` while an external system owns all movement
    and order logic.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`.

    API:
    call AIScripted_RegisterProfile(unitTypeId, profileName)
    call AIScripted_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIScripted initializer Init requires AI

globals
    integer AI_Scripted_ClassId = 0
endglobals

private function Think takes nothing returns nothing
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName returns integer
    local integer profileId
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_Scripted_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, false)
    call AI_SetProfileThinkCallback(profileId, function Think)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    set AI_Scripted_ClassId = AI_RegisterClass("Scripted")
endfunction

endlibrary
