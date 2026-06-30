//============================================================================
// Follow System
//============================================================================
// Makes units follow target units with intelligent RPG mechanics
// Features:
//   - Configurable follow distance (stops following if target too far)
//   - Optional unfollow-on-attack with configurable duration
//   - Two command styles: Passive Follow or Aggressive Defend
//   - Automatic distance checking and re-issuing orders
//   - Easy add/remove API for managing followers
//   - Uses Table6.j by Bribe for efficient data storage
//
// USAGE:
//   1. Ensure Table6.j is loaded before this library (it's in CoreSystems/)
//   2. Call FollowSystem_SetFollow() to make a unit follow another
//   3. Call FollowSystem_RemoveUnit() to stop following
//
// COMMAND STYLES:
//   - FOLLOW_STYLE_PASSIVE (0): Uses Move command, unit won't auto-attack
//   - FOLLOW_STYLE_DEFEND (1): Uses Attack-Move/Defend, unit will fight
//
// API FUNCTIONS:
// Add unit to follow system
// call FollowSystem_SetFollow(unit follower, unit target, real maxDistance, boolean unfollowOnAttack, real unfollowDuration, integer commandStyle, boolean enableMapIcon, boolean enablePing)
//
// Remove from system
// call FollowSystem_RemoveUnit(unit follower)
//
// Check if following
// call FollowSystem_IsFollowing(unit follower) returns boolean
//
// Get current target
// call FollowSystem_GetFollowTarget(unit follower) returns unit
//
// Change target
// call FollowSystem_ChangeTarget(unit follower, unit newTarget)
//
/* Example Usage:
// Passive follower (won't attack, never unfollows on attack, with icon and ping)
        call FollowSystem_SetFollow(udg_dog, udg_hero, 2000.0, false, 0, FOLLOW_STYLE_PASSIVE, true, true)

// Aggressive bodyguard (will attack, unfollows for 10s when hit, no ping)
        call FollowSystem_SetFollow(udg_guard, udg_hero, 1500.0, true, 10.0, FOLLOW_STYLE_DEFEND, true, false)
*/ 

//============================================================================

library FollowSystem initializer Init requires Table, SpeciFX, IconQuery

//============================================================================
// CONFIGURATION
//============================================================================

