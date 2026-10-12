/**
    UnitHider

    Author: Valdemar
    Version: 4.11.0

    Description:
    Hides the ordinary map population outside tracked-unit reveal ranges.
    Player-controlled heroes, configured basic AI heroes, registered companions
    and pets, and explicit reference units reveal nearby units. Autonomous AI
    heroes use a smaller simulation range than camera-followed player and
    scripted references. Generic heroes, combatants, vendors, and quest givers
    remain hideable; only explicit exclusions and revealers bypass distance
    hiding. One delayed bootstrap drains a fresh world snapshot using the
    proven UnitHider 1.0 traversal. Ongoing discovery is event-driven through
    Events, UnitDeathEvent, Unit Event finalization/cargo/removal, and native or
    GUI ShowUnit ownership transfers; normal timer work is limited to references,
    pending changes, nearby hidden cells, and the currently visible candidate
    set. Table v6 stores per-unit ownership and spatial state independently of
    recycled unit indexes. Cinematic mode temporarily narrows reveal coverage
    to the active scene and reclassifies only managed candidates. The system
    only shows units that it hid.

    Credits:
    - UnitHider 1.0 for the reliable owned-hidden-unit model
    - UnitHider3 for cached positions and squared-distance comparisons
    - Bribe's Table v6 for handle-keyed visibility state
    - Events and UnitDeathEvent for lifecycle notifications
    - Bribe's Unit Event 2.5.3.2 for finalization, revival, and removal cleanup

    How to install:
    Import after Table, Events, UnitDeathEvent, Unit Event, and FallenHeroState.
    Keep the GUI variables UnitHider_ReferenceGroup, UnitHider_IgnoredUnits,
    UnitHider_ReferenceUnits, UnitHider_SetSystem, and UnitHider_debug. Replace
    earlier UnitHider versions and disable their GUI timers/toggles. Change
    state through this library's API; the two GUI booleans mirror state but
    direct assignments do not control it.

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
    - UnitHider_NotifyUnitRelocated(whichUnit)
    - UnitHider_Refresh() schedules an explicit visible-world rescan
    - UnitHider_DebugHideAllExceptTracked() -> newly hidden count
    - UnitHider_DebugUnhideAllExceptTracked() -> newly shown count
    - UnitHider_DebugAudit(whichPlayer)
    - UnitHider_DebugPauseProcessing() preserves current visibility

**/
library UnitHider initializer Init requires Table, FallenHeroState, Events, UnitDeathEvent, optional AI

globals
    // Configuration
    private constant real TICK_INTERVAL = 0.10
    private constant integer VISIBLE_SWEEP_TICKS = 5
    private constant integer GRID_AXIS = 64
    private constant integer MAX_REFERENCES = 8190
    private constant integer DEBUG_REFERENCE_LIMIT = 20
    private constant real DEFAULT_HIDE_DISTANCE = 5500.00
    private constant real DEFAULT_SHOW_DISTANCE = 5200.00
    private constant real AI_HIDE_DISTANCE = 2800.00
    private constant real AI_SHOW_DISTANCE = 2500.00

    // Visibility owned by UnitHider. Foreign hidden units are never added here.
    private group hiddenUnits = CreateGroup()
    private group array hiddenCells
    private group visibleUnits = CreateGroup()
    private group visibleScanUnits = CreateGroup()
    private group pendingUnits = CreateGroup()
    private group knownUnits = CreateGroup()
    private group worldScanUnits = CreateGroup()
    private group automaticReferences = CreateGroup()
    private group automaticReferenceScan = CreateGroup()
    private group registeredReferences = CreateGroup()
    private group cinematicReferences = CreateGroup()
    private group cinematicVisibleUnits = CreateGroup()
    private group referenceCacheGroup = CreateGroup()
    private Table managedHidden = 0
    private Table hiddenCell = 0
    private unit cinematicSceneReference = null
    private unit array cachedReferenceUnit
    private real array cachedReferenceX
    private real array cachedReferenceY
    private real array cachedReferenceHideDistance
    private real array cachedReferenceHideDistanceSq
    private real array cachedReferenceShowDistance
    private real array cachedReferenceShowDistanceSq
    private integer referenceCount = 0
    private integer aiReferenceCount = 0

    private timer updateTimer = CreateTimer()
    private boolean enabled = true
    private boolean debugEnabled = false
    private integer internalShowDepth = 0
    private boolean wasInCinematic = false
    private boolean initialized = false
    private boolean managedVisibilityVerificationPending = false
    private integer cinematicDepth = 0
    private integer ticksUntilVisibleSweep = 0
    private rect mapBounds = null
    private real worldMinX = 0.00
    private real worldMinY = 0.00
    private real cellWidth = 1.00
    private real cellHeight = 1.00
    private real fullHideDistance = DEFAULT_HIDE_DISTANCE
    private real fullHideDistanceSq = DEFAULT_HIDE_DISTANCE * DEFAULT_HIDE_DISTANCE
    private real fullShowDistance = DEFAULT_SHOW_DISTANCE
    private real fullShowDistanceSq = DEFAULT_SHOW_DISTANCE * DEFAULT_SHOW_DISTANCE

    // Statistics for debug summaries, reset after each visible-candidate sweep.
    private integer sweepCheckedCount = 0
    private integer sweepHiddenCount = 0
    private integer sweepShownCount = 0
    private integer lastCinematicBeginHiddenBefore = 0
    private integer lastCinematicBeginHiddenAfter = 0
    private integer lastCinematicBeginVisibleAfter = 0
    private integer lastCinematicEndCandidates = 0
    private integer lastCinematicEndHiddenBefore = 0
    private integer lastCinematicEndHiddenAfter = 0
    private integer lastCinematicEndVisibleAfter = 0
    private integer lastManagedVisibilityChecked = 0
    private integer lastManagedVisibilityRepaired = 0
endglobals

private function IsManagedHidden takes unit whichUnit returns boolean
    if managedHidden == 0 or whichUnit == null then
        return false
    endif
    return managedHidden.boolean[GetHandleId(whichUnit)]
endfunction

private function PrepareWorldScan takes nothing returns nothing
    // This disposable group is the authoritative v1-style visible-world pass.
    // Never traverse the persistent known group while changing visibility.
    call GroupClear(worldScanUnits)
    call GroupEnumUnitsInRect(worldScanUnits, mapBounds, null)
    call GroupAddGroup(worldScanUnits, knownUnits)
endfunction

private function PrepareInventoryScan takes nothing returns nothing
    // Debug inventory may include units currently hidden by another system.
    // It is diagnostic only and is never the normal hiding traversal.
    call PrepareWorldScan()
    call GroupAddGroup(knownUnits, worldScanUnits)
