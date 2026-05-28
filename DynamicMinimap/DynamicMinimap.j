library DynamicMinimap initializer Init
//===========================================================================
/*
    DynamicMinimap - Texture Chunks & Camera Bounds with Toggle

    Author: [Valdemar]
    Version: 1.0
    
    Uses:
    - BlzChangeMinimapTerrainTex to swap minimap texture chunks
    - SetCameraBoundsToRect to constrain camera to the visible chunk area
    - Frame manipulation to enlarge/shrink minimap on demand
    
    This creates a scrolling RPG-style minimap that updates both the texture
    and camera bounds dynamically as the player moves.
    
    Features:
    - Dynamic minimap texture swapping based on camera position
    - Camera bounds automatically adjusted to match visible chunk
    - Seamless transition between chunks
    - Works with 256x256 minimap chunks
    - Toggle minimap enlargement with configurable hotkey (default ESC)
    
    Requirements (IMPORTANT)
    - Pre-rendered minimap textures in war3mapImported\ (256x256 px each)
    - Generated using minimap_texture_chunker.py

    My workflow (might differ depending on minimap customization needs):
        1. I took screenshot of the map (View entire map)
        2. Resized to 2024x2024 (doesnt matter what size as long as square)
        3. Upscaled to 8096x8096 using Upscayal AI (upscayl_2x_high-fidelity-4x)
        4. Used minimap_texture_chunker.py to split into 256x256 chunks
        5. Batch Converted PNGs to BLP using BLPLab
        6. Imported BLPs into map in war3mapImported\
        7. Used this DynamicMinimap.j library in map script
        8. Ready
    
    API:
        DynamicMinimap_SetChunkSize(tiles) - Set chunk size (default 32)
        DynamicMinimap_SetGridStep(tiles) - Set grid step between chunks (default 8)
        DynamicMinimap_Enable(enable) - Enable/disable entire system (stops updates, useful for cinematics)
        DynamicMinimap_ForceUpdate() - Manually trigger update
        DynamicMinimap_SetEnlargedPosition(x, y) - Set position when enlarged (default: 0.4, 0.3)
        DynamicMinimap_SetEnlargedScale(scale) - Set scale multiplier when enlarged (default: 3.0x)
        DynamicMinimap_SetToggleKey(oskeytype) - Set hotkey to toggle enlarge (default: OSKEY_ESCAPE)
        DynamicMinimap_GetMinimapEnlarged() - Check if minimap is currently enlarged
        DynamicMinimap_SetFullMapMode(enable) - Switch to single full map texture (disables chunking/bounds)
        DynamicMinimap_SetTrackedUnit(unit) - Set which unit to track (default: player 1 hero)
        DynamicMinimap_SetVisible(visible) - Show/hide the minimap
        DynamicMinimap_GetVisible() - Check if minimap is currently visible

    Credits:
    Thanks to FeelsGoodMan's post at Hive Workshop for idea how to implement minimap texture / camera bounds change

    Thanks to ANdROnlQ post @ Hiveworkshop https://www.hiveworkshop.com/threads/setcamerabounds-camera-rotation-bug.319374/
    Using SetCameraField(CAMERA_FIELD_ROTATION) with some values together calling SetCameraBounds will crash the game
    The camera rotation therefore must be tracked and not update camerabounds if the rotation is in illegal values 

*/
//===========================================================================

