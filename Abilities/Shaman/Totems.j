/**
    Totems

    Author: Valdemar
    Version:

    Description:
    MUI shaman totem system converted from the old GUI Totemic Abilities
    triggers. Totems are tracked per caster and element slot, so player heroes
    and AI shamans can use the same ability rawcodes without shared globals.

    Credits:
    - Old GUI Totemic Abilities triggers

    How to install:
    Requires `Table`, `DamageEngine`, `Events`, and `UnitDeathEvent`.

    API:
    call Totems_CanCast(unit caster, integer abilityId)
    call Totems_GetLiveTotem(unit caster, integer abilityId)

**/
library Totems initializer Init requires Table, DamageEngine, Events, UnitDeathEvent, FallenHeroState

globals
    private constant integer MAX_ACTIVE_TOTEMS = 512
    private constant integer MAX_SKYFURY_TARGETS = 512

    private constant integer TOTEM_SLOT_EARTH = 1
    private constant integer TOTEM_SLOT_FIRE = 2
    private constant integer TOTEM_SLOT_WATER = 3
    private constant integer TOTEM_SLOT_WIND = 4

    private constant real TOTEM_DURATION_DEFAULT = 45.00
    private constant real TOTEM_DURATION_EARTHBIND = 10.00
    private constant real TOTEM_TEXT_SIZE = 5.00
    private constant real TOTEM_TEXT_OFFSET_Z = -175.00
    private constant real TOTEM_TEXT_VISIBLE_RANGE = 1000.00
    private constant real TOTEM_PERIOD = 0.25
    private constant real TOTEM_CLEANSING_PERIOD = 5.00
    private constant real TOTEM_AURA_RADIUS = 500.00
    private constant real WINDFURY_PROC_CHANCE = 20.00
    private constant real WINDFURY_DAMAGE_MULTIPLIER = 1.20
    private constant real WINDFURY_EFFECT_DURATION = 1.50
    private constant real WINDFURY_EFFECT_SCALE = 0.60

    private constant string EFFECT_TOTEM_MASTER = "Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl"
    private constant string EFFECT_CLEANSING = "Abilities\\Spells\\Human\\DispelMagic\\DispelMagicTarget.mdl"
    private constant string EFFECT_WINDFURY = "Abilities\\Spells\\Other\\Tornado\\Tornado_Target.mdl"

    private constant integer ABILITY_AI_TOTEM_WINDFURY = 'A006'
    private constant integer ABILITY_AI_TOTEM_WATER = 'A007'
    private constant integer ABILITY_AI_TOTEM_EARTH = 'A008'
    private constant integer ABILITY_AI_TOTEM_EARTHBIND = 'A009'
    private constant integer ABILITY_AI_TOTEM_FIRE = 'A00A'
    private constant integer ABILITY_AI_TOTEM_STONESKIN = 'A00B'
    private constant integer ABILITY_AI_TOTEM_WIND = 'A00C'

    private constant integer ABILITY_TOTEM_EARTH = 'A63F'
    private constant integer ABILITY_TOTEM_FIRE = 'A63G'
    private constant integer ABILITY_TOTEM_WATER = 'A63H'
    private constant integer ABILITY_TOTEM_WIND = 'A63I'
    private constant integer ABILITY_TOTEM_SKYFURY = 'A01U'
    private constant integer ABILITY_TOTEM_CLEANSING = 'A68F'
    private constant integer ABILITY_TOTEM_STONESKIN = 'A68J'
    private constant integer ABILITY_TOTEM_EARTHBIND = 'A68L'
    private constant integer ABILITY_TOTEM_WINDFURY = 'A68T'
    private constant integer ABILITY_TOTEM_MASTER = 'A636'

    private constant integer UNIT_TOTEM_EARTH_1 = 'o616'
    private constant integer UNIT_TOTEM_EARTH_2 = 'o61N'
    private constant integer UNIT_TOTEM_EARTH_3 = 'o62C'
    private constant integer UNIT_TOTEM_FIRE_1 = 'o617'
    private constant integer UNIT_TOTEM_FIRE_2 = 'o61O'
    private constant integer UNIT_TOTEM_WIND_1 = 'o618'
    private constant integer UNIT_TOTEM_WIND_2 = 'o61Q'
    private constant integer UNIT_TOTEM_WATER_1 = 'o619'
    private constant integer UNIT_TOTEM_WATER_2 = 'o61P'
    private constant integer UNIT_TOTEM_EARTHBIND_1 = 'o620'
    private constant integer UNIT_TOTEM_EARTHBIND_2 = 'o62A'
    private constant integer UNIT_TOTEM_STONESKIN = 'o621'
    private constant integer UNIT_TOTEM_SKYFURY_1 = 'o622'
    private constant integer UNIT_TOTEM_SKYFURY_2 = 'o62D'
    private constant integer UNIT_TOTEM_WINDFURY_1 = 'o623'
    private constant integer UNIT_TOTEM_WINDFURY_2 = 'o62B'
    private constant integer UNIT_TOTEM_CLEANSING_1 = 'o62L'
    private constant integer UNIT_TOTEM_CLEANSING_2 = 'o62M'

    private constant integer BUFF_FIRE_SHIELD = 'B60B'
    private constant integer BUFF_FIRE_SHIELD_CASTER = 'B60F'
    private constant integer BUFF_WINDFURY_1 = 'B60M'
    private constant integer BUFF_WINDFURY_2 = 'B60S'
    private constant integer BUFF_TIMED_LIFE = 'BTLF'

    private Table TotemByCasterSlot = 0
    private Table TotemCasterByHandle = 0
    private Table TotemSlotByHandle = 0
    private Table TotemTextByHandle = 0
    private Table ActiveTotemTracked = 0
    private Table TimedEffectByTimer = 0
    private Table SkyfuryBonusByHandle = 0
    private Table SkyfuryDesiredByHandle = 0
    private Table SkyfurySeenPass = 0
    private Table SkyfuryTracked = 0
    private Table SkyfuryTargetIndexByHandle = 0

    private timer PeriodicTimer = null
    private group EnumGroup = null

    private unit array ActiveTotems
    private integer ActiveTotemCount = 0
    private unit array SkyfuryTargets
    private integer SkyfuryTargetCount = 0
    private integer SkyfuryScanPass = 0
    private real CleansingElapsed = 0.00
    private boolean WindfuryDamageActive = false
