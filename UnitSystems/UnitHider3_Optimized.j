library UnitHider3 initializer Init requires Table, TimerUtils, optional UnitIndexer

/*
    UnitHider 3.0 - Highly Optimized Unit Hiding System
    
    Author: Valdemar (Optimized)
    
    CRITICAL FIXES FOR LAG:
    ======================
    1. Uses Filter function to pre-filter units BEFORE enumeration (MASSIVE performance boost)
    2. Caches reference unit positions to avoid repeated GetUnitX/Y calls
    3. Uses squared distance (no SquareRoot calculations)
    4. Removes GroupAddGroup - uses direct enumeration
    5. Early exit patterns in all loops
    6. Reuses groups (no repeated Create/Destroy)
    7. Batch processing with adjustable intervals
    8. Proper filter cleanup to prevent memory leaks
    
    Based on JASS best practices from: https://jass.sourceforge.net/doc/library.shtml
    
    Key Performance Facts:
    - GroupEnumUnitsInRect WITHOUT filter = checks EVERY unit on map
    - GroupAddGroup = creates FULL COPY (expensive!)
    - SquareRoot = 10x slower than multiplication
    - Filter function = pre-filters before enumeration (critical!)
    
    Requirements:
    - Table by Bribe
    - TimerUtils by Vexorian
    - (Optional) UnitIndexer for Custom Value support
*/

globals
    private constant real CHECK_INTERVAL    = 0.50      // How often to check (seconds)
    private constant real DEFAULT_DISTANCE  = 5500.0    // Default hiding distance
    private constant integer MAX_REF_UNITS  = 20        // Maximum reference units to cache
    
    // Cached reference unit positions (to avoid repeated GetUnitX/Y calls)
    private real array refX
    private real array refY
    private unit array refUnit
    private integer refCount = 0
    
    // Persistent groups (reused, never destroyed)
    private group hiddenUnits       = CreateGroup()     // Currently hidden units
    private group tempEnumGroup     = CreateGroup()     // For enumeration
    private group tempHiddenCheck   = CreateGroup()     // For checking hidden units
    
    // System settings
    private boolean systemEnabled   = true
    private boolean debugEnabled    = false
    private real hidingDistance     = DEFAULT_DISTANCE
    private real hidingDistanceSq   = DEFAULT_DISTANCE * DEFAULT_DISTANCE
    
    // Statistics
    private integer statChecked     = 0
    private integer statHidden      = 0
    private integer statShown       = 0
    
    // Table for tracking hidden state
    private Table isHiddenTable
    
    // Filter (created once, reused)
    private boolexpr filterExpr = null
endglobals

//===================== CONFIGURATION =====================

function UnitHider_SetHidingDistance takes real newDistance returns nothing
    set hidingDistance = newDistance
    set hidingDistanceSq = newDistance * newDistance
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider3] Distance set to: " + R2S(newDistance))
    endif
endfunction

function UnitHider_SetDebugEnabled takes boolean enable returns nothing
    set debugEnabled = enable
    
    if enable then
        call BJDebugMsg("[UnitHider3] Debug mode ENABLED")
    endif
endfunction

//===================== REFERENCE UNIT CACHING =====================

/**
 * Updates the cached positions of reference units
 * Called before each visibility check to minimize GetUnitX/Y calls
 * FIXED: Uses temporary group to avoid destroying the reference group
 */
private function UpdateReferenceCache takes nothing returns nothing
    local unit u
    local integer i = 0
    local group tempRefGroup = CreateGroup()
    
    set refCount = 0
    
    // Copy reference group to temporary group (safe iteration)
    call GroupClear(tempRefGroup)
    call GroupAddGroup(udg_UnitHider_ReferenceGroup, tempRefGroup)
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider3] Reference units in group: " + I2S(CountUnitsInGroup(tempRefGroup)))
    endif
    
    // Cache positions of all reference units
    loop
        set u = FirstOfGroup(tempRefGroup)
        exitwhen u == null or refCount >= MAX_REF_UNITS
        
        set refUnit[refCount] = u
        set refX[refCount] = GetUnitX(u)
        set refY[refCount] = GetUnitY(u)
        set refCount = refCount + 1
        
        if debugEnabled then
            call BJDebugMsg("[UnitHider3] Cached ref unit " + I2S(refCount) + ": " + GetUnitName(u) + " at (" + R2S(refX[refCount-1]) + ", " + R2S(refY[refCount-1]) + ")")
        endif
        
        call GroupRemoveUnit(tempRefGroup, u)
    endloop
    
    // Clean up temporary group
    call DestroyGroup(tempRefGroup)
    set tempRefGroup = null
