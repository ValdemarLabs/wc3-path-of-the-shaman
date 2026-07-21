/**
    ResourceEnergy

    Author: Valdemar
    Version:

    Description:
    Controlled Energy resource for Rogue-style units. The Warcraft III mana bar
    remains the visible resource, but this library owns the stored Energy value
    so item/aura mana gains do not leak into Rogue Energy.

    Credits:
    - Old RageEnergy GUI trigger notes
    - Table v6 by Bribe
    - SetUnitMaxState by Earth-Fury and Blade.dk

    How to install:
    Requires `Table`, `SetUnitMaxState`, and `Events`. Import before systems
    that call the ResourceEnergy API. The Horde Rogue unit type is registered by default.

    API:
    call ResourceEnergy_Register(unit whichUnit)
    call ResourceEnergy_Unregister(unit whichUnit)
    call ResourceEnergy_RegisterUnitType(integer unitTypeId)
    call ResourceEnergy_UnregisterUnitType(integer unitTypeId)
    call ResourceEnergy_Get(unit whichUnit)
    call ResourceEnergy_Set(unit whichUnit, real amount)
    call ResourceEnergy_Add(unit whichUnit, real amount)
    call ResourceEnergy_Has(unit whichUnit, real amount)
    call ResourceEnergy_Spend(unit whichUnit, real amount)
    call ResourceEnergy_Refresh(unit whichUnit)

**/
library ResourceEnergy initializer Init requires Table, SetUnitMaxState, Events

globals
    constant integer RESOURCE_ENERGY_UNIT_ROGUE_HORDE = 'O631'

    private constant real ENERGY_MIN = 0.00
    private constant real ENERGY_MAX = 100.00
    private constant real ITEM_REFRESH_DELAY = 0.10

    real ResourceEnergy_TickPeriod = 1.00
    real ResourceEnergy_EnergyPerTick = 20.00
    boolean ResourceEnergy_BlockManaItems = true
    boolean ResourceEnergy_UseAncientTypeFilter = true
    boolean ResourceEnergy_ShowBlockedItemMessage = true

    private Table EnergyUnitTypes = 0
    private Table EnergyUnitSlot = 0
    private Table EnergyValue = 0
    private Table EnergyHadAncientType = 0
    private Table RefreshTimerUnit = 0

    private integer EnergyUnitCount = 0
    private unit array EnergyUnits

    private timer EnergyTickTimer = null
endglobals

private function EnsureState takes nothing returns nothing
    if EnergyUnitTypes == 0 then
        set EnergyUnitTypes = Table.create()
        set EnergyUnitSlot = Table.create()
        set EnergyValue = Table.create()
        set EnergyHadAncientType = Table.create()
        set RefreshTimerUnit = Table.create()
    endif
endfunction

private function ClampEnergy takes real value returns real
    if value < ENERGY_MIN then
        return ENERGY_MIN
    endif
    if value > ENERGY_MAX then
        return ENERGY_MAX
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
    return EnergyUnitSlot.integer[GetHandleId(whichUnit)] > 0
endfunction

private function IsAutoUnitType takes integer unitTypeId returns boolean
    if unitTypeId == 0 then
        return false
    endif
    call EnsureState()
    return EnergyUnitTypes.boolean[unitTypeId]
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

private function ApplyEnergyUnitSetup takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call SetUnitMaxState(whichUnit, UNIT_STATE_MAX_MANA, ENERGY_MAX)
    call BlzSetUnitRealField(whichUnit, UNIT_RF_MANA_REGENERATION, 0.00)
    if ResourceEnergy_UseAncientTypeFilter and not IsUnitType(whichUnit, UNIT_TYPE_ANCIENT) then
        call UnitAddType(whichUnit, UNIT_TYPE_ANCIENT)
    endif
    call RemoveManaRegenBuffs(whichUnit)
endfunction

private function SetStoredEnergy takes unit whichUnit, real value returns nothing
    local integer handleId
    if whichUnit == null then
        return
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    set value = ClampEnergy(value)
    set EnergyValue.real[handleId] = value
    call SetUnitState(whichUnit, UNIT_STATE_MANA, value)
endfunction