globals
    // ================= CONFIGURATION //===========================================================================
    private constant boolean DEBUG = true
    private constant real UPDATE_INTERVAL = 0.1  // How often to check for updates (default; 0.1)
    private constant integer DEFAULT_CHUNK_SIZE = 32   // 32x32 tiles per chunk (default; 32)
    private constant integer DEFAULT_GRID_STEP = 8     // Grid alignment (default; 8 tiles
    private constant real BOUNDS_PADDING_MULTIPLIER = 1.0  // Camera bounds = chunk size * this (MUST be 1.0 for accurate alignment)
    private constant integer MAP_SIZE_TILES = 480  // Actual WC3 map size in tiles (480x480 tiles)
    private constant integer CHUNK_COORDINATE_SYSTEM = 256  // Chunk files use 256-tile coordinate system
    
    // Map offset correction (CRITICAL - set these to match your Map Properties -> Size and Camera Bounds)
    // These values represent your map's actual world coordinate boundaries
    // Use Map bounds (the Map X/Y values), not Camera bounds!
    // Example: If Map shows X: -29184 to 32256, Y: -32256 to 29184, then:
    //   MAP_WORLD_MIN_X = -29184, MAP_WORLD_MAX_X = 32256
    //   MAP_WORLD_MIN_Y = -32256, MAP_WORLD_MAX_Y = 29184
    private constant real MAP_WORLD_MIN_X = -29184.0  // Map's left edge (from Map Properties)
    private constant real MAP_WORLD_MAX_X = 32256.0   // Map's right edge (from Map Properties)
    private constant real MAP_WORLD_MIN_Y = -32256.0  // Map's bottom edge (from Map Properties)
    private constant real MAP_WORLD_MAX_Y = 29184.0   // Map's top edge (from Map Properties)
    
    // Camera rotation safety (IMPORTANT - danger zone: 220-320 degrees causes crashes with SetCameraBounds especially on large maps)
    // GetCameraField returns RADIANS, so convert degrees to radians
    private constant real SAFE_ROTATION_MIN = 3.84  // 220 degrees in radians
    private constant real SAFE_ROTATION_MAX = 5.59  // 320 degrees in radians
    
    // Texture cache - format: minimap_X_Y_ZOOM.blp
    private constant string TEXTURE_PREFIX = "war3mapImported\\minimap_"
    private constant string TEXTURE_SUFFIX = ".blp"
    private constant string FULL_MAP_TEXTURE = "war3mapImported\\minimap_full.blp"

    // Minimap size toggle configuration (enlarges/shrinks minimap)
    private constant boolean ENABLE_SIZE_TOGGLE = true  // Enable minimap size toggle
    private constant oskeytype SIZE_TOGGLE_KEY = OSKEY_M  // Key to toggle minimap size (default: M)
    
    // Map mode toggle configuration (switches between full map and chunked mode)
    private constant boolean ENABLE_MODE_TOGGLE = true  // Enable map mode toggle
    private constant oskeytype MODE_TOGGLE_KEY = OSKEY_N // Key to toggle map mode (default: N)
    
    // Border frame configuration (Blizzard-style border when enlarged)
    private constant boolean ENABLE_BORDER_FRAME = true  // Show border around enlarged minimap
    private constant real BORDER_PADDING = 0.008  // Extra padding around minimap for border
    // private constant string BORDER_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\human-options-menu-background.dds"  // Texture for border backdrop
    private constant string BORDER_TEXTURE = "UI\\MinimapBackground.blp"  // Texture for border backdrop
    // ================= CONFIGURATION ENDS //===========================================================================

    // DO NOT CHANGE THESE
    private timer updateTimer = null
    private integer currentChunkSize = DEFAULT_CHUNK_SIZE
    private integer currentGridStep = DEFAULT_GRID_STEP
    private boolean enabled = true
    private boolean fullMapMode = false
    private integer lastTileX = -1
    private integer lastTileY = -1
    private rect currentBoundsRect = null
    private rect originalCameraBounds = null
    
    // Minimap size toggle functionality
    private framehandle minimapFrame = null
    private framehandle minimapBorderFrame = null  // Border backdrop for enlarged minimap
    private boolean minimapEnlarged = false
    private boolean minimapVisible = true  // Track minimap visibility
    private trigger sizeToggleTrigger = null  // Trigger for size toggle
    private real enlargedPosX = 0.4  // Center X (0.0 = left, 1.0 = right)
    private real enlargedPosY = 0.3  // Center Y (0.0 = bottom, 1.0 = top)
    private real enlargedScale = 3.0  // Scale multiplier
    private real enlargedPosX_new = 0.4  // Center X (0.0 = left, 1.0 = right)
    private real enlargedPosY_new = 0.358  // Center Y (0.0 = bottom, 1.0 = top)
    private real enlargedScale_new = 2.65  // Scale multiplier
    private real normalPosX = 0.009  // Normal minimap X position (BOTTOMLEFT)
    private real normalPosY = 0.008  // Normal minimap Y position (BOTTOMLEFT)
    private real normalScale = 1.0   // Default minimap scale
    
    // Chat detection
    private boolean chatWindowOpen = false  // Track if chat is open
    private trigger chatDetectTrigger = null
    private trigger chatOpenTrigger = null  // Detect ENTER key to open chat
    private trigger chatCancelTrigger = null  // Detect ESC key to cancel chat
    
    // Map mode toggle functionality
    private trigger modeToggleTrigger = null  // Trigger for mode toggle

