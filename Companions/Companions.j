/**
    Companions

    Author: Valdemar
    Credits:
    - Old GUI companion triggers, converted and consolidated into JASS.
    Version:

    Description:
    Companion party registration, information, idle state, and control-mode
    handling. This library keeps the existing GUI companion globals
    synchronized for older systems. Normal companions and pets use this
    library's companion controller; quest escort cases can opt into
    FollowSystem leash behavior explicitly.

    API:
    call Companions_Add(unit companionUnit, string companionIcon, unit leader, integer mode)
    call Companions_Remove(unit companionUnit)
    call Companions_SetLeader(unit companionUnit, unit leader)
    call Companions_SetMode(unit companionUnit, integer mode)
    call Companions_Halt(unit companionUnit)
    call Companions_HaltAll()
    call Companions_Suspend(unit companionUnit)
    call Companions_Resume(unit companionUnit)
    call Companions_ResumeAll()
    call Companions_RegisterControlled(unit controlledUnit, unit leader, integer mode)
    call Companions_UnregisterControlled(unit controlledUnit)
    call Companions_IsControlled(unit controlledUnit) returns boolean
    call Companions_IsControlledDisplayUnit(unit controlledUnit) returns boolean
    call Companions_GetControlledDisplayCount() returns integer
    call Companions_GetControlledDisplayUnit(integer index) returns unit
    call Companions_SetEscortBehavior(unit controlledUnit, boolean enabled)
    call Companions_SetFollowerBehavior(unit controlledUnit, boolean enabled)
    call Companions_GetMode(unit controlledUnit) returns integer
    call Companions_RefreshOrders(unit controlledUnit)
    call Companions_GetCompanionLimit() returns integer
    call Companions_GetCompanionStatusText() returns string
    call Companions_ShowCompanionLimitInfo()
    call Companions_GetClassInfoText(unit controlledUnit) returns string
    call Companions_GetTypeInfoText(unit controlledUnit) returns string
    call Companions_GetFactionInfoText(unit controlledUnit) returns string
    call Companions_GetAbilityInfoText(unit controlledUnit) returns string

**/
library Companions initializer Init requires QuestGiver, FollowSystem, IconQuery, Table, Events, UnitDeathEvent, SpeciFX, Reputation, DialogSystem

globals
    constant integer COMPANION_MODE_DEFEND = 1
    constant integer COMPANION_MODE_NORMAL = 1
    constant integer COMPANION_MODE_PASSIVE = 2
    constant integer COMPANION_MODE_HOLD = 3
    constant integer COMPANION_MODE_AGGRESSIVE = 4

    public constant integer COMMAND_INVITE = 1
    public constant integer COMMAND_KICK = 2
    public constant integer COMMAND_MODE = 3
    public constant integer COMMAND_DROP_ITEMS = 4
    public unit EventUnit = null
    public unit EventSource = null
    public integer EventCommand = 0
    public integer EventMode = 0

    private constant boolean DEBUG = false
    private constant integer CONTROL_PLAYER_INDEX = 0
    private constant integer COMPANION_OWNER_INDEX = 18
    private constant integer REJECT_OWNER_INDEX = 1
    private constant integer ELARINDOR_OWNER_INDEX = 15
    private constant real COMPANION_FOLLOW_DISTANCE = 2500.00
    private constant real COMPANION_AGGRESSIVE_DISTANCE = 3500.00
    private constant real COMPANION_IDLE_CHECK_INTERVAL = 10.00
    private constant real COMPANION_ORDER_INTERVAL = 2.00
    private constant real HIRED_UNIT_SHOP_INIT_DELAY = 1.00
    private constant real COMPANION_NORMAL_CATCHUP_DISTANCE = 600.00
    private constant real COMPANION_POST_COMBAT_RETURN_DISTANCE = 350.00
    private constant real COMPANION_AGGRESSIVE_CATCHUP_DISTANCE = 1800.00
    private constant real COMPANION_NORMAL_MIN_OFFSET = 100.00
    private constant real COMPANION_NORMAL_MAX_OFFSET = 300.00
    private constant real COMPANION_AGGRESSIVE_MIN_OFFSET = 400.00
    private constant real COMPANION_AGGRESSIVE_MAX_OFFSET = 1800.00
    private constant real COMPANION_RANDOM_MOVE_MIN_DELAY = 3.00
    private constant real COMPANION_RANDOM_MOVE_MAX_DELAY = 7.00
    private constant real COMPANION_IDLE_LEADER_RANDOM_MOVE_MIN_DELAY = 5.00
    private constant real COMPANION_IDLE_LEADER_RANDOM_MOVE_MAX_DELAY = 15.00
    private constant integer COMPANION_PING_TICKS = 3
    private constant integer COMPANION_PING_STYLE = bj_MINIMAPPINGSTYLE_SIMPLE
    private constant integer COMPANION_PING_RED = 255
    private constant integer COMPANION_PING_GREEN = 255
    private constant integer COMPANION_PING_BLUE = 0
    private constant integer COMPANION_PROFILE_NORMAL = 0
    private constant integer COMPANION_PROFILE_ESCORT = 1
    private constant integer COMPANION_PROFILE_FOLLOWER = 2
    private constant integer CONTROLLED_DISPLAY_MAX = 128
    private constant boolean COMPANION_ENABLE_FOLLOWER_EFFECTS = true
    private constant string COMPANION_EFFECT_STOPPED_PATH = "war3mapImported\\QuestMarking.mdl"
    private constant string COMPANION_EFFECT_STOPPED_ATTACH = "origin"
    private constant string COMPANION_EFFECT_FOLLOWING_PATH = "UI\\Feedback\\TargetPreSelected\\TargetPreSelected.mdl"
    private constant string COMPANION_EFFECT_FOLLOWING_ATTACH = "origin"
    private constant integer COMPANION_EFFECT_FOLLOWING_VISIBLE_ALPHA = 255
    private constant integer COMPANION_EFFECT_FOLLOWING_HIDDEN_ALPHA = 0
    private constant real COMPANION_EFFECT_FOLLOWING_VISIBLE_SCALE = 1.00
    private constant real COMPANION_EFFECT_FOLLOWING_HIDDEN_SCALE = 0.001
    private constant string QUEST_RANGER_MISSING = "Ranger Missing"
    private constant string QUEST_RIFTS_CORRUPTION = "Rifts of Corruption"

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
    private constant integer UNIT_UNDEAD_WARLOCK = 'O61K'
    private constant integer UNIT_ORC_WARLOCK = 'H60X'
    private constant integer UNIT_SHAMAN = 'O61H'
    private constant integer UNIT_WARRIOR = 'O629'
    private constant integer UNIT_AVELINE = 'O009'
    private constant integer UNIT_ENGINEER = 'N64O'
    private constant integer UNIT_ENGINEER_SHREDDER = 'N661'
    private constant integer UNIT_PALADIN = 'H60Y'
    private constant integer UNIT_ARADION = 'h00A'
    private constant integer UNIT_VALERIA = 'n01W'

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
    private constant integer UNIT_AIR_ELEMENTAL = 'h60D'
    private constant integer UNIT_WATER_ELEMENTAL = 'n00O'
    private constant integer UNIT_FIRE_ELEMENTAL = 'n616'
    private constant integer UNIT_EARTH_ELEMENTAL = 'n615'
    private constant integer UNIT_SPIRIT_WOLF_1 = 'npig'
    private constant integer UNIT_SPIRIT_WOLF_2 = 'nwlt'
    private constant integer UNIT_SPIRIT_WOLF_3 = 'n61T'
    private constant integer UNIT_SPIRIT_WOLF_4 = 'nwlg'
    private constant integer UNIT_SPIRIT_WOLF_5 = 'nwld'
    private constant integer UNIT_SPIRIT_WOLF_OSW1 = 'osw1'
    private constant integer UNIT_SPIRIT_WOLF_OSW2 = 'osw2'
    private constant integer UNIT_SPIRIT_WOLF_OSW3 = 'osw3'

    private Table CompanionLeader = 0
    private Table CompanionMode = 0
    private Table CompanionSuspended = 0
    private Table CompanionIcon = 0
    private Table CompanionRegistered = 0
    private Table CompanionTracked = 0
    private Table CompanionOrderProfile = 0
    private Table CompanionNextRandomMove = 0
    private Table CompanionStoppedEffect = 0
    private Table CompanionFollowingEffect = 0
    private Table CompanionMapIconSlot = 0
    private Table CompanionPingCycle = 0
    private Table ControlledDisplayIndex = 0
    private minimapicon array CompanionMapIcons
    private unit array ControlledDisplayUnits
    private integer CompanionMapIconCount = 0
    private integer ControlledDisplayCount = 0

    private group ModeTargetGroup = null
    private group ControlledDisplayGroup = null
    private timer CompanionClock = null
    private trigger CommandEventTrigger = null
    private trigger IdleTrigger = null
    private trigger OrderTrigger = null
    private unit ModeCommandCaster = null
    private player CommandSelectionPlayer = null
    private unit CommandSelectionTarget = null
    private integer CommandSelectionCount = 0
    private integer ModeActionMode = COMPANION_MODE_DEFEND
    private unit FocusActionLeader = null
    private integer CurrentGroupMode = COMPANION_MODE_DEFEND
    private group HostilityDropGroup = null
    private integer HostilityDropFactionId = 0
    private unit HostilityDropBarkUnit = null
    private integer HostilityDropSeen = 0
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("[Companions] " + msg)
    endif
endfunction

private function PlayCommandSound takes sound whichSound returns nothing
    if whichSound != null then
        call StopSound(whichSound, false, false)
        call StartSound(whichSound)
    endif
endfunction

private function EnsureCommandEventTrigger takes nothing returns nothing
    if CommandEventTrigger == null then
        set CommandEventTrigger = CreateTrigger()
    endif
endfunction

private function FireCommandEvent takes unit target, unit source, integer commandId, integer mode returns nothing
    if target == null then
        set source = null
        return
    endif
    call EnsureCommandEventTrigger()
    set EventUnit = target
    set EventSource = source
    set EventCommand = commandId
    set EventMode = mode
    call TriggerExecute(CommandEventTrigger)
    set EventUnit = null
    set EventSource = null
    set EventCommand = 0
    set EventMode = 0
    set source = null
endfunction

public function RegisterCommandEvent takes code callback returns nothing
    call EnsureCommandEventTrigger()
    call TriggerAddAction(CommandEventTrigger, callback)
