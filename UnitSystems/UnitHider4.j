/**
    UnitHider4

    Author: Valdemar
    Version: 4.8.0

    Description:
    Hides the ordinary map population outside tracked-unit reveal ranges.
    Player-controlled heroes, configured basic AI heroes, registered companions
    and pets, and explicit reference units reveal nearby units. Generic heroes,
    combatants, vendors, and quest givers remain hideable; only explicit
    exclusions and revealers bypass distance hiding. Complete settlements drain
    a direct world snapshot using the proven UnitHider 1.0 traversal, while
    Events supplies incremental world-enter notifications. Hidden units are
    indexed spatially so continuous work scales with nearby visible population
    rather than every hidden unit. Authoritative passes merge world enumeration
    with Unit Event's indexed handles so units hidden by cinematic or scripted
    systems are not lost. Cinematic mode temporarily narrows reveal coverage to
    the active scene without surrendering UnitHider's normal hidden ownership.
    The system only shows units that it hid.

    Credits:
    - UnitHider 1.0 for the reliable owned-hidden-unit model
    - UnitHider3 for cached positions and squared-distance comparisons
    - Events for incremental world-enter notifications
    - Bribe's Unit Event 2.5.3.2 for hidden-unit inventory and removal cleanup

    How to install:
    Import after Events, Unit Event, and FallenHeroState. Keep the GUI variables
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
    - UnitHider_RegisterReference(whichUnit) immediately reveals its area
    - UnitHider_UnregisterReference(whichUnit)
    - UnitHider_BeginCinematic(sceneReference)
    - UnitHider_EndCinematic()
    - UnitHider_RegisterCinematicReference(whichUnit)
    - UnitHider_UnregisterCinematicReference(whichUnit)
    - UnitHider_SetUnitIgnored(whichUnit, ignored)
    - UnitHider_IsUnitHiddenBySystem(whichUnit) -> boolean
    - UnitHider_Refresh()
    - UnitHider_DebugHideAllExceptTracked() -> newly hidden count
    - UnitHider_DebugUnhideAllExceptTracked() -> newly shown count
    - UnitHider_DebugAudit(whichPlayer)
    - UnitHider_DebugPauseProcessing() preserves current visibility

**/
library UnitHider4 initializer Init requires FallenHeroState, Events, optional AI

globals
    // Configuration
    private constant real UnitHider4_TICK_INTERVAL = 0.10
    private constant integer UnitHider4_RECOVERY_UNITS_PER_TICK = 8
    private constant integer UnitHider4_RECOVERY_GROUP_SLOTS_PER_TICK = 64
    private constant integer UnitHider4_VISIBLE_UNITS_PER_TICK = 128
    private constant integer UnitHider4_GRID_AXIS = 64
    private constant integer UnitHider4_MAX_REFERENCES = 8190
    private constant integer UnitHider4_CELL_CHILD_KEY = 0
    private constant real UnitHider4_DEFAULT_HIDE_DISTANCE = 5500.00
    private constant real UnitHider4_DEFAULT_SHOW_DISTANCE = 5200.00

    // Visibility owned by UnitHider4. Foreign hidden units are never added here.
    private group UnitHider4_HiddenUnits = CreateGroup()
    private group array UnitHider4_HiddenCells
    private hashtable UnitHider4_HiddenCellByHandle = InitHashtable()
    private group UnitHider4_VisibleUnits = CreateGroup()
    private group UnitHider4_PendingUnits = CreateGroup()
    private group UnitHider4_KnownUnits = CreateGroup()
    private group UnitHider4_WorldScanUnits = CreateGroup()
    private group UnitHider4_AutomaticReferences = CreateGroup()
    private group UnitHider4_RegisteredReferences = CreateGroup()
    private group UnitHider4_CinematicReferences = CreateGroup()
    private group UnitHider4_ReferenceCacheGroup = CreateGroup()
    private real array UnitHider4_ReferenceX
    private real array UnitHider4_ReferenceY
    private integer UnitHider4_ReferenceCount = 0

    private timer UnitHider4_Timer = CreateTimer()
    private boolean UnitHider4_Enabled = true
    private boolean UnitHider4_Debug = false
    private boolean UnitHider4_InternalShow = false
    private boolean UnitHider4_WasInCinematic = false
    private boolean UnitHider4_Initialized = false
    private integer UnitHider4_CinematicDepth = 0
    private integer UnitHider4_ScanIndex = 0
    private integer UnitHider4_VisibleScanIndex = 0
    private rect UnitHider4_WorldBounds = null
    private real UnitHider4_WorldMinX = 0.00
    private real UnitHider4_WorldMinY = 0.00
    private real UnitHider4_CellWidth = 1.00
    private real UnitHider4_CellHeight = 1.00
    private real UnitHider4_HideDistance = UnitHider4_DEFAULT_HIDE_DISTANCE
    private real UnitHider4_HideDistanceSq = UnitHider4_DEFAULT_HIDE_DISTANCE * UnitHider4_DEFAULT_HIDE_DISTANCE
    private real UnitHider4_ShowDistance = UnitHider4_DEFAULT_SHOW_DISTANCE
    private real UnitHider4_ShowDistanceSq = UnitHider4_DEFAULT_SHOW_DISTANCE * UnitHider4_DEFAULT_SHOW_DISTANCE

    // Statistics for debug summaries, reset after each complete known-unit sweep.
    private integer UnitHider4_Checked = 0
    private integer UnitHider4_Hidden = 0
    private integer UnitHider4_Shown = 0