endglobals

//===========================================================================
// Helper Functions
//===========================================================================
private function GetMinimapTexturePath takes integer tileX, integer tileY, integer chunkSize returns string
    // Generate texture path based on position
    // Example: "war3mapImported\\minimap_0_0_32.blp"
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
    local real minX
    local real minY
    local real maxX
    local real maxY
    local real boundsSize
    local integer tileX
    local integer tileY
    
    // Only update if position changed
    if chunkCoordX == lastTileX and chunkCoordY == lastTileY then
        return
    endif
    
    set lastTileX = chunkCoordX
    set lastTileY = chunkCoordY
    
    // Change minimap texture using chunk coordinates (256-tile system)
    set texturePath = GetMinimapTexturePath(chunkCoordX, chunkCoordY, currentChunkSize)
    call BlzChangeMinimapTerrainTex(texturePath)
    
    // Convert chunk → MAP TILE coordinates
    // CHANGED: used ONLY to locate chunk origin in tile space
    set tileX = R2I(I2R(chunkCoordX) * I2R(MAP_SIZE_TILES) / I2R(CHUNK_COORDINATE_SYSTEM))
    set tileY = R2I(I2R(chunkCoordY) * I2R(MAP_SIZE_TILES) / I2R(CHUNK_COORDINATE_SYSTEM))
    
    // NEW: compute centered bounds (REQUIRED for camera movement)
    set boundsSize = currentChunkSize * 128.0 * BOUNDS_PADDING_MULTIPLIER / 2.0

    set minX = MAP_WORLD_MIN_X + (tileX * 128.0) + boundsSize * -1.0
    set minY = MAP_WORLD_MIN_Y + (tileY * 128.0) + boundsSize * -1.0
    set maxX = MAP_WORLD_MIN_X + (tileX * 128.0) + boundsSize
    set maxY = MAP_WORLD_MIN_Y + (tileY * 128.0) + boundsSize
    
    // CRITICAL: Check camera rotation before setting bounds to prevent crashes
    if not IsCameraRotationSafe() then
        if DEBUG then
            call BJDebugMsg("|cffFF8800WARNING: Camera rotation unsafe - skipping bounds update|r")
        endif
        return
    endif
    
    // Create/update camera bounds rect
    if currentBoundsRect == null then
        set currentBoundsRect = Rect(minX, minY, maxX, maxY)
    else
        call SetRect(currentBoundsRect, minX, minY, maxX, maxY)
    endif
    
    // Apply camera bounds to region (only if rotation is safe)
    if currentBoundsRect != null then
        call SetCameraBoundsToRect(currentBoundsRect)
    endif
    
    /*
    if DEBUG then
        call BJDebugMsg("Minimap chunk: " + texturePath)
        call BJDebugMsg("Chunk coords (256-sys): " + I2S(chunkCoordX) + "," + I2S(chunkCoordY))
        call BJDebugMsg("Chunk size in map (480-sys): " + R2S(actualChunkSizeInMapTiles) + " tiles")
        call BJDebugMsg("Center world coords: " + R2S(centerX) + "," + R2S(centerY))
        call BJDebugMsg("Camera bounds: " + R2S(boundsSize * 2.0 / 128.0) + "x" + R2S(boundsSize * 2.0 / 128.0) + " tiles")
        call BJDebugMsg("Bounds rect: (" + R2S(minX) + "," + R2S(minY) + ") to (" + R2S(maxX) + "," + R2S(maxY) + ")")
    endif
    */
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
    
    if not enabled or fullMapMode then
        return
    endif
    
    // Get camera position
    set unitX = GetCameraTargetPositionX()
    set unitY = GetCameraTargetPositionY()
    
    // Convert to tile coordinates in actual map (0-based, each tile = 128 units)
    // CHANGED: this is now the SINGLE authoritative conversion
    set unitTileX = R2I((unitX - MAP_WORLD_MIN_X) / 128.0)
    set unitTileY = R2I((unitY - MAP_WORLD_MIN_Y) / 128.0)
    
    // Center the chunk on the unit (offset by half chunk size)
    set unitTileX = unitTileX - (currentChunkSize / 2)
    set unitTileY = unitTileY - (currentChunkSize / 2)
    
    // Snap to grid IN MAP TILE SPACE
    // CHANGED: snapping moved here (fixes cumulative drift)
    set unitTileX = (unitTileX / currentGridStep) * currentGridStep
    set unitTileY = (unitTileY / currentGridStep) * currentGridStep

    // Clamp to map bounds (map tile space)
    // NEW: ensures camera bounds never exceed map
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

    // Convert MAP TILE → CHUNK COORD system (256) for TEXTURE ONLY
    // CHANGED: one-way conversion, never converted back
    set chunkCoordX = R2I(I2R(unitTileX) * I2R(CHUNK_COORDINATE_SYSTEM) / I2R(MAP_SIZE_TILES))
    set chunkCoordY = R2I(I2R(unitTileY) * I2R(CHUNK_COORDINATE_SYSTEM) / I2R(MAP_SIZE_TILES))

    // Snap chunk coords to grid (texture alignment only)
    set chunkCoordX = (chunkCoordX / currentGridStep) * currentGridStep
    set chunkCoordY = (chunkCoordY / currentGridStep) * currentGridStep

    // Clamp chunk coords
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

    // Update minimap texture and camera bounds
    // CHANGED: unitTileX/Y are now the authoritative camera source
    call UpdateMinimapAndBounds(chunkCoordX, chunkCoordY)
    