private function ObserveEnergy takes unit whichUnit returns real
    local integer handleId
    local real stored
    local real current
    if whichUnit == null then
        return ENERGY_MIN
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    set current = ClampEnergy(GetUnitState(whichUnit, UNIT_STATE_MANA))
    if not EnergyValue.real.has(handleId) then
        set EnergyValue.real[handleId] = current
        return current
    endif
    set stored = EnergyValue.real[handleId]
    if current < stored then
        set stored = current
        set EnergyValue.real[handleId] = stored
    elseif current > stored then
        call SetUnitState(whichUnit, UNIT_STATE_MANA, stored)
    endif
    return stored
endfunction

private function RefreshEnergyUnit takes unit whichUnit returns nothing
    local real value
    if whichUnit == null then
        return
    endif
    set value = ObserveEnergy(whichUnit)
    call ApplyEnergyUnitSetup(whichUnit)
    call SetStoredEnergy(whichUnit, value)
endfunction

private function RegisterEnergyUnit takes unit whichUnit returns boolean
    local integer handleId
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return false
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    if EnergyUnitSlot.integer[handleId] > 0 then
        call RefreshEnergyUnit(whichUnit)
        return true
    endif
    set EnergyUnitCount = EnergyUnitCount + 1
    set EnergyUnits[EnergyUnitCount] = whichUnit
    set EnergyUnitSlot.integer[handleId] = EnergyUnitCount
    set EnergyHadAncientType.boolean[handleId] = IsUnitType(whichUnit, UNIT_TYPE_ANCIENT)
    call ApplyEnergyUnitSetup(whichUnit)
    call SetStoredEnergy(whichUnit, ENERGY_MAX)
    return true
endfunction

private function UnregisterEnergyUnit takes unit whichUnit returns boolean
    local integer handleId
    local integer slot
    local unit lastUnit
    if whichUnit == null then
        return false
    endif
    call EnsureState()
    set handleId = GetHandleId(whichUnit)
    set slot = EnergyUnitSlot.integer[handleId]
    if slot <= 0 then
        return false
    endif
    set lastUnit = EnergyUnits[EnergyUnitCount]
    set EnergyUnits[slot] = lastUnit
    if lastUnit != null and slot != EnergyUnitCount then
        set EnergyUnitSlot.integer[GetHandleId(lastUnit)] = slot
    endif
    set EnergyUnits[EnergyUnitCount] = null
    set EnergyUnitCount = EnergyUnitCount - 1
    if ResourceEnergy_UseAncientTypeFilter and not EnergyHadAncientType.boolean[handleId] and IsUnitType(whichUnit, UNIT_TYPE_ANCIENT) then
        call UnitRemoveType(whichUnit, UNIT_TYPE_ANCIENT)
    endif
    call EnergyUnitSlot.integer.remove(handleId)
    call EnergyValue.real.remove(handleId)
    call EnergyHadAncientType.boolean.remove(handleId)
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
            call RegisterEnergyUnit(enumUnit)
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
        return RegisterEnergyUnit(whichUnit)
    endif
    return false
endfunction

private function BlockManaRestore takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call IssueImmediateOrder(whichUnit, "stop")
    call SetStoredEnergy(whichUnit, ObserveEnergy(whichUnit))
    if ResourceEnergy_ShowBlockedItemMessage then
        call DisplayTimedTextToPlayer(GetOwningPlayer(whichUnit), 0.00, 0.00, 2.00, GetUnitName(whichUnit) + " cannot use mana-restoring items.")
    endif
endfunction

private function OnRefreshTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local unit whichUnit = RefreshTimerUnit.unit[timerId]
    call RefreshTimerUnit.unit.remove(timerId)
    call DestroyTimer(expiredTimer)
    if TryAutoRegisterUnit(whichUnit) then
        call RefreshEnergyUnit(whichUnit)
    endif
    set whichUnit = null
    set expiredTimer = null
endfunction

private function QueueRefresh takes unit whichUnit returns nothing
    local timer refreshTimer
    if whichUnit == null then
        return
    endif
    call EnsureState()
    set refreshTimer = CreateTimer()
    set RefreshTimerUnit.unit[GetHandleId(refreshTimer)] = whichUnit
    call TimerStart(refreshTimer, ITEM_REFRESH_DELAY, false, function OnRefreshTimer)
    set refreshTimer = null
endfunction

