/**
    AI_Valeria

    Author: Valdemar
    Version:

    Description:
    Optional Valeria AI profile. This library registers the profile for combat
    assistance while leaving patrol and quest movement in external systems.

    Credits:
    - qAradion / Valeria encounter flow

    How to install:
    Requires `AI.j`.

    API:
    call AI_Valeria_Enable(unit whichUnit)
    call AI_Valeria_Disable(unit whichUnit)

**/
library AIValeria initializer Init requires AI

globals
    constant integer AI_VALERIA_UNIT = 'n01W'
    constant integer AI_VALERIA_UNIQUE_ID = 'VALR'
    private constant real AUTO_ENABLE_INTERVAL = 5.00
    integer AI_Valeria_ClassId = 0
    integer AI_Valeria_ProfileId = 0
    private timer AutoEnableTimer = null
    private boolean AutoEnableAllowed = true
endglobals

private function Think takes nothing returns nothing
    local unit valeria = AI_EventUnit
    local unit target = AI_EventTarget
    local real dx
    local real dy
    local real angle
    if valeria != null and target != null then
        if GetWidgetLife(valeria) <= GetUnitState(valeria, UNIT_STATE_MAX_LIFE) * 0.35 then
            set dx = GetUnitX(valeria) - GetUnitX(target)
            set dy = GetUnitY(valeria) - GetUnitY(target)
            set angle = Atan2(dy, dx)
            call IssuePointOrder(valeria, "move", GetUnitX(valeria) + 500.00 * Cos(angle), GetUnitY(valeria) + 500.00 * Sin(angle))
        else
            call IssueTargetOrder(valeria, "attack", target)
        endif
    endif
    set valeria = null
    set target = null
endfunction

public function Enable takes unit whichUnit returns integer
    local unit existing = AI_GetUnitByUniqueId(AI_VALERIA_UNIQUE_ID)
    if whichUnit == null then
        set existing = null
        return 0
    endif
    set AutoEnableAllowed = true
    if existing != null and existing != whichUnit then
        call AI_UnregisterUnit(existing)
    endif
    set existing = null
    return AI_RegisterUnit(whichUnit, AI_Valeria_ProfileId, AI_VALERIA_UNIQUE_ID)
endfunction

public function Disable takes unit whichUnit returns nothing
    set AutoEnableAllowed = false
    call AI_UnregisterUnit(whichUnit)
endfunction

private function TryAutoEnable takes nothing returns nothing
    if AutoEnableAllowed and udg_Valeria != null and AI_GetInstance(udg_Valeria) <= 0 then
        call AI_Valeria_Enable(udg_Valeria)
    endif
endfunction

private function Init takes nothing returns nothing
    set AI_Valeria_ClassId = AI_RegisterClass("Mage")
    set AI_Valeria_ProfileId = AI_RegisterProfile(AI_Valeria_ClassId, AI_VALERIA_UNIT, "Valeria")
    call AI_SetProfileCap(AI_Valeria_ProfileId, 1)
    call AI_SetUnitTypeCap(AI_VALERIA_UNIT, 1)
    call AI_SetProfileAutonomous(AI_Valeria_ProfileId, false)
    call AI_SetProfileThinkCallback(AI_Valeria_ProfileId, function Think)

    set AutoEnableTimer = CreateTimer()
    call TimerStart(AutoEnableTimer, AUTO_ENABLE_INTERVAL, true, function TryAutoEnable)
endfunction

endlibrary