endfunction

//===========================================================================
// Public API
//===========================================================================

function DynamicMinimap_ForceUpdate takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("DynamicMinimap: Force update triggered")
    endif
    set lastTileX = -1
    set lastTileY = -1
    call PeriodicUpdate()
endfunction

function DynamicMinimap_SetChunkSize takes integer tiles returns nothing
    set currentChunkSize = tiles
    set lastTileX = -1 // Force update
    set lastTileY = -1
    
    if DEBUG then
        call BJDebugMsg("Minimap chunk size set to: " + I2S(tiles) + "x" + I2S(tiles) + " tiles")
    endif
endfunction

function DynamicMinimap_SetGridStep takes integer tiles returns nothing
    set currentGridStep = tiles
    
    if DEBUG then
        call BJDebugMsg("Minimap grid step set to: " + I2S(tiles) + " tiles")
    endif
endfunction

function DynamicMinimap_Enable takes boolean enable returns nothing
    set enabled = enable
    
    // If re-enabling and in full map mode, switch back to chunked mode
    if enable and fullMapMode then
        set fullMapMode = false
        call DynamicMinimap_ForceUpdate()
    endif
    
    if DEBUG then
        if enable then
            call BJDebugMsg("DynamicMinimap: Enabled")
        else
            call BJDebugMsg("DynamicMinimap: Disabled")
        endif
    endif
endfunction

//===========================================================================
// Chat Detection Functions
//===========================================================================
private function OnChatOpen takes nothing returns boolean
    if GetTriggerPlayer() == GetLocalPlayer() then
        // ENTER key pressed - chat window is opening
        set chatWindowOpen = true
    endif
    return false
endfunction

private function OnChatMessage takes nothing returns nothing
    // Chat message was sent or cancelled, chat window is now closed
    set chatWindowOpen = false
endfunction

private function OnChatCancel takes nothing returns boolean
    if GetTriggerPlayer() == GetLocalPlayer() then
        // ESC pressed - reset chat state (fixes stuck chatWindowOpen bug)
        set chatWindowOpen = false
    endif
    return false