endglobals

private function EnsureState takes nothing returns nothing
    if TotemByCasterSlot == 0 then
        set TotemByCasterSlot = Table.create()
        set TotemCasterByHandle = Table.create()
        set TotemSlotByHandle = Table.create()
        set TotemTextByHandle = Table.create()
        set ActiveTotemTracked = Table.create()
        set TimedEffectByTimer = Table.create()
        set SkyfuryBonusByHandle = Table.create()
        set SkyfuryDesiredByHandle = Table.create()
        set SkyfurySeenPass = Table.create()
        set SkyfuryTracked = Table.create()
        set SkyfuryTargetIndexByHandle = Table.create()
        set EnumGroup = CreateGroup()
    endif
endfunction

private function IsAliveUnit takes unit whichUnit returns boolean
    return FallenHeroState_IsAlive(whichUnit)
endfunction

private function IsPlayerTotemAbility takes integer abilityId returns boolean
    return abilityId == ABILITY_TOTEM_EARTH /*
        */ or abilityId == ABILITY_TOTEM_FIRE /*
        */ or abilityId == ABILITY_TOTEM_WATER /*
        */ or abilityId == ABILITY_TOTEM_WIND /*
        */ or abilityId == ABILITY_TOTEM_STONESKIN /*
        */ or abilityId == ABILITY_TOTEM_EARTHBIND /*
        */ or abilityId == ABILITY_TOTEM_SKYFURY /*
        */ or abilityId == ABILITY_TOTEM_WINDFURY /*
        */ or abilityId == ABILITY_TOTEM_CLEANSING
endfunction

private function IsAITotemAbility takes integer abilityId returns boolean
    return abilityId == ABILITY_AI_TOTEM_EARTH /*
        */ or abilityId == ABILITY_AI_TOTEM_FIRE /*
        */ or abilityId == ABILITY_AI_TOTEM_WATER /*
        */ or abilityId == ABILITY_AI_TOTEM_WIND /*
        */ or abilityId == ABILITY_AI_TOTEM_STONESKIN /*
        */ or abilityId == ABILITY_AI_TOTEM_EARTHBIND /*
        */ or abilityId == ABILITY_AI_TOTEM_WINDFURY
endfunction

private function IsTotemAbility takes integer abilityId returns boolean
    return IsPlayerTotemAbility(abilityId) or IsAITotemAbility(abilityId)
endfunction

