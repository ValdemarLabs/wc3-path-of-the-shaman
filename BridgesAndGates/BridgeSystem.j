library BridgeSystem initializer Init requires PatrolSystem
/*
    BridgeSystem

    Core bridge lanes:
        - C/D = top-of-bridge lane
        - A/B = under-bridge lane

    Slot order contract:
        - activate rect slot 1 = C, slot 2 = D
        - deactivate rect slot 1 = A, slot 2 = B

    Current traffic rules:
        - units entering C/D are forced to the opposite C/D rect
        - C/D controls the bridge open/closed state
        - A/B stays normal / free while no top-lane C/D unit is active
        - A/B forced movement is only used while top-lane C/D traffic is active
        - if top-lane traffic starts while units are already inside the bridge rect,
          those under-lane units are adopted into the A/B pass-through handling

    GUI integration:
        - top-lane units update udg_IsUnitOnBridge[GetUnitUserData(unit)]
        - under-lane units do not
*/

globals
    // CONFIGURATION =======================================================================
    private constant real BRIDGE_EXIT_OVERSHOOT = 100.0                    // units move past the opposite exit rect instead of stopping at its center. [Default: 100.0]
    private constant real BRIDGE_UNDER_BRIDGE_SNAP_MARGIN = 100.0          // default per-bridge snap margin used when an A/B unit must be pushed just outside the bridge rect. [Default: 200.0]
    private constant real BRIDGE_FORCED_DEST_REACHED_DISTANCE = 120.0      // forced move counts as reached when the unit is within this distance of the saved destination point. [Default: 120.0]
    private constant real BRIDGE_TOP_LANE_ENTRY_CENTER_REACHED_DISTANCE = 24.0 // top-lane entry-centering counts as reached when the unit is within this distance of the entry rect center. [Default: 24.0]
    private constant real BRIDGE_FORCED_PROGRESS_BUFFER = 16.0             // extra progress required past the far exit edge before the forced move is considered complete [Default: 16.0]
    private constant real BRIDGE_TOP_LANE_FORCE_EXIT_TIMEOUT = 20.0        // if a C/D unit does not finish its forced crossing within this many seconds, snap it past the opposite exit and release bridge state. [Default: 10.0]
    private constant real BRIDGE_VALIDATE_PERIOD = 0.50                    // periodic bridge validator interval [Default: 0.50]
    private constant integer BRIDGE_GHOST_VISIBLE_ABILITY_ID = 'Aeth'      // Fill this with the real Ghost (visible) rawcode later. [Default: 'Aeth']
    private constant boolean BRIDGE_RESUME_TOP_LANE_ORDERS = false         // restore the unit's saved order after finishing a C/D crossing. [Default: false]
    private constant boolean BRIDGE_RESUME_UNDER_LANE_ORDERS = true        // restore the unit's saved order after finishing an A/B crossing. [Default: true]
    private constant boolean BRIDGE_TOP_LANE_INVULNERABLE = true           // if true, top-lane C/D forced crossings temporarily set the unit invulnerable [Default: true]
    private constant boolean BRIDGE_AUTO_ADOPT_UNDER_UNITS = true          // if true, starting top-lane traffic adopts units already inside the bridge rect into A/B pass-through handling [Default: true]
    // CONFIGURATION ENDS ==================================================================

    // =====================================================================================
    // DO NOT EDIT THESE
    private constant integer BRIDGE_TYPE_SLOT_BASE = 1000
    private constant integer BRIDGE_DESTRUCT_SLOT_BASE = 2000
    private constant integer ENTRY_POINT_SLOT_BASE = 3000
    private constant integer ENTRY_BLOCKER_SLOT_BASE = 4000
    private constant integer ACTIVATE_RECT_SLOT_BASE = 5000
    private constant integer DEACTIVATE_RECT_SLOT_BASE = 6000
    private constant integer ACTIVATE_APPROACH_RECT_SLOT_BASE = 7000
    private constant integer DEACTIVATE_APPROACH_RECT_SLOT_BASE = 8000

    private constant integer BRIDGE_LANE_TOP = 1
    private constant integer BRIDGE_LANE_UNDER = 2

    private constant integer ORDER_KIND_NONE = 0
    private constant integer ORDER_KIND_IMMEDIATE = 1
    private constant integer ORDER_KIND_POINT = 2
    private constant integer ORDER_KIND_TARGET = 3

    // Unit state child keys in BridgeSystemTable
    private constant integer UNIT_STATE_BRIDGE_ID = 1
    private constant integer UNIT_STATE_LANE = 2
    private constant integer UNIT_STATE_ENTRY_SLOT = 3
    private constant integer UNIT_STATE_FORCED = 4
    private constant integer UNIT_STATE_WAITING = 5
    private constant integer UNIT_STATE_SUPPRESS = 6
    private constant integer UNIT_STATE_DEST_X = 7
    private constant integer UNIT_STATE_DEST_Y = 8
    private constant integer UNIT_STATE_PENDING_KIND = 9
    private constant integer UNIT_STATE_PENDING_ORDER_ID = 10
    private constant integer UNIT_STATE_PENDING_X = 11
    private constant integer UNIT_STATE_PENDING_Y = 12
    private constant integer UNIT_STATE_PENDING_TARGET = 13
    private constant integer UNIT_STATE_TARGET_SLOT_ENTERED = 14
    private constant integer UNIT_STATE_TOP_INVULNERABILITY_APPLIED = 15
    private constant integer UNIT_STATE_LAST_UNDER_SLOT = 16
    private constant integer UNIT_STATE_IGNORE_UNDER_SLOT = 17
    private constant integer UNIT_STATE_TOP_SHADOW_IMAGE = 18
    private constant integer UNIT_STATE_PATROL_PAUSED_BY_BRIDGE = 20
    private constant integer UNIT_STATE_FORCED_TIMEOUT_AT = 21
    private constant integer UNIT_STATE_TOP_LANE_ENTRY_CENTERING = 22

    private hashtable BridgeSystemTable = null
    private integer BridgeSystemCount = 0
    private integer BridgeSystemEnumBridgeId = 0

    private rect array BridgeSystemBridgeRect
    private string array BridgeSystemName

    private trigger array BridgeSystemActivateTrigger
    private trigger array BridgeSystemDeactivateTrigger
    private trigger array BridgeSystemLeaveTrigger
    private trigger array BridgeSystemActivateConditionTrigger
    private trigger array BridgeSystemDeactivateConditionTrigger
    private trigger array BridgeSystemActivateActionTrigger
    private trigger array BridgeSystemDeactivateActionTrigger

    private group array BridgeSystemTopActiveUnits
    private group array BridgeSystemUnderActiveUnits
    private group array BridgeSystemTopWaitingUnits
    private group array BridgeSystemUnderWaitingUnits
    private boolean array BridgeSystemTopLaneEntryCenteringEnabled
    private boolean array BridgeSystemTopLanePersistentOpen
    private boolean array BridgeSystemTopGhostCollisionEnabled
    private boolean array BridgeSystemUnderGhostCollisionEnabled

    // Tracks bridge-managed units for cleanup validation and bridge-rect adoption.
    private group BridgeSystemTrackedUnits = null
    private group BridgeSystemValidationGroup = null
    private group BridgeSystemRectEnumGroup = null
    private group BridgeSystemIgnoredUnits = null
    private group array BridgeSystemIgnoredGroups
    private integer BridgeSystemIgnoredGroupCount = 0
    private trigger BridgeSystemOrderTrigger = null
    private trigger BridgeSystemDeathTrigger = null
    private timer BridgeSystemClock = null
endglobals

private function BridgeSystem_GetBridgeIdFromTrigger takes trigger whichTrigger returns integer
    return LoadInteger(BridgeSystemTable, GetHandleId(whichTrigger), 0)
endfunction

private function BridgeSystem_GetUnitKey takes unit whichUnit returns integer
    return GetHandleId(whichUnit)
endfunction

private function BridgeSystem_GetUnitBridgeId takes unit whichUnit returns integer
    return LoadInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_BRIDGE_ID)
endfunction

private function BridgeSystem_GetUnitLane takes unit whichUnit returns integer
    return LoadInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_LANE)
endfunction

private function BridgeSystem_GetUnitEntrySlot takes unit whichUnit returns integer
    return LoadInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_ENTRY_SLOT)
endfunction

private function BridgeSystem_GetUnitLastUnderSlot takes unit whichUnit returns integer
    return LoadInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_LAST_UNDER_SLOT)
endfunction

private function BridgeSystem_GetUnitIgnoreUnderSlot takes unit whichUnit returns integer
    return LoadInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_IGNORE_UNDER_SLOT)
endfunction

private function BridgeSystem_IsUnitForced takes unit whichUnit returns boolean
    return LoadBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_FORCED)
endfunction

private function BridgeSystem_IsUnitWaiting takes unit whichUnit returns boolean
    return LoadBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_WAITING)
endfunction

private function BridgeSystem_ShouldIgnoreUnit takes unit whichUnit returns boolean
    local integer slot = 1

    if whichUnit == null then
        return false
    endif

    if BridgeSystemIgnoredUnits != null and IsUnitInGroup(whichUnit, BridgeSystemIgnoredUnits) then
        return true
    endif

    loop
        exitwhen slot > BridgeSystemIgnoredGroupCount
        if BridgeSystemIgnoredGroups[slot] != null and IsUnitInGroup(whichUnit, BridgeSystemIgnoredGroups[slot]) then
            return true
        endif
        set slot = slot + 1
    endloop

    return false
endfunction

private function BridgeSystem_IsControlledType takes integer bridgeId, integer destructTypeId returns boolean
    local integer slot = 1
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 1)

    loop
        exitwhen slot > slotCount
        if LoadInteger(BridgeSystemTable, bridgeId, BRIDGE_TYPE_SLOT_BASE + slot) == destructTypeId then
            return true
        endif
        set slot = slot + 1
    endloop

    return false
endfunction

private function BridgeSystem_EnumBridgeDestructables takes nothing returns nothing
    local destructable d = GetEnumDestructable()
    local integer count

    if BridgeSystem_IsControlledType(BridgeSystemEnumBridgeId, GetDestructableTypeId(d)) then
        set count = LoadInteger(BridgeSystemTable, BridgeSystemEnumBridgeId, 2) + 1
        call SaveInteger(BridgeSystemTable, BridgeSystemEnumBridgeId, 2, count)
        call SaveDestructableHandle(BridgeSystemTable, BridgeSystemEnumBridgeId, BRIDGE_DESTRUCT_SLOT_BASE + count, d)
        call KillDestructable(d)
    endif

    set d = null
endfunction

private function BridgeSystem_SetGuiUnitState takes unit whichUnit, boolean flag returns nothing
    local integer unitIndex

    if whichUnit == null then
        return
    endif

    set unitIndex = GetUnitUserData(whichUnit)
    if unitIndex > 0 then
        set udg_IsUnitOnBridge[unitIndex] = flag
    endif
endfunction

