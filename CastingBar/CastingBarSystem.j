/**
    CastingBarSystem

    Author: Valdemar
    Version:

    Description:
    Displays casting bars for configured ability cast times and confirmed
    channel/follow-through phases. Normal ability durations are not treated as
    channels until the unit is still using the same order after the spell effect
    starts, because buffs and debuffs also use Warcraft III duration fields.

    Credits:
    - maddeemon for initial inspiration from "CastingBar"
    - Table v6 by Bribe

    How to install:
    Requires `Table` and `Events`. Import after those libraries. Add ability raw
    codes to `IsExcludedAbility` for special cases that should never show a bar.

    API:
    call CastingBarSystem_EnableCastingBar(true)
    call CastingBarSystem_EnableAbilityName(true)

**/
library CastingBarSystem initializer Init requires Table, Events, FallenHeroState

//============================================================================
// CONFIGURATION
//============================================================================

globals
    // Position Mode Constants
    private constant integer POSITION_OVERHEAD = 0       // Above unit (traditional)
    private constant integer POSITION_ORIGIN = 1         // At unit center/origin
    private constant integer POSITION_SIDE = 2           // To the side of unit

    // Cast phase constants
    private constant integer CAST_PHASE_PRECAST = 0
    private constant integer CAST_PHASE_PENDING_CHANNEL = 1
    private constant integer CAST_PHASE_CHANNEL = 2

    // Visual Settings
    private constant integer BAR_POSITION_MODE = POSITION_ORIGIN  // Choose position mode
    private constant real CASTING_BAR_SIZE = 0.0138      // Size of the casting bar text (converted from 6.00 * 0.0023)
    private constant real CASTING_NAME_SIZE = 0.00092    // Size of the ability name text (4.00 * 0.0023)
    private constant real BAR_WIDTH_MULTIPLIER = 250.0   // Adjust this to fine-tune progress bar horizontal centering
    private constant real NAME_WIDTH_MULTIPLIER = 300.0  // Adjust this to fine-tune ability name horizontal centering
    private constant real BAR_Z_OFFSET = 50.0            // Height offset above the unit (for OVERHEAD mode)
    private constant real ORIGIN_Z_OFFSET = -50.0        // Height at unit origin (for ORIGIN mode)
    private constant real SIDE_X_OFFSET = 80.0           // Horizontal offset to side (for SIDE mode)
    private constant real SIDE_Z_OFFSET = 20.0           // Height for side position
    // Note: Ability name and casting bar are combined in a single text tag to prevent
    // position desync when camera angle changes (text tags are 2D in 3D space)
    private constant integer NUMBER_OF_TICKS = 30        // Number of 'l' characters in the bar
    private constant real UPDATE_INTERVAL = 0.10         // How often to update the bars (seconds)
    private constant real MAX_DISTANCE = 2500.0          // Maximum distance for text visibility (3D distance from camera)
    private constant real MIN_PHASE_TIME = 0.05          // Ignore tiny object-data timings that only create flicker
    private constant real CHANNEL_CONFIRM_DELAY = 0.25   // Delay before duration fields are allowed to become channel bars
    private constant real PRECAST_FINISH_GRACE = 1.00    // Keep full pre-cast bars briefly if effect/endcast arrives late

    // Feature Toggles
    private constant boolean ENABLE_CASTING_BAR = true   // Show/hide the casting bar
    private constant boolean ENABLE_ABILITY_NAME = true  // Show/hide ability name above bar
    private constant boolean ENABLE_VISIBILITY = true    // Respect fog of war
    private constant boolean DEBUG_MODE = false          // Enable debug messages

    // System Globals
    private group CastingGroup = CreateGroup()
    private trigger PeriodicTrigger
    private string LoadingBarText = ""

    // Runtime Enable/Disable State (can be changed via public functions)
    private boolean RuntimeEnableCastingBar = true
    private boolean RuntimeEnableAbilityName = true

    // Table6.j data storage
    private Table BeginCastTime         // Stores current elapsed time per unit
    private Table EndCastTime           // Stores total phase time per unit
    private Table CastPhase             // Stores pre-cast, pending channel, or channel phase
    private Table PendingChannelTime    // Stores confirmation delay elapsed time
    private Table CastAbilityId         // Stores current ability raw code
    private Table CastAbilityLevel      // Stores current ability level
    private Table CastOrder             // Stores the order id that should remain active for channels
    private Table CastingBarTag         // Stores combined casting bar + name text tags
    private Table AbilityName           // Stores ability name for display
    private Table UnitOwner             // Stores unit owner for visibility checks
    private Table PlayerColors          // Stores player color strings

    // Reusable global location for terrain Z
    private location LOC = Location(0.0, 0.0)
