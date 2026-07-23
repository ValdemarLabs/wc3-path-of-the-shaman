/**
    ShamanBloodlust

    Author: Valdemar
    Version:

    Description:
    Bloodlust group cast and rank 3+ crit bonus converted from GUI.

    Credits:
    - Old GUI "Bloodlust Cast" and "Bloodlust Crit Loop" triggers

    How to install:
    Requires `Table`, `Events`, and `ShamanCommon`.

**/
library ShamanBloodlust initializer Init requires Table, Events, ShamanCommon

globals
    private constant integer MAX_TRACKED = 256
    private constant real BLOODLUST_RADIUS = 600.00
    private constant real CRIT_CHECK_PERIOD = 1.00

    private Table CritByHandle = 0
    private Table AppliedLevelByHandle = 0
    private Table TrackedByHandle = 0
    private group EnumGroup = null
    private timer CritTimer = null
    private unit array TrackedUnits
    private integer TrackedCount = 0
endglobals

private function EnsureState takes nothing returns nothing
    if CritByHandle == 0 then
        set CritByHandle = Table.create()
        set AppliedLevelByHandle = Table.create()
        set TrackedByHandle = Table.create()
    endif
endfunction

private function GetRankBuff takes integer rank returns integer
    if rank == 1 then
        return ShamanCommon_BUFF_BLOODLUST_1
    elseif rank == 2 then
        return ShamanCommon_BUFF_BLOODLUST_2
    elseif rank == 3 then
        return ShamanCommon_BUFF_BLOODLUST_3
    elseif rank == 4 then
        return ShamanCommon_BUFF_BLOODLUST_4
    endif
    return ShamanCommon_BUFF_BLOODLUST_5
endfunction

private function HasAnyCritBloodlust takes unit target returns boolean
    return GetUnitAbilityLevel(target, ShamanCommon_BUFF_BLOODLUST_3) > 0 or GetUnitAbilityLevel(target, ShamanCommon_BUFF_BLOODLUST_4) > 0 or GetUnitAbilityLevel(target, ShamanCommon_BUFF_BLOODLUST_5) > 0
endfunction

private function GetCritBonus takes integer rank returns integer
    if rank == 3 then
        return 5
    elseif rank == 4 then
        return 10
    elseif rank >= 5 then
        return 15
    endif
    return 0
endfunction

private function TrackUnit takes unit target returns nothing
    local integer handleId = GetHandleId(target)
    if target != null and not TrackedByHandle.boolean[handleId] and TrackedCount < MAX_TRACKED then
        set TrackedCount = TrackedCount + 1
        set TrackedUnits[TrackedCount] = target
        set TrackedByHandle.boolean[handleId] = true
    endif
endfunction

private function RemoveCritBonus takes unit target returns nothing
    local integer handleId = GetHandleId(target)
    local integer customValue = GetUnitUserData(target)
    local integer crit = CritByHandle.integer[handleId]
    if customValue > 0 and crit != 0 then
        set udg_Stats_Crit[customValue] = udg_Stats_Crit[customValue] - crit
    endif
    call CritByHandle.integer.remove(handleId)
    call AppliedLevelByHandle.integer.remove(handleId)
endfunction

private function TickCritBonuses takes nothing returns nothing
    local integer index = 1
    local unit target
    loop
        exitwhen index > TrackedCount
        set target = TrackedUnits[index]
        if not ShamanCommon_IsAlive(target) or not HasAnyCritBloodlust(target) then
            call RemoveCritBonus(target)
            call TrackedByHandle.boolean.remove(GetHandleId(target))
            set TrackedUnits[index] = TrackedUnits[TrackedCount]
            set TrackedUnits[TrackedCount] = null
            set TrackedCount = TrackedCount - 1
        else
            set index = index + 1
        endif
    endloop
    if TrackedCount <= 0 then
        call PauseTimer(CritTimer)
    endif
    set target = null
endfunction

private function ApplyCritBonus takes unit target, integer rank returns nothing
    local integer handleId = GetHandleId(target)
    local integer customValue = GetUnitUserData(target)
    local integer crit = GetCritBonus(rank)
    if target == null or customValue <= 0 or crit <= 0 then
        return
    endif
    if CritByHandle.integer[handleId] != 0 then
        call RemoveCritBonus(target)
    endif
    set CritByHandle.integer[handleId] = crit
    set AppliedLevelByHandle.integer[handleId] = rank
    set udg_Stats_Crit[customValue] = udg_Stats_Crit[customValue] + crit
    call TrackUnit(target)
    call TimerStart(CritTimer, CRIT_CHECK_PERIOD, true, function TickCritBonuses)
endfunction

private function CastBloodlustOnTarget takes unit caster, unit target, integer rank, real x, real y returns nothing
    local unit dummy
    if target == null or GetUnitAbilityLevel(target, GetRankBuff(rank)) > 0 then
        return
    endif
    set dummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_BLOODLUST, x, y, bj_UNIT_FACING, 3.00)
    call UnitAddAbility(dummy, ShamanCommon_ABILITY_BLOODLUST_DUMMY)
    call SetUnitAbilityLevel(dummy, ShamanCommon_ABILITY_BLOODLUST_DUMMY, rank)
    call IssueTargetOrder(dummy, "bloodlust", target)
    call ApplyCritBonus(target, rank)
    set dummy = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target
    local integer rank
    local real x
    local real y
    if GetSpellAbilityId() == ShamanCommon_ABILITY_BLOODLUST then
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_BLOODLUST)
        set x = GetUnitX(caster)
        set y = GetUnitY(caster)
        call SetUnitAnimation(caster, "spell")
        call QueueUnitAnimation(caster, "stand")
        call GroupClear(EnumGroup)
        call GroupEnumUnitsInRange(EnumGroup, x, y, BLOODLUST_RADIUS, null)
        call GroupAddUnit(EnumGroup, caster)
        loop
            set target = FirstOfGroup(EnumGroup)
            exitwhen target == null
            call GroupRemoveUnit(EnumGroup, target)
            if ShamanCommon_IsAlive(target) and IsUnitAlly(target, GetOwningPlayer(caster)) and not IsUnitType(target, UNIT_TYPE_STRUCTURE) then
                call CastBloodlustOnTarget(caster, target, rank, x, y)
            endif
        endloop
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    set EnumGroup = CreateGroup()
    set CritTimer = CreateTimer()
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