private function BridgeSystem_SetGhostCollision takes unit whichUnit, boolean flag returns nothing
    if whichUnit == null then
        return
    endif

    // Pathing toggle is the actual collision control; the optional ability is
    // only a visible/helper layer if the configured rawcode is valid.
    call SetUnitPathing(whichUnit, not flag)

    if BRIDGE_GHOST_VISIBLE_ABILITY_ID != 0 then
        if flag then
            if GetUnitAbilityLevel(whichUnit, BRIDGE_GHOST_VISIBLE_ABILITY_ID) == 0 then
                call UnitAddAbility(whichUnit, BRIDGE_GHOST_VISIBLE_ABILITY_ID)
            endif
        else
            if GetUnitAbilityLevel(whichUnit, BRIDGE_GHOST_VISIBLE_ABILITY_ID) > 0 then
                call UnitRemoveAbility(whichUnit, BRIDGE_GHOST_VISIBLE_ABILITY_ID)
            endif
        endif
    endif
endfunction

private function BridgeSystem_IsLaneGhostCollisionEnabled takes integer bridgeId, integer lane returns boolean
    if lane == BRIDGE_LANE_TOP then
        return BridgeSystemTopGhostCollisionEnabled[bridgeId]
    endif
    return BridgeSystemUnderGhostCollisionEnabled[bridgeId]
endfunction

private function BridgeSystem_ShouldResumeLaneOrders takes integer lane returns boolean
    if lane == BRIDGE_LANE_TOP then
        return BRIDGE_RESUME_TOP_LANE_ORDERS
    endif
    return BRIDGE_RESUME_UNDER_LANE_ORDERS
endfunction

private function BridgeSystem_HideTopLaneShadow takes unit whichUnit returns nothing
    local integer unitKey

    if whichUnit == null then
        return
    endif

    set unitKey = BridgeSystem_GetUnitKey(whichUnit)
    call SaveStr(BridgeSystemTable, unitKey, UNIT_STATE_TOP_SHADOW_IMAGE, BlzGetUnitStringField(whichUnit, UNIT_SF_SHADOW_IMAGE_UNIT))
    call BlzSetUnitStringField(whichUnit, UNIT_SF_SHADOW_IMAGE_UNIT, "NONE")
endfunction

private function BridgeSystem_GetCurrentTime takes nothing returns real
    if BridgeSystemClock == null then
        return 0.0
    endif
    return TimerGetElapsed(BridgeSystemClock)
endfunction

private function BridgeSystem_DoNothing takes nothing returns nothing
endfunction

private function BridgeSystem_PausePatrolIfActive takes unit whichUnit returns nothing
    local integer unitKey

    if whichUnit == null then
        return
    endif

    set unitKey = BridgeSystem_GetUnitKey(whichUnit)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_PATROL_PAUSED_BY_BRIDGE, false)
    if PatrolSystem_IsActive(whichUnit) then
        call PatrolSystem_PauseForRelocation(whichUnit)
        call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_PATROL_PAUSED_BY_BRIDGE, true)
    endif
endfunction

private function BridgeSystem_ResumePatrolIfPaused takes unit whichUnit, boolean skipCurrentWaypoint returns nothing
    local integer unitKey

    if whichUnit == null then
        return
    endif

    set unitKey = BridgeSystem_GetUnitKey(whichUnit)
    if LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_PATROL_PAUSED_BY_BRIDGE) then
        call PatrolSystem_ResumeFromCurrentPositionEx(whichUnit, skipCurrentWaypoint)
        call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_PATROL_PAUSED_BY_BRIDGE, false)
    endif
endfunction

function BridgeSystem_SetUnitOnBridge takes unit whichUnit, boolean flag returns nothing
    call BridgeSystem_SetGuiUnitState(whichUnit, flag)
endfunction

function BridgeSystem_SetUnitOnBridgeByCustomValue takes integer customValue, boolean flag returns nothing
    if customValue > 0 then
        set udg_IsUnitOnBridge[customValue] = flag
    endif
endfunction

function BridgeSystem_IsUnitOnBridge takes unit whichUnit returns boolean
    local integer unitIndex = 0

    if whichUnit == null then
        return false
    endif

    set unitIndex = GetUnitUserData(whichUnit)
    if unitIndex > 0 then
        return udg_IsUnitOnBridge[unitIndex]
    endif

    return false
endfunction

function BridgeSystem_SetTopLaneGhostCollision takes integer bridgeId, boolean flag returns nothing
    set BridgeSystemTopGhostCollisionEnabled[bridgeId] = flag
endfunction

function BridgeSystem_SetUnderLaneGhostCollision takes integer bridgeId, boolean flag returns nothing
    set BridgeSystemUnderGhostCollisionEnabled[bridgeId] = flag
endfunction

function BridgeSystem_SetTopLaneEntryCentering takes integer bridgeId, boolean flag returns nothing
    set BridgeSystemTopLaneEntryCenteringEnabled[bridgeId] = flag
endfunction

function BridgeSystem_SetTopLanePersistentOpen takes integer bridgeId, boolean flag returns nothing
    set BridgeSystemTopLanePersistentOpen[bridgeId] = flag
endfunction

function BridgeSystem_SetTopApproach takes integer bridgeId, integer slot, rect whichRect returns nothing
    if slot >= 1 and slot <= 2 then
        call SaveRectHandle(BridgeSystemTable, bridgeId, ACTIVATE_APPROACH_RECT_SLOT_BASE + slot, whichRect)
    endif
endfunction

function BridgeSystem_SetUnderApproach takes integer bridgeId, integer slot, rect whichRect returns nothing
    if slot >= 1 and slot <= 2 then
        call SaveRectHandle(BridgeSystemTable, bridgeId, DEACTIVATE_APPROACH_RECT_SLOT_BASE + slot, whichRect)
    endif
endfunction

private function BridgeSystem_IsInsideAnyBridgeRect takes unit whichUnit returns boolean
    local integer bridgeId = 1

    loop
        exitwhen bridgeId > BridgeSystemCount
        if RectContainsUnit(BridgeSystemBridgeRect[bridgeId], whichUnit) then
            return true
        endif
        set bridgeId = bridgeId + 1
    endloop

    return false
endfunction

private function BridgeSystem_RunActions takes trigger whichTrigger returns nothing
    if whichTrigger != null then
        call TriggerExecute(whichTrigger)
    endif
endfunction

private function BridgeSystem_KillEntryBlockers takes integer bridgeId returns nothing
    local integer slot = 1
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 3)
    local destructable d

    loop
        exitwhen slot > slotCount
        set d = LoadDestructableHandle(BridgeSystemTable, bridgeId, ENTRY_BLOCKER_SLOT_BASE + slot)
        if d != null then
            call KillDestructable(d)
        endif
        set slot = slot + 1
    endloop

    set d = null
endfunction

private function BridgeSystem_RestoreEntryBlockers takes integer bridgeId returns nothing
    local integer slot = 1
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 3)
    local destructable d

    loop
        exitwhen slot > slotCount
        set d = LoadDestructableHandle(BridgeSystemTable, bridgeId, ENTRY_BLOCKER_SLOT_BASE + slot)
        if d != null then
            call DestructableRestoreLife(d, GetDestructableMaxLife(d), false)
        endif
        set slot = slot + 1
    endloop

    set d = null
endfunction

private function BridgeSystem_RestoreBridgeDestructables takes integer bridgeId returns nothing
    local integer slot = 1
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 2)
    local destructable d

    loop
        exitwhen slot > slotCount
        set d = LoadDestructableHandle(BridgeSystemTable, bridgeId, BRIDGE_DESTRUCT_SLOT_BASE + slot)
        if d != null then
            call DestructableRestoreLife(d, GetDestructableMaxLife(d), false)
        endif
        set slot = slot + 1
    endloop

    set d = null
endfunction

private function BridgeSystem_KillBridgeDestructables takes integer bridgeId returns nothing
    local integer slot = 1
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 2)
    local destructable d

    loop
        exitwhen slot > slotCount
        set d = LoadDestructableHandle(BridgeSystemTable, bridgeId, BRIDGE_DESTRUCT_SLOT_BASE + slot)
        if d != null then
            call KillDestructable(d)
        endif
        set slot = slot + 1
    endloop

    set d = null
endfunction

private function BridgeSystem_OpenTopLane takes integer bridgeId returns nothing
    call BridgeSystem_KillEntryBlockers(bridgeId)
    call BridgeSystem_RestoreBridgeDestructables(bridgeId)
endfunction

private function BridgeSystem_CloseTopLane takes integer bridgeId returns nothing
    call BridgeSystem_KillBridgeDestructables(bridgeId)
    call BridgeSystem_RestoreEntryBlockers(bridgeId)
endfunction

private function BridgeSystem_IsTopLanePersistentOpen takes integer bridgeId returns boolean
    return BridgeSystemTopLanePersistentOpen[bridgeId]
endfunction

private function BridgeSystem_GetRectSlotBase takes integer lane returns integer
    if lane == BRIDGE_LANE_TOP then
        return ACTIVATE_RECT_SLOT_BASE
    endif
    return DEACTIVATE_RECT_SLOT_BASE
endfunction

private function BridgeSystem_GetRectCountKey takes integer lane returns integer
    if lane == BRIDGE_LANE_TOP then
        return 4
    endif
    return 5
endfunction

private function BridgeSystem_GetApproachRectSlotBase takes integer lane returns integer
    if lane == BRIDGE_LANE_TOP then
        return ACTIVATE_APPROACH_RECT_SLOT_BASE
    endif
    return DEACTIVATE_APPROACH_RECT_SLOT_BASE
endfunction

private function BridgeSystem_GetOppositeSlot takes integer entrySlot returns integer
    if entrySlot == 1 then
        return 2
    endif
    return 1
endfunction

private function BridgeSystem_GetLaneRectSlotForUnit takes integer bridgeId, integer lane, unit whichUnit returns integer
    local integer slot = 1
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, BridgeSystem_GetRectCountKey(lane))
    local integer slotBase = BridgeSystem_GetRectSlotBase(lane)
    local rect r

    loop
        exitwhen slot > slotCount
        set r = LoadRectHandle(BridgeSystemTable, bridgeId, slotBase + slot)
        if r != null and RectContainsUnit(r, whichUnit) then
            set r = null
            return slot
        endif
        set slot = slot + 1
    endloop

    set r = null
    return 0
endfunction

private function BridgeSystem_GetLaneRectCenterX takes integer bridgeId, integer lane, integer slot returns real
    local rect r = LoadRectHandle(BridgeSystemTable, bridgeId, BridgeSystem_GetRectSlotBase(lane) + slot)
    local real x = 0.0

    if r != null then
        set x = (GetRectMinX(r) + GetRectMaxX(r)) * 0.5
    endif

    set r = null
    return x
endfunction

private function BridgeSystem_GetLaneRectCenterY takes integer bridgeId, integer lane, integer slot returns real
    local rect r = LoadRectHandle(BridgeSystemTable, bridgeId, BridgeSystem_GetRectSlotBase(lane) + slot)
    local real y = 0.0

    if r != null then
        set y = (GetRectMinY(r) + GetRectMaxY(r)) * 0.5
    endif

    set r = null
    return y
endfunction

private function BridgeSystem_GetNearestLaneRectSlot takes integer bridgeId, integer lane, unit whichUnit returns integer
    local integer slot = 1
    local integer bestSlot = 0
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, BridgeSystem_GetRectCountKey(lane))
    local real unitX
    local real unitY
    local real centerX
    local real centerY
    local real dx
    local real dy
    local real distanceSq
    local real bestDistanceSq = 999999999.0

    if whichUnit == null then
        return 0
    endif

    set unitX = GetUnitX(whichUnit)
    set unitY = GetUnitY(whichUnit)

    loop
        exitwhen slot > slotCount
        set centerX = BridgeSystem_GetLaneRectCenterX(bridgeId, lane, slot)
        set centerY = BridgeSystem_GetLaneRectCenterY(bridgeId, lane, slot)
        set dx = unitX - centerX
        set dy = unitY - centerY
        set distanceSq = dx*dx + dy*dy
        if distanceSq < bestDistanceSq then
            set bestDistanceSq = distanceSq
            set bestSlot = slot
        endif
        set slot = slot + 1
    endloop

    return bestSlot