endfunction

private function IsLegacyCompanionReference takes unit whichUnit returns boolean
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

private function IsAllowedLegacyReference takes unit whichUnit returns boolean
    if whichUnit == null or not IsUnitInGroup(whichUnit, udg_UnitHider_ReferenceGroup) then
        return false
    endif
    if IsLegacyCompanionReference(whichUnit) then
        return true
    endif
    return IsUnitType(whichUnit, UNIT_TYPE_HERO) and GetPlayerController(GetOwningPlayer(whichUnit)) == MAP_CONTROL_USER
endfunction

private function IsPlayerControlledHero takes unit whichUnit returns boolean
    if whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return false
    endif
    return GetPlayerController(GetOwningPlayer(whichUnit)) == MAP_CONTROL_USER
endfunction

private function IsConfiguredAIHero takes unit whichUnit returns boolean
    if whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return false
    endif
    static if LIBRARY_AI then
        return AI_IsAlive(whichUnit) and AI_IsUnitHiderRevealer(whichUnit)
    endif
    return false
endfunction

private function IsAutomaticReference takes unit whichUnit, boolean isAlive, boolean isLoaded returns boolean
    if not isAlive or isLoaded then
        return false
    endif
    // Only profiles explicitly configured by AI are automatic remote revealers.
    if IsPlayerControlledHero(whichUnit) or IsConfiguredAIHero(whichUnit) then
        return true
    endif
    return IsLegacyCompanionReference(whichUnit)
endfunction

private function UsesAIRange takes unit whichUnit returns boolean
    if not IsConfiguredAIHero(whichUnit) then
        return false
    endif
    if IsPlayerControlledHero(whichUnit) or IsUnitInGroup(whichUnit, registeredReferences) or whichUnit == cinematicSceneReference or IsUnitInGroup(whichUnit, cinematicReferences) then
        return false
    endif
    if (udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group)) or (udg_TamedUnits != null and IsUnitInGroup(whichUnit, udg_TamedUnits)) then
        return false
    endif
    return true
endfunction

private function UpdateAutomaticReference takes unit whichUnit, boolean isAlive, boolean isLoaded returns boolean
    local boolean isReference = IsAutomaticReference(whichUnit, isAlive, isLoaded)

    if isReference and not IsUnitInGroup(whichUnit, automaticReferences) then
        call GroupAddUnit(automaticReferences, whichUnit)
    elseif not isReference and IsUnitInGroup(whichUnit, automaticReferences) then
        call GroupRemoveUnit(automaticReferences, whichUnit)
    endif
    return isReference
endfunction

private function CacheReferenceGroup takes group sourceGroup returns nothing
    local integer index = 0
    local integer count = BlzGroupGetSize(sourceGroup)
    local unit whichUnit

    loop
        exitwhen index >= count or referenceCount >= MAX_REFERENCES
        set whichUnit = BlzGroupUnitAt(sourceGroup, index)
        if FallenHeroState_IsAlive(whichUnit) and not IsUnitLoaded(whichUnit) and (not IsUnitHidden(whichUnit) or IsManagedHidden(whichUnit) or (cinematicDepth > 0 and (whichUnit == cinematicSceneReference or IsUnitInGroup(whichUnit, cinematicReferences)))) then
            set cachedReferenceX[referenceCount] = GetUnitX(whichUnit)
            set cachedReferenceY[referenceCount] = GetUnitY(whichUnit)
            set cachedReferenceUnit[referenceCount] = whichUnit
            if UsesAIRange(whichUnit) then
                set cachedReferenceHideDistance[referenceCount] = AI_HIDE_DISTANCE
                set cachedReferenceHideDistanceSq[referenceCount] = AI_HIDE_DISTANCE * AI_HIDE_DISTANCE
                set cachedReferenceShowDistance[referenceCount] = AI_SHOW_DISTANCE
                set cachedReferenceShowDistanceSq[referenceCount] = AI_SHOW_DISTANCE * AI_SHOW_DISTANCE
                set aiReferenceCount = aiReferenceCount + 1
            else
                set cachedReferenceHideDistance[referenceCount] = fullHideDistance
                set cachedReferenceHideDistanceSq[referenceCount] = fullHideDistanceSq
                set cachedReferenceShowDistance[referenceCount] = fullShowDistance
                set cachedReferenceShowDistanceSq[referenceCount] = fullShowDistanceSq
            endif
            set referenceCount = referenceCount + 1
        endif
        set index = index + 1
    endloop

    set whichUnit = null
endfunction

private function AddPartyReferences takes group sourceGroup returns nothing
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
        if IsLegacyCompanionReference(whichUnit) then
            call GroupAddUnit(referenceCacheGroup, whichUnit)
        endif
        set index = index + 1
    endloop

    set whichUnit = null
endfunction

private function AddAllowedLegacyReferences takes nothing returns nothing
    local integer index = 0
    local integer count = BlzGroupGetSize(udg_UnitHider_ReferenceGroup)
    local unit whichUnit

    loop
        exitwhen index >= count
        set whichUnit = BlzGroupUnitAt(udg_UnitHider_ReferenceGroup, index)
        if IsAllowedLegacyReference(whichUnit) then
            call GroupAddUnit(referenceCacheGroup, whichUnit)
        endif
        set index = index + 1
    endloop

    set whichUnit = null
endfunction

private function RevalidateAutomaticReferences takes nothing returns nothing
    local unit whichUnit

    // Party membership can change without creating, killing, or transferring
    // the unit. Revalidate only the small revealer set, never unit inventory.
    call GroupClear(automaticReferenceScan)
    call GroupAddGroup(automaticReferences, automaticReferenceScan)
    loop
        set whichUnit = FirstOfGroup(automaticReferenceScan)
        exitwhen whichUnit == null
        call GroupRemoveUnit(automaticReferenceScan, whichUnit)
        if GetUnitTypeId(whichUnit) == 0 or not IsAutomaticReference(whichUnit, FallenHeroState_IsAlive(whichUnit), IsUnitLoaded(whichUnit)) then
            call GroupRemoveUnit(automaticReferences, whichUnit)
        endif
    endloop

    set whichUnit = null
endfunction

