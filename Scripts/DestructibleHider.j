library DestructableHider initializer init

    /*  
        by Zwiebelchen v1.3 – WC3 2.02+ Stable
        Optimizes destructable rendering by hiding those outside the camera frustum.
        Greatly boosts FPS when many destructables are placed on the map.

        Changes in this version:
        - Preserves destructable handle safety
        - Fixes invalid tile indices causing save/load crashes
        - Cleans up hashtable memory properly
        - Avoids redundant ShowDestructable() calls

        Modified by: Valdemar
    */

    globals
        private constant real INTERVAL = 0.2
        private constant integer DRAW_DISTANCE = 5120
        private constant integer TILE_RESOLUTION = 10
        private hashtable hash = InitHashtable()
        private integer columns = 0
        private integer rows = 0
        private integer lastrow = -1
        private integer lastcolumn = -1
        private integer lastid = -1
        private real mapMinX = 0
        private real mapMinY = 0
        private constant integer TILESIZE = DRAW_DISTANCE / TILE_RESOLUTION
    endglobals

    // Determines whether a destructable should be included in the system
    private function filt takes nothing returns boolean
        return true
    endfunction

    // Registers a destructable into the appropriate tile
    public function register takes destructable d returns nothing
        local integer id = R2I((GetDestructableY(d)-mapMinY)/TILESIZE)*columns + R2I((GetDestructableX(d)-mapMinX)/TILESIZE)
        local integer count = LoadInteger(hash, id, 0) + 1
        call SaveInteger(hash, id, 0, count)
        call SaveDestructableHandle(hash, id, count, d)
        call SaveInteger(hash, GetHandleId(d), 0, count)
        call ShowDestructable(d, LoadBoolean(hash, id, -1))
    endfunction

    // Unregisters a destructable and cleans up handle references
    public function unregister takes destructable d returns nothing
        local integer id = R2I((GetDestructableY(d)-mapMinY)/TILESIZE)*columns + R2I((GetDestructableX(d)-mapMinX)/TILESIZE)
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
        call ShowDestructable(d, true)
    endfunction

    // Automatically registers destructables during initialization
    private function autoregister takes nothing returns nothing
        local destructable d = GetEnumDestructable()
        local integer id = R2I((GetDestructableY(d)-mapMinY)/TILESIZE)*columns + R2I((GetDestructableX(d)-mapMinX)/TILESIZE)
        local integer count = LoadInteger(hash, id, 0) + 1
        call SaveInteger(hash, id, 0, count)
        call SaveDestructableHandle(hash, id, count, d)
        call SaveInteger(hash, GetHandleId(d), 0, count)
        call ShowDestructable(d, false)
    endfunction

    // Enumerates tiles and toggles their visibility
    private function EnumGrid takes integer x1, integer x2, integer y1, integer y2, boolean show returns nothing
        local integer a = x1
        local integer b
        local integer id
        local integer count
        local integer j

        if a < 0 then
            set a = 0
        endif
        if x2 >= columns then
            set x2 = columns - 1
        endif

        loop
            exitwhen a > x2
            set b = y1
            if b < 0 then
                set b = 0
            endif
            if y2 >= rows then
                set y2 = rows - 1
            endif

            loop
                exitwhen b > y2
                set id = b * columns + a
                if LoadBoolean(hash, id, -1) != show then
                    call SaveBoolean(hash, id, -1, show)
                    set count = LoadInteger(hash, id, 0)
                    set j = 1
                    loop
                        exitwhen j > count
                        call ShowDestructable(LoadDestructableHandle(hash, id, j), show)
                        set j = j + 1
                    endloop
                endif
                set b = b + 1
            endloop
            set a = a + 1
        endloop
    endfunction

    // Handles tile transitions to manage visibility
    private function ChangeTiles takes integer r, integer c, integer lr, integer lc returns nothing
        call EnumGrid(lc - TILE_RESOLUTION, lc + TILE_RESOLUTION, lr - TILE_RESOLUTION, lr + TILE_RESOLUTION, false) // Hide old
        call EnumGrid(c - TILE_RESOLUTION, c + TILE_RESOLUTION, r - TILE_RESOLUTION, r + TILE_RESOLUTION, true)      // Show new
    endfunction

    // Periodically checks camera location and updates visible tiles
    private function periodic takes nothing returns nothing
        local integer row = R2I((GetCameraTargetPositionY() - mapMinY) / TILESIZE)
        local integer col = R2I((GetCameraTargetPositionX() - mapMinX) / TILESIZE)
        local integer id = row * columns + col
        if id != lastid then
            call ChangeTiles(row, col, lastrow, lastcolumn)
            set lastrow = row
            set lastcolumn = col
            set lastid = id
        endif
    endfunction

    // Initializes the destructable hider system
    private function init takes nothing returns nothing
        set mapMinX = GetRectMinX(bj_mapInitialPlayableArea)
        set mapMinY = GetRectMinY(bj_mapInitialPlayableArea)
        set columns = R2I((GetRectMaxX(bj_mapInitialPlayableArea) - mapMinX) / TILESIZE) + 1
        set rows = R2I((GetRectMaxY(bj_mapInitialPlayableArea) - mapMinY) / TILESIZE) + 1
        set lastrow = -1
        set lastcolumn = -1
        set lastid = -1

        call EnumDestructablesInRect(bj_mapInitialPlayableArea, Filter(function filt), function autoregister)
        call TimerStart(CreateTimer(), INTERVAL, true, function periodic)
        call periodic()
    endfunction

endlibrary