endfunction

function DynamicMinimap_SetFullMapMode takes boolean enable returns nothing
    if enable then
        // Switch to full map mode
        set fullMapMode = true
        
        // Load full map texture
        call BlzChangeMinimapTerrainTex(FULL_MAP_TEXTURE)
        
        // Restore original camera bounds (entire map) with rotation safety check
        if originalCameraBounds != null and IsCameraRotationSafe() then
            call SetCameraBoundsToRect(originalCameraBounds)
        endif
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00DynamicMinimap: Full map mode enabled|r")
        endif
    else
        // Switch back to chunked mode
        set fullMapMode = false
        
        // Force update to reload correct chunk
        call DynamicMinimap_ForceUpdate()
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00DynamicMinimap: Chunked mode enabled|r")
        endif
    endif
endfunction

//===========================================================================
// Minimap Size Toggle Functions
//===========================================================================
private function ToggleMinimapSize takes nothing returns nothing
    if minimapFrame == null or GetHandleId(minimapFrame) == 0 then
        if DEBUG then
            call BJDebugMsg("|cffFF0000Cannot toggle: minimapFrame invalid|r")
        endif
        return
    endif
    
    if minimapEnlarged then
        // Restore to normal - clear all points first, then set back to bottom left
        call BlzFrameClearAllPoints(minimapFrame)
        call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, normalPosX, normalPosY)
        call BlzFrameSetScale(minimapFrame, normalScale)
        set minimapEnlarged = false
        
        // Ensure minimap is visible (fixes visibility bug)
        call BlzFrameSetVisible(minimapFrame, true)
        
        // Re-assert frame levels (fixes z-order issues)
        call BlzFrameSetLevel(minimapFrame, 2)
        
        // Hide border frame (removed GetLocalPlayer check to prevent desync)
        if minimapBorderFrame != null then
            call BlzFrameSetVisible(minimapBorderFrame, false)
            call BlzFrameSetLevel(minimapBorderFrame, 1)
        endif
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap: Restored to normal|r")
        endif
    else
        // Enlarge and center - clear all points first, then set to center
        call BlzFrameClearAllPoints(minimapFrame)

        /* Temp check with reforged UI designer thing - ORIGINAL
        call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_CENTER, enlargedPosX, enlargedPosY)
        call BlzFrameSetScale(minimapFrame, enlargedScale)
        */

        // Test position and scale
        call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_CENTER, enlargedPosX_new, enlargedPosY_new)
        call BlzFrameSetScale(minimapFrame, enlargedScale_new)

        set minimapEnlarged = true
        
        // Ensure minimap is visible (fixes visibility bug)
        call BlzFrameSetVisible(minimapFrame, true)
        
        // Re-assert frame levels (fixes z-order issues)
        call BlzFrameSetLevel(minimapFrame, 2)
        
        // Show and position border frame (removed GetLocalPlayer check to prevent desync)
        if minimapBorderFrame != null then

            // Temp check with reforged UI designer thing - Uncomment if needed - This changes the minimapBorderFrame position to suit as border for minimap
            /*
            call BlzFrameClearAllPoints(minimapBorderFrame)
            call BlzFrameSetPoint(minimapBorderFrame, FRAMEPOINT_CENTER, minimapFrame, FRAMEPOINT_CENTER, 0, 0)
            call BlzFrameSetSize(minimapBorderFrame, BlzFrameGetWidth(minimapFrame) + BORDER_PADDING, BlzFrameGetHeight(minimapFrame) + BORDER_PADDING)
            */ 

            call BlzFrameSetVisible(minimapBorderFrame, true)
            call BlzFrameSetLevel(minimapBorderFrame, 1)
        endif
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap: Enlarged (" + R2S(enlargedScale) + "x) at (" + R2S(enlargedPosX) + ", " + R2S(enlargedPosY) + ")|r")
        endif
    endif
    
    // Force texture update if in chunked mode
    if not fullMapMode then
        call DynamicMinimap_ForceUpdate()
    else
        // In full map mode, reapply the full map texture
        call BlzChangeMinimapTerrainTex(FULL_MAP_TEXTURE)
    endif
