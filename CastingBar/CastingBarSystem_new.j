//============================================================================
// Casting Bar System
//============================================================================
/*
    Author: [Valdemar]
    Version: 1.0 (Engine-correct refactor)

    NOTES (IMPORTANT CHANGES):
    ------------------------------------------------
    - SPELL_CAST      → Pre-cast bar (Casting Time)
    - SPELL_EFFECT    → Channel bar (Duration)
    - SPELL_CHANNEL   → Guard ONLY (no timing)
    - SPELL_ENDCAST   → Cleanup

    SEMANTIC CHANGE:
    ------------------------------------------------
    IsChannel.boolean[unitId] meaning CHANGED:
        false = precast phase (bar fills)
        true  = channel phase (bar drains)

    Blizzard / Rain of Fire / Starfall FIXED
*/
//============================================================================

library CastingBarSystem initializer Init requires Table

//============================================================================
// CONFIGURATION
//============================================================================

globals
    private constant integer POSITION_OVERHEAD = 0
    private constant integer POSITION_ORIGIN = 1
    private constant integer POSITION_SIDE = 2
    
    private constant integer BAR_POSITION_MODE = POSITION_ORIGIN
    private constant real CASTING_BAR_SIZE = 0.0138
    private constant real CASTING_NAME_SIZE = 0.00092
    private constant real BAR_WIDTH_MULTIPLIER = 250.0
    private constant real NAME_WIDTH_MULTIPLIER = 300.0
    private constant real BAR_Z_OFFSET = 50.0
    private constant real ORIGIN_Z_OFFSET = -50.0
    private constant real SIDE_X_OFFSET = 80.0
    private constant real SIDE_Z_OFFSET = 20.0
    
    private constant integer NUMBER_OF_TICKS = 30
    private constant real UPDATE_INTERVAL = 0.10
    private constant real MAX_DISTANCE = 2500.0
    
    private constant boolean ENABLE_CASTING_BAR = true
    private constant boolean ENABLE_ABILITY_NAME = true
    private constant boolean ENABLE_VISIBILITY = true
    private constant boolean DEBUG_MODE = false
    
    private group CastingGroup = CreateGroup()
    private trigger PeriodicTrigger
    private string LoadingBarText = ""
    
    private boolean RuntimeEnableCastingBar = true
    private boolean RuntimeEnableAbilityName = true
    
    private Table BeginCastTime
    private Table EndCastTime
    private Table IsChannel          // SEMANTIC CHANGE (see header)
    private Table CastingBarTag
    private Table AbilityName
    private Table UnitOwner
    private Table PlayerColors
    
    private location LOC = Location(0.0, 0.0)
endglobals

//============================================================================
// EXCLUSIONS
//============================================================================

private function IsExcludedAbility takes integer abilityId returns boolean
    return false
endfunction

//============================================================================
// PUBLIC API
//============================================================================

function CastingBarSystem_EnableCastingBar takes boolean enable returns nothing
    set RuntimeEnableCastingBar = enable
endfunction

function CastingBarSystem_EnableAbilityName takes boolean enable returns nothing
    set RuntimeEnableAbilityName = enable
endfunction

//============================================================================
// PLAYER COLORS
//============================================================================