endglobals

private function UnitHider4_AddIndexedUnitsToKnown takes nothing returns nothing
    local integer unitId = 1
    local unit whichUnit

    loop
        exitwhen unitId > udg_UDexMax
        set whichUnit = udg_UDexUnits[unitId]
        if whichUnit != null and GetUnitTypeId(whichUnit) != 0 then
            call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
        endif
        set unitId = unitId + 1
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_PrepareWorldScan takes nothing returns nothing
    // World enumeration can omit units already hidden by another system. Unit
    // Event is supplemental inventory here; neither source is trusted alone.
    call UnitHider4_AddIndexedUnitsToKnown()
    call GroupClear(UnitHider4_WorldScanUnits)
    call GroupEnumUnitsInRect(UnitHider4_WorldScanUnits, UnitHider4_WorldBounds, null)
    call GroupAddGroup(UnitHider4_KnownUnits, UnitHider4_WorldScanUnits)
    call GroupAddGroup(UnitHider4_WorldScanUnits, UnitHider4_KnownUnits)
endfunction

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

private function UnitHider4_IsAllowedLegacyReference takes unit whichUnit returns boolean
    if whichUnit == null or not IsUnitInGroup(whichUnit, udg_UnitHider_ReferenceGroup) then
        return false
    endif
    if UnitHider4_IsLegacyCompanionReference(whichUnit) then
        return true
    endif
    return IsUnitType(whichUnit, UNIT_TYPE_HERO) and GetPlayerController(GetOwningPlayer(whichUnit)) == MAP_CONTROL_USER
endfunction

private function UnitHider4_IsPlayerControlledHero takes unit whichUnit returns boolean
    if whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return false
    endif
    return GetPlayerController(GetOwningPlayer(whichUnit)) == MAP_CONTROL_USER
endfunction

private function UnitHider4_IsConfiguredAIHero takes unit whichUnit returns boolean
    if whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return false
    endif
    static if LIBRARY_AI then
        return AI_IsAlive(whichUnit) and AI_IsUnitHiderRevealer(whichUnit)
    endif
    return false
endfunction

private function UnitHider4_IsAutomaticReference takes unit whichUnit, boolean isAlive, boolean isLoaded returns boolean
    if not isAlive or isLoaded then
        return false
    endif
    // Only profiles explicitly configured by AI are automatic remote revealers.
    if UnitHider4_IsPlayerControlledHero(whichUnit) or UnitHider4_IsConfiguredAIHero(whichUnit) then
        return true
    endif
    return UnitHider4_IsLegacyCompanionReference(whichUnit)
endfunction

private function UnitHider4_UpdateAutomaticReference takes unit whichUnit, boolean isAlive, boolean isLoaded returns boolean
    local boolean isReference = UnitHider4_IsAutomaticReference(whichUnit, isAlive, isLoaded)

    if isReference and not IsUnitInGroup(whichUnit, UnitHider4_AutomaticReferences) then
        call GroupAddUnit(UnitHider4_AutomaticReferences, whichUnit)
    elseif not isReference and IsUnitInGroup(whichUnit, UnitHider4_AutomaticReferences) then
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
        if FallenHeroState_IsAlive(whichUnit) and not IsUnitLoaded(whichUnit) and (not IsUnitHidden(whichUnit) or IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) or (UnitHider4_CinematicDepth > 0 and IsUnitInGroup(whichUnit, UnitHider4_CinematicReferences))) then
            set UnitHider4_ReferenceX[UnitHider4_ReferenceCount] = GetUnitX(whichUnit)
            set UnitHider4_ReferenceY[UnitHider4_ReferenceCount] = GetUnitY(whichUnit)
            set UnitHider4_ReferenceCount = UnitHider4_ReferenceCount + 1
        endif
        set index = index + 1
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_AddPartyReferences takes group sourceGroup returns nothing
    local integer index = 0
    local integer count
    local unit whichUnit

    if sourceGroup == null then
        return
    endif
    set count = BlzGroupGetSize(sourceGroup)
    loop
        exitwhen index >= count
        set whichUnit = BlzGroupUnitAt(sourceGroup, index)
        if UnitHider4_IsLegacyCompanionReference(whichUnit) then
            call GroupAddUnit(UnitHider4_ReferenceCacheGroup, whichUnit)
        endif
        set index = index + 1
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_AddAllowedLegacyReferences takes nothing returns nothing
    local integer index = 0
    local integer count = BlzGroupGetSize(udg_UnitHider_ReferenceGroup)
    local unit whichUnit

    loop
        exitwhen index >= count
        set whichUnit = BlzGroupUnitAt(udg_UnitHider_ReferenceGroup, index)
        if UnitHider4_IsAllowedLegacyReference(whichUnit) then
            call GroupAddUnit(UnitHider4_ReferenceCacheGroup, whichUnit)
        endif
        set index = index + 1
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_UpdateReferenceCache takes nothing returns nothing
    call GroupClear(UnitHider4_ReferenceCacheGroup)
    if UnitHider4_CinematicDepth > 0 then
        // During a cinematic only the active scene and explicit scripted
        // references reveal surrounding population. Automatic references stay
        // protected themselves without keeping unrelated map areas active.
        call GroupAddGroup(UnitHider4_CinematicReferences, UnitHider4_ReferenceCacheGroup)
        call GroupAddGroup(UnitHider4_RegisteredReferences, UnitHider4_ReferenceCacheGroup)
    endif
    if UnitHider4_CinematicDepth == 0 or BlzGroupGetSize(UnitHider4_ReferenceCacheGroup) == 0 then
        call GroupAddGroup(UnitHider4_AutomaticReferences, UnitHider4_ReferenceCacheGroup)
        call GroupAddGroup(UnitHider4_RegisteredReferences, UnitHider4_ReferenceCacheGroup)
        call UnitHider4_AddPartyReferences(udg_Companion_Group)
        call UnitHider4_AddPartyReferences(udg_TamedUnits)
        // The legacy group often contains obsolete NPC/dummy entries. Only its
        // player-controlled heroes and current companion/pet registrations reveal.
        call UnitHider4_AddAllowedLegacyReferences()
    endif

    set UnitHider4_ReferenceCount = 0
    call UnitHider4_CacheReferenceGroup(UnitHider4_ReferenceCacheGroup)