endfunction

private function BridgeSystem_GetLaneApproachSlotForUnit takes integer bridgeId, integer lane, unit whichUnit returns integer
    local integer slot = 1
    local integer slotBase = BridgeSystem_GetApproachRectSlotBase(lane)
    local rect r

    loop
        exitwhen slot > 2
        set r = LoadRectHandle(BridgeSystemTable, bridgeId, slotBase + slot)
        if r != null and RectContainsUnit(r, whichUnit) then
            set r = null
            return slot
        endif
        set slot = slot + 1
    endloop

    set r = null
    return 0
endfunction

private function BridgeSystem_ShouldRedirectApproachOrder takes integer bridgeId, integer lane, integer slot, real targetX, real targetY returns boolean
    local integer targetSlot
    local real sourceX
    local real sourceY
    local real laneDx
    local real laneDy
    local real laneDistance
    local real orderDx
    local real orderDy
    local real progress

    if RectContainsCoords(BridgeSystemBridgeRect[bridgeId], targetX, targetY) then
        return true
    endif

    set targetSlot = BridgeSystem_GetOppositeSlot(slot)
    set sourceX = BridgeSystem_GetLaneRectCenterX(bridgeId, lane, slot)
    set sourceY = BridgeSystem_GetLaneRectCenterY(bridgeId, lane, slot)
    set laneDx = BridgeSystem_GetLaneRectCenterX(bridgeId, lane, targetSlot) - sourceX
    set laneDy = BridgeSystem_GetLaneRectCenterY(bridgeId, lane, targetSlot) - sourceY
    set laneDistance = SquareRoot(laneDx*laneDx + laneDy*laneDy)

    if laneDistance <= 0.0 then
        return false
    endif

    set orderDx = targetX - sourceX
    set orderDy = targetY - sourceY
    set progress = (orderDx*laneDx + orderDy*laneDy) / laneDistance
    return progress >= 32.0
endfunction

private function BridgeSystem_IsInsideLaneRects takes integer bridgeId, integer lane, unit whichUnit returns boolean
    local integer slot = 1
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, BridgeSystem_GetRectCountKey(lane))
    local integer slotBase = BridgeSystem_GetRectSlotBase(lane)
    local rect r

    loop
        exitwhen slot > slotCount
        set r = LoadRectHandle(BridgeSystemTable, bridgeId, slotBase + slot)
        if r != null and RectContainsUnit(r, whichUnit) then
            set r = null
            return true
        endif
        set slot = slot + 1
    endloop

    set r = null
    return false
endfunction

private function BridgeSystem_IsUnitInsideLaneSlot takes integer bridgeId, integer lane, integer slot, unit whichUnit returns boolean
    local rect r = LoadRectHandle(BridgeSystemTable, bridgeId, BridgeSystem_GetRectSlotBase(lane) + slot)
    local boolean result = false

    if r != null then
        set result = RectContainsUnit(r, whichUnit)
    endif

    set r = null
    return result
endfunction

private function BridgeSystem_IsInsideLaneFlow takes integer bridgeId, integer lane, unit whichUnit returns boolean
    if RectContainsUnit(BridgeSystemBridgeRect[bridgeId], whichUnit) then
        return true
    endif
    return BridgeSystem_IsInsideLaneRects(bridgeId, lane, whichUnit)
endfunction

private function BridgeSystem_HasReachedForcedDestination takes unit whichUnit returns boolean
    local integer bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    local integer lane = BridgeSystem_GetUnitLane(whichUnit)
    local integer entrySlot = BridgeSystem_GetUnitEntrySlot(whichUnit)
    local integer unitKey = BridgeSystem_GetUnitKey(whichUnit)
    local integer targetSlot
    local rect targetRect
    local real currentX
    local real currentY
    local real sourceX
    local real sourceY
    local real targetCenterX
    local real targetCenterY
    local real pathDx
    local real pathDy
    local real pathDistance
    local real edgeDistance
    local real edgeX
    local real edgeY
    local real progress
    local real dx
    local real dy

    if whichUnit == null or bridgeId <= 0 or not BridgeSystem_IsUnitForced(whichUnit) then
        return false
    endif

    set currentX = GetUnitX(whichUnit)
    set currentY = GetUnitY(whichUnit)
    set dx = currentX - LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_X)
    set dy = currentY - LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_Y)
    if LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TOP_LANE_ENTRY_CENTERING) then
        return dx*dx + dy*dy <= BRIDGE_TOP_LANE_ENTRY_CENTER_REACHED_DISTANCE*BRIDGE_TOP_LANE_ENTRY_CENTER_REACHED_DISTANCE
    endif
    if dx*dx + dy*dy <= BRIDGE_FORCED_DEST_REACHED_DISTANCE*BRIDGE_FORCED_DEST_REACHED_DISTANCE then
        return true
    endif

    set targetSlot = BridgeSystem_GetOppositeSlot(entrySlot)
    if not RectContainsUnit(BridgeSystemBridgeRect[bridgeId], whichUnit) then
        set sourceX = BridgeSystem_GetLaneRectCenterX(bridgeId, lane, entrySlot)
        set sourceY = BridgeSystem_GetLaneRectCenterY(bridgeId, lane, entrySlot)
        set targetCenterX = BridgeSystem_GetLaneRectCenterX(bridgeId, lane, targetSlot)
        set targetCenterY = BridgeSystem_GetLaneRectCenterY(bridgeId, lane, targetSlot)
        set pathDx = targetCenterX - sourceX
        set pathDy = targetCenterY - sourceY
        set pathDistance = SquareRoot(pathDx*pathDx + pathDy*pathDy)
        if pathDistance > 0.0 then
            set targetRect = LoadRectHandle(BridgeSystemTable, bridgeId, BridgeSystem_GetRectSlotBase(lane) + targetSlot)
            set edgeDistance = 0.0
            set edgeX = 999999.0
            set edgeY = 999999.0
            if targetRect != null then
                if pathDx != 0.0 then
                    set edgeX = ((GetRectMaxX(targetRect) - GetRectMinX(targetRect)) * 0.5) / RAbsBJ(pathDx / pathDistance)
                endif
                if pathDy != 0.0 then
                    set edgeY = ((GetRectMaxY(targetRect) - GetRectMinY(targetRect)) * 0.5) / RAbsBJ(pathDy / pathDistance)
                endif
                if edgeX < edgeY then
                    set edgeDistance = edgeX
                else
                    set edgeDistance = edgeY
                endif
            endif
            set progress = ((currentX - sourceX) * pathDx + (currentY - sourceY) * pathDy) / pathDistance
            if progress >= pathDistance + edgeDistance + BRIDGE_FORCED_PROGRESS_BUFFER then
                set targetRect = null
                return true
            endif
        endif
    endif

    set targetRect = null
    return false
endfunction

private function BridgeSystem_HasActiveLaneUnits takes integer bridgeId, integer lane returns boolean
    if lane == BRIDGE_LANE_TOP then
        return CountUnitsInGroup(BridgeSystemTopActiveUnits[bridgeId]) > 0
    endif
    return CountUnitsInGroup(BridgeSystemUnderActiveUnits[bridgeId]) > 0
endfunction

private function BridgeSystem_IsUnderLaneControlActive takes integer bridgeId returns boolean
    return BridgeSystem_HasActiveLaneUnits(bridgeId, BRIDGE_LANE_TOP)
endfunction

private function BridgeSystem_GetPendingTarget takes nothing returns widget
    local widget w = GetOrderTargetUnit()

    if w == null then
        set w = GetOrderTargetItem()
    endif
    if w == null then
        set w = GetOrderTargetDestructable()
    endif

    return w
endfunction

private function BridgeSystem_IsApproachRedirectOrder takes integer orderId returns boolean
    if orderId == OrderId("move") then
        return true
    endif
    if orderId == OrderId("smart") then
        return true
    endif
    if orderId == OrderId("patrol") then
        return true
    endif
    return false
endfunction

private function BridgeSystem_SavePendingOrder takes unit whichUnit returns nothing
    local integer unitKey = BridgeSystem_GetUnitKey(whichUnit)
    local integer orderId = GetIssuedOrderId()
    local eventid whichEvent = GetTriggerEventId()
    local widget target = null

    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_ORDER_ID, orderId)

    if whichEvent == EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER then
        call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_KIND, ORDER_KIND_POINT)
        call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_X, GetOrderPointX())
        call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_Y, GetOrderPointY())
        call RemoveSavedHandle(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_TARGET)
        return
    endif

    if whichEvent == EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER then
        set target = BridgeSystem_GetPendingTarget()
        if target != null then
            call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_KIND, ORDER_KIND_TARGET)
            call SaveWidgetHandle(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_TARGET, target)
        else
            call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_KIND, ORDER_KIND_IMMEDIATE)
            call RemoveSavedHandle(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_TARGET)
        endif
        set target = null
        return
    endif

    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_KIND, ORDER_KIND_IMMEDIATE)
    call RemoveSavedHandle(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_TARGET)
endfunction

private function BridgeSystem_IssueSavedOrder takes unit whichUnit, integer orderKind, integer orderId, real x, real y, widget target returns nothing
    if whichUnit == null or orderKind == ORDER_KIND_NONE or orderId == 0 then
        return
    endif

    if orderKind == ORDER_KIND_POINT then
        call IssuePointOrderById(whichUnit, orderId, x, y)
    elseif orderKind == ORDER_KIND_TARGET then
        if target != null then
            call IssueTargetOrderById(whichUnit, orderId, target)
        endif
    else
        call IssueImmediateOrderById(whichUnit, orderId)
    endif
endfunction

