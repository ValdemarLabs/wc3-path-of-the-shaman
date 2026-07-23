/**
    AbilitiesPlayerInit

    Author: Valdemar
    Version:

    Description:
    Table-backed base value registry for converted player shaman ability
    scripts. Values are imported from the old "Init Abilities" GUI trigger,
    but stored by ability rawcode, value type, and rank instead of GUI globals.

    Credits:
    - Bribe's Table v6
    - Old GUI "Init Abilities" trigger

    How to install:
    Requires `Table`. Import before converted ability scripts that read player
    shaman base values. The old GUI "Init Abilities" trigger can be disabled
    once all converted ability scripts use this library.

    API:
    - call AbilitiesPlayerInit_Apply()
    - call AbilitiesPlayerInit_RegisterBaseValue(abilityId, valueType, rank, value)
    - set found = AbilitiesPlayerInit_HasBaseValue(abilityId, valueType, rank)
    - set value = AbilitiesPlayerInit_GetBaseValue(abilityId, valueType, rank)
    - set value = AbilitiesPlayerInit_GetUnitBaseValue(caster, abilityId, valueType)
    - set value = AbilitiesPlayerInit_ApplyDamageModifiers(caster, abilityId, value)
    - set value = AbilitiesPlayerInit_ApplyHealingModifiers(caster, abilityId, value)
    - set value = AbilitiesPlayerInit_GetUnitDamageValue(caster, abilityId, valueType)
    - set value = AbilitiesPlayerInit_GetUnitHealingValue(caster, abilityId, valueType)

**/
library AbilitiesPlayerInit initializer Init requires Table, optional Talents

globals
    public constant integer VALUE_BASE = 1
    public constant integer VALUE_AREA_BASE = 2
    public constant integer VALUE_MANA_COST = 3

    private constant integer API_RANK_KEY_STRIDE = 100

    private constant integer API_ABILITY_LIGHTNING_BOLT = 'A6A0'
    private constant integer API_ABILITY_LIGHTNING_STRIKE = 'A67H'
    private constant integer API_ABILITY_CHAIN_LIGHTNING = 'A67L'
    private constant integer API_ABILITY_FIRE_SHOCK = 'A67J'
    private constant integer API_ABILITY_FROST_SHOCK = 'A69L'
    private constant integer API_ABILITY_NATURE_SHOCK = 'A69N'
    private constant integer API_ABILITY_LIGHTNING_SHIELD = 'A68H'
    private constant integer API_ABILITY_STORMSTRIKE = 'A685'
    private constant integer API_ABILITY_WHIRLWIND = 'A6DP'
    private constant integer API_ABILITY_PRIMAL_FORCE = 'A022'
    private constant integer API_ABILITY_GHOST_WOLF_BITE = 'A68K'
    private constant integer API_ABILITY_HEALING_WAVE = 'A66Y'
    private constant integer API_ABILITY_CHAIN_HEAL = 'A672'
    private constant integer API_ABILITY_HEALING_RAIN = 'A66W'
    private constant integer API_ABILITY_REJUVENATION = 'A69W'
    private constant integer API_ABILITY_WATER_SHIELD = 'A62Z'
    private constant integer API_ABILITY_ANCESTRAL_WARD = 'A6AL'

    private Table API_ValueByAbility = 0
    private boolean API_Applied = false
endglobals

private function API_EnsureState takes nothing returns nothing
    if API_ValueByAbility == 0 then
        set API_ValueByAbility = Table.create()
    endif
endfunction

private function API_GetRankKey takes integer valueType, integer rank returns integer
    return valueType * API_RANK_KEY_STRIDE + rank
endfunction

private function API_GetUnitAbilityRank takes unit caster, integer abilityId returns integer
    local integer rank = 1
    if caster != null then
        set rank = GetUnitAbilityLevel(caster, abilityId)
        if rank <= 0 then
            set rank = 1
        endif
    endif
    return rank
endfunction