endfunction

private function EnsureState takes nothing returns nothing
    if CompanionTracked == 0 then
        set CompanionLeader = Table.create()
        set CompanionMode = Table.create()
        set CompanionSuspended = Table.create()
        set CompanionIcon = Table.create()
        set CompanionRegistered = Table.create()
        set CompanionTracked = Table.create()
        set CompanionOrderProfile = Table.create()
        set CompanionNextRandomMove = Table.create()
        set CompanionStoppedEffect = Table.create()
        set CompanionFollowingEffect = Table.create()
        set CompanionMapIconSlot = Table.create()
        set CompanionPingCycle = Table.create()
        set ControlledDisplayIndex = Table.create()
    endif
    if ModeTargetGroup == null then
        set ModeTargetGroup = CreateGroup()
    endif
    if ControlledDisplayGroup == null then
        set ControlledDisplayGroup = CreateGroup()
    endif
    if HostilityDropGroup == null then
        set HostilityDropGroup = CreateGroup()
    endif
    if CompanionClock == null then
        set CompanionClock = CreateTimer()
        call TimerStart(CompanionClock, 1000000.00, false, null)
    endif
endfunction

private function GetNow takes nothing returns real
    call EnsureState()
    return TimerGetElapsed(CompanionClock)
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
    if ControlledDisplayGroup != null and IsUnitInGroup(u, ControlledDisplayGroup) then
        return true
    endif
    return false
endfunction

private function IsPetControlUnit takes unit u returns boolean
    return u != null and udg_TamedUnits != null and IsUnitInGroup(u, udg_TamedUnits)
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

private function IsPlayerOwnedCommander takes unit u returns boolean
    return IsAliveUnit(u) and GetOwningPlayer(u) == Player(CONTROL_PLAYER_INDEX)
endfunction

private function PickCompanionCommandSpeaker takes nothing returns unit
    local boolean nazgrekOwned = IsPlayerOwnedCommander(udg_Nazgrek)
    local boolean zulkisOwned = IsPlayerOwnedCommander(udg_Zulkis)

    if nazgrekOwned and zulkisOwned then
        if GetRandomInt(1, 2) == 1 then
            return udg_Nazgrek
        endif
        return udg_Zulkis
    elseif nazgrekOwned then
        return udg_Nazgrek
    elseif zulkisOwned then
        return udg_Zulkis
    endif
    return null
endfunction

private function GetCompanionCommandSpeakerName takes unit speaker returns string
    if speaker == udg_Zulkis then
        return "Zulkis"
    endif
    return "Nazgrek"
endfunction

private function GetCompanionCommandLineKey takes integer commandId, integer mode returns string
    if commandId == COMMAND_INVITE then
        return "Invite"
    elseif commandId == COMMAND_KICK then
        return "Kick"
    elseif commandId == COMMAND_DROP_ITEMS then
        return "DropItems"
    elseif commandId == COMMAND_MODE then
        set mode = NormalizeMode(mode)
        if mode == COMPANION_MODE_PASSIVE then
            return "PassiveMode"
        elseif mode == COMPANION_MODE_HOLD then
            return "HoldMode"
        elseif mode == COMPANION_MODE_AGGRESSIVE then
            return "AggressiveMode"
        endif
        return "NormalMode"
    endif
    return ""
endfunction

private function QueueCompanionCommandLine takes integer commandId, integer mode returns nothing
    local unit speaker = PickCompanionCommandSpeaker()
    local string speakerName
    local string commandKey

    if speaker == null then
        set speaker = null
        return
    endif

    set speakerName = GetCompanionCommandSpeakerName(speaker)
    set commandKey = GetCompanionCommandLineKey(commandId, mode)
    if commandKey != "" and DialogSystem_PickCompanionCommandLine(speaker, speakerName, commandKey) then
        call DialogSystem_QueueFieldLine(speaker, speakerName, DialogSystem_PickedSound, DialogSystem_PickedText)
    endif

    set speaker = null
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

    if udg_CompanionFocusZulkis != null and IsUnitInGroup(u, udg_CompanionFocusZulkis) then
        if IsAliveUnit(udg_Zulkis) then
            return udg_Zulkis
        endif
        return null
    endif
    if udg_CompanionFocusNazgrek != null and IsUnitInGroup(u, udg_CompanionFocusNazgrek) then
        if IsAliveUnit(udg_Nazgrek) then
            return udg_Nazgrek
        endif
        return null
    endif

    return GetPreferredLeader(null)
endfunction

private function SetFocusUnit takes unit u, unit leader returns nothing
    if u == null then
        return
    endif
    if udg_CompanionFocusNazgrek == null then
        set udg_CompanionFocusNazgrek = CreateGroup()
    endif
    if udg_CompanionFocusZulkis == null then
        set udg_CompanionFocusZulkis = CreateGroup()
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

private function IsSummonedElementalType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_AIR_ELEMENTAL or unitTypeId == UNIT_WATER_ELEMENTAL or unitTypeId == UNIT_FIRE_ELEMENTAL or unitTypeId == UNIT_EARTH_ELEMENTAL
endfunction

private function IsSummonedSpiritWolfType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_SPIRIT_WOLF_1 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_2 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_3 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_4 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_5 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_OSW1 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_OSW2 /*
        */ or unitTypeId == UNIT_SPIRIT_WOLF_OSW3
endfunction

private function AddControlledDisplayUnit takes unit controlledUnit returns nothing
    local integer unitId
    if controlledUnit == null or GetUnitTypeId(controlledUnit) == 0 then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(controlledUnit)
    if ControlledDisplayIndex.integer[unitId] > 0 then
        return
    endif
    call GroupAddUnit(ControlledDisplayGroup, controlledUnit)
    if ControlledDisplayCount >= CONTROLLED_DISPLAY_MAX then
        set ControlledDisplayIndex.integer[unitId] = -1
        return
    endif

    set ControlledDisplayCount = ControlledDisplayCount + 1
    set ControlledDisplayUnits[ControlledDisplayCount] = controlledUnit
    set ControlledDisplayIndex.integer[unitId] = ControlledDisplayCount
endfunction

private function RemoveControlledDisplayUnit takes unit controlledUnit returns nothing
    local integer unitId
    local integer index
    local unit moved
    if controlledUnit == null or ControlledDisplayIndex == 0 then
        return
    endif

    set unitId = GetHandleId(controlledUnit)
    set index = ControlledDisplayIndex.integer[unitId]
    if index <= 0 then
        if index < 0 then
            call ControlledDisplayIndex.integer.remove(unitId)
        endif
        if ControlledDisplayGroup != null then
            call GroupRemoveUnit(ControlledDisplayGroup, controlledUnit)
        endif
        return
    endif

    set moved = ControlledDisplayUnits[ControlledDisplayCount]
    set ControlledDisplayUnits[index] = moved
    set ControlledDisplayUnits[ControlledDisplayCount] = null
    set ControlledDisplayCount = ControlledDisplayCount - 1
    if moved != null and moved != controlledUnit then
        set ControlledDisplayIndex.integer[GetHandleId(moved)] = index
    endif
    call ControlledDisplayIndex.integer.remove(unitId)
    if ControlledDisplayGroup != null then
        call GroupRemoveUnit(ControlledDisplayGroup, controlledUnit)
    endif
    set moved = null
endfunction

private function GetUnitTypeIconPath takes integer unitTypeId returns string
    local string iconPath = BlzGetAbilityIcon(unitTypeId)

    if iconPath == null then
        return ""
    endif
    return iconPath
endfunction

private function EnsureGuiCompanionGroups takes nothing returns nothing
    if udg_Companion_Group == null then
        set udg_Companion_Group = CreateGroup()
    endif
    if udg_CompanionFocusNazgrek == null then
        set udg_CompanionFocusNazgrek = CreateGroup()
    endif
    if udg_CompanionFocusZulkis == null then
        set udg_CompanionFocusZulkis = CreateGroup()
    endif
endfunction

private function SyncGuiCompanionEntry takes unit companionUnit, string companionIcon returns nothing
    local integer index
    local integer customValue

    if companionUnit == null then
        return
    endif

    call EnsureGuiCompanionGroups()
    call GroupAddUnit(udg_Companion_Group, companionUnit)

    set index = FindCompanionIndex(companionUnit)
    set customValue = GetUnitUserData(companionUnit)

    if index == 0 then
        set udg_CompanionCount = udg_CompanionCount + 1
        set index = udg_CompanionCount
        set udg_CompanionUnit[index] = companionUnit
    endif

    if index > 0 then
        if customValue > 0 then
            set udg_CompanionIndex[customValue] = index
        endif
        if companionIcon != "" then
            set udg_CompanionIcon[index] = companionIcon
        endif
    endif
    if customValue > 0 then
        set udg_UnitHider_ReferenceUnits[customValue] = companionUnit
    endif
endfunction

private function RepairGuiCompanionState takes nothing returns nothing
    local integer i = 1
    local unit companionUnit
    local integer customValue

    call EnsureGuiCompanionGroups()
    loop
        exitwhen i > udg_CompanionCount
        set companionUnit = udg_CompanionUnit[i]
        if companionUnit != null and GetUnitTypeId(companionUnit) != 0 then
            call GroupAddUnit(udg_Companion_Group, companionUnit)
            set customValue = GetUnitUserData(companionUnit)
            if customValue > 0 then
                set udg_CompanionIndex[customValue] = i
                set udg_UnitHider_ReferenceUnits[customValue] = companionUnit
            endif
            if not IsUnitInGroup(companionUnit, udg_CompanionFocusNazgrek) and not IsUnitInGroup(companionUnit, udg_CompanionFocusZulkis) then
                call SetFocusUnit(companionUnit, GetFocusedLeader(companionUnit))
            endif
        endif
        set i = i + 1
    endloop

    set companionUnit = null
endfunction

private function IsLeaderIdleForRandomMovement takes unit leader returns boolean
    local integer customValue

    if leader == null or GetUnitTypeId(leader) == 0 then
        return false
    endif

    set customValue = GetUnitUserData(leader)
    if customValue > 0 then
        return not udg_UnitMoving[customValue] and not udg_GCSM_UnitInCombat[customValue] and not udg_UnitIsCasting[customValue]
    endif
    return GetUnitCurrentOrder(leader) == 0
endfunction