private function GetTotemSlotForAbility takes integer abilityId returns integer
    if abilityId == ABILITY_TOTEM_EARTH or abilityId == ABILITY_AI_TOTEM_EARTH /*
        */ or abilityId == ABILITY_TOTEM_STONESKIN or abilityId == ABILITY_AI_TOTEM_STONESKIN /*
        */ or abilityId == ABILITY_TOTEM_EARTHBIND or abilityId == ABILITY_AI_TOTEM_EARTHBIND then
        return TOTEM_SLOT_EARTH
    elseif abilityId == ABILITY_TOTEM_FIRE or abilityId == ABILITY_AI_TOTEM_FIRE or abilityId == ABILITY_TOTEM_SKYFURY then
        return TOTEM_SLOT_FIRE
    elseif abilityId == ABILITY_TOTEM_WATER or abilityId == ABILITY_AI_TOTEM_WATER or abilityId == ABILITY_TOTEM_CLEANSING then
        return TOTEM_SLOT_WATER
    elseif abilityId == ABILITY_TOTEM_WIND or abilityId == ABILITY_AI_TOTEM_WIND /*
        */ or abilityId == ABILITY_TOTEM_WINDFURY or abilityId == ABILITY_AI_TOTEM_WINDFURY then
        return TOTEM_SLOT_WIND
    endif
    return 0
endfunction

private function GetTotemSlotKey takes unit caster, integer slot returns integer
    return GetHandleId(caster) * 10 + slot
endfunction

private function GetTotemDuration takes integer abilityId returns real
    if abilityId == ABILITY_TOTEM_EARTHBIND or abilityId == ABILITY_AI_TOTEM_EARTHBIND then
        return TOTEM_DURATION_EARTHBIND
    endif
    return TOTEM_DURATION_DEFAULT
endfunction

private function GetTotemUnitType takes integer abilityId, integer level returns integer
    local boolean greater = level >= 2
    if abilityId == ABILITY_TOTEM_EARTH or abilityId == ABILITY_AI_TOTEM_EARTH then
        if greater then
            return UNIT_TOTEM_EARTH_2
        endif
        return UNIT_TOTEM_EARTH_1
    elseif abilityId == ABILITY_TOTEM_FIRE or abilityId == ABILITY_AI_TOTEM_FIRE then
        if greater then
            return UNIT_TOTEM_FIRE_2
        endif
        return UNIT_TOTEM_FIRE_1
    elseif abilityId == ABILITY_TOTEM_WATER or abilityId == ABILITY_AI_TOTEM_WATER then
        if greater then
            return UNIT_TOTEM_WATER_2
        endif
        return UNIT_TOTEM_WATER_1
    elseif abilityId == ABILITY_TOTEM_WIND or abilityId == ABILITY_AI_TOTEM_WIND then
        if greater then
            return UNIT_TOTEM_WIND_2
        endif
        return UNIT_TOTEM_WIND_1
    elseif abilityId == ABILITY_TOTEM_EARTHBIND or abilityId == ABILITY_AI_TOTEM_EARTHBIND then
        if greater then
            return UNIT_TOTEM_EARTHBIND_2
        endif
        return UNIT_TOTEM_EARTHBIND_1
    elseif abilityId == ABILITY_TOTEM_STONESKIN or abilityId == ABILITY_AI_TOTEM_STONESKIN then
        return UNIT_TOTEM_STONESKIN
    elseif abilityId == ABILITY_TOTEM_SKYFURY then
        if greater then
            return UNIT_TOTEM_SKYFURY_2
        endif
        return UNIT_TOTEM_SKYFURY_1
    elseif abilityId == ABILITY_TOTEM_WINDFURY or abilityId == ABILITY_AI_TOTEM_WINDFURY then
        if greater then
            return UNIT_TOTEM_WINDFURY_2
        endif
        return UNIT_TOTEM_WINDFURY_1
    elseif abilityId == ABILITY_TOTEM_CLEANSING then
        if greater then
            return UNIT_TOTEM_CLEANSING_2
        endif
        return UNIT_TOTEM_CLEANSING_1
    endif
    return 0
endfunction

private function IsTotemUnitType takes integer unitTypeId returns boolean
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

private function IsFireAutocastTotem takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_FIRE_1 or unitTypeId == UNIT_TOTEM_FIRE_2
endfunction

private function IsWindAutocastTotem takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_WIND_1 or unitTypeId == UNIT_TOTEM_WIND_2
endfunction

private function IsSkyfuryTotem takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_SKYFURY_1 or unitTypeId == UNIT_TOTEM_SKYFURY_2
endfunction

private function IsCleansingTotem takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TOTEM_CLEANSING_1 or unitTypeId == UNIT_TOTEM_CLEANSING_2
endfunction

private function GetSkyfuryBonus takes integer unitTypeId returns integer
    if unitTypeId == UNIT_TOTEM_SKYFURY_2 then
        return 10
    elseif unitTypeId == UNIT_TOTEM_SKYFURY_1 then
        return 5
    endif
    return 0
