/**
    ShamanCommon

    Author: Valdemar
    Version:

    Description:
    Shared rawcodes, math, dummy helpers, and player-hero transfer utilities
    used by converted shaman ability libraries.

    Credits:
    - Old GUI Shaman Abilities triggers

    How to install:
    Requires `AbilitiesPlayerInit`. Import before converted shaman ability
    libraries. `Talents` and `AbilityPoints` are optional integration points.

    API:
    - set amount = ShamanCommon_GetDamageAmount(caster, abilityId, valueType, statType, statScale)
    - set amount = ShamanCommon_GetHealingAmount(caster, abilityId, valueType, statType, statScale)
    - set amount = ShamanCommon_GetHybridDamageAmount(caster, abilityId, valueType, primaryStat, primaryScale, secondaryStat, secondaryScale)
    - call ShamanCommon_SetRealField(caster, abilityId, field, value)
    - call ShamanCommon_ApplyCooldownReduction(caster, abilityId)
    - call ShamanCommon_RefreshAbility(caster, abilityId)
    - set dummy = ShamanCommon_CreateTimedDummy(owner, unitTypeId, x, y, facing, duration)
    - call ShamanCommon_PlaySoundLabelOnUnit(soundLabel, caster)

**/
library ShamanCommon initializer Init requires ExSound, ExSoundEditorSounds, AbilitiesPlayerInit, optional Talents, optional AbilityPoints

