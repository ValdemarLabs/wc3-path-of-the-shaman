/**
    UnitHider4

    Author: Valdemar
    Version: 4.0.0

    Description:
    Hides distant units in bounded batches so the work is spread across frames.
    Player-controlled and registered AI heroes, registered companions and pets,
    active combatants, and explicit reference units reveal nearby units. Every
    hero is protected from hiding. The system only shows units that it hid.

    Credits:
    - UnitHider 1.0 for the reliable owned-hidden-unit model
    - UnitHider3 for cached positions and squared-distance comparisons
    - Bribe's Unit Event 2.5.3.2 for the indexed unit registry

    How to install:
    Import after Unit Event and FallenHeroState. Keep the GUI variables
    UnitHider_ReferenceGroup, UnitHider_IgnoredUnits, UnitHider_ReferenceUnits,
    UnitHider_SetSystem, and UnitHider_debug. Replace earlier UnitHider versions
    and disable their GUI timers/toggles. Change state through this library's API;
    the two GUI booleans mirror state but direct assignments do not control it.

    API:
    - UnitHider_StartHideUnitsSystem()
    - UnitHider_SetSystemEnabled(enable)
    - UnitHider_SetDebugEnabled(enable)
    - UnitHider_SetHidingDistance(distance)
    - UnitHider_SetUnhidingDistance(distance)
    - UnitHider_RegisterReference(whichUnit)
    - UnitHider_UnregisterReference(whichUnit)
    - UnitHider_SetUnitIgnored(whichUnit, ignored)
    - UnitHider_IsUnitHiddenBySystem(whichUnit) -> boolean
    - UnitHider_Refresh()

**/
library UnitHider4 initializer Init requires FallenHeroState, optional AI

globals
    // Configuration
    private constant real UnitHider4_TICK_INTERVAL = 0.03125
    private constant integer UnitHider4_UNITS_PER_TICK = 128
    private constant integer UnitHider4_HIDDEN_UNITS_PER_TICK = 256
    private constant integer UnitHider4_REFERENCE_REFRESH_TICKS = 4
    private constant integer UnitHider4_MAX_REFERENCES = 8190
    private constant real UnitHider4_DEFAULT_HIDE_DISTANCE = 5500.00
    private constant real UnitHider4_DEFAULT_SHOW_DISTANCE = 5200.00

    // Visibility owned by UnitHider4. Foreign hidden units are never added here.
    private group UnitHider4_HiddenUnits = CreateGroup()
    private group UnitHider4_AutomaticReferences = CreateGroup()
    private group UnitHider4_RegisteredReferences = CreateGroup()
    private group UnitHider4_ReferenceCacheGroup = CreateGroup()
    private real array UnitHider4_ReferenceX
    private real array UnitHider4_ReferenceY
    private integer UnitHider4_ReferenceCount = 0

    private timer UnitHider4_Timer = CreateTimer()
    private boolean UnitHider4_Enabled = true
    private boolean UnitHider4_Debug = false
    private boolean UnitHider4_InternalShow = false
    private boolean UnitHider4_WasInCinematic = false
    private integer UnitHider4_ScanIndex = 1
    private integer UnitHider4_HiddenScanIndex = 0
    private integer UnitHider4_RefreshTick = UnitHider4_REFERENCE_REFRESH_TICKS
    private real UnitHider4_HideDistance = UnitHider4_DEFAULT_HIDE_DISTANCE
    private real UnitHider4_HideDistanceSq = UnitHider4_DEFAULT_HIDE_DISTANCE * UnitHider4_DEFAULT_HIDE_DISTANCE
    private real UnitHider4_ShowDistance = UnitHider4_DEFAULT_SHOW_DISTANCE
    private real UnitHider4_ShowDistanceSq = UnitHider4_DEFAULT_SHOW_DISTANCE * UnitHider4_DEFAULT_SHOW_DISTANCE

    // Statistics for debug summaries, reset after each complete indexed sweep.
    private integer UnitHider4_Checked = 0
    private integer UnitHider4_Hidden = 0
    private integer UnitHider4_Shown = 0
endglobals

private function UnitHider4_IsLegacyCompanionReference takes unit whichUnit returns boolean
    local integer unitId

    if whichUnit == null then
        return false
    endif
    set unitId = GetUnitUserData(whichUnit)
    if unitId <= 0 or udg_UnitHider_ReferenceUnits[unitId] != whichUnit then
        return false
    endif
    return (udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group)) or (udg_TamedUnits != null and IsUnitInGroup(whichUnit, udg_TamedUnits))
endfunction