endfunction

private function UnitHider4_RebuildAutomaticReferences takes nothing returns nothing
    local integer index = 0
    local integer count = BlzGroupGetSize(UnitHider4_KnownUnits)
    local unit whichUnit
    local boolean isAlive
    local boolean isLoaded

    call GroupClear(UnitHider4_AutomaticReferences)
    loop
        exitwhen index >= count
        set whichUnit = BlzGroupUnitAt(UnitHider4_KnownUnits, index)
        if whichUnit != null and GetUnitTypeId(whichUnit) != 0 then
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            if UnitHider4_IsAutomaticReference(whichUnit, isAlive, isLoaded) then
                call GroupAddUnit(UnitHider4_AutomaticReferences, whichUnit)
            endif
        endif
        set index = index + 1
    endloop
    call UnitHider4_UpdateReferenceCache()
    set whichUnit = null
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

private function UnitHider4_IsTrackedReference takes unit whichUnit, boolean isAutomaticReference returns boolean
    return isAutomaticReference or IsUnitInGroup(whichUnit, UnitHider4_RegisteredReferences) or IsUnitInGroup(whichUnit, UnitHider4_CinematicReferences) or UnitHider4_IsAllowedLegacyReference(whichUnit)
endfunction

private function UnitHider4_IsProtected takes unit whichUnit, boolean isAutomaticReference returns boolean
    return UnitHider4_IsTrackedReference(whichUnit, isAutomaticReference) or IsUnitInGroup(whichUnit, udg_UnitHider_IgnoredUnits) or GetUnitAbilityLevel(whichUnit, 'Aloc') > 0
endfunction

private function UnitHider4_GetGridX takes real x returns integer
    local integer gridX = R2I((x - UnitHider4_WorldMinX) / UnitHider4_CellWidth)

    if gridX < 0 then
        return 0
    elseif gridX >= UnitHider4_GRID_AXIS then
        return UnitHider4_GRID_AXIS - 1
    endif
    return gridX
endfunction

private function UnitHider4_GetGridY takes real y returns integer
    local integer gridY = R2I((y - UnitHider4_WorldMinY) / UnitHider4_CellHeight)

    if gridY < 0 then
        return 0
    elseif gridY >= UnitHider4_GRID_AXIS then
        return UnitHider4_GRID_AXIS - 1
    endif
    return gridY
endfunction

private function UnitHider4_GetCellId takes unit whichUnit returns integer
    return UnitHider4_GetGridX(GetUnitX(whichUnit)) + UnitHider4_GetGridY(GetUnitY(whichUnit)) * UnitHider4_GRID_AXIS
endfunction

private function UnitHider4_RemoveHiddenTracking takes unit whichUnit returns nothing
    local integer handleId
    local integer encodedCell

    if whichUnit == null then
        return
    endif
    set handleId = GetHandleId(whichUnit)
    set encodedCell = LoadInteger(UnitHider4_HiddenCellByHandle, handleId, UnitHider4_CELL_CHILD_KEY)
    if encodedCell > 0 and UnitHider4_HiddenCells[encodedCell - 1] != null then
        call GroupRemoveUnit(UnitHider4_HiddenCells[encodedCell - 1], whichUnit)
    endif
    call RemoveSavedInteger(UnitHider4_HiddenCellByHandle, handleId, UnitHider4_CELL_CHILD_KEY)
    call GroupRemoveUnit(UnitHider4_HiddenUnits, whichUnit)
endfunction

private function UnitHider4_AddHiddenTracking takes unit whichUnit returns nothing
    local integer cellId

    if whichUnit == null then
        return
    endif
    call UnitHider4_RemoveHiddenTracking(whichUnit)
    set cellId = UnitHider4_GetCellId(whichUnit)
    if UnitHider4_HiddenCells[cellId] == null then
        set UnitHider4_HiddenCells[cellId] = CreateGroup()
    endif
    call GroupAddUnit(UnitHider4_HiddenUnits, whichUnit)
    call GroupAddUnit(UnitHider4_HiddenCells[cellId], whichUnit)
    call SaveInteger(UnitHider4_HiddenCellByHandle, GetHandleId(whichUnit), UnitHider4_CELL_CHILD_KEY, cellId + 1)
