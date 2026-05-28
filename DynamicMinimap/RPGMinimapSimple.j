library RPGMinimap initializer Init requires optional TerrainTextureColors
//===========================================================================
/*
    RPG Minimap - vJASS Implementation
    
    A scrolling minimap system for RPG maps with locked camera.
    Uses proper vJASS structs and modern coding practices.NO
    
    Features:
    - Scrolling minimap centered on camera
    - Terrain texture rendering with fog of war
    - Dynamic icon management using structs
    - Hero auto-registration
    - Efficient frame recycling
    
    API:
        RPGMinimap.registerIcon(unit, texture, size) -> MinimapIcon
        RPGMinimap.removeIcon(unit)
        RPGMinimap.revealCircle(x, y, radius)
        RPGMinimap.revealRect(minX, minY, maxX, maxY)
        RPGMinimap.show(enable)
*/
//===========================================================================

globals
    // Configuration
    private constant boolean DEBUG = true
    private constant real UPDATE_INTERVAL = 0.03
    private constant integer TILES_VISIBLE = 20
    private constant real SCREEN_SIZE = 0.20
    private constant real SCREEN_X = 0.01
    private constant real SCREEN_Y = 0.01
    private constant integer MAX_MAP_TILES = 256
    
    // Colors
    private constant integer COLOR_FOG = 0x20202020
    private constant integer COLOR_BLACK = 0x00000000
    private constant integer COLOR_FALLBACK = 0x50505050
endglobals

//===========================================================================
// Native functions (remove if already in MAP header or elsewhere)
//===========================================================================
function UnitAlive takes unit u returns boolean
    return not IsUnitType(u, UNIT_TYPE_DEAD) and GetUnitTypeId(u) != 0
endfunction

//===========================================================================
// Simple Table Implementation
//===========================================================================
struct Table
    private hashtable ht = InitHashtable()
    private integer key
    
    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.key = this
        return this
    endmethod
    
    method store takes integer k, integer value returns nothing
        call SaveInteger(this.ht, this.key, k, value)
    endmethod
    
    method load takes integer k returns integer
        return LoadInteger(this.ht, this.key, k)
    endmethod
    
    method has takes integer k returns boolean
        return HaveSavedInteger(this.ht, this.key, k)
    endmethod
    
    method remove takes integer k returns nothing
        call RemoveSavedInteger(this.ht, this.key, k)
    endmethod
    
    method flush takes nothing returns nothing
        call FlushChildHashtable(this.ht, this.key)
    endmethod
    
    method destroy takes nothing returns nothing
        call this.flush()
        call this.deallocate()
    endmethod
endstruct

//===========================================================================
// Terrain Tile Struct
//===========================================================================
struct TerrainTile
    framehandle frame
    integer worldX = -999
    integer worldY = -999
    real mapMinX
    real mapMinY
    real mapMaxX
    real mapMaxY
    
    static method create takes framehandle f, real minX, real minY, real maxX, real maxY returns thistype
        local thistype this = thistype.allocate()
        set this.frame = f
        set this.mapMinX = minX
        set this.mapMinY = minY
        set this.mapMaxX = maxX
        set this.mapMaxY = maxY
        return this
    endmethod
    
    method updateTile takes integer newX, integer newY, boolean explored returns nothing
        local real worldPosX
        local real worldPosY
        local integer terrainType
        local integer color
        
        if this.worldX == newX and this.worldY == newY then
            return
        endif
        
        set this.worldX = newX
        set this.worldY = newY
        
        set worldPosX = I2R(newX) * 128.0
        set worldPosY = I2R(newY) * 128.0
        
        // Check bounds
        if worldPosX < this.mapMinX or worldPosX > this.mapMaxX or worldPosY < this.mapMinY or worldPosY > this.mapMaxY then
            call BlzFrameSetVertexColor(this.frame, COLOR_BLACK)
            call BlzFrameSetVisible(this.frame, true)
            return
        endif
        
        // Check fog of war (TEMPORARILY DISABLED FOR TESTING)
        //if not explored then
        //    call BlzFrameSetVertexColor(this.frame, COLOR_FOG)
        //    call BlzFrameSetVisible(this.frame, true)
        //    return
        //endif
        
        // Get terrain color
        set terrainType = GetTerrainType(worldPosX, worldPosY)
        set color = GetTerrainColorForType(terrainType)
        
        if color == 0 then
            if DEBUG then
                call BJDebugMsg("Missing terrain type: " + I2S(terrainType))
            endif
            // Use a visible brown color for missing terrains
            set color = BlzConvertColor(255, 139, 90, 43)
        endif
        
        // TESTING: Force bright green to see if frames render at all
        set color = BlzConvertColor(255, 0, 255, 0)
        
        call BlzFrameSetVertexColor(this.frame, color)
        call BlzFrameSetVisible(this.frame, true)
        
        if DEBUG and I2R(newX) < 5.0 and I2R(newY) < 5.0 then
            call BJDebugMsg("Tile updated: " + I2S(newX) + "," + I2S(newY) + " color=" + I2S(color))
        endif
    endmethod
    
    method destroy takes nothing returns nothing
        set this.frame = null
        call this.deallocate()
    endmethod
