/**
    DoodadRender

    Author: Valdemar
    Version: 1.4.0

    Description:
        Reduces rendering load by hiding selected preplaced doodad types outside
        a camera-eye-centered tile area. The production-default area backend uses
        rawcode/rect animation calls. An opt-in Warcraft III 3.0 backend builds a
        runtime instance index and updates individual doodads for comparison.

    Credits:
        Camera-grid concept based on Zwiebelchen's DestructableHider.

    How to install:
        Import DoodadManager.j before this library through the normal JassHelper
        workflow. Additional types may be registered through RegisterType. The
        indexed backend requires Warcraft III 3.0.0.24268 or newer.

    API:
        DoodadRender_RegisterType(integer doodadId, real drawDistance)
        DoodadRender_Enable()
        DoodadRender_Disable()
        DoodadRender_Refresh()
        DoodadRender_SetBackend(integer backend) -> boolean
        DoodadRender_GetBackend() -> integer
        DoodadRender_GetBackendName() -> string
        DoodadRender_IsEnabled() -> boolean
        DoodadRender_IsIndexedDatabaseBuilt() -> boolean
        DoodadRender_GetIndexedSourceCount() -> integer
        DoodadRender_GetIndexedInstanceCount() -> integer
        DoodadRender_GetIndexedBuildElapsed() -> real
        DoodadRender_GetAreaAnimationCallCount() -> integer
        DoodadRender_GetIndexedAnimationCallCount() -> integer
        DoodadRender_GetTransitionCount() -> integer
        DoodadRender_GetFullRefreshCount() -> integer
        DoodadRender_GetLastRebuildElapsed() -> real
        DoodadRender_GetTransitionElapsedTotal() -> real
        DoodadRender_GetTransitionElapsedMax() -> real
        DoodadRender_ResetDiagnostics()
        DoodadRender_SuspendForCinematic()
        DoodadRender_ResumeAfterCinematic()

**/
library DoodadRender initializer Init requires DoodadManager
    globals
        constant integer DOODAD_RENDER_BACKEND_AREA = 0
        constant integer DOODAD_RENDER_BACKEND_INDEXED = 1

        // Configuration
        private constant real UPDATE_INTERVAL = 0.20
        private constant real TILE_SIZE = 512.00
        private constant integer OVERSCAN_TILES = 0
        private constant boolean DISABLE_DURING_CINEMATICS = true
        private constant boolean DEBUG = false
        private constant integer DEFAULT_BACKEND = DOODAD_RENDER_BACKEND_AREA

        // Hashtable namespaces. Type indices are positive parent keys; indexed
        // instance nodes use negative parent keys and store doodad/next fields.
        private constant integer INDEX_TYPE_LOOKUP_PARENT = 0
        private constant integer INDEX_NODE_DOODAD = 0
        private constant integer INDEX_NODE_NEXT = 1

        // Managed doodad types and their effective tile radii.
        private integer typeCount = 0
        private integer array typeId
        private integer array typeRadius

        // Playable-map grid geometry.
        private real mapMinX = 0.00
        private real mapMinY = 0.00
        private real mapMaxX = 0.00
        private real mapMaxY = 0.00
        private integer columns = 0
        private integer rows = 0

        // Runtime state and reusable handles.
        private rect workRect = null
        private timer updateTimer = null
        private timer diagnosticClock = null
        private integer lastColumn = -1
        private integer lastRow = -1
        private integer cameraColumn = 0
        private integer cameraRow = 0
        private integer backend = DEFAULT_BACKEND
        private boolean enabled = false
        private boolean initialized = false
        private integer cinematicSuspendDepth = 0
        private boolean cinematicWasEnabled = false

        // The indexed backend is built lazily so the default backend keeps its
        // existing startup cost. No JASS arrays scale with placement count.
        private hashtable indexedStore = null
        private boolean indexedBuilt = false
        private integer indexedSourceCount = 0
        private integer indexedInstanceCount = 0
        private real indexedBuildElapsed = 0.00

        // Optional per-client diagnostics.
        private integer areaAnimationCallCount = 0
        private integer indexedAnimationCallCount = 0
        private integer transitionCount = 0
        private integer fullRefreshCount = 0
        private real lastRebuildElapsed = 0.00
        private real transitionElapsedTotal = 0.00
        private real transitionElapsedMax = 0.00
    endglobals

    private function AbsInteger takes integer value returns integer
        if value < 0 then
            return -value
        endif
        return value
    endfunction

    private function IsValidBackend takes integer value returns boolean
        return value == DOODAD_RENDER_BACKEND_AREA or value == DOODAD_RENDER_BACKEND_INDEXED
    endfunction

    private function BackendName takes nothing returns string
        if backend == DOODAD_RENDER_BACKEND_INDEXED then
            return "indexed"
        endif
        return "area"
    endfunction

    private function CalculateGridCells takes real mapSize returns integer
        local integer result = R2I(mapSize / TILE_SIZE)

        if I2R(result) * TILE_SIZE < mapSize then
            set result = result + 1
        endif
        if result < 1 then
            set result = 1
        endif
        return result
    endfunction

    private function WorldToColumn takes real x returns integer
        local integer column = R2I((x - mapMinX) / TILE_SIZE)

        if column < 0 then
            return 0
        endif
        if column >= columns then
            return columns - 1
        endif
        return column
    endfunction

    private function WorldToRow takes real y returns integer
        local integer row = R2I((y - mapMinY) / TILE_SIZE)

        if row < 0 then
            return 0
        endif
        if row >= rows then
            return rows - 1
        endif
        return row
    endfunction

    private function GridCellId takes integer column, integer row returns integer
        return row * columns + column
    endfunction

    // The camera eye makes configured ranges behave as distance from the viewer.
    private function ReadCameraCell takes nothing returns nothing
        set cameraColumn = WorldToColumn(GetCameraEyePositionX())
        set cameraRow = WorldToRow(GetCameraEyePositionY())
    endfunction

    private function DistanceToRadius takes real drawDistance returns integer
        local integer radius

        if drawDistance < 0.00 then
            set drawDistance = 0.00
        endif
        set radius = R2I(drawDistance / TILE_SIZE)
        if I2R(radius) * TILE_SIZE < drawDistance then
            set radius = radius + 1
        endif
        return radius + OVERSCAN_TILES
    endfunction

    private function FindType takes integer doodadId returns integer
        local integer index = 1

        loop
            exitwhen index > typeCount
            if typeId[index] == doodadId then
                return index
            endif
            set index = index + 1
        endloop
        return 0
    endfunction

    private function ResetIndexedDatabase takes nothing returns nothing
        local integer index = 1

        call FlushParentHashtable(indexedStore)
        loop
            exitwhen index > typeCount
            call SaveInteger(indexedStore, INDEX_TYPE_LOOKUP_PARENT, typeId[index], index)
            set index = index + 1
        endloop
        set indexedBuilt = false
        set indexedSourceCount = 0
        set indexedInstanceCount = 0
        set indexedBuildElapsed = 0.00
    endfunction

    // Builds type/cell linked lists without relying on JASS array capacity.
    private function BuildIndexedDatabase takes nothing returns nothing
        local timer clock
        local integer doodadIndex
        local integer doodadId
        local integer typeIndex
        local integer column
        local integer row
        local integer cellId
        local integer head
        local real doodadX
        local real doodadY

        if indexedBuilt then
            return
        endif

        call ResetIndexedDatabase()
        set clock = CreateTimer()
        call TimerStart(clock, 86400.00, false, null)
        set indexedSourceCount = BlzGetNumDoodads()
        set doodadIndex = 0
        loop
            exitwhen doodadIndex >= indexedSourceCount
            set doodadId = BlzGetDoodadId(doodadIndex)
            set typeIndex = LoadInteger(indexedStore, INDEX_TYPE_LOOKUP_PARENT, doodadId)
            if typeIndex > 0 then
                set doodadX = BlzGetDoodadX(doodadIndex)
                set doodadY = BlzGetDoodadY(doodadIndex)
                if doodadX >= mapMinX and doodadX <= mapMaxX and doodadY >= mapMinY and doodadY <= mapMaxY then
                    set column = WorldToColumn(doodadX)
                    set row = WorldToRow(doodadY)
                    set cellId = GridCellId(column, row)
                    set head = LoadInteger(indexedStore, typeIndex, cellId)
                    set indexedInstanceCount = indexedInstanceCount + 1
                    call SaveInteger(indexedStore, -indexedInstanceCount, INDEX_NODE_DOODAD, doodadIndex)
                    call SaveInteger(indexedStore, -indexedInstanceCount, INDEX_NODE_NEXT, head)
                    call SaveInteger(indexedStore, typeIndex, cellId, indexedInstanceCount)
                endif
            endif
            set doodadIndex = doodadIndex + 1
        endloop
        set indexedBuildElapsed = TimerGetElapsed(clock)
        set indexedBuilt = true
        call PauseTimer(clock)
        call DestroyTimer(clock)
        set clock = null
    endfunction

    // Converts inclusive grid bounds to one clamped reusable world rect.
    private function SetWorkRect takes integer minColumn, integer minRow, integer maxColumn, integer maxRow returns boolean
        local real minX
        local real minY
        local real maxX
        local real maxY

        if minColumn > maxColumn or minRow > maxRow then
            return false
        endif
        if maxColumn < 0 or maxRow < 0 or minColumn >= columns or minRow >= rows then
            return false
        endif

        if minColumn < 0 then
            set minColumn = 0
        endif
        if minRow < 0 then
            set minRow = 0
        endif
        if maxColumn >= columns then
            set maxColumn = columns - 1
        endif
        if maxRow >= rows then
            set maxRow = rows - 1
        endif

        set minX = mapMinX + I2R(minColumn) * TILE_SIZE
        set minY = mapMinY + I2R(minRow) * TILE_SIZE
        set maxX = mapMinX + I2R(maxColumn + 1) * TILE_SIZE
        set maxY = mapMinY + I2R(maxRow + 1) * TILE_SIZE

        if maxX > mapMaxX then
            set maxX = mapMaxX
        endif
        if maxY > mapMaxY then
            set maxY = mapMaxY
        endif

        call SetRect(workRect, minX, minY, maxX, maxY)
        return true
    endfunction

    private function SetTypeArea takes integer typeIndex, integer minColumn, integer minRow, integer maxColumn, integer maxRow, boolean show returns nothing
        if not SetWorkRect(minColumn, minRow, maxColumn, maxRow) then
            return
        endif

        if show then
            call SetDoodadAnimationRect(workRect, typeId[typeIndex], "show", false)
        else
            call SetDoodadAnimationRect(workRect, typeId[typeIndex], "hide", false)
        endif
        set areaAnimationCallCount = areaAnimationCallCount + 1
    endfunction

    private function SetTypeGlobally takes integer typeIndex, boolean show returns nothing
        if show then
            call SetDoodadAnimationRect(bj_mapInitialPlayableArea, typeId[typeIndex], "show", false)
        else
            call SetDoodadAnimationRect(bj_mapInitialPlayableArea, typeId[typeIndex], "hide", false)
        endif
        set areaAnimationCallCount = areaAnimationCallCount + 1
    endfunction

    private function HideAllManagedTypes takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > typeCount
            call SetTypeGlobally(index, false)
            set index = index + 1
        endloop
    endfunction

    private function ShowAllManagedTypes takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > typeCount
            call SetTypeGlobally(index, true)
            set index = index + 1
        endloop
    endfunction

    private function ShowCurrentAreas takes integer column, integer row returns nothing
        local integer index = 1
        local integer radius

        loop
            exitwhen index > typeCount
            set radius = typeRadius[index]
            call SetTypeArea(index, column - radius, row - radius, column + radius, row + radius, true)
            set index = index + 1
        endloop
    endfunction

    private function SetIndexedNodeAnimation takes integer node, boolean show returns nothing
        local integer doodadIndex = LoadInteger(indexedStore, -node, INDEX_NODE_DOODAD)

        if show then
            call BlzSetSingleDoodadAnimation(doodadIndex, "show", false)
        else
            call BlzSetSingleDoodadAnimation(doodadIndex, "hide", false)
        endif
        set indexedAnimationCallCount = indexedAnimationCallCount + 1
    endfunction

    private function SetIndexedCell takes integer typeIndex, integer column, integer row, boolean show returns nothing
        local integer node

        if column < 0 or column >= columns or row < 0 or row >= rows then
            return
        endif
        set node = LoadInteger(indexedStore, typeIndex, GridCellId(column, row))
        loop
            exitwhen node == 0
            call SetIndexedNodeAnimation(node, show)
            set node = LoadInteger(indexedStore, -node, INDEX_NODE_NEXT)
        endloop
    endfunction

    private function SetIndexedTypeArea takes integer typeIndex, integer minColumn, integer minRow, integer maxColumn, integer maxRow, boolean show returns nothing
        local integer column
        local integer row

        if minColumn > maxColumn or minRow > maxRow then
            return
        endif
        if maxColumn < 0 or maxRow < 0 or minColumn >= columns or minRow >= rows then
            return
        endif
        if minColumn < 0 then
            set minColumn = 0
        endif
        if minRow < 0 then
            set minRow = 0
        endif
        if maxColumn >= columns then
            set maxColumn = columns - 1
        endif
        if maxRow >= rows then
            set maxRow = rows - 1
        endif

        set row = minRow
        loop
            exitwhen row > maxRow
            set column = minColumn
            loop
                exitwhen column > maxColumn
                call SetIndexedCell(typeIndex, column, row, show)
                set column = column + 1
            endloop
            set row = row + 1
        endloop
    endfunction

    private function HideAllIndexedInstances takes nothing returns nothing
        local integer node = 1

        loop
            exitwhen node > indexedInstanceCount
            call SetIndexedNodeAnimation(node, false)
            set node = node + 1
        endloop
    endfunction

    private function ShowAllIndexedInstances takes nothing returns nothing
        local integer node = 1

        loop
            exitwhen node > indexedInstanceCount
            call SetIndexedNodeAnimation(node, true)
            set node = node + 1
        endloop
    endfunction

    private function ShowIndexedCurrentAreas takes integer column, integer row returns nothing
        local integer index = 1
        local integer radius

        loop
            exitwhen index > typeCount
            set radius = typeRadius[index]
            call SetIndexedTypeArea(index, column - radius, row - radius, column + radius, row + radius, true)
            set index = index + 1
        endloop
    endfunction

    private function UpdateIndexedTypeHorizontal takes integer typeIndex, integer oldColumn, integer oldRow, integer newColumn, integer newRow returns nothing
        local integer radius = typeRadius[typeIndex]

        if newColumn > oldColumn then
            call SetIndexedTypeArea(typeIndex, oldColumn - radius, oldRow - radius, oldColumn - radius, oldRow + radius, false)
            call SetIndexedTypeArea(typeIndex, newColumn + radius, newRow - radius, newColumn + radius, newRow + radius, true)
        elseif newColumn < oldColumn then
            call SetIndexedTypeArea(typeIndex, oldColumn + radius, oldRow - radius, oldColumn + radius, oldRow + radius, false)
            call SetIndexedTypeArea(typeIndex, newColumn - radius, newRow - radius, newColumn - radius, newRow + radius, true)
        endif
    endfunction

    private function UpdateIndexedTypeVertical takes integer typeIndex, integer oldColumn, integer oldRow, integer newColumn, integer newRow returns nothing
        local integer radius = typeRadius[typeIndex]

        if newRow > oldRow then
            call SetIndexedTypeArea(typeIndex, oldColumn - radius, oldRow - radius, oldColumn + radius, oldRow - radius, false)
            call SetIndexedTypeArea(typeIndex, newColumn - radius, newRow + radius, newColumn + radius, newRow + radius, true)
        elseif newRow < oldRow then
            call SetIndexedTypeArea(typeIndex, oldColumn - radius, oldRow + radius, oldColumn + radius, oldRow + radius, false)
            call SetIndexedTypeArea(typeIndex, newColumn - radius, newRow - radius, newColumn + radius, newRow - radius, true)
        endif
    endfunction

    private function UpdateIndexedTypeFull takes integer typeIndex, integer oldColumn, integer oldRow, integer newColumn, integer newRow returns nothing
        local integer radius = typeRadius[typeIndex]

        call SetIndexedTypeArea(typeIndex, oldColumn - radius, oldRow - radius, oldColumn + radius, oldRow + radius, false)
        call SetIndexedTypeArea(typeIndex, newColumn - radius, newRow - radius, newColumn + radius, newRow + radius, true)
    endfunction

    private function UpdateTypeHorizontal takes integer typeIndex, integer oldColumn, integer oldRow, integer newColumn, integer newRow returns nothing
        local integer radius = typeRadius[typeIndex]

        if newColumn > oldColumn then
            call SetTypeArea(typeIndex, oldColumn - radius, oldRow - radius, oldColumn - radius, oldRow + radius, false)
            call SetTypeArea(typeIndex, newColumn + radius, newRow - radius, newColumn + radius, newRow + radius, true)
        elseif newColumn < oldColumn then
            call SetTypeArea(typeIndex, oldColumn + radius, oldRow - radius, oldColumn + radius, oldRow + radius, false)
            call SetTypeArea(typeIndex, newColumn - radius, newRow - radius, newColumn - radius, newRow + radius, true)
        endif
    endfunction

    private function UpdateTypeVertical takes integer typeIndex, integer oldColumn, integer oldRow, integer newColumn, integer newRow returns nothing
        local integer radius = typeRadius[typeIndex]

        if newRow > oldRow then
            call SetTypeArea(typeIndex, oldColumn - radius, oldRow - radius, oldColumn + radius, oldRow - radius, false)
            call SetTypeArea(typeIndex, newColumn - radius, newRow + radius, newColumn + radius, newRow + radius, true)
        elseif newRow < oldRow then
            call SetTypeArea(typeIndex, oldColumn - radius, oldRow + radius, oldColumn + radius, oldRow + radius, false)
            call SetTypeArea(typeIndex, newColumn - radius, newRow - radius, newColumn + radius, newRow - radius, true)
        endif
    endfunction

    private function UpdateTypeFull takes integer typeIndex, integer oldColumn, integer oldRow, integer newColumn, integer newRow returns nothing
        local integer radius = typeRadius[typeIndex]

        call SetTypeArea(typeIndex, oldColumn - radius, oldRow - radius, oldColumn + radius, oldRow + radius, false)
        call SetTypeArea(typeIndex, newColumn - radius, newRow - radius, newColumn + radius, newRow + radius, true)
    endfunction

    private function DebugTransition takes integer column, integer row, boolean fullRefresh returns nothing
        if DEBUG then
            if fullRefresh then
                call BJDebugMsg("DoodadRender | Backend: " + BackendName() + " | Camera tile: " + I2S(column) + ", " + I2S(row) + " | Types: " + I2S(typeCount) + " | Transitions: " + I2S(transitionCount) + " | Area calls: " + I2S(areaAnimationCallCount) + " | Indexed calls: " + I2S(indexedAnimationCallCount) + " | Full refreshes: " + I2S(fullRefreshCount) + " | Full refresh: true")
            else
                call BJDebugMsg("DoodadRender | Backend: " + BackendName() + " | Camera tile: " + I2S(column) + ", " + I2S(row) + " | Types: " + I2S(typeCount) + " | Transitions: " + I2S(transitionCount) + " | Area calls: " + I2S(areaAnimationCallCount) + " | Indexed calls: " + I2S(indexedAnimationCallCount) + " | Full refreshes: " + I2S(fullRefreshCount) + " | Full refresh: false")
            endif
        endif
    endfunction

    private function UpdateVisibility takes integer oldColumn, integer oldRow, integer newColumn, integer newRow returns nothing
        local integer deltaColumn = newColumn - oldColumn
        local integer deltaRow = newRow - oldRow
        local integer index = 1
        local boolean fullRefresh = AbsInteger(deltaColumn) > 1 or AbsInteger(deltaRow) > 1

        loop
            exitwhen index > typeCount
            if backend == DOODAD_RENDER_BACKEND_INDEXED then
                if fullRefresh then
                    call UpdateIndexedTypeFull(index, oldColumn, oldRow, newColumn, newRow)
                else
                    call UpdateIndexedTypeHorizontal(index, oldColumn, oldRow, newColumn, newRow)
                    call UpdateIndexedTypeVertical(index, oldColumn, oldRow, newColumn, newRow)
                endif
            else
                if fullRefresh then
                    call UpdateTypeFull(index, oldColumn, oldRow, newColumn, newRow)
                else
                    call UpdateTypeHorizontal(index, oldColumn, oldRow, newColumn, newRow)
                    call UpdateTypeVertical(index, oldColumn, oldRow, newColumn, newRow)
                endif
            endif
            set index = index + 1
        endloop

        set transitionCount = transitionCount + 1
        if fullRefresh then
            set fullRefreshCount = fullRefreshCount + 1
        endif
        call DebugTransition(newColumn, newRow, fullRefresh)
    endfunction

    private function RebuildVisibleState takes nothing returns nothing
        local real startTime = TimerGetElapsed(diagnosticClock)

        call ReadCameraCell()
        if backend == DOODAD_RENDER_BACKEND_INDEXED then
            call BuildIndexedDatabase()
            call HideAllIndexedInstances()
            call ShowIndexedCurrentAreas(cameraColumn, cameraRow)
        else
            call HideAllManagedTypes()
            call ShowCurrentAreas(cameraColumn, cameraRow)
        endif
        set lastColumn = cameraColumn
        set lastRow = cameraRow
        set fullRefreshCount = fullRefreshCount + 1
        set lastRebuildElapsed = TimerGetElapsed(diagnosticClock) - startTime
        call DebugTransition(cameraColumn, cameraRow, true)
    endfunction

    private function Periodic takes nothing returns nothing
        local integer column
        local integer row
        local real startTime
        local real elapsed

        if not enabled then
            return
        endif

        call ReadCameraCell()
        set column = cameraColumn
        set row = cameraRow
        if column == lastColumn and row == lastRow then
            return
        endif

        set startTime = TimerGetElapsed(diagnosticClock)
        call UpdateVisibility(lastColumn, lastRow, column, row)
        set elapsed = TimerGetElapsed(diagnosticClock) - startTime
        set transitionElapsedTotal = transitionElapsedTotal + elapsed
        if elapsed > transitionElapsedMax then
            set transitionElapsedMax = elapsed
        endif
        set lastColumn = column
        set lastRow = row
    endfunction

    private function StartRendering takes nothing returns nothing
        if not initialized or enabled then
            return
        endif

        set enabled = true
        call RebuildVisibleState()
        call TimerStart(updateTimer, UPDATE_INTERVAL, true, function Periodic)
    endfunction

    private function StopRendering takes nothing returns nothing
        if not initialized or not enabled then
            return
        endif

        set enabled = false
        call PauseTimer(updateTimer)
        if backend == DOODAD_RENDER_BACKEND_INDEXED and indexedBuilt then
            call ShowAllIndexedInstances()
        else
            call ShowAllManagedTypes()
        endif
        set lastColumn = -1
        set lastRow = -1
    endfunction

    public function RegisterType takes integer doodadId, real drawDistance returns nothing
        local integer index
        local integer radius
        local boolean newType = false

        if doodadId == 0 then
            if DEBUG then
                call BJDebugMsg("DoodadRender | Ignored rawcode 0 registration.")
            endif
            return
        endif

        set radius = DistanceToRadius(drawDistance)
        set index = FindType(doodadId)
        if index == 0 then
            set typeCount = typeCount + 1
            set index = typeCount
            set typeId[index] = doodadId
            set newType = true
        elseif typeRadius[index] == radius then
            return
        endif
        set typeRadius[index] = radius

        if indexedStore != null then
            call SaveInteger(indexedStore, INDEX_TYPE_LOOKUP_PARENT, doodadId, index)
        endif
        if newType and indexedBuilt then
            if initialized and enabled and backend == DOODAD_RENDER_BACKEND_INDEXED then
                call ShowAllIndexedInstances()
            endif
            call ResetIndexedDatabase()
            if backend == DOODAD_RENDER_BACKEND_INDEXED then
                call BuildIndexedDatabase()
            endif
        endif

        if initialized and enabled then
            call RebuildVisibleState()
        endif
    endfunction

    public function SetBackend takes integer value returns boolean
        local boolean wasEnabled

        if not IsValidBackend(value) then
            return false
        endif
        if backend == value then
            return true
        endif

        set wasEnabled = enabled
        if wasEnabled then
            call StopRendering()
        endif
        set backend = value
        if backend == DOODAD_RENDER_BACKEND_INDEXED then
            call BuildIndexedDatabase()
        endif
        if wasEnabled then
            call StartRendering()
        endif
        return true
    endfunction

    public function GetBackend takes nothing returns integer
        return backend
    endfunction

    public function GetBackendName takes nothing returns string
        return BackendName()
    endfunction

    public function IsEnabled takes nothing returns boolean
        return enabled
    endfunction

    public function IsIndexedDatabaseBuilt takes nothing returns boolean
        return indexedBuilt
    endfunction

    public function GetIndexedSourceCount takes nothing returns integer
        return indexedSourceCount
    endfunction

    public function GetIndexedInstanceCount takes nothing returns integer
        return indexedInstanceCount
    endfunction

    public function GetIndexedBuildElapsed takes nothing returns real
        return indexedBuildElapsed
    endfunction

    public function GetAreaAnimationCallCount takes nothing returns integer
        return areaAnimationCallCount
    endfunction

    public function GetIndexedAnimationCallCount takes nothing returns integer
        return indexedAnimationCallCount
    endfunction

    public function GetTransitionCount takes nothing returns integer
        return transitionCount
    endfunction

    public function GetFullRefreshCount takes nothing returns integer
        return fullRefreshCount
    endfunction

    public function GetLastRebuildElapsed takes nothing returns real
        return lastRebuildElapsed
    endfunction

    public function GetTransitionElapsedTotal takes nothing returns real
        return transitionElapsedTotal
    endfunction

    public function GetTransitionElapsedMax takes nothing returns real
        return transitionElapsedMax
    endfunction

    public function ResetDiagnostics takes nothing returns nothing
        set areaAnimationCallCount = 0
        set indexedAnimationCallCount = 0
        set transitionCount = 0
        set fullRefreshCount = 0
        set lastRebuildElapsed = 0.00
        set transitionElapsedTotal = 0.00
        set transitionElapsedMax = 0.00
    endfunction

    public function Enable takes nothing returns nothing
        if cinematicSuspendDepth > 0 then
            set cinematicWasEnabled = true
            return
        endif
        call StartRendering()
    endfunction

    public function Disable takes nothing returns nothing
        if cinematicSuspendDepth > 0 then
            set cinematicWasEnabled = false
            return
        endif
        call StopRendering()
    endfunction

    public function Refresh takes nothing returns nothing
        if initialized and enabled then
            call RebuildVisibleState()
        endif
    endfunction

    public function SuspendForCinematic takes nothing returns nothing
        if not DISABLE_DURING_CINEMATICS then
            return
        endif

        if cinematicSuspendDepth == 0 then
            set cinematicWasEnabled = enabled
            call StopRendering()
        endif
        set cinematicSuspendDepth = cinematicSuspendDepth + 1
    endfunction

    public function ResumeAfterCinematic takes nothing returns nothing
        if not DISABLE_DURING_CINEMATICS or cinematicSuspendDepth <= 0 then
            return
        endif

        set cinematicSuspendDepth = cinematicSuspendDepth - 1
        if cinematicSuspendDepth == 0 and cinematicWasEnabled then
            call StartRendering()
        endif
    endfunction

    private function ConfigureTypes takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > DoodadManager_GetTypeCount()
            call RegisterType(DoodadManager_GetTypeId(index), DoodadManager_GetDrawDistance(index))
            set index = index + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        set mapMinX = GetRectMinX(bj_mapInitialPlayableArea)
        set mapMinY = GetRectMinY(bj_mapInitialPlayableArea)
        set mapMaxX = GetRectMaxX(bj_mapInitialPlayableArea)
        set mapMaxY = GetRectMaxY(bj_mapInitialPlayableArea)
        set columns = CalculateGridCells(mapMaxX - mapMinX)
        set rows = CalculateGridCells(mapMaxY - mapMinY)
        set workRect = Rect(mapMinX, mapMinY, mapMinX, mapMinY)
        set updateTimer = CreateTimer()
        set diagnosticClock = CreateTimer()
        call TimerStart(diagnosticClock, 86400.00, true, null)
        set indexedStore = InitHashtable()

        call ConfigureTypes()

        set initialized = true
        call Enable()
    endfunction
endlibrary