endfunction

private function UnitHider4_ShowOwned takes unit whichUnit, boolean show returns nothing
    set UnitHider4_InternalShow = true
    call ShowUnit(whichUnit, show)
    set UnitHider4_InternalShow = false
endfunction

private function UnitHider4_ShowManaged takes unit whichUnit, boolean trackVisible returns nothing
    call UnitHider4_RemoveHiddenTracking(whichUnit)
    call UnitHider4_ShowOwned(whichUnit, true)
    if trackVisible then
        call GroupAddUnit(UnitHider4_VisibleUnits, whichUnit)
    else
        call GroupRemoveUnit(UnitHider4_VisibleUnits, whichUnit)
    endif
    set UnitHider4_Shown = UnitHider4_Shown + 1
endfunction

private function UnitHider4_HideManaged takes unit whichUnit returns nothing
    call GroupRemoveUnit(UnitHider4_VisibleUnits, whichUnit)
    call UnitHider4_ShowOwned(whichUnit, false)
    call UnitHider4_AddHiddenTracking(whichUnit)
    set UnitHider4_Hidden = UnitHider4_Hidden + 1
endfunction

private function UnitHider4_ProcessUnit takes unit whichUnit returns nothing
    local boolean isAutomaticReference
    local boolean isAlive
    local boolean isLoaded

    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return
    endif

    set isAlive = FallenHeroState_IsAlive(whichUnit)
    set isLoaded = IsUnitLoaded(whichUnit)
    set isAutomaticReference = UnitHider4_UpdateAutomaticReference(whichUnit, isAlive, isLoaded)
    if not UnitHider4_Enabled then
        return
    endif

    set UnitHider4_Checked = UnitHider4_Checked + 1

    if IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
        if isLoaded then
            return
        endif
        if not isAlive or UnitHider4_IsProtected(whichUnit, isAutomaticReference) then
            call UnitHider4_ShowManaged(whichUnit, false)
        else
            // Cinematic or scripted movement may have changed its grid cell.
            call UnitHider4_AddHiddenTracking(whichUnit)
        endif
        return
    endif

    // IsUnitHidden here means another system owns the hidden state.
    if IsUnitHidden(whichUnit) or not isAlive or isLoaded or UnitHider4_IsProtected(whichUnit, isAutomaticReference) then
        call GroupRemoveUnit(UnitHider4_VisibleUnits, whichUnit)
        return
    endif

    if UnitHider4_ReferenceCount == 0 then
        call UnitHider4_HideManaged(whichUnit)
    elseif UnitHider4_IsNearReference(whichUnit, UnitHider4_HideDistanceSq) then
        call GroupAddUnit(UnitHider4_VisibleUnits, whichUnit)
    else
        call UnitHider4_HideManaged(whichUnit)
    endif
endfunction