endfunction

private function GetTotemText takes integer abilityId returns string
    if abilityId == ABILITY_TOTEM_EARTH or abilityId == ABILITY_AI_TOTEM_EARTH then
        return "<Earth Totem>"
    elseif abilityId == ABILITY_TOTEM_FIRE or abilityId == ABILITY_AI_TOTEM_FIRE then
        return "<Fire Totem>"
    elseif abilityId == ABILITY_TOTEM_WATER or abilityId == ABILITY_AI_TOTEM_WATER then
        return "<Water Totem>"
    elseif abilityId == ABILITY_TOTEM_WIND or abilityId == ABILITY_AI_TOTEM_WIND then
        return "<Wind Totem>"
    elseif abilityId == ABILITY_TOTEM_STONESKIN or abilityId == ABILITY_AI_TOTEM_STONESKIN then
        return "<Stoneskin Totem>"
    elseif abilityId == ABILITY_TOTEM_EARTHBIND or abilityId == ABILITY_AI_TOTEM_EARTHBIND then
        return "<Earthbind Totem>"
    elseif abilityId == ABILITY_TOTEM_SKYFURY then
        return "<Skyfury Totem>"
    elseif abilityId == ABILITY_TOTEM_WINDFURY or abilityId == ABILITY_AI_TOTEM_WINDFURY then
        return "<Windfury Totem>"
    elseif abilityId == ABILITY_TOTEM_CLEANSING then
        return "<Cleansing Totem>"
    endif
    return "<Totem>"
endfunction

private function GetTotemTextRed takes integer abilityId returns integer
    if abilityId == ABILITY_TOTEM_FIRE or abilityId == ABILITY_AI_TOTEM_FIRE or abilityId == ABILITY_TOTEM_SKYFURY then
        return 255
    elseif abilityId == ABILITY_TOTEM_WIND or abilityId == ABILITY_AI_TOTEM_WIND /*
        */ or abilityId == ABILITY_TOTEM_WINDFURY or abilityId == ABILITY_AI_TOTEM_WINDFURY then
        return 191
    endif
    return 38
endfunction

private function GetTotemTextGreen takes integer abilityId returns integer
    if abilityId == ABILITY_TOTEM_EARTH or abilityId == ABILITY_AI_TOTEM_EARTH /*
        */ or abilityId == ABILITY_TOTEM_STONESKIN or abilityId == ABILITY_AI_TOTEM_STONESKIN /*
        */ or abilityId == ABILITY_TOTEM_EARTHBIND or abilityId == ABILITY_AI_TOTEM_EARTHBIND then
        return 255
    endif
    return 38
endfunction

private function GetTotemTextBlue takes integer abilityId returns integer
    if abilityId == ABILITY_TOTEM_WATER or abilityId == ABILITY_AI_TOTEM_WATER or abilityId == ABILITY_TOTEM_CLEANSING then
        return 255
    elseif abilityId == ABILITY_TOTEM_WIND or abilityId == ABILITY_AI_TOTEM_WIND /*
        */ or abilityId == ABILITY_TOTEM_WINDFURY or abilityId == ABILITY_AI_TOTEM_WINDFURY then
        return 191
    endif
    return 38
endfunction

private function RemoveActiveTotem takes unit totem returns nothing
    local integer handleId = GetHandleId(totem)
    local integer index = 1
    loop
        exitwhen index > ActiveTotemCount
        if ActiveTotems[index] == totem then
            set ActiveTotems[index] = ActiveTotems[ActiveTotemCount]
            set ActiveTotems[ActiveTotemCount] = null
            set ActiveTotemCount = ActiveTotemCount - 1
            call ActiveTotemTracked.boolean.remove(handleId)
            return
        endif
        set index = index + 1
    endloop
    call ActiveTotemTracked.boolean.remove(handleId)
endfunction

private function AddActiveTotem takes unit totem returns nothing
    local integer handleId = GetHandleId(totem)
    if totem != null and not ActiveTotemTracked.boolean[handleId] and ActiveTotemCount < MAX_ACTIVE_TOTEMS then
        set ActiveTotemCount = ActiveTotemCount + 1
        set ActiveTotems[ActiveTotemCount] = totem
        set ActiveTotemTracked.boolean[handleId] = true
    endif
endfunction

private function IsTotemTextVisibleAt takes real x, real y returns boolean
    local real dx = x - GetCameraTargetPositionX()
    local real dy = y - GetCameraTargetPositionY()
    return dx * dx + dy * dy <= TOTEM_TEXT_VISIBLE_RANGE * TOTEM_TEXT_VISIBLE_RANGE