private function API_GetAbilityTable takes integer abilityId, boolean create returns Table
    call API_EnsureState()
    if API_ValueByAbility.has(abilityId) then
        return API_ValueByAbility[abilityId]
    elseif create then
        return API_ValueByAbility.link(abilityId)
    endif
    return 0
endfunction

public function RegisterBaseValue takes integer abilityId, integer valueType, integer rank, real value returns nothing
    local Table abilityTable
    if abilityId == 0 or valueType <= 0 or rank <= 0 then
        return
    endif
    set abilityTable = API_GetAbilityTable(abilityId, true)
    set abilityTable.real[API_GetRankKey(valueType, rank)] = value
endfunction

public function Apply takes nothing returns nothing
    if API_Applied then
        return
    endif
    set API_Applied = true

    call RegisterBaseValue(API_ABILITY_LIGHTNING_BOLT, VALUE_BASE, 1, 75.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_BOLT, VALUE_BASE, 2, 125.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_BOLT, VALUE_BASE, 3, 175.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_BOLT, VALUE_BASE, 4, 225.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_BOLT, VALUE_BASE, 5, 300.00)

    call RegisterBaseValue(API_ABILITY_LIGHTNING_STRIKE, VALUE_BASE, 1, 75.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_STRIKE, VALUE_BASE, 2, 150.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_STRIKE, VALUE_BASE, 3, 225.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_STRIKE, VALUE_BASE, 4, 300.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_STRIKE, VALUE_BASE, 5, 375.00)

    call RegisterBaseValue(API_ABILITY_CHAIN_LIGHTNING, VALUE_BASE, 1, 85.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_LIGHTNING, VALUE_BASE, 2, 125.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_LIGHTNING, VALUE_BASE, 3, 180.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_LIGHTNING, VALUE_BASE, 4, 220.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_LIGHTNING, VALUE_BASE, 5, 250.00)

    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_BASE, 1, 60.00)
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_BASE, 2, 90.00)
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_BASE, 3, 140.00)
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_BASE, 4, 160.00)
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_BASE, 5, 190.00)

    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_AREA_BASE, 1, 35.00)
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_AREA_BASE, 2, 50.00)
    // Old GUI export repeated index 1 for these ranks; store the intended rank values.
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_AREA_BASE, 3, 80.00)
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_AREA_BASE, 4, 100.00)
    call RegisterBaseValue(API_ABILITY_FIRE_SHOCK, VALUE_AREA_BASE, 5, 120.00)

    call RegisterBaseValue(API_ABILITY_FROST_SHOCK, VALUE_BASE, 1, 50.00)
    call RegisterBaseValue(API_ABILITY_FROST_SHOCK, VALUE_BASE, 2, 100.00)
    call RegisterBaseValue(API_ABILITY_FROST_SHOCK, VALUE_BASE, 3, 150.00)
    call RegisterBaseValue(API_ABILITY_FROST_SHOCK, VALUE_BASE, 4, 200.00)
    call RegisterBaseValue(API_ABILITY_FROST_SHOCK, VALUE_BASE, 5, 250.00)

    call RegisterBaseValue(API_ABILITY_NATURE_SHOCK, VALUE_BASE, 1, 80.00)
    call RegisterBaseValue(API_ABILITY_NATURE_SHOCK, VALUE_BASE, 2, 160.00)
    call RegisterBaseValue(API_ABILITY_NATURE_SHOCK, VALUE_BASE, 3, 240.00)
    call RegisterBaseValue(API_ABILITY_NATURE_SHOCK, VALUE_BASE, 4, 320.00)
    call RegisterBaseValue(API_ABILITY_NATURE_SHOCK, VALUE_BASE, 5, 400.00)

    call RegisterBaseValue(API_ABILITY_LIGHTNING_SHIELD, VALUE_BASE, 1, 10.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_SHIELD, VALUE_BASE, 2, 25.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_SHIELD, VALUE_BASE, 3, 40.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_SHIELD, VALUE_BASE, 4, 55.00)
    call RegisterBaseValue(API_ABILITY_LIGHTNING_SHIELD, VALUE_BASE, 5, 70.00)

    call RegisterBaseValue(API_ABILITY_STORMSTRIKE, VALUE_BASE, 1, 25.00)
    call RegisterBaseValue(API_ABILITY_STORMSTRIKE, VALUE_BASE, 2, 40.00)
    call RegisterBaseValue(API_ABILITY_STORMSTRIKE, VALUE_BASE, 3, 70.00)
    call RegisterBaseValue(API_ABILITY_STORMSTRIKE, VALUE_BASE, 4, 100.00)
    call RegisterBaseValue(API_ABILITY_STORMSTRIKE, VALUE_BASE, 5, 125.00)

    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_BASE, 1, 15.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_BASE, 2, 25.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_BASE, 3, 35.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_BASE, 4, 45.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_BASE, 5, 55.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_MANA_COST, 1, 50.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_MANA_COST, 2, 60.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_MANA_COST, 3, 70.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_MANA_COST, 4, 80.00)
    call RegisterBaseValue(API_ABILITY_WHIRLWIND, VALUE_MANA_COST, 5, 90.00)

    call RegisterBaseValue(API_ABILITY_PRIMAL_FORCE, VALUE_BASE, 1, 20.00)
    call RegisterBaseValue(API_ABILITY_PRIMAL_FORCE, VALUE_BASE, 2, 40.00)
    call RegisterBaseValue(API_ABILITY_PRIMAL_FORCE, VALUE_BASE, 3, 60.00)
    call RegisterBaseValue(API_ABILITY_PRIMAL_FORCE, VALUE_BASE, 4, 80.00)
    call RegisterBaseValue(API_ABILITY_PRIMAL_FORCE, VALUE_BASE, 5, 120.00)

    call RegisterBaseValue(API_ABILITY_GHOST_WOLF_BITE, VALUE_BASE, 1, 25.00)
    call RegisterBaseValue(API_ABILITY_GHOST_WOLF_BITE, VALUE_BASE, 2, 40.00)
    call RegisterBaseValue(API_ABILITY_GHOST_WOLF_BITE, VALUE_BASE, 3, 70.00)
    call RegisterBaseValue(API_ABILITY_GHOST_WOLF_BITE, VALUE_BASE, 4, 100.00)
    call RegisterBaseValue(API_ABILITY_GHOST_WOLF_BITE, VALUE_BASE, 5, 125.00)

    call RegisterBaseValue(API_ABILITY_HEALING_WAVE, VALUE_BASE, 1, 200.00)
    call RegisterBaseValue(API_ABILITY_HEALING_WAVE, VALUE_BASE, 2, 300.00)
    call RegisterBaseValue(API_ABILITY_HEALING_WAVE, VALUE_BASE, 3, 400.00)
    call RegisterBaseValue(API_ABILITY_HEALING_WAVE, VALUE_BASE, 4, 500.00)
    call RegisterBaseValue(API_ABILITY_HEALING_WAVE, VALUE_BASE, 5, 650.00)

    call RegisterBaseValue(API_ABILITY_CHAIN_HEAL, VALUE_BASE, 1, 120.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_HEAL, VALUE_BASE, 2, 200.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_HEAL, VALUE_BASE, 3, 280.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_HEAL, VALUE_BASE, 4, 360.00)
    call RegisterBaseValue(API_ABILITY_CHAIN_HEAL, VALUE_BASE, 5, 450.00)

    call RegisterBaseValue(API_ABILITY_REJUVENATION, VALUE_BASE, 1, 200.00)
    call RegisterBaseValue(API_ABILITY_REJUVENATION, VALUE_BASE, 2, 300.00)
    call RegisterBaseValue(API_ABILITY_REJUVENATION, VALUE_BASE, 3, 400.00)
    call RegisterBaseValue(API_ABILITY_REJUVENATION, VALUE_BASE, 4, 500.00)
    call RegisterBaseValue(API_ABILITY_REJUVENATION, VALUE_BASE, 5, 600.00)

    call RegisterBaseValue(API_ABILITY_HEALING_RAIN, VALUE_BASE, 1, 10.00)
    call RegisterBaseValue(API_ABILITY_HEALING_RAIN, VALUE_BASE, 2, 20.00)
    call RegisterBaseValue(API_ABILITY_HEALING_RAIN, VALUE_BASE, 3, 30.00)
    call RegisterBaseValue(API_ABILITY_HEALING_RAIN, VALUE_BASE, 4, 40.00)
    call RegisterBaseValue(API_ABILITY_HEALING_RAIN, VALUE_BASE, 5, 50.00)

    call RegisterBaseValue(API_ABILITY_WATER_SHIELD, VALUE_BASE, 1, 100.00)
    call RegisterBaseValue(API_ABILITY_WATER_SHIELD, VALUE_BASE, 2, 200.00)
    call RegisterBaseValue(API_ABILITY_WATER_SHIELD, VALUE_BASE, 3, 250.00)
    call RegisterBaseValue(API_ABILITY_WATER_SHIELD, VALUE_BASE, 4, 300.00)
    call RegisterBaseValue(API_ABILITY_WATER_SHIELD, VALUE_BASE, 5, 350.00)

    call RegisterBaseValue(API_ABILITY_ANCESTRAL_WARD, VALUE_BASE, 1, 100.00)
    call RegisterBaseValue(API_ABILITY_ANCESTRAL_WARD, VALUE_BASE, 2, 150.00)
    call RegisterBaseValue(API_ABILITY_ANCESTRAL_WARD, VALUE_BASE, 3, 200.00)
    call RegisterBaseValue(API_ABILITY_ANCESTRAL_WARD, VALUE_BASE, 4, 250.00)
    call RegisterBaseValue(API_ABILITY_ANCESTRAL_WARD, VALUE_BASE, 5, 300.00)