private function InitPlayerColors takes nothing returns nothing
    set PlayerColors.string[1]  = "|cffff0303"
    set PlayerColors.string[2]  = "|cff0042ff"
    set PlayerColors.string[3]  = "|cff1ce6b9"
    set PlayerColors.string[4]  = "|cff540081"
    set PlayerColors.string[5]  = "|cfffffc01"
    set PlayerColors.string[6]  = "|cfffe8a0e"
    set PlayerColors.string[7]  = "|cff20c000"
    set PlayerColors.string[8]  = "|cffe55bb0"
    set PlayerColors.string[9]  = "|cff959697"
    set PlayerColors.string[10] = "|cff7ebff1"
    set PlayerColors.string[11] = "|cff106246"
    set PlayerColors.string[12] = "|cff4e2a04"
    set PlayerColors.string[13] = "|c002F2F2F"
    set PlayerColors.string[14] = "|c002F2F2F"
    set PlayerColors.string[15] = "|cffA52A2A"
    set PlayerColors.string[16] = "|cff800000"
    set PlayerColors.string[17] = "|cff808000"
    set PlayerColors.string[18] = "|cff008080"
    set PlayerColors.string[19] = "|cff4682B4"
    set PlayerColors.string[20] = "|cffD2691E"
    set PlayerColors.string[21] = "|cff9ACD32"
    set PlayerColors.string[22] = "|cff32CD32"
    set PlayerColors.string[23] = "|cffFF4500"
    set PlayerColors.string[24] = "|cff8B4513"
endfunction

//============================================================================
// HELPERS
//============================================================================

private function GetWorldZ takes real x, real y returns real
    call MoveLocation(LOC, x, y)
    return GetLocationZ(LOC)
endfunction

private function GetAbilityCastTime takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    if abil == null then
        return 0.0
    endif
    return BlzGetAbilityRealLevelField(abil, ABILITY_RLF_CASTING_TIME, level - 1)
endfunction

private function GetAbilityDuration takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    local real d
    if abil == null then
        return 0.0
    endif
    set d = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, level - 1)
    if d <= 0.0 then
        set d = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, level - 1)
    endif
    return d
endfunction

private function GetAbilityFollowThrough takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    if abil == null then
        return 0.0
    endif
    return BlzGetAbilityRealLevelField(abil, ABILITY_RLF_FOLLOW_THROUGH_TIME, level - 1)
endfunction

private function GetBarXOffset takes unit u returns real
    local real barWidth
    if BAR_POSITION_MODE == POSITION_SIDE then
        return GetUnitX(u) + SIDE_X_OFFSET
    endif
    set barWidth = (NUMBER_OF_TICKS + 2.0) * CASTING_BAR_SIZE * BAR_WIDTH_MULTIPLIER
    return GetUnitX(u) - (barWidth * 0.5)
endfunction

private function GetBarZOffset takes nothing returns real
    if BAR_POSITION_MODE == POSITION_ORIGIN then
        return ORIGIN_Z_OFFSET
    elseif BAR_POSITION_MODE == POSITION_SIDE then
        return SIDE_Z_OFFSET
    endif
    return BAR_Z_OFFSET
endfunction

//============================================================================
// CORE EVENTS
//============================================================================

// SPELL_CAST → PRECAST BAR (works for Firebolt!)
private function OnBeginCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abil = GetSpellAbilityId()
    local integer lvl = GetUnitAbilityLevel(u, abil)
    local integer uid = GetHandleId(u)
    local real castTime
    local string barText
    local player owner
    local integer pid

    // Skip excluded abilities
    if IsExcludedAbility(abil) then
        set u = null
        return
    endif

    // Get cast time for ANY ability
    set castTime = GetAbilityCastTime(abil, lvl, u)

    // Skip if cast time is 0
    if castTime <= 0.0 then
        set u = null
        return
    endif

    // Initialize casting data
    set IsChannel.boolean[uid] = false
    set BeginCastTime.real[uid] = 0.0
    set EndCastTime.real[uid] = castTime
    set AbilityName.string[uid] = BlzGetAbilityTooltip(abil, lvl - 1)

    set owner = GetOwningPlayer(u)
    set pid = GetPlayerId(owner) + 1
    set UnitOwner.player[uid] = owner

    // Initial empty bar
    set barText = "[" + LoadingBarText + "]"
    if ENABLE_ABILITY_NAME and RuntimeEnableAbilityName then
        set barText = AbilityName.string[uid] + "|n" + barText
    endif

    if ENABLE_CASTING_BAR and RuntimeEnableCastingBar and IsUnitVisible(u, owner) then
        set CastingBarTag.texttag[uid] = CreateTextTag()
        call SetTextTagText(CastingBarTag.texttag[uid], barText, CASTING_BAR_SIZE)
        call SetTextTagPos(CastingBarTag.texttag[uid], GetBarXOffset(u), GetUnitY(u), GetBarZOffset())
    endif

    call GroupAddUnit(CastingGroup, u)
    call EnableTrigger(PeriodicTrigger)

    set u = null
    set owner = null