private function UnitHider4_IsTrackedHero takes unit whichUnit returns boolean
    local integer unitId

    if whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return false
    endif
    if GetPlayerController(GetOwningPlayer(whichUnit)) == MAP_CONTROL_USER then
        return true
    endif
    set unitId = GetUnitUserData(whichUnit)
    if unitId > 0 and udg_UnitHider_ReferenceUnits[unitId] == whichUnit then
        return true
    endif
    static if LIBRARY_AI then
        if AI_GetInstance(whichUnit) > 0 and AI_IsAlive(whichUnit) then
            return true
        endif
    endif
    return false
endfunction

private function UnitHider4_IsActiveCombatUnit takes unit whichUnit returns boolean
    local integer unitId

    if whichUnit == null then
        return false
    endif
    set unitId = GetUnitUserData(whichUnit)
    return unitId > 0 and (udg_GCSM_UnitInCombat[unitId] or udg_UnitIsCasting[unitId])
endfunction

private function UnitHider4_IsAutomaticReference takes unit whichUnit returns boolean
    if not FallenHeroState_IsAlive(whichUnit) or IsUnitLoaded(whichUnit) then
        return false
    endif
    return UnitHider4_IsTrackedHero(whichUnit) or UnitHider4_IsLegacyCompanionReference(whichUnit) or UnitHider4_IsActiveCombatUnit(whichUnit)
endfunction

private function UnitHider4_UpdateAutomaticReference takes unit whichUnit returns boolean
    local boolean isReference = UnitHider4_IsAutomaticReference(whichUnit)

    if isReference then
        call GroupAddUnit(UnitHider4_AutomaticReferences, whichUnit)
    else
        call GroupRemoveUnit(UnitHider4_AutomaticReferences, whichUnit)
    endif
    return isReference
endfunction

private function UnitHider4_CacheReferenceGroup takes group sourceGroup returns nothing
    local integer index = 0
    local integer count = BlzGroupGetSize(sourceGroup)
    local unit whichUnit

    loop
        exitwhen index >= count or UnitHider4_ReferenceCount >= UnitHider4_MAX_REFERENCES
        set whichUnit = BlzGroupUnitAt(sourceGroup, index)
        if FallenHeroState_IsAlive(whichUnit) and not IsUnitLoaded(whichUnit) and not IsUnitHidden(whichUnit) then
            set UnitHider4_ReferenceX[UnitHider4_ReferenceCount] = GetUnitX(whichUnit)
            set UnitHider4_ReferenceY[UnitHider4_ReferenceCount] = GetUnitY(whichUnit)
            set UnitHider4_ReferenceCount = UnitHider4_ReferenceCount + 1
        endif
        set index = index + 1
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_UpdateReferenceCache takes nothing returns nothing
    call GroupClear(UnitHider4_ReferenceCacheGroup)
    call GroupAddGroup(UnitHider4_AutomaticReferences, UnitHider4_ReferenceCacheGroup)
    call GroupAddGroup(UnitHider4_RegisteredReferences, UnitHider4_ReferenceCacheGroup)
    call GroupAddGroup(udg_UnitHider_ReferenceGroup, UnitHider4_ReferenceCacheGroup)

    set UnitHider4_ReferenceCount = 0
    call UnitHider4_CacheReferenceGroup(UnitHider4_ReferenceCacheGroup)
endfunction

private function UnitHider4_IsNearReference takes unit whichUnit, real distanceSq returns boolean
    local real unitX = GetUnitX(whichUnit)
    local real unitY = GetUnitY(whichUnit)
    local real deltaX
    local real deltaY
    local integer index = 0

    loop
        exitwhen index >= UnitHider4_ReferenceCount
        set deltaX = UnitHider4_ReferenceX[index] - unitX
        set deltaY = UnitHider4_ReferenceY[index] - unitY
        if deltaX * deltaX + deltaY * deltaY <= distanceSq then
            return true
        endif
        set index = index + 1
    endloop
    return false
endfunction

private function UnitHider4_IsProtected takes unit whichUnit, boolean isAutomaticReference returns boolean
    return isAutomaticReference or IsUnitType(whichUnit, UNIT_TYPE_HERO) or IsUnitInGroup(whichUnit, UnitHider4_RegisteredReferences) or IsUnitInGroup(whichUnit, udg_UnitHider_ReferenceGroup) or IsUnitInGroup(whichUnit, udg_UnitHider_IgnoredUnits) or GetUnitAbilityLevel(whichUnit, 'Aloc') > 0
endfunction

private function UnitHider4_ShowOwned takes unit whichUnit, boolean show returns nothing
    set UnitHider4_InternalShow = true
    call ShowUnit(whichUnit, show)
    set UnitHider4_InternalShow = false
endfunction