private function UnitHider4_ProcessPendingUnits takes nothing returns nothing
    local unit whichUnit

    loop
        set whichUnit = FirstOfGroup(UnitHider4_PendingUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(UnitHider4_PendingUnits, whichUnit)
        call UnitHider4_ProcessUnit(whichUnit)
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_FinishSweep takes nothing returns nothing
    // Include revealers discovered late in this sweep before the next begins.
    call UnitHider4_UpdateReferenceCache()
    if UnitHider4_Debug then
        call BJDebugMsg("[UnitHider4] Known: " + I2S(BlzGroupGetSize(UnitHider4_KnownUnits)) + " | Checked: " + I2S(UnitHider4_Checked) + " | Hidden: " + I2S(UnitHider4_Hidden) + " | Shown: " + I2S(UnitHider4_Shown) + " | Managed hidden: " + I2S(BlzGroupGetSize(UnitHider4_HiddenUnits)) + " | References: " + I2S(UnitHider4_ReferenceCount))
    endif
    set UnitHider4_Checked = 0
    set UnitHider4_Hidden = 0
    set UnitHider4_Shown = 0
endfunction

private function UnitHider4_ResetKnownUnitScan takes nothing returns nothing
    set UnitHider4_ScanIndex = 0
endfunction

private function UnitHider4_RevealCell takes integer cellId, real referenceX, real referenceY returns nothing
    local group cellGroup = UnitHider4_HiddenCells[cellId]
    local integer index = 0
    local integer count
    local real deltaX
    local real deltaY
    local unit whichUnit
    local boolean isAutomaticReference
    local boolean isAlive
    local boolean isLoaded
    local boolean isProtected

    if cellGroup == null then
        return
    endif
    set count = BlzGroupGetSize(cellGroup)
    loop
        exitwhen index >= count
        set whichUnit = BlzGroupUnitAt(cellGroup, index)
        if whichUnit == null then
            set index = index + 1
        elseif GetUnitTypeId(whichUnit) == 0 or not IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
            call GroupRemoveUnit(cellGroup, whichUnit)
            set count = BlzGroupGetSize(cellGroup)
        else
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            set isAutomaticReference = UnitHider4_UpdateAutomaticReference(whichUnit, isAlive, isLoaded)
            set isProtected = UnitHider4_IsProtected(whichUnit, isAutomaticReference)
            set deltaX = GetUnitX(whichUnit) - referenceX
            set deltaY = GetUnitY(whichUnit) - referenceY
            if not isLoaded and (not isAlive or isProtected or deltaX * deltaX + deltaY * deltaY <= UnitHider4_ShowDistanceSq) then
                call UnitHider4_ShowManaged(whichUnit, isAlive and not isProtected)
                set count = BlzGroupGetSize(cellGroup)
            else
                set index = index + 1
            endif
        endif
    endloop

    set whichUnit = null
    set cellGroup = null
endfunction

private function UnitHider4_RevealNearReferences takes nothing returns nothing
    local integer referenceIndex = 0
    local integer minGridX
    local integer maxGridX
    local integer minGridY
    local integer maxGridY
    local integer gridX
    local integer gridY
    local real referenceX
    local real referenceY

    loop
        exitwhen referenceIndex >= UnitHider4_ReferenceCount
        set referenceX = UnitHider4_ReferenceX[referenceIndex]
        set referenceY = UnitHider4_ReferenceY[referenceIndex]
        set minGridX = UnitHider4_GetGridX(referenceX - UnitHider4_ShowDistance)
        set maxGridX = UnitHider4_GetGridX(referenceX + UnitHider4_ShowDistance)
        set minGridY = UnitHider4_GetGridY(referenceY - UnitHider4_ShowDistance)
        set maxGridY = UnitHider4_GetGridY(referenceY + UnitHider4_ShowDistance)
        set gridY = minGridY
        loop
            exitwhen gridY > maxGridY
            set gridX = minGridX
            loop
                exitwhen gridX > maxGridX
                call UnitHider4_RevealCell(gridX + gridY * UnitHider4_GRID_AXIS, referenceX, referenceY)
                set gridX = gridX + 1
            endloop
            set gridY = gridY + 1
        endloop
        set referenceIndex = referenceIndex + 1
    endloop
endfunction

private function UnitHider4_ProcessVisibleBatch takes nothing returns nothing
    local integer processed = 0
    local integer count = BlzGroupGetSize(UnitHider4_VisibleUnits)
    local integer limit = count
    local integer previousCount
    local unit whichUnit

    if limit > UnitHider4_VISIBLE_UNITS_PER_TICK then
        set limit = UnitHider4_VISIBLE_UNITS_PER_TICK
    endif
    loop
        exitwhen processed >= limit or count <= 0
        if UnitHider4_VisibleScanIndex >= count then
            set UnitHider4_VisibleScanIndex = 0
        endif
        set whichUnit = BlzGroupUnitAt(UnitHider4_VisibleUnits, UnitHider4_VisibleScanIndex)
        set previousCount = count
        call UnitHider4_ProcessUnit(whichUnit)
        set count = BlzGroupGetSize(UnitHider4_VisibleUnits)
        if count >= previousCount then
            set UnitHider4_VisibleScanIndex = UnitHider4_VisibleScanIndex + 1
        endif
        set processed = processed + 1
    endloop

    if count <= 0 then
        set UnitHider4_VisibleScanIndex = 0
    endif
    set whichUnit = null
endfunction

private function UnitHider4_SettleMap takes nothing returns boolean
    local unit whichUnit

    // Restore the proven v1/v3 settlement contract: take a fresh world
    // snapshot, merge already-known units, then remove each snapshot member
    // before changing its visibility. The persistent group is never used as
    // the mutable traversal source for the authoritative pass.
    call UnitHider4_PrepareWorldScan()
    set whichUnit = FirstOfGroup(UnitHider4_WorldScanUnits)
    if whichUnit == null then
        return false
    endif
    call UnitHider4_RebuildAutomaticReferences()
    loop
        exitwhen whichUnit == null
        call GroupRemoveUnit(UnitHider4_WorldScanUnits, whichUnit)
        call UnitHider4_ProcessUnit(whichUnit)
        call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
        set whichUnit = FirstOfGroup(UnitHider4_WorldScanUnits)
    endloop
    // ProcessUnit preserves already-managed hidden units. Complete the
    // settlement by revealing the spatial cells around the new reference set.
    call UnitHider4_UpdateReferenceCache()
    call UnitHider4_RevealNearReferences()
    set UnitHider4_Initialized = true
    call GroupClear(UnitHider4_PendingUnits)
    call UnitHider4_FinishSweep()
    call UnitHider4_ResetKnownUnitScan()
    set whichUnit = null
    return true
endfunction

private function UnitHider4_ProcessBatch takes nothing returns nothing
    local integer processed = 0
    local integer inspected = 0
    local integer count
    local unit whichUnit

    if not UnitHider4_Enabled then
        return
    endif
    // The first full settlement must happen even during the opening cinematic.
    // Later cinematic ticks pause mutation until the exit settlement.
    if not UnitHider4_Initialized then
        call UnitHider4_SettleMap()
        if udg_InCinematic then
            set UnitHider4_WasInCinematic = true
        endif
        return
    endif
    if UnitHider4_CinematicDepth > 0 or udg_InCinematic then
        set UnitHider4_WasInCinematic = true
        return
    endif
    if UnitHider4_WasInCinematic then
        set UnitHider4_WasInCinematic = false
        set UnitHider4_Initialized = false
        call UnitHider4_SettleMap()
        return
    endif

    // Reclassify new entrants after other creation callbacks have completed,
    // and foreign-shown units without waiting for the recovery scan.
    call UnitHider4_ProcessPendingUnits()
    call UnitHider4_UpdateReferenceCache()
    call UnitHider4_RevealNearReferences()
    call UnitHider4_ProcessVisibleBatch()

    loop
        exitwhen processed >= UnitHider4_RECOVERY_UNITS_PER_TICK or inspected >= UnitHider4_RECOVERY_GROUP_SLOTS_PER_TICK
        set count = BlzGroupGetSize(UnitHider4_KnownUnits)
        if UnitHider4_ScanIndex >= count then
            call UnitHider4_FinishSweep()
            call UnitHider4_ResetKnownUnitScan()
            set inspected = UnitHider4_RECOVERY_GROUP_SLOTS_PER_TICK
        else
            set whichUnit = BlzGroupUnitAt(UnitHider4_KnownUnits, UnitHider4_ScanIndex)
            set UnitHider4_ScanIndex = UnitHider4_ScanIndex + 1
            set inspected = inspected + 1
            if whichUnit != null and GetUnitTypeId(whichUnit) != 0 and not IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
                call UnitHider4_ProcessUnit(whichUnit)
                set processed = processed + 1
            endif
        endif
    endloop

    set whichUnit = null
endfunction

private function UnitHider4_UnhideAllManaged takes nothing returns nothing
    local unit whichUnit

    loop
        set whichUnit = FirstOfGroup(UnitHider4_HiddenUnits)
        exitwhen whichUnit == null
        call UnitHider4_RemoveHiddenTracking(whichUnit)
        call UnitHider4_ShowOwned(whichUnit, true)
    endloop
    call GroupClear(UnitHider4_VisibleUnits)
    call GroupClear(UnitHider4_PendingUnits)
    set UnitHider4_VisibleScanIndex = 0

    set whichUnit = null
endfunction

function UnitHider_DebugHideAllExceptTracked takes nothing returns integer
    local integer hiddenCount = 0
    local unit whichUnit
    local boolean isAlive
    local boolean isLoaded
    local boolean isAutomaticReference
    local boolean wasManaged

    call UnitHider4_PrepareWorldScan()
    call UnitHider4_RebuildAutomaticReferences()

    loop
        set whichUnit = FirstOfGroup(UnitHider4_WorldScanUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(UnitHider4_WorldScanUnits, whichUnit)
        if GetUnitTypeId(whichUnit) != 0 then
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            set isAutomaticReference = UnitHider4_UpdateAutomaticReference(whichUnit, isAlive, isLoaded)
            set wasManaged = IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits)
            call GroupRemoveUnit(UnitHider4_PendingUnits, whichUnit)
            if UnitHider4_IsTrackedReference(whichUnit, isAutomaticReference) then
                if wasManaged then
                    call UnitHider4_ShowManaged(whichUnit, false)
                endif
            elseif isAlive and not isLoaded and not wasManaged and not IsUnitHidden(whichUnit) and not IsUnitInGroup(whichUnit, udg_UnitHider_IgnoredUnits) and GetUnitAbilityLevel(whichUnit, 'Aloc') == 0 then
                call UnitHider4_HideManaged(whichUnit)
                set hiddenCount = hiddenCount + 1
            endif
        endif
    endloop

    call UnitHider4_UpdateReferenceCache()
    call UnitHider4_ResetKnownUnitScan()
    set UnitHider4_VisibleScanIndex = 0
    set whichUnit = null
    return hiddenCount
endfunction

function UnitHider_DebugUnhideAllExceptTracked takes nothing returns integer
    local integer shownCount = BlzGroupGetSize(UnitHider4_HiddenUnits)

    call UnitHider4_UnhideAllManaged()
    call UnitHider4_ResetKnownUnitScan()
    return shownCount
endfunction

function UnitHider_DebugAudit takes player whichPlayer returns nothing
    local integer totalCount = 0
    local integer exemptCount = 0
    local integer eligibleHiddenCount = 0
    local integer foreignHiddenCount = 0
    local integer nearVisibleCount = 0
    local integer farVisibleCount = 0
    local unit whichUnit
    local boolean isAlive
    local boolean isLoaded
    local boolean isAutomaticReference
    local string state = "enabled"

    call UnitHider4_PrepareWorldScan()
    call UnitHider4_RebuildAutomaticReferences()
    loop
        set whichUnit = FirstOfGroup(UnitHider4_WorldScanUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(UnitHider4_WorldScanUnits, whichUnit)
        if GetUnitTypeId(whichUnit) != 0 then
            set totalCount = totalCount + 1
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            set isAutomaticReference = UnitHider4_IsAutomaticReference(whichUnit, isAlive, isLoaded)
            if not isAlive or isLoaded or UnitHider4_IsProtected(whichUnit, isAutomaticReference) then
                set exemptCount = exemptCount + 1
            elseif IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
                set eligibleHiddenCount = eligibleHiddenCount + 1
            elseif IsUnitHidden(whichUnit) then
                set foreignHiddenCount = foreignHiddenCount + 1
            elseif UnitHider4_IsNearReference(whichUnit, UnitHider4_HideDistanceSq) then
                set nearVisibleCount = nearVisibleCount + 1
            else
                set farVisibleCount = farVisibleCount + 1
            endif
        endif
    endloop
    if not UnitHider4_Enabled then
        set state = "disabled"
    endif
    if UnitHider4_CinematicDepth > 0 then
        set state = state + ", cinematic managed"
    elseif udg_InCinematic then
        set state = state + ", cinematic compatibility suspension"
    endif
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "|cffffcc00[UnitHider4 audit]|r " + state + " | references=" + I2S(UnitHider4_ReferenceCount))
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Inventory=" + I2S(totalCount) + " | known=" + I2S(BlzGroupGetSize(UnitHider4_KnownUnits)) + " | exempt=" + I2S(exemptCount) + " | managed hidden=" + I2S(eligibleHiddenCount) + " | foreign hidden=" + I2S(foreignHiddenCount))
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Visible near references=" + I2S(nearVisibleCount) + " | visible outside hide range=" + I2S(farVisibleCount) + " | pending=" + I2S(BlzGroupGetSize(UnitHider4_PendingUnits)))
    set whichUnit = null
    set whichPlayer = null
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

function UnitHider_RegisterCinematicReference takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
    call GroupAddUnit(UnitHider4_CinematicReferences, whichUnit)
    if IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
        call UnitHider4_ShowManaged(whichUnit, false)
    endif
    call UnitHider4_UpdateReferenceCache()
    if UnitHider4_Enabled and UnitHider4_CinematicDepth > 0 then
        call UnitHider4_RevealNearReferences()
    endif
endfunction

function UnitHider_UnregisterCinematicReference takes unit whichUnit returns nothing
    call GroupRemoveUnit(UnitHider4_CinematicReferences, whichUnit)
    call UnitHider4_UpdateReferenceCache()
    if UnitHider4_Enabled and UnitHider4_CinematicDepth > 0 then
        set UnitHider4_Initialized = false
        call UnitHider4_SettleMap()
    endif
endfunction

function UnitHider_BeginCinematic takes unit sceneReference returns nothing
    set UnitHider4_CinematicDepth = UnitHider4_CinematicDepth + 1
    set UnitHider4_WasInCinematic = true
    if sceneReference != null then
        call GroupAddUnit(UnitHider4_KnownUnits, sceneReference)
        call GroupAddUnit(UnitHider4_CinematicReferences, sceneReference)
    endif
    if UnitHider4_Enabled then
        set UnitHider4_Initialized = false
        call UnitHider4_SettleMap()
    endif
endfunction

function UnitHider_EndCinematic takes nothing returns nothing
    if UnitHider4_CinematicDepth <= 0 then
        return
    endif
    set UnitHider4_CinematicDepth = UnitHider4_CinematicDepth - 1
    if UnitHider4_CinematicDepth > 0 then
        return
    endif
    call GroupClear(UnitHider4_CinematicReferences)
    set UnitHider4_WasInCinematic = false
    if UnitHider4_Enabled then
        set UnitHider4_Initialized = false
        call UnitHider4_SettleMap()
    endif
endfunction

function UnitHider_SetSystemEnabled takes boolean enable returns nothing
    set UnitHider4_Enabled = enable
    set udg_UnitHider_SetSystem = enable
    if enable then
        call TimerStart(UnitHider4_Timer, UnitHider4_TICK_INTERVAL, true, function UnitHider4_ProcessBatch)
        call UnitHider4_ResetKnownUnitScan()
        set UnitHider4_VisibleScanIndex = 0
        set UnitHider4_Initialized = false
    else
        call UnitHider4_UnhideAllManaged()
        set UnitHider4_Initialized = false
    endif
    if UnitHider4_Debug then
        if enable then
            call BJDebugMsg("[UnitHider4] System enabled")
        else
            call BJDebugMsg("[UnitHider4] System disabled")
        endif
    endif
endfunction

function UnitHider_DebugPauseProcessing takes nothing returns nothing
    set UnitHider4_Enabled = false
    set udg_UnitHider_SetSystem = false
    call PauseTimer(UnitHider4_Timer)
endfunction

function UnitHider_RegisterReference takes unit whichUnit returns nothing
    if whichUnit != null then
        call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
        call GroupAddUnit(UnitHider4_RegisteredReferences, whichUnit)
        if IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
            call UnitHider4_ShowManaged(whichUnit, false)
        endif
        call UnitHider4_UpdateReferenceCache()
        if UnitHider4_Enabled then
            // Explicit references take effect before the next timer update so
            // scripted camera cuts cannot expose an unrevealed area.
            call UnitHider4_RevealNearReferences()
        endif
    endif
endfunction

function UnitHider_UnregisterReference takes unit whichUnit returns nothing
    call GroupRemoveUnit(UnitHider4_RegisteredReferences, whichUnit)
    call UnitHider4_UpdateReferenceCache()
    if UnitHider4_Initialized and UnitHider4_Enabled and not udg_InCinematic then
        call UnitHider4_ProcessUnit(whichUnit)
    endif
endfunction

function UnitHider_SetUnitIgnored takes unit whichUnit, boolean ignored returns nothing
    if whichUnit == null then
        return
    endif
    call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
    if ignored then
        call GroupAddUnit(udg_UnitHider_IgnoredUnits, whichUnit)
        if IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits) then
            call UnitHider4_ShowManaged(whichUnit, false)
        endif
    else
        call GroupRemoveUnit(udg_UnitHider_IgnoredUnits, whichUnit)
        if UnitHider4_Initialized and UnitHider4_Enabled and not udg_InCinematic then
            call UnitHider4_ProcessUnit(whichUnit)
        endif
    endif