endglobals

//============================================================================
// EXCLUSION LIST
//============================================================================
// Add ability IDs here that should NOT show casting bars
// Simply add them to the list in the function below
//============================================================================

private function IsExcludedAbility takes integer abilityId returns boolean
    // Example exclusions (replace with your actual ability raw codes):

    // Uncomment and add your exclusions below:
    // if abilityId == 'A000' then  // Example ability
    //     return true
    // endif
    // if abilityId == 'A001' then  // Another example
    //     return true
    // endif

    // Item abilities that shouldn't show bars
    // if abilityId == 'AItp' then  // Town Portal
    //     return true
    // endif

    return false
endfunction

//============================================================================
// PUBLIC API - Call these from GUI triggers
//============================================================================

function CastingBarSystem_EnableCastingBar takes boolean enable returns nothing
    set RuntimeEnableCastingBar = enable
endfunction

function CastingBarSystem_EnableAbilityName takes boolean enable returns nothing
    set RuntimeEnableAbilityName = enable
endfunction

//============================================================================
// PLAYER COLOR INITIALIZATION
//============================================================================

private function InitPlayerColors takes nothing returns nothing
    set PlayerColors.string[1] = "|cffff0303"  // Red
    set PlayerColors.string[2] = "|cff0042ff"  // Blue
    set PlayerColors.string[3] = "|cff1ce6b9"  // Teal
    set PlayerColors.string[4] = "|cff540081"  // Purple
    set PlayerColors.string[5] = "|cfffffc01"  // Yellow
    set PlayerColors.string[6] = "|cfffe8a0e"  // Orange
    set PlayerColors.string[7] = "|cff20c000"  // Green
    set PlayerColors.string[8] = "|cffe55bb0"  // Pink
    set PlayerColors.string[9] = "|cff959697"  // Gray
    set PlayerColors.string[10] = "|cff7ebff1" // Light Blue
    set PlayerColors.string[11] = "|cff106246" // Dark Green
    set PlayerColors.string[12] = "|cff4e2a04" // Brown
    set PlayerColors.string[13] = "|c002F2F2F" // Light Gray
    set PlayerColors.string[14] = "|c002F2F2F" // Light Gray
    set PlayerColors.string[15] = "|cffA52A2A" // Brown Red
    set PlayerColors.string[16] = "|cff800000" // Maroon
    set PlayerColors.string[17] = "|cff808000" // Olive
    set PlayerColors.string[18] = "|cff008080" // Teal Dark
    set PlayerColors.string[19] = "|cff4682B4" // Steel Blue
    set PlayerColors.string[20] = "|cffD2691E" // Chocolate
    set PlayerColors.string[21] = "|cff9ACD32" // Yellow Green
    set PlayerColors.string[22] = "|cff32CD32" // Lime Green
    set PlayerColors.string[23] = "|cffFF4500" // Orange Red
    set PlayerColors.string[24] = "|cff8B4513" // Saddle Brown
endfunction

//============================================================================
// HELPER FUNCTIONS
//============================================================================

private function DebugMsg takes string message returns nothing
    if DEBUG_MODE then
        call BJDebugMsg("[CastingBarSystem] " + message)
    endif
endfunction

private function GetWorldZ takes real x, real y returns real
    call MoveLocation(LOC, x, y)
    return GetLocationZ(LOC)
endfunction

private function GetAbilityDisplayName takes integer abilityId, integer level returns string
    local string abilityName = ""

    if level > 0 then
        set abilityName = BlzGetAbilityTooltip(abilityId, level - 1)
    endif

    if abilityName == "" or abilityName == null then
        set abilityName = GetObjectName(abilityId)
    endif

    return abilityName
endfunction

private function GetAbilityCastTime takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    local real castTime = 0.0

    if abil != null and level > 0 then
        set castTime = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_CASTING_TIME, level - 1)
    endif

    set abil = null
    return castTime