private function UnitHider4_ProcessUnit takes unit whichUnit returns nothing
    local boolean isAutomaticReference

    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return
    endif

    set isAutomaticReference = UnitHider4_UpdateAutomaticReference(whichUnit)
    if not UnitHider4_Enabled then
        return
    endif

    set UnitHider4_Checked = UnitHider4_Checked + 1

    if IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
        if IsUnitLoaded(whichUnit) then
            return
        endif
        if UnitHider4_ReferenceCount == 0 or not FallenHeroState_IsAlive(whichUnit) or UnitHider4_IsProtected(whichUnit, isAutomaticReference) or UnitHider4_IsNearReference(whichUnit, UnitHider4_ShowDistanceSq) then
            call UnitHider4_ShowOwned(whichUnit, true)
            call GroupRemoveUnit(UnitHider4_HiddenUnits, whichUnit)
            set UnitHider4_Shown = UnitHider4_Shown + 1
        endif
        return
    endif

    // IsUnitHidden here means another system owns the hidden state.
    if IsUnitHidden(whichUnit) or not FallenHeroState_IsAlive(whichUnit) or IsUnitLoaded(whichUnit) or UnitHider4_IsProtected(whichUnit, isAutomaticReference) then
        return
    endif

    // No valid revealers is a fail-safe state: do not hide the map.
    if UnitHider4_ReferenceCount > 0 and not UnitHider4_IsNearReference(whichUnit, UnitHider4_HideDistanceSq) then
        call UnitHider4_ShowOwned(whichUnit, false)
        call GroupAddUnit(UnitHider4_HiddenUnits, whichUnit)
        set UnitHider4_Hidden = UnitHider4_Hidden + 1
    endif
endfunction

private function UnitHider4_FinishSweep takes nothing returns nothing
    if UnitHider4_Debug then
        call BJDebugMsg("[UnitHider4] Checked: " + I2S(UnitHider4_Checked) + " | Hidden: " + I2S(UnitHider4_Hidden) + " | Shown: " + I2S(UnitHider4_Shown) + " | Managed hidden: " + I2S(BlzGroupGetSize(UnitHider4_HiddenUnits)) + " | References: " + I2S(UnitHider4_ReferenceCount))
    endif
    set UnitHider4_Checked = 0
    set UnitHider4_Hidden = 0
    set UnitHider4_Shown = 0
endfunction

private function UnitHider4_ProcessHiddenBatch takes nothing returns nothing
    local integer processed = 0
    local integer count = BlzGroupGetSize(UnitHider4_HiddenUnits)
    local integer limit = count
    local integer previousCount
    local unit whichUnit

    if limit > UnitHider4_HIDDEN_UNITS_PER_TICK then
        set limit = UnitHider4_HIDDEN_UNITS_PER_TICK
    endif
    loop
        exitwhen processed >= limit or count <= 0
        if UnitHider4_HiddenScanIndex >= count then
            set UnitHider4_HiddenScanIndex = 0
        endif
        set whichUnit = BlzGroupUnitAt(UnitHider4_HiddenUnits, UnitHider4_HiddenScanIndex)
        set previousCount = count
        call UnitHider4_ProcessUnit(whichUnit)
        set count = BlzGroupGetSize(UnitHider4_HiddenUnits)
        if count >= previousCount then
            set UnitHider4_HiddenScanIndex = UnitHider4_HiddenScanIndex + 1
        endif
        set processed = processed + 1
    endloop

    if count <= 0 then
        set UnitHider4_HiddenScanIndex = 0
    endif
    set whichUnit = null
endfunction

private function UnitHider4_ProcessBatch takes nothing returns nothing
    local integer processed = 0
    local unit whichUnit

    if udg_InCinematic then
        set UnitHider4_WasInCinematic = true
        return
    endif
    if UnitHider4_WasInCinematic then
        set UnitHider4_WasInCinematic = false
        set UnitHider4_RefreshTick = UnitHider4_REFERENCE_REFRESH_TICKS
        set UnitHider4_ScanIndex = 1
    endif

    set UnitHider4_RefreshTick = UnitHider4_RefreshTick + 1
    if UnitHider4_RefreshTick >= UnitHider4_REFERENCE_REFRESH_TICKS then
        set UnitHider4_RefreshTick = 0
        call UnitHider4_UpdateReferenceCache()
    endif

    if UnitHider4_Enabled then
        call UnitHider4_ProcessHiddenBatch()
    endif

    loop
        exitwhen processed >= UnitHider4_UNITS_PER_TICK
        if UnitHider4_ScanIndex > udg_UDexMax then
            call UnitHider4_FinishSweep()
            set UnitHider4_ScanIndex = 1
            set processed = UnitHider4_UNITS_PER_TICK
        else
            set whichUnit = udg_UDexUnits[UnitHider4_ScanIndex]
            call UnitHider4_ProcessUnit(whichUnit)
            set UnitHider4_ScanIndex = UnitHider4_ScanIndex + 1
            set processed = processed + 1
        endif
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_UnhideAllManaged takes nothing returns nothing
    local unit whichUnit

    loop
        set whichUnit = FirstOfGroup(UnitHider4_HiddenUnits)
        exitwhen whichUnit == null
        call UnitHider4_ShowOwned(whichUnit, true)
        call GroupRemoveUnit(UnitHider4_HiddenUnits, whichUnit)
    endloop

    set whichUnit = null
