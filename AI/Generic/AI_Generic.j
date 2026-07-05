/**
    AI_Generic

    Author: Valdemar
    Version:

    Description:
    Generic AI profile factory for unit types that only need the shared
    `AI.j` state engine plus simple attack behavior.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`.

    API:
    call AIGeneric_RegisterProfile(unitTypeId, profileName, autonomous)
    call AIGeneric_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIGeneric initializer Init requires AI

globals
    integer AI_Generic_ClassId = 0
endglobals

private function Think takes nothing returns nothing
    local unit whichUnit = AI_EventUnit
    local unit target = AI_EventTarget
    if whichUnit != null and target != null then
        call IssueTargetOrder(whichUnit, "attack", target)
    endif
    set whichUnit = null
    set target = null
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName, boolean autonomous returns integer
    local integer profileId
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_Generic_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, autonomous)
    call AI_SetProfileThinkCallback(profileId, function Think)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    set AI_Generic_ClassId = AI_RegisterClass("Generic")
endfunction

endlibrary
