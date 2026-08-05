library DynamicMinimapTesting initializer Init
//===========================================================================
/*
    DynamicMinimapTesting - Minimal version for crash testing
    Based on DynamicMinimap_06_640PM.j (working baseline)
*/
//===========================================================================

globals
    // Configuration
    private constant boolean DEBUG = true
    private constant real UPDATE_INTERVAL = 0.1
    private constant integer DEFAULT_CHUNK_SIZE = 32
    private constant integer DEFAULT_GRID_STEP = 8
    private constant real BOUNDS_PADDING_MULTIPLIER = 2.0    
    private constant real MIN_BOUNDS_SIZE = 3072.0  // Minimum camera bounds size (in game units)    
    // Camera rotation safety (danger zone: 220-320 degrees causes crashes with SetCameraBounds)
    // GetCameraField returns RADIANS, so convert degrees to radians
    private constant real SAFE_ROTATION_MIN = 3.84  // 220 degrees in radians
    private constant real SAFE_ROTATION_MAX = 5.59  // 320 degrees in radians
    
    private constant integer MAP_SIZE_TILES = 480
    private constant integer CHUNK_COORDINATE_SYSTEM = 256

    // Texture paths
    private constant string TEXTURE_PREFIX = "war3mapImported\\minimap_"
    private constant string TEXTURE_SUFFIX = ".blp"
    private constant string FULL_MAP_TEXTURE = "war3mapImported\\minimap_full.blp"

    // Map mode toggle configuration
    private constant boolean ENABLE_MODE_TOGGLE = true
    private constant oskeytype MODE_TOGGLE_KEY = OSKEY_N

    // State
    private timer updateTimer = null
    private integer currentChunkSize = DEFAULT_CHUNK_SIZE
    private integer currentGridStep = DEFAULT_GRID_STEP
    private boolean fullMapMode = false
    private integer lastTileX = -1
    private integer lastTileY = -1
    private rect currentBoundsRect = null
    private rect originalCameraBounds = null
    
    // Cached map bounds (calculated once at init)
    private real cachedMapMinX = 0.0
    private real cachedMapMinY = 0.0
    private real cachedMapMaxX = 0.0
    private real cachedMapMaxY = 0.0
    
    // Map mode toggle functionality
    private trigger modeToggleTrigger = null
    private timer modeSwitchDelayTimer = null

endglobals

//===========================================================================
// Helper Functions
//===========================================================================
private function GetMinimapTexturePath takes integer tileX, integer tileY, integer chunkSize returns string
    return TEXTURE_PREFIX + I2S(tileX) + "_" + I2S(tileY) + "_" + I2S(chunkSize) + TEXTURE_SUFFIX
endfunction

// Check if camera rotation is safe for SetCameraBounds
// Returns true if safe, false if in danger zone (220-320 degrees)
private function IsCameraRotationSafe takes nothing returns boolean
    local real rotation = GetCameraField(CAMERA_FIELD_ROTATION)  // Returns radians
    
    // Normalize rotation to 0-2π range
    loop
        exitwhen rotation >= 0.0
        set rotation = rotation + 6.28318  // Add 2π
    endloop
    loop
        exitwhen rotation < 6.28318
        set rotation = rotation - 6.28318  // Subtract 2π
    endloop
    
    // Check if in danger zone (220-320 degrees = 3.84-5.59 radians)
    if rotation >= SAFE_ROTATION_MIN and rotation <= SAFE_ROTATION_MAX then
        return false  // DANGER ZONE - do not call SetCameraBounds!
    endif
    
    return true  // Safe to call SetCameraBounds
endfunction

