/**
    ResourceRage

    Author: Valdemar
    Version:

    Description:
    Controlled Rage resource for Warrior-style units. The Warcraft III mana bar
    remains the visible resource, but this library owns the stored Rage value
    and generates Rage from damage events instead of normal mana restoration.

    Credits:
    - Old RageEnergy GUI trigger notes
    - DamageEngine by Bribe
    - Table v6 by Bribe
    - SetUnitMaxState by Earth-Fury and Blade.dk

    How to install:
    Requires `Table`, `SetUnitMaxState`, and `DamageEngine`. Import before
    systems that call the ResourceRage API. The Horde Warrior unit type is
    registered by default.

    API:
    call ResourceRage_Register(unit whichUnit)
    call ResourceRage_Unregister(unit whichUnit)
    call ResourceRage_RegisterUnitType(integer unitTypeId)
    call ResourceRage_UnregisterUnitType(integer unitTypeId)
    call ResourceRage_Get(unit whichUnit)
    call ResourceRage_Set(unit whichUnit, real amount)
    call ResourceRage_Add(unit whichUnit, real amount)
    call ResourceRage_Has(unit whichUnit, real amount)
    call ResourceRage_Spend(unit whichUnit, real amount)
    call ResourceRage_Refresh(unit whichUnit)

**/
library ResourceRage initializer Init requires Table, SetUnitMaxState, DamageEngine

globals
    constant integer RESOURCE_RAGE_UNIT_WARRIOR_HORDE = 'O629'
    constant integer RESOURCE_RAGE_UNIT_WARRIOR_RIVERBANE = 'O009'
    constant integer RESOURCE_RAGE_ABILITY_BLOODRAGE = 'A00G'
    constant integer RESOURCE_RAGE_ABILITY_BLOODRAGE_ALT = 'A00K'
    constant integer RESOURCE_RAGE_BUFF_BLOODRAGE = 'B01G'

    private constant integer MAX_PLAYER_INDEX = 27
    private constant real RAGE_MIN = 0.00
    private constant real RAGE_MAX = 100.00
    private constant real ITEM_REFRESH_DELAY = 0.10

    real ResourceRage_InitialRage = 0.00
    real ResourceRage_AttackScale = 0.20
    real ResourceRage_DefenseScale = 0.10
    real ResourceRage_LevelScale = 0.01
    real ResourceRage_MinGain = 3.00
    real ResourceRage_MaxGain = 60.00
    real ResourceRage_BloodrageCastGain = 20.00
    real ResourceRage_BloodrageAttackBonus = 2.00
    real ResourceRage_BloodrageDefenseBonus = 1.00
    real ResourceRage_DecayDelay = 5.00
    real ResourceRage_DecayPeriod = 1.50
    real ResourceRage_DecayAmount = 5.00
    boolean ResourceRage_BlockManaItems = true
    boolean ResourceRage_UseAncientTypeFilter = true
    boolean ResourceRage_ShowBlockedItemMessage = true

    private Table RageUnitTypes = 0
    private Table RageUnitSlot = 0
    private Table RageValue = 0
    private Table RageHadAncientType = 0
    private Table RageLastGainTime = 0
    private Table RefreshTimerUnit = 0
    private Table RefreshQueued = 0

    private integer RageUnitCount = 0
    private unit array RageUnits

    private timer RageClockTimer = null
    private timer RageDecayTimer = null
    // private trigger RageEnterTrigger = null //Usused. Currently using centralized GUI trigger "Init 07 Unit Event Enters"
    private trigger RageItemTrigger = null
    private trigger RageSpellCastTrigger = null
    private trigger RageSpellEffectTrigger = null
endglobals

private function EnsureState takes nothing returns nothing
    if RageUnitTypes == 0 then
        set RageUnitTypes = Table.create()
        set RageUnitSlot = Table.create()
        set RageValue = Table.create()
        set RageHadAncientType = Table.create()
        set RageLastGainTime = Table.create()
        set RefreshTimerUnit = Table.create()
        set RefreshQueued = Table.create()
    endif
    
    if RageClockTimer == null then
        set RageClockTimer = CreateTimer()
        call TimerStart(RageClockTimer, 1000000.00, false, null)
    endif
endfunction