endfunction

private function OnSizeToggleKey takes nothing returns boolean
    if GetTriggerPlayer() == GetLocalPlayer() then
        // If chat is open and this is ESC key, just close chat (don't toggle minimap)
        if chatWindowOpen then
            set chatWindowOpen = false
        else
            // Chat not open, safe to toggle minimap size
            call ToggleMinimapSize()
        endif
    endif
    return false
endfunction

//===========================================================================
// Map Mode Toggle Functions
//===========================================================================
private function ToggleMapMode takes nothing returns nothing
    if fullMapMode then
        // Switch to chunked mode
        call DynamicMinimap_SetFullMapMode(false)
        if DEBUG then
            call BJDebugMsg("|cff00ff00Map Mode: Chunked (dynamic)|r")
        endif
    else
        // Switch to full map mode
        call DynamicMinimap_SetFullMapMode(true)
        if DEBUG then
            call BJDebugMsg("|cff00ff00Map Mode: Full map|r")
        endif
    endif
endfunction

private function OnModeToggleKey takes nothing returns boolean
    if GetTriggerPlayer() == GetLocalPlayer() then
        // Don't toggle if chat is open
        if not chatWindowOpen then
            call ToggleMapMode()
        endif
    endif
    return false
endfunction

function DynamicMinimap_SetEnlargedPosition takes real x, real y returns nothing
    set enlargedPosX = x
    set enlargedPosY = y
    
    if DEBUG then
        call BJDebugMsg("Minimap enlarged position set to: (" + R2S(x) + ", " + R2S(y) + ")")
    endif
endfunction

function DynamicMinimap_SetEnlargedScale takes real scale returns nothing
    set enlargedScale = scale
    
    if DEBUG then
        call BJDebugMsg("Minimap enlarged scale set to: " + R2S(scale) + "x")
    endif
endfunction

function DynamicMinimap_SetSizeToggleKey takes oskeytype oskeyCode returns nothing
    // Remove old trigger
    if sizeToggleTrigger != null then
        call DestroyTrigger(sizeToggleTrigger)
    endif
    
    // Create new trigger with specified key
    set sizeToggleTrigger = CreateTrigger()
    call BlzTriggerRegisterPlayerKeyEvent(sizeToggleTrigger, Player(0), oskeyCode, 0, false)
    call TriggerAddCondition(sizeToggleTrigger, Condition(function OnSizeToggleKey))
    
    if DEBUG then
        call BJDebugMsg("Minimap size toggle key updated")
    endif
endfunction

function DynamicMinimap_SetModeToggleKey takes oskeytype oskeyCode returns nothing
    // Remove old trigger
    if modeToggleTrigger != null then
        call DestroyTrigger(modeToggleTrigger)
    endif
    
    // Create new trigger with specified key
    set modeToggleTrigger = CreateTrigger()
    call BlzTriggerRegisterPlayerKeyEvent(modeToggleTrigger, Player(0), oskeyCode, 0, false)
    call TriggerAddCondition(modeToggleTrigger, Condition(function OnModeToggleKey))
    
    if DEBUG then
        call BJDebugMsg("Map mode toggle key updated")
    endif
endfunction

function DynamicMinimap_GetMinimapEnlarged takes nothing returns boolean
    return minimapEnlarged
endfunction

function DynamicMinimap_SetVisible takes boolean visible returns nothing
    if minimapFrame == null then
        return
    endif
    
    set minimapVisible = visible
    
    if GetLocalPlayer() == Player(0) then
        call BlzFrameSetVisible(minimapFrame, visible)
    endif
    
    if DEBUG then
        if visible then
            call BJDebugMsg("|cff00ff00Minimap: Visible|r")
        else
            call BJDebugMsg("|cff00ff00Minimap: Hidden|r")
        endif
    endif
endfunction