globals
    public constant integer STAT_NONE = 0
    public constant integer STAT_STRENGTH = 1
    public constant integer STAT_AGILITY = 2
    public constant integer STAT_INTELLIGENCE = 3

    public constant integer HERO_SLOT_NONE = 0
    public constant integer HERO_SLOT_NAZGREK = 1
    public constant integer HERO_SLOT_ZULKIS = 2

    public constant integer COMPANION_OWNER_PLAYER_INDEX = 18
    public constant integer BUFF_TIMED_LIFE = 'BTLF'

    public constant integer ABILITY_LIGHTNING_BOLT = 'A6A0'
    public constant integer ABILITY_LIGHTNING_STRIKE = 'A67H'
    public constant integer ABILITY_CHAIN_LIGHTNING = 'A67L'
    public constant integer ABILITY_FIRE_SHOCK = 'A67J'
    public constant integer ABILITY_FROST_SHOCK = 'A69L'
    public constant integer ABILITY_NATURE_SHOCK = 'A69N'
    public constant integer ABILITY_LIGHTNING_SHIELD = 'A68H'
    public constant integer ABILITY_SUMMON_ELEMENTAL = 'A67Q'
    public constant integer ABILITY_CHANNEL_AIR_ELEMENTAL = 'A61K'
    public constant integer ABILITY_CHANNEL_WATER_ELEMENTAL = 'A61L'
    public constant integer ABILITY_CHANNEL_FIRE_ELEMENTAL = 'A61M'
    public constant integer ABILITY_CHANNEL_EARTH_ELEMENTAL = 'A61N'

    public constant integer ABILITY_STORMSTRIKE = 'A685'
    public constant integer ABILITY_WHIRLWIND = 'A6DP'
    public constant integer ABILITY_WIND_SHEAR = 'A026'
    public constant integer ABILITY_PRIMAL_FORCE = 'A022'
    public constant integer ABILITY_BLOODLUST = 'A67N'
    public constant integer ABILITY_FERAL_SPIRITS = 'A679'
    public constant integer ABILITY_GHOST_WOLF_MORPH = 'A68Y'
    public constant integer ABILITY_GHOST_WOLF_NORMAL = 'A68Z'
    public constant integer ABILITY_GHOST_WOLF_PASSIVE = 'A68V'
    public constant integer ABILITY_GHOST_WOLF_BITE = 'A68K'
    public constant integer ABILITY_GHOST_WOLF_FURIOUS_HOWL = 'A69C'
    public constant integer ABILITY_ENHANCEMENT_CATEGORY = 'A67A'
    public constant integer ABILITY_HEX = 'A673'
    public constant integer ABILITY_HERO_SHAMAN_HEX = 'A005'
    public constant integer ABILITY_VOODOO_CURSE = 'A675'
    public constant integer ABILITY_VOODOO_SPIRITS = 'A677'

    public constant integer ABILITY_HEALING_WAVE = 'A66Y'
    public constant integer ABILITY_CHAIN_HEAL = 'A672'
    public constant integer ABILITY_HEALING_RAIN = 'A66W'
    public constant integer ABILITY_REJUVENATION = 'A69W'
    public constant integer ABILITY_WATER_SHIELD = 'A62Z'
    public constant integer ABILITY_SPIRIT_LINK = 'A01Z'
    public constant integer ABILITY_ANCESTRAL_WARD = 'A6AL'
    public constant integer ABILITY_SPIRITUAL_HEALING = 'A638'
    public constant integer ABILITY_TOTEMIC_RESURGENCE = 'A69Y'
    public constant integer ABILITY_REINCARNATION = 'A68A'

    public constant integer DUMMY_LIGHTNING_STRIKE = 'e602'
    public constant integer DUMMY_LIGHTNING_STRIKE_DOWN = 'e603'
    public constant integer DUMMY_SHOCK = 'h60M'
    public constant integer DUMMY_STORMSTRIKE = 'n631'
    public constant integer DUMMY_BITE = 'n638'
    public constant integer DUMMY_WIND_SHEAR = 'n00D'
    public constant integer DUMMY_PRIMAL_FORCE_WIND = 'n00B'
    public constant integer DUMMY_BLOODLUST = 'n00C'
    public constant integer DUMMY_CHAIN_HEAL = 'n63I'

    public constant integer ABILITY_FROST_SHOCK_BOLTS = 'A69M'
    public constant integer ABILITY_NATURE_SHOCK_ROOT = 'A69O'
    public constant integer ABILITY_WIND_SHEAR_DUMMY = 'A028'
    public constant integer ABILITY_PRIMAL_FORCE_WIND_DUMMY = 'A024'
    public constant integer ABILITY_BLOODLUST_DUMMY = 'A025'

    public constant integer ABILITY_STORMSTRIKE_DAMAGE_1 = 'A684'
    public constant integer ABILITY_STORMSTRIKE_DAMAGE_2 = 'A686'
    public constant integer ABILITY_STORMSTRIKE_DAMAGE_3 = 'A687'
    public constant integer ABILITY_STORMSTRIKE_DAMAGE_4 = 'A688'
    public constant integer ABILITY_STORMSTRIKE_DAMAGE_5 = 'A689'

    public constant integer ABILITY_BITE_DAMAGE_1 = 'A68M'
    public constant integer ABILITY_BITE_DAMAGE_2 = 'A693'
    public constant integer ABILITY_BITE_DAMAGE_3 = 'A699'
    public constant integer ABILITY_BITE_DAMAGE_4 = 'A69A'
    public constant integer ABILITY_BITE_DAMAGE_5 = 'A69B'

    public constant integer BUFF_BLOODLUST_1 = 'B01O'
    public constant integer BUFF_BLOODLUST_2 = 'B01P'
    public constant integer BUFF_BLOODLUST_3 = 'B01Q'
    public constant integer BUFF_BLOODLUST_4 = 'B01R'
    public constant integer BUFF_BLOODLUST_5 = 'B01S'
    public constant integer BUFF_LIGHTNING_SHIELD = 'B60I'
    public constant integer BUFF_ANCESTRAL_WARD = 'B614'
    public constant integer BUFF_WATER_SHIELD = 'B615'

    public constant integer UNIT_AIR_ELEMENTAL = 'h60D'
    public constant integer UNIT_WATER_ELEMENTAL = 'h60C'
    public constant integer UNIT_FIRE_ELEMENTAL = 'n616'
    public constant integer UNIT_EARTH_ELEMENTAL = 'n615'
    public constant integer UNIT_NAZGREK_GHOST_WOLF = 'H60K'
    public constant integer UNIT_ZULKIS_GHOST_WOLF = 'O61Y'
    public constant integer UNIT_ZULKIS_RANGED_GHOST_WOLF = 'O61Z'

    public constant integer UNIT_SPIRIT_WOLF_1 = 'npig'
    public constant integer UNIT_SPIRIT_WOLF_2 = 'nwlt'
    public constant integer UNIT_SPIRIT_WOLF_3 = 'n61T'
    public constant integer UNIT_SPIRIT_WOLF_4 = 'nwlg'
    public constant integer UNIT_SPIRIT_WOLF_5 = 'nwld'
    public constant integer UNIT_SPIRIT_WOLF_OSW1 = 'osw1'
    public constant integer UNIT_SPIRIT_WOLF_OSW2 = 'osw2'
    public constant integer UNIT_SPIRIT_WOLF_OSW3 = 'osw3'

    public constant integer UNIT_TOTEM_EARTH_1 = 'o616'
    public constant integer UNIT_TOTEM_EARTH_2 = 'o61N'
    public constant integer UNIT_TOTEM_EARTH_3 = 'o62C'
    public constant integer UNIT_TOTEM_FIRE_1 = 'o617'
    public constant integer UNIT_TOTEM_FIRE_2 = 'o61O'
    public constant integer UNIT_TOTEM_WIND_1 = 'o618'
    public constant integer UNIT_TOTEM_WIND_2 = 'o61Q'
    public constant integer UNIT_TOTEM_WATER_1 = 'o619'
    public constant integer UNIT_TOTEM_WATER_2 = 'o61P'
    public constant integer UNIT_TOTEM_EARTHBIND_1 = 'o620'
    public constant integer UNIT_TOTEM_EARTHBIND_2 = 'o62A'
    public constant integer UNIT_TOTEM_STONESKIN = 'o621'
    public constant integer UNIT_TOTEM_SKYFURY_1 = 'o622'
    public constant integer UNIT_TOTEM_SKYFURY_2 = 'o62D'
    public constant integer UNIT_TOTEM_WINDFURY_1 = 'o623'
    public constant integer UNIT_TOTEM_WINDFURY_2 = 'o62B'
    public constant integer UNIT_TOTEM_CLEANSING_1 = 'o62L'
    public constant integer UNIT_TOTEM_CLEANSING_2 = 'o62M'