private function ScheduleNextRandomMove takes unit controlledUnit, unit leader returns nothing
    local integer unitId

    if controlledUnit == null or CompanionNextRandomMove == 0 then
        return
    endif

    set unitId = GetHandleId(controlledUnit)
    if IsLeaderIdleForRandomMovement(leader) then
        set CompanionNextRandomMove.real[unitId] = GetNow() + GetRandomReal(COMPANION_IDLE_LEADER_RANDOM_MOVE_MIN_DELAY, COMPANION_IDLE_LEADER_RANDOM_MOVE_MAX_DELAY)
    else
        set CompanionNextRandomMove.real[unitId] = GetNow() + GetRandomReal(COMPANION_RANDOM_MOVE_MIN_DELAY, COMPANION_RANDOM_MOVE_MAX_DELAY)
    endif
endfunction

private function IsRandomMoveReady takes unit controlledUnit, unit leader returns boolean
    local integer unitId

    if controlledUnit == null or CompanionNextRandomMove == 0 then
        return false
    endif

    set unitId = GetHandleId(controlledUnit)
    if CompanionNextRandomMove.real[unitId] <= 0.00 then
        call ScheduleNextRandomMove(controlledUnit, leader)
        return false
    endif
    return GetNow() >= CompanionNextRandomMove.real[unitId]
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

    if registered or IsPetControlUnit(controlledUnit) then
        call RemoveControlledDisplayUnit(controlledUnit)
    else
        call AddControlledDisplayUnit(controlledUnit)
    endif
    call RemoveWanderAbility(controlledUnit)
    call SetFocusUnit(controlledUnit, leader)
    if not CompanionOrderProfile.has(unitId) then
        set CompanionOrderProfile[unitId] = COMPANION_PROFILE_NORMAL
    endif
    call ScheduleNextRandomMove(controlledUnit, leader)
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

private function GetDistanceBetweenUnits takes unit a, unit b returns real
    local real dx = GetUnitX(a) - GetUnitX(b)
    local real dy = GetUnitY(a) - GetUnitY(b)
    return SquareRoot(dx * dx + dy * dy)
endfunction

private function CreateCompanionIndicatorEffect takes string effectPath, unit controlledUnit, string attachPoint returns effect
    local effect sfx

    if effectPath == "" or controlledUnit == null then
        return null
    endif

    set sfx = AddSpecialEffectTarget(effectPath, controlledUnit, attachPoint)
    if sfx != null then
        call SpeciFX_MarkAsExcluded(sfx)
    endif
    return sfx
endfunction

private function DestroyCompanionStoppedEffect takes unit controlledUnit returns nothing
    local integer unitId
    local effect sfx

    if controlledUnit == null or CompanionStoppedEffect == 0 then
        return
    endif

    set unitId = GetHandleId(controlledUnit)
    set sfx = CompanionStoppedEffect.effect[unitId]
    if sfx != null then
        call DestroyEffect(sfx)
        call CompanionStoppedEffect.remove(unitId)
    endif
    set sfx = null
endfunction

private function HideCompanionFollowingEffect takes unit controlledUnit returns nothing
    local integer unitId
    local effect sfx

    if controlledUnit == null or CompanionFollowingEffect == 0 then
        return
    endif

    set unitId = GetHandleId(controlledUnit)
    set sfx = CompanionFollowingEffect.effect[unitId]
    if sfx != null then
        call BlzSetSpecialEffectAlpha(sfx, COMPANION_EFFECT_FOLLOWING_HIDDEN_ALPHA)
        call BlzSetSpecialEffectScale(sfx, COMPANION_EFFECT_FOLLOWING_HIDDEN_SCALE)
    endif
    set sfx = null
endfunction

private function ShowCompanionFollowingEffect takes unit controlledUnit returns nothing
    local integer unitId
    local effect sfx

    if not COMPANION_ENABLE_FOLLOWER_EFFECTS or controlledUnit == null then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(controlledUnit)
    set sfx = CompanionFollowingEffect.effect[unitId]
    if sfx == null then
        set sfx = CreateCompanionIndicatorEffect(COMPANION_EFFECT_FOLLOWING_PATH, controlledUnit, COMPANION_EFFECT_FOLLOWING_ATTACH)
        set CompanionFollowingEffect.effect[unitId] = sfx
    endif
    if sfx != null then
        call BlzSetSpecialEffectScale(sfx, COMPANION_EFFECT_FOLLOWING_VISIBLE_SCALE)
        call BlzSetSpecialEffectAlpha(sfx, COMPANION_EFFECT_FOLLOWING_VISIBLE_ALPHA)
    endif
    set sfx = null
endfunction

private function DestroyCompanionFollowerEffects takes unit controlledUnit returns nothing
    local integer unitId
    local effect sfx

    if controlledUnit == null or CompanionFollowingEffect == 0 then
        return
    endif

    call DestroyCompanionStoppedEffect(controlledUnit)
    set unitId = GetHandleId(controlledUnit)
    set sfx = CompanionFollowingEffect.effect[unitId]
    if sfx != null then
        call HideCompanionFollowingEffect(controlledUnit)
        call DestroyEffect(sfx)
        call CompanionFollowingEffect.remove(unitId)
    endif
    set sfx = null
endfunction

private function SetCompanionFollowerEffectState takes unit controlledUnit, boolean stopped returns nothing
    local integer unitId
    local effect sfx

    if not COMPANION_ENABLE_FOLLOWER_EFFECTS or controlledUnit == null then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(controlledUnit)
    if stopped then
        call HideCompanionFollowingEffect(controlledUnit)
        set sfx = CompanionStoppedEffect.effect[unitId]
        if sfx == null then
            set sfx = CreateCompanionIndicatorEffect(COMPANION_EFFECT_STOPPED_PATH, controlledUnit, COMPANION_EFFECT_STOPPED_ATTACH)
            set CompanionStoppedEffect.effect[unitId] = sfx
        endif
    else
        call DestroyCompanionStoppedEffect(controlledUnit)
        call ShowCompanionFollowingEffect(controlledUnit)
    endif
    set sfx = null
endfunction

private function ClearCompanionFarIcon takes unit controlledUnit returns nothing
    local integer unitId
    local integer iconSlot

    if controlledUnit == null or CompanionMapIconSlot == 0 then
        return
    endif

    set unitId = GetHandleId(controlledUnit)
    set iconSlot = CompanionMapIconSlot[unitId] - 1
    if iconSlot >= 0 and CompanionMapIcons[iconSlot] != null then
        call IconQuery_UnregisterIcon(CompanionMapIcons[iconSlot])
        set CompanionMapIcons[iconSlot] = null
    endif
    call CompanionMapIconSlot.remove(unitId)
    call CompanionPingCycle.remove(unitId)
endfunction

private function EnsureCompanionFarIcon takes unit controlledUnit returns nothing
    local integer unitId
    local minimapicon mapIcon

    if controlledUnit == null then
        return
    endif

    call EnsureState()
    set unitId = GetHandleId(controlledUnit)
    if CompanionMapIconSlot[unitId] > 0 then
        return
    endif

    set mapIcon = IconQuery_RegisterCompanionFollowerUnitIcon(controlledUnit)
    if mapIcon != null then
        set CompanionMapIcons[CompanionMapIconCount] = mapIcon
        set CompanionMapIconSlot[unitId] = CompanionMapIconCount + 1
        set CompanionMapIconCount = CompanionMapIconCount + 1
    endif
    set mapIcon = null
endfunction

private function PingCompanionIfReady takes unit controlledUnit returns nothing
    local integer unitId = GetHandleId(controlledUnit)
    local integer cycles = CompanionPingCycle[unitId] + 1
    local location pingLoc

    if cycles >= COMPANION_PING_TICKS then
        set pingLoc = Location(GetUnitX(controlledUnit), GetUnitY(controlledUnit))
        call PingMinimapLocForForceEx(GetPlayersAll(), pingLoc, 1.00, COMPANION_PING_STYLE, COMPANION_PING_RED, COMPANION_PING_GREEN, COMPANION_PING_BLUE)
        call RemoveLocation(pingLoc)
        set pingLoc = null
        set cycles = 0
    endif
    set CompanionPingCycle[unitId] = cycles
endfunction

private function UpdateCompanionFarIcon takes unit controlledUnit, unit leader, real distance, integer mode returns nothing
    local boolean isFar = distance > GetModeDistance(mode)

    if isFar or IconQuery_GetCategoryMode(ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS) == ICONQUERY_CATEGORY_MODE_ALWAYS then
        call EnsureCompanionFarIcon(controlledUnit)
    else
        call ClearCompanionFarIcon(controlledUnit)
    endif

    if isFar then
        call PingCompanionIfReady(controlledUnit)
    else
        call CompanionPingCycle.remove(GetHandleId(controlledUnit))
    endif
endfunction

private function IsUnitCastingByCustomValue takes integer customValue returns boolean
    return customValue > 0 and udg_UnitIsCasting[customValue]
endfunction

private function IsUnitMovingByCustomValue takes integer customValue returns boolean
    return customValue > 0 and udg_UnitMoving[customValue]
endfunction

private function IsUnitInCombatByCustomValue takes integer customValue returns boolean
    return customValue > 0 and udg_GCSM_UnitInCombat[customValue]
endfunction

private function IsUnitIdleByCustomValue takes integer customValue returns boolean
    return customValue > 0 and udg_CompanionUnitIdle[customValue]
endfunction

private function IsAliveByCustomValue takes unit controlledUnit, integer customValue returns boolean
    if customValue <= 0 then
        return IsAliveUnit(controlledUnit)
    endif
    return IsAliveUnit(controlledUnit) and udg_IsUnitAlive[customValue]
endfunction

private function IsFatiguedActivePet takes unit controlledUnit returns boolean
    return controlledUnit != null and controlledUnit == udg_TamedUnit and udg_Pet_Dead and udg_TamedUnits != null and IsUnitInGroup(controlledUnit, udg_TamedUnits)
endfunction

private function ClearOrderIdleState takes unit controlledUnit, integer customValue returns nothing
    call RemoveWanderAbility(controlledUnit)
    if customValue > 0 then
        set udg_CompanionUnitIdle[customValue] = false
    endif
endfunction

private function IssueRandomAttackMoveNearLeader takes unit controlledUnit, unit leader, real minOffset, real maxOffset returns nothing
    local real angle = GetRandomReal(0.00, 6.2831853)
    local real offset = GetRandomReal(minOffset, maxOffset)

    call IssuePointOrder(controlledUnit, "attack", GetUnitX(leader) + offset * Cos(angle), GetUnitY(leader) + offset * Sin(angle))