endfunction

private function UpdateTotemTextVisibility takes unit totem returns nothing
    local texttag tt
    if totem != null then
        set tt = TotemTextByHandle.texttag[GetHandleId(totem)]
        if tt != null and GetLocalPlayer() == Player(0) then
            call SetTextTagVisibility(tt, IsTotemTextVisibleAt(GetUnitX(totem), GetUnitY(totem)))
        endif
    endif
    set tt = null
endfunction

private function DestroyTotemText takes unit totem returns nothing
    local integer handleId = GetHandleId(totem)
    local texttag tt = TotemTextByHandle.texttag[handleId]
    if tt != null then
        call DestroyTextTag(tt)
        call TotemTextByHandle.texttag.remove(handleId)
    endif
    set tt = null
endfunction

private function CreateTotemText takes unit totem, integer abilityId, real duration returns nothing
    local integer handleId = GetHandleId(totem)
    local texttag tt = CreateTextTag()
    call SetTextTagText(tt, GetTotemText(abilityId), TOTEM_TEXT_SIZE * 0.023 / 10.00)
    call SetTextTagPosUnit(tt, totem, TOTEM_TEXT_OFFSET_Z)
    call SetTextTagColor(tt, GetTotemTextRed(abilityId), GetTotemTextGreen(abilityId), GetTotemTextBlue(abilityId), 255)
    call SetTextTagPermanent(tt, false)
    call SetTextTagLifespan(tt, duration)
    call SetTextTagFadepoint(tt, duration - 1.00)
    call SetTextTagVelocity(tt, 0.00, 0.00)
    call SetTextTagVisibility(tt, false)
    set TotemTextByHandle.texttag[handleId] = tt
    call UpdateTotemTextVisibility(totem)
    set tt = null
endfunction

private function CleanupTotem takes unit totem returns nothing
    local integer handleId
    local unit caster
    local integer slot
    local integer slotKey
    if totem == null then
        return
    endif
    set handleId = GetHandleId(totem)
    set caster = TotemCasterByHandle.unit[handleId]
    set slot = TotemSlotByHandle.integer[handleId]
    if caster != null and slot > 0 then
        set slotKey = GetTotemSlotKey(caster, slot)
        if TotemByCasterSlot.unit[slotKey] == totem then
            call TotemByCasterSlot.unit.remove(slotKey)
        endif
    endif
    call DestroyTotemText(totem)
    call RemoveActiveTotem(totem)
    call TotemCasterByHandle.unit.remove(handleId)
    call TotemSlotByHandle.integer.remove(handleId)
    set caster = null
endfunction

private function GetLiveTotemForSlot takes unit caster, integer slot returns unit
    local unit totem
    if caster == null or slot <= 0 then
        return null
    endif
    call EnsureState()
    set totem = TotemByCasterSlot.unit[GetTotemSlotKey(caster, slot)]
    if totem != null and not IsAliveUnit(totem) then
        call CleanupTotem(totem)
        set totem = null
    endif
    return totem
endfunction

public function GetLiveTotem takes unit caster, integer abilityId returns unit
    return GetLiveTotemForSlot(caster, GetTotemSlotForAbility(abilityId))
endfunction

public function CanCast takes unit caster, integer abilityId returns boolean
    local integer slot = GetTotemSlotForAbility(abilityId)
    if caster == null or slot <= 0 then
        return false
    endif
    return GetLiveTotemForSlot(caster, slot) == null
endfunction

private function TrackTotem takes unit caster, unit totem, integer slot returns nothing
    local integer handleId = GetHandleId(totem)
    call EnsureState()
    set TotemByCasterSlot.unit[GetTotemSlotKey(caster, slot)] = totem
    set TotemCasterByHandle.unit[handleId] = caster
    set TotemSlotByHandle.integer[handleId] = slot
    call AddActiveTotem(totem)
endfunction