private function BridgeSystem_TeleportUnderLaneUnitPastBridge takes integer bridgeId, unit whichUnit, integer entrySlot, boolean resumeOrder returns nothing
    local integer targetSlot
    local integer unitKey
    local integer pendingKind = ORDER_KIND_NONE
    local integer pendingOrderId = 0
    local real pendingX = 0.0
    local real pendingY = 0.0
    local widget pendingTarget = null
    local rect bridgeRect
    local real sourceX
    local real sourceY
    local real targetX
    local real targetY
    local real pathDx
    local real pathDy
    local real snapX
    local real snapY

    if whichUnit == null or bridgeId <= 0 then
        return
    endif

    set bridgeRect = BridgeSystemBridgeRect[bridgeId]
    if bridgeRect == null then
        return
    endif

    set unitKey = BridgeSystem_GetUnitKey(whichUnit)
    call BridgeSystem_PausePatrolIfActive(whichUnit)

    if resumeOrder then
        set pendingKind = LoadInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_KIND)
        set pendingOrderId = LoadInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_ORDER_ID)
        set pendingX = LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_X)
        set pendingY = LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_Y)
        set pendingTarget = LoadWidgetHandle(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_TARGET)
    endif

    set targetSlot = BridgeSystem_GetOppositeSlot(entrySlot)
    call SaveInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_LAST_UNDER_SLOT, entrySlot)
    call SaveInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_IGNORE_UNDER_SLOT, targetSlot)
    set sourceX = BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_UNDER, entrySlot)
    set sourceY = BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_UNDER, entrySlot)
    set targetX = BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_UNDER, targetSlot)
    set targetY = BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_UNDER, targetSlot)
    set pathDx = targetX - sourceX
    set pathDy = targetY - sourceY
    set snapX = GetUnitX(whichUnit)
    set snapY = GetUnitY(whichUnit)

    if RAbsBJ(pathDx) >= RAbsBJ(pathDy) then
        if pathDx >= 0.0 then
            set snapX = GetRectMaxX(bridgeRect) + BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        else
            set snapX = GetRectMinX(bridgeRect) - BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        endif
    else
        if pathDy >= 0.0 then
            set snapY = GetRectMaxY(bridgeRect) + BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        else
            set snapY = GetRectMinY(bridgeRect) - BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        endif
    endif

    call SetUnitPosition(whichUnit, snapX, snapY)

    if resumeOrder and not LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_PATROL_PAUSED_BY_BRIDGE) then
        call BridgeSystem_IssueSavedOrder(whichUnit, pendingKind, pendingOrderId, pendingX, pendingY, pendingTarget)
    endif
    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_KIND, ORDER_KIND_NONE)
    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_ORDER_ID, 0)
    call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_X, 0.0)
    call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_Y, 0.0)
    call RemoveSavedHandle(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_TARGET)
    call BridgeSystem_ResumePatrolIfPaused(whichUnit, true)

    set pendingTarget = null
    set bridgeRect = null
endfunction

private function BridgeSystem_SnapUnderLaneUnitPastBridge takes unit whichUnit returns nothing
    local integer bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    local integer entrySlot = BridgeSystem_GetUnitEntrySlot(whichUnit)
    local integer targetSlot
    local rect bridgeRect
    local real sourceX
    local real sourceY
    local real targetX
    local real targetY
    local real pathDx
    local real pathDy
    local real snapX
    local real snapY

    if whichUnit == null or bridgeId <= 0 or BridgeSystem_GetUnitLane(whichUnit) != BRIDGE_LANE_UNDER then
        return
    endif
    if not BridgeSystem_HasActiveLaneUnits(bridgeId, BRIDGE_LANE_TOP) then
        return
    endif

    set bridgeRect = BridgeSystemBridgeRect[bridgeId]
    if bridgeRect == null or not RectContainsUnit(bridgeRect, whichUnit) then
        set bridgeRect = null
        return
    endif

    set targetSlot = BridgeSystem_GetOppositeSlot(entrySlot)
    set sourceX = BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_UNDER, entrySlot)
    set sourceY = BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_UNDER, entrySlot)
    set targetX = BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_UNDER, targetSlot)
    set targetY = BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_UNDER, targetSlot)
    set pathDx = targetX - sourceX
    set pathDy = targetY - sourceY
    set snapX = GetUnitX(whichUnit)
    set snapY = GetUnitY(whichUnit)

    if RAbsBJ(pathDx) >= RAbsBJ(pathDy) then
        if pathDx >= 0.0 then
            set snapX = GetRectMaxX(bridgeRect) + BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        else
            set snapX = GetRectMinX(bridgeRect) - BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        endif
    else
        if pathDy >= 0.0 then
            set snapY = GetRectMaxY(bridgeRect) + BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        else
            set snapY = GetRectMinY(bridgeRect) - BRIDGE_UNDER_BRIDGE_SNAP_MARGIN
        endif
    endif

    call SetUnitPosition(whichUnit, snapX, snapY)

    set bridgeRect = null
endfunction

private function BridgeSystem_ShouldCenterTopLaneEntry takes integer bridgeId, unit whichUnit, integer entrySlot returns boolean
    local real dx
    local real dy

    if whichUnit == null or not BridgeSystemTopLaneEntryCenteringEnabled[bridgeId] then
        return false
    endif

    set dx = GetUnitX(whichUnit) - BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_TOP, entrySlot)
    set dy = GetUnitY(whichUnit) - BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_TOP, entrySlot)
    return dx*dx + dy*dy > BRIDGE_TOP_LANE_ENTRY_CENTER_REACHED_DISTANCE*BRIDGE_TOP_LANE_ENTRY_CENTER_REACHED_DISTANCE
endfunction

private function BridgeSystem_SetForcedMoveDestination takes integer bridgeId, unit whichUnit, integer lane, integer entrySlot, boolean centerTopEntry returns nothing
    local integer unitKey = BridgeSystem_GetUnitKey(whichUnit)
    local integer targetSlot = BridgeSystem_GetOppositeSlot(entrySlot)
    local real sourceX = BridgeSystem_GetLaneRectCenterX(bridgeId, lane, entrySlot)
    local real sourceY = BridgeSystem_GetLaneRectCenterY(bridgeId, lane, entrySlot)
    local real targetX = BridgeSystem_GetLaneRectCenterX(bridgeId, lane, targetSlot)
    local real targetY = BridgeSystem_GetLaneRectCenterY(bridgeId, lane, targetSlot)
    local real dx = targetX - sourceX
    local real dy = targetY - sourceY
    local real distance = SquareRoot(dx*dx + dy*dy)
    local real dirX = 0.0
    local real dirY = 0.0
    local rect targetRect = null
    local real edgeDistance = 0.0
    local real edgeX = 999999.0
    local real edgeY = 999999.0

    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TOP_LANE_ENTRY_CENTERING, lane == BRIDGE_LANE_TOP and centerTopEntry)
    call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_FORCED_TIMEOUT_AT, 0.0)

    if lane == BRIDGE_LANE_TOP and centerTopEntry then
        call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_X, sourceX)
        call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_Y, sourceY)
        call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_FORCED_TIMEOUT_AT, BridgeSystem_GetCurrentTime() + BRIDGE_TOP_LANE_FORCE_EXIT_TIMEOUT)
        return
    endif

    if distance > 0.0 then
        set dirX = dx / distance
        set dirY = dy / distance
        set targetRect = LoadRectHandle(BridgeSystemTable, bridgeId, BridgeSystem_GetRectSlotBase(lane) + targetSlot)
        if targetRect != null then
            if dirX != 0.0 then
                set edgeX = ((GetRectMaxX(targetRect) - GetRectMinX(targetRect)) * 0.5) / RAbsBJ(dirX)
            endif
            if dirY != 0.0 then
                set edgeY = ((GetRectMaxY(targetRect) - GetRectMinY(targetRect)) * 0.5) / RAbsBJ(dirY)
            endif
            if edgeX < edgeY then
                set edgeDistance = edgeX
            else
                set edgeDistance = edgeY
            endif
        endif
        set targetX = targetX + (edgeDistance + BRIDGE_EXIT_OVERSHOOT) * dirX
        set targetY = targetY + (edgeDistance + BRIDGE_EXIT_OVERSHOOT) * dirY
    endif

    call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_X, targetX)
    call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_Y, targetY)
    if lane == BRIDGE_LANE_TOP then
        call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_FORCED_TIMEOUT_AT, BridgeSystem_GetCurrentTime() + BRIDGE_TOP_LANE_FORCE_EXIT_TIMEOUT)
    endif

    set targetRect = null
endfunction

private function BridgeSystem_SetForcedMoveState takes integer bridgeId, unit whichUnit, integer lane, integer entrySlot returns nothing
    local integer unitKey = BridgeSystem_GetUnitKey(whichUnit)

    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_BRIDGE_ID, bridgeId)
    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_LANE, lane)
    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_ENTRY_SLOT, entrySlot)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_FORCED, true)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_WAITING, false)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TARGET_SLOT_ENTERED, false)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TOP_INVULNERABILITY_APPLIED, false)

    call BridgeSystem_SetForcedMoveDestination(bridgeId, whichUnit, lane, entrySlot, lane == BRIDGE_LANE_TOP and BridgeSystem_ShouldCenterTopLaneEntry(bridgeId, whichUnit, entrySlot))
endfunction

private function BridgeSystem_IssueForcedMove takes unit whichUnit returns nothing
    local integer unitKey = BridgeSystem_GetUnitKey(whichUnit)

    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_SUPPRESS, true)
    call IssuePointOrder(whichUnit, "move", LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_X), LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_Y))
endfunction

private function BridgeSystem_AdvanceForcedMove takes unit whichUnit returns boolean
    local integer bridgeId
    local integer lane
    local integer entrySlot

    if whichUnit == null or not BridgeSystem_IsUnitForced(whichUnit) then
        return false
    endif

    set bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    set lane = BridgeSystem_GetUnitLane(whichUnit)
    set entrySlot = BridgeSystem_GetUnitEntrySlot(whichUnit)
    if bridgeId <= 0 then
        return false
    endif

    if lane == BRIDGE_LANE_TOP and LoadBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_TOP_LANE_ENTRY_CENTERING) then
        call BridgeSystem_SetForcedMoveDestination(bridgeId, whichUnit, lane, entrySlot, false)
        call BridgeSystem_IssueForcedMove(whichUnit)
        return true
    endif

    return false
endfunction

private function BridgeSystem_QueueUnit takes integer bridgeId, unit whichUnit, integer lane, integer entrySlot returns nothing
    local integer unitKey = BridgeSystem_GetUnitKey(whichUnit)

    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_BRIDGE_ID, bridgeId)
    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_LANE, lane)
    call SaveInteger(BridgeSystemTable, unitKey, UNIT_STATE_ENTRY_SLOT, entrySlot)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_FORCED, false)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_WAITING, true)
    call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TOP_LANE_ENTRY_CENTERING, false)
    call SaveReal(BridgeSystemTable, unitKey, UNIT_STATE_FORCED_TIMEOUT_AT, 0.0)
    call GroupAddUnit(BridgeSystemTrackedUnits, whichUnit)

    if lane == BRIDGE_LANE_TOP then
        call GroupAddUnit(BridgeSystemTopWaitingUnits[bridgeId], whichUnit)
    else
        call GroupAddUnit(BridgeSystemUnderWaitingUnits[bridgeId], whichUnit)
    endif

    call PauseUnit(whichUnit, true)
endfunction

private function BridgeSystem_RemoveWaitingState takes unit whichUnit returns nothing
    local integer bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    local integer lane = BridgeSystem_GetUnitLane(whichUnit)

    if bridgeId <= 0 then
        return
    endif

    if lane == BRIDGE_LANE_TOP then
        call GroupRemoveUnit(BridgeSystemTopWaitingUnits[bridgeId], whichUnit)
    else
        call GroupRemoveUnit(BridgeSystemUnderWaitingUnits[bridgeId], whichUnit)
    endif

    call SaveBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_WAITING, false)
    call PauseUnit(whichUnit, false)
endfunction

private function BridgeSystem_StartUnderCrossing takes integer bridgeId, unit whichUnit, integer entrySlot returns nothing
    if whichUnit == null or BridgeSystem_ShouldIgnoreUnit(whichUnit) then
        return
    endif
    if not BridgeSystem_IsUnderLaneControlActive(bridgeId) then
        return
    endif

    if BridgeSystem_IsUnitWaiting(whichUnit) and BridgeSystem_GetUnitBridgeId(whichUnit) == bridgeId and BridgeSystem_GetUnitLane(whichUnit) == BRIDGE_LANE_UNDER then
        call BridgeSystem_RemoveWaitingState(whichUnit)
    endif

    call BridgeSystem_TeleportUnderLaneUnitPastBridge(bridgeId, whichUnit, entrySlot, BridgeSystem_ShouldResumeLaneOrders(BRIDGE_LANE_UNDER))