endfunction

private function GetAbilityDuration takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    local real duration = 0.0

    if abil != null and level > 0 then
        // Try hero duration first, then normal duration.
        set duration = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, level - 1)
        if duration <= 0.0 then
            set duration = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, level - 1)
        endif
    endif

    set abil = null
    return duration
endfunction

private function GetAbilityFollowThrough takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    local real followThrough = 0.0

    if abil != null and level > 0 then
        set followThrough = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_FOLLOW_THROUGH_TIME, level - 1)
    endif

    set abil = null
    return followThrough
endfunction

private function GetAbilityChannelTime takes integer abilityId, integer level, unit u returns real
    local real followThrough = GetAbilityFollowThrough(abilityId, level, u)

    if followThrough > 0.0 then
        return followThrough
    endif

    return GetAbilityDuration(abilityId, level, u)
endfunction

private function GetBarXOffset takes unit u returns real
    local real barWidth
    if BAR_POSITION_MODE == POSITION_SIDE then
        return GetUnitX(u) + SIDE_X_OFFSET
    endif
    // Center the casting bar by offsetting half its width.
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

private function IsWithinVisibleDistance takes real unitX, real unitY, real zOffset returns boolean
    local real unitZ = GetWorldZ(unitX, unitY) + zOffset
    local real camX = GetCameraTargetPositionX()
    local real camY = GetCameraTargetPositionY()
    local real camZ = GetCameraTargetPositionZ()
    local real dx = unitX - camX
    local real dy = unitY - camY
    local real dz = unitZ - camZ
    return (dx*dx + dy*dy + dz*dz) <= (MAX_DISTANCE * MAX_DISTANCE)
endfunction

private function ClampBarLength takes integer barLength returns integer
    if barLength < 0 then
        return 0
    endif
    if barLength > NUMBER_OF_TICKS then
        return NUMBER_OF_TICKS
    endif
    return barLength
endfunction

private function ClampProgress takes real progress returns real
    if progress < 0.0 then
        return 0.0
    endif
    if progress > 1.0 then
        return 1.0
    endif
    return progress
endfunction

private function GetPlayerColorString takes player owner returns string
    local integer playerId

    if owner == null then
        return "|cffffffff"
    endif

    set playerId = GetPlayerId(owner) + 1
    if playerId < 1 or playerId > 24 then
        return "|cffffffff"
    endif

    return PlayerColors.string[playerId]
endfunction

private function BuildBarText takes integer unitId, integer barLength returns string
    local player owner = UnitOwner.player[unitId]
    local string barText

    set barLength = ClampBarLength(barLength)
    set barText = "[" + GetPlayerColorString(owner) + SubString(LoadingBarText, 0, barLength) + "|r" + SubString(LoadingBarText, barLength, NUMBER_OF_TICKS) + "]"

    if ENABLE_ABILITY_NAME and RuntimeEnableAbilityName then
        set barText = AbilityName.string[unitId] + "|n" + barText
    endif

    set owner = null
    return barText
endfunction

private function UpdateTextTagPositionAndVisibility takes unit u returns nothing
    local integer unitId = GetHandleId(u)
    local texttag tag = CastingBarTag.texttag[unitId]

    if tag == null then
        set tag = null
        return
    endif

    call SetTextTagPos(tag, GetBarXOffset(u), GetUnitY(u), GetBarZOffset())

    if ENABLE_VISIBILITY then
        if not IsWithinVisibleDistance(GetUnitX(u), GetUnitY(u), GetBarZOffset()) or not IsUnitVisible(u, UnitOwner.player[unitId]) then
            call SetTextTagVisibility(tag, false)
        else
            call SetTextTagVisibility(tag, true)
        endif
    else
        call SetTextTagVisibility(tag, true)
    endif

    set tag = null
endfunction

private function EnsureTextTag takes unit u, string barText returns nothing
    local integer unitId
    local texttag tag

    if not ENABLE_CASTING_BAR or not RuntimeEnableCastingBar then
        return
    endif

    set unitId = GetHandleId(u)
    set tag = CastingBarTag.texttag[unitId]

    if tag == null then
        set tag = CreateTextTag()
        set CastingBarTag.texttag[unitId] = tag
    endif

    call SetTextTagText(tag, barText, CASTING_BAR_SIZE)
    call UpdateTextTagPositionAndVisibility(u)

    set tag = null
