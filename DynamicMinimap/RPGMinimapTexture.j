library RPGMinimapTexture initializer Init requires optional TerrainTextureColors
//===========================================================================
/*
    RPG Minimap - Dynamic Texture & Camera Bounds
    
    Uses:
    - BlzChangeMinimapTerrainTex to swap minimap texture chunks
    - SetCameraBoundsToRect to constrain camera to the visible chunk area
    
    This creates a scrolling RPG-style minimap that updates both the texture
    and camera bounds dynamically as the player moves.
    
    Features:
    - Dynamic minimap texture swapping based on camera position
    - Camera bounds automatically adjusted to match visible chunk
    - Seamless transition between chunks
    - Works with 256x256 minimap chunks
    
    Requirements:
    - Pre-rendered minimap textures in war3mapImported\ (256x256 px each)
    - Generated using minimap_texture_chunker.py
    
    API:
        RPGMinimapTexture_SetChunkSize(tiles) - Set chunk size (default 32)
        RPGMinimapTexture_SetGridStep(tiles) - Set grid step between chunks (default 8)
        RPGMinimapTexture_Enable(enable) - Enable/disable dynamic updates
        RPGMinimapTexture_ForceUpdate() - Manually trigger update
*/
//===========================================================================

globals
    private constant boolean DEBUG = true
    private constant real UPDATE_INTERVAL = 0.1  // How often to check for updates
    private constant integer DEFAULT_CHUNK_SIZE = 32   // 32x32 tiles per chunk
    private constant integer DEFAULT_GRID_STEP = 8     // Grid alignment (8 tiles)
    private constant real BOUNDS_PADDING_MULTIPLIER = 2.0  // Camera bounds = chunk size * this
    private constant integer MAP_SIZE_TILES = 480  // Actual WC3 map size in tiles
    private constant integer CHUNK_COORDINATE_SYSTEM = 256  // Chunk files use 256-tile coordinate system
    
    private timer updateTimer = null
    private integer currentChunkSize = DEFAULT_CHUNK_SIZE
    private integer currentGridStep = DEFAULT_GRID_STEP
    private boolean enabled = true
    
    private integer lastTileX = -1
    private integer lastTileY = -1
    private rect currentBoundsRect = null
    
    // Track unit instead of camera to avoid feedback loop
    private unit trackedUnit = null
    
    // Texture cache - format: minimap_X_Y_ZOOM.blp
    private constant string TEXTURE_PREFIX = "war3mapImported\\minimap_"
    private constant string TEXTURE_SUFFIX = ".blp"
    
    // Minimap toggle functionality
    private framehandle minimapFrame = null
    private boolean minimapEnlarged = false
    private real enlargedPosX = 0.4  // Center X (0.0 = left, 1.0 = right)
    private real enlargedPosY = 0.3  // Center Y (0.0 = bottom, 1.0 = top)
    private real enlargedScale = 3.0  // Scale multiplier
    private real normalPosX = 0.009  // Normal minimap X position (BOTTOMLEFT)
    private real normalPosY = 0.008  // Normal minimap Y position (BOTTOMLEFT)
    private real normalScale = 1.0   // Default minimap scale
    private trigger toggleTrigger = null
    private oskeytype toggleKey = OSKEY_ESCAPE  // Default to ESC key
endglobals

//===========================================================================
// Helper Functions
//===========================================================================
private function GetMinimapTexturePath takes integer tileX, integer tileY, integer chunkSize returns string
    // Generate texture path based on position
    // Example: "war3mapImported\\minimap_0_0_32.blp"
    return TEXTURE_PREFIX + I2S(tileX) + "_" + I2S(tileY) + "_" + I2S(chunkSize) + TEXTURE_SUFFIX
endfunction

