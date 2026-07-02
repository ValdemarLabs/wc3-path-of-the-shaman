/**
    Companions

    Author: Valdemar
    Credits:
    - Old GUI companion triggers, converted and consolidated into JASS.
    Version:

    Description:
    Companion party registration, information, idle state, and control-mode
    handling. This library keeps the existing GUI companion globals
    synchronized for older systems while using FollowSystem for the actual
    follow orders where appropriate.

    API:
    call Companions_Add(unit companionUnit, string companionIcon, unit leader, integer mode)
    call Companions_Remove(unit companionUnit)
    call Companions_SetLeader(unit companionUnit, unit leader)
    call Companions_SetMode(unit companionUnit, integer mode)
    call Companions_Suspend(unit companionUnit)
    call Companions_Resume(unit companionUnit)
    call Companions_RegisterControlled(unit controlledUnit, unit leader, integer mode)
    call Companions_UnregisterControlled(unit controlledUnit)
    call Companions_IsControlled(unit controlledUnit) returns boolean

**/
library Companions initializer Init requires QuestGiver, FollowSystem, Table, UnitDeathEvent

globals
    constant integer COMPANION_MODE_DEFEND = 1
    constant integer COMPANION_MODE_NORMAL = 1
    constant integer COMPANION_MODE_PASSIVE = 2
    constant integer COMPANION_MODE_HOLD = 3
    constant integer COMPANION_MODE_AGGRESSIVE = 4

    private constant boolean DEBUG = false
    private constant integer MAX_PLAYER_INDEX = 27
    private constant integer COMPANION_OWNER_INDEX = 18
    private constant integer REJECT_OWNER_INDEX = 1
    private constant real COMPANION_FOLLOW_DISTANCE = 2500.00
    private constant real COMPANION_AGGRESSIVE_DISTANCE = 3500.00
    private constant real COMPANION_IDLE_CHECK_INTERVAL = 10.00

    private constant integer ABIL_INVITE = 'A622'
    private constant integer ABIL_KICK = 'A621'
    private constant integer ABIL_MODE_PASSIVE = 'A61Z'
    private constant integer ABIL_MODE_NORMAL = 'A61X'
    private constant integer ABIL_MODE_AGGRESSIVE = 'A61S'
    private constant integer ABIL_MODE_HOLD = 'A6DX'
    private constant integer ABIL_INFORMATION = 'A6E9'
    private constant integer ABIL_DROP_ITEMS = 'A6DZ'
    private constant integer ABIL_FOCUS_NAZGREK = 'A6E4'
    private constant integer ABIL_FOCUS_ZULKIS = 'A6E5'
    private constant integer ABIL_WANDER_NEUTRAL = 'Awan'
    private constant integer BUFF_TIMED_LIFE = 'BTLF'

    private constant integer UNIT_ROGUE = 'O631'
    private constant integer UNIT_WARLOCK = 'O61K'
    private constant integer UNIT_RIVERBANE_WARLOCK = 'H60X'
    private constant integer UNIT_SHAMAN = 'O61H'
    private constant integer UNIT_WARRIOR = 'O629'
    private constant integer UNIT_ENGINEER = 'N64O'
    private constant integer UNIT_ENGINEER_SHREDDER = 'N661'
    private constant integer UNIT_PALADIN = 'H60Y'

    private constant integer UNIT_GRUNT_1 = 'o62Y'
    private constant integer UNIT_GRUNT_5 = 'o634'
    private constant integer UNIT_GRUNT_10 = 'o635'
    private constant integer UNIT_GRUNT_15 = 'o636'
    private constant integer UNIT_GRUNT_20 = 'o637'
    private constant integer UNIT_GRUNT_25 = 'o638'
    private constant integer UNIT_MARAUDER_1 = 'o62P'
    private constant integer UNIT_MARAUDER_5 = 'o630'
    private constant integer UNIT_STONEGUARD_5 = 'o62Z'
    private constant integer UNIT_RAIDER = 'orai'
    private constant integer UNIT_HEADHUNTER = 'ohun'
    private constant integer UNIT_WITCH_DOCTOR = 'odoc'
    private constant integer UNIT_HIRED_SHAMAN = 'oshm'

    private Table CompanionLeader = 0
    private Table CompanionMode = 0
    private Table CompanionSuspended = 0
    private Table CompanionIcon = 0
    private Table CompanionRegistered = 0
    private Table CompanionTracked = 0

    private group ModeTargetGroup = null
    private trigger IdleTrigger = null
    private player ModeSelectionPlayer = null
    private boolean ModeSelectionFound = false
    private integer ModeActionMode = COMPANION_MODE_DEFEND
    private integer CurrentGroupMode = COMPANION_MODE_DEFEND
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("[Companions] " + msg)
    endif
endfunction

private function EnsureState takes nothing returns nothing
    if CompanionTracked == 0 then
        set CompanionLeader = Table.create()
        set CompanionMode = Table.create()
        set CompanionSuspended = Table.create()
        set CompanionIcon = Table.create()
        set CompanionRegistered = Table.create()
        set CompanionTracked = Table.create()
    endif
    if ModeTargetGroup == null then
        set ModeTargetGroup = CreateGroup()
    endif
endfunction

private function IsAliveUnit takes unit u returns boolean
    return u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD)
endfunction

private function IsControlGroupUnit takes unit u returns boolean
    if u == null then
        return false
    endif
    if udg_Companion_Group != null and IsUnitInGroup(u, udg_Companion_Group) then
        return true
    endif
    if udg_TamedUnits != null and IsUnitInGroup(u, udg_TamedUnits) then
        return true
    endif
    return false
endfunction

private function IsValidControlTarget takes unit u returns boolean
    return IsAliveUnit(u) and IsControlGroupUnit(u)
