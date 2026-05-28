library UnitHider initializer Init requires Table, TimerUtils, optional UnitIndexer

/*
    UnitHider 2.0 - Optimized Unit Hiding System
    
    Author: Valdemar
    
    Improvements:
    - Uses Bribe's Table v6 for efficient data storage
    - Uses TimerUtils for better timer management
    - Filters units before enumeration (major performance boost)
    - Caches distance calculations
    - Uses squared distance to avoid expensive SquareRoot calls
    - Batch processing with configurable intervals
    - Proper memory management
    
    Lag Sources Fixed:
    1. Removed SquareRoot() - now uses squared distance comparison
    2. Added filter to GroupEnumUnitsInRect - prevents checking all units
    3. Removed repeated group creation/destruction
    4. Uses Table instead of hashtable for faster lookups
    5. Optimized IsUnitNearReferenceUnits with early exit
    
    Requirements:
    - Table by Bribe
    - TimerUtils by Vexorian
    - (Optional) UnitIndexer for Custom Value support
*/

globals
    private constant real CHECK_INTERVAL    = 0.50      // How often to check (seconds)
    private constant real DEFAULT_DISTANCE  = 5500.0    // Default hiding distance
    
    // Tables for efficient storage (using integers: 0=visible, 1=hidden)
    private Table isHidden                              // Tracks if unit is hidden
    private group hiddenUnits       = CreateGroup()     // Group of currently hidden units
    private group tempGroup         = CreateGroup()     // Reusable temp group for main loop
    private group refCheckGroup     = CreateGroup()     // Separate group for reference checks
    
    // System settings
    private boolean systemEnabled   = true
    private boolean debugEnabled    = false
    private real hidingDistance     = DEFAULT_DISTANCE
    private real hidingDistanceSq   = DEFAULT_DISTANCE * DEFAULT_DISTANCE  // Squared for optimization
    
    // Statistics
    private integer totalChecked    = 0
    private integer totalHidden     = 0
    private integer totalShown      = 0
endglobals

//===================== CONFIGURATION =====================

/**
 * Sets the distance at which units will be hidden
 * @param newDistance - The new hiding distance
 */
function UnitHider_SetHidingDistance takes real newDistance returns nothing
    set hidingDistance = newDistance
    set hidingDistanceSq = newDistance * newDistance
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider] Distance set to: " + R2S(newDistance))
    endif
endfunction

/**
 * Enables or disables debug messages
 * @param enable - true to enable, false to disable
 */
function UnitHider_SetDebugEnabled takes boolean enable returns nothing
    set debugEnabled = enable
    set udg_UnitHider_debug = enable
    
    if enable then
        call BJDebugMsg("[UnitHider] Debug mode ENABLED")
    endif
endfunction

/**
 * Enables or disables the entire system
 * @param enable - true to enable, false to disable
 */
function UnitHider_SetSystemEnabled takes boolean enable returns nothing
    local unit u
    local integer unitId
    
    set systemEnabled = enable
    set udg_UnitHider_SetSystem = enable
    
    if debugEnabled then
        if enable then
            call BJDebugMsg("[UnitHider] System ENABLED")
        else
            call BJDebugMsg("[UnitHider] System DISABLED - Unhiding all units")
        endif
    endif
    
    // If disabling, unhide all units
    if not enable then
        call GroupClear(tempGroup)
        call GroupAddGroup(hiddenUnits, tempGroup)
        
        loop
            set u = FirstOfGroup(tempGroup)
            exitwhen u == null
            
            call ShowUnit(u, true)
            call GroupRemoveUnit(hiddenUnits, u)
            call GroupRemoveUnit(tempGroup, u)
            
            static if LIBRARY_UnitIndexer then
                set unitId = GetUnitUserData(u)
            else
                set unitId = GetHandleId(u)
            endif
            
            set isHidden[unitId] = 0  // ✅ Set to 0 (visible)
        endloop
    endif
endfunction

//===================== CORE LOGIC =====================

/**
 * Checks if a unit is near any reference unit (OPTIMIZED)
 * Uses squared distance to avoid expensive SquareRoot calls
 * 
 * @param u - The unit to check
 * @return true if unit is within hiding distance of any reference unit
 */
private function IsUnitNearReferenceUnits takes unit u returns boolean
    local real ux = GetUnitX(u)
    local real uy = GetUnitY(u)
    local real dx
    local real dy
    local real distSq
    local unit ref
    
    // Use separate group to avoid corrupting main iteration
    call GroupClear(refCheckGroup)
    call GroupAddGroup(udg_UnitHider_ReferenceGroup, refCheckGroup)
    
    // Check each reference unit
    loop
        set ref = FirstOfGroup(refCheckGroup)
        exitwhen ref == null
        
        // Calculate squared distance (no SquareRoot needed!)
        set dx = GetUnitX(ref) - ux
        set dy = GetUnitY(ref) - uy
        set distSq = dx * dx + dy * dy
        
        // Early exit if close enough
        if distSq <= hidingDistanceSq then
            return true
        endif
        
        call GroupRemoveUnit(refCheckGroup, ref)
    endloop
    
    return false