endstruct

//===========================================================================
// Minimap Icon Struct
//===========================================================================
struct MinimapIcon
    unit target
    framehandle frame
    string texture
    real size
    boolean visible = false
    
    static method create takes unit whichUnit, string tex, real sz, framehandle f returns thistype
        local thistype this = thistype.allocate()
        
        set this.target = whichUnit
        set this.texture = tex
        set this.size = sz
        set this.frame = f
        
        call BlzFrameSetTexture(this.frame, tex, 0, true)
        call BlzFrameSetSize(this.frame, sz, sz)
        call BlzFrameSetVisible(this.frame, false)
        
        return this
    endmethod
    
    method updatePosition takes real camX, real camY, real worldSize returns nothing
        local real unitX
        local real unitY
        local real screenX
        local real screenY
        local real dx
        local real dy
        local real halfSize
        local boolean inRange
        
        if this.target == null or not UnitAlive(this.target) then
            if this.visible then
                set this.visible = false
                call BlzFrameSetVisible(this.frame, false)
            endif
            return
        endif
        
        set unitX = GetUnitX(this.target)
        set unitY = GetUnitY(this.target)
        set dx = unitX - camX
        set dy = unitY - camY
        set halfSize = worldSize * 0.5
        
        set inRange = dx >= -halfSize and dx <= halfSize and dy >= -halfSize and dy <= halfSize
        
        if inRange then
            set screenX = SCREEN_X + SCREEN_SIZE * 0.5 + (dx / worldSize) * SCREEN_SIZE
            set screenY = SCREEN_Y + SCREEN_SIZE * 0.5 + (dy / worldSize) * SCREEN_SIZE
            
            call BlzFrameSetAbsPoint(this.frame, FRAMEPOINT_CENTER, screenX, screenY)
            
            if not this.visible then
                set this.visible = true
                call BlzFrameSetVisible(this.frame, true)
            endif
        else
            if this.visible then
                set this.visible = false
                call BlzFrameSetVisible(this.frame, false)
            endif
        endif
    endmethod
    
    method destroy takes nothing returns nothing
        call BlzFrameSetVisible(this.frame, false)
        set this.visible = false
        set this.target = null
        call this.deallocate()
    endmethod
endstruct

