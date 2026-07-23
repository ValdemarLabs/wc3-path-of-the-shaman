/**
    ShamanChainHeal

    Author: Valdemar
    Version:

    Description:
    Chain Heal Ocl1 amount refresh and Totemic Resurgence Ancestral Ward hook
    converted from GUI.

    Credits:
    - Old GUI "Chain Heal Bonus" trigger

    How to install:
    Requires `Events`, `ShamanCommon`, `ShamanTotemicResurgence`, and
    `ShamanAncestralWard`.

**/
library ShamanChainHeal initializer Init requires Events, ShamanCommon, ShamanTotemicResurgence, ShamanAncestralWard

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local real amount
    local integer wardRank
    if GetSpellAbilityId() == ShamanCommon_ABILITY_CHAIN_HEAL then
        set amount = ShamanCommon_GetHealingAmount(caster, ShamanCommon_ABILITY_CHAIN_HEAL, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.50)
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_CHAIN_HEAL, ABILITY_RLF_DAMAGE_PER_TARGET_OCL1, amount)
        set wardRank = ShamanTotemicResurgence_GetWardRank(caster)
        if wardRank > 0 and target != null then
            call ShamanAncestralWard_ApplyFromTotemicResurgence(caster, target, wardRank, GetHeroInt(caster, true))
        endif
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