endfunction

private function BridgeSystem_AdoptBridgeRectUnderUnits takes integer bridgeId returns nothing
    local unit u
    local integer entrySlot

    call GroupEnumUnitsInRect(BridgeSystemRectEnumGroup, BridgeSystemBridgeRect[bridgeId], null)

    loop
        set u = FirstOfGroup(BridgeSystemRectEnumGroup)
        exitwhen u == null
        call GroupRemoveUnit(BridgeSystemRectEnumGroup, u)

        if GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) and not BridgeSystem_ShouldIgnoreUnit(u) then
            if not BridgeSystem_IsUnitForced(u) and not BridgeSystem_IsUnitWaiting(u) then
                set entrySlot = BridgeSystem_GetUnitLastUnderSlot(u)
                if entrySlot < 1 or entrySlot > 2 then
                    set entrySlot = BridgeSystem_GetNearestLaneRectSlot(bridgeId, BRIDGE_LANE_UNDER, u)
                endif
                if entrySlot != 0 then
                    call BridgeSystem_StartUnderCrossing(bridgeId, u, entrySlot)
                endif
            endif
        endif
    endloop

    set u = null
endfunction

private function BridgeSystem_StartTopCrossing takes integer bridgeId, unit whichUnit, integer entrySlot returns nothing
    local boolean firstTopUnit = false

    if whichUnit == null or BridgeSystem_ShouldIgnoreUnit(whichUnit) then
        return
    endif

    if BridgeSystem_IsUnitWaiting(whichUnit) and BridgeSystem_GetUnitBridgeId(whichUnit) == bridgeId and BridgeSystem_GetUnitLane(whichUnit) == BRIDGE_LANE_TOP then
        call BridgeSystem_RemoveWaitingState(whichUnit)
    endif

    if not BridgeSystem_HasActiveLaneUnits(bridgeId, BRIDGE_LANE_TOP) then
        set firstTopUnit = true
        if not BridgeSystem_IsTopLanePersistentOpen(bridgeId) then
            call BridgeSystem_OpenTopLane(bridgeId)
            call BridgeSystem_RunActions(BridgeSystemActivateActionTrigger[bridgeId])
        endif
    endif

    call BridgeSystem_SetForcedMoveState(bridgeId, whichUnit, BRIDGE_LANE_TOP, entrySlot)
    call SaveBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_TOP_INVULNERABILITY_APPLIED, BRIDGE_TOP_LANE_INVULNERABLE)
    if BRIDGE_TOP_LANE_INVULNERABLE then
        call SetUnitInvulnerable(whichUnit, true)
    endif
    call BridgeSystem_HideTopLaneShadow(whichUnit)
    call BridgeSystem_SetGuiUnitState(whichUnit, true)
    call BridgeSystem_SetGhostCollision(whichUnit, BridgeSystem_IsLaneGhostCollisionEnabled(bridgeId, BRIDGE_LANE_TOP))
    call GroupAddUnit(BridgeSystemTrackedUnits, whichUnit)
    call GroupAddUnit(BridgeSystemTopActiveUnits[bridgeId], whichUnit)
    if firstTopUnit and BRIDGE_AUTO_ADOPT_UNDER_UNITS then
        call BridgeSystem_AdoptBridgeRectUnderUnits(bridgeId)
    endif
    call BridgeSystem_IssueForcedMove(whichUnit)
endfunction

private function BridgeSystem_ReleaseWaitingUnits takes integer bridgeId, integer lane returns nothing
    local unit u
    local integer entrySlot
    local group sourceGroup

    if lane == BRIDGE_LANE_TOP then
        set sourceGroup = BridgeSystemTopWaitingUnits[bridgeId]
    else
        set sourceGroup = BridgeSystemUnderWaitingUnits[bridgeId]
    endif

    loop
        set u = FirstOfGroup(sourceGroup)
        exitwhen u == null
        set entrySlot = BridgeSystem_GetUnitEntrySlot(u)
        if lane == BRIDGE_LANE_TOP then
            call BridgeSystem_StartTopCrossing(bridgeId, u, entrySlot)
        else
            call BridgeSystem_StartUnderCrossing(bridgeId, u, entrySlot)
        endif
    endloop

    set u = null
    set sourceGroup = null
endfunction

private function BridgeSystem_TryRedirectApproachPointOrder takes unit whichUnit returns boolean
    local integer bridgeId = 1
    local integer slot = 0
    local real targetX
    local real targetY

    if whichUnit == null then
        return false
    endif
    if BridgeSystem_ShouldIgnoreUnit(whichUnit) then
        return false
    endif
    if not BridgeSystem_IsApproachRedirectOrder(GetIssuedOrderId()) then
        return false
    endif

    set targetX = GetOrderPointX()
    set targetY = GetOrderPointY()

    loop
        exitwhen bridgeId > BridgeSystemCount
        set slot = BridgeSystem_GetLaneApproachSlotForUnit(bridgeId, BRIDGE_LANE_TOP, whichUnit)
        if slot != 0 and not BridgeSystem_HasActiveLaneUnits(bridgeId, BRIDGE_LANE_TOP) and RectContainsCoords(BridgeSystemBridgeRect[bridgeId], targetX, targetY) then
            call BridgeSystem_StartTopCrossing(bridgeId, whichUnit, slot)
            return true
        endif
        if slot != 0 and BridgeSystem_ShouldRedirectApproachOrder(bridgeId, BRIDGE_LANE_TOP, slot, targetX, targetY) then
            call SaveBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_SUPPRESS, true)
            call IssuePointOrder(whichUnit, "move", BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_TOP, slot), BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_TOP, slot))
            return true
        endif

        if BridgeSystem_IsUnderLaneControlActive(bridgeId) then
            set slot = BridgeSystem_GetLaneApproachSlotForUnit(bridgeId, BRIDGE_LANE_UNDER, whichUnit)
            if slot != 0 and BridgeSystem_ShouldRedirectApproachOrder(bridgeId, BRIDGE_LANE_UNDER, slot, targetX, targetY) then
                call BridgeSystem_SavePendingOrder(whichUnit)
                call SaveInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_LAST_UNDER_SLOT, slot)
                call SaveBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_SUPPRESS, true)
                call IssuePointOrder(whichUnit, "move", BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_UNDER, slot), BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_UNDER, slot))
                return true
            endif
        endif
        set bridgeId = bridgeId + 1
    endloop

    return false
endfunction

private function BridgeSystem_ClearManagedStateCore takes unit whichUnit, boolean resumeOrder returns integer
    local integer unitKey
    local integer bridgeId
    local integer lane
    local boolean wasForced
    local boolean wasWaiting
    local integer transitionCode = 0
    local integer pendingKind = ORDER_KIND_NONE
    local integer pendingOrderId = 0
    local real pendingX = 0.0
    local real pendingY = 0.0
    local widget pendingTarget = null
    local boolean topInvulnerabilityApplied = false
    local string shadowImage = ""

    if whichUnit == null then
        return 0
    endif

    set unitKey = BridgeSystem_GetUnitKey(whichUnit)
    set topInvulnerabilityApplied = LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TOP_INVULNERABILITY_APPLIED)
    set bridgeId = LoadInteger(BridgeSystemTable, unitKey, UNIT_STATE_BRIDGE_ID)
    set lane = LoadInteger(BridgeSystemTable, unitKey, UNIT_STATE_LANE)
    set wasForced = LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_FORCED)
    set wasWaiting = LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_WAITING)

    if bridgeId <= 0 then
        call BridgeSystem_SetGuiUnitState(whichUnit, false)
        if topInvulnerabilityApplied then
            call SetUnitInvulnerable(whichUnit, false)
        endif
        call PauseUnit(whichUnit, false)
        call BridgeSystem_SetGhostCollision(whichUnit, false)
        return 0
    endif

    if resumeOrder then
        set pendingKind = LoadInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_KIND)
        set pendingOrderId = LoadInteger(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_ORDER_ID)
        set pendingX = LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_X)
        set pendingY = LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_Y)
        set pendingTarget = LoadWidgetHandle(BridgeSystemTable, unitKey, UNIT_STATE_PENDING_TARGET)
    endif
    if lane == BRIDGE_LANE_TOP then
        set shadowImage = LoadStr(BridgeSystemTable, unitKey, UNIT_STATE_TOP_SHADOW_IMAGE)
        if shadowImage == null then
            set shadowImage = ""
        endif
    endif

    if lane == BRIDGE_LANE_TOP then
        if wasForced then
            call GroupRemoveUnit(BridgeSystemTopActiveUnits[bridgeId], whichUnit)
            if CountUnitsInGroup(BridgeSystemTopActiveUnits[bridgeId]) == 0 then
                set transitionCode = 1
            endif
        elseif wasWaiting then
            call GroupRemoveUnit(BridgeSystemTopWaitingUnits[bridgeId], whichUnit)
        endif
    elseif lane == BRIDGE_LANE_UNDER then
        if wasForced then
            call GroupRemoveUnit(BridgeSystemUnderActiveUnits[bridgeId], whichUnit)
            if CountUnitsInGroup(BridgeSystemUnderActiveUnits[bridgeId]) == 0 then
                set transitionCode = 2
            endif
        elseif wasWaiting then
            call GroupRemoveUnit(BridgeSystemUnderWaitingUnits[bridgeId], whichUnit)
        endif
    endif

    call GroupRemoveUnit(BridgeSystemTrackedUnits, whichUnit)
    call PauseUnit(whichUnit, false)
    call BridgeSystem_SetGhostCollision(whichUnit, false)
    call BridgeSystem_SetGuiUnitState(whichUnit, false)
    if topInvulnerabilityApplied then
        call SetUnitInvulnerable(whichUnit, false)
    endif
    if lane == BRIDGE_LANE_TOP then
        call BlzSetUnitStringField(whichUnit, UNIT_SF_SHADOW_IMAGE_UNIT, shadowImage)
    endif
    call FlushChildHashtable(BridgeSystemTable, unitKey)

    if resumeOrder then
        call BridgeSystem_IssueSavedOrder(whichUnit, pendingKind, pendingOrderId, pendingX, pendingY, pendingTarget)
    endif

    set pendingTarget = null
    return transitionCode
endfunction

private function BridgeSystem_ClearWaitingUnits takes integer bridgeId, integer lane returns nothing
    local unit u
    local group sourceGroup

    if lane == BRIDGE_LANE_TOP then
        set sourceGroup = BridgeSystemTopWaitingUnits[bridgeId]
    else
        set sourceGroup = BridgeSystemUnderWaitingUnits[bridgeId]
    endif

    loop
        set u = FirstOfGroup(sourceGroup)
        exitwhen u == null
        call BridgeSystem_ClearManagedStateCore(u, BridgeSystem_ShouldResumeLaneOrders(lane))
    endloop

    set u = null
    set sourceGroup = null
endfunction

private function BridgeSystem_ClearActiveUnits takes integer bridgeId, integer lane returns nothing
    local unit u
    local group sourceGroup

    if lane == BRIDGE_LANE_TOP then
        set sourceGroup = BridgeSystemTopActiveUnits[bridgeId]
    else
        set sourceGroup = BridgeSystemUnderActiveUnits[bridgeId]
    endif

    loop
        set u = FirstOfGroup(sourceGroup)
        exitwhen u == null
        call BridgeSystem_ClearManagedStateCore(u, BridgeSystem_ShouldResumeLaneOrders(lane))
    endloop

    set u = null
    set sourceGroup = null