endfunction

private function IssueCompanionPassiveOrder takes unit controlledUnit, unit leader, real distance, integer currentOrder returns nothing
    if distance > 150.00 or currentOrder != OrderId("move") then
        call IssueTargetOrder(controlledUnit, "move", leader)
    endif
endfunction

private function IssueCompanionNormalOrder takes unit controlledUnit, unit leader, real distance, integer customValue, integer currentOrder returns nothing
    if not IsUnitInCombatByCustomValue(customValue) and not IsUnitMovingByCustomValue(customValue) and not IsUnitIdleByCustomValue(customValue) and not udg_CompanionDialogueActive and IsRandomMoveReady(controlledUnit, leader) then
        call ClearOrderIdleState(controlledUnit, customValue)
        call IssueRandomAttackMoveNearLeader(controlledUnit, leader, COMPANION_NORMAL_MIN_OFFSET, COMPANION_NORMAL_MAX_OFFSET)
        call ScheduleNextRandomMove(controlledUnit, leader)
    elseif currentOrder == OrderId("attack") and not IsUnitInCombatByCustomValue(GetUnitUserData(leader)) and distance >= COMPANION_POST_COMBAT_RETURN_DISTANCE then
        call ClearOrderIdleState(controlledUnit, customValue)
        call IssueTargetOrder(controlledUnit, "smart", leader)
    elseif distance >= COMPANION_NORMAL_CATCHUP_DISTANCE or IsUnitInCombatByCustomValue(GetUnitUserData(leader)) then
        if currentOrder != OrderId("smart") or distance > GetModeDistance(COMPANION_MODE_DEFEND) then
            call ClearOrderIdleState(controlledUnit, customValue)
            call IssueTargetOrder(controlledUnit, "smart", leader)
        endif
    endif
endfunction

private function IssueCompanionAggressiveOrder takes unit controlledUnit, unit leader, real distance, integer customValue, integer currentOrder returns nothing
    if not IsUnitInCombatByCustomValue(customValue) and currentOrder != OrderId("attack") and IsRandomMoveReady(controlledUnit, leader) then
        call ClearOrderIdleState(controlledUnit, customValue)
        call IssueRandomAttackMoveNearLeader(controlledUnit, leader, COMPANION_AGGRESSIVE_MIN_OFFSET, COMPANION_AGGRESSIVE_MAX_OFFSET)
        call ScheduleNextRandomMove(controlledUnit, leader)
    elseif distance >= COMPANION_AGGRESSIVE_CATCHUP_DISTANCE or IsUnitInCombatByCustomValue(GetUnitUserData(leader)) then
        if currentOrder != OrderId("smart") or distance > GetModeDistance(COMPANION_MODE_AGGRESSIVE) then
            call ClearOrderIdleState(controlledUnit, customValue)
            call IssueTargetOrder(controlledUnit, "smart", leader)
        endif
    endif
endfunction

private function UpdateCompanionOrderUnit takes unit controlledUnit returns nothing
    local integer unitId
    local integer mode
    local integer customValue
    local integer currentOrder
    local unit leader
    local real distance

    if controlledUnit == null or GetUnitTypeId(controlledUnit) == 0 or CompanionTracked == 0 then
        return
    endif

    call TrackExistingControlUnit(controlledUnit)
    set unitId = GetHandleId(controlledUnit)
    if CompanionTracked[unitId] == 0 then
        return
    endif
    if CompanionOrderProfile[unitId] == COMPANION_PROFILE_ESCORT then
        return
    endif
    call FollowSystem_RemoveUnit(controlledUnit)
    if CompanionSuspended[unitId] == 1 then
        if IsFatiguedActivePet(controlledUnit) then
            call EnsureCompanionFarIcon(controlledUnit)
        else
            call ClearCompanionFarIcon(controlledUnit)
        endif
        call DestroyCompanionFollowerEffects(controlledUnit)
        return
    endif

    set mode = NormalizeMode(CompanionMode[unitId])
    set CompanionMode[unitId] = mode
    set leader = CompanionLeader.unit[unitId]
    if leader == null then
        set leader = GetFocusedLeader(controlledUnit)
        if IsAliveUnit(leader) then
            set CompanionLeader.unit[unitId] = leader
        endif
    endif
    set customValue = GetUnitUserData(controlledUnit)
    if not IsAliveByCustomValue(controlledUnit, customValue) or not IsAliveUnit(leader) or leader == controlledUnit then
        call ClearCompanionFarIcon(controlledUnit)
        call DestroyCompanionFollowerEffects(controlledUnit)
        set leader = null
        return
    endif

    set distance = GetDistanceBetweenUnits(controlledUnit, leader)
    call UpdateCompanionFarIcon(controlledUnit, leader, distance, mode)

    if mode == COMPANION_MODE_HOLD then
        if CompanionOrderProfile[unitId] == COMPANION_PROFILE_FOLLOWER then
            call SetCompanionFollowerEffectState(controlledUnit, true)
        else
            call DestroyCompanionFollowerEffects(controlledUnit)
        endif
        set leader = null
        return
    endif

    if CompanionOrderProfile[unitId] == COMPANION_PROFILE_FOLLOWER then
        if distance > GetModeDistance(mode) then
            call ClearOrderIdleState(controlledUnit, customValue)
            call IssueImmediateOrder(controlledUnit, "stop")
            call SetCompanionFollowerEffectState(controlledUnit, true)
            set leader = null
            return
        endif
        call SetCompanionFollowerEffectState(controlledUnit, false)
    else
        call DestroyCompanionFollowerEffects(controlledUnit)
    endif

    if IsUnitCastingByCustomValue(customValue) then
        set leader = null
        return
    endif

    set currentOrder = GetUnitCurrentOrder(controlledUnit)
    if mode == COMPANION_MODE_PASSIVE then
        call ClearOrderIdleState(controlledUnit, customValue)
        call IssueCompanionPassiveOrder(controlledUnit, leader, distance, currentOrder)
    elseif mode == COMPANION_MODE_AGGRESSIVE then
        call IssueCompanionAggressiveOrder(controlledUnit, leader, distance, customValue, currentOrder)
    else
        call IssueCompanionNormalOrder(controlledUnit, leader, distance, customValue, currentOrder)
    endif

    set leader = null
endfunction

private function UpdateCompanionOrderEnum takes nothing returns nothing
    call UpdateCompanionOrderUnit(GetEnumUnit())
endfunction

private function IsDialogOrderBlocked takes nothing returns boolean
    return udg_InCinematic or udg_CompanionDialogueActive or DialogSystem_IsSequenceActive() or DialogSystem_IsDialogVisible() or DialogSystem_IsFieldLineQueueActive()
endfunction

private function OnOrderPeriodic takes nothing returns nothing
    if IsDialogOrderBlocked() then
        return
    endif

    call RepairGuiCompanionState()
    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function UpdateCompanionOrderEnum)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function UpdateCompanionOrderEnum)
    endif
    if ControlledDisplayGroup != null then
        call ForGroup(ControlledDisplayGroup, function UpdateCompanionOrderEnum)
    endif
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
        if IsFatiguedActivePet(companionUnit) then
            call EnsureCompanionFarIcon(companionUnit)
        else
            call ClearCompanionFarIcon(companionUnit)
        endif
        call DestroyCompanionFollowerEffects(companionUnit)
        call IssueImmediateOrder(companionUnit, "stop")
        return
    endif

    set mode = NormalizeMode(CompanionMode[unitId])
    set CompanionMode[unitId] = mode
    set leader = CompanionLeader.unit[unitId]
    if leader == null then
        set leader = GetFocusedLeader(companionUnit)
        if IsAliveUnit(leader) then
            set CompanionLeader.unit[unitId] = leader
        endif
    endif

    if mode == COMPANION_MODE_HOLD then
        call FollowSystem_RemoveUnit(companionUnit)
        if IsAliveUnit(companionUnit) and IsAliveUnit(leader) and leader != companionUnit then
            call UpdateCompanionFarIcon(companionUnit, leader, GetDistanceBetweenUnits(companionUnit, leader), mode)
        else
            call ClearCompanionFarIcon(companionUnit)
        endif
        if CompanionOrderProfile[unitId] == COMPANION_PROFILE_FOLLOWER then
            call SetCompanionFollowerEffectState(companionUnit, true)
        else
            call DestroyCompanionFollowerEffects(companionUnit)
        endif
        call IssueImmediateOrder(companionUnit, "holdposition")
    elseif IsAliveUnit(companionUnit) and IsAliveUnit(leader) and leader != companionUnit then
        if CompanionOrderProfile[unitId] == COMPANION_PROFILE_ESCORT then
            call ClearCompanionFarIcon(companionUnit)
            call DestroyCompanionFollowerEffects(companionUnit)
            call FollowSystem_SetFollow(companionUnit, leader, GetModeDistance(mode), false, 0.00, GetModeFollowStyle(mode), true, true)
        else
            call FollowSystem_RemoveUnit(companionUnit)
            call UpdateCompanionOrderUnit(companionUnit)
        endif
    else
        call FollowSystem_RemoveUnit(companionUnit)
        call ClearCompanionFarIcon(companionUnit)
        call DestroyCompanionFollowerEffects(companionUnit)
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
    if companionIcon == "" then
        set companionIcon = GetUnitTypeIconPath(GetUnitTypeId(companionUnit))
    endif

    if CompanionRegistered[unitId] == 0 then
        call QuestGiver_AddCompanion(companionUnit, companionIcon)
    endif

    call RegisterControlledInternal(companionUnit, leader, mode, true, companionIcon)
    call SyncGuiCompanionEntry(companionUnit, companionIcon)
    call ApplyOrders(companionUnit)
    set leader = GetFocusedLeader(companionUnit)
    if IsAliveUnit(leader) and NormalizeMode(mode) != COMPANION_MODE_HOLD and not IsUnitCastingByCustomValue(GetUnitUserData(companionUnit)) then
        call ClearOrderIdleState(companionUnit, GetUnitUserData(companionUnit))
        if NormalizeMode(mode) == COMPANION_MODE_PASSIVE then
            call IssueTargetOrder(companionUnit, "move", leader)
        else
            call IssueTargetOrder(companionUnit, "smart", leader)
        endif
    endif
    if IconQuery_GetCategoryMode(ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS) == ICONQUERY_CATEGORY_MODE_ALWAYS then
        call EnsureCompanionFarIcon(companionUnit)
    endif
    call DebugMsg("Add " + GetUnitName(companionUnit))