endfunction

private function DestroyCastingText takes integer unitId returns nothing
    local texttag tag = CastingBarTag.texttag[unitId]

    if tag != null then
        call DestroyTextTag(tag)
        call CastingBarTag.texttag.remove(unitId)
    endif

    set tag = null
endfunction

private function DisablePeriodicIfIdle takes nothing returns nothing
    if FirstOfGroup(CastingGroup) == null then
        call DisableTrigger(PeriodicTrigger)
    endif
endfunction

private function ClearCastingState takes unit u returns nothing
    local integer unitId

    if u == null then
        return
    endif

    set unitId = GetHandleId(u)
    call GroupRemoveUnit(CastingGroup, u)
    call DestroyCastingText(unitId)
    call BeginCastTime.real.remove(unitId)
    call EndCastTime.real.remove(unitId)
    call CastPhase.integer.remove(unitId)
    call PendingChannelTime.real.remove(unitId)
    call CastAbilityId.integer.remove(unitId)
    call CastAbilityLevel.integer.remove(unitId)
    call CastOrder.integer.remove(unitId)
    call AbilityName.string.remove(unitId)
    call UnitOwner.player.remove(unitId)
    call DisablePeriodicIfIdle()
endfunction

private function RememberCurrentOrder takes unit u, integer unitId returns nothing
    local integer currentOrder = GetUnitCurrentOrder(u)

    if currentOrder != 0 then
        set CastOrder.integer[unitId] = currentOrder
    endif
endfunction

private function IsStoredOrderStillActive takes unit u, integer unitId returns boolean
    local integer storedOrder = CastOrder.integer[unitId]
    local integer currentOrder = GetUnitCurrentOrder(u)

    if storedOrder == 0 then
        return currentOrder != 0
    endif

    return currentOrder == storedOrder
endfunction

private function StoreCommonCastState takes unit u, integer abilityId, integer abilityLevel returns nothing
    local integer unitId = GetHandleId(u)
    local player owner = GetOwningPlayer(u)

    set CastAbilityId.integer[unitId] = abilityId
    set CastAbilityLevel.integer[unitId] = abilityLevel
    set AbilityName.string[unitId] = GetAbilityDisplayName(abilityId, abilityLevel)
    set UnitOwner.player[unitId] = owner
    call RememberCurrentOrder(u, unitId)

    set owner = null
endfunction

private function StartVisualPhase takes unit u, integer abilityId, integer abilityLevel, integer phase, real totalTime returns nothing
    local integer unitId
    local integer initialBarLength = 0

    if u == null or abilityId == 0 or abilityLevel <= 0 or totalTime <= MIN_PHASE_TIME or IsExcludedAbility(abilityId) then
        return
    endif

    set unitId = GetHandleId(u)

    if IsUnitInGroup(u, CastingGroup) and CastAbilityId.integer[unitId] != abilityId then
        call ClearCastingState(u)
    endif

    call StoreCommonCastState(u, abilityId, abilityLevel)
    set CastPhase.integer[unitId] = phase
    set BeginCastTime.real[unitId] = 0.0
    set EndCastTime.real[unitId] = totalTime
    call PendingChannelTime.real.remove(unitId)

    if phase == CAST_PHASE_CHANNEL then
        set initialBarLength = NUMBER_OF_TICKS
    endif

    call EnsureTextTag(u, BuildBarText(unitId, initialBarLength))
    call GroupAddUnit(CastingGroup, u)
    call EnableTrigger(PeriodicTrigger)
    call DebugMsg("Started phase " + I2S(phase) + " for " + AbilityName.string[unitId] + " (" + R2S(totalTime) + "s).")
endfunction