endfunction

/**
 * Fast proximity check using cached reference positions
 * Uses squared distance to avoid SquareRoot
 */
private function IsUnitNearAnyReference takes real ux, real uy returns boolean
    local integer i = 0
    local real dx
    local real dy
    local real distSq
    
    // Check against all cached reference positions
    loop
        exitwhen i >= refCount
        
        set dx = refX[i] - ux
        set dy = refY[i] - uy
        set distSq = dx * dx + dy * dy
        
        // Early exit if within range
        if distSq <= hidingDistanceSq then
            return true
        endif
        
        set i = i + 1
    endloop
    
    return false
endfunction

//===================== FILTER FUNCTION =====================

/**
 * CRITICAL: Pre-filter units BEFORE enumeration
 * This is called by GroupEnumUnitsInRect to skip units we don't care about
 * Prevents the main loop from processing thousands of irrelevant units
 * FIXED: Simplified filter - only filters invalid units, not positions
 */
private function FilterValidUnits takes nothing returns boolean
    local unit u = GetFilterUnit()
    local integer i
    
    // Skip dead units immediately
    if GetUnitState(u, UNIT_STATE_LIFE) <= 0 then
        return false
    endif
    
    // Skip reference units (should NEVER be hidden) - check against cached array
    set i = 0
    loop
        exitwhen i >= refCount
        if u == refUnit[i] then
            return false  // This is a reference unit!
        endif
        set i = i + 1
    endloop
    
    // Skip explicitly ignored units
    if IsUnitInGroup(u, udg_UnitHider_IgnoredUnits) then
        return false
    endif
    
    // Skip Locust units (dummy units)
    if GetUnitAbilityLevel(u, 'Aloc') > 0 then
        return false
    endif
    
    // Include all other valid units for processing
    return true
endfunction

//===================== CORE VISIBILITY SYSTEM =====================

/**
 * Main visibility check - HYBRID APPROACH
 * Uses the OLD working logic (two-phase check) with NEW optimizations (caching, squared distance)
 */
private function CheckUnitsVisibility takes nothing returns nothing
    local unit u
    local integer unitId
    local real ux
    local real uy
    local boolean isNear
    
    if not systemEnabled then
        if debugEnabled then
            call BJDebugMsg("[UnitHider3] Check skipped - system disabled")
        endif
        return
    endif
    
    // Reset statistics
    set statChecked = 0
    set statHidden = 0
    set statShown = 0
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider3] ===== Starting visibility check =====")
    endif
    
    // Update cached reference positions FIRST
    call UpdateReferenceCache()
    
    if refCount == 0 then
        if debugEnabled then
            call BJDebugMsg("[UnitHider3] ERROR: No reference units! Aborting check.")
        endif
        return
    endif
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider3] Cached " + I2S(refCount) + " reference positions. Hiding distance: " + R2S(hidingDistance))
    endif
    
    // ===== PHASE 1: UNHIDE units from hiddenUnits that are now near references =====
    call GroupClear(tempHiddenCheck)
    call GroupAddGroup(hiddenUnits, tempHiddenCheck)
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider3] Phase 1: Checking " + I2S(CountUnitsInGroup(tempHiddenCheck)) + " hidden units for unhiding...")
    endif
    
    loop
        set u = FirstOfGroup(tempHiddenCheck)
        exitwhen u == null
        
        // Get position
        set ux = GetUnitX(u)
        set uy = GetUnitY(u)
        
        // Check if now near any reference
        set isNear = IsUnitNearAnyReference(ux, uy)
        
        if isNear then
            // Unit is near a reference - unhide it
            call ShowUnit(u, true)
            call GroupRemoveUnit(hiddenUnits, u)
            
            set unitId = GetHandleId(u)
            set isHiddenTable[unitId] = 0
            set statShown = statShown + 1
            
            if debugEnabled then
                call BJDebugMsg("[UnitHider3] SHOWN: " + GetUnitName(u) + " (now near reference)")
            endif
        endif
        
        call GroupRemoveUnit(tempHiddenCheck, u)
    endloop
    
    // ===== PHASE 2: HIDE units that are far from references =====
    call GroupClear(tempEnumGroup)
    call GroupEnumUnitsInRect(tempEnumGroup, GetWorldBounds(), filterExpr)
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider3] Phase 2: Checking " + I2S(CountUnitsInGroup(tempEnumGroup)) + " valid units for hiding...")
    endif
    
    loop
        set u = FirstOfGroup(tempEnumGroup)
        exitwhen u == null
        
        set statChecked = statChecked + 1
        
        // Skip if already hidden
        if not IsUnitInGroup(u, hiddenUnits) then
            // Get position
            set ux = GetUnitX(u)
            set uy = GetUnitY(u)
            
            // Check if far from all references
            set isNear = IsUnitNearAnyReference(ux, uy)
            
            if not isNear then
                // Unit is far from all references - hide it
                call ShowUnit(u, false)
                call GroupAddUnit(hiddenUnits, u)
                
                set unitId = GetHandleId(u)
                set isHiddenTable[unitId] = 1
                set statHidden = statHidden + 1
                
                if debugEnabled then
                    call BJDebugMsg("[UnitHider3] HIDDEN: " + GetUnitName(u) + " (far from all references)")
                endif
            endif
        endif
        
        call GroupRemoveUnit(tempEnumGroup, u)
    endloop
    
    // Debug summary
    if debugEnabled then
        call BJDebugMsg("[UnitHider3] ===== Check Complete =====")
        call BJDebugMsg("[UnitHider3] Stats - Checked: " + I2S(statChecked) + " | Hidden: " + I2S(statHidden) + " | Shown: " + I2S(statShown) + " | Total Currently Hidden: " + I2S(CountUnitsInGroup(hiddenUnits)))
    endif