function DynamicMinimap_GetVisible takes nothing returns boolean
    return minimapVisible
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function InitFrames takes nothing returns nothing
    // Get minimap frame and set its level
    set minimapFrame = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    if minimapFrame == null or GetHandleId(minimapFrame) == 0 then
        if DEBUG then
            call BJDebugMsg("|cffFF0000CRITICAL: Failed to get minimap frame (HandleId null)|r")
        endif
        return  // Abort initialization if minimap frame not available
    endif
    
    call BlzFrameSetLevel(minimapFrame, 2)  // Minimap higher level than border

/*
        set minimapBorderFrame = BlzCreateFrameByType("BACKDROP", "MinimapBorderBackdrop", gameUI, "", 0)
        if minimapBorderFrame != null then
            call BlzFrameSetTexture(minimapBorderFrame, BORDER_TEXTURE, 0, true)
            call BlzFrameSetLevel(minimapBorderFrame, -1)  // Below minimap (2) but above default UI (0)
            // Set all points to be slightly larger than minimap
            call BlzFrameSetPoint(minimapBorderFrame, FRAMEPOINT_TOPLEFT, minimapFrame, FRAMEPOINT_TOPLEFT, -BORDER_PADDING/2, BORDER_PADDING/2)
            call BlzFrameSetPoint(minimapBorderFrame, FRAMEPOINT_BOTTOMRIGHT, minimapFrame, FRAMEPOINT_BOTTOMRIGHT, BORDER_PADDING/2, -BORDER_PADDING/2)
            call BlzFrameSetVisible(minimapBorderFrame, false)  // Hidden initially
            
            if DEBUG then
                call BJDebugMsg("|cff00ff00Minimap border frame created|r")
            endif
        endif
    endif
    
*/ 
    // Set up ENTER key detection to track when chat opens
    set chatOpenTrigger = CreateTrigger()
    call BlzTriggerRegisterPlayerKeyEvent(chatOpenTrigger, Player(0), OSKEY_RETURN, 0, false)
    call TriggerAddCondition(chatOpenTrigger, Condition(function OnChatOpen))
    
    // Set up chat detection trigger to detect when chat closes
    set chatDetectTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(chatDetectTrigger, Player(0), "", false)
    call TriggerAddAction(chatDetectTrigger, function OnChatMessage)
    
    // Set up ESC key detection to reset chat state when cancelled
    set chatCancelTrigger = CreateTrigger()
    call BlzTriggerRegisterPlayerKeyEvent(chatCancelTrigger, Player(0), OSKEY_ESCAPE, 0, false)
    call TriggerAddCondition(chatCancelTrigger, Condition(function OnChatCancel))
    
    // Set up minimap size toggle trigger if enabled
    if ENABLE_SIZE_TOGGLE then
        set sizeToggleTrigger = CreateTrigger()
        call BlzTriggerRegisterPlayerKeyEvent(sizeToggleTrigger, Player(0), SIZE_TOGGLE_KEY, 0, false)
        call TriggerAddCondition(sizeToggleTrigger, Condition(function OnSizeToggleKey))
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap size toggle: Enabled|r")
        endif
    endif
    
    // Set up map mode toggle trigger if enabled
    if ENABLE_MODE_TOGGLE then
        set modeToggleTrigger = CreateTrigger()
        call BlzTriggerRegisterPlayerKeyEvent(modeToggleTrigger, Player(0), MODE_TOGGLE_KEY, 0, false)
        call TriggerAddCondition(modeToggleTrigger, Condition(function OnModeToggleKey))
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Map mode toggle: Enabled|r")
        endif
    endif
endfunction