private function UpdateMinimapAndBounds takes integer chunkCoordX, integer chunkCoordY, integer actualMapTileX, integer actualMapTileY returns nothing
    local string texturePath
    local real minX
    local real minY
    local real maxX
    local real maxY
    local real centerX
    local real centerY
    local real boundsSize
    local real mapMinX = GetRectMinX(bj_mapInitialPlayableArea)
    local real mapMinY = GetRectMinY(bj_mapInitialPlayableArea)
    
    // Only update if position changed
    if chunkCoordX == lastTileX and chunkCoordY == lastTileY then
        return
    endif
    
    set lastTileX = chunkCoordX
    set lastTileY = chunkCoordY
    
    // Change minimap texture using chunk coordinates (256-tile system)
    set texturePath = GetMinimapTexturePath(chunkCoordX, chunkCoordY, currentChunkSize)
    call BlzChangeMinimapTerrainTex(texturePath)
    
    // Calculate center using ACTUAL map tiles (480-tile system) for proper world coordinates
    set centerX = mapMinX + (actualMapTileX * 128.0) + (currentChunkSize * 64.0)
    set centerY = mapMinY + (actualMapTileY * 128.0) + (currentChunkSize * 64.0)
    
    // Camera bounds are LARGER than minimap chunk (with padding)
    // This allows camera to move freely and trigger next update
    set boundsSize = currentChunkSize * 128.0 * BOUNDS_PADDING_MULTIPLIER / 2.0
    set minX = centerX - boundsSize
    set minY = centerY - boundsSize
    set maxX = centerX + boundsSize
    set maxY = centerY + boundsSize
    
    // Create/update camera bounds rect
    if currentBoundsRect == null then
        set currentBoundsRect = Rect(minX, minY, maxX, maxY)
    else
        call SetRect(currentBoundsRect, minX, minY, maxX, maxY)
    endif
    
    // Apply camera bounds to region
    call SetCameraBoundsToRect(currentBoundsRect)
    
    if DEBUG then
        call BJDebugMsg("Minimap chunk: " + texturePath)
        call BJDebugMsg("Actual map tiles: " + I2S(actualMapTileX) + "," + I2S(actualMapTileY))
        call BJDebugMsg("Camera bounds: " + R2S(boundsSize * 2.0 / 128.0) + "x" + R2S(boundsSize * 2.0 / 128.0) + " tiles")
    endif
endfunction

//===========================================================================
// Periodic Update
//===========================================================================
private function PeriodicUpdate takes nothing returns nothing
    local real unitX
    local real unitY
    local integer unitTileX
    local integer unitTileY
    local integer chunkCoordX
    local integer chunkCoordY
    local real mapMinX = GetRectMinX(bj_mapInitialPlayableArea)
    local real mapMinY = GetRectMinY(bj_mapInitialPlayableArea)
    local real scaleFactor = I2R(CHUNK_COORDINATE_SYSTEM) / I2R(MAP_SIZE_TILES)
    
    if not enabled then
        return
    endif
    
    // Get tracked unit position (or camera as fallback)
    if trackedUnit != null and GetUnitTypeId(trackedUnit) != 0 then
        set unitX = GetUnitX(trackedUnit)
        set unitY = GetUnitY(trackedUnit)
    else
        // Fallback to camera position if no unit tracked
        set unitX = GetCameraTargetPositionX()
        set unitY = GetCameraTargetPositionY()
    endif
    
    // Convert to tile coordinates in actual map (0-based, each tile = 128 units)
    set unitTileX = R2I((unitX - mapMinX) / 128.0)
    set unitTileY = R2I((unitY - mapMinY) / 128.0)
    
    // Center the chunk on the unit (offset by half chunk size)
    set unitTileX = unitTileX - (currentChunkSize / 2)
    set unitTileY = unitTileY - (currentChunkSize / 2)
    
    // Scale to chunk coordinate system (256-tile system for chunk filenames)
    // Example: tile 240 in 480-tile map = tile 128 in 256-tile chunk system
    set chunkCoordX = R2I(I2R(unitTileX) * scaleFactor)
    set chunkCoordY = R2I(I2R(unitTileY) * scaleFactor)
    
    // Snap to grid alignment
    set chunkCoordX = (chunkCoordX / currentGridStep) * currentGridStep
    set chunkCoordY = (chunkCoordY / currentGridStep) * currentGridStep
    
    // Clamp to valid range in chunk coordinate system (0 to 224 for 256-tile chunks)
    if chunkCoordX < 0 then
        set chunkCoordX = 0
    elseif chunkCoordX > CHUNK_COORDINATE_SYSTEM - currentChunkSize then
        set chunkCoordX = CHUNK_COORDINATE_SYSTEM - currentChunkSize
    endif
    
    if chunkCoordY < 0 then
        set chunkCoordY = 0
    elseif chunkCoordY > CHUNK_COORDINATE_SYSTEM - currentChunkSize then
        set chunkCoordY = CHUNK_COORDINATE_SYSTEM - currentChunkSize
    endif
    
    // Also clamp actual tile coordinates for camera bounds
    if unitTileX < 0 then
        set unitTileX = 0
    elseif unitTileX > MAP_SIZE_TILES - currentChunkSize then
        set unitTileX = MAP_SIZE_TILES - currentChunkSize
    endif
    
    if unitTileY < 0 then
        set unitTileY = 0
    elseif unitTileY > MAP_SIZE_TILES - currentChunkSize then
        set unitTileY = MAP_SIZE_TILES - currentChunkSize
    endif
    
    // Update minimap texture and camera bounds if moved to new chunk
    call UpdateMinimapAndBounds(chunkCoordX, chunkCoordY, unitTileX, unitTileY)
