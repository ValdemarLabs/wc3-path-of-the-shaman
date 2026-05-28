//============================================================================
// Casting Bar System
//============================================================================
/*
    Author: [Valdemar]
    Version: 1.0

    Description:
    Automatically displays casting bars for channeled abilities

    Features:
    - Auto-detection of ability cast times (no manual registration needed)
    - Easy-to-maintain exclusion list for abilities that shouldn't show bars
    - Visual progress bars with ability names
    - Player-colored bars
    - Supports channeled abilities with automatic channel detection
    - Uses Table6.j by Bribe for efficient data storage

    USAGE:
    1. Ensure Table6.j is loaded before this library (it's in CoreSystems/)
    2. Add ability raw codes to IsExcludedAbility() if needed
    3. All abilities with cast time > 0 will automatically show bars

 Credits: maddeemon for initial inspiration from "CastingBar"
 */
//============================================================================

library CastingBarSystem initializer Init requires Table

//============================================================================
// CONFIGURATION
//============================================================================

globals
    // Position Mode Constants
    private constant integer POSITION_OVERHEAD = 0       // Above unit (traditional)
    private constant integer POSITION_ORIGIN = 1         // At unit center/origin
    private constant integer POSITION_SIDE = 2           // To the side of unit
    
    // Visual Settings
    private constant integer BAR_POSITION_MODE = POSITION_ORIGIN  // Choose position mode
    private constant real CASTING_BAR_SIZE = 0.0138      // Size of the casting bar text (converted from 6.00 * 0.0023)
    private constant real CASTING_NAME_SIZE = 0.00092    // Size of the ability name text (4.00 * 0.0023) 
    private constant real BAR_WIDTH_MULTIPLIER = 250.0     // Adjust this to fine-tune progress bar horizontal centering
    private constant real NAME_WIDTH_MULTIPLIER = 300.0    // Adjust this to fine-tune ability name horizontal centering
    private constant real BAR_Z_OFFSET = 50.0            // Height offset above the unit (for OVERHEAD mode)
    private constant real ORIGIN_Z_OFFSET = -50.0          // Height at unit origin (for ORIGIN mode)
    private constant real SIDE_X_OFFSET = 80.0           // Horizontal offset to side (for SIDE mode)
    private constant real SIDE_Z_OFFSET = 20.0           // Height for side position
    // Note: Ability name and casting bar are combined in a single text tag to prevent
    // position desync when camera angle changes (text tags are 2D in 3D space)
    private constant integer NUMBER_OF_TICKS = 30        // Number of 'l' characters in the bar
    private constant real UPDATE_INTERVAL = 0.10         // How often to update the bars (seconds)
    private constant real MAX_DISTANCE = 2500.0          // Maximum distance for text visibility (3D distance from camera)
    
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
    private Table UnitData              // Main table for unit data
    private Table BeginCastTime         // Stores current elapsed time per unit
    private Table EndCastTime           // Stores total cast time per unit
    private Table IsChannel             // Stores whether ability is channeled
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

private function GetWorldZ takes real x, real y returns real
    call MoveLocation(LOC, x, y)
    return GetLocationZ(LOC)
endfunction

/* unused now
private function GetAbilityCastTime takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    local real castTime = 0.0
    
    if abil != null then
        set castTime = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_CASTING_TIME, level - 1)
    endif
    
    return castTime
endfunction
*/

/* unused now
private function GetAbilityDuration takes integer abilityId, integer level, unit u returns real
    local ability abil = BlzGetUnitAbility(u, abilityId)
    local real duration = 0.0
    
    if abil != null then
        // Try hero duration first, then normal duration
        set duration = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, level - 1)
        if duration == 0.0 then
            set duration = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, level - 1)
        endif
    endif
    
    return duration
endfunction
*/

/* unused now
private function IsChanneledAbility takes integer abilityId, integer level, unit u returns boolean
    local ability abil = BlzGetUnitAbility(u, abilityId)
    local real duration = 0.0
    
    if abil != null then
        // Check if ability has duration (channeled abilities like Life Drain, Blizzard)
        set duration = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, level - 1)
        if duration == 0.0 then
            set duration = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, level - 1)
        endif
        if duration > 0.0 then
            return true
        endif
    endif
    
    return false
endfunction
*/