endfunction

private function BridgeSystem_ClearManagedStateEx takes unit whichUnit, boolean resumeOrder, boolean processTransitions returns nothing
    local integer bridgeId
    local integer transitionCode

    if whichUnit == null then
        return
    endif

    set bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    set transitionCode = BridgeSystem_ClearManagedStateCore(whichUnit, resumeOrder)

    if processTransitions and transitionCode == 1 then
        if CountUnitsInGroup(BridgeSystemTopWaitingUnits[bridgeId]) > 0 then
            call BridgeSystem_ReleaseWaitingUnits(bridgeId, BRIDGE_LANE_TOP)
        else
            if not BridgeSystem_IsTopLanePersistentOpen(bridgeId) then
                call BridgeSystem_CloseTopLane(bridgeId)
                call BridgeSystem_RunActions(BridgeSystemDeactivateActionTrigger[bridgeId])
            endif
            call BridgeSystem_ClearActiveUnits(bridgeId, BRIDGE_LANE_UNDER)
        endif
        if CountUnitsInGroup(BridgeSystemUnderWaitingUnits[bridgeId]) > 0 then
            call BridgeSystem_ClearWaitingUnits(bridgeId, BRIDGE_LANE_UNDER)
        endif
    elseif processTransitions and transitionCode == 2 then
        if CountUnitsInGroup(BridgeSystemTopWaitingUnits[bridgeId]) > 0 then
            call BridgeSystem_ReleaseWaitingUnits(bridgeId, BRIDGE_LANE_TOP)
        elseif not BridgeSystem_HasActiveLaneUnits(bridgeId, BRIDGE_LANE_TOP) and not BridgeSystem_IsTopLanePersistentOpen(bridgeId) then
            call BridgeSystem_OpenTopLane(bridgeId)
            call BridgeSystem_RunActions(BridgeSystemActivateActionTrigger[bridgeId])
        endif
    endif
endfunction

private function BridgeSystem_ClearManagedState takes unit whichUnit, boolean resumeOrder returns nothing
    call BridgeSystem_ClearManagedStateEx(whichUnit, resumeOrder, true)
endfunction

private function BridgeSystem_IsUnitManagedByOtherLane takes integer bridgeId, integer lane, unit whichUnit returns boolean
    if whichUnit == null then
        return false
    endif

    return BridgeSystem_GetUnitBridgeId(whichUnit) == bridgeId and (BridgeSystem_IsUnitForced(whichUnit) or BridgeSystem_IsUnitWaiting(whichUnit)) and BridgeSystem_GetUnitLane(whichUnit) != lane
endfunction

private function BridgeSystem_ShouldForceReleaseManagedUnit takes unit whichUnit returns boolean
    local integer bridgeId
    local integer lane
    local integer unitKey

    if whichUnit == null then
        return false
    endif

    set bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    if bridgeId <= 0 or not BridgeSystem_IsUnitForced(whichUnit) then
        return false
    endif
    if GetUnitTypeId(whichUnit) == 0 or IsUnitType(whichUnit, UNIT_TYPE_DEAD) then
        return true
    endif
    if BridgeSystem_ShouldIgnoreUnit(whichUnit) then
        return true
    endif

    set lane = BridgeSystem_GetUnitLane(whichUnit)
    if lane != BRIDGE_LANE_TOP and lane != BRIDGE_LANE_UNDER then
        return true
    endif

    if lane == BRIDGE_LANE_UNDER and not BridgeSystem_IsInsideLaneFlow(bridgeId, lane, whichUnit) then
        return true
    endif

    if lane == BRIDGE_LANE_TOP and not RectContainsUnit(BridgeSystemBridgeRect[bridgeId], whichUnit) then
        set unitKey = BridgeSystem_GetUnitKey(whichUnit)
        if LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TARGET_SLOT_ENTERED) then
            return true
        endif
    endif

    return false
endfunction

private function BridgeSystem_HasTopLaneForceExitTimedOut takes unit whichUnit returns boolean
    if whichUnit == null or not BridgeSystem_IsUnitForced(whichUnit) then
        return false
    endif
    if BridgeSystem_GetUnitLane(whichUnit) != BRIDGE_LANE_TOP then
        return false
    endif
    if GetUnitTypeId(whichUnit) == 0 or IsUnitType(whichUnit, UNIT_TYPE_DEAD) then
        return false
    endif

    return LoadReal(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_FORCED_TIMEOUT_AT) > 0.0 and BridgeSystem_GetCurrentTime() >= LoadReal(BridgeSystemTable, BridgeSystem_GetUnitKey(whichUnit), UNIT_STATE_FORCED_TIMEOUT_AT)
endfunction

private function BridgeSystem_ForceTopLaneUnitToExit takes unit whichUnit returns nothing
    local integer bridgeId
    local integer entrySlot
    local integer targetSlot
    local integer unitKey
    local real targetX
    local real targetY

    if whichUnit == null or BridgeSystem_GetUnitLane(whichUnit) != BRIDGE_LANE_TOP then
        return
    endif

    set bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    set entrySlot = BridgeSystem_GetUnitEntrySlot(whichUnit)
    if bridgeId <= 0 or entrySlot <= 0 then
        return
    endif

    set unitKey = BridgeSystem_GetUnitKey(whichUnit)
    if LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_TOP_LANE_ENTRY_CENTERING) then
        call BridgeSystem_SetForcedMoveDestination(bridgeId, whichUnit, BRIDGE_LANE_TOP, entrySlot, false)
    endif
    set targetX = LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_X)
    set targetY = LoadReal(BridgeSystemTable, unitKey, UNIT_STATE_DEST_Y)
    if targetX == 0.0 and targetY == 0.0 then
        set targetSlot = BridgeSystem_GetOppositeSlot(entrySlot)
        set targetX = BridgeSystem_GetLaneRectCenterX(bridgeId, BRIDGE_LANE_TOP, targetSlot)
        set targetY = BridgeSystem_GetLaneRectCenterY(bridgeId, BRIDGE_LANE_TOP, targetSlot)
    endif
    call SetUnitPosition(whichUnit, targetX, targetY)
    call BridgeSystem_ClearManagedState(whichUnit, BridgeSystem_ShouldResumeLaneOrders(BRIDGE_LANE_TOP))
endfunction

private function BridgeSystem_ClearUnitBridgeState takes unit whichUnit returns nothing
    call BridgeSystem_ClearManagedState(whichUnit, false)
endfunction

function BridgeSystem_Activate takes integer bridgeId, unit whichUnit returns nothing
    if BridgeSystem_ShouldIgnoreUnit(whichUnit) then
        return
    endif
    call BridgeSystem_StartTopCrossing(bridgeId, whichUnit, 1)
endfunction

function BridgeSystem_Deactivate takes integer bridgeId, unit whichUnit returns nothing
    if BridgeSystem_ShouldIgnoreUnit(whichUnit) then
        return
    endif
    if BridgeSystem_IsUnderLaneControlActive(bridgeId) then
        call BridgeSystem_StartUnderCrossing(bridgeId, whichUnit, 1)
    endif
endfunction

private function BridgeSystem_CanActivate takes nothing returns boolean
    local integer bridgeId = BridgeSystem_GetBridgeIdFromTrigger(GetTriggeringTrigger())
    local unit u = GetTriggerUnit()

    if BridgeSystem_GetUnitBridgeId(u) == bridgeId and BridgeSystem_IsUnitForced(u) and BridgeSystem_GetUnitLane(u) == BRIDGE_LANE_TOP then
        set u = null
        return true
    endif
    if BridgeSystem_ShouldIgnoreUnit(u) then
        set u = null
        return false
    endif
    if BridgeSystem_IsUnitManagedByOtherLane(bridgeId, BRIDGE_LANE_TOP, u) then
        set u = null
        return false
    endif

    if BridgeSystemActivateConditionTrigger[bridgeId] != null then
        set u = null
        return TriggerEvaluate(BridgeSystemActivateConditionTrigger[bridgeId])
    endif

    set u = null
    return true
endfunction

private function BridgeSystem_CanDeactivate takes nothing returns boolean
    local integer bridgeId = BridgeSystem_GetBridgeIdFromTrigger(GetTriggeringTrigger())
    local unit u = GetTriggerUnit()

    if BridgeSystem_GetUnitBridgeId(u) == bridgeId and BridgeSystem_IsUnitForced(u) and BridgeSystem_GetUnitLane(u) == BRIDGE_LANE_UNDER then
        set u = null
        return true
    endif
    if BridgeSystem_ShouldIgnoreUnit(u) then
        set u = null
        return false
    endif
    if BridgeSystem_IsUnitManagedByOtherLane(bridgeId, BRIDGE_LANE_UNDER, u) then
        set u = null
        return false
    endif
    if not BridgeSystem_IsUnderLaneControlActive(bridgeId) then
        set u = null
        return false
    endif

    if BridgeSystemDeactivateConditionTrigger[bridgeId] != null then
        set u = null
        return TriggerEvaluate(BridgeSystemDeactivateConditionTrigger[bridgeId])
    endif

    set u = null
    return true
endfunction

private function BridgeSystem_OnActivate takes nothing returns nothing
    local integer bridgeId = BridgeSystem_GetBridgeIdFromTrigger(GetTriggeringTrigger())
    local unit u = GetTriggerUnit()
    local integer slot = BridgeSystem_GetLaneRectSlotForUnit(bridgeId, BRIDGE_LANE_TOP, u)
    local integer targetSlot
    local boolean releasedStaleState = false

    if slot == 0 then
        set slot = BridgeSystem_GetNearestLaneRectSlot(bridgeId, BRIDGE_LANE_TOP, u)
        if slot == 0 then
            set u = null
            return
        endif
    endif

    if BridgeSystem_GetUnitBridgeId(u) == bridgeId and BridgeSystem_IsUnitForced(u) and BridgeSystem_GetUnitLane(u) == BRIDGE_LANE_TOP then
        set targetSlot = BridgeSystem_GetOppositeSlot(BridgeSystem_GetUnitEntrySlot(u))
        if slot == targetSlot then
            if LoadBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(u), UNIT_STATE_TARGET_SLOT_ENTERED) then
                // This is a later re-entry into the old destination slot, so the
                // previous top-lane bridge state must be discarded now.
                call BridgeSystem_ClearManagedState(u, false)
                set releasedStaleState = true
            else
                // First time entering the opposite top slot belongs to the
                // current forced crossing; keep forcing the unit past the exit.
                call SaveBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(u), UNIT_STATE_TARGET_SLOT_ENTERED, true)
                set u = null
                return
            endif
        endif
        if not releasedStaleState and BridgeSystem_HasReachedForcedDestination(u) then
            // Finished state from the previous crossing may still be attached
            // when the unit immediately re-enters from the opposite top side.
            call BridgeSystem_ClearManagedState(u, false)
        elseif not releasedStaleState then
            set u = null
            return
        endif
    endif

    call BridgeSystem_StartTopCrossing(bridgeId, u, slot)

    set u = null
endfunction