endfunction

//===========================================================================
// Public API
//===========================================================================
function RPGMinimapTexture_SetChunkSize takes integer tiles returns nothing
    set currentChunkSize = tiles
    set lastTileX = -1 // Force update
    set lastTileY = -1
    
    if DEBUG then
        call BJDebugMsg("Minimap chunk size set to: " + I2S(tiles) + "x" + I2S(tiles) + " tiles")
    endif
endfunction

function RPGMinimapTexture_SetGridStep takes integer tiles returns nothing
    set currentGridStep = tiles
    
    if DEBUG then
        call BJDebugMsg("Minimap grid step set to: " + I2S(tiles) + " tiles")
    endif
endfunction

function RPGMinimapTexture_Enable takes boolean enable returns nothing
    set enabled = enable
    
    if DEBUG then
        if enable then
            call BJDebugMsg("RPGMinimapTexture: Enabled")
        else
            call BJDebugMsg("RPGMinimapTexture: Disabled")
        endif
    endif
endfunction

function RPGMinimapTexture_ForceUpdate takes nothing returns nothing
    set lastTileX = -1
    set lastTileY = -1
    call PeriodicUpdate()
endfunction

function RPGMinimapTexture_SetTrackedUnit takes unit whichUnit returns nothing
    set trackedUnit = whichUnit
    set lastTileX = -1
    set lastTileY = -1
    
    if DEBUG then
        if whichUnit != null then
            call BJDebugMsg("RPGMinimapTexture: Now tracking " + GetUnitName(whichUnit))
        else
            call BJDebugMsg("RPGMinimapTexture: Tracking cleared (using camera)")
        endif
    endif
endfunction

//===========================================================================
// Minimap Toggle Functions
//===========================================================================
private function ToggleMinimap takes nothing returns nothing
    if minimapFrame == null then
        return
    endif
    
    if minimapEnlarged then
        // Restore to normal - clear all points first, then set back to bottom left
        call BlzFrameClearAllPoints(minimapFrame)
        call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, normalPosX, normalPosY)
        call BlzFrameSetScale(minimapFrame, normalScale)
        set minimapEnlarged = false
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap: Restored to normal|r")
        endif
    else
        // Enlarge and center - clear all points first, then set to center
        call BlzFrameClearAllPoints(minimapFrame)
        call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_CENTER, enlargedPosX, enlargedPosY)
        call BlzFrameSetScale(minimapFrame, enlargedScale)
        set minimapEnlarged = true
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap: Enlarged (" + R2S(enlargedScale) + "x) at (" + R2S(enlargedPosX) + ", " + R2S(enlargedPosY) + ")|r")
        endif
    endif
    
    // Force minimap texture update
    call RPGMinimapTexture_ForceUpdate()
endfunction

private function OnToggleKey takes nothing returns boolean
    if GetTriggerPlayer() == GetLocalPlayer() then
        call ToggleMinimap()
    endif
    return false
endfunction

function RPGMinimapTexture_SetEnlargedPosition takes real x, real y returns nothing
    set enlargedPosX = x
    set enlargedPosY = y
    
    if DEBUG then
        call BJDebugMsg("Minimap enlarged position set to: (" + R2S(x) + ", " + R2S(y) + ")")
    endif
endfunction

function RPGMinimapTexture_SetEnlargedScale takes real scale returns nothing
    set enlargedScale = scale
    
    if DEBUG then
        call BJDebugMsg("Minimap enlarged scale set to: " + R2S(scale) + "x")
    endif
endfunction

function RPGMinimapTexture_SetToggleKey takes oskeytype oskeyCode returns nothing
    // Remove old trigger
    if toggleTrigger != null then
        call DestroyTrigger(toggleTrigger)
    endif
    
    // Create new trigger with specified key
    set toggleKey = oskeyCode
    set toggleTrigger = CreateTrigger()
    call BlzTriggerRegisterPlayerKeyEvent(toggleTrigger, Player(0), toggleKey, 0, false)
    call TriggerAddCondition(toggleTrigger, Condition(function OnToggleKey))
    
    if DEBUG then
        call BJDebugMsg("Minimap toggle key set to specified OSKEY")
    endif
endfunction