endfunction

function UnitHider_SetHidingDistance takes real newDistance returns nothing
    if newDistance < 0.00 then
        set newDistance = 0.00
    endif
    set UnitHider4_HideDistance = newDistance
    set UnitHider4_HideDistanceSq = newDistance * newDistance
    set UnitHider4_ShowDistance = newDistance
    set UnitHider4_ShowDistanceSq = newDistance * newDistance
endfunction

function UnitHider_SetUnhidingDistance takes real newDistance returns nothing
    if newDistance < 0.00 then
        set newDistance = 0.00
    elseif newDistance > UnitHider4_HideDistance then
        set newDistance = UnitHider4_HideDistance
    endif
    set UnitHider4_ShowDistance = newDistance
    set UnitHider4_ShowDistanceSq = newDistance * newDistance
endfunction

function UnitHider_SetDebugEnabled takes boolean enable returns nothing
    set UnitHider4_Debug = enable
    set udg_UnitHider_debug = enable
endfunction

function UnitHider_SetSystemEnabled takes boolean enable returns nothing
    set UnitHider4_Enabled = enable
    set udg_UnitHider_SetSystem = enable
    if enable then
        set UnitHider4_ScanIndex = 1
        set UnitHider4_HiddenScanIndex = 0
        set UnitHider4_RefreshTick = UnitHider4_REFERENCE_REFRESH_TICKS
    else
        call UnitHider4_UnhideAllManaged()
    endif
    if UnitHider4_Debug then
        if enable then
            call BJDebugMsg("[UnitHider4] System enabled")
        else
            call BJDebugMsg("[UnitHider4] System disabled")
        endif
    endif
endfunction

function UnitHider_RegisterReference takes unit whichUnit returns nothing
    if whichUnit != null then
        call GroupAddUnit(UnitHider4_RegisteredReferences, whichUnit)
        if IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
            call UnitHider4_ShowOwned(whichUnit, true)
            call GroupRemoveUnit(UnitHider4_HiddenUnits, whichUnit)
        endif
        set UnitHider4_RefreshTick = UnitHider4_REFERENCE_REFRESH_TICKS
    endif
endfunction

function UnitHider_UnregisterReference takes unit whichUnit returns nothing
    call GroupRemoveUnit(UnitHider4_RegisteredReferences, whichUnit)
    set UnitHider4_RefreshTick = UnitHider4_REFERENCE_REFRESH_TICKS
endfunction

function UnitHider_SetUnitIgnored takes unit whichUnit, boolean ignored returns nothing
    if whichUnit == null then
        return
    endif
    if ignored then
        call GroupAddUnit(udg_UnitHider_IgnoredUnits, whichUnit)
        if IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
            call UnitHider4_ShowOwned(whichUnit, true)
            call GroupRemoveUnit(UnitHider4_HiddenUnits, whichUnit)
        endif
    else
        call GroupRemoveUnit(udg_UnitHider_IgnoredUnits, whichUnit)
    endif
endfunction

function UnitHider_IsUnitHiddenBySystem takes unit whichUnit returns boolean
    return whichUnit != null and IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits)
endfunction

function UnitHider_Refresh takes nothing returns nothing
    set UnitHider4_ScanIndex = 1
    set UnitHider4_HiddenScanIndex = 0
    set UnitHider4_RefreshTick = UnitHider4_REFERENCE_REFRESH_TICKS
endfunction

function UnitHider_StartHideUnitsSystem takes nothing returns nothing
    call UnitHider_SetDebugEnabled(false)
    call UnitHider_SetSystemEnabled(true)
endfunction

// Any foreign ShowUnit call transfers visibility ownership away from UnitHider4.
private function UnitHider4_OnShowUnit takes unit whichUnit, boolean show returns nothing
    if not UnitHider4_InternalShow and whichUnit != null then
        call GroupRemoveUnit(UnitHider4_HiddenUnits, whichUnit)
    endif
endfunction
hook ShowUnit UnitHider4_OnShowUnit

private function Init takes nothing returns nothing
    if udg_UnitHider_ReferenceGroup == null then
        set udg_UnitHider_ReferenceGroup = CreateGroup()
    endif
    if udg_UnitHider_IgnoredUnits == null then
        set udg_UnitHider_IgnoredUnits = CreateGroup()
    endif
    set udg_UnitHider_SetSystem = true
    set udg_UnitHider_debug = false
    call TimerStart(UnitHider4_Timer, UnitHider4_TICK_INTERVAL, true, function UnitHider4_ProcessBatch)
endfunction

endlibrary