globals
    // Command Style Constants (used in API)
    constant integer FOLLOW_STYLE_PASSIVE = 0    // Move to target (passive, won't attack)
    constant integer FOLLOW_STYLE_DEFEND = 1     // Attack-move to target (aggressive)
    
    // Update Settings
    private constant real UPDATE_INTERVAL = 0.5          // How often to update follow orders (seconds)
    private constant real ORDER_REISSUE_THRESHOLD = 100.0 // Reissue order if unit more than this far from target
    
    // Default Values (can be overridden per unit in API call)
    private constant real DEFAULT_MAX_FOLLOW_DISTANCE = 2500.0  // Stop following if target beyond this distance
    private constant real DEFAULT_UNFOLLOW_DURATION = 15.0      // Seconds to stop following after being attacked
    private constant boolean DEFAULT_UNFOLLOW_ON_ATTACK = true  // Whether units unfollow when attacked by default
    private constant integer DEFAULT_COMMAND_STYLE = FOLLOW_STYLE_DEFEND  // Default follow behavior
    
    // Distance Thresholds
    private constant real MIN_DISTANCE_TO_TARGET = 150.0  // Don't issue order if already this close
    private constant real LEASH_CHECK_DISTANCE = 50.0     // Extra buffer for leash distance check
    
    // Feature Toggles
    private constant boolean DEBUG_MODE = false            // Enable debug messages
    private constant boolean ENABLE_COLLISION_DETECTION = true  // Stop if target is dead/removed
    
    // Map Icon Settings
    private constant boolean ENABLE_MAP_ICON = true       // Show map icon on follower units
    private constant integer MAP_ICON_STYLE = bj_CAMPPINGSTYLE_CONTROL_ALLY  // Icon style for followers
    
    // Ping Settings (when unit is not following)
    private constant boolean ENABLE_PING_WHEN_NOT_FOLLOWING = true  // Ping map when unit stops following
    private constant real PING_INTERVAL = 5.0             // How often to ping (seconds)
    private constant integer PING_STYLE = bj_MINIMAPPINGSTYLE_SIMPLE  // Ping visual style
    private constant integer PING_RED = 255               // Ping color - Red component (0-255)
    private constant integer PING_GREEN = 255             // Ping color - Green component (0-255)
    private constant integer PING_BLUE = 0                // Ping color - Blue component (0-255)
    
    // Special Effect Settings (Visual Indicators)
    private constant boolean ENABLE_SPECIAL_EFFECTS = true  // Enable/disable special effects system
    
    // Stopped/Not Following Effect
    private constant string EFFECT_STOPPED_PATH = "war3mapImported\\QuestMarking.mdl"  // Effect when stopped/not following
    private constant string EFFECT_STOPPED_ATTACH = "origin"  // Attachment point for stopped effect (overhead, origin, chest, etc.)
    
    // Following Effect  
    private constant string EFFECT_FOLLOWING_PATH = "UI\\Feedback\\TargetPreSelected\\TargetPreSelected.mdl"  // Effect when actively following
    private constant string EFFECT_FOLLOWING_ATTACH = "origin"  // Attachment point for following effect
    
    // System Globals
    private group FollowGroup = CreateGroup()
    private trigger PeriodicTrigger
    private trigger DamageTrigger
    
    // Minimapicon storage (like QuestIconSystem pattern)
    private minimapicon array FollowMapIcons
    private integer MapIconIndex = 0
    
    // Data storage using Table6 (like PatrolSystem and QuestIconSystem)
    private Table FollowHash
    
    // Data keys for nested Table (each unit gets a Table with these keys)
    private constant integer KEY_TARGET = 0              // unit - target being followed
    private constant integer KEY_DISTANCE = 1            // real - max follow distance
    private constant integer KEY_DURATION = 2            // real - unfollow duration  
    private constant integer KEY_LAST_ORDER = 3          // real - last order time marker
    private constant integer KEY_UNFOLLOW_ON_ATTACK = 4  // integer - whether to unfollow (0/1)
    private constant integer KEY_COMMAND_STYLE = 5       // integer - command style
    private constant integer KEY_IS_UNFOLLOWING = 6      // integer - in unfollow state (0/1)
    private constant integer KEY_MAP_ICON = 7            // integer - map icon array index
    private constant integer KEY_LAST_PING = 8           // integer - update cycles since last ping
    private constant integer KEY_TIMER = 9               // timer - unfollow timer handle
    private constant integer KEY_OWNER = 10              // player - unit owner
    private constant integer KEY_ENABLE_PING = 11        // integer - whether ping is enabled for this unit (0/1)
    private constant integer KEY_ENABLE_MAP_ICON = 12    // integer - whether map icon is enabled for this unit (0/1)
    private constant integer KEY_EFFECT_STOPPED = 13     // effect - special effect when stopped/not following
    private constant integer KEY_EFFECT_FOLLOWING = 14   // effect - special effect when following
endglobals

//============================================================================
// PRIVATE HELPER FUNCTIONS
//============================================================================

// Convert boolean to integer (0 or 1)
private function B2I takes boolean b returns integer
    if b then
        return 1
    endif
    return 0
endfunction

// Helper function to destroy all effects for a unit (clean slate)
private function DestroyAllEffects takes Table unitData returns nothing
    local effect sfx
    
    set sfx = unitData.effect[KEY_EFFECT_STOPPED]
    if sfx != null then
        call DestroyEffect(sfx)
        set unitData.effect[KEY_EFFECT_STOPPED] = null
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: Destroyed STOPPED effect")
        endif
    endif
    
    set sfx = unitData.effect[KEY_EFFECT_FOLLOWING]
    if sfx != null then
        call DestroyEffect(sfx)
        set unitData.effect[KEY_EFFECT_FOLLOWING] = null
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: Destroyed FOLLOWING effect")
        endif
    endif
    
    set sfx = null