private function GetNow takes nothing returns real
    call EnsureState()
    return TimerGetElapsed(RageClockTimer)
endfunction

private function ClampRage takes real value returns real
    if value < RAGE_MIN then
        return RAGE_MIN
    endif
    if value > RAGE_MAX then
        return RAGE_MAX
    endif
    return value
endfunction

private function IsAliveUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
endfunction

private function IsTrackedUnit takes unit whichUnit returns boolean
    if whichUnit == null then
        return false
    endif
    call EnsureState()
    return RageUnitSlot.integer[GetHandleId(whichUnit)] > 0
endfunction

private function IsAutoUnitType takes integer unitTypeId returns boolean
    if unitTypeId == 0 then
        return false
    endif
    call EnsureState()
    return RageUnitTypes.boolean[unitTypeId]
endfunction

private function ShouldAutoRegisterUnit takes unit whichUnit returns boolean
    return whichUnit != null and IsAutoUnitType(GetUnitTypeId(whichUnit))
endfunction

private function IsKnownManaRestoreAbility takes integer abilityId returns boolean
    return abilityId == 'A6BM' or abilityId == 'A6BN' or abilityId == 'A6BO' or abilityId == 'A6BP' or /*
        */ abilityId == 'A6B1' or abilityId == 'A6B2' or abilityId == 'A6B3' or /*
        */ abilityId == 'A6B4' or abilityId == 'A6B5' or abilityId == 'A6B6' or /*
        */ abilityId == 'A6BA' or abilityId == 'A6BB' or abilityId == 'A6BC' or /*
        */ abilityId == 'A6BJ' or abilityId == 'A6BK' or abilityId == 'A6BL' or /*
        */ abilityId == 'AIma' or abilityId == 'AImr'
endfunction

private function RemoveManaRegenBuffs takes unit whichUnit returns nothing
    call UnitRemoveAbility(whichUnit, 'B60P') // Water Totem Aura
    call UnitRemoveAbility(whichUnit, 'BHab') // Brilliance/Mana Regeneration Aura
    call UnitRemoveAbility(whichUnit, 'B604') // Water/Replenishment mana regeneration
endfunction

private function ApplyRageUnitSetup takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call SetUnitMaxState(whichUnit, UNIT_STATE_MAX_MANA, RAGE_MAX)
    call BlzSetUnitRealField(whichUnit, UNIT_RF_MANA_REGENERATION, 0.00)
    if ResourceRage_UseAncientTypeFilter and not IsUnitType(whichUnit, UNIT_TYPE_ANCIENT) then
        call UnitAddType(whichUnit, UNIT_TYPE_ANCIENT)
    endif
    call RemoveManaRegenBuffs(whichUnit)
endfunction

private function SetStoredRage takes unit whichUnit, real value returns nothing
    local integer handleId
    if whichUnit == null then
        return
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    set value = ClampRage(value)
    set RageValue.real[handleId] = value
    call SetUnitState(whichUnit, UNIT_STATE_MANA, value)
endfunction

private function ObserveRage takes unit whichUnit returns real
    local integer handleId
    local real stored
    local real current
    if whichUnit == null then
        return RAGE_MIN
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    set current = ClampRage(GetUnitState(whichUnit, UNIT_STATE_MANA))
    if not RageValue.real.has(handleId) then
        set RageValue.real[handleId] = current
        return current
    endif
    set stored = RageValue.real[handleId]
    if current < stored then
        set stored = current
        set RageValue.real[handleId] = stored
    elseif current > stored then
        call SetUnitState(whichUnit, UNIT_STATE_MANA, stored)
    endif
    return stored
endfunction

private function RefreshRageUnit takes unit whichUnit returns nothing
    local real value
    if whichUnit == null then
        return
    endif
    set value = ObserveRage(whichUnit)
    call ApplyRageUnitSetup(whichUnit)
    call SetStoredRage(whichUnit, value)
endfunction

private function RegisterRageUnit takes unit whichUnit returns boolean
    local integer handleId
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return false
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    if RageUnitSlot.integer[handleId] > 0 then
        call RefreshRageUnit(whichUnit)
        return true
    endif
    set RageUnitCount = RageUnitCount + 1
    set RageUnits[RageUnitCount] = whichUnit
    set RageUnitSlot.integer[handleId] = RageUnitCount
    set RageHadAncientType.boolean[handleId] = IsUnitType(whichUnit, UNIT_TYPE_ANCIENT)
    set RageLastGainTime.real[handleId] = GetNow()
    call ApplyRageUnitSetup(whichUnit)
    call SetStoredRage(whichUnit, ResourceRage_InitialRage)
    return true