endglobals

public function IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
endfunction

public function IsPlayerHero takes unit whichUnit returns boolean
    return whichUnit != null and (whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis)
endfunction

public function GetHeroSlot takes unit whichUnit returns integer
    if whichUnit == udg_Nazgrek or whichUnit == udg_NazgrekMorph then
        return HERO_SLOT_NAZGREK
    elseif whichUnit == udg_Zulkis or whichUnit == udg_ZulkisMorph then
        return HERO_SLOT_ZULKIS
    endif
    return HERO_SLOT_NONE
endfunction

public function GetHeroBySlot takes integer heroSlot returns unit
    if heroSlot == HERO_SLOT_NAZGREK then
        return udg_Nazgrek
    elseif heroSlot == HERO_SLOT_ZULKIS then
        return udg_Zulkis
    endif
    return null
endfunction

public function SetHeroBySlot takes integer heroSlot, unit whichHero returns nothing
    if heroSlot == HERO_SLOT_NAZGREK then
        set udg_Nazgrek = whichHero
    elseif heroSlot == HERO_SLOT_ZULKIS then
        set udg_Zulkis = whichHero
    endif
endfunction

public function ClampRank takes integer rank returns integer
    if rank < 1 then
        return 1
    elseif rank > 5 then
        return 5
    endif
    return rank
endfunction

public function GetAbilityRank takes unit caster, integer abilityId returns integer
    return ClampRank(GetUnitAbilityLevel(caster, abilityId))
endfunction

public function GetStat takes unit whichUnit, integer statType returns real
    if whichUnit == null then
        return 0.00
    elseif statType == STAT_STRENGTH then
        return I2R(GetHeroStr(whichUnit, true))
    elseif statType == STAT_AGILITY then
        return I2R(GetHeroAgi(whichUnit, true))
    elseif statType == STAT_INTELLIGENCE then
        return I2R(GetHeroInt(whichUnit, true))
    endif
    return 0.00
endfunction

public function GetRawAmount takes unit caster, integer abilityId, integer valueType, integer statType, real statScale returns real
    return AbilitiesPlayerInit_GetUnitBaseValue(caster, abilityId, valueType) + GetStat(caster, statType) * statScale
endfunction

public function GetHybridRawAmount takes unit caster, integer abilityId, integer valueType, integer primaryStatType, real primaryStatScale, integer secondaryStatType, real secondaryStatScale returns real
    return AbilitiesPlayerInit_GetUnitBaseValue(caster, abilityId, valueType) + GetStat(caster, primaryStatType) * primaryStatScale + GetStat(caster, secondaryStatType) * secondaryStatScale
endfunction

public function GetDamageAmount takes unit caster, integer abilityId, integer valueType, integer statType, real statScale returns real
    return AbilitiesPlayerInit_ApplyDamageModifiers(caster, abilityId, GetRawAmount(caster, abilityId, valueType, statType, statScale))
endfunction

public function GetHealingAmount takes unit caster, integer abilityId, integer valueType, integer statType, real statScale returns real
    return AbilitiesPlayerInit_ApplyHealingModifiers(caster, abilityId, GetRawAmount(caster, abilityId, valueType, statType, statScale))
