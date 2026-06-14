/**
    Companions

    Author: Valdemar
    Version:

    Description:
    Thin companion wrapper over QuestGiver companion registration and
    FollowSystem movement. Keeps party icons/groups in sync while exposing
    defend, passive, hold, suspend, and resume controls for scripted NPC
    companions.

    How to install:

    API:
    call Companions_Add(unit companionUnit, string companionIcon, unit leader, integer mode)
    call Companions_Remove(unit companionUnit)
    call Companions_SetLeader(unit companionUnit, unit leader)
    call Companions_SetMode(unit companionUnit, integer mode)
    call Companions_Suspend(unit companionUnit)
    call Companions_Resume(unit companionUnit)

**/
library Companions requires QuestGiver, FollowSystem, Table

globals
    constant integer COMPANION_MODE_DEFEND = 1
    constant integer COMPANION_MODE_PASSIVE = 2
    constant integer COMPANION_MODE_HOLD = 3

    private constant boolean DEBUG = false
    private constant real COMPANION_FOLLOW_DISTANCE = 2500.00

    private Table CompanionLeader = 0
    private Table CompanionMode = 0
    private Table CompanionSuspended = 0
    private Table CompanionIcon = 0
    private Table CompanionRegistered = 0
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("[Companions] " + msg)
    endif
endfunction

private function IsValidCompanion takes unit companionUnit returns boolean
    return companionUnit != null and GetUnitTypeId(companionUnit) != 0 and not IsUnitType(companionUnit, UNIT_TYPE_DEAD)
endfunction

private function ApplyOrders takes unit companionUnit returns nothing
    local integer unitId
    local unit leader
    local integer mode
    if not IsValidCompanion(companionUnit) then
        return
    endif
    if CompanionRegistered == 0 then
        return
    endif
    set unitId = GetHandleId(companionUnit)
    if CompanionSuspended[unitId] == 1 then
        call FollowSystem_RemoveUnit(companionUnit)
        call IssueImmediateOrder(companionUnit, "stop")
        return
    endif
    set leader = CompanionLeader.unit[unitId]
    set mode = CompanionMode[unitId]
    if mode == COMPANION_MODE_HOLD then
        call FollowSystem_RemoveUnit(companionUnit)
        call IssueImmediateOrder(companionUnit, "stop")
    elseif leader != null and IsValidCompanion(leader) then
        if mode == COMPANION_MODE_PASSIVE then
            call FollowSystem_SetFollow(companionUnit, leader, COMPANION_FOLLOW_DISTANCE, false, 0.00, FOLLOW_STYLE_PASSIVE, true, true)
        else
            call FollowSystem_SetFollow(companionUnit, leader, COMPANION_FOLLOW_DISTANCE, false, 0.00, FOLLOW_STYLE_DEFEND, true, true)
        endif
    else
        call FollowSystem_RemoveUnit(companionUnit)
        call IssueImmediateOrder(companionUnit, "stop")
    endif
    set leader = null
endfunction

public function Add takes unit companionUnit, string companionIcon, unit leader, integer mode returns nothing
    local integer unitId
    if not IsValidCompanion(companionUnit) then
        return
    endif
    if CompanionLeader == 0 then
        set CompanionLeader = Table.create()
        set CompanionMode = Table.create()
        set CompanionSuspended = Table.create()
        set CompanionIcon = Table.create()
        set CompanionRegistered = Table.create()
    endif
    set unitId = GetHandleId(companionUnit)
    if CompanionRegistered[unitId] == 0 then
        call QuestGiver_AddCompanion(companionUnit, companionIcon)
        set CompanionRegistered[unitId] = 1
    elseif companionIcon != "" then
        set CompanionIcon.string[unitId] = companionIcon
    endif
    if mode == 0 then
        set mode = COMPANION_MODE_DEFEND
    endif
    set CompanionLeader.unit[unitId] = leader
    set CompanionMode[unitId] = mode
    set CompanionSuspended[unitId] = 0
    set CompanionIcon.string[unitId] = companionIcon
    call ApplyOrders(companionUnit)
    call DebugMsg("Add " + GetUnitName(companionUnit))
endfunction

public function Remove takes unit companionUnit returns nothing
    local integer unitId
    if companionUnit == null or CompanionRegistered == 0 then
        return
    endif
    set unitId = GetHandleId(companionUnit)
    call FollowSystem_RemoveUnit(companionUnit)
    if CompanionRegistered[unitId] == 1 then
        call QuestGiver_RemoveCompanion(companionUnit)
    endif
    call CompanionLeader.remove(unitId)
    call CompanionMode.remove(unitId)
    call CompanionSuspended.remove(unitId)
    call CompanionIcon.remove(unitId)
    call CompanionRegistered.remove(unitId)
    call DebugMsg("Remove " + GetUnitName(companionUnit))
endfunction

public function SetLeader takes unit companionUnit, unit leader returns nothing
    local integer unitId
    if not IsValidCompanion(companionUnit) or CompanionRegistered == 0 then
        return
    endif
    set unitId = GetHandleId(companionUnit)
    if CompanionRegistered[unitId] == 0 then
        return
    endif
    set CompanionLeader.unit[unitId] = leader
    call ApplyOrders(companionUnit)
endfunction

public function SetMode takes unit companionUnit, integer mode returns nothing
    local integer unitId
    if not IsValidCompanion(companionUnit) or CompanionRegistered == 0 then
        return
    endif
    set unitId = GetHandleId(companionUnit)
    if CompanionRegistered[unitId] == 0 then
        return
    endif
    if mode == 0 then
        set mode = COMPANION_MODE_DEFEND
    endif
    set CompanionMode[unitId] = mode
    call ApplyOrders(companionUnit)
endfunction

public function Suspend takes unit companionUnit returns nothing
    local integer unitId
    if not IsValidCompanion(companionUnit) or CompanionRegistered == 0 then
        return
    endif
    set unitId = GetHandleId(companionUnit)
    if CompanionRegistered[unitId] == 0 then
        return
    endif
    set CompanionSuspended[unitId] = 1
    call ApplyOrders(companionUnit)
endfunction

public function Resume takes unit companionUnit returns nothing
    local integer unitId
    if not IsValidCompanion(companionUnit) or CompanionRegistered == 0 then
        return
    endif
    set unitId = GetHandleId(companionUnit)
    if CompanionRegistered[unitId] == 0 then
        return
    endif
    set CompanionSuspended[unitId] = 0
    call ApplyOrders(companionUnit)
endfunction

endlibrary