endfunction

private function RemoveInternal takes unit companionUnit returns nothing
    local integer unitId

    if companionUnit == null or CompanionTracked == 0 then
        return
    endif

    set unitId = GetHandleId(companionUnit)
    call RemoveControlledDisplayUnit(companionUnit)
    call FollowSystem_RemoveUnit(companionUnit)
    call ClearCompanionFarIcon(companionUnit)
    call DestroyCompanionFollowerEffects(companionUnit)

    if CompanionRegistered[unitId] == 1 or FindCompanionIndex(companionUnit) > 0 then
        call QuestGiver_RemoveCompanion(companionUnit)
    endif
    if udg_Companion_Group != null then
        call GroupRemoveUnit(udg_Companion_Group, companionUnit)
    endif
    if udg_CompanionFocusNazgrek != null then
        call GroupRemoveUnit(udg_CompanionFocusNazgrek, companionUnit)
    endif
    if udg_CompanionFocusZulkis != null then
        call GroupRemoveUnit(udg_CompanionFocusZulkis, companionUnit)
    endif

    call CompanionLeader.remove(unitId)
    call CompanionMode.remove(unitId)
    call CompanionSuspended.remove(unitId)
    call CompanionIcon.remove(unitId)
    call CompanionRegistered.remove(unitId)
    call CompanionTracked.remove(unitId)
    call CompanionOrderProfile.remove(unitId)
    call CompanionNextRandomMove.remove(unitId)
    call CompanionStoppedEffect.remove(unitId)
    call CompanionFollowingEffect.remove(unitId)
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

private function SetEscortBehaviorInternal takes unit controlledUnit, boolean enabled returns nothing
    local integer unitId

    if controlledUnit == null or GetUnitTypeId(controlledUnit) == 0 then
        return
    endif

    call EnsureState()
    call TrackExistingControlUnit(controlledUnit)
    set unitId = GetHandleId(controlledUnit)
    if CompanionTracked[unitId] == 0 then
        return
    endif

    if enabled then
        set CompanionOrderProfile[unitId] = COMPANION_PROFILE_ESCORT
        call ClearCompanionFarIcon(controlledUnit)
        call DestroyCompanionFollowerEffects(controlledUnit)
    else
        set CompanionOrderProfile[unitId] = COMPANION_PROFILE_NORMAL
        call FollowSystem_RemoveUnit(controlledUnit)
        call DestroyCompanionFollowerEffects(controlledUnit)
    endif
    call ApplyOrders(controlledUnit)
endfunction

private function SetFollowerBehaviorInternal takes unit controlledUnit, boolean enabled returns nothing
    local integer unitId

    if controlledUnit == null or GetUnitTypeId(controlledUnit) == 0 then
        return
    endif

    call EnsureState()
    call TrackExistingControlUnit(controlledUnit)
    set unitId = GetHandleId(controlledUnit)
    if CompanionTracked[unitId] == 0 then
        return
    endif

    call FollowSystem_RemoveUnit(controlledUnit)
    if enabled then
        set CompanionOrderProfile[unitId] = COMPANION_PROFILE_FOLLOWER
    elseif CompanionOrderProfile[unitId] == COMPANION_PROFILE_FOLLOWER then
        set CompanionOrderProfile[unitId] = COMPANION_PROFILE_NORMAL
        call DestroyCompanionFollowerEffects(controlledUnit)
    endif
    call ApplyOrders(controlledUnit)
endfunction

private function SetSuspendedInternal takes unit companionUnit, boolean suspended returns nothing
    local integer unitId

    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 or CompanionTracked == 0 then
        return
    endif

    set unitId = GetHandleId(companionUnit)
    if CompanionTracked[unitId] == 0 then
        return
    endif

    if suspended then
        set CompanionSuspended[unitId] = 1
    else
        set CompanionSuspended[unitId] = 0
    endif
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
    if IsDialogOrderBlocked() then
        return
    endif

    call RepairGuiCompanionState()
    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function UpdateCompanionIdleEnum)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function UpdatePetIdleEnum)
    endif
    if ControlledDisplayGroup != null then
        call ForGroup(ControlledDisplayGroup, function UpdateCompanionIdleEnum)
    endif
endfunction

private function IsNamedCompanionType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_ROGUE or unitTypeId == UNIT_UNDEAD_WARLOCK or unitTypeId == UNIT_ORC_WARLOCK or unitTypeId == UNIT_SHAMAN or unitTypeId == UNIT_WARRIOR or unitTypeId == UNIT_AVELINE or unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER or unitTypeId == UNIT_PALADIN or unitTypeId == UNIT_ARADION or unitTypeId == UNIT_VALERIA
endfunction

private function GetNamedCompanionIcon takes integer unitTypeId returns string
    if unitTypeId == UNIT_ROGUE then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroBlademaster.blp"
    elseif unitTypeId == UNIT_UNDEAD_WARLOCK or unitTypeId == UNIT_ORC_WARLOCK then
        return "ReplaceableTextures\\CommandButtons\\BTNChaosWarlockGreen.blp"
    elseif unitTypeId == UNIT_SHAMAN then
        return "ReplaceableTextures\\CommandButtons\\BTNShaman.blp"
    elseif unitTypeId == UNIT_WARRIOR then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroTaurenChieftain.blp"
    elseif unitTypeId == UNIT_AVELINE then
        return "ReplaceableTextures\\CommandButtons\\BTNFootman.blp"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroTinker.blp"
    elseif unitTypeId == UNIT_PALADIN then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroPaladin.blp"
    elseif unitTypeId == UNIT_ARADION then
        return "ReplaceableTextures\\CommandButtons\\BTNHeroBloodElfPrince.blp"
    elseif unitTypeId == UNIT_VALERIA then
        return "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp"
    endif
    return ""
endfunction

private function GetReturnOwner takes integer unitTypeId returns player
    if unitTypeId == UNIT_ROGUE or unitTypeId == UNIT_UNDEAD_WARLOCK or unitTypeId == UNIT_ORC_WARLOCK or unitTypeId == UNIT_SHAMAN or unitTypeId == UNIT_WARRIOR then
        return Player(5)
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return Player(6)
    elseif unitTypeId == UNIT_PALADIN or unitTypeId == UNIT_AVELINE then
        return Player(14)
    elseif unitTypeId == UNIT_ARADION or unitTypeId == UNIT_VALERIA then
        return Player(ELARINDOR_OWNER_INDEX)
    endif
    return null
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

private function GetCompanionCandidateLevel takes unit target returns integer
    if target == null then
        return 0
    endif
    if IsUnitType(target, UNIT_TYPE_HERO) then
        return GetHeroLevel(target)
    endif
    return GetUnitLevel(target)
endfunction

private function GetCompanionLimitForLevel takes integer heroLevel returns integer
    if heroLevel >= 25 then
        return 6
    elseif heroLevel >= 20 then
        return 5
    elseif heroLevel >= 15 then
        return 4
    elseif heroLevel >= 10 then
        return 3
    elseif heroLevel >= 5 then
        return 2
    endif
    return 1
endfunction

private function GetCompanionLimitInternal takes nothing returns integer
    if udg_Companion_GroupSize > 0 then
        return udg_Companion_GroupSize
    endif
    return GetCompanionLimitForLevel(GetMaxPartyHeroLevel())
endfunction

private function GetCompanionLimitInfoTextInternal takes nothing returns string
    return "|cffffcc00Companion Party Size|r\n" + "|cffbfbfbfActive companions:|r |cffffffff" + I2S(udg_CompanionCount) + " / " + I2S(GetCompanionLimitInternal()) + "|r\n" + "|cffbfbfbfSize is based on the highest level hero in the party.|r\n" + "|cffbfbfbfLevel brackets:|r 1-4 = 1, 5-9 = 2, 10-14 = 3, 15-19 = 4, 20-24 = 5, 25+ = 6\n" + "|cff808080Map override: Companion_GroupSize can replace the level-based size.|r"
endfunction

private function IsCompanionPartyFull takes nothing returns boolean
    return udg_CompanionCount >= GetCompanionLimitInternal()
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

private function GetUnitFactionForHostility takes unit target returns Faction
    local Faction f
    local integer unitTypeId

    if target == null then
        return 0
    endif

    set f = Faction.getByUnit(target)
    if f != 0 then
        return f
    endif

    set unitTypeId = GetUnitTypeId(target)
    if target == udg_Aradion or target == udg_Valeria or unitTypeId == UNIT_ARADION or unitTypeId == UNIT_VALERIA then
        return Faction.getFaction("Elarindor")
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return Faction.getFaction("Goblins")
    elseif unitTypeId == UNIT_PALADIN or unitTypeId == UNIT_AVELINE then
        return Faction.getFaction("Riverbane")
    elseif IsNamedCompanionType(unitTypeId) or unitTypeId == UNIT_GRUNT_1 or unitTypeId == UNIT_GRUNT_5 or unitTypeId == UNIT_GRUNT_10 or unitTypeId == UNIT_GRUNT_15 or unitTypeId == UNIT_GRUNT_20 or unitTypeId == UNIT_GRUNT_25 or unitTypeId == UNIT_MARAUDER_1 or unitTypeId == UNIT_MARAUDER_5 or unitTypeId == UNIT_STONEGUARD_5 or unitTypeId == UNIT_RAIDER or unitTypeId == UNIT_HEADHUNTER or unitTypeId == UNIT_WITCH_DOCTOR or unitTypeId == UNIT_HIRED_SHAMAN then
        return Faction.getFaction("Horde")
    endif

    return 0
endfunction

private function IsHostilitySource takes unit source returns boolean
    if source == null then
        return false
    endif
    if GetOwningPlayer(source) == Player(CONTROL_PLAYER_INDEX) then
        return true
    endif
    if udg_Companion_Group != null and IsUnitInGroup(source, udg_Companion_Group) then
        return true
    endif
    if udg_TamedUnits != null and IsUnitInGroup(source, udg_TamedUnits) then
        return true
    endif
    if ControlledDisplayGroup != null and IsUnitInGroup(source, ControlledDisplayGroup) then
        return true
    endif
    return false
endfunction