endfunction

public function GetHybridDamageAmount takes unit caster, integer abilityId, integer valueType, integer primaryStatType, real primaryStatScale, integer secondaryStatType, real secondaryStatScale returns real
    return AbilitiesPlayerInit_ApplyDamageModifiers(caster, abilityId, GetHybridRawAmount(caster, abilityId, valueType, primaryStatType, primaryStatScale, secondaryStatType, secondaryStatScale))
endfunction

public function GetHybridHealingAmount takes unit caster, integer abilityId, integer valueType, integer primaryStatType, real primaryStatScale, integer secondaryStatType, real secondaryStatScale returns real
    return AbilitiesPlayerInit_ApplyHealingModifiers(caster, abilityId, GetHybridRawAmount(caster, abilityId, valueType, primaryStatType, primaryStatScale, secondaryStatType, secondaryStatScale))
endfunction

public function GetSpecialBonusValue takes unit caster, integer abilityId returns integer
    static if LIBRARY_Talents then
        return Talents_GetEffectBonusPercent(caster, Talents_EFFECT_SPECIAL, abilityId)
    else
        return 0
    endif
endfunction

public function ApplySpecialRankBonus takes unit caster, integer abilityId, real amount, real percentPerSpecialValue returns real
    return amount * (1.00 + I2R(GetSpecialBonusValue(caster, abilityId)) * percentPerSpecialValue / 100.00)
endfunction

public function GetCooldownBonusPercent takes unit caster, integer abilityId returns integer
    static if LIBRARY_Talents then
        return Talents_GetCooldownBonusPercent(caster, abilityId)
    else
        return 0
    endif
endfunction

public function ApplyCooldownReduction takes unit caster, integer abilityId returns nothing
    local integer bonus = GetCooldownBonusPercent(caster, abilityId)
    local integer rank
    local real cooldown
    local ability whichAbility

    if caster == null or abilityId == 0 or bonus <= 0 then
        return
    endif
    if bonus >= 100 then
        call BlzStartUnitAbilityCooldown(caster, abilityId, 0.00)
        return
    endif

    set cooldown = BlzGetUnitAbilityCooldownRemaining(caster, abilityId)
    if cooldown <= 0.00 then
        set rank = GetAbilityRank(caster, abilityId)
        set whichAbility = BlzGetUnitAbility(caster, abilityId)
        if whichAbility != null then
            set cooldown = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_COOLDOWN, rank - 1)
        endif
    endif
    if cooldown > 0.00 then
        call BlzStartUnitAbilityCooldown(caster, abilityId, cooldown * (1.00 - I2R(bonus) / 100.00))
    endif

    set whichAbility = null
endfunction

public function SetRealField takes unit caster, integer abilityId, abilityreallevelfield whichField, real value returns nothing
    local integer rank = GetAbilityRank(caster, abilityId)
    local ability whichAbility = BlzGetUnitAbility(caster, abilityId)
    if whichAbility != null then
        call BlzSetAbilityRealLevelField(whichAbility, whichField, rank - 1, value)
    endif
    set whichAbility = null
endfunction

public function SetIntegerField takes unit caster, integer abilityId, abilityintegerlevelfield whichField, integer value returns nothing
    local integer rank = GetAbilityRank(caster, abilityId)
    local ability whichAbility = BlzGetUnitAbility(caster, abilityId)
    if whichAbility != null then
        call BlzSetAbilityIntegerLevelField(whichAbility, whichField, rank - 1, value)
    endif
    set whichAbility = null
endfunction

public function RefreshAbility takes unit caster, integer abilityId returns nothing
    local integer rank
    if caster == null or GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return
    endif
    set rank = GetUnitAbilityLevel(caster, abilityId)
    if rank > 1 then
        call DecUnitAbilityLevel(caster, abilityId)
        call IncUnitAbilityLevel(caster, abilityId)
    else
        call IncUnitAbilityLevel(caster, abilityId)
        call DecUnitAbilityLevel(caster, abilityId)
    endif
    call SetUnitAbilityLevel(caster, abilityId, rank)
endfunction

public function CreateTimedDummy takes player owner, integer unitTypeId, real x, real y, real facing, real duration returns unit
    local unit dummy
    if owner == null or unitTypeId == 0 then
        return null
    endif
    set dummy = CreateUnit(owner, unitTypeId, x, y, facing)
    if duration > 0.00 then
        call UnitApplyTimedLife(dummy, BUFF_TIMED_LIFE, duration)
    endif
    return dummy
