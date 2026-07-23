/**
    ShamanWaterShield

    Author: Valdemar
    Version:

    Description:
    Water Shield shield amount converted from the old BAmr GUI trigger set.
    Uses ShamanBoneArmor so absorbed shield life restores mana to the target.

    Credits:
    - Old GUI "Water Shield BAmr" triggers

    How to install:
    Requires `Events`, `ShamanCommon`, and `ShamanBoneArmor`.

**/
library ShamanWaterShield initializer Init requires Events, ShamanCommon, ShamanBoneArmor

globals
    private constant real SHIELD_DURATION = 90.00
    private constant real INTELLIGENCE_SCALE = 2.25
endglobals

private function GetShieldAmount takes unit caster, integer rank returns real
    return AbilitiesPlayerInit_GetBaseValue(ShamanCommon_ABILITY_WATER_SHIELD, AbilitiesPlayerInit_VALUE_BASE, rank) + ShamanCommon_GetStat(caster, ShamanCommon_STAT_INTELLIGENCE) * INTELLIGENCE_SCALE
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local integer rank
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_WATER_SHIELD then
        if target == null then
            set target = caster
        endif
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_WATER_SHIELD)
        set amount = GetShieldAmount(caster, rank)
        call ShamanBoneArmor_ApplyShield(caster, target, ShamanCommon_BUFF_WATER_SHIELD, amount, ShamanBoneArmor_MODE_WATER_SHIELD, true, SHIELD_DURATION)
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
