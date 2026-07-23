/**
    ShamanAncestralWard

    Author: Valdemar
    Version:

    Description:
    Ancestral Ward shield amount and cooldown handling converted from the old
    BAmr GUI trigger set. Uses ShamanBoneArmor for the absorb engine.

    Credits:
    - Old GUI "Ancestral Ward BAmr" triggers

    How to install:
    Requires `Events`, `ShamanCommon`, and `ShamanBoneArmor`.

    API:
    - call ShamanAncestralWard_ApplyFromTotemicResurgence(caster, target, rank, intelligence)

**/
library ShamanAncestralWard initializer Init requires Events, ShamanCommon, ShamanBoneArmor

globals
    private constant real SHIELD_DURATION = 90.00
    private constant real NORMAL_COOLDOWN = 10.00
    private constant real INTELLIGENCE_SCALE = 2.25
    private constant real ANCESTRAL_GRACE_BONUS_PER_VALUE = 5.00
endglobals

private function GetShieldAmount takes unit caster, integer rank, integer intelligence returns real
    local real amount = AbilitiesPlayerInit_GetBaseValue(ShamanCommon_ABILITY_ANCESTRAL_WARD, AbilitiesPlayerInit_VALUE_BASE, rank) + I2R(intelligence) * INTELLIGENCE_SCALE
    set amount = ShamanCommon_ApplySpecialRankBonus(caster, ShamanCommon_ABILITY_ANCESTRAL_WARD, amount, ANCESTRAL_GRACE_BONUS_PER_VALUE)
    return amount
endfunction

private function ApplyInternal takes unit caster, unit target, integer rank, integer intelligence, boolean requireBuff, boolean startCooldown returns nothing
    local real amount
    if target == null then
        return
    endif
    set rank = ShamanCommon_ClampRank(rank)
    set amount = GetShieldAmount(caster, rank, intelligence)
    call ShamanBoneArmor_ApplyShield(caster, target, ShamanCommon_BUFF_ANCESTRAL_WARD, amount, ShamanBoneArmor_MODE_ANCESTRAL_WARD, requireBuff, SHIELD_DURATION)
    if startCooldown and caster != null and GetUnitAbilityLevel(caster, ShamanCommon_ABILITY_ANCESTRAL_WARD) > 0 then
        call BlzStartUnitAbilityCooldown(caster, ShamanCommon_ABILITY_ANCESTRAL_WARD, NORMAL_COOLDOWN)
    endif
endfunction

public function ApplyFromTotemicResurgence takes unit caster, unit target, integer rank, integer intelligence returns nothing
    call ApplyInternal(caster, target, rank, intelligence, false, false)
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    if GetSpellAbilityId() == ShamanCommon_ABILITY_ANCESTRAL_WARD then
        call ApplyInternal(caster, target, ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_ANCESTRAL_WARD), GetHeroInt(caster, true), true, true)
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