private function BridgeSystem_OnDeactivate takes nothing returns nothing
    local integer bridgeId = BridgeSystem_GetBridgeIdFromTrigger(GetTriggeringTrigger())
    local unit u = GetTriggerUnit()
    local integer slot = BridgeSystem_GetLaneRectSlotForUnit(bridgeId, BRIDGE_LANE_UNDER, u)
    local integer targetSlot
    local boolean releasedStaleState = false

    if slot == 0 then
        set slot = BridgeSystem_GetNearestLaneRectSlot(bridgeId, BRIDGE_LANE_UNDER, u)
        if slot == 0 then
            set u = null
            return
        endif
    endif
    if BridgeSystem_GetUnitIgnoreUnderSlot(u) == slot then
        call SaveInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(u), UNIT_STATE_IGNORE_UNDER_SLOT, 0)
        set u = null
        return
    endif
    call SaveInteger(BridgeSystemTable, BridgeSystem_GetUnitKey(u), UNIT_STATE_LAST_UNDER_SLOT, slot)

    if BridgeSystem_GetUnitBridgeId(u) == bridgeId and BridgeSystem_IsUnitForced(u) and BridgeSystem_GetUnitLane(u) == BRIDGE_LANE_UNDER then
        set targetSlot = BridgeSystem_GetOppositeSlot(BridgeSystem_GetUnitEntrySlot(u))
        if slot == targetSlot then
            if LoadBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(u), UNIT_STATE_TARGET_SLOT_ENTERED) then
                call BridgeSystem_ClearManagedState(u, false)
                set releasedStaleState = true
            else
                call SaveBoolean(BridgeSystemTable, BridgeSystem_GetUnitKey(u), UNIT_STATE_TARGET_SLOT_ENTERED, true)
                set u = null
                return
            endif
        endif
        if not releasedStaleState and BridgeSystem_HasReachedForcedDestination(u) then
            call BridgeSystem_ClearManagedState(u, false)
        elseif not releasedStaleState then
            set u = null
            return
        endif
    endif

    if not BridgeSystem_IsUnderLaneControlActive(bridgeId) then
        set u = null
        return
    endif

    call BridgeSystem_StartUnderCrossing(bridgeId, u, slot)

    set u = null
endfunction

private function BridgeSystem_OnLeaveBridgeArea takes nothing returns nothing
    local integer bridgeId = BridgeSystem_GetBridgeIdFromTrigger(GetTriggeringTrigger())
    local unit u = GetTriggerUnit()

    if BridgeSystem_GetUnitBridgeId(u) == bridgeId and (not BridgeSystem_IsUnitForced(u) or BridgeSystem_ShouldForceReleaseManagedUnit(u)) then
        call BridgeSystem_ClearManagedState(u, false)
    endif

    set u = null
endfunction

function BridgeSystem_Create takes string bridgeName, rect bridgeRect returns integer
    local integer bridgeId

    set BridgeSystemCount = BridgeSystemCount + 1
    set bridgeId = BridgeSystemCount

    set BridgeSystemName[bridgeId] = bridgeName
    set BridgeSystemBridgeRect[bridgeId] = bridgeRect

    set BridgeSystemActivateTrigger[bridgeId] = CreateTrigger()
    set BridgeSystemDeactivateTrigger[bridgeId] = CreateTrigger()
    set BridgeSystemLeaveTrigger[bridgeId] = CreateTrigger()

    set BridgeSystemTopActiveUnits[bridgeId] = CreateGroup()
    set BridgeSystemUnderActiveUnits[bridgeId] = CreateGroup()
    set BridgeSystemTopWaitingUnits[bridgeId] = CreateGroup()
    set BridgeSystemUnderWaitingUnits[bridgeId] = CreateGroup()
    set BridgeSystemTopLaneEntryCenteringEnabled[bridgeId] = true
    set BridgeSystemTopLanePersistentOpen[bridgeId] = false
    set BridgeSystemTopGhostCollisionEnabled[bridgeId] = true
    set BridgeSystemUnderGhostCollisionEnabled[bridgeId] = true

    call SaveInteger(BridgeSystemTable, GetHandleId(BridgeSystemActivateTrigger[bridgeId]), 0, bridgeId)
    call SaveInteger(BridgeSystemTable, GetHandleId(BridgeSystemDeactivateTrigger[bridgeId]), 0, bridgeId)
    call SaveInteger(BridgeSystemTable, GetHandleId(BridgeSystemLeaveTrigger[bridgeId]), 0, bridgeId)

    call TriggerAddCondition(BridgeSystemActivateTrigger[bridgeId], Condition(function BridgeSystem_CanActivate))
    call TriggerAddAction(BridgeSystemActivateTrigger[bridgeId], function BridgeSystem_OnActivate)

    call TriggerAddCondition(BridgeSystemDeactivateTrigger[bridgeId], Condition(function BridgeSystem_CanDeactivate))
    call TriggerAddAction(BridgeSystemDeactivateTrigger[bridgeId], function BridgeSystem_OnDeactivate)

    call TriggerAddAction(BridgeSystemLeaveTrigger[bridgeId], function BridgeSystem_OnLeaveBridgeArea)

    return bridgeId
endfunction

function BridgeSystem_AddControlledType takes integer bridgeId, integer destructTypeId returns nothing
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 1) + 1
    call SaveInteger(BridgeSystemTable, bridgeId, 1, slotCount)
    call SaveInteger(BridgeSystemTable, bridgeId, BRIDGE_TYPE_SLOT_BASE + slotCount, destructTypeId)
endfunction

function BridgeSystem_RegisterDefaultControlledTypes takes integer bridgeId returns nothing
    call BridgeSystem_AddControlledType(bridgeId, 'OTip') // Invisible Platform
    call BridgeSystem_AddControlledType(bridgeId, 'OTis') // Invisible Platform (small)
    call BridgeSystem_AddControlledType(bridgeId, 'YTpb') // Pathing Blocker (Ground)
    call BridgeSystem_AddControlledType(bridgeId, 'YTpc') // Pathing Blocker (Ground) (Large)
endfunction

function BridgeSystem_AddEntryBlockerPoint takes integer bridgeId, rect pointRect returns nothing
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 3) + 1
    call SaveInteger(BridgeSystemTable, bridgeId, 3, slotCount)
    call SaveRectHandle(BridgeSystemTable, bridgeId, ENTRY_POINT_SLOT_BASE + slotCount, pointRect)
endfunction

function BridgeSystem_AddActivateRect takes integer bridgeId, rect whichRect returns nothing
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 4) + 1
    call SaveInteger(BridgeSystemTable, bridgeId, 4, slotCount)
    call SaveRectHandle(BridgeSystemTable, bridgeId, ACTIVATE_RECT_SLOT_BASE + slotCount, whichRect)
endfunction

function BridgeSystem_AddDeactivateRect takes integer bridgeId, rect whichRect returns nothing
    local integer slotCount = LoadInteger(BridgeSystemTable, bridgeId, 5) + 1
    call SaveInteger(BridgeSystemTable, bridgeId, 5, slotCount)
    call SaveRectHandle(BridgeSystemTable, bridgeId, DEACTIVATE_RECT_SLOT_BASE + slotCount, whichRect)
endfunction

function BridgeSystem_SetActivateCondition takes integer bridgeId, boolexpr whichCondition returns nothing
    if BridgeSystemActivateConditionTrigger[bridgeId] == null then
        set BridgeSystemActivateConditionTrigger[bridgeId] = CreateTrigger()
    endif

    call TriggerAddCondition(BridgeSystemActivateConditionTrigger[bridgeId], whichCondition)
endfunction

function BridgeSystem_SetDeactivateCondition takes integer bridgeId, boolexpr whichCondition returns nothing
    if BridgeSystemDeactivateConditionTrigger[bridgeId] == null then
        set BridgeSystemDeactivateConditionTrigger[bridgeId] = CreateTrigger()
    endif

    call TriggerAddCondition(BridgeSystemDeactivateConditionTrigger[bridgeId], whichCondition)
endfunction

function BridgeSystem_AddActivateAction takes integer bridgeId, code callback returns nothing
    if BridgeSystemActivateActionTrigger[bridgeId] == null then
        set BridgeSystemActivateActionTrigger[bridgeId] = CreateTrigger()
    endif

    call TriggerAddAction(BridgeSystemActivateActionTrigger[bridgeId], callback)
endfunction

function BridgeSystem_AddDeactivateAction takes integer bridgeId, code callback returns nothing
    if BridgeSystemDeactivateActionTrigger[bridgeId] == null then
        set BridgeSystemDeactivateActionTrigger[bridgeId] = CreateTrigger()
    endif

    call TriggerAddAction(BridgeSystemDeactivateActionTrigger[bridgeId], callback)
endfunction

function BridgeSystem_AddIgnoredUnit takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif

    call GroupAddUnit(BridgeSystemIgnoredUnits, whichUnit)
endfunction

function BridgeSystem_RemoveIgnoredUnit takes unit whichUnit returns nothing
    if whichUnit == null or BridgeSystemIgnoredUnits == null then
        return
    endif

    call GroupRemoveUnit(BridgeSystemIgnoredUnits, whichUnit)
endfunction

function BridgeSystem_AddIgnoredGroup takes group whichGroup returns nothing
    local integer slot = 1

    if whichGroup == null then
        return
    endif

    loop
        exitwhen slot > BridgeSystemIgnoredGroupCount
        if BridgeSystemIgnoredGroups[slot] == whichGroup then
            return
        endif
        set slot = slot + 1
    endloop

    set BridgeSystemIgnoredGroupCount = BridgeSystemIgnoredGroupCount + 1
    set BridgeSystemIgnoredGroups[BridgeSystemIgnoredGroupCount] = whichGroup
endfunction

function BridgeSystem_RemoveIgnoredGroup takes group whichGroup returns nothing
    local integer slot = 1

    if whichGroup == null then
        return
    endif

    loop
        exitwhen slot > BridgeSystemIgnoredGroupCount
        if BridgeSystemIgnoredGroups[slot] == whichGroup then
            loop
                exitwhen slot >= BridgeSystemIgnoredGroupCount
                set BridgeSystemIgnoredGroups[slot] = BridgeSystemIgnoredGroups[slot + 1]
                set slot = slot + 1
            endloop
            set BridgeSystemIgnoredGroups[BridgeSystemIgnoredGroupCount] = null
            set BridgeSystemIgnoredGroupCount = BridgeSystemIgnoredGroupCount - 1
            return
        endif
        set slot = slot + 1
    endloop
endfunction

function BridgeSystem_InitIgnoredUnits takes nothing returns nothing
    // Examples:
    // call BridgeSystem_AddIgnoredUnit(udg_SomeUnit)
endfunction

function BridgeSystem_InitIgnoredGroups takes nothing returns nothing
    // Examples:
    // call BridgeSystem_AddIgnoredGroup(udg_SomeUnitGroup)
endfunction