endfunction

private function NormalizeMode takes integer mode returns integer
    if mode == COMPANION_MODE_PASSIVE then
        return COMPANION_MODE_PASSIVE
    elseif mode == COMPANION_MODE_HOLD then
        return COMPANION_MODE_HOLD
    elseif mode == COMPANION_MODE_AGGRESSIVE then
        return COMPANION_MODE_AGGRESSIVE
    endif
    return COMPANION_MODE_DEFEND
endfunction

private function GetModeName takes integer mode returns string
    set mode = NormalizeMode(mode)
    if mode == COMPANION_MODE_PASSIVE then
        return "Passive"
    elseif mode == COMPANION_MODE_HOLD then
        return "Hold Position"
    elseif mode == COMPANION_MODE_AGGRESSIVE then
        return "Aggressive"
    endif
    return "Normal"
endfunction

private function GetModeDistance takes integer mode returns real
    if NormalizeMode(mode) == COMPANION_MODE_AGGRESSIVE then
        return COMPANION_AGGRESSIVE_DISTANCE
    endif
    return COMPANION_FOLLOW_DISTANCE
endfunction

private function GetModeFollowStyle takes integer mode returns integer
    if NormalizeMode(mode) == COMPANION_MODE_PASSIVE then
        return FOLLOW_STYLE_PASSIVE
    endif
    return FOLLOW_STYLE_DEFEND
endfunction

private function GetPreferredLeader takes unit caster returns unit
    if IsAliveUnit(caster) and (caster == udg_Nazgrek or caster == udg_Zulkis) then
        return caster
    endif
    if IsAliveUnit(udg_Nazgrek) then
        return udg_Nazgrek
    endif
    if IsAliveUnit(udg_Zulkis) then
        return udg_Zulkis
    endif
    return null
endfunction

private function GetFocusedLeader takes unit u returns unit
    local integer unitId
    local unit leader = null

    if u == null then
        return null
    endif

    if CompanionTracked != 0 then
        set unitId = GetHandleId(u)
        set leader = CompanionLeader.unit[unitId]
        if IsAliveUnit(leader) then
            return leader
        endif
    endif

    if udg_CompanionFocusZulkis != null and IsUnitInGroup(u, udg_CompanionFocusZulkis) and IsAliveUnit(udg_Zulkis) then
        return udg_Zulkis
    endif
    if udg_CompanionFocusNazgrek != null and IsUnitInGroup(u, udg_CompanionFocusNazgrek) and IsAliveUnit(udg_Nazgrek) then
        return udg_Nazgrek
    endif

    return GetPreferredLeader(null)
endfunction

private function SetFocusUnit takes unit u, unit leader returns nothing
    if u == null then
        return
    endif
    if udg_CompanionFocusNazgrek != null then
        call GroupRemoveUnit(udg_CompanionFocusNazgrek, u)
    endif
    if udg_CompanionFocusZulkis != null then
        call GroupRemoveUnit(udg_CompanionFocusZulkis, u)
    endif
    if leader == udg_Zulkis and udg_CompanionFocusZulkis != null then
        call GroupAddUnit(udg_CompanionFocusZulkis, u)
    elseif udg_CompanionFocusNazgrek != null then
        call GroupAddUnit(udg_CompanionFocusNazgrek, u)
    endif
endfunction

private function RemoveWanderAbility takes unit u returns nothing
    if u != null and GetUnitAbilityLevel(u, ABIL_WANDER_NEUTRAL) > 0 then
        call UnitRemoveAbility(u, ABIL_WANDER_NEUTRAL)
    endif
endfunction

private function AddWanderAbility takes unit u returns nothing
    if u != null and GetUnitAbilityLevel(u, ABIL_WANDER_NEUTRAL) == 0 then
        call UnitAddAbility(u, ABIL_WANDER_NEUTRAL)
    endif
endfunction

private function FindCompanionIndex takes unit companionUnit returns integer
    local integer i = 1
    loop
        exitwhen i > udg_CompanionCount
        if udg_CompanionUnit[i] == companionUnit then
            return i
        endif
        set i = i + 1
    endloop
    return 0
endfunction

private function SyncGuiCompanionEntry takes unit companionUnit, string companionIcon returns nothing
    local integer index
    local integer customValue

    if companionUnit == null then
        return
    endif

    set index = FindCompanionIndex(companionUnit)
    set customValue = GetUnitUserData(companionUnit)

    if index > 0 then
        set udg_CompanionIndex[customValue] = index
        if companionIcon != "" then
            set udg_CompanionIcon[index] = companionIcon
        endif
    endif
    if customValue > 0 then
        set udg_UnitHider_ReferenceUnits[customValue] = companionUnit
    endif
endfunction

private function RegisterControlledInternal takes unit controlledUnit, unit leader, integer mode, boolean registered, string icon returns nothing
    local integer unitId

    if controlledUnit == null or GetUnitTypeId(controlledUnit) == 0 then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(controlledUnit)
    set CompanionTracked[unitId] = 1
    set CompanionRegistered[unitId] = 0
    if registered then
        set CompanionRegistered[unitId] = 1
    endif
    set CompanionLeader.unit[unitId] = leader
    set CompanionMode[unitId] = NormalizeMode(mode)
    set CompanionSuspended[unitId] = 0
    set CompanionIcon.string[unitId] = icon

    call RemoveWanderAbility(controlledUnit)
    call SetFocusUnit(controlledUnit, leader)
endfunction