private function UpdateReferenceCache takes nothing returns nothing
    local integer index = 0

    call RevalidateAutomaticReferences()
    loop
        exitwhen index >= referenceCount
        set cachedReferenceUnit[index] = null
        set index = index + 1
    endloop
    call GroupClear(referenceCacheGroup)
    if cinematicDepth > 0 then
        // During a cinematic only the active scene and explicit scripted
        // references reveal surrounding population. Automatic references stay
        // protected themselves without keeping unrelated map areas active.
        call GroupAddGroup(cinematicReferences, referenceCacheGroup)
        if cinematicSceneReference != null then
            call GroupAddUnit(referenceCacheGroup, cinematicSceneReference)
        endif
        call GroupAddGroup(registeredReferences, referenceCacheGroup)
    endif
    if cinematicDepth == 0 or BlzGroupGetSize(referenceCacheGroup) == 0 then
        call GroupAddGroup(automaticReferences, referenceCacheGroup)
        call GroupAddGroup(registeredReferences, referenceCacheGroup)
        call AddPartyReferences(udg_Companion_Group)
        call AddPartyReferences(udg_TamedUnits)
        // The legacy group often contains obsolete NPC/dummy entries. Only its
        // player-controlled heroes and current companion/pet registrations reveal.
        call AddAllowedLegacyReferences()
    endif

    set referenceCount = 0
    set aiReferenceCount = 0
    call CacheReferenceGroup(referenceCacheGroup)
endfunction

private function RefreshAutomaticReferences takes nothing returns nothing
    local unit whichUnit
    local boolean isAlive
    local boolean isLoaded

    // Recheck existing revealers as well as this cycle's authoritative world
    // snapshot. This keeps ownership/death changes current without walking the
    // entire persistent inventory.
    call GroupClear(automaticReferenceScan)
    call GroupAddGroup(automaticReferences, automaticReferenceScan)
    call GroupAddGroup(worldScanUnits, automaticReferenceScan)
    loop
        set whichUnit = FirstOfGroup(automaticReferenceScan)
        exitwhen whichUnit == null
        call GroupRemoveUnit(automaticReferenceScan, whichUnit)
        if whichUnit != null and GetUnitTypeId(whichUnit) != 0 then
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            call UpdateAutomaticReference(whichUnit, isAlive, isLoaded)
        else
            call GroupRemoveUnit(automaticReferences, whichUnit)
        endif
    endloop
    call UpdateReferenceCache()
    set whichUnit = null
endfunction

private function IsWithinHideRange takes unit whichUnit returns boolean
    local real unitX = GetUnitX(whichUnit)
    local real unitY = GetUnitY(whichUnit)
    local real deltaX
    local real deltaY
    local integer index = 0

    loop
        exitwhen index >= referenceCount
        set deltaX = cachedReferenceX[index] - unitX
        set deltaY = cachedReferenceY[index] - unitY
        if deltaX * deltaX + deltaY * deltaY <= cachedReferenceHideDistanceSq[index] then
            return true
        endif
        set index = index + 1
    endloop
    return false
endfunction

private function IsTrackedReference takes unit whichUnit, boolean isAutomaticReference returns boolean
    return isAutomaticReference or IsUnitInGroup(whichUnit, registeredReferences) or whichUnit == cinematicSceneReference or IsUnitInGroup(whichUnit, cinematicReferences) or IsAllowedLegacyReference(whichUnit)
endfunction

private function IsProtected takes unit whichUnit, boolean isAutomaticReference returns boolean
    return IsTrackedReference(whichUnit, isAutomaticReference) or IsUnitInGroup(whichUnit, udg_UnitHider_IgnoredUnits) or GetUnitAbilityLevel(whichUnit, 'Aloc') > 0
endfunction

private function GetGridX takes real x returns integer
    local integer gridX = R2I((x - worldMinX) / cellWidth)

    if gridX < 0 then
        return 0
    elseif gridX >= GRID_AXIS then
        return GRID_AXIS - 1
    endif
    return gridX
endfunction

private function GetGridY takes real y returns integer
    local integer gridY = R2I((y - worldMinY) / cellHeight)

    if gridY < 0 then
        return 0
    elseif gridY >= GRID_AXIS then
        return GRID_AXIS - 1
    endif
    return gridY
endfunction

private function GetCellId takes unit whichUnit returns integer
    return GetGridX(GetUnitX(whichUnit)) + GetGridY(GetUnitY(whichUnit)) * GRID_AXIS
endfunction

private function RemoveHiddenTracking takes unit whichUnit returns nothing
    local integer handleId
    local integer encodedCell

    if whichUnit == null then
        return
    endif
    if managedHidden == 0 or hiddenCell == 0 then
        call GroupRemoveUnit(hiddenUnits, whichUnit)
        return
    endif
    set handleId = GetHandleId(whichUnit)
    set encodedCell = hiddenCell.integer[handleId]
    if encodedCell > 0 and hiddenCells[encodedCell - 1] != null then
        call GroupRemoveUnit(hiddenCells[encodedCell - 1], whichUnit)
    endif
    call hiddenCell.integer.remove(handleId)
    call managedHidden.boolean.remove(handleId)
    call GroupRemoveUnit(hiddenUnits, whichUnit)
endfunction

private function AddHiddenTracking takes unit whichUnit returns nothing
    local integer cellId

    if whichUnit == null then
        return
    endif
    call RemoveHiddenTracking(whichUnit)
    set cellId = GetCellId(whichUnit)
    if hiddenCells[cellId] == null then
        set hiddenCells[cellId] = CreateGroup()
    endif
    call GroupAddUnit(hiddenUnits, whichUnit)
    call GroupAddUnit(hiddenCells[cellId], whichUnit)
    set managedHidden.boolean[GetHandleId(whichUnit)] = true
    set hiddenCell.integer[GetHandleId(whichUnit)] = cellId + 1
endfunction

private function ShowOwned takes unit whichUnit, boolean show returns nothing
    set internalShowDepth = internalShowDepth + 1
    call ShowUnit(whichUnit, show)
    set internalShowDepth = internalShowDepth - 1
endfunction

private function ShowManaged takes unit whichUnit, boolean trackVisible returns nothing
    call RemoveHiddenTracking(whichUnit)
    call ShowOwned(whichUnit, true)
    if trackVisible then
        call GroupAddUnit(visibleUnits, whichUnit)
        if cinematicDepth > 0 then
            call GroupAddUnit(cinematicVisibleUnits, whichUnit)
        endif
    else
        call GroupRemoveUnit(visibleUnits, whichUnit)
    endif
    set sweepShownCount = sweepShownCount + 1
endfunction

private function HideManaged takes unit whichUnit returns nothing
    call GroupRemoveUnit(visibleUnits, whichUnit)
    call GroupRemoveUnit(cinematicVisibleUnits, whichUnit)
    call ShowOwned(whichUnit, false)
    call AddHiddenTracking(whichUnit)
    set sweepHiddenCount = sweepHiddenCount + 1
endfunction

