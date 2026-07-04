/**
    AI_Passive

    Author: Valdemar
    Version:

    Description:
    Generic passive AI profile factory for units that should avoid combat and
    not use autonomous wander/shop/camp/travel behavior by default.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`.

    API:
    call AI_Passive_RegisterProfile(unitTypeId, profileName)
    call AI_Passive_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIPassive initializer Init requires AI

globals
    integer AI_Passive_ClassId = 0
endglobals

private function MoveAwayFromTarget takes unit whichUnit, unit target, real distance returns nothing
    local real dx
    local real dy
    local real angle
    if whichUnit == null or target == null then
        return
    endif
    set dx = GetUnitX(whichUnit) - GetUnitX(target)
    set dy = GetUnitY(whichUnit) - GetUnitY(target)
    if dx == 0.00 and dy == 0.00 then
        set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif
    call IssuePointOrder(whichUnit, "move", GetUnitX(whichUnit) + distance * Cos(angle), GetUnitY(whichUnit) + distance * Sin(angle))
endfunction

private function Think takes nothing returns nothing
    local unit whichUnit = AI_EventUnit
    local unit target = AI_EventTarget
    if whichUnit != null and target != null then
        call MoveAwayFromTarget(whichUnit, target, 450.00)
    endif
    set whichUnit = null
    set target = null
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName returns integer
    local integer profileId
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_Passive_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, false)
    call AI_SetProfileThinkCallback(profileId, function Think)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    set AI_Passive_ClassId = AI_RegisterClass("Passive")
endfunction

endlibrary