private function TrackExistingControlUnit takes unit controlledUnit returns nothing
    local integer unitId
    local unit leader

    if controlledUnit == null or GetUnitTypeId(controlledUnit) == 0 then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(controlledUnit)
    if CompanionTracked[unitId] == 1 then
        return
    endif

    set leader = GetFocusedLeader(controlledUnit)
    call RegisterControlledInternal(controlledUnit, leader, CurrentGroupMode, udg_Companion_Group != null and IsUnitInGroup(controlledUnit, udg_Companion_Group) and FindCompanionIndex(controlledUnit) > 0, "")
    set leader = null
endfunction

private function ApplyOrders takes unit companionUnit returns nothing
    local integer unitId
    local unit leader
    local integer mode

    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 then
        return
    endif
    if CompanionTracked == 0 then
        return
    endif

    set unitId = GetHandleId(companionUnit)
    if CompanionTracked[unitId] == 0 then
        return
    endif

    if CompanionSuspended[unitId] == 1 then
        call FollowSystem_RemoveUnit(companionUnit)
        call IssueImmediateOrder(companionUnit, "stop")
        return
    endif

    set leader = CompanionLeader.unit[unitId]
    set mode = NormalizeMode(CompanionMode[unitId])
    set CompanionMode[unitId] = mode

    if mode == COMPANION_MODE_HOLD then
        call FollowSystem_RemoveUnit(companionUnit)
        call IssueImmediateOrder(companionUnit, "holdposition")
    elseif IsAliveUnit(companionUnit) and IsAliveUnit(leader) and leader != companionUnit then
        call FollowSystem_SetFollow(companionUnit, leader, GetModeDistance(mode), false, 0.00, GetModeFollowStyle(mode), true, true)
    else
        call FollowSystem_RemoveUnit(companionUnit)
        call IssueImmediateOrder(companionUnit, "stop")
    endif

    set leader = null
endfunction

private function AddInternal takes unit companionUnit, string companionIcon, unit leader, integer mode returns nothing
    local integer unitId

    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(companionUnit)

    if CompanionRegistered[unitId] == 0 then
        call QuestGiver_AddCompanion(companionUnit, companionIcon)
    endif

    call RegisterControlledInternal(companionUnit, leader, mode, true, companionIcon)
    call SyncGuiCompanionEntry(companionUnit, companionIcon)
    call ApplyOrders(companionUnit)
    call DebugMsg("Add " + GetUnitName(companionUnit))
endfunction

private function RemoveInternal takes unit companionUnit returns nothing
    local integer unitId

    if companionUnit == null or CompanionTracked == 0 then
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
    call CompanionTracked.remove(unitId)
    call DebugMsg("Remove " + GetUnitName(companionUnit))
endfunction

private function SetLeaderInternal takes unit companionUnit, unit leader returns nothing
    local integer unitId

    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(companionUnit)
    if CompanionTracked[unitId] == 0 then
        call RegisterControlledInternal(companionUnit, leader, CurrentGroupMode, udg_Companion_Group != null and IsUnitInGroup(companionUnit, udg_Companion_Group) and FindCompanionIndex(companionUnit) > 0, "")
    endif

    set CompanionLeader.unit[unitId] = leader
    call SetFocusUnit(companionUnit, leader)
    call ApplyOrders(companionUnit)
endfunction

private function SetModeInternal takes unit companionUnit, integer mode returns nothing
    local integer unitId

    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(companionUnit)
    if CompanionTracked[unitId] == 0 then
        call RegisterControlledInternal(companionUnit, GetFocusedLeader(companionUnit), mode, udg_Companion_Group != null and IsUnitInGroup(companionUnit, udg_Companion_Group) and FindCompanionIndex(companionUnit) > 0, "")
    endif

    set CompanionMode[unitId] = NormalizeMode(mode)
    call ApplyOrders(companionUnit)
endfunction

private function SetIdleFlag takes unit controlledUnit, boolean isIdle returns nothing
    local integer customValue

    if controlledUnit == null then
        return
    endif

    set customValue = GetUnitUserData(controlledUnit)
    if customValue > 0 then
        set udg_CompanionUnitIdle[customValue] = isIdle
    endif
endfunction

private function ClearIdleState takes unit controlledUnit returns nothing
    call RemoveWanderAbility(controlledUnit)
    call SetIdleFlag(controlledUnit, false)
endfunction

private function IsCompanionIdleBlocked takes unit controlledUnit returns boolean
    local integer unitId
    local integer mode

    if controlledUnit == null or CompanionTracked == 0 then
        return false
    endif

    set unitId = GetHandleId(controlledUnit)
    if CompanionTracked[unitId] == 0 then
        return false
    endif

    set mode = NormalizeMode(CompanionMode[unitId])
    return CompanionSuspended[unitId] == 1 or mode == COMPANION_MODE_HOLD
endfunction

private function UpdateCompanionIdleUnit takes unit controlledUnit, boolean isPet returns nothing
    local integer customValue

    if controlledUnit == null or GetUnitTypeId(controlledUnit) == 0 then
        return
    endif

    call TrackExistingControlUnit(controlledUnit)
    set customValue = GetUnitUserData(controlledUnit)
    if customValue <= 0 or not IsAliveUnit(controlledUnit) or not udg_IsUnitAlive[customValue] then
        call ClearIdleState(controlledUnit)
        return
    endif

    if IsCompanionIdleBlocked(controlledUnit) then
        call ClearIdleState(controlledUnit)
        return
    endif

    if isPet then
        if not udg_UnitMoving[customValue] then
            call AddWanderAbility(controlledUnit)
            set udg_CompanionUnitIdle[customValue] = true
        else
            call ClearIdleState(controlledUnit)
        endif
    elseif not udg_UnitMoving[customValue] and not udg_GCSM_UnitInCombat[customValue] and not udg_CompanionDialogueActive then
        call AddWanderAbility(controlledUnit)
        set udg_CompanionUnitIdle[customValue] = true
    else
        call ClearIdleState(controlledUnit)
    endif