endfunction

private function ResumeFollowTimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer timerId = GetHandleId(t)
    local Table timerData = FollowHash.link(timerId)
    local unit follower = timerData.unit[KEY_TIMER]
    local integer unitId
    local Table unitData
    
    if follower != null and IsUnitInGroup(follower, FollowGroup) then
        set unitId = GetHandleId(follower)
        set unitData = FollowHash.link(unitId)
        set unitData[KEY_IS_UNFOLLOWING] = 0
        
        // Switch from stopped effect to following effect when resuming
        if ENABLE_SPECIAL_EFFECTS then
            call DestroyAllEffects(unitData)
            set unitData.effect[KEY_EFFECT_FOLLOWING] = AddSpecialEffectTarget(EFFECT_FOLLOWING_PATH, follower, EFFECT_FOLLOWING_ATTACH)
            call SpeciFX_MarkAsExcluded(unitData.effect[KEY_EFFECT_FOLLOWING])
            if DEBUG_MODE then
                call BJDebugMsg("FollowSystem: Created FOLLOWING effect (resume)")
            endif
        endif
        
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: " + GetUnitName(follower) + " resuming follow after timer")
        endif
    endif
    
    // Clean up timer reference
    call timerData.remove(KEY_TIMER)
    call DestroyTimer(t)
    set t = null
    set follower = null
endfunction

private function GetDistance takes unit u1, unit u2 returns real
    local real dx = GetUnitX(u1) - GetUnitX(u2)
    local real dy = GetUnitY(u1) - GetUnitY(u2)
    return SquareRoot(dx*dx + dy*dy)
endfunction

private function IsUnitValid takes unit u returns boolean
    return u != null and not IsUnitType(u, UNIT_TYPE_DEAD) and GetUnitTypeId(u) != 0
endfunction

private function IssueFollowOrder takes unit follower, unit target, integer style returns nothing
    if style == FOLLOW_STYLE_PASSIVE then
        // Passive follow: move to follow the unit (won't attack)
        call IssueTargetOrder(follower, "move", target)
    else
        // Aggressive defend: attack the target (will follow and fight)
        call IssueTargetOrder(follower, "smart", target)
    endif
endfunction

private function RemoveUnitInternal takes unit u returns nothing
    local integer unitId = GetHandleId(u)
    local Table unitData = FollowHash.link(unitId)
    local timer t
    local integer timerId
    local integer mapIconIndex
    local effect sfx
    
    // Clean up timer if it exists
    set t = unitData.timer[KEY_TIMER]
    if t != null then
        set timerId = GetHandleId(t)
        call PauseTimer(t)
        call FollowHash.link(timerId).remove(KEY_TIMER)
        call DestroyTimer(t)
    endif
    
    // Destroy map icon if it exists (using QuestIconSystem pattern)
    if ENABLE_MAP_ICON then
        set mapIconIndex = unitData[KEY_MAP_ICON]
        if mapIconIndex >= 0 and mapIconIndex < MapIconIndex then
            call IconQuery_UnregisterIcon(FollowMapIcons[mapIconIndex])
            set FollowMapIcons[mapIconIndex] = null
        endif
    endif
    
    // Clean up special effects
    if ENABLE_SPECIAL_EFFECTS then
        call DestroyAllEffects(unitData)
    endif
    
    // Remove from group
    call GroupRemoveUnit(FollowGroup, u)
    
    // Clear all data for this unit
    call unitData.flush()
    
    if DEBUG_MODE then
        call BJDebugMsg("FollowSystem: Removed unit " + GetUnitName(u) + " from system")
    endif
    
    set t = null