endfunction

// SPELL_EFFECT → CHANNEL/FOLLOW-THROUGH ONLY
private function OnSpellEffect takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abil = GetSpellAbilityId()
    local integer lvl = GetUnitAbilityLevel(u, abil)
    local integer uid = GetHandleId(u)
    local real duration
    local real follow
    local real barTime
    local string barText
    local player owner
    local integer pid

    set follow = GetAbilityFollowThrough(abil, lvl, u)
    set duration = GetAbilityDuration(abil, lvl, u)

    // Only show a follow-through bar if the spell has actual channel or follow-through
    if follow <= 0.0 and duration <= 0.0 then
        // Non-channeled ability (Firebolt) → DO NOT remove precast bar
        set u = null
        return
    endif

    // Decide total bar time
    if follow > 0.0 then
        set barTime = follow
    else
        set barTime = duration
    endif

    // Reset channel info and times
    set IsChannel.boolean[uid] = true
    set BeginCastTime.real[uid] = 0.0
    set EndCastTime.real[uid] = barTime

    // Remove old text tag only if it exists
    if CastingBarTag.texttag[uid] != null then
        call DestroyTextTag(CastingBarTag.texttag[uid])
        call CastingBarTag.remove(uid)
    endif
    call GroupRemoveUnit(CastingGroup, u)

    // Create new text tag for channel/follow-through
    set owner = GetOwningPlayer(u)
    set pid = GetPlayerId(owner) + 1
    set UnitOwner.player[uid] = owner

    set barText = "[" + PlayerColors.string[pid] + LoadingBarText + "|r]"
    if ENABLE_ABILITY_NAME and RuntimeEnableAbilityName then
        set barText = AbilityName.string[uid] + "|n" + barText
    endif

    set CastingBarTag.texttag[uid] = CreateTextTag()
    call SetTextTagText(CastingBarTag.texttag[uid], barText, CASTING_BAR_SIZE)
    call SetTextTagPos(CastingBarTag.texttag[uid], GetBarXOffset(u), GetUnitY(u), GetBarZOffset())

    call GroupAddUnit(CastingGroup, u)
    call EnableTrigger(PeriodicTrigger)

    set u = null
    set owner = null
endfunction

// SPELL_CHANNEL → SAFETY ONLY
private function OnSpellChannel takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer uid = GetHandleId(u)
    
    // Only remove from casting group if this is a true channel (duration/follow > 0)
    if IsChannel.boolean[uid] and IsUnitInGroup(u, CastingGroup) then
        call GroupRemoveUnit(CastingGroup, u)
    endif

    set u = null
endfunction
// SPELL_ENDCAST → CLEANUP
private function OnEndCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer uid = GetHandleId(u)

    if CastingBarTag.texttag[uid] != null then
        call DestroyTextTag(CastingBarTag.texttag[uid])
        call CastingBarTag.remove(uid)
    endif

    call BeginCastTime.remove(uid)
    call EndCastTime.remove(uid)
    call IsChannel.remove(uid)
    call AbilityName.remove(uid)
    call UnitOwner.remove(uid)
    call GroupRemoveUnit(CastingGroup, u)

    if FirstOfGroup(CastingGroup) == null then
        call DisableTrigger(PeriodicTrigger)
    endif

    set u = null
endfunction

//============================================================================
// UPDATE LOOP
//============================================================================

