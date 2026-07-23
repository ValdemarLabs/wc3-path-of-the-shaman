/**
    ShamanHealingWave

    Author: Valdemar
    Version:

    Description:
    Healing Wave Hhb1 amount refresh converted from GUI. Uses
    AbilitiesPlayerInit base values, Intelligence scaling, talents, and
    Totemic Resurgence.

    Credits:
    - Old GUI "Healing Wave Bonus" trigger

    How to install:
    Requires `Events`, `ShamanCommon`, and `ShamanTotemicResurgence`.

**/
library ShamanHealingWave initializer Init requires Events, ShamanCommon, ShamanTotemicResurgence

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local real amount
    local real multiplier
    if GetSpellAbilityId() == ShamanCommon_ABILITY_HEALING_WAVE then
        set amount = ShamanCommon_GetHealingAmount(caster, ShamanCommon_ABILITY_HEALING_WAVE, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.50)
        set multiplier = ShamanTotemicResurgence_GetMultiplier(caster)
        if multiplier > 0.00 then
            set amount = amount * multiplier
        endif
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_HEALING_WAVE, ABILITY_RLF_AMOUNT_HEALED_DAMAGED_HHB1, amount)
        call ShamanCommon_RefreshAbility(caster, ShamanCommon_ABILITY_HEALING_WAVE)
    endif
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