endfunction

private function UnregisterRageUnit takes unit whichUnit returns boolean
    local integer handleId
    local integer slot
    local unit lastUnit
    if whichUnit == null then
        return false
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    set slot = RageUnitSlot.integer[handleId]
    if slot <= 0 then
        return false
    endif
    set lastUnit = RageUnits[RageUnitCount]
    set RageUnits[slot] = lastUnit
    if lastUnit != null and slot != RageUnitCount then
        set RageUnitSlot.integer[GetHandleId(lastUnit)] = slot
    endif
    set RageUnits[RageUnitCount] = null
    set RageUnitCount = RageUnitCount - 1
    if ResourceRage_UseAncientTypeFilter and not RageHadAncientType.boolean[handleId] and IsUnitType(whichUnit, UNIT_TYPE_ANCIENT) then
        call UnitRemoveType(whichUnit, UNIT_TYPE_ANCIENT)
    endif
    call RageUnitSlot.integer.remove(handleId)
    call RageValue.real.remove(handleId)
    call RageHadAncientType.boolean.remove(handleId)
    call RageLastGainTime.real.remove(handleId)
    set lastUnit = null
    return true
endfunction

private function ScanExistingUnitType takes integer unitTypeId returns nothing
    local group enumGroup
    local unit enumUnit
    if unitTypeId == 0 then
        return
    endif
    set enumGroup = CreateGroup()
    call GroupEnumUnitsInRect(enumGroup, GetWorldBounds(), null)
    loop
        set enumUnit = FirstOfGroup(enumGroup)
        exitwhen enumUnit == null
        call GroupRemoveUnit(enumGroup, enumUnit)
        if GetUnitTypeId(enumUnit) == unitTypeId then
            call RegisterRageUnit(enumUnit)
        endif
    endloop
    call DestroyGroup(enumGroup)
    set enumUnit = null
    set enumGroup = null
endfunction

private function TryAutoRegisterUnit takes unit whichUnit returns boolean
    if IsTrackedUnit(whichUnit) then
        return true
    endif
    if ShouldAutoRegisterUnit(whichUnit) then
        return RegisterRageUnit(whichUnit)
    endif
    return false
endfunction

private function AddRageGain takes unit whichUnit, real amount returns nothing
    if not TryAutoRegisterUnit(whichUnit) then
        return
    endif
    if amount <= 0.00 then
        return
    endif
    call SetStoredRage(whichUnit, ObserveRage(whichUnit) + amount)
    set RageLastGainTime.real[GetHandleId(whichUnit)] = GetNow()
endfunction

private function CalculateRageGain takes unit whichUnit, real damageAmount, real scale, real bloodrageBonus returns real
    local real levelFactor
    local real gain
    if whichUnit == null or damageAmount <= 0.00 then
        return 0.00
    endif
    set levelFactor = 1.00 - I2R(GetHeroLevel(whichUnit)) * ResourceRage_LevelScale
    if levelFactor < 0.10 then
        set levelFactor = 0.10
    endif
    set gain = damageAmount * scale * levelFactor
    if GetUnitAbilityLevel(whichUnit, RESOURCE_RAGE_BUFF_BLOODRAGE) > 0 then
        set gain = gain + bloodrageBonus
    endif
    if gain > ResourceRage_MaxGain then
        set gain = ResourceRage_MaxGain
    elseif gain < ResourceRage_MinGain then
        set gain = ResourceRage_MinGain
    endif
    return gain
endfunction

private function BlockManaRestore takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call IssueImmediateOrder(whichUnit, "stop")
    call SetStoredRage(whichUnit, ObserveRage(whichUnit))
    if ResourceRage_ShowBlockedItemMessage then
        call DisplayTimedTextToPlayer(GetOwningPlayer(whichUnit), 0.00, 0.00, 2.00, GetUnitName(whichUnit) + " cannot use mana-restoring items.")
    endif