private function SpawnTotem takes unit caster, integer abilityId, real x, real y returns unit
    local integer level = 1
    local integer slot = GetTotemSlotForAbility(abilityId)
    local integer unitTypeId
    local real duration = GetTotemDuration(abilityId)
    local unit oldTotem
    local unit totem
    if caster == null or slot <= 0 then
        return null
    endif
    set level = GetUnitAbilityLevel(caster, abilityId)
    if level <= 0 then
        set level = 1
    endif
    set unitTypeId = GetTotemUnitType(abilityId, level)
    if unitTypeId == 0 then
        return null
    endif
    set oldTotem = GetLiveTotemForSlot(caster, slot)
    if oldTotem != null then
        call KillUnit(oldTotem)
    endif
    set totem = CreateUnit(GetOwningPlayer(caster), unitTypeId, x, y, bj_UNIT_FACING)
    call UnitApplyTimedLife(totem, BUFF_TIMED_LIFE, duration)
    call SetUnitPathing(totem, false)
    call TrackTotem(caster, totem, slot)
    call CreateTotemText(totem, abilityId, duration)
    if abilityId == ABILITY_TOTEM_EARTHBIND or abilityId == ABILITY_AI_TOTEM_EARTHBIND then
        call IssueImmediateOrder(totem, "slowon")
    endif
    set oldTotem = null
    return totem
endfunction

private function SetSkyfuryBonus takes unit target, integer newBonus returns nothing
    local integer handleId
    local integer oldBonus
    local integer diff
    local integer unitIndex
    if target == null then
        return
    endif
    set handleId = GetHandleId(target)
    set oldBonus = SkyfuryBonusByHandle.integer[handleId]
    set diff = newBonus - oldBonus
    set unitIndex = GetUnitUserData(target)
    if unitIndex <= 0 then
        set unitIndex = SkyfuryTargetIndexByHandle.integer[handleId]
    endif
    if unitIndex <= 0 then
        return
    endif
    if diff != 0 then
        set udg_Stats_Crit[unitIndex] = udg_Stats_Crit[unitIndex] + diff
        set udg_Stats_SpellPowerPct[unitIndex] = udg_Stats_SpellPowerPct[unitIndex] + diff
    endif
    if newBonus > 0 then
        set SkyfuryBonusByHandle.integer[handleId] = newBonus
        set SkyfuryTargetIndexByHandle.integer[handleId] = unitIndex
    else
        call SkyfuryBonusByHandle.integer.remove(handleId)
        call SkyfuryTargetIndexByHandle.integer.remove(handleId)
    endif
endfunction

private function TrackSkyfuryTarget takes unit target returns nothing
    local integer handleId = GetHandleId(target)
    if not SkyfuryTracked.boolean[handleId] and SkyfuryTargetCount < MAX_SKYFURY_TARGETS then
        set SkyfuryTargetCount = SkyfuryTargetCount + 1
        set SkyfuryTargets[SkyfuryTargetCount] = target
        set SkyfuryTracked.boolean[handleId] = true
    endif
endfunction

private function UpdateSkyfuryCandidate takes unit source, unit target, integer bonus returns nothing
    local integer handleId
    if bonus <= 0 or not IsAliveUnit(target) then
        return
    elseif IsUnitType(target, UNIT_TYPE_STRUCTURE) or not IsUnitAlly(target, GetOwningPlayer(source)) then
        return
    elseif GetUnitUserData(target) <= 0 then
        return
    endif
    set handleId = GetHandleId(target)
    if SkyfurySeenPass.integer[handleId] != SkyfuryScanPass then
        set SkyfurySeenPass.integer[handleId] = SkyfuryScanPass
        set SkyfuryDesiredByHandle.integer[handleId] = bonus
        call TrackSkyfuryTarget(target)
    elseif SkyfuryDesiredByHandle.integer[handleId] < bonus then
        set SkyfuryDesiredByHandle.integer[handleId] = bonus
    endif
endfunction

private function ScanSkyfurySource takes unit source returns nothing
    local integer bonus = GetSkyfuryBonus(GetUnitTypeId(source))
    local unit target
    call GroupClear(EnumGroup)
    call GroupEnumUnitsInRange(EnumGroup, GetUnitX(source), GetUnitY(source), TOTEM_AURA_RADIUS, null)
    loop
        set target = FirstOfGroup(EnumGroup)
        exitwhen target == null
        call GroupRemoveUnit(EnumGroup, target)
        call UpdateSkyfuryCandidate(source, target, bonus)
    endloop
    set target = null
endfunction