function BridgeSystem_FinalizeSetup takes integer bridgeId returns nothing
    local integer slot = 1
    local integer slotCount
    local rect r
    local real x
    local real y

    set BridgeSystemEnumBridgeId = bridgeId
    call EnumDestructablesInRect(BridgeSystemBridgeRect[bridgeId], null, function BridgeSystem_EnumBridgeDestructables)
    set BridgeSystemEnumBridgeId = 0

    set slotCount = LoadInteger(BridgeSystemTable, bridgeId, 3)
    loop
        exitwhen slot > slotCount
        set r = LoadRectHandle(BridgeSystemTable, bridgeId, ENTRY_POINT_SLOT_BASE + slot)
        set x = (GetRectMinX(r) + GetRectMaxX(r)) * 0.5
        set y = (GetRectMinY(r) + GetRectMaxY(r)) * 0.5
        call SaveDestructableHandle(BridgeSystemTable, bridgeId, ENTRY_BLOCKER_SLOT_BASE + slot, CreateDestructable('YTpb', x, y, GetRandomReal(0.0, 360.0), 1.0, 0))
        set slot = slot + 1
    endloop

    set slot = 1
    set slotCount = LoadInteger(BridgeSystemTable, bridgeId, 4)
    loop
        exitwhen slot > slotCount
        call TriggerRegisterEnterRectSimple(BridgeSystemActivateTrigger[bridgeId], LoadRectHandle(BridgeSystemTable, bridgeId, ACTIVATE_RECT_SLOT_BASE + slot))
        set slot = slot + 1
    endloop

    set slot = 1
    set slotCount = LoadInteger(BridgeSystemTable, bridgeId, 5)
    loop
        exitwhen slot > slotCount
        call TriggerRegisterEnterRectSimple(BridgeSystemDeactivateTrigger[bridgeId], LoadRectHandle(BridgeSystemTable, bridgeId, DEACTIVATE_RECT_SLOT_BASE + slot))
        set slot = slot + 1
    endloop

    if BridgeSystem_IsTopLanePersistentOpen(bridgeId) then
        call BridgeSystem_OpenTopLane(bridgeId)
    endif

    call TriggerRegisterLeaveRectSimple(BridgeSystemLeaveTrigger[bridgeId], BridgeSystemBridgeRect[bridgeId])
    set r = null
endfunction

private function BridgeSystem_ShouldKeepManagedUnit takes unit whichUnit returns boolean
    local integer bridgeId = BridgeSystem_GetUnitBridgeId(whichUnit)
    local integer lane

    if whichUnit == null or bridgeId <= 0 then
        return false
    endif

    if BridgeSystem_ShouldIgnoreUnit(whichUnit) then
        return false
    endif

    if GetUnitTypeId(whichUnit) == 0 or IsUnitType(whichUnit, UNIT_TYPE_DEAD) then
        return false
    endif

    set lane = BridgeSystem_GetUnitLane(whichUnit)
    if lane != BRIDGE_LANE_TOP and lane != BRIDGE_LANE_UNDER then
        return false
    endif

    if BridgeSystem_IsUnitForced(whichUnit) then
        // Forced lane units may cross gaps between entry rects and the main
        // bridge rect, and may overshoot past the exit rect.
        return true
    endif

    if BridgeSystem_IsUnitWaiting(whichUnit) then
        if lane == BRIDGE_LANE_UNDER and not BridgeSystem_IsUnderLaneControlActive(bridgeId) then
            return false
        endif
        if RectContainsUnit(BridgeSystemBridgeRect[bridgeId], whichUnit) then
            return true
        endif
        return BridgeSystem_IsInsideLaneRects(bridgeId, lane, whichUnit)
    endif

    return false
endfunction

private function BridgeSystem_ForceLaneUnitEnum takes nothing returns nothing
    local unit u = GetEnumUnit()

    if BridgeSystem_IsUnitForced(u) then
        if BridgeSystem_GetUnitLane(u) == BRIDGE_LANE_UNDER then
            call BridgeSystem_SnapUnderLaneUnitPastBridge(u)
        endif
        call BridgeSystem_IssueForcedMove(u)
    endif

    set u = null
endfunction

private function BridgeSystem_ForceLaneUnitsOut takes group whichGroup returns nothing
    call ForGroup(whichGroup, function BridgeSystem_ForceLaneUnitEnum)
endfunction

private function BridgeSystem_EvaluateBridge takes integer bridgeId returns nothing
    local boolean hasTopActive = CountUnitsInGroup(BridgeSystemTopActiveUnits[bridgeId]) > 0
    local boolean hasUnderActive = CountUnitsInGroup(BridgeSystemUnderActiveUnits[bridgeId]) > 0
    local boolean hasTopWaiting = CountUnitsInGroup(BridgeSystemTopWaitingUnits[bridgeId]) > 0
    local boolean hasUnderWaiting = CountUnitsInGroup(BridgeSystemUnderWaitingUnits[bridgeId]) > 0

    if hasTopActive then
        if BRIDGE_AUTO_ADOPT_UNDER_UNITS then
            call BridgeSystem_AdoptBridgeRectUnderUnits(bridgeId)
        endif
        call BridgeSystem_ForceLaneUnitsOut(BridgeSystemTopActiveUnits[bridgeId])
    endif
    if hasUnderActive then
        call BridgeSystem_ForceLaneUnitsOut(BridgeSystemUnderActiveUnits[bridgeId])
    endif

    // Recover from deadlock: if both lanes only have paused waiting units and no
    // lane is currently active, pick one lane and push it out of the bridge flow.
    if not hasTopActive and not hasUnderActive then
        if hasTopWaiting then
            call BridgeSystem_ReleaseWaitingUnits(bridgeId, BRIDGE_LANE_TOP)
        elseif hasUnderWaiting then
            call BridgeSystem_ClearWaitingUnits(bridgeId, BRIDGE_LANE_UNDER)
        endif
    endif
endfunction

private function BridgeSystem_PeriodicValidate takes nothing returns nothing
    local integer bridgeId = 1
    local unit u

    loop
        set u = FirstOfGroup(BridgeSystemTrackedUnits)
        exitwhen u == null
        call GroupRemoveUnit(BridgeSystemTrackedUnits, u)
        call GroupAddUnit(BridgeSystemValidationGroup, u)
    endloop

    loop
        set u = FirstOfGroup(BridgeSystemValidationGroup)
        exitwhen u == null
        call GroupRemoveUnit(BridgeSystemValidationGroup, u)

        if BridgeSystem_ShouldForceReleaseManagedUnit(u) then
            call BridgeSystem_ClearManagedState(u, BridgeSystem_ShouldResumeLaneOrders(BridgeSystem_GetUnitLane(u)))
        elseif BridgeSystem_HasTopLaneForceExitTimedOut(u) then
            call BridgeSystem_ForceTopLaneUnitToExit(u)
        elseif BridgeSystem_HasReachedForcedDestination(u) then
            if not BridgeSystem_AdvanceForcedMove(u) then
                call BridgeSystem_ClearManagedState(u, BridgeSystem_ShouldResumeLaneOrders(BridgeSystem_GetUnitLane(u)))
            else
                call GroupAddUnit(BridgeSystemTrackedUnits, u)
            endif
        elseif BridgeSystem_ShouldKeepManagedUnit(u) then
            call GroupAddUnit(BridgeSystemTrackedUnits, u)
        else
            call BridgeSystem_ClearManagedState(u, false)
        endif
    endloop

    loop
        exitwhen bridgeId > BridgeSystemCount
        call BridgeSystem_EvaluateBridge(bridgeId)
        set bridgeId = bridgeId + 1
    endloop

    set u = null
endfunction

private function BridgeSystem_OnIssuedOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer unitKey
    local integer bridgeId
    local integer lane
    local integer targetSlot
    local eventid whichEvent

    if u == null then
        return
    endif

    set whichEvent = GetTriggerEventId()
    set unitKey = BridgeSystem_GetUnitKey(u)
    if LoadBoolean(BridgeSystemTable, unitKey, UNIT_STATE_SUPPRESS) then
        call SaveBoolean(BridgeSystemTable, unitKey, UNIT_STATE_SUPPRESS, false)
        set u = null
        return
    endif

    if BridgeSystem_ShouldIgnoreUnit(u) then
        if BridgeSystem_IsUnitForced(u) or BridgeSystem_IsUnitWaiting(u) then
            call BridgeSystem_ClearManagedState(u, false)
        endif
        set u = null
        return
    endif

    if whichEvent == EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER and not BridgeSystem_IsUnitForced(u) and not BridgeSystem_IsUnitWaiting(u) then
        if BridgeSystem_TryRedirectApproachPointOrder(u) then
            set u = null
            return
        endif
    endif

    if BridgeSystem_IsUnitForced(u) then
        set bridgeId = BridgeSystem_GetUnitBridgeId(u)
        set lane = BridgeSystem_GetUnitLane(u)
        set targetSlot = BridgeSystem_GetOppositeSlot(BridgeSystem_GetUnitEntrySlot(u))
        if BridgeSystem_HasReachedForcedDestination(u) then
            if BridgeSystem_AdvanceForcedMove(u) then
                set u = null
                return
            endif
            // The new player order should take over immediately once the forced
            // bridge movement is effectively complete.
            call BridgeSystem_ClearManagedState(u, false)
            set u = null
            return
        endif
        if lane == BRIDGE_LANE_TOP and not RectContainsUnit(BridgeSystemBridgeRect[bridgeId], u) and BridgeSystem_IsUnitInsideLaneSlot(bridgeId, lane, targetSlot, u) then
            // Top-lane units should be released as soon as the player gives a
            // new order from the exit-side C/D rect, even if the exact
            // overshoot point has not been reached yet.
            call BridgeSystem_ClearManagedState(u, false)
            set u = null
            return
        endif
        if BridgeSystem_ShouldResumeLaneOrders(lane) then
            call BridgeSystem_SavePendingOrder(u)
        endif
        call BridgeSystem_IssueForcedMove(u)
    elseif BridgeSystem_IsUnitWaiting(u) then
        if BridgeSystem_ShouldResumeLaneOrders(BridgeSystem_GetUnitLane(u)) then
            call BridgeSystem_SavePendingOrder(u)
        endif
    endif

    set u = null
endfunction

private function BridgeSystem_OnDeath takes nothing returns nothing
    local unit u = GetTriggerUnit()

    if u == null then
        return
    endif

    if BridgeSystem_GetUnitBridgeId(u) > 0 and (BridgeSystem_IsUnitForced(u) or BridgeSystem_IsUnitWaiting(u)) then
        call BridgeSystem_ClearManagedState(u, false)
    endif

    set u = null
endfunction

private function BridgeSystem_InitDelayed takes nothing returns nothing
    call BridgeSystem_InitIgnoredUnits()
    call BridgeSystem_InitIgnoredGroups()
endfunction

private function Init takes nothing returns nothing
    local integer playerIndex = 0

    set BridgeSystemTable = InitHashtable()
    set BridgeSystemTrackedUnits = CreateGroup()
    set BridgeSystemValidationGroup = CreateGroup()
    set BridgeSystemRectEnumGroup = CreateGroup()
    set BridgeSystemIgnoredUnits = CreateGroup()
    set BridgeSystemClock = CreateTimer()

    set BridgeSystemOrderTrigger = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(BridgeSystemOrderTrigger, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call TriggerRegisterAnyUnitEventBJ(BridgeSystemOrderTrigger, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call TriggerRegisterAnyUnitEventBJ(BridgeSystemOrderTrigger, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(BridgeSystemOrderTrigger, function BridgeSystem_OnIssuedOrder)

    set BridgeSystemDeathTrigger = CreateTrigger()
    loop
        exitwhen playerIndex > 27
        call TriggerRegisterPlayerUnitEvent(BridgeSystemDeathTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DEATH, null)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(BridgeSystemDeathTrigger, function BridgeSystem_OnDeath)

    call TimerStart(BridgeSystemClock, 999999.0, false, function BridgeSystem_DoNothing)
    call TimerStart(CreateTimer(), BRIDGE_VALIDATE_PERIOD, true, function BridgeSystem_PeriodicValidate)
    call TimerStart(CreateTimer(), 1.0, false, function BridgeSystem_InitDelayed)
endfunction

endlibrary