endfunction

function UnitHider_IsUnitHiddenBySystem takes unit whichUnit returns boolean
    return whichUnit != null and IsUnitInGroup(whichUnit, UnitHider4_HiddenUnits)
endfunction

function UnitHider_Refresh takes nothing returns nothing
    call UnitHider4_ResetKnownUnitScan()
    set UnitHider4_VisibleScanIndex = 0
    set UnitHider4_Initialized = false
endfunction

function UnitHider_StartHideUnitsSystem takes nothing returns nothing
    call UnitHider_SetDebugEnabled(false)
    call UnitHider_SetSystemEnabled(true)
endfunction

// Foreign ShowUnit calls release owned tracking; shown units are reclassified
// together on the next active update.
private function UnitHider4_OnShowUnit takes unit whichUnit, boolean show returns nothing
    if not UnitHider4_InternalShow and whichUnit != null then
        call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
        call UnitHider4_RemoveHiddenTracking(whichUnit)
        call GroupRemoveUnit(UnitHider4_VisibleUnits, whichUnit)
        if show and UnitHider4_Enabled then
            call GroupAddUnit(UnitHider4_PendingUnits, whichUnit)
        else
            call GroupRemoveUnit(UnitHider4_PendingUnits, whichUnit)
        endif
    endif
endfunction
hook ShowUnit UnitHider4_OnShowUnit