endfunction

public function HasBaseValue takes integer abilityId, integer valueType, integer rank returns boolean
    local Table abilityTable
    if abilityId == 0 or valueType <= 0 then
        return false
    endif
    if rank <= 0 then
        set rank = 1
    endif
    call Apply()
    set abilityTable = API_GetAbilityTable(abilityId, false)
    if abilityTable == 0 then
        return false
    endif
    return abilityTable.real.has(API_GetRankKey(valueType, rank))
endfunction

public function GetBaseValue takes integer abilityId, integer valueType, integer rank returns real
    local Table abilityTable
    if abilityId == 0 or valueType <= 0 then
        return 0.00
    endif
    if rank <= 0 then
        set rank = 1
    endif
    call Apply()
    set abilityTable = API_GetAbilityTable(abilityId, false)
    if abilityTable == 0 or not abilityTable.real.has(API_GetRankKey(valueType, rank)) then
        return 0.00
    endif
    return abilityTable.real[API_GetRankKey(valueType, rank)]
endfunction

public function GetUnitBaseValue takes unit caster, integer abilityId, integer valueType returns real
    return GetBaseValue(abilityId, valueType, API_GetUnitAbilityRank(caster, abilityId))
endfunction

public function ApplyDamageModifiers takes unit caster, integer abilityId, real amount returns real
    static if LIBRARY_Talents then
        return Talents_ApplyDamageBonus(caster, abilityId, amount)
    else
        return amount
    endif
endfunction

public function ApplyHealingModifiers takes unit caster, integer abilityId, real amount returns real
    static if LIBRARY_Talents then
        return Talents_ApplyHealBonus(caster, abilityId, amount)
    else
        return amount
    endif
endfunction

public function GetUnitDamageValue takes unit caster, integer abilityId, integer valueType returns real
    return ApplyDamageModifiers(caster, abilityId, GetUnitBaseValue(caster, abilityId, valueType))
endfunction

public function GetUnitHealingValue takes unit caster, integer abilityId, integer valueType returns real
    return ApplyHealingModifiers(caster, abilityId, GetUnitBaseValue(caster, abilityId, valueType))
endfunction

private function Init takes nothing returns nothing
    call Apply()
endfunction

endlibrary
