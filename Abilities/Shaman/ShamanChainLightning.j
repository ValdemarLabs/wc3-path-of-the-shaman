/**
    ShamanChainLightning

    Author: Valdemar
    Version:

    Description:
    Updates Chain Lightning damage per target from AbilitiesPlayerInit and
    talent bonuses when the spell is cast.

    Credits:
    - Old GUI "Chain Lightning" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanChainLightning initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_CHAIN_LIGHTNING then
        set amount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_CHAIN_LIGHTNING, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.75)
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_CHAIN_LIGHTNING, ABILITY_RLF_DAMAGE_PER_TARGET_OCL1, amount)
        call ShamanCommon_RefreshAbility(caster, ShamanCommon_ABILITY_CHAIN_LIGHTNING)
    endif
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