private function GetBarXOffset takes unit u returns real
    local real barWidth
    if BAR_POSITION_MODE == POSITION_SIDE then
        return GetUnitX(u) + SIDE_X_OFFSET
    endif
    // Center the casting bar by offsetting half its width
    // Bar has approximately 32 characters (30 ticks + 2 brackets)
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

//============================================================================
// CORE FUNCTIONS
//============================================================================

private function StartCastingBar takes unit u, integer abilId, integer lvl returns nothing
    local integer uid = GetHandleId(u)
    local string barText
    local player owner
    local integer playerId

    // Safety: don't double-add
    if IsUnitInGroup(u, CastingGroup) then
        return
    endif

    // Store ability name
    set AbilityName.string[uid] = BlzGetAbilityTooltip(abilId, lvl - 1)

    // Store owner
    set owner = GetOwningPlayer(u)
    set UnitOwner.player[uid] = owner
    set playerId = GetPlayerId(owner) + 1

    // Build initial bar text
    if IsChannel.boolean[uid] then
        // Channel starts full and drains
        set barText = "[" + PlayerColors.string[playerId] + LoadingBarText + "|r]"
    else
        // Normal cast starts empty and fills
        set barText = "[" + LoadingBarText + "]"
    endif

    // Combine ability name + bar
    if ENABLE_ABILITY_NAME and RuntimeEnableAbilityName then
        set barText = AbilityName.string[uid] + "|n" + barText
    endif

    // Create text tag
    if ENABLE_CASTING_BAR and RuntimeEnableCastingBar then
        if IsUnitVisible(u, owner) then
            set CastingBarTag.texttag[uid] = CreateTextTag()
            call SetTextTagText(CastingBarTag.texttag[uid], barText, CASTING_BAR_SIZE)
            call SetTextTagPos(CastingBarTag.texttag[uid], GetBarXOffset(u), GetUnitY(u), GetBarZOffset())

            // Initial visibility by distance
            if IsWithinVisibleDistance(GetUnitX(u), GetUnitY(u), GetBarZOffset()) then
                call SetTextTagVisibility(CastingBarTag.texttag[uid], true)
            else
                call SetTextTagVisibility(CastingBarTag.texttag[uid], false)
            endif
        else
            set CastingBarTag.texttag[uid] = null
        endif
    endif

    // Activate casting state
    call GroupAddUnit(CastingGroup, u)
    call EnableTrigger(PeriodicTrigger)

    set owner = null
endfunction

private function OnSpellCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilId = GetSpellAbilityId()
    local integer lvl = GetUnitAbilityLevel(u, abilId)
    local integer uid = GetHandleId(u)
    local ability a
    local real castPoint
    local real castTime

    if IsExcludedAbility(abilId) then
        set u = null
        return
    endif

    if IsUnitInGroup(u, CastingGroup) then
        return
    endif

    set a = BlzGetUnitAbility(u, abilId)
    if a == null then
        set u = null
        return
    endif

    set castPoint = BlzGetUnitRealField(u, UNIT_RF_CAST_POINT)
    set castTime  = BlzGetAbilityRealLevelField(a, ABILITY_RLF_CASTING_TIME, lvl - 1)

    if castPoint + castTime <= 0.0 then
        set u = null
        return
    endif

    set IsChannel.boolean[uid] = false
    set BeginCastTime.real[uid] = 0.0
    set EndCastTime.real[uid] = castPoint + castTime

    call StartCastingBar(u, abilId, lvl)

    set u = null
endfunction

private function OnSpellChannel takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilId = GetSpellAbilityId()
    local integer lvl = GetUnitAbilityLevel(u, abilId)
    local integer uid = GetHandleId(u)
    local ability a
    local real duration

    if IsExcludedAbility(abilId) then
        set u = null
        return
    endif

    set a = BlzGetUnitAbility(u, abilId)
    if a == null then
        set u = null
        return
    endif

    set duration = BlzGetAbilityRealLevelField(a, ABILITY_RLF_DURATION_HERO, lvl - 1)
    if duration == 0.0 then
        set duration = BlzGetAbilityRealLevelField(a, ABILITY_RLF_DURATION_NORMAL, lvl - 1)
    endif

    if duration <= 0.0 then
        set u = null
        return
    endif

    set IsChannel.boolean[uid] = true
    set BeginCastTime.real[uid] = 0.0
    set EndCastTime.real[uid] = duration

    call StartCastingBar(u, abilId, lvl)

    set u = null