endfunction

//============================================================================
// PUBLIC API FUNCTIONS
//============================================================================

// Main function to add a unit to the follow system
// Parameters:
//   follower: The unit that will follow
//   target: The unit to follow
//   maxDistance: Max distance before stopping follow (use 0 for default)
//   unfollowOnAttack: Whether to stop following when attacked
//   unfollowDuration: How long to stop following after attack (use 0 for default)
//   commandStyle: FOLLOW_STYLE_PASSIVE or FOLLOW_STYLE_DEFEND
//   enableMapIcon: Whether to show minimap icon on this unit
//   enablePing: Whether to ping when unit is not following
function FollowSystem_SetFollow takes unit follower, unit target, real maxDistance, boolean unfollowOnAttack, real unfollowDuration, integer commandStyle, boolean enableMapIcon, boolean enablePing returns nothing
    local integer unitId
    local integer mapIconIndex
    local minimapicon mapIcon
    local Table unitData
    
    // Validation
    if not IsUnitValid(follower) or not IsUnitValid(target) then
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: Invalid unit(s) passed to SetFollow")
        endif
        return
    endif
    
    // Can't follow self
    if follower == target then
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: Unit cannot follow itself")
        endif
        return
    endif
    
    set unitId = GetHandleId(follower)
    
    // Use defaults if values are 0 or invalid
    if maxDistance <= 0.0 then
        set maxDistance = DEFAULT_MAX_FOLLOW_DISTANCE
    endif
    if unfollowDuration <= 0.0 then
        set unfollowDuration = DEFAULT_UNFOLLOW_DURATION
    endif
    
    // Store all data in Table6 (cache reference for performance)
    set unitData = FollowHash.link(unitId)
    set unitData.unit[KEY_TARGET] = target
    set unitData.real[KEY_DISTANCE] = maxDistance
    set unitData[KEY_UNFOLLOW_ON_ATTACK] = B2I(unfollowOnAttack)
    set unitData.real[KEY_DURATION] = unfollowDuration
    set unitData[KEY_COMMAND_STYLE] = commandStyle
    set unitData[KEY_IS_UNFOLLOWING] = 0
    set unitData.real[KEY_LAST_ORDER] = 0.0
    set unitData.player[KEY_OWNER] = GetOwningPlayer(follower)
    set unitData[KEY_LAST_PING] = 0
    set unitData[KEY_ENABLE_PING] = B2I(enablePing)
    set unitData[KEY_ENABLE_MAP_ICON] = B2I(enableMapIcon)

    if ENABLE_MAP_ICON then
        set mapIconIndex = unitData[KEY_MAP_ICON]
        if mapIconIndex >= 0 and mapIconIndex < MapIconIndex and FollowMapIcons[mapIconIndex] != null then
            call IconQuery_UnregisterIcon(FollowMapIcons[mapIconIndex])
            set FollowMapIcons[mapIconIndex] = null
        endif
    endif
    
    // Create map icon if enabled (using QuestIconSystem pattern)
    if ENABLE_MAP_ICON and enableMapIcon then
        set mapIcon = IconQuery_RegisterCompanionFollowerUnitIcon(follower)
        if mapIcon != null then
            set FollowMapIcons[MapIconIndex] = mapIcon
            set unitData[KEY_MAP_ICON] = MapIconIndex
            set MapIconIndex = MapIconIndex + 1
        else
            set unitData[KEY_MAP_ICON] = -1
        endif
    else
        set unitData[KEY_MAP_ICON] = -1
    endif
    
    // Initialize special effects storage (null by default)
    set unitData.effect[KEY_EFFECT_STOPPED] = null
    set unitData.effect[KEY_EFFECT_FOLLOWING] = null
    
    // Add to group if not already in it
    if not IsUnitInGroup(follower, FollowGroup) then
        call GroupAddUnit(FollowGroup, follower)
    endif
    
    // Issue initial follow order
    call IssueFollowOrder(follower, target, commandStyle)
    
    // Create initial following effect
    if ENABLE_SPECIAL_EFFECTS then
        set unitData.effect[KEY_EFFECT_FOLLOWING] = AddSpecialEffectTarget(EFFECT_FOLLOWING_PATH, follower, EFFECT_FOLLOWING_ATTACH)
        call SpeciFX_MarkAsExcluded(unitData.effect[KEY_EFFECT_FOLLOWING])
    endif
    
    // Enable periodic trigger
    call EnableTrigger(PeriodicTrigger)
    
    if DEBUG_MODE then
        call BJDebugMsg("FollowSystem: " + GetUnitName(follower) + " now following " + GetUnitName(target))
    endif