private function DropCompanionForFactionHostility takes unit companionUnit returns nothing
    local player returnOwner

    if companionUnit == null or udg_Companion_Group == null or not IsUnitInGroup(companionUnit, udg_Companion_Group) then
        return
    endif

    set udg_CompanionUnitKicked = companionUnit
    call FireCommandEvent(companionUnit, null, COMMAND_KICK, 0)
    set returnOwner = GetReturnOwner(GetUnitTypeId(companionUnit))
    call RemoveInternal(companionUnit)
    call RemoveWanderAbility(companionUnit)

    if returnOwner != null then
        call SetUnitOwner(companionUnit, returnOwner, true)
    else
        call RejectTemporaryCompanion(companionUnit, "")
    endif

    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(companionUnit) + " has left the party.")
    set returnOwner = null
endfunction

private function CollectHostilityDropCompanion takes nothing returns nothing
    local unit companionUnit = GetEnumUnit()
    local Faction f = GetUnitFactionForHostility(companionUnit)

    if f != 0 and f.id == HostilityDropFactionId and IsAliveUnit(companionUnit) then
        call GroupAddUnit(HostilityDropGroup, companionUnit)
        set HostilityDropSeen = HostilityDropSeen + 1
        if HostilityDropBarkUnit == null or GetRandomInt(1, HostilityDropSeen) == 1 then
            set HostilityDropBarkUnit = companionUnit
        endif
    endif

    set companionUnit = null
endfunction

private function DropOtherHostilityDropCompanion takes nothing returns nothing
    local unit companionUnit = GetEnumUnit()

    if companionUnit != HostilityDropBarkUnit then
        call DropCompanionForFactionHostility(companionUnit)
    endif

    set companionUnit = null
endfunction

private function DropCompanionsForHostileFaction takes Faction targetFaction returns nothing
    if targetFaction == 0 or udg_Companion_Group == null then
        return
    endif

    call EnsureState()
    call GroupClear(HostilityDropGroup)
    set HostilityDropFactionId = targetFaction.id
    set HostilityDropBarkUnit = null
    set HostilityDropSeen = 0

    call ForGroup(udg_Companion_Group, function CollectHostilityDropCompanion)
    if HostilityDropBarkUnit != null then
        call DropCompanionForFactionHostility(HostilityDropBarkUnit)
        call ForGroup(HostilityDropGroup, function DropOtherHostilityDropCompanion)
    endif

    call GroupClear(HostilityDropGroup)
    set HostilityDropFactionId = 0
    set HostilityDropBarkUnit = null
    set HostilityDropSeen = 0
endfunction

private function HandleHostilityAgainstFactionUnit takes unit source, unit target returns nothing
    local Faction targetFaction

    if not IsHostilitySource(source) then
        return
    endif

    set targetFaction = GetUnitFactionForHostility(target)
    if targetFaction != 0 then
        call DropCompanionsForHostileFaction(targetFaction)
    endif
endfunction

private function GetCommandPlayer takes unit caster returns player
    if caster == null then
        return Player(CONTROL_PLAYER_INDEX)
    endif
    if GetOwningPlayer(caster) == Player(COMPANION_OWNER_INDEX) then
        return Player(CONTROL_PLAYER_INDEX)
    endif
    return GetOwningPlayer(caster)
endfunction

private function FindSelectedCommandTarget takes nothing returns nothing
    local unit u = GetEnumUnit()

    if IsValidControlTarget(u) and IsUnitSelected(u, CommandSelectionPlayer) then
        set CommandSelectionCount = CommandSelectionCount + 1
        if CommandSelectionTarget == null then
            set CommandSelectionTarget = u
        endif
    endif

    set u = null
endfunction

private function GetSelectedCommandTarget takes player commandPlayer returns unit
    local unit selectedTarget

    call EnsureState()
    call RepairGuiCompanionState()
    set CommandSelectionPlayer = commandPlayer
    set CommandSelectionTarget = null
    set CommandSelectionCount = 0

    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function FindSelectedCommandTarget)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function FindSelectedCommandTarget)
    endif
    if ControlledDisplayGroup != null then
        call ForGroup(ControlledDisplayGroup, function FindSelectedCommandTarget)
    endif

    if CommandSelectionCount == 1 then
        set selectedTarget = CommandSelectionTarget
    else
        set selectedTarget = null
    endif

    set CommandSelectionTarget = null
    set CommandSelectionPlayer = null
    set CommandSelectionCount = 0
    return selectedTarget
endfunction

private function ResolveCommandTarget takes unit caster, unit target, player commandPlayer returns unit
    call RepairGuiCompanionState()
    if target != null then
        return target
    endif
    if IsValidControlTarget(caster) then
        return caster
    endif
    return GetSelectedCommandTarget(commandPlayer)
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
    call FireCommandEvent(u, ModeCommandCaster, COMMAND_MODE, ModeActionMode)
    set u = null
endfunction

private function ApplyModeToSingleTarget takes unit target, integer mode returns nothing
    if not IsValidControlTarget(target) then
        set target = null
        return
    endif

    set mode = NormalizeMode(mode)
    call TrackExistingControlUnit(target)
    call SetModeInternal(target, mode)
    call QueueCompanionCommandLine(COMMAND_MODE, mode)
    call FireCommandEvent(target, ModeCommandCaster, COMMAND_MODE, mode)
    call PlayCommandSound(gg_snd_GoodJob)
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + ": " + GetModeName(mode) + " Mode")
    set target = null
endfunction

private function ApplyModeToAllTargets takes integer mode returns nothing
    local integer count

    call EnsureState()
    call RepairGuiCompanionState()
    set mode = NormalizeMode(mode)
    call GroupClear(ModeTargetGroup)
    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function AddAllModeTarget)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function AddAllModeTarget)
    endif
    if ControlledDisplayGroup != null then
        call ForGroup(ControlledDisplayGroup, function AddAllModeTarget)
    endif
    set CurrentGroupMode = mode

    set ModeActionMode = mode
    set count = CountUnitsInGroup(ModeTargetGroup)
    if count > 0 then
        call QueueCompanionCommandLine(COMMAND_MODE, mode)
    endif
    call ForGroup(ModeTargetGroup, function ApplyModeTarget)

    if count > 0 then
        call PlayCommandSound(gg_snd_GoodJob)
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Companions: " + GetModeName(mode) + " Mode")
    endif

    call GroupClear(ModeTargetGroup)
    set ModeCommandCaster = null
endfunction

private function ApplyModeFromCommand takes unit caster, unit target, integer mode returns nothing
    call RepairGuiCompanionState()
    if IsValidControlTarget(caster) then
        set ModeCommandCaster = caster
    else
        set ModeCommandCaster = null
    endif
    if target != null then
        call ApplyModeToSingleTarget(target, mode)
    else
        call ApplyModeToAllTargets(mode)
    endif
    set ModeCommandCaster = null
    set target = null
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

private function IsQuestOpenForCompanionInvite takes string questName returns boolean
    if udg_Aradion == null then
        return false
    endif
    return QuestGiver_IsQuestDiscoveredByNameAndGiver(questName, udg_Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(questName, udg_Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(questName, udg_Aradion)
endfunction

private function IsQuestCompanionReputationBypass takes unit target returns boolean
    local integer unitTypeId

    if target == null then
        return false
    endif

    set unitTypeId = GetUnitTypeId(target)
    if target == udg_Aradion or unitTypeId == UNIT_ARADION then
        return IsQuestOpenForCompanionInvite(QUEST_RIFTS_CORRUPTION)
    endif
    if target == udg_Valeria or unitTypeId == UNIT_VALERIA then
        return IsQuestOpenForCompanionInvite(QUEST_RANGER_MISSING) or IsQuestOpenForCompanionInvite(QUEST_RIFTS_CORRUPTION)
    endif
    return false
endfunction

private function IsQuestCompanionLevelBypass takes unit target returns boolean
    return IsQuestCompanionReputationBypass(target)
endfunction

private function IsQuestCompanionType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_ARADION or unitTypeId == UNIT_VALERIA
endfunction

private function GetHireReputationRequirement takes Faction f returns integer
    return Reputation_REP_NEUTRAL
endfunction

private function CanHireByReputation takes unit target returns boolean
    local Faction f

    if target == null then
        return false
    endif
    if IsQuestCompanionReputationBypass(target) then
        return true
    endif

    set f = Faction.getByUnit(target)
    if f == 0 then
        return true
    endif

    return Reputation.getRep(Player(CONTROL_PLAYER_INDEX), f) >= GetHireReputationRequirement(f)
endfunction

private function GetHireReputationFailureText takes unit target returns string
    local Faction f

    if target == null then
        return "This unit will not join the party."
    endif

    set f = Faction.getByUnit(target)
    if f != 0 then
        return GetUnitName(target) + " requires Neutral reputation with " + f.name + " to join."
    endif
    return GetUnitName(target) + " will not join the party."
endfunction

private function HandleInvite takes unit caster, unit target returns nothing
    local integer unitTypeId
    local integer requiredLevel
    local integer candidateLevel
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

    if IsQuestCompanionType(unitTypeId) and not IsQuestCompanionReputationBypass(target) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " cannot join outside the active quest.")
        return
    endif

    if IsUnitEnemy(target, GetOwningPlayer(caster)) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " is hostile and cannot be invited.")
        return
    endif

    if not CanHireByReputation(target) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetHireReputationFailureText(target))
        return
    endif

    if IsCompanionPartyFull() then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Companions: party is full.")
        return
    endif

    set requiredLevel = GetMaxPartyHeroLevel()
    set candidateLevel = GetCompanionCandidateLevel(target)
    if candidateLevel > requiredLevel and not IsQuestCompanionLevelBypass(target) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " is higher level than this party.")
        return
    endif

    set icon = GetNamedCompanionIcon(unitTypeId)
    set leader = GetPreferredLeader(caster)
    call SetUnitOwner(target, Player(COMPANION_OWNER_INDEX), true)
    call AddInternal(target, icon, leader, CurrentGroupMode)
    call QueueCompanionCommandLine(COMMAND_INVITE, CurrentGroupMode)
    call FireCommandEvent(target, caster, COMMAND_INVITE, CurrentGroupMode)
    call PlayCommandSound(gg_snd_Rescue)

    set leader = null
endfunction

private function HandleKick takes unit caster, unit target returns nothing
    local player returnOwner

    if target == null or udg_Companion_Group == null or not IsUnitInGroup(target, udg_Companion_Group) then
        return
    endif

    set udg_CompanionUnitKicked = target
    call PlayCommandSound(gg_snd_UpkeepRing)

    call QueueCompanionCommandLine(COMMAND_KICK, 0)
    call FireCommandEvent(target, caster, COMMAND_KICK, 0)
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
    if target == null or not IsValidControlTarget(target) then
        return
    endif

    call PlayCommandSound(gg_snd_GoodJob)
    call TrackExistingControlUnit(target)
    call SetLeaderInternal(target, leader)
    if leader != null then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " now follows " + GetUnitName(leader) + ".")
    endif