endfunction


/* OLD function that worked
private function OnBeginCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer abilityLevel = GetUnitAbilityLevel(u, abilityId)
    local integer unitId = GetHandleId(u)
    local real castTime
    local string abilityName
    local string barText
    local player owner
    local integer playerId
    
    // Check if ability is excluded
    if IsExcludedAbility(abilityId) then
        set u = null
        return
    endif
    
    // Check if this is a channeled ability (has duration)
    set IsChannel.boolean[unitId] = IsChanneledAbility(abilityId, abilityLevel, u)
    
    // Get cast time or duration depending on ability type
    if IsChannel.boolean[unitId] then
        // For channeled abilities (Life Drain, Blizzard), use the duration field
        set castTime = GetAbilityDuration(abilityId, abilityLevel, u)
    else
        // For non-channeled abilities with cast time (Firebolt), use the casting time
        set castTime = GetAbilityCastTime(abilityId, abilityLevel, u)
    endif
    
    // If cast time/duration is 0 or less, don't show bar
    if castTime <= 0.0 then
        set u = null
        return
    endif
    
    // Check if unit is already casting (shouldn't happen, but safety check)
    if IsUnitInGroup(u, CastingGroup) then
        set u = null
        return
    endif
    
    // Initialize casting data in Tables
    set BeginCastTime.real[unitId] = 0.0
    set EndCastTime.real[unitId] = castTime
    
    // Get ability name and store it
    set abilityName = BlzGetAbilityTooltip(abilityId, abilityLevel - 1)
    set AbilityName.string[unitId] = abilityName
    
    // Get player color and store owner
    set owner = GetOwningPlayer(u)
    set playerId = GetPlayerId(owner) + 1
    set UnitOwner.player[unitId] = owner
    
    // Create initial bar text
    if IsChannel.boolean[unitId] then
        // Channeled abilities start with full colored bar (will empty as ability drains/channels)
        set barText = "[" + PlayerColors.string[playerId] + LoadingBarText + "|r]"
    else
        // Non-channeled casting abilities start with empty bar (will fill as cast charges up)
        set barText = "[" + LoadingBarText + "]"
    endif
    
    // Combine ability name and casting bar into single text tag to prevent position desync when camera angle changes
    if ENABLE_ABILITY_NAME and RuntimeEnableAbilityName then
        set barText = abilityName + "|n" + barText
    endif
    
    // Create combined text tag (ability name + casting bar)
    if ENABLE_CASTING_BAR and RuntimeEnableCastingBar then
        if IsUnitVisible(u, owner) then
            set CastingBarTag.texttag[unitId] = CreateTextTag()
            call SetTextTagText(CastingBarTag.texttag[unitId], barText, CASTING_BAR_SIZE)
            call SetTextTagPos(CastingBarTag.texttag[unitId], GetBarXOffset(u), GetUnitY(u), GetBarZOffset())
            // Set initial visibility based on distance
            if IsWithinVisibleDistance(GetUnitX(u), GetUnitY(u), GetBarZOffset()) then
                call SetTextTagVisibility(CastingBarTag.texttag[unitId], true)
            else
                call SetTextTagVisibility(CastingBarTag.texttag[unitId], false)
            endif
        else
            set CastingBarTag.texttag[unitId] = null
        endif
    endif
    
    // Add unit to casting group and enable periodic trigger
    call GroupAddUnit(CastingGroup, u)
    call EnableTrigger(PeriodicTrigger)
    if DEBUG_MODE then
        call BJDebugMsg("Added unit to casting group, enabled periodic trigger")
    endif
    
    // Cleanup
    set u = null
    set owner = null
endfunction
*/