//===========================================================================
// Main RPGMinimap Module
//===========================================================================
module RPGMinimap
    // Public map bounds
    private static real mapMinX
    private static real mapMinY
    private static real mapMaxX
    private static real mapMaxY
    
    // Private data
    private static timer updateTimer = CreateTimer()
    private static TerrainTile array tiles[1600]
    private static integer tileCount = 0
    private static Table iconTable = 0
    private static hashtable fogTable = InitHashtable()
    private static boolean shown = false
    private static boolean initialized = false
    private static real worldSize = 0
    
    private static real lastCamX = 0
    private static real lastCamY = 0
    private static integer lastTileX = 0
    private static integer lastTileY = 0
    
    // Periodic update
    private static method periodicUpdate takes nothing returns nothing
        local real camX = GetCameraTargetPositionX()
        local real camY = GetCameraTargetPositionY()
        local integer camTileX = R2I(camX / 128.0)
        local integer camTileY = R2I(camY / 128.0)
        local MinimapIcon icon
        local integer i
        local integer key
        
        if not thistype.shown then
            return
        endif
        
        // Update terrain if camera moved
        if camTileX != thistype.lastTileX or camTileY != thistype.lastTileY then
            set thistype.lastTileX = camTileX
            set thistype.lastTileY = camTileY
            call thistype.updateTerrain(camTileX, camTileY)
        endif
        
        // Update all icons
        set i = 0
        loop
            exitwhen i >= 8191
            if thistype.iconTable.has(i) then
                set icon = thistype.iconTable.load(i)
                if icon != 0 then
                    call icon.updatePosition(camX, camY, thistype.worldSize)
                endif
            endif
            set i = i + 1
        endloop
        
        // Auto-reveal around camera
        call thistype.revealCircle(camX, camY, 1000.0)
        
        set thistype.lastCamX = camX
        set thistype.lastCamY = camY
    endmethod
    
    // Update terrain tiles
    private static method updateTerrain takes integer camTileX, integer camTileY returns nothing
        local integer i = 0
        local integer offsetX
        local integer offsetY
        local integer worldTileX
        local integer worldTileY
        local integer halfTiles = TILES_VISIBLE / 2
        local integer fogIndex
        local boolean explored
        local TerrainTile tile
        
        set offsetX = 0
        loop
            exitwhen offsetX >= TILES_VISIBLE
            
            set offsetY = 0
            loop
                exitwhen offsetY >= TILES_VISIBLE
                
                set worldTileX = camTileX - halfTiles + offsetX
                set worldTileY = camTileY - halfTiles + offsetY
                
                set fogIndex = worldTileX * MAX_MAP_TILES + worldTileY
                set explored = LoadBoolean(thistype.fogTable, fogIndex, 0)
                
                set tile = thistype.tiles[i]
                call tile.updateTile(worldTileX, worldTileY, explored)
                
                set i = i + 1
                set offsetY = offsetY + 1
            endloop
            
            set offsetX = offsetX + 1
        endloop
    endmethod
    
    // Auto-register heroes
    private static method onUnitEnter takes nothing returns boolean
        local unit u = GetTriggerUnit()
        
        if IsUnitType(u, UNIT_TYPE_HERO) then
            call thistype.registerIcon(u, "UI\\Minimap\\MinimapIcon.blp", 0.01)
        endif
        
        set u = null
        return false
    endmethod
    
    // Public API
    static method registerIcon takes unit whichUnit, string texture, real size returns MinimapIcon
        local integer key = GetHandleId(whichUnit)
        local MinimapIcon icon
        local framehandle f
        
        if thistype.iconTable.has(key) then
            set icon = thistype.iconTable.load(key)
            set icon.texture = texture
            set icon.size = size
            call BlzFrameSetTexture(icon.frame, texture, 0, true)
            call BlzFrameSetSize(icon.frame, size, size)
        else
            set f = BlzCreateFrame("BACKDROP", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
            set icon = MinimapIcon.create(whichUnit, texture, size, f)
            call thistype.iconTable.store(key, icon)
        endif
        
        return icon
    endmethod
    
    static method removeIcon takes unit whichUnit returns nothing
        local integer key = GetHandleId(whichUnit)
        local MinimapIcon icon
        
        if thistype.iconTable.has(key) then
            set icon = thistype.iconTable.load(key)
            call icon.destroy()
            call thistype.iconTable.remove(key)
        endif
    endmethod
    
    static method revealCircle takes real x, real y, real radius returns nothing
        local integer centerX = R2I(x / 128.0)
        local integer centerY = R2I(y / 128.0)
        local integer rad = R2I(radius / 128.0) + 1
        local integer tileX
        local integer tileY
        local integer dx
        local integer dy
        local integer index
        
        set tileX = centerX - rad
        loop
            exitwhen tileX > centerX + rad
            
            set tileY = centerY - rad
            loop
                exitwhen tileY > centerY + rad
                
                set dx = tileX - centerX
                set dy = tileY - centerY
                
                if dx * dx + dy * dy <= rad * rad then
                    if tileX >= 0 and tileX < MAX_MAP_TILES and tileY >= 0 and tileY < MAX_MAP_TILES then
                        set index = tileX * MAX_MAP_TILES + tileY
                        call SaveBoolean(thistype.fogTable, index, 0, true)
                    endif
                endif
                
                set tileY = tileY + 1
            endloop
            
            set tileX = tileX + 1
        endloop
    endmethod
    
    static method revealRect takes real minX, real minY, real maxX, real maxY returns nothing
        local integer tileMinX = R2I(minX / 128.0)
        local integer tileMinY = R2I(minY / 128.0)
        local integer tileMaxX = R2I(maxX / 128.0)
        local integer tileMaxY = R2I(maxY / 128.0)
        local integer tileX
        local integer tileY
        local integer index
        
        set tileX = tileMinX
        loop
            exitwhen tileX > tileMaxX
            
            set tileY = tileMinY
            loop
                exitwhen tileY > tileMaxY
                
                if tileX >= 0 and tileX < MAX_MAP_TILES and tileY >= 0 and tileY < MAX_MAP_TILES then
                    set index = tileX * MAX_MAP_TILES + tileY
                    call SaveBoolean(thistype.fogTable, index, 0, true)
                endif
                
                set tileY = tileY + 1
            endloop
            
            set tileX = tileX + 1
        endloop
    endmethod
    
    static method show takes boolean enable returns nothing
        local integer i
        local TerrainTile tile
        
        set thistype.shown = enable
        
        set i = 0
        loop
            exitwhen i >= thistype.tileCount
            set tile = thistype.tiles[i]
            call BlzFrameSetVisible(tile.frame, enable)
            set i = i + 1
        endloop
        
        if DEBUG then
            if enable then
                call BJDebugMsg("RPGMinimap shown")
            else
                call BJDebugMsg("RPGMinimap hidden")
            endif
        endif
    endmethod
    
    static method init takes nothing returns nothing
        local integer i = 0
        local integer row
        local integer col
        local framehandle frame
        local framehandle parent = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        local real tileSize = SCREEN_SIZE / I2R(TILES_VISIBLE)
        local real posX
        local real posY
        local trigger t
        
        // Hide default minimap
        call BlzFrameSetVisible(BlzGetFrameByName("MiniMapFrame", 0), false)
        call BlzFrameSetVisible(BlzGetFrameByName("MinimapFrame", 0), false)
        
        // Store map bounds
        set thistype.mapMinX = GetRectMinX(bj_mapInitialPlayableArea)
        set thistype.mapMinY = GetRectMinY(bj_mapInitialPlayableArea)
        set thistype.mapMaxX = GetRectMaxX(bj_mapInitialPlayableArea)
        set thistype.mapMaxY = GetRectMaxY(bj_mapInitialPlayableArea)
        set thistype.worldSize = I2R(TILES_VISIBLE) * 128.0
        
        // Initialize icon table
        set thistype.iconTable = Table.create()
        
        // Create terrain tiles
        loop
            exitwhen i >= TILES_VISIBLE * TILES_VISIBLE
            
            set row = i / TILES_VISIBLE
            set col = i - (row * TILES_VISIBLE)
            
            set frame = BlzCreateSimpleFrame("SimpleStatusBarTemplate", parent, 0)
            call BlzFrameSetSize(frame, tileSize, tileSize)
            
            set posX = SCREEN_X + I2R(col) * tileSize
            set posY = SCREEN_Y + I2R(row) * tileSize
            call BlzFrameSetAbsPoint(frame, FRAMEPOINT_BOTTOMLEFT, posX, posY)
            call BlzFrameSetLevel(frame, 1)
            call BlzFrameSetVisible(frame, true)
            
            set thistype.tiles[i] = TerrainTile.create(frame, thistype.mapMinX, thistype.mapMinY, thistype.mapMaxX, thistype.mapMaxY)
            set i = i + 1
        endloop
        
        set thistype.tileCount = i
        
        // Setup auto-registration for heroes
        set t = CreateTrigger()
        call TriggerRegisterEnterRectSimple(t, bj_mapInitialPlayableArea)
        call TriggerAddCondition(t, Filter(function thistype.onUnitEnter))
        
        // Start update timer
        call TimerStart(thistype.updateTimer, UPDATE_INTERVAL, true, function thistype.periodicUpdate)
        
        set thistype.initialized = true
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00RPGMinimap initialized|r")
        endif
        
        // Initial terrain update - reveal fog first!
        set thistype.lastCamX = GetCameraTargetPositionX()
        set thistype.lastCamY = GetCameraTargetPositionY()
        set thistype.lastTileX = R2I(thistype.lastCamX / 128.0)
        set thistype.lastTileY = R2I(thistype.lastCamY / 128.0)
        call thistype.revealCircle(thistype.lastCamX, thistype.lastCamY, 1000.0)
        call thistype.updateTerrain(thistype.lastTileX, thistype.lastTileY)
        
        // Show minimap by default
        call thistype.show(true)
        
        set parent = null
        set frame = null
        set t = null
    endmethod
endmodule

//===========================================================================
// Wrapper struct to apply module
//===========================================================================
struct RPGMinimapImpl
    implement RPGMinimap
endstruct

//===========================================================================
// Public API Functions
//===========================================================================
function RPGMinimap_RegisterIcon takes unit whichUnit, string texture, real size returns nothing
    call RPGMinimapImpl.registerIcon(whichUnit, texture, size)
endfunction

function RPGMinimap_RemoveIcon takes unit whichUnit returns nothing
    call RPGMinimapImpl.removeIcon(whichUnit)
endfunction

function RPGMinimap_RevealCircle takes real x, real y, real radius returns nothing
    call RPGMinimapImpl.revealCircle(x, y, radius)
endfunction

function RPGMinimap_RevealRect takes real minX, real minY, real maxX, real maxY returns nothing
    call RPGMinimapImpl.revealRect(minX, minY, maxX, maxY)
endfunction

function RPGMinimap_Show takes boolean enable returns nothing
    call RPGMinimapImpl.show(enable)
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function Init takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("|cffFFFF00RPGMinimap: Starting initialization...|r")
    endif
    
    call RPGMinimapImpl.init()
endfunction

endlibrary