private function TickSkyfury takes nothing returns nothing
    local integer index = 1
    local integer writeIndex = 0
    local integer oldCount
    local unit totem
    local unit target
    local integer handleId
    local integer desired
    set SkyfuryScanPass = SkyfuryScanPass + 1
    loop
        exitwhen index > ActiveTotemCount
        set totem = ActiveTotems[index]
        if IsAliveUnit(totem) and IsSkyfuryTotem(GetUnitTypeId(totem)) then
            call ScanSkyfurySource(totem)
        endif
        set index = index + 1
    endloop
    set index = 1
    loop
        exitwhen index > SkyfuryTargetCount
        set target = SkyfuryTargets[index]
        set handleId = GetHandleId(target)
        set desired = 0
        if IsAliveUnit(target) and SkyfurySeenPass.integer[handleId] == SkyfuryScanPass then
            set desired = SkyfuryDesiredByHandle.integer[handleId]
        endif
        call SetSkyfuryBonus(target, desired)
        if desired > 0 then
            set writeIndex = writeIndex + 1
            set SkyfuryTargets[writeIndex] = target
        else
            call SkyfuryTracked.boolean.remove(handleId)
            call SkyfuryDesiredByHandle.integer.remove(handleId)
            call SkyfurySeenPass.integer.remove(handleId)
        endif
        set index = index + 1
    endloop
    set oldCount = SkyfuryTargetCount
    set SkyfuryTargetCount = writeIndex
    loop
        exitwhen writeIndex >= oldCount
        set writeIndex = writeIndex + 1
        set SkyfuryTargets[writeIndex] = null
    endloop
    set totem = null
    set target = null
endfunction

private function DispelNearCleansingTotem takes unit totem returns nothing
    local unit target
    local player owner = GetOwningPlayer(totem)
    call GroupClear(EnumGroup)
    call GroupEnumUnitsInRange(EnumGroup, GetUnitX(totem), GetUnitY(totem), TOTEM_AURA_RADIUS, null)
    loop
        set target = FirstOfGroup(EnumGroup)
        exitwhen target == null
        call GroupRemoveUnit(EnumGroup, target)
        if IsAliveUnit(target) and not IsUnitType(target, UNIT_TYPE_STRUCTURE) then
            if IsUnitAlly(target, owner) then
                call UnitRemoveBuffsEx(target, false, true, true, true, true, false, false)
                call DestroyEffect(AddSpecialEffectTarget(EFFECT_CLEANSING, target, "overhead"))
            elseif IsUnitEnemy(target, owner) then
                call UnitRemoveBuffsEx(target, true, false, true, true, true, false, false)
                call DestroyEffect(AddSpecialEffectTarget(EFFECT_CLEANSING, target, "overhead"))
            endif
        endif
    endloop
    set owner = null
    set target = null
endfunction

private function TickCleansing takes nothing returns nothing
    local integer index = 1
    local unit totem
    loop
        exitwhen index > ActiveTotemCount
        set totem = ActiveTotems[index]
        if IsAliveUnit(totem) and IsCleansingTotem(GetUnitTypeId(totem)) then
            call DispelNearCleansingTotem(totem)
        endif
        set index = index + 1
    endloop
    set totem = null
endfunction

private function TickTotems takes nothing returns nothing
    local integer index = 1
    local unit totem
    call EnsureState()
    loop
        exitwhen index > ActiveTotemCount
        set totem = ActiveTotems[index]
        if IsAliveUnit(totem) then
            call UpdateTotemTextVisibility(totem)
            set index = index + 1
        else
            call CleanupTotem(totem)
        endif
    endloop
    call TickSkyfury()
    set CleansingElapsed = CleansingElapsed + TOTEM_PERIOD
    if CleansingElapsed >= TOTEM_CLEANSING_PERIOD then
        set CleansingElapsed = 0.00
        call TickCleansing()
    endif
    set totem = null
endfunction

private function DestroyTimedEffect takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local effect sfx = TimedEffectByTimer.effect[timerId]
    if sfx != null then
        call DestroyEffect(sfx)
    endif
    call TimedEffectByTimer.effect.remove(timerId)
    call DestroyTimer(expired)
    set sfx = null
    set expired = null
endfunction

private function AddTimedEffect takes effect sfx, real duration returns nothing
    local timer effectTimer
    if sfx != null then
        set effectTimer = CreateTimer()
        set TimedEffectByTimer.effect[GetHandleId(effectTimer)] = sfx
        call TimerStart(effectTimer, duration, false, function DestroyTimedEffect)
        set effectTimer = null
    endif
endfunction

private function HasWindfuryBuff takes unit source returns boolean
    return GetUnitAbilityLevel(source, BUFF_WINDFURY_1) > 0 or GetUnitAbilityLevel(source, BUFF_WINDFURY_2) > 0
endfunction

private function CanProcWindfury takes unit source, unit target, real amount returns boolean
    if WindfuryDamageActive or amount <= 0.00 or not udg_IsDamageAttack or not udg_IsDamageMelee then
        return false
    elseif not IsAliveUnit(source) or not IsAliveUnit(target) then
        return false
    elseif not IsUnitEnemy(target, GetOwningPlayer(source)) or not HasWindfuryBuff(source) then
        return false
    elseif GetUnitAbilityLevel(source, BUFF_FIRE_SHIELD_CASTER) > 0 then
        return false
    endif
    return GetRandomReal(0.00, 100.00) <= WINDFURY_PROC_CHANCE