private function EnergyTick takes nothing returns nothing
    local integer index = 1
    local unit whichUnit
    local unit lastUnit
    local real value
    loop
        exitwhen index > EnergyUnitCount
        set whichUnit = EnergyUnits[index]
        if whichUnit == null then
            set lastUnit = EnergyUnits[EnergyUnitCount]
            set EnergyUnits[index] = lastUnit
            if lastUnit != null and index != EnergyUnitCount then
                set EnergyUnitSlot.integer[GetHandleId(lastUnit)] = index
            endif
            set EnergyUnits[EnergyUnitCount] = null
            set EnergyUnitCount = EnergyUnitCount - 1
        elseif GetUnitTypeId(whichUnit) == 0 then
            call UnregisterEnergyUnit(whichUnit)
        elseif IsAliveUnit(whichUnit) then
            call ApplyEnergyUnitSetup(whichUnit)
            set value = ObserveEnergy(whichUnit)
            if value < ENERGY_MAX then
                call SetStoredEnergy(whichUnit, value + ResourceEnergy_EnergyPerTick)
            endif
            set index = index + 1
        else
            set index = index + 1
        endif
    endloop
    set whichUnit = null
    set lastUnit = null
endfunction

public function OnUnitEnter takes unit whichUnit returns nothing
    call TryAutoRegisterUnit(whichUnit)
endfunction

private function HandleUnitEnter takes nothing returns nothing
    call TryAutoRegisterUnit(GetTriggerUnit())
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
        if ResourceEnergy_BlockManaItems and IsKnownManaRestoreAbility(abilityId) then
            call BlockManaRestore(whichUnit)
        endif
        call QueueRefresh(whichUnit)
    endif
    set whichUnit = null
endfunction

public function Register takes unit whichUnit returns boolean
    return RegisterEnergyUnit(whichUnit)
endfunction

public function Unregister takes unit whichUnit returns boolean
    return UnregisterEnergyUnit(whichUnit)
endfunction

public function RegisterUnitType takes integer unitTypeId returns nothing
    if unitTypeId == 0 then
        return
    endif
    call EnsureState()
    set EnergyUnitTypes.boolean[unitTypeId] = true
    call ScanExistingUnitType(unitTypeId)
endfunction

public function UnregisterUnitType takes integer unitTypeId returns nothing
    if unitTypeId == 0 then
        return
    endif
    call EnsureState()
    call EnergyUnitTypes.boolean.remove(unitTypeId)
endfunction

public function IsRegistered takes unit whichUnit returns boolean
    return IsTrackedUnit(whichUnit)
endfunction

public function Refresh takes unit whichUnit returns nothing
    if TryAutoRegisterUnit(whichUnit) then
        call RefreshEnergyUnit(whichUnit)
    endif
endfunction

public function Get takes unit whichUnit returns real
    if TryAutoRegisterUnit(whichUnit) then
        return ObserveEnergy(whichUnit)
    endif
    return ENERGY_MIN
endfunction

public function Set takes unit whichUnit, real amount returns nothing
    if TryAutoRegisterUnit(whichUnit) then
        call ApplyEnergyUnitSetup(whichUnit)
        call SetStoredEnergy(whichUnit, amount)
    endif
endfunction

public function Add takes unit whichUnit, real amount returns nothing
    if TryAutoRegisterUnit(whichUnit) then
        call SetStoredEnergy(whichUnit, ObserveEnergy(whichUnit) + amount)
    endif
endfunction

public function Has takes unit whichUnit, real amount returns boolean
    if amount <= 0.00 then
        return true
    endif
    if TryAutoRegisterUnit(whichUnit) then
        return ObserveEnergy(whichUnit) >= amount
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
    set value = ObserveEnergy(whichUnit)
    if value < amount then
        return false
    endif
    call SetStoredEnergy(whichUnit, value - amount)
    return true
endfunction

private function Init takes nothing returns nothing
    call EnsureState()

    set EnergyTickTimer = CreateTimer()
    call TimerStart(EnergyTickTimer, ResourceEnergy_TickPeriod, true, function EnergyTick)

    call Events_RegisterUnitEnter(function HandleUnitEnter)
    call Events_RegisterPlayerUnitEvent(function HandleItemChange, EVENT_PLAYER_UNIT_PICKUP_ITEM)
    call Events_RegisterPlayerUnitEvent(function HandleItemChange, EVENT_PLAYER_UNIT_DROP_ITEM)
    call Events_RegisterPlayerUnitEvent(function HandleItemChange, EVENT_PLAYER_UNIT_USE_ITEM)
    call Events_RegisterPlayerUnitEvent(function HandleSpellCast, EVENT_PLAYER_UNIT_SPELL_CAST)

    call RegisterUnitType(RESOURCE_ENERGY_UNIT_ROGUE_HORDE)
endfunction

endlibrary