private function UnitHider4_OnUnitEnter takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()

    if whichUnit != null then
        call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
        // Events may run before Unit Event and AI/companion registration.
        // Recheck on the next UnitHider tick after those callbacks settle.
        call GroupAddUnit(UnitHider4_PendingUnits, whichUnit)
    endif
    if UnitHider4_Initialized and UnitHider4_Enabled and not udg_InCinematic then
        call UnitHider4_ProcessUnit(whichUnit)
    endif
    set whichUnit = null
endfunction

private function UnitHider4_OnUnitIndexed takes nothing returns nothing
    local unit whichUnit = udg_UDexUnits[udg_UDex]

    if whichUnit != null then
        call GroupAddUnit(UnitHider4_KnownUnits, whichUnit)
        call GroupAddUnit(UnitHider4_PendingUnits, whichUnit)
    endif
    set whichUnit = null
endfunction

private function UnitHider4_OnUnitDeindex takes nothing returns nothing
    local unit whichUnit = udg_UDexUnits[udg_UDex]

    call UnitHider4_RemoveHiddenTracking(whichUnit)
    call GroupRemoveUnit(UnitHider4_KnownUnits, whichUnit)
    call GroupRemoveUnit(UnitHider4_VisibleUnits, whichUnit)
    call GroupRemoveUnit(UnitHider4_PendingUnits, whichUnit)
    call GroupRemoveUnit(UnitHider4_AutomaticReferences, whichUnit)
    call GroupRemoveUnit(UnitHider4_RegisteredReferences, whichUnit)
    call GroupRemoveUnit(UnitHider4_CinematicReferences, whichUnit)
    set whichUnit = null
