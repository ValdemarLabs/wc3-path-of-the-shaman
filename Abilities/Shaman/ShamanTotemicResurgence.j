/**
    ShamanTotemicResurgence

    Author: Valdemar
    Version:

    Description:
    Shared Totemic Resurgence helper converted from GUI. Counts nearby allied
    totems and exposes the healing multiplier or Ancestral Ward rank.

    Credits:
    - Old GUI "Totemic Resurgence" trigger

    How to install:
    Requires `ShamanCommon`.

    API:
    - set count = ShamanTotemicResurgence_CountTotems(caster)
    - set multiplier = ShamanTotemicResurgence_GetMultiplier(caster)
    - set rank = ShamanTotemicResurgence_GetWardRank(caster)

**/
library ShamanTotemicResurgence initializer Init requires ShamanCommon

globals
    private constant real TOTEM_SEARCH_RADIUS = 500.00
    private group EnumGroup = null
endglobals

public function CountTotems takes unit caster returns integer
    local unit totem
    local integer count = 0

    if caster == null or GetUnitAbilityLevel(caster, ShamanCommon_ABILITY_TOTEMIC_RESURGENCE) <= 0 then
        return 0
    endif

    call GroupClear(EnumGroup)
    call GroupEnumUnitsInRange(EnumGroup, GetUnitX(caster), GetUnitY(caster), TOTEM_SEARCH_RADIUS, null)
    loop
        set totem = FirstOfGroup(EnumGroup)
        exitwhen totem == null
        call GroupRemoveUnit(EnumGroup, totem)
        if ShamanCommon_IsAlive(totem) and IsUnitAlly(totem, GetOwningPlayer(caster)) and ShamanCommon_IsTotemUnitType(GetUnitTypeId(totem)) then
            set count = count + 1
        endif
    endloop

    set totem = null
    return count
endfunction

public function GetMultiplier takes unit caster returns real
    local integer count = CountTotems(caster)
    if count <= 0 then
        return 0.00
    elseif count == 1 then
        return 1.15
    elseif count == 2 then
        return 1.30
    elseif count == 3 then
        return 1.45
    endif
    return 1.60
endfunction

public function GetWardRank takes unit caster returns integer
    local integer count = CountTotems(caster)
    if count <= 0 then
        return 0
    elseif count >= 4 then
        return 4
    endif
    return count
endfunction

private function Init takes nothing returns nothing
    set EnumGroup = CreateGroup()
endfunction

endlibrary