function RPGMinimapTexture_GetMinimapEnlarged takes nothing returns boolean
    return minimapEnlarged
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function Init takes nothing returns nothing
    local real mapMinX = GetRectMinX(bj_mapInitialPlayableArea)
    local real mapMinY = GetRectMinY(bj_mapInitialPlayableArea)
    local real startX
    local real startY
    local integer startTileX
    local integer startTileY
    local group g
    
    if DEBUG then
        call BJDebugMsg("|cffFFFF00RPGMinimapTexture: Starting initialization...|r")
    endif
    
    // Try to find player 1's hero to track
    set g = CreateGroup()
    call GroupEnumUnitsOfPlayer(g, Player(0), null)
    loop
        set trackedUnit = FirstOfGroup(g)
        exitwhen trackedUnit == null
        if IsUnitType(trackedUnit, UNIT_TYPE_HERO) then
            exitwhen true
        endif
        call GroupRemoveUnit(g, trackedUnit)
        set trackedUnit = null
    endloop
    call DestroyGroup(g)
    set g = null
    
    // Get initial position (unit or camera)
    if trackedUnit != null then
        set startX = GetUnitX(trackedUnit)
        set startY = GetUnitY(trackedUnit)
        if DEBUG then
            call BJDebugMsg("|cff00ff00Found hero to track: " + GetUnitName(trackedUnit) + "|r")
        endif
    else
        set startX = GetCameraTargetPositionX()
        set startY = GetCameraTargetPositionY()
        if DEBUG then
            call BJDebugMsg("|cffFFFF00No hero found, tracking camera position|r")
        endif
    endif
    
    set startTileX = R2I((startX - mapMinX) / 128.0) - (currentChunkSize / 2)
    set startTileY = R2I((startY - mapMinY) / 128.0) - (currentChunkSize / 2)
    
    // Clamp actual tile coordinates
    if startTileX < 0 then
        set startTileX = 0
    elseif startTileX > MAP_SIZE_TILES - currentChunkSize then
        set startTileX = MAP_SIZE_TILES - currentChunkSize
    endif
    if startTileY < 0 then
        set startTileY = 0
    elseif startTileY > MAP_SIZE_TILES - currentChunkSize then
        set startTileY = MAP_SIZE_TILES - currentChunkSize
    endif
    
    // Convert to chunk coordinates for texture lookup
    set startTileX = R2I(I2R(startTileX) * I2R(CHUNK_COORDINATE_SYSTEM) / I2R(MAP_SIZE_TILES))
    set startTileY = R2I(I2R(startTileY) * I2R(CHUNK_COORDINATE_SYSTEM) / I2R(MAP_SIZE_TILES))
    
    // Snap to grid
    set startTileX = (startTileX / currentGridStep) * currentGridStep
    set startTileY = (startTileY / currentGridStep) * currentGridStep
    
    if startTileX < 0 then
        set startTileX = 0
    endif
    if startTileY < 0 then
        set startTileY = 0
    endif
    
    // Get minimap frame and store normal position/scale
    set minimapFrame = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    if minimapFrame != null then
        // Use default values since we can't retrieve current frame position/scale
        // normalPosX, normalPosY, and normalScale already set to defaults in globals
        
        // Set up toggle trigger for local player
        set toggleTrigger = CreateTrigger()
        call BlzTriggerRegisterPlayerKeyEvent(toggleTrigger, Player(0), toggleKey, 0, false)
        call TriggerAddCondition(toggleTrigger, Condition(function OnToggleKey))
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap toggle: Enabled (ESC key)|r")
            call BJDebugMsg("|cffAAAAFFNormal pos: (" + R2S(normalPosX) + ", " + R2S(normalPosY) + "), scale: " + R2S(normalScale) + "|r")
        endif
    else
        if DEBUG then
            call BJDebugMsg("|cffFF0000Minimap toggle: Failed to get minimap frame|r")
        endif
    endif
    
    // Start update timer
    set updateTimer = CreateTimer()
    call TimerStart(updateTimer, UPDATE_INTERVAL, true, function PeriodicUpdate)
    
    // Set initial minimap texture and camera bounds
    call UpdateMinimapAndBounds(startTileX, startTileY, R2I((startX - mapMinX) / 128.0) - (currentChunkSize / 2), R2I((startY - mapMinY) / 128.0) - (currentChunkSize / 2))
    
    if DEBUG then
        call BJDebugMsg("|cff00ff00RPGMinimapTexture: Initialized|r")
        call BJDebugMsg("|cffAAAAFFChunk size: " + I2S(currentChunkSize) + "x" + I2S(currentChunkSize) + " tiles|r")
        call BJDebugMsg("|cffAAAAFFGrid step: " + I2S(currentGridStep) + " tiles|r")
    endif
endfunction

endlibrary