endfunction

private function UpdateCompanionIdleEnum takes nothing returns nothing
    local unit controlledUnit = GetEnumUnit()

    call UpdateCompanionIdleUnit(controlledUnit, false)

    set controlledUnit = null
endfunction

private function UpdatePetIdleEnum takes nothing returns nothing
    local unit controlledUnit = GetEnumUnit()

    call UpdateCompanionIdleUnit(controlledUnit, true)

    set controlledUnit = null
endfunction

private function OnIdlePeriodic takes nothing returns nothing
    if udg_InCinematic then
        return
    endif

    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function UpdateCompanionIdleEnum)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function UpdatePetIdleEnum)
    endif
endfunction

private function IsNamedCompanionType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_ROGUE or unitTypeId == UNIT_WARLOCK or unitTypeId == UNIT_RIVERBANE_WARLOCK or unitTypeId == UNIT_SHAMAN or unitTypeId == UNIT_WARRIOR or unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER or unitTypeId == UNIT_PALADIN
endfunction

private function GetNamedCompanionIcon takes integer unitTypeId returns string
    if unitTypeId == UNIT_ROGUE then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroBlademaster.blp"
    elseif unitTypeId == UNIT_WARLOCK or unitTypeId == UNIT_RIVERBANE_WARLOCK then
        return "ReplaceableTextures\\CommandButtons\\BTNChaosWarlockGreen.blp"
    elseif unitTypeId == UNIT_SHAMAN then
        return "ReplaceableTextures\\CommandButtons\\BTNShaman.blp"
    elseif unitTypeId == UNIT_WARRIOR then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroTaurenChieftain.blp"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroTinker.blp"
    elseif unitTypeId == UNIT_PALADIN then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroPaladin.blp"
    endif
    return ""
endfunction

private function GetReturnOwner takes integer unitTypeId returns player
    if unitTypeId == UNIT_ROGUE or unitTypeId == UNIT_WARLOCK or unitTypeId == UNIT_SHAMAN or unitTypeId == UNIT_WARRIOR then
        return Player(5)
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return Player(6)
    elseif unitTypeId == UNIT_PALADIN or unitTypeId == UNIT_RIVERBANE_WARLOCK then
        return Player(14)
    endif
    return null
endfunction

private function GetCompanionLimit takes nothing returns integer
    if udg_Companion_GroupSize > 0 then
        return udg_Companion_GroupSize
    endif
    return 6
endfunction

private function IsCompanionPartyFull takes nothing returns boolean
    return udg_CompanionCount >= GetCompanionLimit()
endfunction

private function GetMaxPartyHeroLevel takes nothing returns integer
    local integer level = 1

    if udg_Nazgrek != null and GetHeroLevel(udg_Nazgrek) > level then
        set level = GetHeroLevel(udg_Nazgrek)
    endif
    if udg_Zulkis != null and GetHeroLevel(udg_Zulkis) > level then
        set level = GetHeroLevel(udg_Zulkis)
    endif

    return level
endfunction

private function GetHiredUnitLevel takes unit hiredUnit returns integer
    local integer unitTypeId

    if hiredUnit == null then
        return 0
    endif

    set unitTypeId = GetUnitTypeId(hiredUnit)
    if unitTypeId == UNIT_GRUNT_1 or unitTypeId == UNIT_MARAUDER_1 or unitTypeId == UNIT_RAIDER or unitTypeId == UNIT_HEADHUNTER or unitTypeId == UNIT_WITCH_DOCTOR or unitTypeId == UNIT_HIRED_SHAMAN then
        return IMaxBJ(GetUnitLevel(hiredUnit), 1)
    elseif unitTypeId == UNIT_GRUNT_5 or unitTypeId == UNIT_MARAUDER_5 or unitTypeId == UNIT_STONEGUARD_5 then
        return 5
    elseif unitTypeId == UNIT_GRUNT_10 then
        return 10
    elseif unitTypeId == UNIT_GRUNT_15 then
        return 15
    elseif unitTypeId == UNIT_GRUNT_20 then
        return 20
    elseif unitTypeId == UNIT_GRUNT_25 then
        return 25
    endif

    return 0
endfunction

private function GetHiredUnitIcon takes integer unitTypeId returns string
    if unitTypeId == UNIT_GRUNT_1 or unitTypeId == UNIT_GRUNT_5 or unitTypeId == UNIT_GRUNT_10 or unitTypeId == UNIT_GRUNT_15 or unitTypeId == UNIT_GRUNT_20 or unitTypeId == UNIT_GRUNT_25 then
        return "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp"
    elseif unitTypeId == UNIT_MARAUDER_1 or unitTypeId == UNIT_MARAUDER_5 then
        return "ReplaceableTextures\\CommandButtons\\BTNChaosWarlord.blp"
    elseif unitTypeId == UNIT_STONEGUARD_5 then
        return "ReplaceableTextures\\CommandButtons\\BTNTauren.blp"
    elseif unitTypeId == UNIT_RAIDER then
        return "ReplaceableTextures\\CommandButtons\\BTNRaider.blp"
    elseif unitTypeId == UNIT_HEADHUNTER then
        return "ReplaceableTextures\\CommandButtons\\BTNHeadHunterBerserker.blp"
    elseif unitTypeId == UNIT_WITCH_DOCTOR then
        return "ReplaceableTextures\\CommandButtons\\BTNWitchDoctor.blp"
    elseif unitTypeId == UNIT_HIRED_SHAMAN then
        return "ReplaceableTextures\\CommandButtons\\BTNShaman.blp"
    endif
    return ""
endfunction