private function QueueChannelPhase takes unit u, integer abilityId, integer abilityLevel, real totalTime returns nothing
    local integer unitId

    if u == null or abilityId == 0 or abilityLevel <= 0 or totalTime <= MIN_PHASE_TIME or IsExcludedAbility(abilityId) then
        return
    endif

    set unitId = GetHandleId(u)

    if IsUnitInGroup(u, CastingGroup) and CastAbilityId.integer[unitId] != abilityId then
        call ClearCastingState(u)
    endif

    call StoreCommonCastState(u, abilityId, abilityLevel)
    set CastPhase.integer[unitId] = CAST_PHASE_PENDING_CHANNEL
    set PendingChannelTime.real[unitId] = 0.0
    set BeginCastTime.real[unitId] = 0.0
    set EndCastTime.real[unitId] = totalTime

    call GroupAddUnit(CastingGroup, u)
    call EnableTrigger(PeriodicTrigger)
    call DebugMsg("Queued channel confirmation for " + AbilityName.string[unitId] + " (" + R2S(totalTime) + "s).")
endfunction

private function TryStartPrecast takes unit u, integer abilityId, integer abilityLevel returns nothing
    local integer unitId
    local real castTime

    if u == null or abilityId == 0 or abilityLevel <= 0 or IsExcludedAbility(abilityId) then
        return
    endif

    set unitId = GetHandleId(u)
    set castTime = GetAbilityCastTime(abilityId, abilityLevel, u)

    if castTime <= MIN_PHASE_TIME then
        return
    endif

    if IsUnitInGroup(u, CastingGroup) and CastAbilityId.integer[unitId] == abilityId then
        return
    endif

    call StartVisualPhase(u, abilityId, abilityLevel, CAST_PHASE_PRECAST, castTime)
endfunction

//============================================================================
// CORE FUNCTIONS
//============================================================================

private function OnSpellCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer abilityLevel = GetUnitAbilityLevel(u, abilityId)

    call TryStartPrecast(u, abilityId, abilityLevel)
    set u = null
endfunction

private function OnSpellChannel takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer abilityLevel = GetUnitAbilityLevel(u, abilityId)

    // Some object-data paths expose cast time earliest through SPELL_CHANNEL.
    // Duration bars are intentionally not started here; normal spells also fire
    // this event and often have non-channel duration fields.
    call TryStartPrecast(u, abilityId, abilityLevel)

    set u = null
endfunction

private function OnSpellEffect takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer abilityLevel = GetUnitAbilityLevel(u, abilityId)
    local integer unitId
    local real channelTime

    if u == null or abilityId == 0 or abilityLevel <= 0 or IsExcludedAbility(abilityId) then
        set u = null
        return
    endif

    set unitId = GetHandleId(u)
    set channelTime = GetAbilityChannelTime(abilityId, abilityLevel, u)

    if channelTime > MIN_PHASE_TIME then
        call QueueChannelPhase(u, abilityId, abilityLevel, channelTime)
    elseif IsUnitInGroup(u, CastingGroup) and CastAbilityId.integer[unitId] == abilityId and CastPhase.integer[unitId] == CAST_PHASE_PRECAST then
        call ClearCastingState(u)
    endif

    set u = null
endfunction

private function OnEndCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer unitId

    if u == null then
        set u = null
        return
    endif

    set unitId = GetHandleId(u)

    if IsUnitInGroup(u, CastingGroup) and (abilityId == 0 or CastAbilityId.integer[unitId] == abilityId) then
        call ClearCastingState(u)
    endif

    set u = null
endfunction

private function UpdatePrecastUnit takes unit u, integer unitId returns nothing
    local real elapsed = BeginCastTime.real[unitId] + UPDATE_INTERVAL
    local real totalTime = EndCastTime.real[unitId]
    local real progress
    local integer barLength

    if totalTime <= MIN_PHASE_TIME then
        call ClearCastingState(u)
        return
    endif

    set BeginCastTime.real[unitId] = elapsed

    if elapsed > totalTime + PRECAST_FINISH_GRACE then
        call ClearCastingState(u)
        return
    endif

    set progress = ClampProgress(elapsed / totalTime)
    set barLength = R2I(progress * NUMBER_OF_TICKS)
    call EnsureTextTag(u, BuildBarText(unitId, barLength))
endfunction