endfunction

// Remove a unit from the follow system
function FollowSystem_RemoveUnit takes unit u returns nothing
    if IsUnitInGroup(u, FollowGroup) then
        call RemoveUnitInternal(u)
        
        // Disable trigger if no units are following
        if FirstOfGroup(FollowGroup) == null then
            call DisableTrigger(PeriodicTrigger)
        endif
    endif
endfunction

// Check if a unit is currently following
function FollowSystem_IsFollowing takes unit u returns boolean
    return IsUnitInGroup(u, FollowGroup)
endfunction

// Get the target a unit is following (returns null if not following)
function FollowSystem_GetFollowTarget takes unit u returns unit
    if IsUnitInGroup(u, FollowGroup) then
        return FollowHash.link(GetHandleId(u)).unit[KEY_TARGET]
    endif
    return null
endfunction

// Change the follow target for an existing follower
function FollowSystem_ChangeTarget takes unit follower, unit newTarget returns nothing
    local integer unitId
    local Table unitData
    
    if not IsUnitInGroup(follower, FollowGroup) then
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: Unit is not in follow system")
        endif
        return
    endif
    
    if not IsUnitValid(newTarget) then
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: Invalid new target")
        endif
        return
    endif
    
    set unitId = GetHandleId(follower)
    set unitData = FollowHash.link(unitId)
    
    // Update target
    set unitData.unit[KEY_TARGET] = newTarget
    
    // Issue new follow order if not currently unfollowing
    if unitData[KEY_IS_UNFOLLOWING] == 0 then
        call IssueFollowOrder(follower, newTarget, unitData[KEY_COMMAND_STYLE])
    endif
    
    if DEBUG_MODE then
        call BJDebugMsg("FollowSystem: Changed follow target for " + GetUnitName(follower))
    endif
endfunction

//============================================================================
// CORE UPDATE LOGIC
//============================================================================