private function RejectTemporaryCompanion takes unit companionUnit, string message returns nothing
    if companionUnit == null then
        return
    endif

    if message != "" then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, message)
    endif

    call SetUnitOwner(companionUnit, Player(REJECT_OWNER_INDEX), true)
    call UnitApplyTimedLife(companionUnit, BUFF_TIMED_LIFE, 60.00)
    call IssuePointOrder(companionUnit, "attack", GetUnitX(companionUnit) + GetRandomReal(-600.00, 600.00), GetUnitY(companionUnit) + GetRandomReal(-600.00, 600.00))
endfunction

private function AddSelectedModeTarget takes nothing returns nothing
    local unit u = GetEnumUnit()

    if IsValidControlTarget(u) and IsUnitSelected(u, ModeSelectionPlayer) then
        call GroupAddUnit(ModeTargetGroup, u)
        set ModeSelectionFound = true
    endif

    set u = null
endfunction

private function AddAllModeTarget takes nothing returns nothing
    local unit u = GetEnumUnit()

    if IsValidControlTarget(u) then
        call GroupAddUnit(ModeTargetGroup, u)
    endif

    set u = null
endfunction

private function ApplyModeTarget takes nothing returns nothing
    local unit u = GetEnumUnit()
    call TrackExistingControlUnit(u)
    call SetModeInternal(u, ModeActionMode)
    set u = null
endfunction

private function ApplyModeFromPlayer takes player modePlayer, integer mode returns nothing
    local integer count

    call EnsureState()
    set mode = NormalizeMode(mode)
    set ModeSelectionPlayer = modePlayer
    set ModeSelectionFound = false
    call GroupClear(ModeTargetGroup)

    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function AddSelectedModeTarget)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function AddSelectedModeTarget)
    endif

    if not ModeSelectionFound then
        if udg_Companion_Group != null then
            call ForGroup(udg_Companion_Group, function AddAllModeTarget)
        endif
        if udg_TamedUnits != null then
            call ForGroup(udg_TamedUnits, function AddAllModeTarget)
        endif
        set CurrentGroupMode = mode
    endif

    set ModeActionMode = mode
    call ForGroup(ModeTargetGroup, function ApplyModeTarget)
    set count = CountUnitsInGroup(ModeTargetGroup)

    if count > 0 then
        if gg_snd_GoodJob != null then
            call StartSound(gg_snd_GoodJob)
        endif
        if ModeSelectionFound then
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Selected companions: " + GetModeName(mode) + " Mode")
        else
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Companions: " + GetModeName(mode) + " Mode")
        endif
    endif

    call GroupClear(ModeTargetGroup)
    set ModeSelectionPlayer = null
endfunction

private function GetModeFromAbility takes integer abilityId returns integer
    if abilityId == ABIL_MODE_PASSIVE then
        return COMPANION_MODE_PASSIVE
    elseif abilityId == ABIL_MODE_HOLD then
        return COMPANION_MODE_HOLD
    elseif abilityId == ABIL_MODE_AGGRESSIVE then
        return COMPANION_MODE_AGGRESSIVE
    elseif abilityId == ABIL_MODE_NORMAL then
        return COMPANION_MODE_DEFEND
    endif
    return 0
endfunction

private function HandleInvite takes unit caster, unit target returns nothing
    local integer unitTypeId
    local string icon
    local unit leader

    if target == null then
        return
    endif

    set unitTypeId = GetUnitTypeId(target)
    if not IsNamedCompanionType(unitTypeId) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "This unit cannot join the party.")
        return
    endif

    if IsUnitEnemy(target, GetOwningPlayer(caster)) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " is hostile and cannot be invited.")
        return
    endif

    if IsCompanionPartyFull() then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Companions: party is full.")
        return
    endif

    if GetUnitLevel(target) > GetMaxPartyHeroLevel() + 5 then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " is too experienced to join this party.")
        return
    endif

    set icon = GetNamedCompanionIcon(unitTypeId)
    set leader = GetPreferredLeader(caster)
    call SetUnitOwner(target, Player(COMPANION_OWNER_INDEX), true)
    call AddInternal(target, icon, leader, CurrentGroupMode)

    set leader = null
endfunction

private function HandleKick takes unit caster, unit target returns nothing
    local player returnOwner

    if target == null or udg_Companion_Group == null or not IsUnitInGroup(target, udg_Companion_Group) then
        return
    endif

    set udg_CompanionUnitKicked = target
    if gg_snd_UpkeepRing != null then
        call StartSound(gg_snd_UpkeepRing)
    endif

    set returnOwner = GetReturnOwner(GetUnitTypeId(target))
    call RemoveInternal(target)
    call RemoveWanderAbility(target)

    if returnOwner != null then
        call SetUnitOwner(target, returnOwner, true)
    else
        call RejectTemporaryCompanion(target, "")
    endif

    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " has left the party.")
    set returnOwner = null
endfunction

private function HandleFocus takes unit target, unit leader returns nothing
    if target == null or not IsControlGroupUnit(target) then
        return
    endif

    call TrackExistingControlUnit(target)
    call SetLeaderInternal(target, leader)
    if leader != null then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " now follows " + GetUnitName(leader) + ".")
    endif
endfunction

private function IsHiredUnitType takes integer unitTypeId returns boolean
    if unitTypeId == UNIT_GRUNT_1 or unitTypeId == UNIT_GRUNT_5 or unitTypeId == UNIT_GRUNT_10 or unitTypeId == UNIT_GRUNT_15 or unitTypeId == UNIT_GRUNT_20 or unitTypeId == UNIT_GRUNT_25 then
        return true
    endif
    if unitTypeId == UNIT_MARAUDER_1 or unitTypeId == UNIT_MARAUDER_5 or unitTypeId == UNIT_STONEGUARD_5 then
        return true
    endif
    return unitTypeId == UNIT_RAIDER or unitTypeId == UNIT_HEADHUNTER or unitTypeId == UNIT_WITCH_DOCTOR or unitTypeId == UNIT_HIRED_SHAMAN