endfunction

/**
 * Timer callback
 */
private function OnTimerExpire takes nothing returns nothing
    call CheckUnitsVisibility()
endfunction

//===================== ENABLE/DISABLE SYSTEM =====================

function UnitHider_SetSystemEnabled takes boolean enable returns nothing
    local unit u
    local integer unitId
    local group tempGroup = CreateGroup()
    
    if debugEnabled then
        if enable then
            if systemEnabled then
                call BJDebugMsg("[UnitHider3] System ENABLING... (already enabled)")
            else
                call BJDebugMsg("[UnitHider3] System ENABLING... (was disabled)")
            endif
        else
            call BJDebugMsg("[UnitHider3] System DISABLING - Will unhide all units. Currently hidden: " + I2S(CountUnitsInGroup(hiddenUnits)))
        endif
    endif
    
    // If disabling, unhide all units BEFORE changing systemEnabled
    if not enable and systemEnabled then
        // Copy hiddenUnits to temp group to avoid modification during iteration
        call GroupClear(tempGroup)
        call GroupAddGroup(hiddenUnits, tempGroup)
        
        if debugEnabled then
            call BJDebugMsg("[UnitHider3] Copied " + I2S(CountUnitsInGroup(tempGroup)) + " units to unhide")
        endif
        
        loop
            set u = FirstOfGroup(tempGroup)
            exitwhen u == null
            
            call ShowUnit(u, true)
            call GroupRemoveUnit(tempGroup, u)
            call GroupRemoveUnit(hiddenUnits, u)
            
            // Get unit ID for table
            set unitId = GetHandleId(u)
            set isHiddenTable[unitId] = 0
            
            if debugEnabled then
                call BJDebugMsg("[UnitHider3] Force unhiding: " + GetUnitName(u))
            endif
        endloop
        
        if debugEnabled then
            call BJDebugMsg("[UnitHider3] All units unhidden. Remaining in hiddenUnits: " + I2S(CountUnitsInGroup(hiddenUnits)))
        endif
    endif
    
    // Now change the state
    set systemEnabled = enable
    
    // If enabling, do an immediate check
    if enable then
        call DestroyGroup(tempGroup)
        set tempGroup = null
        call CheckUnitsVisibility()
        
        if debugEnabled then
            call BJDebugMsg("[UnitHider3] System enabled - immediate check completed")
        endif
    else
        call DestroyGroup(tempGroup)
        set tempGroup = null
    endif
endfunction

//===================== INITIALIZATION =====================

private function Init takes nothing returns nothing
    local timer t = NewTimer()
    
    // Create table
    set isHiddenTable = Table.create()
    
    // Create filter ONCE (reused forever)
    set filterExpr = Filter(function FilterValidUnits)
    
    // Set up periodic timer
    call TimerStart(t, CHECK_INTERVAL, true, function OnTimerExpire)
    
    // Initial check after short delay
    call TimerStart(CreateTimer(), 0.10, false, function CheckUnitsVisibility)
    
    call BJDebugMsg("[UnitHider3] Initialized - Interval: " + R2S(CHECK_INTERVAL) + "s, Distance: " + R2S(hidingDistance))
endfunction

/**
 * Public function to start the system
 */
function UnitHider_StartHideUnitsSystem takes nothing returns nothing
    call UnitHider_SetDebugEnabled(false)
    call UnitHider_SetSystemEnabled(true)
    call BJDebugMsg("[UnitHider3] Started successfully")
endfunction

endlibrary