private function UpdatePendingChannelUnit takes unit u, integer unitId returns nothing
    local real pendingTime = PendingChannelTime.real[unitId] + UPDATE_INTERVAL

    set PendingChannelTime.real[unitId] = pendingTime

    if pendingTime < CHANNEL_CONFIRM_DELAY then
        if CastingBarTag.texttag[unitId] != null then
            call UpdateTextTagPositionAndVisibility(u)
        endif
        return
    endif

    if not IsStoredOrderStillActive(u, unitId) then
        call ClearCastingState(u)
        return
    endif

    set CastPhase.integer[unitId] = CAST_PHASE_CHANNEL
    set BeginCastTime.real[unitId] = 0.0
    call PendingChannelTime.real.remove(unitId)
    call EnsureTextTag(u, BuildBarText(unitId, NUMBER_OF_TICKS))
    call DebugMsg("Confirmed channel for " + AbilityName.string[unitId] + ".")
endfunction

private function UpdateChannelUnit takes unit u, integer unitId returns nothing
    local real elapsed = BeginCastTime.real[unitId] + UPDATE_INTERVAL
    local real totalTime = EndCastTime.real[unitId]
    local real progress
    local integer barLength

    if totalTime <= MIN_PHASE_TIME then
        call ClearCastingState(u)
        return
    endif

    set BeginCastTime.real[unitId] = elapsed

    if elapsed >= totalTime or not IsStoredOrderStillActive(u, unitId) then
        call ClearCastingState(u)
        return
    endif

    set progress = ClampProgress(1.0 - elapsed / totalTime)
    set barLength = R2I(progress * NUMBER_OF_TICKS)
    call EnsureTextTag(u, BuildBarText(unitId, barLength))
endfunction

// Helper function called for each unit in the casting group
private function UpdateSingleUnit takes nothing returns nothing
    local unit u = GetEnumUnit()
    local integer unitId
    local integer phase

    if not FallenHeroState_IsAlive(u) then
        call ClearCastingState(u)
        set u = null
        return
    endif

    set unitId = GetHandleId(u)
    set phase = CastPhase.integer[unitId]

    if phase == CAST_PHASE_PENDING_CHANNEL then
        call UpdatePendingChannelUnit(u, unitId)
    elseif phase == CAST_PHASE_CHANNEL then
        call UpdateChannelUnit(u, unitId)
    else
        call UpdatePrecastUnit(u, unitId)
    endif

    set u = null
endfunction

private function UpdateCastingBars takes nothing returns nothing
    call ForGroup(CastingGroup, function UpdateSingleUnit)
    call DisablePeriodicIfIdle()
endfunction

private function OnPeriodic takes nothing returns nothing
    call UpdateCastingBars()
endfunction

//============================================================================
// INITIALIZATION
//============================================================================

private function Init takes nothing returns nothing
    local integer i = 0

    // Initialize runtime enable states from constants
    set RuntimeEnableCastingBar = ENABLE_CASTING_BAR
    set RuntimeEnableAbilityName = ENABLE_ABILITY_NAME

    // Create Table instances
    set BeginCastTime = Table.create()
    set EndCastTime = Table.create()
    set CastPhase = Table.create()
    set PendingChannelTime = Table.create()
    set CastAbilityId = Table.create()
    set CastAbilityLevel = Table.create()
    set CastOrder = Table.create()
    set CastingBarTag = Table.create()
    set AbilityName = Table.create()
    set UnitOwner = Table.create()
    set PlayerColors = Table.create()

    // Initialize player colors
    call InitPlayerColors()

    // Build the loading bar text (filled with 'l' characters)
    loop
        exitwhen i >= NUMBER_OF_TICKS
        set LoadingBarText = LoadingBarText + "l"
        set i = i + 1
    endloop

    // Shared spell events. Cast time uses SPELL_CAST/SPELL_CHANNEL; duration
    // fields are considered only after SPELL_EFFECT and a short order check.
    call Events_RegisterPlayerUnitEvent(function OnSpellCast, EVENT_PLAYER_UNIT_SPELL_CAST)
    call Events_RegisterPlayerUnitEvent(function OnSpellChannel, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    call Events_RegisterPlayerUnitEvent(function OnSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_RegisterPlayerUnitEvent(function OnEndCast, EVENT_PLAYER_UNIT_SPELL_ENDCAST)

    // Create periodic trigger (disabled by default)
    set PeriodicTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(PeriodicTrigger, UPDATE_INTERVAL, true)
    call TriggerAddAction(PeriodicTrigger, function OnPeriodic)
    call DisableTrigger(PeriodicTrigger)
endfunction

endlibrary