private function ProcessUnit takes unit whichUnit returns nothing
    local boolean isAutomaticReference
    local boolean isAlive
    local boolean isLoaded

    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return
    endif

    set isAlive = FallenHeroState_IsAlive(whichUnit)
    set isLoaded = IsUnitLoaded(whichUnit)
    set isAutomaticReference = UpdateAutomaticReference(whichUnit, isAlive, isLoaded)
    if not enabled then
        return
    endif

    set sweepCheckedCount = sweepCheckedCount + 1

    // Repair ownership if an engine/script path made a managed unit visible
    // without passing through the ShowUnit hook.
    if IsManagedHidden(whichUnit) and not IsUnitHidden(whichUnit) then
        call RemoveHiddenTracking(whichUnit)
    endif

    if IsManagedHidden(whichUnit) then
        if isLoaded or not isAlive then
            return
        endif
        if IsProtected(whichUnit, isAutomaticReference) then
            call ShowManaged(whichUnit, false)
        else
            // Explicit lifecycle notifications also repair a relocated cell.
            call AddHiddenTracking(whichUnit)
        endif
        return
    endif

    // IsUnitHidden here means another system owns the hidden state.
    if IsUnitHidden(whichUnit) or not isAlive or isLoaded or IsProtected(whichUnit, isAutomaticReference) then
        call GroupRemoveUnit(visibleUnits, whichUnit)
        return
    endif

    if referenceCount == 0 then
        call HideManaged(whichUnit)
    elseif IsWithinHideRange(whichUnit) then
        call GroupAddUnit(visibleUnits, whichUnit)
    else
        call HideManaged(whichUnit)
    endif
endfunction