private function OnSpellEnd takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer uid = GetHandleId(u)

    if not IsUnitInGroup(u, CastingGroup) then
        set u = null
        return
    endif

    call GroupRemoveUnit(CastingGroup, u)

    // Destroy text tags and clean up data
    if CastingBarTag.texttag[uid] != null then
        call DestroyTextTag(CastingBarTag.texttag[uid])
        call CastingBarTag.texttag.remove(uid)
    endif

    call IsChannel.boolean.remove(uid)
    call BeginCastTime.real.remove(uid)
    call EndCastTime.real.remove(uid)
    call AbilityName.string.remove(uid)
    call UnitOwner.player.remove(uid)

    if FirstOfGroup(CastingGroup) == null then
        call DisableTrigger(PeriodicTrigger)
    endif

    set u = null
endfunction

/* OLD
private function OnEndCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer unitId
    
    // Check if unit is in casting group
    if not IsUnitInGroup(u, CastingGroup) then
        set u = null
        return
    endif
    
    // Remove unit from casting group
    call GroupRemoveUnit(CastingGroup, u)
    
    // Destroy text tags and clean up data
    set unitId = GetHandleId(u)
    if CastingBarTag.texttag[unitId] != null then
        call DestroyTextTag(CastingBarTag.texttag[unitId])
        call CastingBarTag.texttag.remove(unitId)
    endif
    set AbilityName.string[unitId] = ""
    call AbilityName.remove(unitId)
    call UnitOwner.player.remove(unitId)
    
    // Disable periodic trigger if no units are casting
    if FirstOfGroup(CastingGroup) == null then
        call DisableTrigger(PeriodicTrigger)
    endif
    
    set u = null
endfunction
*/

// Helper function called for each unit in the casting group
private function UpdateSingleUnit takes nothing returns nothing
    local unit u = GetEnumUnit()
    local integer unitId = GetHandleId(u)
    local real progress
    local real barProgress
    local integer barLength
    local string barText
    local string abilityName 
    local player owner
    local integer playerId
    // Visibility check variables
    local real unitX
    local real unitY
    local real unitZ
    local real camX
    local real camY
    local real camZ
    local real dx
    local real dy
    local real dz
    local real distSq
    
    if DEBUG_MODE then
        call BJDebugMsg("Processing unit ID: " + I2S(unitId))
        call BJDebugMsg("BeginCastTime: " + R2S(BeginCastTime.real[unitId]) + " EndCastTime: " + R2S(EndCastTime.real[unitId]))
    endif
    
    // Check if casting is complete
    if BeginCastTime.real[unitId] >= EndCastTime.real[unitId] then
        if DEBUG_MODE then
            call BJDebugMsg("Casting complete, removing unit")
        endif
        // Remove unit from group
        call GroupRemoveUnit(CastingGroup, u)
        
        // Destroy text tags and clean up data
        if CastingBarTag.texttag[unitId] != null then
            call DestroyTextTag(CastingBarTag.texttag[unitId])
            call CastingBarTag.texttag.remove(unitId)
        endif
        call AbilityName.string.remove(unitId)
        call UnitOwner.player.remove(unitId)
    else
        // Update casting time
        set BeginCastTime.real[unitId] = BeginCastTime.real[unitId] + UPDATE_INTERVAL
        if DEBUG_MODE then
            call BJDebugMsg("Updated time. Progress: " + R2S(BeginCastTime.real[unitId]) + " / " + R2S(EndCastTime.real[unitId]))
        endif
        
        // Calculate progress (0.0 to 1.0)
        set progress = BeginCastTime.real[unitId] / EndCastTime.real[unitId]
        
        // For channeled abilities (Life Drain, Blizzard), reverse the progress (empty from full)
        // For non-channeled cast time abilities (Firebolt), progress fills up (empty to full)
        if IsChannel.boolean[unitId] then
            set progress = 1.0 - progress
        endif
        
        // Convert to bar length
        set barProgress = progress * NUMBER_OF_TICKS
        set barLength = R2I(barProgress)
        
        // Update text content only when bar has visible progress
        if barLength >= 1 and ENABLE_CASTING_BAR and RuntimeEnableCastingBar then
            // Get player color
            set owner = GetOwningPlayer(u)
            set playerId = GetPlayerId(owner) + 1
            
            // Create colored bar text (match maddeem's substring logic)
            set barText = "[" + PlayerColors.string[playerId] + SubString(LoadingBarText, 0, barLength) + "|r" + SubString(LoadingBarText, barLength - 1, NUMBER_OF_TICKS) + "]"
            
            // Combine with ability name if enabled
            if ENABLE_ABILITY_NAME and RuntimeEnableAbilityName then
                set barText = AbilityName.string[unitId] + "|n" + barText
            endif
            
            // Update text tag content
            call SetTextTagText(CastingBarTag.texttag[unitId], barText, CASTING_BAR_SIZE)
            
            set owner = null
        endif
        
        // Always update position and visibility with 3D distance check
        if ENABLE_CASTING_BAR and RuntimeEnableCastingBar and CastingBarTag.texttag[unitId] != null then
            call SetTextTagPos(CastingBarTag.texttag[unitId], GetBarXOffset(u), GetUnitY(u), GetBarZOffset())
            
            if ENABLE_VISIBILITY then
                set unitX = GetUnitX(u)
                set unitY = GetUnitY(u)
                set unitZ = GetWorldZ(unitX, unitY) + GetBarZOffset()
                set camX = GetCameraTargetPositionX()
                set camY = GetCameraTargetPositionY()
                set camZ = GetCameraTargetPositionZ()
                set dx = unitX - camX
                set dy = unitY - camY
                set dz = unitZ - camZ
                set distSq = dx*dx + dy*dy + dz*dz
                
                if distSq > MAX_DISTANCE * MAX_DISTANCE or not IsUnitVisible(u, UnitOwner.player[unitId]) then
                    call SetTextTagVisibility(CastingBarTag.texttag[unitId], false)
                else
                    call SetTextTagVisibility(CastingBarTag.texttag[unitId], true)
                endif
            endif
        endif
    endif
    
    set u = null
