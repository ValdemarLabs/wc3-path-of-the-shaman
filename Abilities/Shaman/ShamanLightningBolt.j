/**
    ShamanLightningBolt

    Author: Valdemar
    Version:

    Description:
    Updates Lightning Bolt damage from AbilitiesPlayerInit and talent bonuses
    when the spell is cast.

    Credits:
    - Old GUI "Lightning Bolt" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanLightningBolt initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_LIGHTNING_BOLT then
        set amount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_LIGHTNING_BOLT, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.50)
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_LIGHTNING_BOLT, ABILITY_RLF_DAMAGE_HTB1, amount)
    endif
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