endfunction

private function GetDisplayName takes unit target returns string
    local string displayName

    if target == null or GetUnitTypeId(target) == 0 then
        return "Unknown"
    endif

    if IsUnitType(target, UNIT_TYPE_HERO) then
        set displayName = GetHeroProperName(target)
        if displayName != null and displayName != "" then
            return displayName
        endif
    endif

    set displayName = GetUnitName(target)
    if displayName != null and displayName != "" then
        return displayName
    endif

    set displayName = GetObjectName(GetUnitTypeId(target))
    if displayName != null and displayName != "" then
        return displayName
    endif

    return "Unknown"
endfunction

private function GetUnitTypeInfoName takes integer unitTypeId returns string
    local string objectName

    if unitTypeId == UNIT_ROGUE then
        return "Rogue"
    elseif unitTypeId == UNIT_WARLOCK or unitTypeId == UNIT_RIVERBANE_WARLOCK then
        return "Warlock"
    elseif unitTypeId == UNIT_SHAMAN then
        return "Restoration Shaman"
    elseif unitTypeId == UNIT_WARRIOR then
        return "Warrior"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Engineer"
    elseif unitTypeId == UNIT_PALADIN then
        return "Paladin"
    elseif unitTypeId == UNIT_GRUNT_1 or unitTypeId == UNIT_GRUNT_5 or unitTypeId == UNIT_GRUNT_10 or unitTypeId == UNIT_GRUNT_15 or unitTypeId == UNIT_GRUNT_20 or unitTypeId == UNIT_GRUNT_25 then
        return "Grunt"
    elseif unitTypeId == UNIT_MARAUDER_1 or unitTypeId == UNIT_MARAUDER_5 then
        return "Marauder"
    elseif unitTypeId == UNIT_STONEGUARD_5 then
        return "Stoneguard"
    elseif unitTypeId == UNIT_RAIDER then
        return "Raider"
    elseif unitTypeId == UNIT_HEADHUNTER then
        return "Headhunter"
    elseif unitTypeId == UNIT_WITCH_DOCTOR then
        return "Witch Doctor"
    elseif unitTypeId == UNIT_HIRED_SHAMAN then
        return "Shaman"
    endif

    set objectName = GetObjectName(unitTypeId)
    if objectName != null and objectName != "" then
        return objectName
    endif

    return "Controlled Unit"
endfunction

private function GetFactionInfoText takes unit target returns string
    local integer unitTypeId

    if target == null then
        return "Unknown"
    endif

    set unitTypeId = GetUnitTypeId(target)
    if udg_TamedUnits != null and IsUnitInGroup(target, udg_TamedUnits) then
        return "Tamed Beast"
    elseif target == udg_Shadowclaw then
        return "Shadowclaw"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Goblins"
    elseif unitTypeId == UNIT_PALADIN or unitTypeId == UNIT_RIVERBANE_WARLOCK then
        return "Riverbane Citizen"
    elseif IsNamedCompanionType(unitTypeId) or IsHiredUnitType(unitTypeId) then
        return "Horde"
    endif

    return "Unknown"
endfunction

private function GetAttackTypeInfoText takes unit target returns string
    if target != null and IsUnitType(target, UNIT_TYPE_RANGED_ATTACKER) then
        return "Ranged"
    endif
    return "Melee"
endfunction

private function GetLevelInfoText takes unit target returns string
    if target == null then
        return "0"
    endif
    if IsUnitType(target, UNIT_TYPE_HERO) then
        return I2S(GetHeroLevel(target))
    endif
    return I2S(GetUnitLevel(target))
endfunction

private function GetDamageInfoText takes unit target returns string
    local integer baseDamage
    local integer diceCount
    local integer diceSides

    if target == null then
        return "0-0"
    endif

    set baseDamage = BlzGetUnitBaseDamage(target, 0)
    set diceCount = BlzGetUnitDiceNumber(target, 0)
    set diceSides = BlzGetUnitDiceSides(target, 0)

    if diceCount < 0 then
        set diceCount = 0
    endif
    if diceSides < 1 then
        set diceSides = 1
    endif

    return I2S(baseDamage + diceCount) + "-" + I2S(baseDamage + diceCount * diceSides)
endfunction

private function GetSharedStatsInfoText takes unit target returns string
    local integer customValue

    if target == null then
        return "-"
    endif

    set customValue = GetUnitUserData(target)
    if customValue <= 0 then
        return "-"
    endif

    return I2S(udg_Stats_Hit[customValue]) + "% Hit | " + I2S(udg_Stats_Crit[customValue]) + "% Crit | " + I2S(udg_Stats_Dodge[customValue]) + "% Dodge | " + I2S(udg_Stats_Block[customValue]) + "% Block | " + I2S(udg_Stats_SpellPowerPct[customValue]) + "% Spell | " + I2S(udg_Stats_SpellPowerFlat[customValue]) + " Spell Power"
endfunction

private function GetFocusInfoText takes unit target returns string
    local unit leader = GetFocusedLeader(target)
    local string result = "None"

    if IsControlGroupUnit(target) and IsAliveUnit(leader) then
        set result = GetDisplayName(leader)
    endif

    set leader = null
    return result
endfunction