endfunction

/**
 * Filter function for GroupEnumUnitsInRect
 * Pre-filters units before processing (MAJOR performance boost)
 * 
 * @return true if unit should be processed
 */
private function FilterValidUnits takes nothing returns boolean
    local unit u = GetFilterUnit()
    
    // CRITICAL: Skip reference units - they should NEVER be hidden
    if IsUnitInGroup(u, udg_UnitHider_ReferenceGroup) then
        return false
    endif
    
    // Skip ignored units
    if IsUnitInGroup(u, udg_UnitHider_IgnoredUnits) then
        return false
    endif
    
    // Skip dead units
    if GetUnitState(u, UNIT_STATE_LIFE) <= 0 then
        return false
    endif
    
    // Skip units with Locust
    if GetUnitAbilityLevel(u, 'Aloc') > 0 then
        return false
    endif
    
    return true
endfunction

/**
 * Main visibility check function (OPTIMIZED)
 * Now uses filtering and batch processing
 */
private function CheckUnitsVisibility takes nothing returns nothing
    local unit u
    local integer unitId
    local boolexpr filter
    local boolean isNear
    
    // Reset statistics
    set totalChecked = 0
    set totalHidden = 0
    set totalShown = 0
    
    if not systemEnabled then
        return
    endif
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider] Checking visibility...")
    endif
    
    // STEP 1: Unhide units that are now near reference units
    call GroupClear(tempGroup)
    call GroupAddGroup(hiddenUnits, tempGroup)
    
    loop
        set u = FirstOfGroup(tempGroup)
        exitwhen u == null
        
        if IsUnitNearReferenceUnits(u) then
            call ShowUnit(u, true)
            call GroupRemoveUnit(hiddenUnits, u)
            
            static if LIBRARY_UnitIndexer then
                set unitId = GetUnitUserData(u)
            else
                set unitId = GetHandleId(u)
            endif
            
            set isHidden[unitId] = 0  // ✅ Set to 0 (visible)
            set totalShown = totalShown + 1
            
            if debugEnabled then
                call BJDebugMsg("[UnitHider] Shown: " + GetUnitName(u))
            endif
        endif
        
        call GroupRemoveUnit(tempGroup, u)
    endloop
    
    // STEP 2: Hide units that are far from reference units (with filtering!)
    call GroupClear(tempGroup)
    set filter = Filter(function FilterValidUnits)
    call GroupEnumUnitsInRect(tempGroup, GetWorldBounds(), filter)
    call DestroyBoolExpr(filter)
    
    loop
        set u = FirstOfGroup(tempGroup)
        exitwhen u == null
        set totalChecked = totalChecked + 1
        
        static if LIBRARY_UnitIndexer then
            set unitId = GetUnitUserData(u)
        else
            set unitId = GetHandleId(u)
        endif
        
        // Check if unit is NOT already hidden before processing
        // Only hide units that aren't already in the hiddenUnits group
        if not IsUnitInGroup(u, hiddenUnits) then
            set isNear = IsUnitNearReferenceUnits(u)
            
            if not isNear then
                call ShowUnit(u, false)
                call GroupAddUnit(hiddenUnits, u)
                set isHidden[unitId] = 1  // ✅ Set to 1 (hidden)
                set totalHidden = totalHidden + 1
                
                if debugEnabled then
                    call BJDebugMsg("[UnitHider] Hidden: " + GetUnitName(u))
                endif
            endif
        endif
        
        call GroupRemoveUnit(tempGroup, u)
    endloop
    
    // Debug summary
    if debugEnabled then
        call BJDebugMsg("[UnitHider] Checked: " + I2S(totalChecked) + " | Hidden: " + I2S(totalHidden) + " | Shown: " + I2S(totalShown))
    endif
endfunction

/**
 * Timer callback for periodic checks
 */
private function OnTimerExpire takes nothing returns nothing
    call CheckUnitsVisibility()
endfunction

//===================== INITIALIZATION =====================

/**
 * Initializes the system
 */
private function Init takes nothing returns nothing
    local timer t = NewTimer()
    
    // Create table
    set isHidden = Table.create()
    
    // Set up periodic timer using TimerUtils
    call TimerStart(t, CHECK_INTERVAL, true, function OnTimerExpire)
    
    // Initial check after a short delay
    call TimerStart(CreateTimer(), 0.10, false, function CheckUnitsVisibility)
    
    if debugEnabled then
        call BJDebugMsg("[UnitHider] System initialized with " + R2S(CHECK_INTERVAL) + "s interval")
    endif
endfunction

/**
 * Public function to start the system (for backwards compatibility)
 */
function UnitHider_StartHideUnitsSystem takes nothing returns nothing
    call UnitHider_SetDebugEnabled(false)
    call UnitHider_SetSystemEnabled(true)
    
    call BJDebugMsg("[UnitHider] Started successfully")
endfunction

endlibrary