endfunction

private function UpdateCastingBars takes nothing returns nothing
    if DEBUG_MODE then
        call BJDebugMsg("UpdateCastingBars called")
    endif
    
    // Use ForGroup to iterate over all units once (like maddeem's system)
    call ForGroup(CastingGroup, function UpdateSingleUnit)
    
    // Disable trigger if no units are casting
    if FirstOfGroup(CastingGroup) == null then
        call DisableTrigger(PeriodicTrigger)
    endif
endfunction

private function OnPeriodic takes nothing returns nothing
    call UpdateCastingBars()
endfunction

//============================================================================
// INITIALIZATION
//============================================================================

private function Init takes nothing returns nothing
    local trigger beginCastTrig = CreateTrigger()
    local trigger beginTrigger = CreateTrigger()
    local trigger endTrigger = CreateTrigger()
    local integer i = 0
    
    // Initialize runtime enable states from constants
    set RuntimeEnableCastingBar = ENABLE_CASTING_BAR
    set RuntimeEnableAbilityName = ENABLE_ABILITY_NAME
    
    // Create Table instances
    set BeginCastTime = Table.create()
    set EndCastTime = Table.create()
    set IsChannel = Table.create()
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
    
    // Register events for all players
    set i = 0
    loop
        exitwhen i >= bj_MAX_PLAYER_SLOTS
        // Begin casting
        call TriggerRegisterPlayerUnitEvent(beginCastTrig, Player(i), EVENT_PLAYER_UNIT_SPELL_CAST, null)
        // Begins channeling = when unit starts channeling an ability
        call TriggerRegisterPlayerUnitEvent(beginTrigger, Player(i), EVENT_PLAYER_UNIT_SPELL_CHANNEL, null)
        // Stops casting = when unit stops/finishes casting (includes interruption)
        call TriggerRegisterPlayerUnitEvent(endTrigger, Player(i), EVENT_PLAYER_UNIT_SPELL_ENDCAST, null)
        set i = i + 1
    endloop
    
    // Set trigger actions
    call TriggerAddAction(beginCastTrig, function OnSpellCast)
    call TriggerAddAction(beginTrigger,  function OnSpellChannel)
    call TriggerAddAction(endTrigger,    function OnSpellEnd)
    
    // Create periodic trigger (disabled by default)
    set PeriodicTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(PeriodicTrigger, UPDATE_INTERVAL, true)
    call TriggerAddAction(PeriodicTrigger, function OnPeriodic)
    call DisableTrigger(PeriodicTrigger)
endfunction

endlibrary