private function GetAbilityInfoText takes unit target returns string
    local integer unitTypeId

    if target == null then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(target)
    if unitTypeId == UNIT_WARLOCK or unitTypeId == UNIT_RIVERBANE_WARLOCK then
        return "Shadow Bolt, Life Drain, Rain of Fire, Banish, Fear, Curse of Agony, Life Tap, Summon Imp"
    elseif unitTypeId == UNIT_ROGUE then
        return "Evasion, Garrote, Shadowstep, Sinister Strike, Slice and Dice, Surprise Attack, Toxic Venom"
    elseif unitTypeId == UNIT_WARRIOR then
        return "Battle Shout, Charge, Heroic Strike, Rend, Sunder Armor, Thunder Clap, Retaliation, Recklessness"
    elseif unitTypeId == UNIT_SHAMAN then
        return "Chain Heal, Chain Lightning, Earth Totem, Earthbind Totem, Fire Totem, Stoneskin Totem, Water Totem, Wind Totem, Windfury Totem, Healing Wave, Hex, Lightning Bolt"
    elseif unitTypeId == UNIT_ENGINEER then
        return "Repair, Mechanical Construct, Grenade, Turret, Shredder, Drone, Smoke Bomb"
    elseif unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Shred, Charge, Slam, Cluster Rockets, Smoke Bomb"
    elseif unitTypeId == UNIT_PALADIN then
        return "Divine Shield, Holy Light, Inner Fire, Judgement Strike, Lay on Hands"
    elseif target == udg_Shadowclaw then
        return "Initial pet rules, scaled stats, pet inventory, fatigue, revive"
    elseif udg_TamedUnits != null and IsUnitInGroup(target, udg_TamedUnits) then
        return "Tamed beast abilities, pet inventory, fatigue, revive"
    elseif IsHiredUnitType(unitTypeId) then
        return "Hired unit command-card abilities"
    endif

    return "Unit command-card abilities"
endfunction

private function HandleInformation takes unit target returns nothing
    local integer unitId
    local integer unitTypeId
    local real maxMana
    local string modeText = "Uncontrolled"

    if target == null or GetUnitTypeId(target) == 0 then
        return
    endif

    set unitTypeId = GetUnitTypeId(target)
    if not IsControlGroupUnit(target) and not IsNamedCompanionType(unitTypeId) and not IsHiredUnitType(unitTypeId) then
        return
    endif

    if gg_snd_GoodJob != null then
        call StartSound(gg_snd_GoodJob)
    endif

    if IsControlGroupUnit(target) then
        call TrackExistingControlUnit(target)
        if CompanionTracked != 0 then
            set unitId = GetHandleId(target)
            if CompanionTracked[unitId] == 1 then
                set modeText = GetModeName(CompanionMode[unitId])
            endif
        endif
    else
        set modeText = "Not in party"
    endif

    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Name:|r " + GetDisplayName(target))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Unit type: |r" + GetUnitTypeInfoName(unitTypeId))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Attack type: |r" + GetAttackTypeInfoText(target))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Faction: |r" + GetFactionInfoText(target))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Level: |r" + GetLevelInfoText(target) + " | |cFFFFCC00Life: |r" + I2S(R2I(GetUnitState(target, UNIT_STATE_LIFE))) + " / " + I2S(R2I(GetUnitState(target, UNIT_STATE_MAX_LIFE))))

    set maxMana = GetUnitState(target, UNIT_STATE_MAX_MANA)
    if maxMana > 0.00 then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Mana: |r" + I2S(R2I(GetUnitState(target, UNIT_STATE_MANA))) + " / " + I2S(R2I(maxMana)) + " | |cFFFFCC00Damage: |r" + GetDamageInfoText(target) + " | |cFFFFCC00Armor: |r" + I2S(R2I(BlzGetUnitArmor(target))))
    else
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Damage: |r" + GetDamageInfoText(target) + " | |cFFFFCC00Armor: |r" + I2S(R2I(BlzGetUnitArmor(target))))
    endif

    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Stats: |r" + GetSharedStatsInfoText(target))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Mode: |r" + modeText + " | |cFFFFCC00Focus: |r" + GetFocusInfoText(target))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFF7EBFF1Abilities:|r " + GetAbilityInfoText(target))
endfunction

private function DropUnitItems takes unit target returns nothing
    local integer slot = 0
    local integer maxSlots = UnitInventorySize(target)
    local item droppedItem
    local real angle
    local real x = GetUnitX(target)
    local real y = GetUnitY(target)

    if maxSlots > 6 then
        set maxSlots = 6
    endif

    loop
        exitwhen slot >= maxSlots
        set droppedItem = UnitItemInSlot(target, slot)
        if droppedItem != null then
            call UnitRemoveItem(target, droppedItem)
            set angle = 6.2831853 * I2R(slot) / 6.00
            call SetItemPosition(droppedItem, x + 90.00 * Cos(angle), y + 90.00 * Sin(angle))
        endif
        set slot = slot + 1
    endloop

    set droppedItem = null
endfunction

private function HandleDropItems takes unit target returns nothing
    if target == null or udg_Companion_Group == null or not IsUnitInGroup(target, udg_Companion_Group) then
        return
    endif

    call DropUnitItems(target)
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " dropped carried items.")
endfunction