private function ProcessPendingUnits takes nothing returns nothing
    local unit whichUnit

    loop
        set whichUnit = FirstOfGroup(pendingUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(pendingUnits, whichUnit)
        call ProcessUnit(whichUnit)
    endloop

    set whichUnit = null
endfunction

private function ReconcileManagedHiddenVisibility takes nothing returns nothing
    local unit whichUnit

    // Validate only UnitHider-owned handles. This is used at authoritative
    // boundaries, never as a recurring world or hidden-population scan.
    set lastManagedVisibilityChecked = 0
    set lastManagedVisibilityRepaired = 0
    call GroupClear(worldScanUnits)
    call GroupAddGroup(hiddenUnits, worldScanUnits)
    loop
        set whichUnit = FirstOfGroup(worldScanUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(worldScanUnits, whichUnit)
        set lastManagedVisibilityChecked = lastManagedVisibilityChecked + 1
        if GetUnitTypeId(whichUnit) == 0 or not IsManagedHidden(whichUnit) then
            call RemoveHiddenTracking(whichUnit)
        elseif not IsUnitHidden(whichUnit) then
            // A BJ wrapper or engine transition showed a unit without the
            // native hook observing it. Reclassify that exact unit now.
            set lastManagedVisibilityRepaired = lastManagedVisibilityRepaired + 1
            call ProcessUnit(whichUnit)
        endif
    endloop

    set whichUnit = null
endfunction

private function FinishSweep takes nothing returns nothing
    // Include revealers discovered late in this sweep before the next begins.
    call UpdateReferenceCache()
    if debugEnabled then
        call BJDebugMsg("[UnitHider] Known: " + I2S(BlzGroupGetSize(knownUnits)) + " | Checked: " + I2S(sweepCheckedCount) + " | Hidden: " + I2S(sweepHiddenCount) + " | Shown: " + I2S(sweepShownCount) + " | Managed hidden: " + I2S(BlzGroupGetSize(hiddenUnits)) + " | References: " + I2S(referenceCount))
    endif
    set sweepCheckedCount = 0
    set sweepHiddenCount = 0
    set sweepShownCount = 0
endfunction

private function RevealCell takes integer cellId, real referenceX, real referenceY, real showDistanceSq returns nothing
    local group cellGroup = hiddenCells[cellId]
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
        elseif GetUnitTypeId(whichUnit) == 0 or not IsManagedHidden(whichUnit) then
            call GroupRemoveUnit(cellGroup, whichUnit)
            set count = BlzGroupGetSize(cellGroup)
        else
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            set isAutomaticReference = UpdateAutomaticReference(whichUnit, isAlive, isLoaded)
            set isProtected = IsProtected(whichUnit, isAutomaticReference)
            set deltaX = GetUnitX(whichUnit) - referenceX
            set deltaY = GetUnitY(whichUnit) - referenceY
            if isAlive and not isLoaded and (isProtected or deltaX * deltaX + deltaY * deltaY <= showDistanceSq) then
                call ShowManaged(whichUnit, not isProtected)
                set count = BlzGroupGetSize(cellGroup)
            else
                set index = index + 1
            endif
        endif
    endloop

    set whichUnit = null
    set cellGroup = null
endfunction

private function RevealNearReferences takes nothing returns nothing
    local integer referenceIndex = 0
    local integer minGridX
    local integer maxGridX
    local integer minGridY
    local integer maxGridY
    local integer gridX
    local integer gridY
    local real referenceX
    local real referenceY
    local real showDistance
    local real showDistanceSq

    loop
        exitwhen referenceIndex >= referenceCount
        set referenceX = cachedReferenceX[referenceIndex]
        set referenceY = cachedReferenceY[referenceIndex]
        set showDistance = cachedReferenceShowDistance[referenceIndex]
        set showDistanceSq = cachedReferenceShowDistanceSq[referenceIndex]
        set minGridX = GetGridX(referenceX - showDistance)
        set maxGridX = GetGridX(referenceX + showDistance)
        set minGridY = GetGridY(referenceY - showDistance)
        set maxGridY = GetGridY(referenceY + showDistance)
        set gridY = minGridY
        loop
            exitwhen gridY > maxGridY
            set gridX = minGridX
            loop
                exitwhen gridX > maxGridX
                call RevealCell(gridX + gridY * GRID_AXIS, referenceX, referenceY, showDistanceSq)
                set gridX = gridX + 1
            endloop
            set gridY = gridY + 1
        endloop
        set referenceIndex = referenceIndex + 1
    endloop
endfunction

private function ReclassifyVisibleUnits takes nothing returns nothing
    local unit whichUnit

    call GroupClear(visibleScanUnits)
    call GroupAddGroup(visibleUnits, visibleScanUnits)
    loop
        set whichUnit = FirstOfGroup(visibleScanUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(visibleScanUnits, whichUnit)
        call ProcessUnit(whichUnit)
    endloop
    call UpdateReferenceCache()
    set whichUnit = null
endfunction

private function BootstrapMap takes nothing returns nothing
    local unit whichUnit

    // The only automatic global enumeration: seed and classify preplaced units
    // once after map systems have initialized. Later discovery is event-driven.
    call PrepareWorldScan()
    call RefreshAutomaticReferences()
    loop
        set whichUnit = FirstOfGroup(worldScanUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(worldScanUnits, whichUnit)
        call ProcessUnit(whichUnit)
    endloop
    call UpdateReferenceCache()
    call RevealNearReferences()
    set initialized = true
    set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
    set managedVisibilityVerificationPending = true
    call GroupClear(pendingUnits)
    call FinishSweep()
    set whichUnit = null
endfunction

private function ClearCinematicState takes nothing returns nothing
    set cinematicDepth = 0
    set wasInCinematic = false
    set cinematicSceneReference = null
    call GroupClear(cinematicReferences)
endfunction

private function ReconcileCinematicVisible takes nothing returns nothing
    local unit whichUnit

    loop
        set whichUnit = FirstOfGroup(cinematicVisibleUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(cinematicVisibleUnits, whichUnit)
        call ProcessUnit(whichUnit)
    endloop

    set whichUnit = null
endfunction

private function RestoreNormalVisibility takes nothing returns nothing
    call ClearCinematicState()
    call ProcessPendingUnits()
    call UpdateReferenceCache()
    set managedVisibilityVerificationPending = false
    call ReconcileManagedHiddenVisibility()
    call ReclassifyVisibleUnits()
    call ReconcileCinematicVisible()
    call UpdateReferenceCache()
    call RevealNearReferences()
    set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
    call FinishSweep()
endfunction

private function ProcessBatch takes nothing returns nothing
    if not enabled then
        return
    endif
    // One delayed full bootstrap catches every preplaced visible unit.
    if not initialized then
        call BootstrapMap()
        if udg_InCinematic then
            set wasInCinematic = true
        endif
        return
    endif
    // Recover from an unmatched cinematic API call without enumerating the map.
    if cinematicDepth > 0 and not udg_InCinematic then
        call RestoreNormalVisibility()
        return
    endif
    // Legacy cinematics without Begin/End remain a compatibility suspension.
    if cinematicDepth == 0 and udg_InCinematic then
        set wasInCinematic = true
        return
    endif
    if cinematicDepth == 0 and wasInCinematic then
        set wasInCinematic = false
        call ProcessPendingUnits()
        call UpdateReferenceCache()
        set managedVisibilityVerificationPending = false
        call ReconcileManagedHiddenVisibility()
        call ReclassifyVisibleUnits()
        call RevealNearReferences()
        set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
        call FinishSweep()
        return
    endif

    // Events and ShowUnit ownership transfers feed this exact pending set.
    call ProcessPendingUnits()
    call UpdateReferenceCache()
    if managedVisibilityVerificationPending then
        set managedVisibilityVerificationPending = false
        call ReconcileManagedHiddenVisibility()
        call UpdateReferenceCache()
    endif
    call RevealNearReferences()
    // Movement has no native position-changed event. Recheck only currently
    // shown eligible candidates every 0.50 seconds, never the whole map.
    set ticksUntilVisibleSweep = ticksUntilVisibleSweep - 1
    if ticksUntilVisibleSweep <= 0 then
        call ReclassifyVisibleUnits()
        call RevealNearReferences()
        set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
        call FinishSweep()
    endif
endfunction

private function UnhideAllManaged takes nothing returns nothing
    local unit whichUnit

    loop
        set whichUnit = FirstOfGroup(hiddenUnits)
        exitwhen whichUnit == null
        call RemoveHiddenTracking(whichUnit)
        call ShowOwned(whichUnit, true)
    endloop
    call GroupClear(visibleUnits)
    call GroupClear(visibleScanUnits)
    call GroupClear(pendingUnits)
    call GroupClear(cinematicVisibleUnits)
    set ticksUntilVisibleSweep = 0
    set managedVisibilityVerificationPending = false

    set whichUnit = null
endfunction

public function DebugHideAllExceptTracked takes nothing returns integer
    local integer hiddenCount = 0
    local unit whichUnit
    local boolean isAlive
    local boolean isLoaded
    local boolean isAutomaticReference
    local boolean wasManaged

    call PrepareWorldScan()
    call RefreshAutomaticReferences()

    loop
        set whichUnit = FirstOfGroup(worldScanUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(worldScanUnits, whichUnit)
        if GetUnitTypeId(whichUnit) != 0 then
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            set isAutomaticReference = UpdateAutomaticReference(whichUnit, isAlive, isLoaded)
            set wasManaged = IsManagedHidden(whichUnit)
            call GroupRemoveUnit(pendingUnits, whichUnit)
            if IsTrackedReference(whichUnit, isAutomaticReference) then
                if wasManaged then
                    call ShowManaged(whichUnit, false)
                endif
            elseif isAlive and not isLoaded and not wasManaged and not IsUnitHidden(whichUnit) and not IsUnitInGroup(whichUnit, udg_UnitHider_IgnoredUnits) and GetUnitAbilityLevel(whichUnit, 'Aloc') == 0 then
                call HideManaged(whichUnit)
                set hiddenCount = hiddenCount + 1
            endif
        endif
    endloop

    call UpdateReferenceCache()
    set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
    set whichUnit = null
    return hiddenCount
endfunction

public function DebugUnhideAllExceptTracked takes nothing returns integer
    local integer shownCount = BlzGroupGetSize(hiddenUnits)

    call UnhideAllManaged()
    return shownCount
endfunction

public function DebugAudit takes player whichPlayer returns nothing
    local integer totalCount = 0
    local integer exemptCount = 0
    local integer eligibleHiddenCount = 0
    local integer managedShownCount = 0
    local integer foreignHiddenCount = 0
    local integer nearVisibleCount = 0
    local integer farVisibleCount = 0
    local unit whichUnit
    local boolean isAlive
    local boolean isLoaded
    local boolean isAutomaticReference
    local integer referenceIndex = 0
    local string referenceKind
    local string state = "enabled"

    call PrepareInventoryScan()
    call RefreshAutomaticReferences()
    loop
        set whichUnit = FirstOfGroup(worldScanUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(worldScanUnits, whichUnit)
        if GetUnitTypeId(whichUnit) != 0 then
            set totalCount = totalCount + 1
            set isAlive = FallenHeroState_IsAlive(whichUnit)
            set isLoaded = IsUnitLoaded(whichUnit)
            set isAutomaticReference = IsAutomaticReference(whichUnit, isAlive, isLoaded)
            if IsManagedHidden(whichUnit) and not IsUnitHidden(whichUnit) then
                set managedShownCount = managedShownCount + 1
            elseif not isAlive or isLoaded or IsProtected(whichUnit, isAutomaticReference) then
                set exemptCount = exemptCount + 1
            elseif IsManagedHidden(whichUnit) then
                set eligibleHiddenCount = eligibleHiddenCount + 1
            elseif IsUnitHidden(whichUnit) then
                set foreignHiddenCount = foreignHiddenCount + 1
            elseif IsWithinHideRange(whichUnit) then
                set nearVisibleCount = nearVisibleCount + 1
            else
                set farVisibleCount = farVisibleCount + 1
            endif
        endif
    endloop
    if not enabled then
        set state = "disabled"
    endif
    if cinematicDepth > 0 then
        set state = state + ", cinematic managed"
    elseif udg_InCinematic then
        set state = state + ", cinematic compatibility suspension"
    endif
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "|cffffcc00[UnitHider audit]|r " + state + " | references=" + I2S(referenceCount) + " (full=" + I2S(referenceCount - aiReferenceCount) + ", AI=" + I2S(aiReferenceCount) + ")")
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Inventory=" + I2S(totalCount) + " | known=" + I2S(BlzGroupGetSize(knownUnits)) + " | exempt=" + I2S(exemptCount) + " | managed hidden=" + I2S(eligibleHiddenCount) + " | managed shown mismatch=" + I2S(managedShownCount) + " | foreign hidden=" + I2S(foreignHiddenCount))
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Visible near references=" + I2S(nearVisibleCount) + " | visible outside hide range=" + I2S(farVisibleCount) + " | pending=" + I2S(BlzGroupGetSize(pendingUnits)))
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Ranges: full=" + I2S(R2I(fullShowDistance)) + "/" + I2S(R2I(fullHideDistance)) + " | autonomous AI=" + I2S(R2I(AI_SHOW_DISTANCE)) + "/" + I2S(R2I(AI_HIDE_DISTANCE)) + " (show/hide)")
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Last cinematic: begin hidden=" + I2S(lastCinematicBeginHiddenBefore) + "->" + I2S(lastCinematicBeginHiddenAfter) + " visible=" + I2S(lastCinematicBeginVisibleAfter) + " | end candidates=" + I2S(lastCinematicEndCandidates) + " hidden=" + I2S(lastCinematicEndHiddenBefore) + "->" + I2S(lastCinematicEndHiddenAfter) + " visible=" + I2S(lastCinematicEndVisibleAfter))
    call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Last managed-hidden verification: checked=" + I2S(lastManagedVisibilityChecked) + " | repaired=" + I2S(lastManagedVisibilityRepaired))
    loop
        exitwhen referenceIndex >= referenceCount or referenceIndex >= DEBUG_REFERENCE_LIMIT
        set whichUnit = cachedReferenceUnit[referenceIndex]
        if whichUnit == cinematicSceneReference or IsUnitInGroup(whichUnit, cinematicReferences) then
            set referenceKind = "cinematic"
        elseif IsUnitInGroup(whichUnit, registeredReferences) then
            set referenceKind = "explicit"
        elseif IsPlayerControlledHero(whichUnit) then
            set referenceKind = "player hero"
        elseif udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group) then
            set referenceKind = "companion"
        elseif udg_TamedUnits != null and IsUnitInGroup(whichUnit, udg_TamedUnits) then
            set referenceKind = "pet"
        elseif IsConfiguredAIHero(whichUnit) then
            set referenceKind = "autonomous AI"
        else
            set referenceKind = "legacy"
        endif
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "Ref " + I2S(referenceIndex + 1) + ": " + GetUnitName(whichUnit) + " | " + referenceKind + " | owner=" + I2S(GetPlayerId(GetOwningPlayer(whichUnit)) + 1) + " | x=" + I2S(R2I(cachedReferenceX[referenceIndex])) + " y=" + I2S(R2I(cachedReferenceY[referenceIndex])) + " | range=" + I2S(R2I(cachedReferenceShowDistance[referenceIndex])) + "/" + I2S(R2I(cachedReferenceHideDistance[referenceIndex])))
        set referenceIndex = referenceIndex + 1
    endloop
    if referenceCount > DEBUG_REFERENCE_LIMIT then
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, I2S(referenceCount - DEBUG_REFERENCE_LIMIT) + " additional references omitted.")
    endif
    set whichUnit = null
    set whichPlayer = null
endfunction

public function SetHidingDistance takes real newDistance returns nothing
    if newDistance < 0.00 then
        set newDistance = 0.00
    endif
    set fullHideDistance = newDistance
    set fullHideDistanceSq = newDistance * newDistance
    set fullShowDistance = newDistance
    set fullShowDistanceSq = newDistance * newDistance
endfunction

public function SetUnhidingDistance takes real newDistance returns nothing
    if newDistance < 0.00 then
        set newDistance = 0.00
    elseif newDistance > fullHideDistance then
        set newDistance = fullHideDistance
    endif
    set fullShowDistance = newDistance
    set fullShowDistanceSq = newDistance * newDistance
endfunction

public function SetDebugEnabled takes boolean enable returns nothing
    set debugEnabled = enable
    set udg_UnitHider_debug = enable
endfunction

public function RegisterCinematicReference takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call GroupAddUnit(knownUnits, whichUnit)
    call GroupAddUnit(cinematicReferences, whichUnit)
    call GroupAddUnit(cinematicVisibleUnits, whichUnit)
    if IsManagedHidden(whichUnit) then
        call ShowManaged(whichUnit, false)
    endif
    call UpdateReferenceCache()
    if enabled and cinematicDepth > 0 then
        call RevealNearReferences()
    endif
endfunction

public function UnregisterCinematicReference takes unit whichUnit returns nothing
    call GroupRemoveUnit(cinematicReferences, whichUnit)
    if whichUnit == cinematicSceneReference then
        set cinematicSceneReference = null
    endif
    call UpdateReferenceCache()
    if enabled and cinematicDepth > 0 then
        call ProcessUnit(whichUnit)
        call ReclassifyVisibleUnits()
        call RevealNearReferences()
        set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
    endif
endfunction

public function BeginCinematic takes unit sceneReference returns nothing
    set lastCinematicBeginHiddenBefore = BlzGroupGetSize(hiddenUnits)
    // Cinematic ON is shared boolean state. A new scene replaces the previous
    // primary reference without discarding additional registered scene anchors.
    set cinematicSceneReference = sceneReference
    set cinematicDepth = 1
    set wasInCinematic = true
    if sceneReference != null then
        call GroupAddUnit(knownUnits, sceneReference)
        call GroupAddUnit(cinematicVisibleUnits, sceneReference)
        if IsManagedHidden(sceneReference) then
            call ShowManaged(sceneReference, false)
        endif
    endif
    if enabled then
        if not initialized then
            call BootstrapMap()
        else
            call ProcessPendingUnits()
            call UpdateReferenceCache()
            call ReclassifyVisibleUnits()
            call RevealNearReferences()
            set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
            call FinishSweep()
        endif
    endif
    set lastCinematicBeginHiddenAfter = BlzGroupGetSize(hiddenUnits)
    set lastCinematicBeginVisibleAfter = BlzGroupGetSize(cinematicVisibleUnits)
endfunction

public function EndCinematic takes nothing returns nothing
    set lastCinematicEndCandidates = BlzGroupGetSize(cinematicVisibleUnits)
    set lastCinematicEndHiddenBefore = BlzGroupGetSize(hiddenUnits)
    if enabled then
        if initialized then
            call RestoreNormalVisibility()
        else
            call ClearCinematicState()
            call BootstrapMap()
            call ReconcileCinematicVisible()
        endif
    else
        call ClearCinematicState()
        call GroupClear(cinematicVisibleUnits)
    endif
    set lastCinematicEndHiddenAfter = BlzGroupGetSize(hiddenUnits)
    set lastCinematicEndVisibleAfter = BlzGroupGetSize(visibleUnits)
endfunction

public function SetSystemEnabled takes boolean enable returns nothing
    if enabled == enable then
        set udg_UnitHider_SetSystem = enable
        return
    endif
    set enabled = enable
    set udg_UnitHider_SetSystem = enable
    if enable then
        call TimerStart(updateTimer, TICK_INTERVAL, true, function ProcessBatch)
        set ticksUntilVisibleSweep = 0
        set initialized = false
    else
        call UnhideAllManaged()
        set initialized = false
    endif
    if debugEnabled then
        if enable then
            call BJDebugMsg("[UnitHider] System enabled")
        else
            call BJDebugMsg("[UnitHider] System disabled")
        endif
    endif
endfunction

public function DebugPauseProcessing takes nothing returns nothing
    set enabled = false
    set udg_UnitHider_SetSystem = false
    call PauseTimer(updateTimer)
endfunction

public function RegisterReference takes unit whichUnit returns nothing
    if whichUnit != null then
        call GroupAddUnit(knownUnits, whichUnit)
        call GroupAddUnit(registeredReferences, whichUnit)
        if IsManagedHidden(whichUnit) then
            call ShowManaged(whichUnit, false)
        endif
        call UpdateReferenceCache()
        if enabled then
            // Explicit references take effect before the next timer update so
            // scripted camera cuts cannot expose an unrevealed area.
            call RevealNearReferences()
        endif
    endif
endfunction

public function UnregisterReference takes unit whichUnit returns nothing
    call GroupRemoveUnit(registeredReferences, whichUnit)
    call UpdateReferenceCache()
    if initialized and enabled and not udg_InCinematic then
        call ProcessUnit(whichUnit)
        call ReclassifyVisibleUnits()
        call RevealNearReferences()
        set ticksUntilVisibleSweep = VISIBLE_SWEEP_TICKS
    endif
endfunction

public function SetUnitIgnored takes unit whichUnit, boolean ignored returns nothing
    if whichUnit == null then
        return
    endif
    call GroupAddUnit(knownUnits, whichUnit)
    if ignored then
        call GroupAddUnit(udg_UnitHider_IgnoredUnits, whichUnit)
        if IsManagedHidden(whichUnit) then
            call ShowManaged(whichUnit, false)
        endif
    else
        call GroupRemoveUnit(udg_UnitHider_IgnoredUnits, whichUnit)
        if initialized and enabled and not udg_InCinematic then
            call ProcessUnit(whichUnit)
        endif
    endif
endfunction

public function IsUnitHiddenBySystem takes unit whichUnit returns boolean
    return IsManagedHidden(whichUnit)
endfunction

public function Refresh takes nothing returns nothing
    // Explicit maintenance API: the next timer tick performs a fresh visible
    // world bootstrap. Normal timer and cinematic paths never call this.
    set ticksUntilVisibleSweep = 0
    set initialized = false
endfunction

public function StartHideUnitsSystem takes nothing returns nothing
    call SetDebugEnabled(false)
    call SetSystemEnabled(true)
endfunction

private function QueueUnit takes unit whichUnit returns nothing
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return
    endif
    call GroupAddUnit(knownUnits, whichUnit)
    call GroupAddUnit(pendingUnits, whichUnit)
    set ticksUntilVisibleSweep = 0
endfunction

public function NotifyUnitRelocated takes unit whichUnit returns nothing
    call QueueUnit(whichUnit)
endfunction

private function OnSetUnitX takes unit whichUnit, real newX returns nothing
    call QueueUnit(whichUnit)
endfunction
hook SetUnitX OnSetUnitX

private function OnSetUnitY takes unit whichUnit, real newY returns nothing
    call QueueUnit(whichUnit)
endfunction
hook SetUnitY OnSetUnitY

private function OnSetUnitPosition takes unit whichUnit, real newX, real newY returns nothing
    call QueueUnit(whichUnit)
endfunction
hook SetUnitPosition OnSetUnitPosition

private function OnSetUnitPositionLoc takes unit whichUnit, location whichLocation returns nothing
    call QueueUnit(whichUnit)
endfunction
hook SetUnitPositionLoc OnSetUnitPositionLoc

// Foreign visibility calls transfer ownership. A shown unit is reclassified
// after the original native or BJ call completes on the next active update.
private function TrackExternalVisibilityChange takes unit whichUnit, boolean show returns nothing
    if internalShowDepth == 0 and whichUnit != null then
        call RemoveHiddenTracking(whichUnit)
        call GroupRemoveUnit(visibleUnits, whichUnit)
        if show and enabled then
            call QueueUnit(whichUnit)
            if cinematicDepth > 0 then
                call GroupAddUnit(cinematicVisibleUnits, whichUnit)
            endif
        else
            call GroupRemoveUnit(pendingUnits, whichUnit)
            call GroupRemoveUnit(cinematicVisibleUnits, whichUnit)
        endif
    endif
endfunction

private function OnShowUnit takes unit whichUnit, boolean show returns nothing
    call TrackExternalVisibilityChange(whichUnit, show)
endfunction
hook ShowUnit OnShowUnit

// GUI Unit - Show/Hide actions call these Blizzard wrappers. Their internal
// native ShowUnit calls live in blizzard.j and are not rewritten by the hook
// above, so observe the wrappers explicitly.
private function OnShowUnitShow takes unit whichUnit returns nothing
    if whichUnit != null and not (IsUnitType(whichUnit, UNIT_TYPE_HERO) and IsUnitDeadBJ(whichUnit)) then
        call TrackExternalVisibilityChange(whichUnit, true)
    endif
endfunction
hook ShowUnitShow OnShowUnitShow

private function OnShowUnitHide takes unit whichUnit returns nothing
    call TrackExternalVisibilityChange(whichUnit, false)
endfunction
hook ShowUnitHide OnShowUnitHide

private function OnUnitEnter takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()

    call QueueUnit(whichUnit)
    set whichUnit = null
endfunction

private function OnUnitFinalized takes nothing returns nothing
    local unit whichUnit = udg_UDexUnits[udg_UDex]

    call QueueUnit(whichUnit)
    set whichUnit = null
endfunction

private function OnUnitLifecycleChanged takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()

    call QueueUnit(whichUnit)
    set whichUnit = null
endfunction

private function OnUnitLoaded takes nothing returns nothing
    local unit whichUnit = GetLoadedUnit()

    call QueueUnit(whichUnit)
    set whichUnit = null
endfunction

private function OnUnitCargoChanged takes nothing returns nothing
    local unit whichUnit = udg_UDexUnits[udg_UDex]

    // Unit Event supplies both load and unload transitions. Reclassifying the
    // exact cargo unit also repairs its hidden spatial cell after unloading.
    call QueueUnit(whichUnit)
    set whichUnit = null
endfunction

private function OnUnitRevived takes nothing returns nothing
    local unit whichUnit = udg_UDexUnits[udg_UDex]

    call QueueUnit(whichUnit)
    set whichUnit = null
endfunction

private function OnUnitDeath takes nothing returns nothing
    local unit whichUnit = UnitDeathEvent_GetDyingUnit()

    if whichUnit != null then
        call GroupAddUnit(knownUnits, whichUnit)
        call GroupRemoveUnit(visibleUnits, whichUnit)
        call GroupRemoveUnit(visibleScanUnits, whichUnit)
        call GroupRemoveUnit(pendingUnits, whichUnit)
        call GroupRemoveUnit(cinematicVisibleUnits, whichUnit)
        call GroupRemoveUnit(automaticReferences, whichUnit)
        call UpdateReferenceCache()
        set ticksUntilVisibleSweep = 0
    endif
    set whichUnit = null
endfunction

private function OnUnitDeindex takes nothing returns nothing
    local unit whichUnit = udg_UDexUnits[udg_UDex]
    local integer handleId = 0

    if whichUnit == cinematicSceneReference then
        set cinematicSceneReference = null
    endif
    if whichUnit != null then
        set handleId = GetHandleId(whichUnit)
    endif
    call RemoveHiddenTracking(whichUnit)
    if handleId != 0 then
        call managedHidden.boolean.remove(handleId)
        call hiddenCell.integer.remove(handleId)
    endif
    call GroupRemoveUnit(knownUnits, whichUnit)
    call GroupRemoveUnit(visibleUnits, whichUnit)
    call GroupRemoveUnit(visibleScanUnits, whichUnit)
    call GroupRemoveUnit(pendingUnits, whichUnit)
    call GroupRemoveUnit(worldScanUnits, whichUnit)
    call GroupRemoveUnit(automaticReferences, whichUnit)
    call GroupRemoveUnit(automaticReferenceScan, whichUnit)
    call GroupRemoveUnit(registeredReferences, whichUnit)
    call GroupRemoveUnit(cinematicReferences, whichUnit)
    call GroupRemoveUnit(cinematicVisibleUnits, whichUnit)
    call UpdateReferenceCache()
    set ticksUntilVisibleSweep = 0
    set whichUnit = null
endfunction

private function Init takes nothing returns nothing
    local rect worldBounds = GetWorldBounds()
    local trigger finalizeTrigger = CreateTrigger()
    local trigger deindexTrigger = CreateTrigger()
    local trigger reviveTrigger = CreateTrigger()
    local trigger transformTrigger = CreateTrigger()
    local trigger cargoTrigger = CreateTrigger()

    if udg_UnitHider_ReferenceGroup == null then
        set udg_UnitHider_ReferenceGroup = CreateGroup()
    endif
    if udg_UnitHider_IgnoredUnits == null then
        set udg_UnitHider_IgnoredUnits = CreateGroup()
    endif
    set udg_UnitHider_SetSystem = true
    set udg_UnitHider_debug = false
    set managedHidden = Table.create()
    set hiddenCell = Table.create()
    set mapBounds = worldBounds
    set worldMinX = GetRectMinX(worldBounds)
    set worldMinY = GetRectMinY(worldBounds)
    set cellWidth = (GetRectMaxX(worldBounds) - worldMinX) / I2R(GRID_AXIS)
    set cellHeight = (GetRectMaxY(worldBounds) - worldMinY) / I2R(GRID_AXIS)
    call Events_RegisterUnitEnter(function OnUnitEnter)
    call Events_RegisterPlayerUnitEvent(function OnUnitLifecycleChanged, EVENT_PLAYER_UNIT_CHANGE_OWNER)
    call Events_RegisterPlayerUnitEvent(function OnUnitLoaded, EVENT_PLAYER_UNIT_LOADED)
    call Events_RegisterPlayerUnitEvent(function OnUnitLifecycleChanged, EVENT_PLAYER_HERO_REVIVE_FINISH)
    call UnitDeathEvent_Register(function OnUnitDeath)
    call TriggerRegisterVariableEvent(finalizeTrigger, "udg_UnitIndexEvent", EQUAL, 1.50)
    call TriggerAddAction(finalizeTrigger, function OnUnitFinalized)
    call TriggerRegisterVariableEvent(deindexTrigger, "udg_UnitIndexEvent", EQUAL, 2.00)
    call TriggerAddAction(deindexTrigger, function OnUnitDeindex)
    call TriggerRegisterVariableEvent(reviveTrigger, "udg_DeathEvent", EQUAL, 2.00)
    call TriggerAddAction(reviveTrigger, function OnUnitRevived)
    call TriggerRegisterVariableEvent(transformTrigger, "udg_UnitTypeEvent", EQUAL, 1.00)
    call TriggerAddAction(transformTrigger, function OnUnitFinalized)
    call TriggerRegisterVariableEvent(cargoTrigger, "udg_CargoEvent", EQUAL, 1.00)
    call TriggerRegisterVariableEvent(cargoTrigger, "udg_CargoEvent", EQUAL, 2.00)
    call TriggerAddAction(cargoTrigger, function OnUnitCargoChanged)
    call TimerStart(updateTimer, TICK_INTERVAL, true, function ProcessBatch)
    set worldBounds = null
    set finalizeTrigger = null
    set deindexTrigger = null
    set reviveTrigger = null
    set transformTrigger = null
    set cargoTrigger = null
endfunction

endlibrary