endfunction

public function PolarX takes real x, real distance, real angle returns real
    return x + distance * Cos(angle * bj_DEGTORAD)
endfunction

public function PolarY takes real y, real distance, real angle returns real
    return y + distance * Sin(angle * bj_DEGTORAD)
endfunction

public function AngleBetweenCoordinates takes real ax, real ay, real bx, real by returns real
    return bj_RADTODEG * Atan2(by - ay, bx - ax)
endfunction

public function DistanceBetweenCoordinates takes real ax, real ay, real bx, real by returns real
    local real dx = bx - ax
    local real dy = by - ay
    return SquareRoot(dx * dx + dy * dy)
endfunction

public function PlaySound takes sound whichSound returns nothing
    call ExSound_PlayHandle(whichSound)
endfunction

public function PlaySoundAtPoint takes sound whichSound, real x, real y returns nothing
    call ExSound_PlayHandleAtPoint(whichSound, x, y)
endfunction

public function PlaySoundOnUnit takes sound whichSound, unit whichUnit returns nothing
    call ExSound_PlayHandleOnUnit(whichSound, whichUnit)
endfunction

public function PlaySoundLabel takes string soundLabel returns nothing
    call ExSound_PlayLabel(soundLabel, false)
endfunction

public function PlaySoundLabelAtPoint takes string soundLabel, real x, real y returns nothing
    call ExSound_PlayLabelAtPoint(soundLabel, x, y, false)
endfunction

public function PlaySoundLabelOnUnit takes string soundLabel, unit whichUnit returns nothing
    call ExSound_PlayLabelOnUnit(soundLabel, whichUnit, false)
endfunction

public function PlaySoundLabelOrPath takes string soundLabel, string soundPath returns nothing
    call ExSound_PlayLabelOrPath(soundLabel, soundPath, false)
endfunction

public function PlaySoundLabelOrPathAtPoint takes string soundLabel, string soundPath, real x, real y returns nothing
    call ExSound_PlayLabelOrPathAtPoint(soundLabel, soundPath, x, y, false)
endfunction

public function PlaySoundLabelOrPathOnUnit takes string soundLabel, string soundPath, unit whichUnit returns nothing
    call ExSound_PlayLabelOrPathOnUnit(soundLabel, soundPath, whichUnit, false)
endfunction

public function PlaySoundHandleLabelOrPathOnUnit takes sound whichSound, string soundLabel, string soundPath, unit whichUnit returns nothing
    call ExSound_PlayHandleLabelOrPathOnUnit(whichSound, soundLabel, soundPath, whichUnit, false)
endfunction

public function PlaySoundPath takes string soundPath returns nothing
    call ExSound_PlayPath(soundPath, false)
endfunction

public function PlaySoundPathAtPoint takes string soundPath, real x, real y returns nothing
    call ExSound_PlayPathAtPoint(soundPath, x, y, false)
endfunction

public function PlaySoundPathOnUnit takes string soundPath, unit whichUnit returns nothing
    call ExSound_PlayPathOnUnit(soundPath, whichUnit, false)
endfunction

public function SelectForOwner takes unit whichUnit returns nothing
    if whichUnit != null then
        call SelectUnitForPlayerSingle(whichUnit, GetOwningPlayer(whichUnit))
    endif
endfunction

public function TransferInventory takes unit source, unit target returns nothing
    local integer slot = 0
    local item whichItem
    if source == null or target == null then
        return
    endif
    loop
        exitwhen slot >= 6
        set whichItem = UnitRemoveItemFromSlot(source, slot)
        if whichItem != null then
            call UnitAddItem(target, whichItem)
        endif
        set slot = slot + 1
    endloop
    set whichItem = null
endfunction

public function TransferHeroLevelExperience takes unit source, unit target returns nothing
    if source == null or target == null then
        return
    endif
    static if LIBRARY_AbilityPoints then
        call AbilityPoints_DisableHeroLevelUp()
    endif
    call SetHeroLevel(target, GetHeroLevel(source), false)
    call SetHeroXP(target, GetHeroXP(source), false)
    static if LIBRARY_AbilityPoints then
        call AbilityPoints_EnableHeroLevelUp()
    endif
endfunction

