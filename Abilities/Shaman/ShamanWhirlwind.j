/**
    ShamanWhirlwind

    Author: Valdemar
    Version:

    Description:
    Whirlwind damage and mana-cost refresh converted from GUI. Strength and
    Agility reduce mana cost and increase damage.

    Credits:
    - Old GUI "Whirlwind" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanWhirlwind initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer rank
    local real strength
    local real agility
    local real manaReduction
    local integer manaCost
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_WHIRLWIND then
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_WHIRLWIND)
        set strength = ShamanCommon_GetStat(caster, ShamanCommon_STAT_STRENGTH)
        set agility = ShamanCommon_GetStat(caster, ShamanCommon_STAT_AGILITY)
        set manaReduction = strength * 0.40 + agility * 0.20
        if manaReduction > 75.00 then
            set manaReduction = 75.00
        endif
        set manaCost = R2I(AbilitiesPlayerInit_GetBaseValue(ShamanCommon_ABILITY_WHIRLWIND, AbilitiesPlayerInit_VALUE_MANA_COST, rank) * (1.00 - manaReduction / 100.00))
        set amount = ShamanCommon_GetHybridDamageAmount(caster, ShamanCommon_ABILITY_WHIRLWIND, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_AGILITY, 0.85, ShamanCommon_STAT_STRENGTH, 0.35)
        call ShamanCommon_PlaySound(gg_snd_Whirlwind)
        call ShamanCommon_SetIntegerField(caster, ShamanCommon_ABILITY_WHIRLWIND, ABILITY_ILF_MANA_COST, manaCost)
        call BlzSetUnitAbilityManaCost(caster, ShamanCommon_ABILITY_WHIRLWIND, rank - 1, manaCost)
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_WHIRLWIND, ABILITY_RLF_DAMAGE_PER_SECOND_OWW1, amount)
        call ShamanCommon_RefreshAbility(caster, ShamanCommon_ABILITY_WHIRLWIND)
    endif
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