private function Init takes nothing returns nothing
    local real startX
    local real startY
    local integer startTileX
    local integer startTileY
    local framehandle gameUI
    local framehandle parentFrame
    
    if DEBUG then
        call BJDebugMsg("|cffFFFF00DynamicMinimap: Starting initialization...|r")
        call BJDebugMsg("|cffAAAAFFMap bounds configured: X(" + R2S(MAP_WORLD_MIN_X) + " to " + R2S(MAP_WORLD_MAX_X) + "), Y(" + R2S(MAP_WORLD_MIN_Y) + " to " + R2S(MAP_WORLD_MAX_Y) + ")|r")
        call BJDebugMsg("|cffAAAAFFMap size: " + I2S(MAP_SIZE_TILES) + "x" + I2S(MAP_SIZE_TILES) + " tiles (" + R2S((MAP_WORLD_MAX_X - MAP_WORLD_MIN_X)) + " units)|r")
    endif
    
    // Create border frame at map init (CRITICAL: ConsoleUI operations must be done at map init, not in timers)
    if ENABLE_BORDER_FRAME then
        // Get gameUI first (always available)
        set gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        
        // Validate gameUI exists before proceeding
        if gameUI == null then
            if DEBUG then
                call BJDebugMsg("|cffFF0000CRITICAL: Failed to get ORIGIN_FRAME_GAME_UI - border frame disabled|r")
            endif
        else
            // Try to use ConsoleUIBackdrop as parent, fallback to gameUI if not available
            set parentFrame = BlzGetFrameByName("ConsoleUIBackdrop", 0)
            if parentFrame == null then
                set parentFrame = gameUI
                if DEBUG then
                    call BJDebugMsg("|cffFFFF00Border: Using gameUI as parent (ConsoleUIBackdrop not found)|r")
                endif
            endif
            
            // parentFrame is now guaranteed to be non-null (either ConsoleUIBackdrop or gameUI)
            if parentFrame != null then
            set minimapBorderFrame = BlzCreateFrameByType("BACKDROP", "MinimapBorderBackdrop", parentFrame, "", 1)
            if minimapBorderFrame != null then
                call BlzFrameSetAbsPoint(minimapBorderFrame, FRAMEPOINT_TOPLEFT, 0.0974200, 0.545080)
                call BlzFrameSetAbsPoint(minimapBorderFrame, FRAMEPOINT_BOTTOMRIGHT, 0.692630, 0.169240)
                call BlzFrameSetTexture(minimapBorderFrame, BORDER_TEXTURE, 0, true)
                call BlzFrameSetVisible(minimapBorderFrame, false)  // Hidden initially
                call BlzFrameSetLevel(minimapBorderFrame, 1)  // Below minimap (2) but above default UI (0)
                if DEBUG then
                    call BJDebugMsg("|cff00ff00Minimap border frame created at map init|r")
                endif
            else
                if DEBUG then
                    call BJDebugMsg("|cffFF0000Failed to create minimap border frame|r")
                endif
            endif
        else
            if DEBUG then
                call BJDebugMsg("|cffFF0000CRITICAL: parentFrame is null (should not happen)|r")
            endif
        endif
        endif
    endif
    
    // Store original camera bounds for full map mode (use GetEntireMapRect for safety)
    set originalCameraBounds = GetEntireMapRect()
    
    // Get initial camera position
    set startX = GetCameraTargetPositionX()
    set startY = GetCameraTargetPositionY()
    
    if DEBUG then
        call BJDebugMsg("|cff00ff00Using camera position for minimap tracking|r")
        call BJDebugMsg("|cffAAAAFFInitial position: (" + R2S(startX) + ", " + R2S(startY) + ")|r")
    endif
    
    set startTileX = R2I((startX - MAP_WORLD_MIN_X) / 128.0) - (currentChunkSize / 2)
    set startTileY = R2I((startY - MAP_WORLD_MIN_Y) / 128.0) - (currentChunkSize / 2)
    
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
    
    // Delay frame initialization until after map load (0.1s for asset-heavy maps)
    call TimerStart(CreateTimer(), 1.0, false, function InitFrames)
    
    // Start update timer
    set updateTimer = CreateTimer()
    call TimerStart(updateTimer, UPDATE_INTERVAL, true, function PeriodicUpdate)
    
    // Set initial minimap texture and camera bounds
    call UpdateMinimapAndBounds(startTileX, startTileY)
    
    if DEBUG then
        call BJDebugMsg("|cff00ff00DynamicMinimap: Initialized|r")
        call BJDebugMsg("|cffAAAAFFChunk size: " + I2S(currentChunkSize) + "x" + I2S(currentChunkSize) + " tiles|r")
        call BJDebugMsg("|cffAAAAFFGrid step: " + I2S(currentGridStep) + " tiles|r")
    endif
endfunction

endlibrary