public function TransferHeroState takes unit source, unit target returns nothing
    if source == null or target == null then
        return
    endif
    call TransferHeroLevelExperience(source, target)
    call SetHeroStr(target, GetHeroStr(source, true), true)
    call SetHeroAgi(target, GetHeroAgi(source, true), true)
    call SetHeroInt(target, GetHeroInt(source, true), true)
    call SetUnitState(target, UNIT_STATE_LIFE, GetUnitState(source, UNIT_STATE_LIFE))
    call SetUnitState(target, UNIT_STATE_MANA, GetUnitState(source, UNIT_STATE_MANA))
    call TransferInventory(source, target)
endfunction

public function AddLife takes unit target, real amount returns nothing
    if target != null and amount > 0.00 then
        call SetUnitState(target, UNIT_STATE_LIFE, GetUnitState(target, UNIT_STATE_LIFE) + amount)
    endif
endfunction

public function AddMana takes unit target, real amount returns nothing
    if target != null and amount > 0.00 then
        call SetUnitState(target, UNIT_STATE_MANA, GetUnitState(target, UNIT_STATE_MANA) + amount)
    endif
endfunction

public function IsHostileGroundTarget takes unit source, unit target, boolean rejectMechanical returns boolean
    if not IsAlive(target) or source == null or target == source then
        return false
    elseif IsUnitType(target, UNIT_TYPE_STRUCTURE) or IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE) then
        return false
    elseif IsUnitType(target, UNIT_TYPE_FLYING) or not IsUnitType(target, UNIT_TYPE_GROUND) then
        return false
    elseif rejectMechanical and IsUnitType(target, UNIT_TYPE_MECHANICAL) then
        return false
    endif
    return IsUnitEnemy(target, GetOwningPlayer(source))
endfunction

public function IsTotemUnitType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_EARTH_1 /*
        */ or unitTypeId == UNIT_TOTEM_EARTH_2 /*
        */ or unitTypeId == UNIT_TOTEM_EARTH_3 /*
        */ or unitTypeId == UNIT_TOTEM_FIRE_1 /*
        */ or unitTypeId == UNIT_TOTEM_FIRE_2 /*
        */ or unitTypeId == UNIT_TOTEM_WIND_1 /*
        */ or unitTypeId == UNIT_TOTEM_WIND_2 /*
        */ or unitTypeId == UNIT_TOTEM_WATER_1 /*
        */ or unitTypeId == UNIT_TOTEM_WATER_2 /*
        */ or unitTypeId == UNIT_TOTEM_EARTHBIND_1 /*
        */ or unitTypeId == UNIT_TOTEM_EARTHBIND_2 /*
        */ or unitTypeId == UNIT_TOTEM_STONESKIN /*
        */ or unitTypeId == UNIT_TOTEM_SKYFURY_1 /*
        */ or unitTypeId == UNIT_TOTEM_SKYFURY_2 /*
        */ or unitTypeId == UNIT_TOTEM_WINDFURY_1 /*
        */ or unitTypeId == UNIT_TOTEM_WINDFURY_2 /*
        */ or unitTypeId == UNIT_TOTEM_CLEANSING_1 /*
        */ or unitTypeId == UNIT_TOTEM_CLEANSING_2
endfunction

public function IsEarthTotemUnitType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_EARTH_1 or unitTypeId == UNIT_TOTEM_EARTH_2 or unitTypeId == UNIT_TOTEM_EARTH_3 or unitTypeId == UNIT_TOTEM_EARTHBIND_1 or unitTypeId == UNIT_TOTEM_EARTHBIND_2 or unitTypeId == UNIT_TOTEM_STONESKIN
endfunction

public function IsWaterTotemUnitType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_WATER_1 or unitTypeId == UNIT_TOTEM_WATER_2 or unitTypeId == UNIT_TOTEM_CLEANSING_1 or unitTypeId == UNIT_TOTEM_CLEANSING_2
endfunction

public function IsWindTotemUnitType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_WIND_1 or unitTypeId == UNIT_TOTEM_WIND_2 or unitTypeId == UNIT_TOTEM_WINDFURY_1 or unitTypeId == UNIT_TOTEM_WINDFURY_2
endfunction

public function IsFireTotemUnitType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_FIRE_1 or unitTypeId == UNIT_TOTEM_FIRE_2 or unitTypeId == UNIT_TOTEM_SKYFURY_1 or unitTypeId == UNIT_TOTEM_SKYFURY_2
endfunction

public function IsSpiritWolfUnitType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_SPIRIT_WOLF_1 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_2 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_3 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_4 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_5 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_OSW1 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_OSW2 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_OSW3
endfunction

private function Init takes nothing returns nothing
    call ExSoundEditorSounds_RegisterAll()
endfunction

endlibrary