private function UpdateMinimapAndBounds takes integer chunkCoordX, integer chunkCoordY returns nothing
    local string texturePath
    local real centerX
    local real centerY
    local real boundsSize
    local real actualChunkSizeInMapTiles
    local real scaleFactor = I2R(MAP_SIZE_TILES) / I2R(CHUNK_COORDINATE_SYSTEM)
    local real minX
    local real minY
    local real maxX
    local real maxY
    
    // Only update if position changed
    if chunkCoordX == lastTileX and chunkCoordY == lastTileY then
        return
    endif
    
    set lastTileX = chunkCoordX
    set lastTileY = chunkCoordY
    
    // Change minimap texture
    set texturePath = GetMinimapTexturePath(chunkCoordX, chunkCoordY, currentChunkSize)
    call BlzChangeMinimapTerrainTex(texturePath)
    
    // Calculate chunk size in map tiles
    set actualChunkSizeInMapTiles = I2R(currentChunkSize) * scaleFactor
    
    // Calculate center coordinates
    set centerX = cachedMapMinX + (I2R(chunkCoordX) * scaleFactor * 128.0) + (actualChunkSizeInMapTiles * 128.0 / 2.0)
    set centerY = cachedMapMinY + (I2R(chunkCoordY) * scaleFactor * 128.0) + (actualChunkSizeInMapTiles * 128.0 / 2.0)
    
    // Calculate bounds with padding
    set boundsSize = actualChunkSizeInMapTiles * 128.0 * BOUNDS_PADDING_MULTIPLIER / 2.0
    
    // Calculate bounds coordinates
    set minX = centerX - boundsSize
    set minY = centerY - boundsSize
    set maxX = centerX + boundsSize
    set maxY = centerY + boundsSize
    
    // Clamp bounds to playable area to prevent out-of-bounds issues
    if minX < cachedMapMinX then
        set minX = cachedMapMinX
    endif
    if minY < cachedMapMinY then
        set minY = cachedMapMinY
    endif
    if maxX > cachedMapMaxX then
        set maxX = cachedMapMaxX
    endif
    if maxY > cachedMapMaxY then
        set maxY = cachedMapMaxY
    endif
    
    // Validate bounds are not degenerate
    if maxX <= minX or maxY <= minY then
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "ERROR: Invalid camera bounds calculated")
        endif
        return
    endif
    
    // Ensure minimum bounds size to prevent overly restrictive camera
    if (maxX - minX) < MIN_BOUNDS_SIZE then
        set centerX = (minX + maxX) / 2.0
        set minX = centerX - (MIN_BOUNDS_SIZE / 2.0)
        set maxX = centerX + (MIN_BOUNDS_SIZE / 2.0)
        // Re-clamp after expansion
        if minX < cachedMapMinX then
            set minX = cachedMapMinX
            set maxX = minX + MIN_BOUNDS_SIZE
        endif
        if maxX > cachedMapMaxX then
            set maxX = cachedMapMaxX
            set minX = maxX - MIN_BOUNDS_SIZE
        endif
    endif
    
    if (maxY - minY) < MIN_BOUNDS_SIZE then
        set centerY = (minY + maxY) / 2.0
        set minY = centerY - (MIN_BOUNDS_SIZE / 2.0)
        set maxY = centerY + (MIN_BOUNDS_SIZE / 2.0)
        // Re-clamp after expansion
        if minY < cachedMapMinY then
            set minY = cachedMapMinY
            set maxY = minY + MIN_BOUNDS_SIZE
        endif
        if maxY > cachedMapMaxY then
            set maxY = cachedMapMaxY
            set minY = maxY - MIN_BOUNDS_SIZE
        endif
    endif
    
    // Final validation
    if maxX <= minX or maxY <= minY then
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "ERROR: Invalid bounds after minimum size enforcement")
        endif
        return
    endif
    
    if DEBUG then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Bounds update: (" + R2S(minX) + "," + R2S(minY) + ") to (" + R2S(maxX) + "," + R2S(maxY) + ")")
    endif
    
    // CRITICAL: Check camera rotation before setting bounds to prevent crashes
    if not IsCameraRotationSafe() then
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "WARNING: Camera rotation unsafe - skipping bounds update")
        endif
        return
    endif
    
    // Create/update camera bounds rect
    if currentBoundsRect == null then
        set currentBoundsRect = Rect(minX, minY, maxX, maxY)
    else
        call SetRect(currentBoundsRect, minX, minY, maxX, maxY)
    endif
    
    // Apply camera bounds (only if rotation is safe)
    call SetCameraBoundsToRect(currentBoundsRect)
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
    local real scaleFactor = I2R(CHUNK_COORDINATE_SYSTEM) / I2R(MAP_SIZE_TILES)
    
    if fullMapMode then
        return
    endif
    
    // Get camera position
    set unitX = GetCameraTargetPositionX()
    set unitY = GetCameraTargetPositionY()
    
    // Convert to tile coordinates
    set unitTileX = R2I((unitX - cachedMapMinX) / 128.0)
    set unitTileY = R2I((unitY - cachedMapMinY) / 128.0)
    
    // Center chunk on position
    set unitTileX = unitTileX - (currentChunkSize / 2)
    set unitTileY = unitTileY - (currentChunkSize / 2)
    
    // Scale to chunk coordinate system
    set chunkCoordX = R2I(I2R(unitTileX) * scaleFactor)
    set chunkCoordY = R2I(I2R(unitTileY) * scaleFactor)
    
    // Snap to grid
    set chunkCoordX = (chunkCoordX / currentGridStep) * currentGridStep
    set chunkCoordY = (chunkCoordY / currentGridStep) * currentGridStep
    
    // Clamp to valid range
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
    
    // Update
    call UpdateMinimapAndBounds(chunkCoordX, chunkCoordY)