//UPDATE LOOP → correctly handle precast & channel/follow-through
private function UpdateSingleUnit takes nothing returns nothing
    local unit u = GetEnumUnit()
    local integer uid = GetHandleId(u)
    local real progress
    local integer barLength
    local string barText
    local player owner
    local integer pid
    local real increment

    // Use actual update increment based on real UPDATE_INTERVAL
    set increment = UPDATE_INTERVAL

    set BeginCastTime.real[uid] = BeginCastTime.real[uid] + increment

    if BeginCastTime.real[uid] >= EndCastTime.real[uid] then
        call OnEndCast()
        set u = null
        return
    endif

    set progress = BeginCastTime.real[uid] / EndCastTime.real[uid]

    // Channel/follow-through phase → bar drains correctly
    if IsChannel.boolean[uid] then
        set progress = 1.0 - progress
    endif

    // Clamp
    if progress < 0.0 then
        set progress = 0.0
    elseif progress > 1.0 then
        set progress = 1.0
    endif

    set barLength = R2I(progress * NUMBER_OF_TICKS)

    set owner = GetOwningPlayer(u)
    set pid = GetPlayerId(owner) + 1

    set barText = "[" + PlayerColors.string[pid] + SubString(LoadingBarText, 0, barLength) + "|r" + SubString(LoadingBarText, barLength, NUMBER_OF_TICKS) + "]"
    if ENABLE_ABILITY_NAME and RuntimeEnableAbilityName then
        set barText = AbilityName.string[uid] + "|n" + barText
    endif

    call SetTextTagText(CastingBarTag.texttag[uid], barText, CASTING_BAR_SIZE)
    call SetTextTagPos(CastingBarTag.texttag[uid], GetBarXOffset(u), GetUnitY(u), GetBarZOffset())

    set u = null
    set owner = null
endfunction

private function OnPeriodic takes nothing returns nothing
    call ForGroup(CastingGroup, function UpdateSingleUnit)
    if FirstOfGroup(CastingGroup) == null then
        call DisableTrigger(PeriodicTrigger)
    endif
endfunction

//============================================================================
// INIT
//============================================================================

private function Init takes nothing returns nothing
    local trigger tCast = CreateTrigger()
    local trigger tEffect = CreateTrigger()
    local trigger tChannel = CreateTrigger()
    local trigger tEnd = CreateTrigger()
    local integer i = 0

    set BeginCastTime = Table.create()
    set EndCastTime = Table.create()
    set IsChannel = Table.create()
    set CastingBarTag = Table.create()
    set AbilityName = Table.create()
    set UnitOwner = Table.create()
    set PlayerColors = Table.create()

    call InitPlayerColors()

    loop
        exitwhen i >= NUMBER_OF_TICKS
        set LoadingBarText = LoadingBarText + "l"
        set i = i + 1
    endloop

    set i = 0
    loop
        exitwhen i >= bj_MAX_PLAYER_SLOTS
        call TriggerRegisterPlayerUnitEvent(tCast,    Player(i), EVENT_PLAYER_UNIT_SPELL_CAST,    null)
        call TriggerRegisterPlayerUnitEvent(tEffect,  Player(i), EVENT_PLAYER_UNIT_SPELL_EFFECT,  null)
        call TriggerRegisterPlayerUnitEvent(tChannel, Player(i), EVENT_PLAYER_UNIT_SPELL_CHANNEL, null)
        call TriggerRegisterPlayerUnitEvent(tEnd,     Player(i), EVENT_PLAYER_UNIT_SPELL_ENDCAST, null)
        set i = i + 1
    endloop

    call TriggerAddAction(tCast,    function OnBeginCast)
    call TriggerAddAction(tEffect,  function OnSpellEffect)
    call TriggerAddAction(tChannel, function OnSpellChannel)
    call TriggerAddAction(tEnd,     function OnEndCast)

    set PeriodicTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(PeriodicTrigger, UPDATE_INTERVAL, true)
    call TriggerAddAction(PeriodicTrigger, function OnPeriodic)
    call DisableTrigger(PeriodicTrigger)
endfunction

endlibrary
