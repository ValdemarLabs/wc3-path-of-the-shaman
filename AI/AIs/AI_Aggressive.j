/**
    AI_Aggressive

    Author: Valdemar
    Version:

    Description:
    Generic aggressive AI profile factory for hostile units that should seek
    and attack nearby enemies using the shared `AI.j` state engine.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`.

    API:
    call AI_Aggressive_RegisterProfile(unitTypeId, profileName, autonomous)
    call AI_Aggressive_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIAggressive initializer Init requires AI

globals
    integer AI_Aggressive_ClassId = 0
endglobals

private function Think takes nothing returns nothing
    local unit whichUnit = AI_EventUnit
    local unit target = AI_EventTarget
    if whichUnit != null and target != null then
        call IssueTargetOrder(whichUnit, "attack", target)
        if GetRandomInt(1, 8) == 1 then
            call AI_RequestBark(whichUnit, AI_BARK_ATTACKING)
        endif
    endif
    set whichUnit = null
    set target = null
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName, boolean autonomous returns integer
    local integer profileId
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_Aggressive_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, autonomous)
    call AI_SetProfileThinkCallback(profileId, function Think)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    set AI_Aggressive_ClassId = AI_RegisterClass("Aggressive")
endfunction

endlibrary