endfunction

private function HandleDamageModifier takes nothing returns nothing
    local unit source = udg_DamageEventSource
    local unit target = udg_DamageEventTarget
    local real amount = udg_DamageEventAmount
    local effect sfx
    if CanProcWindfury(source, target, amount) then
        set WindfuryDamageActive = true
        call UnitDamageTarget(source, target, amount * WINDFURY_DAMAGE_MULTIPLIER, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
        call SetUnitAnimation(source, "attack")
        set sfx = AddSpecialEffectTarget(EFFECT_WINDFURY, source, "right hand")
        call BlzSetSpecialEffectScale(sfx, WINDFURY_EFFECT_SCALE)
        call AddTimedEffect(sfx, WINDFURY_EFFECT_DURATION)
        set WindfuryDamageActive = false
    endif
    set sfx = null
    set source = null
    set target = null
endfunction

private function HandleAttack takes nothing returns nothing
    local unit attacked = GetTriggerUnit()
    local unit attacker = GetAttacker()
    local unit totem
    local player owner
    local integer index = 1
    local integer unitTypeId
    if not IsAliveUnit(attacked) or not IsAliveUnit(attacker) then
        set attacked = null
        set attacker = null
        return
    endif
    loop
        exitwhen index > ActiveTotemCount
        set totem = ActiveTotems[index]
        if IsAliveUnit(totem) then
            set owner = GetOwningPlayer(totem)
            set unitTypeId = GetUnitTypeId(totem)
            if IsUnitAlly(attacked, owner) and IsUnitEnemy(attacker, owner) then
                if IsFireAutocastTotem(unitTypeId) and GetUnitAbilityLevel(attacked, BUFF_FIRE_SHIELD) == 0 then
                    call IssueTargetOrder(totem, "lightningshield", attacked)
                elseif IsWindAutocastTotem(unitTypeId) then
                    if unitTypeId == UNIT_TOTEM_WIND_2 then
                        call IssueTargetOrder(totem, "forkedlightning", attacker)
                    else
                        call IssueTargetOrder(totem, "cyclone", attacker)
                    endif
                endif
            endif
        endif
        set index = index + 1
    endloop
    set owner = null
    set totem = null
    set attacked = null
    set attacker = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local real x
    local real y
    local unit totem
    if IsTotemAbility(abilityId) then
        set x = GetSpellTargetX()
        set y = GetSpellTargetY()
        if x == 0.00 and y == 0.00 then
            set x = GetUnitX(caster)
            set y = GetUnitY(caster)
        endif
        set totem = SpawnTotem(caster, abilityId, x, y)
    endif
    set totem = null
    set caster = null
endfunction

private function HandleSpellFinish takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer level
    local integer manaCost
    if IsPlayerTotemAbility(abilityId) and GetUnitAbilityLevel(caster, ABILITY_TOTEM_MASTER) > 0 then
        set level = GetUnitAbilityLevel(caster, abilityId)
        if level <= 0 then
            set level = 1
        endif
        set manaCost = BlzGetUnitAbilityManaCost(caster, abilityId, level - 1)
        if manaCost > 0 then
            call SetUnitState(caster, UNIT_STATE_MANA, GetUnitState(caster, UNIT_STATE_MANA) + I2R(manaCost))
        endif
        call DestroyEffect(AddSpecialEffectTarget(EFFECT_TOTEM_MASTER, caster, "origin"))
    endif
    set caster = null
endfunction

private function HandleDeath takes nothing returns nothing
    local unit dying = UnitDeathEvent_GetDyingUnit()
    if IsTotemUnitType(GetUnitTypeId(dying)) or ActiveTotemTracked.boolean[GetHandleId(dying)] then
        call CleanupTotem(dying)
        call RemoveUnit(dying)
    endif
    set dying = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()

    call Events_RegisterSpellEffect(function HandleSpellEffect)
    call Events_RegisterSpellFinish(function HandleSpellFinish)
    call Events_RegisterUnitAttacked(function HandleAttack)
    call UnitDeathEvent_Register(function HandleDeath)

    set PeriodicTimer = CreateTimer()
    call TimerStart(PeriodicTimer, TOTEM_PERIOD, true, function TickTotems)
    call RegisterDamageEngine(function HandleDamageModifier, "", 1.00)
endfunction

endlibrary
