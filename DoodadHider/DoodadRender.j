/**
    DoodadRender

    Author: Valdemar
    Version: 1.2.0

    Description:
        Reduces rendering load by hiding selected preplaced doodad types outside
        a camera-eye-centered tile area. Doodads are managed by rawcode and rect;
        no handles, instance registration, or placement changes are used.

    Credits:
        Camera-grid concept based on Zwiebelchen's DestructableHider.

    How to install:
        Import DoodadManager.j before this library through the normal JassHelper
        workflow. Additional types may be registered through RegisterType.

    API:
        DoodadRender_RegisterType(integer doodadId, real drawDistance)
        DoodadRender_Enable()
        DoodadRender_Disable()
        DoodadRender_Refresh()

**/
library DoodadRender initializer Init requires DoodadManager
    globals
        // Configuration
        private constant real UPDATE_INTERVAL = 0.20
        private constant real TILE_SIZE = 512.00
        private constant integer OVERSCAN_TILES = 0
        private constant boolean DEBUG = false

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
        private integer lastColumn = -1
        private integer lastRow = -1
        private integer cameraColumn = 0
        private integer cameraRow = 0
        private boolean enabled = false
        private boolean initialized = false

        // Optional per-client diagnostics.
        private integer animationCallCount = 0
        private integer transitionCount = 0
        private integer fullRefreshCount = 0
    endglobals

    private function AbsInteger takes integer value returns integer
        if value < 0 then
            return -value
        endif
        return value
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
        if DEBUG then
            set animationCallCount = animationCallCount + 1
        endif
    endfunction

    private function SetTypeGlobally takes integer typeIndex, boolean show returns nothing
        if show then
            call SetDoodadAnimationRect(bj_mapInitialPlayableArea, typeId[typeIndex], "show", false)
        else
            call SetDoodadAnimationRect(bj_mapInitialPlayableArea, typeId[typeIndex], "hide", false)
        endif
        if DEBUG then
            set animationCallCount = animationCallCount + 1
        endif
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
                call BJDebugMsg("DoodadRender | Camera tile: " + I2S(column) + ", " + I2S(row) + " | Types: " + I2S(typeCount) + " | Transitions: " + I2S(transitionCount) + " | Calls: " + I2S(animationCallCount) + " | Full refreshes: " + I2S(fullRefreshCount) + " | Full refresh: true")
            else
                call BJDebugMsg("DoodadRender | Camera tile: " + I2S(column) + ", " + I2S(row) + " | Types: " + I2S(typeCount) + " | Transitions: " + I2S(transitionCount) + " | Calls: " + I2S(animationCallCount) + " | Full refreshes: " + I2S(fullRefreshCount) + " | Full refresh: false")
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
            if fullRefresh then
                call UpdateTypeFull(index, oldColumn, oldRow, newColumn, newRow)
            else
                call UpdateTypeHorizontal(index, oldColumn, oldRow, newColumn, newRow)
                call UpdateTypeVertical(index, oldColumn, oldRow, newColumn, newRow)
            endif
            set index = index + 1
        endloop

        if DEBUG then
            set transitionCount = transitionCount + 1
            if fullRefresh then
                set fullRefreshCount = fullRefreshCount + 1
            endif
        endif
        call DebugTransition(newColumn, newRow, fullRefresh)
    endfunction

    private function RebuildVisibleState takes nothing returns nothing
        call ReadCameraCell()
        call HideAllManagedTypes()
        call ShowCurrentAreas(cameraColumn, cameraRow)
        set lastColumn = cameraColumn
        set lastRow = cameraRow
        if DEBUG then
            set fullRefreshCount = fullRefreshCount + 1
        endif
        call DebugTransition(cameraColumn, cameraRow, true)
    endfunction

    private function Periodic takes nothing returns nothing
        local integer column
        local integer row

        if not enabled then
            return
        endif

        call ReadCameraCell()
        set column = cameraColumn
        set row = cameraRow
        if column == lastColumn and row == lastRow then
            return
        endif

        call UpdateVisibility(lastColumn, lastRow, column, row)
        set lastColumn = column
        set lastRow = row
    endfunction

    public function RegisterType takes integer doodadId, real drawDistance returns nothing
        local integer index
        local integer radius

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
        elseif typeRadius[index] == radius then
            return
        endif
        set typeRadius[index] = radius

        if initialized and enabled then
            call RebuildVisibleState()
        endif
    endfunction

    public function Enable takes nothing returns nothing
        if not initialized or enabled then
            return
        endif

        set enabled = true
        call RebuildVisibleState()
        call TimerStart(updateTimer, UPDATE_INTERVAL, true, function Periodic)
    endfunction

    public function Disable takes nothing returns nothing
        if not initialized or not enabled then
            return
        endif

        set enabled = false
        call PauseTimer(updateTimer)
        call ShowAllManagedTypes()
        set lastColumn = -1
        set lastRow = -1
    endfunction

    public function Refresh takes nothing returns nothing
        if initialized and enabled then
            call RebuildVisibleState()
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

        call ConfigureTypes()

        set initialized = true
        call Enable()
    endfunction
endlibrary