endfunction

private function Init takes nothing returns nothing
    local rect worldBounds = GetWorldBounds()
    local trigger indexTrigger = CreateTrigger()
    local trigger deindexTrigger = CreateTrigger()

    if udg_UnitHider_ReferenceGroup == null then
        set udg_UnitHider_ReferenceGroup = CreateGroup()
    endif
    if udg_UnitHider_IgnoredUnits == null then
        set udg_UnitHider_IgnoredUnits = CreateGroup()
    endif
    set udg_UnitHider_SetSystem = true
    set udg_UnitHider_debug = false
    set UnitHider4_WorldBounds = worldBounds
    set UnitHider4_WorldMinX = GetRectMinX(worldBounds)
    set UnitHider4_WorldMinY = GetRectMinY(worldBounds)
    set UnitHider4_CellWidth = (GetRectMaxX(worldBounds) - UnitHider4_WorldMinX) / I2R(UnitHider4_GRID_AXIS)
    set UnitHider4_CellHeight = (GetRectMaxY(worldBounds) - UnitHider4_WorldMinY) / I2R(UnitHider4_GRID_AXIS)
    call Events_RegisterUnitEnter(function UnitHider4_OnUnitEnter)
    call TriggerRegisterVariableEvent(indexTrigger, "udg_UnitIndexEvent", EQUAL, 1.50)
    call TriggerAddAction(indexTrigger, function UnitHider4_OnUnitIndexed)
    call TriggerRegisterVariableEvent(deindexTrigger, "udg_UnitIndexEvent", EQUAL, 2.00)
    call TriggerAddAction(deindexTrigger, function UnitHider4_OnUnitDeindex)
    call UnitHider4_ResetKnownUnitScan()
    call TimerStart(UnitHider4_Timer, UnitHider4_TICK_INTERVAL, true, function UnitHider4_ProcessBatch)
    set worldBounds = null
    set indexTrigger = null
    set deindexTrigger = null
endfunction

endlibrary