endfunction

private function OnRefreshTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local unit whichUnit = RefreshTimerUnit.unit[timerId]

    call RefreshTimerUnit.unit.remove(timerId)
    call DestroyTimer(expiredTimer)

    if whichUnit != null then
        if TryAutoRegisterUnit(whichUnit) then
            call RefreshRageUnit(whichUnit)
        endif

        call RefreshQueued.boolean.remove(GetHandleId(whichUnit))
    endif

    set whichUnit = null
    set expiredTimer = null
endfunction

private function QueueRefresh takes unit whichUnit returns nothing
    local timer refreshTimer
    local integer handleId

    if whichUnit == null then
        return
    endif

    call EnsureState()
    set handleId = GetHandleId(whichUnit)

    if RefreshQueued.boolean[handleId] then
        return
    endif

    set RefreshQueued.boolean[handleId] = true
    set refreshTimer = CreateTimer()
    set RefreshTimerUnit.unit[GetHandleId(refreshTimer)] = whichUnit
    call TimerStart(refreshTimer, ITEM_REFRESH_DELAY, false, function OnRefreshTimer)
    set refreshTimer = null
endfunction

private function RageDecayTick takes nothing returns nothing
    local integer index = 1
    local unit whichUnit
    local unit lastUnit
    local integer handleId
    local real value
    local real now = GetNow()
    loop
        exitwhen index > RageUnitCount
        set whichUnit = RageUnits[index]
        if whichUnit == null then
            set lastUnit = RageUnits[RageUnitCount]
            set RageUnits[index] = lastUnit
            if lastUnit != null and index != RageUnitCount then
                set RageUnitSlot.integer[GetHandleId(lastUnit)] = index
            endif
            set RageUnits[RageUnitCount] = null
            set RageUnitCount = RageUnitCount - 1
        elseif GetUnitTypeId(whichUnit) == 0 then
            if not UnregisterRageUnit(whichUnit) then
                call BJDebugMsg("[ResourceRage] Failed to unregister invalid unit at slot " + I2S(index))
                set lastUnit = RageUnits[RageUnitCount]
                set RageUnits[index] = lastUnit

                if lastUnit != null and index != RageUnitCount then
                    set RageUnitSlot.integer[GetHandleId(lastUnit)] = index
                endif

                set RageUnits[RageUnitCount] = null
                set RageUnitCount = RageUnitCount - 1
            endif
        elseif IsAliveUnit(whichUnit) then
            set handleId = GetHandleId(whichUnit)
            call ApplyRageUnitSetup(whichUnit)
            set value = ObserveRage(whichUnit)
            if value > RAGE_MIN and now - RageLastGainTime.real[handleId] >= ResourceRage_DecayDelay then
                call SetStoredRage(whichUnit, value - ResourceRage_DecayAmount)
            endif
            set index = index + 1
        else
            set index = index + 1
        endif
    endloop
    set whichUnit = null
    set lastUnit = null
endfunction

private function HandleDamage takes nothing returns nothing
    local unit source = udg_DamageEventSource
    local unit target = udg_DamageEventTarget
    local real damageAmount = udg_DamageEventAmount
    if damageAmount <= 0.00 then
        set source = null
        set target = null
        return
    endif
    if TryAutoRegisterUnit(source) and not udg_IsDamageSpell then
        call AddRageGain(source, CalculateRageGain(source, damageAmount, ResourceRage_AttackScale, ResourceRage_BloodrageAttackBonus))
    endif
    if target != source and TryAutoRegisterUnit(target) then
        call AddRageGain(target, CalculateRageGain(target, damageAmount, ResourceRage_DefenseScale, ResourceRage_BloodrageDefenseBonus))
    endif
    set source = null
    set target = null
endfunction

public function OnUnitEnter takes unit whichUnit returns nothing
    call TryAutoRegisterUnit(whichUnit)
endfunction

private function HandleItemChange takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    if TryAutoRegisterUnit(whichUnit) then
        call QueueRefresh(whichUnit)
    endif
    set whichUnit = null
endfunction

