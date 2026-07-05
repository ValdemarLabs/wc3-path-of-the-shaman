/**
    AI_GenericBoss

    Author: Valdemar
    Version:

    Description:
    Generic boss AI profile factory. Boss profiles register through `AI.j` but
    avoid random spawning and autonomous travel by default.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`.

    API:
    call AIGenericBoss_RegisterProfile(unitTypeId, profileName, autonomous)
    call AIGenericBoss_RegisterUnit(whichUnit, profileId, uniqueId)
    call AIGenericBoss_SetBossFightActive(active)

**/
library AIGenericBoss initializer Init requires AI

globals
    integer AI_GenericBoss_ClassId = 0
endglobals

private function Think takes nothing returns nothing
    local unit boss = AI_EventUnit
    local unit target = AI_EventTarget
    if boss != null and target != null then
        call IssueTargetOrder(boss, "attack", target)
        if GetRandomInt(1, 6) == 1 then
            call AI_RequestBark(boss, AI_BARK_ATTACKING)
        endif
    endif
    set boss = null
    set target = null
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName, boolean autonomous returns integer
    local integer profileId
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_GenericBoss_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, autonomous)
    call AI_SetProfileThinkCallback(profileId, function Think)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

public function SetBossFightActive takes boolean active returns nothing
    call AI_SetBossFightActive(active)
endfunction

private function Init takes nothing returns nothing
    set AI_GenericBoss_ClassId = AI_RegisterClass("Generic Boss")
endfunction

endlibrary