private function UpdateSingleFollower takes nothing returns nothing
    local unit follower = GetEnumUnit()
    local integer unitId = GetHandleId(follower)
    local Table unitData = FollowHash.link(unitId)
    local unit target
    local real distance
    local real maxDistance
    local integer lastPingCycles
    local integer pingCyclesNeeded
    local location pingLoc
    
    set target = unitData.unit[KEY_TARGET]
    
    // Calculate how many update cycles needed between pings
    set pingCyclesNeeded = R2I(PING_INTERVAL / UPDATE_INTERVAL)
    
    // Validate follower and target
    if not IsUnitValid(follower) then
        call RemoveUnitInternal(follower)
        set follower = null
        set target = null
        return
    endif
    
    if not IsUnitValid(target) then
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: Target invalid, removing follower")
        endif
        call RemoveUnitInternal(follower)
        set follower = null
        set target = null
        return
    endif
    
    // Check if unit is in unfollow state (timer will clear this flag)
    if unitData[KEY_IS_UNFOLLOWING] != 0 then
        // Ensure ONLY stopped effect is active
        if ENABLE_SPECIAL_EFFECTS then
            if unitData.effect[KEY_EFFECT_STOPPED] == null then
                call DestroyAllEffects(unitData)
                set unitData.effect[KEY_EFFECT_STOPPED] = AddSpecialEffectTarget(EFFECT_STOPPED_PATH, follower, EFFECT_STOPPED_ATTACH)
                call SpeciFX_MarkAsExcluded(unitData.effect[KEY_EFFECT_STOPPED])
                if DEBUG_MODE then
                    call BJDebugMsg("FollowSystem: Created STOPPED effect (unfollowing)")
                endif
            endif
        endif
        
        // Still in unfollow state, ping if enabled
        if ENABLE_PING_WHEN_NOT_FOLLOWING and unitData[KEY_ENABLE_PING] != 0 then
            set lastPingCycles = unitData[KEY_LAST_PING]
            set lastPingCycles = lastPingCycles + 1
            
            // Ping at intervals
            if lastPingCycles >= pingCyclesNeeded then
                set pingLoc = Location(GetUnitX(follower), GetUnitY(follower))
                call PingMinimapLocForForceEx(GetPlayersAll(), pingLoc, 1.0, PING_STYLE, PING_RED, PING_GREEN, PING_BLUE)
                call RemoveLocation(pingLoc)
                set lastPingCycles = 0
                set pingLoc = null
            endif
            set unitData[KEY_LAST_PING] = lastPingCycles
        endif
        set follower = null
        set target = null
        return
    endif
    
    // Calculate distance to target
    set distance = GetDistance(follower, target)
    set maxDistance = unitData.real[KEY_DISTANCE]
    
    // Check if target is beyond max follow distance (leash broken)
    // If too far, don't issue movement orders but keep unit in system
    if distance > maxDistance then
        if DEBUG_MODE then
            call BJDebugMsg("FollowSystem: " + GetUnitName(follower) + " too far from target (distance: " + R2S(distance) + "), not moving")
        endif
        // Stop the unit and wait for target to come back in range
        call IssueImmediateOrder(follower, "stop")
        
        // Ensure ONLY stopped effect is active
        if ENABLE_SPECIAL_EFFECTS then
            if unitData.effect[KEY_EFFECT_STOPPED] == null then
                call DestroyAllEffects(unitData)
                set unitData.effect[KEY_EFFECT_STOPPED] = AddSpecialEffectTarget(EFFECT_STOPPED_PATH, follower, EFFECT_STOPPED_ATTACH)
                call SpeciFX_MarkAsExcluded(unitData.effect[KEY_EFFECT_STOPPED])
                if DEBUG_MODE then
                    call BJDebugMsg("FollowSystem: Created STOPPED effect (too far)")
                endif
            endif
        endif
        
        // Ping if enabled at intervals
        if ENABLE_PING_WHEN_NOT_FOLLOWING and unitData[KEY_ENABLE_PING] != 0 then
            set lastPingCycles = unitData[KEY_LAST_PING]
            set lastPingCycles = lastPingCycles + 1
            
            // Ping at intervals
            if lastPingCycles >= pingCyclesNeeded then
                set pingLoc = Location(GetUnitX(follower), GetUnitY(follower))
                call PingMinimapLocForForceEx(GetPlayersAll(), pingLoc, 1.0, PING_STYLE, PING_RED, PING_GREEN, PING_BLUE)
                call RemoveLocation(pingLoc)
                set lastPingCycles = 0
                set pingLoc = null
            endif
            set unitData[KEY_LAST_PING] = lastPingCycles
        endif
        
        set follower = null
        set target = null
        return
    endif
    
    // Ensure ONLY following effect is active (unit is in range and following)
    if ENABLE_SPECIAL_EFFECTS then
        if unitData.effect[KEY_EFFECT_FOLLOWING] == null then
            call DestroyAllEffects(unitData)
            set unitData.effect[KEY_EFFECT_FOLLOWING] = AddSpecialEffectTarget(EFFECT_FOLLOWING_PATH, follower, EFFECT_FOLLOWING_ATTACH)
            call SpeciFX_MarkAsExcluded(unitData.effect[KEY_EFFECT_FOLLOWING])
            if DEBUG_MODE then
                call BJDebugMsg("FollowSystem: Created FOLLOWING effect (in range)")
            endif
        endif
    endif
    
    // Only issue new order if:
    // 1. Unit is far enough from target to need repositioning
    // 2. Enough time has passed since last order (prevent order spam)
    if distance > MIN_DISTANCE_TO_TARGET then
        if distance > ORDER_REISSUE_THRESHOLD or unitData.real[KEY_LAST_ORDER] == 0.0 then
            call IssueFollowOrder(follower, target, unitData[KEY_COMMAND_STYLE])
            set unitData.real[KEY_LAST_ORDER] = 1.0  // Mark that order was issued
            set unitData[KEY_LAST_PING] = 0  // Reset ping counter when following
        endif
    endif
    
    set follower = null
    set target = null