private function HandleSoldUnit takes nothing returns nothing
    local unit soldUnit = GetSoldUnit()
    local unit buyer = GetBuyingUnit()
    local integer unitTypeId
    local integer hiredLevel
    local string icon
    local unit leader

    if soldUnit == null then
        set buyer = null
        return
    endif

    if GetOwningPlayer(soldUnit) != Player(0) and (buyer == null or GetOwningPlayer(buyer) != Player(0)) then
        set soldUnit = null
        set buyer = null
        return
    endif

    set unitTypeId = GetUnitTypeId(soldUnit)
    set hiredLevel = GetHiredUnitLevel(soldUnit)
    set icon = GetHiredUnitIcon(unitTypeId)
    if hiredLevel <= 0 or icon == "" then
        set soldUnit = null
        set buyer = null
        return
    endif

    if IsCompanionPartyFull() then
        call RejectTemporaryCompanion(soldUnit, "Companions: party is full.")
        set soldUnit = null
        set buyer = null
        return
    endif

    if hiredLevel > GetMaxPartyHeroLevel() then
        call RejectTemporaryCompanion(soldUnit, GetUnitName(soldUnit) + " requires a higher-level leader.")
        set soldUnit = null
        set buyer = null
        return
    endif

    set udg_CompanionHiredUnitLevel[GetUnitUserData(soldUnit)] = hiredLevel
    set leader = GetPreferredLeader(buyer)
    call SetUnitOwner(soldUnit, Player(COMPANION_OWNER_INDEX), true)
    call AddInternal(soldUnit, icon, leader, CurrentGroupMode)

    set leader = null
    set soldUnit = null
    set buyer = null
endfunction

private function OnUnitDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()

    if dying != null and udg_Companion_Group != null and IsUnitInGroup(dying, udg_Companion_Group) and not IsUnitType(dying, UNIT_TYPE_HERO) and dying != udg_Valeria and dying != udg_Aradion then
        set udg_CompanionUnitKicked = dying
        call SyncGuiCompanionEntry(dying, "")
        call RemoveInternal(dying)
    endif

    set dying = null
endfunction

private function OnSpellEffect takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    local integer mode = GetModeFromAbility(abilityId)
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()

    if mode != 0 then
        call ApplyModeFromPlayer(GetOwningPlayer(caster), mode)
    elseif abilityId == ABIL_INVITE then
        if target != udg_Shadowclaw then
            call HandleInvite(caster, target)
        endif
    elseif abilityId == ABIL_KICK then
        if target == null or udg_TamedUnits == null or not IsUnitInGroup(target, udg_TamedUnits) then
            call HandleKick(caster, target)
        endif
    elseif abilityId == ABIL_FOCUS_NAZGREK then
        call HandleFocus(target, udg_Nazgrek)
    elseif abilityId == ABIL_FOCUS_ZULKIS then
        call HandleFocus(target, udg_Zulkis)
    elseif abilityId == ABIL_INFORMATION then
        call HandleInformation(target)
    elseif abilityId == ABIL_DROP_ITEMS then
        call HandleDropItems(target)
    endif

    set caster = null
    set target = null
endfunction

public function Add takes unit companionUnit, string companionIcon, unit leader, integer mode returns nothing
    call AddInternal(companionUnit, companionIcon, leader, mode)
endfunction

public function Remove takes unit companionUnit returns nothing
    call RemoveInternal(companionUnit)
endfunction

public function SetLeader takes unit companionUnit, unit leader returns nothing
    call SetLeaderInternal(companionUnit, leader)
endfunction

public function SetMode takes unit companionUnit, integer mode returns nothing
    call SetModeInternal(companionUnit, mode)
endfunction

public function Suspend takes unit companionUnit returns nothing
    local integer unitId

    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 or CompanionTracked == 0 then
        return
    endif

    set unitId = GetHandleId(companionUnit)
    if CompanionTracked[unitId] == 0 then
        return
    endif

    set CompanionSuspended[unitId] = 1
    call ApplyOrders(companionUnit)
endfunction

public function Resume takes unit companionUnit returns nothing
    local integer unitId

    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 or CompanionTracked == 0 then
        return
    endif

    set unitId = GetHandleId(companionUnit)
    if CompanionTracked[unitId] == 0 then
        return
    endif

    set CompanionSuspended[unitId] = 0
    call ApplyOrders(companionUnit)
endfunction

public function RegisterControlled takes unit controlledUnit, unit leader, integer mode returns nothing
    call RegisterControlledInternal(controlledUnit, leader, mode, false, "")
    call ApplyOrders(controlledUnit)
endfunction

public function UnregisterControlled takes unit controlledUnit returns nothing
    local integer unitId

    if controlledUnit == null or CompanionTracked == 0 then
        return
    endif

    set unitId = GetHandleId(controlledUnit)
    call FollowSystem_RemoveUnit(controlledUnit)
    call CompanionLeader.remove(unitId)
    call CompanionMode.remove(unitId)
    call CompanionSuspended.remove(unitId)
    call CompanionIcon.remove(unitId)
    call CompanionRegistered.remove(unitId)
    call CompanionTracked.remove(unitId)
endfunction

public function IsControlled takes unit controlledUnit returns boolean
    if controlledUnit == null or CompanionTracked == 0 then
        return false
    endif
    return CompanionTracked[GetHandleId(controlledUnit)] == 1
endfunction

private function Init takes nothing returns nothing
    local integer playerIndex = 0

    call EnsureState()

    set bj_lastCreatedTrigger = CreateTrigger()
    loop
        call TriggerRegisterPlayerUnitEvent(bj_lastCreatedTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > MAX_PLAYER_INDEX
    endloop
    call TriggerAddAction(bj_lastCreatedTrigger, function OnSpellEffect)

    set bj_lastCreatedTrigger = CreateTrigger()
    set playerIndex = 0
    loop
        call TriggerRegisterPlayerUnitEvent(bj_lastCreatedTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_SELL, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > MAX_PLAYER_INDEX
    endloop
    call TriggerAddAction(bj_lastCreatedTrigger, function HandleSoldUnit)

    set IdleTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(IdleTrigger, COMPANION_IDLE_CHECK_INTERVAL, true)
    call TriggerAddAction(IdleTrigger, function OnIdlePeriodic)

    call UnitDeathEvent_Register(function OnUnitDeath)
endfunction

endlibrary