endfunction

private function ApplyFocusTarget takes nothing returns nothing
    local unit u = GetEnumUnit()
    call TrackExistingControlUnit(u)
    call SetLeaderInternal(u, FocusActionLeader)
    set u = null
endfunction

private function ApplyFocusToAllTargets takes unit leader returns nothing
    local integer count

    call EnsureState()
    call RepairGuiCompanionState()
    call GroupClear(ModeTargetGroup)
    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function AddAllModeTarget)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function AddAllModeTarget)
    endif
    if ControlledDisplayGroup != null then
        call ForGroup(ControlledDisplayGroup, function AddAllModeTarget)
    endif

    set FocusActionLeader = leader
    call ForGroup(ModeTargetGroup, function ApplyFocusTarget)
    set count = CountUnitsInGroup(ModeTargetGroup)

    if count > 0 and leader != null then
        call PlayCommandSound(gg_snd_GoodJob)
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Companions now follow " + GetUnitName(leader) + ".")
    endif

    call GroupClear(ModeTargetGroup)
    set FocusActionLeader = null
    set leader = null
endfunction

private function ApplyFocusFromCommand takes unit target, unit leader returns nothing
    if target != null then
        call HandleFocus(target, leader)
    else
        call ApplyFocusToAllTargets(leader)
    endif
    set target = null
    set leader = null
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
    elseif unitTypeId == UNIT_UNDEAD_WARLOCK or unitTypeId == UNIT_ORC_WARLOCK then
        return "Warlock"
    elseif unitTypeId == UNIT_SHAMAN then
        return "Restoration Shaman"
    elseif unitTypeId == UNIT_WARRIOR or unitTypeId == UNIT_AVELINE then
        return "Warrior"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Engineer"
    elseif unitTypeId == UNIT_PALADIN then
        return "Paladin"
    elseif unitTypeId == UNIT_ARADION then
        return "Farseer"
    elseif unitTypeId == UNIT_VALERIA then
        return "Ranger"
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
    elseif unitTypeId == UNIT_AIR_ELEMENTAL then
        return "Air Elemental"
    elseif unitTypeId == UNIT_WATER_ELEMENTAL then
        return "Water Elemental"
    elseif unitTypeId == UNIT_FIRE_ELEMENTAL then
        return "Fire Elemental"
    elseif unitTypeId == UNIT_EARTH_ELEMENTAL then
        return "Earth Elemental"
    elseif IsSummonedSpiritWolfType(unitTypeId) then
        return "Spirit Wolf"
    endif

    set objectName = GetObjectName(unitTypeId)
    if objectName != null and objectName != "" then
        return objectName
    endif

    return "Controlled Unit"
endfunction

private function GetCompanionClassInfoTextInternal takes unit target returns string
    local integer unitTypeId

    if target == null then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(target)
    if unitTypeId == UNIT_ROGUE then
        return "Rogue"
    elseif unitTypeId == UNIT_UNDEAD_WARLOCK or unitTypeId == UNIT_ORC_WARLOCK then
        return "Warlock"
    elseif unitTypeId == UNIT_SHAMAN or unitTypeId == UNIT_HIRED_SHAMAN then
        return "Shaman"
    elseif unitTypeId == UNIT_WARRIOR or unitTypeId == UNIT_AVELINE then
        return "Warrior"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Engineer"
    elseif unitTypeId == UNIT_PALADIN then
        return "Paladin"
    elseif unitTypeId == UNIT_ARADION then
        return "Farseer"
    elseif unitTypeId == UNIT_VALERIA then
        return "Ranger"
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
    elseif IsSummonedElementalType(unitTypeId) then
        return "Elemental"
    elseif IsSummonedSpiritWolfType(unitTypeId) then
        return "Spirit Wolf"
    endif

    return GetUnitTypeInfoName(unitTypeId)
endfunction

private function GetCompanionTypeInfoTextInternal takes unit target returns string
    local integer unitTypeId

    if target == null then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(target)
    if unitTypeId == UNIT_WARRIOR or unitTypeId == UNIT_AVELINE or unitTypeId == UNIT_GRUNT_1 or unitTypeId == UNIT_GRUNT_5 or unitTypeId == UNIT_GRUNT_10 or unitTypeId == UNIT_GRUNT_15 or unitTypeId == UNIT_GRUNT_20 or unitTypeId == UNIT_GRUNT_25 or unitTypeId == UNIT_STONEGUARD_5 then
        return "Tank"
    elseif unitTypeId == UNIT_PALADIN or unitTypeId == UNIT_SHAMAN or unitTypeId == UNIT_HIRED_SHAMAN then
        return "Healer"
    elseif unitTypeId == UNIT_ROGUE or unitTypeId == UNIT_MARAUDER_1 or unitTypeId == UNIT_MARAUDER_5 or unitTypeId == UNIT_RAIDER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Melee Damage"
    elseif unitTypeId == UNIT_UNDEAD_WARLOCK or unitTypeId == UNIT_ORC_WARLOCK or unitTypeId == UNIT_VALERIA or unitTypeId == UNIT_HEADHUNTER then
        return "Ranged Damage"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ARADION or unitTypeId == UNIT_WITCH_DOCTOR then
        return "Support"
    elseif unitTypeId == UNIT_EARTH_ELEMENTAL then
        return "Tank"
    elseif IsSummonedElementalType(unitTypeId) then
        return "Ranged Damage"
    elseif IsSummonedSpiritWolfType(unitTypeId) then
        return "Melee Damage"
    endif

    if IsUnitType(target, UNIT_TYPE_RANGED_ATTACKER) then
        return "Ranged Damage"
    endif
    return "Melee Damage"
endfunction

private function GetFactionInfoTextInternal takes unit target returns string
    local integer unitTypeId
    local string factionName

    if target == null then
        return "Unknown"
    endif

    set unitTypeId = GetUnitTypeId(target)
    if udg_TamedUnits != null and IsUnitInGroup(target, udg_TamedUnits) then
        return "Tamed Beast"
    elseif target == udg_Shadowclaw then
        return "Shadowclaw"
    endif

    set factionName = Reputation_GetUnitFactionName(target)
    if factionName != "" then
        return factionName
    endif

    if target == udg_Aradion or target == udg_Valeria or unitTypeId == UNIT_ARADION or unitTypeId == UNIT_VALERIA then
        return "Elarindor"
    elseif unitTypeId == UNIT_ENGINEER or unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Goblins"
    elseif unitTypeId == UNIT_PALADIN or unitTypeId == UNIT_AVELINE then
        return "Riverbane Citizen"
    elseif IsNamedCompanionType(unitTypeId) or IsHiredUnitType(unitTypeId) then
        return "Horde"
    elseif IsSummonedElementalType(unitTypeId) or IsSummonedSpiritWolfType(unitTypeId) then
        return "Summoned Spirit"
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

private function GetCompanionAbilityInfoTextInternal takes unit target returns string
    local integer unitTypeId

    if target == null then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(target)
    if unitTypeId == UNIT_UNDEAD_WARLOCK or unitTypeId == UNIT_ORC_WARLOCK then
        return "Shadow Bolt, Life Drain, Rain of Fire, Banish, Fear, Curse of Agony, Life Tap, Summon Imp"
    elseif unitTypeId == UNIT_ROGUE then
        return "Evasion, Garrote, Shadowstep, Sinister Strike, Slice and Dice, Surprise Attack, Toxic Venom"
    elseif unitTypeId == UNIT_WARRIOR or unitTypeId == UNIT_AVELINE then
        return "Battle Shout, Charge, Heroic Strike, Rend, Sunder Armor, Thunder Clap, Retaliation, Recklessness"
    elseif unitTypeId == UNIT_SHAMAN then
        return "Chain Heal, Chain Lightning, Earth Totem, Earthbind Totem, Fire Totem, Stoneskin Totem, Water Totem, Wind Totem, Windfury Totem, Healing Wave, Hex, Lightning Bolt"
    elseif unitTypeId == UNIT_ENGINEER then
        return "Repair, Mechanical Construct, Grenade, Turret, Shredder, Drone, Smoke Bomb"
    elseif IsSummonedElementalType(unitTypeId) then
        return "Elemental attacks and shaman-bound companion control"
    elseif IsSummonedSpiritWolfType(unitTypeId) then
        return "Spirit bites and shaman-bound companion control"
    elseif unitTypeId == UNIT_ENGINEER_SHREDDER then
        return "Shred, Charge, Slam, Cluster Rockets, Smoke Bomb"
    elseif unitTypeId == UNIT_PALADIN then
        return "Divine Shield, Holy Light, Inner Fire, Judgement Strike, Lay on Hands"
    elseif unitTypeId == UNIT_ARADION then
        return "Quest companion abilities, rift closing, support spells"
    elseif unitTypeId == UNIT_VALERIA then
        return "Ranger attacks, Cold Arrows, quest companion abilities"
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

    call PlayCommandSound(gg_snd_GoodJob)

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
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Faction: |r" + GetFactionInfoTextInternal(target))
    if unitTypeId == UNIT_AVELINE then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Info: |rAveline is a Riverbane human who protects her people from bandits and orc raiders.")
    endif
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Level: |r" + GetLevelInfoText(target) + " | |cFFFFCC00Life: |r" + I2S(R2I(GetUnitState(target, UNIT_STATE_LIFE))) + " / " + I2S(R2I(GetUnitState(target, UNIT_STATE_MAX_LIFE))))

    set maxMana = GetUnitState(target, UNIT_STATE_MAX_MANA)
    if maxMana > 0.00 then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Mana: |r" + I2S(R2I(GetUnitState(target, UNIT_STATE_MANA))) + " / " + I2S(R2I(maxMana)) + " | |cFFFFCC00Damage: |r" + GetDamageInfoText(target) + " | |cFFFFCC00Armor: |r" + I2S(R2I(BlzGetUnitArmor(target))))
    else
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Damage: |r" + GetDamageInfoText(target) + " | |cFFFFCC00Armor: |r" + I2S(R2I(BlzGetUnitArmor(target))))
    endif

    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Stats: |r" + GetSharedStatsInfoText(target))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFFFFCC00Mode: |r" + modeText + " | |cFFFFCC00Focus: |r" + GetFocusInfoText(target))
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cFF7EBFF1Abilities:|r " + GetCompanionAbilityInfoTextInternal(target))
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

