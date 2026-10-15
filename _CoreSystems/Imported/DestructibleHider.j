/**
    DestructableHider

    Author: Zwiebelchen, modified by Valdemar
    Version: 1.4

    Description:
    Hides destructables outside the camera window. Camera-cell transitions update
    only the non-overlapping strips of the old and new tile rectangles.

    Credits:
    Zwiebelchen for the original DestructableHider implementation.

    How to install:
    Import this library before systems that call its runtime registration API.

    API:
    - DestructableHider_register(destructable)
    - DestructableHider_unregister(destructable)
    - DestructableHider_SetDiagnosticsEnabled(boolean)
    - DestructableHider_IsDiagnosticsEnabled() -> boolean
    - DestructableHider_ResetDiagnostics()
    - DestructableHider_GetTileCellCount() -> integer
    - DestructableHider_GetDestructableConsideredCount() -> integer
    - DestructableHider_GetShowCallCount() -> integer
    - DestructableHider_GetSameCellUpdateCount() -> integer
    - DestructableHider_GetOverlappingTransitionCount() -> integer
    - DestructableHider_GetNonOverlappingTransitionCount() -> integer

**/
library DestructableHider initializer init
    globals
        // Configuration
        private constant real INTERVAL = 0.2
        private constant integer DRAW_DISTANCE = 5120
        private constant integer TILE_RESOLUTION = 10
        private constant integer TILESIZE = DRAW_DISTANCE / TILE_RESOLUTION

        // Tile registration and camera-window state
        private hashtable hash = InitHashtable()
        private integer columns = 0
        private integer rows = 0
        private integer lastrow = -1
        private integer lastcolumn = -1
        private boolean hasLastCell = false
        private real mapMinX = 0.00
        private real mapMinY = 0.00

        // Disabled-by-default benchmark counters avoid strings in the hot path.
        private boolean diagnosticsEnabled = false
        private integer tileCellCount = 0
        private integer destructableConsideredCount = 0
        private integer showCallCount = 0
        private integer sameCellUpdateCount = 0
        private integer overlappingTransitionCount = 0
        private integer nonOverlappingTransitionCount = 0
    endglobals

    private function MaxInteger takes integer a, integer b returns integer
        if a > b then
            return a
        endif
        return b
    endfunction

    private function MinInteger takes integer a, integer b returns integer
        if a < b then
            return a
        endif
        return b
    endfunction

    // Determines whether a destructable should be included in the system.
    private function filt takes nothing returns boolean
        return true
    endfunction

    // Registers a destructable into the appropriate tile.
    public function register takes destructable d returns nothing
        local integer id = R2I((GetDestructableY(d) - mapMinY) / TILESIZE) * columns + R2I((GetDestructableX(d) - mapMinX) / TILESIZE)
        local integer count = LoadInteger(hash, id, 0) + 1

        call SaveInteger(hash, id, 0, count)
        call SaveDestructableHandle(hash, id, count, d)
        call SaveInteger(hash, GetHandleId(d), 0, count)
        if diagnosticsEnabled then
            set showCallCount = showCallCount + 1
        endif
        call ShowDestructable(d, LoadBoolean(hash, id, -1))
    endfunction

    // Unregisters a destructable and cleans up handle references.
    public function unregister takes destructable d returns nothing
        local integer id = R2I((GetDestructableY(d) - mapMinY) / TILESIZE) * columns + R2I((GetDestructableX(d) - mapMinX) / TILESIZE)
        local integer count = LoadInteger(hash, id, 0)
        local integer pos = LoadInteger(hash, GetHandleId(d), 0)
        local destructable temp

        if pos < count then
            set temp = LoadDestructableHandle(hash, id, count)
            call SaveDestructableHandle(hash, id, pos, temp)
            call SaveInteger(hash, GetHandleId(temp), 0, pos)
            set temp = null
        endif
        call RemoveSavedHandle(hash, id, count)
        call SaveInteger(hash, id, 0, count - 1)
        call FlushChildHashtable(hash, GetHandleId(d))
        if diagnosticsEnabled then
            set showCallCount = showCallCount + 1
        endif
        call ShowDestructable(d, true)
    endfunction

    // Automatically registers destructables during initialization.
    private function autoregister takes nothing returns nothing
        local destructable d = GetEnumDestructable()
        local integer id = R2I((GetDestructableY(d) - mapMinY) / TILESIZE) * columns + R2I((GetDestructableX(d) - mapMinX) / TILESIZE)
        local integer count = LoadInteger(hash, id, 0) + 1

        call SaveInteger(hash, id, 0, count)
        call SaveDestructableHandle(hash, id, count, d)
        call SaveInteger(hash, GetHandleId(d), 0, count)
        if diagnosticsEnabled then
            set showCallCount = showCallCount + 1
        endif
        call ShowDestructable(d, false)
        set d = null
    endfunction

    // Enumerates one already-clamped inclusive rectangle.
    private function EnumGrid takes integer x1, integer x2, integer y1, integer y2, boolean show returns nothing
        local integer x = x1
        local integer y
        local integer id
        local integer count
        local integer index

        if diagnosticsEnabled then
            set tileCellCount = tileCellCount + (x2 - x1 + 1) * (y2 - y1 + 1)
        endif
        loop
            exitwhen x > x2
            set y = y1
            loop
                exitwhen y > y2
                set id = y * columns + x
                if LoadBoolean(hash, id, -1) != show then
                    call SaveBoolean(hash, id, -1, show)
                    set count = LoadInteger(hash, id, 0)
                    if diagnosticsEnabled then
                        set destructableConsideredCount = destructableConsideredCount + count
                        set showCallCount = showCallCount + count
                    endif
                    set index = 1
                    loop
                        exitwhen index > count
                        call ShowDestructable(LoadDestructableHandle(hash, id, index), show)
                        set index = index + 1
                    endloop
                endif
                set y = y + 1
            endloop
            set x = x + 1
        endloop
    endfunction

    // Empty differential strips are rejected before reaching EnumGrid.
    private function EnumRect takes integer x1, integer x2, integer y1, integer y2, boolean show returns nothing
        if x1 <= x2 and y1 <= y2 then
            call EnumGrid(x1, x2, y1, y2, show)
        endif
    endfunction

    private function ShowWindow takes integer row, integer column returns nothing
        local integer x1 = MaxInteger(0, column - TILE_RESOLUTION)
        local integer x2 = MinInteger(columns - 1, column + TILE_RESOLUTION)
        local integer y1 = MaxInteger(0, row - TILE_RESOLUTION)
        local integer y2 = MinInteger(rows - 1, row + TILE_RESOLUTION)

        call EnumRect(x1, x2, y1, y2, true)
    endfunction

    // Updates old-new and new-old as four non-overlapping strips per rectangle.
    private function ChangeTiles takes integer row, integer column, integer lastRow, integer lastColumn returns nothing
        local integer oldX1 = MaxInteger(0, lastColumn - TILE_RESOLUTION)
        local integer oldX2 = MinInteger(columns - 1, lastColumn + TILE_RESOLUTION)
        local integer oldY1 = MaxInteger(0, lastRow - TILE_RESOLUTION)
        local integer oldY2 = MinInteger(rows - 1, lastRow + TILE_RESOLUTION)
        local integer newX1 = MaxInteger(0, column - TILE_RESOLUTION)
        local integer newX2 = MinInteger(columns - 1, column + TILE_RESOLUTION)
        local integer newY1 = MaxInteger(0, row - TILE_RESOLUTION)
        local integer newY2 = MinInteger(rows - 1, row + TILE_RESOLUTION)
        local integer intersectionX1
        local integer intersectionX2
        local integer intersectionY1
        local integer intersectionY2

        if oldX1 == newX1 and oldX2 == newX2 and oldY1 == newY1 and oldY2 == newY2 then
            if diagnosticsEnabled then
                set overlappingTransitionCount = overlappingTransitionCount + 1
            endif
            return
        endif

        set intersectionX1 = MaxInteger(oldX1, newX1)
        set intersectionX2 = MinInteger(oldX2, newX2)
        set intersectionY1 = MaxInteger(oldY1, newY1)
        set intersectionY2 = MinInteger(oldY2, newY2)

        if intersectionX1 > intersectionX2 or intersectionY1 > intersectionY2 then
            if diagnosticsEnabled then
                set nonOverlappingTransitionCount = nonOverlappingTransitionCount + 1
            endif
            call EnumRect(oldX1, oldX2, oldY1, oldY2, false)
            call EnumRect(newX1, newX2, newY1, newY2, true)
            return
        endif

        if diagnosticsEnabled then
            set overlappingTransitionCount = overlappingTransitionCount + 1
        endif

        // Full-height side strips and intersection-width top/bottom strips visit each tile once.
        call EnumRect(oldX1, intersectionX1 - 1, oldY1, oldY2, false)
        call EnumRect(intersectionX2 + 1, oldX2, oldY1, oldY2, false)
        call EnumRect(intersectionX1, intersectionX2, oldY1, intersectionY1 - 1, false)
        call EnumRect(intersectionX1, intersectionX2, intersectionY2 + 1, oldY2, false)

        call EnumRect(newX1, intersectionX1 - 1, newY1, newY2, true)
        call EnumRect(intersectionX2 + 1, newX2, newY1, newY2, true)
        call EnumRect(intersectionX1, intersectionX2, newY1, intersectionY1 - 1, true)
        call EnumRect(intersectionX1, intersectionX2, intersectionY2 + 1, newY2, true)
    endfunction

    // Periodically checks camera location and updates visible tiles.
    private function periodic takes nothing returns nothing
        local integer row = R2I((GetCameraTargetPositionY() - mapMinY) / TILESIZE)
        local integer column = R2I((GetCameraTargetPositionX() - mapMinX) / TILESIZE)

        if hasLastCell and row == lastrow and column == lastcolumn then
            if diagnosticsEnabled then
                set sameCellUpdateCount = sameCellUpdateCount + 1
            endif
            return
        endif
        if hasLastCell then
            call ChangeTiles(row, column, lastrow, lastcolumn)
        else
            // Initial registration already hid every destructable; only reveal the first window.
            call ShowWindow(row, column)
        endif
        set lastrow = row
        set lastcolumn = column
        set hasLastCell = true
    endfunction

    public function SetDiagnosticsEnabled takes boolean enabled returns nothing
        set diagnosticsEnabled = enabled
    endfunction

    public function IsDiagnosticsEnabled takes nothing returns boolean
        return diagnosticsEnabled
    endfunction

    public function ResetDiagnostics takes nothing returns nothing
        set tileCellCount = 0
        set destructableConsideredCount = 0
        set showCallCount = 0
        set sameCellUpdateCount = 0
        set overlappingTransitionCount = 0
        set nonOverlappingTransitionCount = 0
    endfunction

    public function GetTileCellCount takes nothing returns integer
        return tileCellCount
    endfunction

    public function GetDestructableConsideredCount takes nothing returns integer
        return destructableConsideredCount
    endfunction

    public function GetShowCallCount takes nothing returns integer
        return showCallCount
    endfunction

    public function GetSameCellUpdateCount takes nothing returns integer
        return sameCellUpdateCount
    endfunction

    public function GetOverlappingTransitionCount takes nothing returns integer
        return overlappingTransitionCount
    endfunction

    public function GetNonOverlappingTransitionCount takes nothing returns integer
        return nonOverlappingTransitionCount
    endfunction

    private function init takes nothing returns nothing
        set mapMinX = GetRectMinX(bj_mapInitialPlayableArea)
        set mapMinY = GetRectMinY(bj_mapInitialPlayableArea)
        set columns = R2I((GetRectMaxX(bj_mapInitialPlayableArea) - mapMinX) / TILESIZE) + 1
        set rows = R2I((GetRectMaxY(bj_mapInitialPlayableArea) - mapMinY) / TILESIZE) + 1
        set lastrow = -1
        set lastcolumn = -1
        set hasLastCell = false

        call EnumDestructablesInRect(bj_mapInitialPlayableArea, Filter(function filt), function autoregister)
        call TimerStart(CreateTimer(), INTERVAL, true, function periodic)
        call periodic()
    endfunction
endlibrary