endfunction

private function OnPeriodic takes nothing returns nothing
    // Update all followers
    call ForGroup(FollowGroup, function UpdateSingleFollower)
    
    // Disable trigger if no units are following
    if FirstOfGroup(FollowGroup) == null then
        call DisableTrigger(PeriodicTrigger)
    endif
endfunction

//============================================================================
// DAMAGE EVENT HANDLING (using DamageEngine)
//============================================================================

private function OnDamage takes nothing returns nothing
    local unit damaged = udg_DamageEventTarget
    local integer unitId
    local Table unitData
    local timer t
    local real duration
    local integer timerId
    
    // Check if damaged unit is in follow system
    if damaged == null or not IsUnitInGroup(damaged, FollowGroup) then
        set damaged = null
        return
    endif
    
    set unitId = GetHandleId(damaged)
    set unitData = FollowHash.link(unitId)
    
    // Check if this unit has unfollow-on-attack enabled
    if unitData[KEY_UNFOLLOW_ON_ATTACK] == 0 then
        set damaged = null
        return
    endif
    
    // Enter or extend unfollow state
    set unitData[KEY_IS_UNFOLLOWING] = 1
    set duration = unitData.real[KEY_DURATION]
    
    // Clean up existing timer if present
    set t = unitData.timer[KEY_TIMER]
    if t != null then
        set timerId = GetHandleId(t)
        call PauseTimer(t)
        call FollowHash.link(timerId).remove(KEY_TIMER)
        call DestroyTimer(t)
    endif
    
    // Create new timer
    set t = CreateTimer()
    set timerId = GetHandleId(t)
    
    set unitData.timer[KEY_TIMER] = t
    set FollowHash.link(timerId).unit[KEY_TIMER] = damaged
    call TimerStart(t, duration, false, function ResumeFollowTimerExpire)
    
    // Stop current order
    call IssueImmediateOrder(damaged, "stop")
    
    if DEBUG_MODE then
        call BJDebugMsg("FollowSystem: " + GetUnitName(damaged) + " damaged, unfollowing for " + R2S(duration) + " seconds")
    endif
    
    set damaged = null
    set t = null
endfunction

//============================================================================
// INITIALIZATION
//============================================================================

private function Init takes nothing returns nothing
    // Initialize Table6 data structure
    set FollowHash = Table.create()
    
    // Create periodic trigger (disabled by default)
    set PeriodicTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(PeriodicTrigger, UPDATE_INTERVAL, true)
    call TriggerAddAction(PeriodicTrigger, function OnPeriodic)
    call DisableTrigger(PeriodicTrigger)
    
    // Register with DamageEngine (like PatrolSystem)
    set DamageTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(DamageTrigger, "udg_DamageEvent", EQUAL, 1.00)
    call TriggerAddAction(DamageTrigger, function OnDamage)
    
    if DEBUG_MODE then
        call BJDebugMsg("FollowSystem: Initialized with DamageEngine")
    endif
endfunction

endlibrary