endfunction

//===========================================================================
// Public API
//===========================================================================
private function DelayedChunkedModeSwitch takes nothing returns nothing
    set fullMapMode = false
    set lastTileX = -1
    set lastTileY = -1
endfunction

function DynamicMinimapTesting_SetFullMapMode takes boolean enable returns nothing
    local real minX
    local real minY
    local real maxX
    local real maxY
    
    if enable then
        // Switching TO full map mode
        set fullMapMode = true
        
        // Apply full map texture FIRST
        call BlzChangeMinimapTerrainTex(FULL_MAP_TEXTURE)
        
        // Then restore camera bounds
        if originalCameraBounds != null then
            set minX = GetRectMinX(originalCameraBounds)
            set minY = GetRectMinY(originalCameraBounds)
            set maxX = GetRectMaxX(originalCameraBounds)
            set maxY = GetRectMaxY(originalCameraBounds)
            
            // Validate rect is not degenerate and rotation is safe
            if maxX > minX and maxY > minY and IsCameraRotationSafe() then
                call SetCameraBoundsToRect(originalCameraBounds)
            endif
        endif
    else
        // Switching TO chunked mode - add small delay for camera adjustment
        if modeSwitchDelayTimer == null then
            set modeSwitchDelayTimer = CreateTimer()
        endif
        call TimerStart(modeSwitchDelayTimer, 0.5, false, function DelayedChunkedModeSwitch)
    endif
endfunction

function DynamicMinimapTesting_GetCurrentMode takes nothing returns boolean
    return fullMapMode
endfunction

function DynamicMinimapTesting_ForceUpdate takes nothing returns nothing
    // Only force update if in chunked mode
    if not fullMapMode then
        set lastTileX = -1
        set lastTileY = -1
        // Let next timer tick handle the update
    endif
endfunction

//===========================================================================
// Map Mode Toggle Functions
//===========================================================================
private function ToggleMapMode takes nothing returns nothing
    call DynamicMinimapTesting_SetFullMapMode(not fullMapMode)
endfunction

private function OnModeToggleKey takes nothing returns boolean
    if GetTriggerPlayer() == GetLocalPlayer() then
        call ToggleMapMode()
    endif
    return false
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function Init takes nothing returns nothing
    local real startX
    local real startY
    local integer startTileX
    local integer startTileY
    
    // Cache map bounds once at initialization for performance
    set cachedMapMinX = GetRectMinX(bj_mapInitialPlayableArea)
    set cachedMapMinY = GetRectMinY(bj_mapInitialPlayableArea)
    set cachedMapMaxX = GetRectMaxX(bj_mapInitialPlayableArea)
    set cachedMapMaxY = GetRectMaxY(bj_mapInitialPlayableArea)
    
    // Store original camera bounds (use bj_mapInitialPlayableArea directly)
    set originalCameraBounds = bj_mapInitialPlayableArea
    
    // Get initial camera position
    set startX = GetCameraTargetPositionX()
    set startY = GetCameraTargetPositionY()
    
    // Calculate initial chunk
    set startTileX = R2I((startX - cachedMapMinX) / 128.0) - (currentChunkSize / 2)
    set startTileY = R2I((startY - cachedMapMinY) / 128.0) - (currentChunkSize / 2)
    
    // Clamp and convert to chunk coordinates
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
    
    // Set up map mode toggle trigger if enabled
    if ENABLE_MODE_TOGGLE then
        set modeToggleTrigger = CreateTrigger()
        call BlzTriggerRegisterPlayerKeyEvent(modeToggleTrigger, Player(0), MODE_TOGGLE_KEY, 0, false)
        call TriggerAddCondition(modeToggleTrigger, Condition(function OnModeToggleKey))
    endif
    
    // Start update timer
    set updateTimer = CreateTimer()
    call TimerStart(updateTimer, UPDATE_INTERVAL, true, function PeriodicUpdate)
    
    // Set initial chunk
    call UpdateMinimapAndBounds(startTileX, startTileY)
endfunction

endlibrary
