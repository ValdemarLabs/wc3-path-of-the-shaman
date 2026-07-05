/**
    AI_Guard

    Author: Valdemar
    Version:

    Description:
    Generic guard AI profile factory for stationary or patrol-owned defenders.
    Guard profiles do not autonomous-wander by default, but they attack nearby
    enemies when the shared AI tick provides a target.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`.

    API:
    call AIGuard_RegisterProfile(unitTypeId, profileName)
    call AIGuard_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIGuard initializer Init requires AI

globals
    integer AI_Guard_ClassId = 0
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

public function RegisterProfile takes integer unitTypeId, string profileName returns integer
    local integer profileId
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_Guard_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, false)
    call AI_SetProfileThinkCallback(profileId, function Think)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    set AI_Guard_ClassId = AI_RegisterClass("Guard")
endfunction

endlibrary