private function HandleDropItems takes unit caster, unit target returns nothing
    if target == null or udg_Companion_Group == null or not IsUnitInGroup(target, udg_Companion_Group) then
        set caster = null
        return
    endif

    call DropUnitItems(target)
    call QueueCompanionCommandLine(COMMAND_DROP_ITEMS, 0)
    call FireCommandEvent(target, caster, COMMAND_DROP_ITEMS, 0)
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " dropped carried items.")
    set caster = null
endfunction

private function AddHiredUnitStock takes unit shopUnit, integer unitTypeId returns nothing
    if shopUnit != null then
        call RemoveUnitFromStock(shopUnit, unitTypeId)
        call AddUnitToStock(shopUnit, unitTypeId, 1, 1)
    endif
    set shopUnit = null
endfunction

private function InitHiredUnitShops takes nothing returns nothing
    local trigger initTrigger = GetTriggeringTrigger()

    // Thornwoods Horde units. Shop: Barracks 0019 <gen> / gg_unit_o607_0019.
    call AddHiredUnitStock(gg_unit_o607_0019, UNIT_GRUNT_1)
    call AddHiredUnitStock(gg_unit_o607_0019, UNIT_GRUNT_5)
    call AddHiredUnitStock(gg_unit_o607_0019, UNIT_GRUNT_10)

    // Sirensong, Ghostridge, and Forward Base had no stock entries in the old GUI trigger.

    if initTrigger != null then
        call DestroyTrigger(initTrigger)
    endif
    set initTrigger = null
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
    call PlayCommandSound(gg_snd_Rescue)

    set leader = null
    set soldUnit = null
    set buyer = null
endfunction

private function OnUnitDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local unit killer = GetKillingUnit()

    call HandleHostilityAgainstFactionUnit(killer, dying)

    if dying != null and udg_Companion_Group != null and IsUnitInGroup(dying, udg_Companion_Group) and not IsUnitType(dying, UNIT_TYPE_HERO) and dying != udg_Valeria and dying != udg_Aradion and dying != udg_Aveline then
        set udg_CompanionUnitKicked = dying
        call SyncGuiCompanionEntry(dying, "")
        call RemoveInternal(dying)
    endif

    set dying = null
    set killer = null
endfunction

private function OnUnitAttacked takes nothing returns nothing
    local unit attacker = GetAttacker()
    local unit target = GetTriggerUnit()

    call HandleHostilityAgainstFactionUnit(attacker, target)

    set attacker = null
    set target = null
endfunction

private function OnSpellEffect takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    local integer mode = GetModeFromAbility(abilityId)
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local player commandPlayer = GetCommandPlayer(caster)

    if target == null and (abilityId == ABIL_KICK or abilityId == ABIL_INFORMATION or abilityId == ABIL_DROP_ITEMS) then
        set target = ResolveCommandTarget(caster, target, commandPlayer)
    endif

    if mode != 0 then
        call ApplyModeFromCommand(caster, target, mode)
    elseif abilityId == ABIL_INVITE then
        if target != udg_Shadowclaw then
            call HandleInvite(caster, target)
        endif
    elseif abilityId == ABIL_KICK then
        if target == null or udg_TamedUnits == null or not IsUnitInGroup(target, udg_TamedUnits) then
            call HandleKick(caster, target)
        endif
    elseif abilityId == ABIL_FOCUS_NAZGREK then
        call ApplyFocusFromCommand(target, udg_Nazgrek)
    elseif abilityId == ABIL_FOCUS_ZULKIS then
        call ApplyFocusFromCommand(target, udg_Zulkis)
    elseif abilityId == ABIL_INFORMATION then
        call HandleInformation(target)
    elseif abilityId == ABIL_DROP_ITEMS then
        call HandleDropItems(caster, target)
    endif

    set caster = null
    set target = null
    set commandPlayer = null
endfunction

private function HaltControlledEnum takes nothing returns nothing
    call SetSuspendedInternal(GetEnumUnit(), true)
endfunction

private function ResumeControlledEnum takes nothing returns nothing
    call SetSuspendedInternal(GetEnumUnit(), false)
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

public function SetEscortBehavior takes unit controlledUnit, boolean enabled returns nothing
    call SetEscortBehaviorInternal(controlledUnit, enabled)
endfunction

public function SetFollowerBehavior takes unit controlledUnit, boolean enabled returns nothing
    call SetFollowerBehaviorInternal(controlledUnit, enabled)
endfunction

public function GetMode takes unit companionUnit returns integer
    local integer unitId
    call EnsureState()
    if companionUnit == null or GetUnitTypeId(companionUnit) == 0 then
        return COMPANION_MODE_DEFEND
    endif
    set unitId = GetHandleId(companionUnit)
    if CompanionTracked[unitId] == 0 then
        return COMPANION_MODE_DEFEND
    endif
    return NormalizeMode(CompanionMode[unitId])
endfunction

public function RefreshOrders takes unit companionUnit returns nothing
    if companionUnit == null then
        return
    endif
    call ClearOrderIdleState(companionUnit, GetUnitUserData(companionUnit))
    call ApplyOrders(companionUnit)
endfunction

public function Halt takes unit companionUnit returns nothing
    call SetSuspendedInternal(companionUnit, true)
endfunction

public function HaltAll takes nothing returns nothing
    call RepairGuiCompanionState()
    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function HaltControlledEnum)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function HaltControlledEnum)
    endif
    if ControlledDisplayGroup != null then
        call ForGroup(ControlledDisplayGroup, function HaltControlledEnum)
    endif
endfunction

public function Suspend takes unit companionUnit returns nothing
    call SetSuspendedInternal(companionUnit, true)
endfunction

public function Resume takes unit companionUnit returns nothing
    call SetSuspendedInternal(companionUnit, false)
endfunction

public function ResumeAll takes nothing returns nothing
    call RepairGuiCompanionState()
    if udg_Companion_Group != null then
        call ForGroup(udg_Companion_Group, function ResumeControlledEnum)
    endif
    if udg_TamedUnits != null then
        call ForGroup(udg_TamedUnits, function ResumeControlledEnum)
    endif
    if ControlledDisplayGroup != null then
        call ForGroup(ControlledDisplayGroup, function ResumeControlledEnum)
    endif
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
    call RemoveControlledDisplayUnit(controlledUnit)
    call FollowSystem_RemoveUnit(controlledUnit)
    call ClearCompanionFarIcon(controlledUnit)
    call DestroyCompanionFollowerEffects(controlledUnit)
    if udg_CompanionFocusNazgrek != null then
        call GroupRemoveUnit(udg_CompanionFocusNazgrek, controlledUnit)
    endif
    if udg_CompanionFocusZulkis != null then
        call GroupRemoveUnit(udg_CompanionFocusZulkis, controlledUnit)
    endif
    call CompanionLeader.remove(unitId)
    call CompanionMode.remove(unitId)
    call CompanionSuspended.remove(unitId)
    call CompanionIcon.remove(unitId)
    call CompanionRegistered.remove(unitId)
    call CompanionTracked.remove(unitId)
    call CompanionOrderProfile.remove(unitId)
    call CompanionNextRandomMove.remove(unitId)
    call CompanionStoppedEffect.remove(unitId)
    call CompanionFollowingEffect.remove(unitId)
endfunction

public function IsControlled takes unit controlledUnit returns boolean
    if controlledUnit == null or CompanionTracked == 0 then
        return false
    endif
    return CompanionTracked[GetHandleId(controlledUnit)] == 1
endfunction

public function IsControlledDisplayUnit takes unit controlledUnit returns boolean
    if controlledUnit == null or ControlledDisplayIndex == 0 then
        return false
    endif
    if IsPetControlUnit(controlledUnit) then
        return false
    endif
    return ControlledDisplayIndex.integer[GetHandleId(controlledUnit)] > 0
endfunction

public function GetControlledDisplayCount takes nothing returns integer
    call EnsureState()
    return ControlledDisplayCount
endfunction

public function GetControlledDisplayUnit takes integer index returns unit
    call EnsureState()
    if index < 1 or index > ControlledDisplayCount then
        return null
    endif
    return ControlledDisplayUnits[index]
endfunction

public function GetCompanionLimit takes nothing returns integer
    return GetCompanionLimitInternal()
endfunction

public function GetCompanionStatusText takes nothing returns string
    return I2S(udg_CompanionCount) + " / " + I2S(GetCompanionLimitInternal()) + " companions"
endfunction

public function GetCompanionLimitInfoText takes nothing returns string
    return GetCompanionLimitInfoTextInternal()
endfunction

public function ShowCompanionLimitInfo takes nothing returns nothing
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetCompanionLimitInfoTextInternal())
endfunction

public function GetClassInfoText takes unit controlledUnit returns string
    return GetCompanionClassInfoTextInternal(controlledUnit)
endfunction

public function GetTypeInfoText takes unit controlledUnit returns string
    return GetCompanionTypeInfoTextInternal(controlledUnit)
endfunction

public function GetFactionInfoText takes unit controlledUnit returns string
    return GetFactionInfoTextInternal(controlledUnit)
endfunction

public function GetAbilityInfoText takes unit controlledUnit returns string
    return GetCompanionAbilityInfoTextInternal(controlledUnit)
endfunction

private function Init takes nothing returns nothing
    local trigger shopInitTrigger = null

    call EnsureState()

    call Events_RegisterPlayerUnitEvent(function OnSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_RegisterPlayerUnitEvent(function HandleSoldUnit, EVENT_PLAYER_UNIT_SELL)
    call Events_RegisterPlayerUnitEvent(function OnUnitAttacked, EVENT_PLAYER_UNIT_ATTACKED)

    set IdleTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(IdleTrigger, COMPANION_IDLE_CHECK_INTERVAL, true)
    call TriggerAddAction(IdleTrigger, function OnIdlePeriodic)

    set OrderTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(OrderTrigger, COMPANION_ORDER_INTERVAL, true)
    call TriggerAddAction(OrderTrigger, function OnOrderPeriodic)

    call UnitDeathEvent_Register(function OnUnitDeath)

    set shopInitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(shopInitTrigger, HIRED_UNIT_SHOP_INIT_DELAY, false)
    call TriggerAddAction(shopInitTrigger, function InitHiredUnitShops)

    set shopInitTrigger = null
endfunction

endlibrary