private function HandleSpellCast takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    if TryAutoRegisterUnit(whichUnit) then
        if ResourceRage_BlockManaItems and IsKnownManaRestoreAbility(abilityId) then
            call BlockManaRestore(whichUnit)
        endif
        call QueueRefresh(whichUnit)
    endif
    set whichUnit = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    if TryAutoRegisterUnit(whichUnit) and (abilityId == RESOURCE_RAGE_ABILITY_BLOODRAGE or abilityId == RESOURCE_RAGE_ABILITY_BLOODRAGE_ALT) then
        call AddRageGain(whichUnit, ResourceRage_BloodrageCastGain)
    endif
    set whichUnit = null
endfunction

private function RegisterPlayerUnitEventAll takes trigger whichTrigger, playerunitevent whichEvent returns nothing
    local integer playerIndex = 0
    loop
        call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > MAX_PLAYER_INDEX
    endloop
endfunction

public function Register takes unit whichUnit returns boolean
    return RegisterRageUnit(whichUnit)
endfunction

public function Unregister takes unit whichUnit returns boolean
    return UnregisterRageUnit(whichUnit)
endfunction

public function RegisterUnitType takes integer unitTypeId returns nothing
    if unitTypeId == 0 then
        return
    endif
    call EnsureState()
    set RageUnitTypes.boolean[unitTypeId] = true
    call ScanExistingUnitType(unitTypeId)
endfunction

public function UnregisterUnitType takes integer unitTypeId returns nothing
    if unitTypeId == 0 then
        return
    endif
    call EnsureState()
    call RageUnitTypes.boolean.remove(unitTypeId)
endfunction

public function IsRegistered takes unit whichUnit returns boolean
    return IsTrackedUnit(whichUnit)
endfunction

public function Refresh takes unit whichUnit returns nothing
    if TryAutoRegisterUnit(whichUnit) then
        call RefreshRageUnit(whichUnit)
    endif
endfunction

public function Get takes unit whichUnit returns real
    if TryAutoRegisterUnit(whichUnit) then
        return ObserveRage(whichUnit)
    endif
    return RAGE_MIN
endfunction

public function Set takes unit whichUnit, real amount returns nothing
    if TryAutoRegisterUnit(whichUnit) then
        call ApplyRageUnitSetup(whichUnit)
        call SetStoredRage(whichUnit, amount)
    endif
endfunction

public function Add takes unit whichUnit, real amount returns nothing
    call AddRageGain(whichUnit, amount)
endfunction

public function Has takes unit whichUnit, real amount returns boolean
    if amount <= 0.00 then
        return true
    endif
    if TryAutoRegisterUnit(whichUnit) then
        return ObserveRage(whichUnit) >= amount
    endif
    return false
endfunction

public function Spend takes unit whichUnit, real amount returns boolean
    local real value
    if amount <= 0.00 then
        return true
    endif
    if not TryAutoRegisterUnit(whichUnit) then
        return false
    endif
    set value = ObserveRage(whichUnit)
    if value < amount then
        return false
    endif
    call SetStoredRage(whichUnit, value - amount)
    return true
endfunction

private function Init takes nothing returns nothing
    call EnsureState()

    set RageDecayTimer = CreateTimer()
    call TimerStart(RageDecayTimer, ResourceRage_DecayPeriod, true, function RageDecayTick)

    set RageItemTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(RageItemTrigger, EVENT_PLAYER_UNIT_PICKUP_ITEM)
    call RegisterPlayerUnitEventAll(RageItemTrigger, EVENT_PLAYER_UNIT_DROP_ITEM)
    call RegisterPlayerUnitEventAll(RageItemTrigger, EVENT_PLAYER_UNIT_USE_ITEM)
    call TriggerAddAction(RageItemTrigger, function HandleItemChange)

    set RageSpellCastTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(RageSpellCastTrigger, EVENT_PLAYER_UNIT_SPELL_CAST)
    call TriggerAddAction(RageSpellCastTrigger, function HandleSpellCast)

    set RageSpellEffectTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(RageSpellEffectTrigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call TriggerAddAction(RageSpellEffectTrigger, function HandleSpellEffect)

    call RegisterDamageEngine(function HandleDamage, "", 1.00)
    call RegisterUnitType(RESOURCE_RAGE_UNIT_WARRIOR_HORDE)
    call RegisterUnitType(RESOURCE_RAGE_UNIT_WARRIOR_RIVERBANE)
endfunction

endlibrary
