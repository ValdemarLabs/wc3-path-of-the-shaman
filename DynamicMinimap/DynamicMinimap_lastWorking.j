/**
    DynamicMinimap

    Author: Valdemar
    Version: 1.5

    Description:
        Swaps 256-coordinate minimap chunks and updates matching camera bounds.
        Full/chunked map modes and normal/enlarged frame layouts can be toggled.
        Approaching chunk borders can request a gentle safe-angle correction
        from CameraControl. Cinematic suspension cancels all pending chunk work
        and restores the full-map presentation.

    Credits:
        FeelsGoodMan for the dynamic minimap texture/camera-bounds approach.
        ANdROnlQ for documenting the SetCameraBounds rotation crash:
        https://www.hiveworkshop.com/threads/setcamerabounds-camera-rotation-bug.319374/

    How to install:
        Import the pre-rendered 256x256 BLP chunks and full-map texture under
        war3mapImported\, import this library after Interface, and configure the
        map, camera, and minimap-art bounds below. Import CameraControl after
        this library to service smooth safe-rotation requests.

    Uses:
    - BlzChangeMinimapTerrainTex to swap minimap texture chunks
    - SetCameraBoundsToRect to constrain camera to the visible chunk area
    - Optional CameraControl integration for non-cinematic safety turns
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
        DynamicMinimap_SetChunkSize(tiles)
        DynamicMinimap_SetGridStep(tiles)
        DynamicMinimap_Enable(enable)
        DynamicMinimap_SuspendForScriptedCamera()
        DynamicMinimap_ResumeAfterScriptedCamera()
        DynamicMinimap_HasSafeRotationRequest()
        DynamicMinimap_GetSafeRotationTarget()
        DynamicMinimap_ForceUpdate()
        DynamicMinimap_SetEnlargedPosition(x, y)
        DynamicMinimap_SetEnlargedScale(scale)
        DynamicMinimap_SetSizeToggleKey(oskeytype)
        DynamicMinimap_SetModeToggleKey(oskeytype)
        DynamicMinimap_GetMinimapEnlarged()
        DynamicMinimap_SetFullMapMode(enable)
        DynamicMinimap_SetVisible(visible)
        DynamicMinimap_GetVisible()
**/
library DynamicMinimap initializer Init requires Interface

globals
    // ================= CONFIGURATION //===========================================================================
    private constant boolean DEBUG = false
    private constant real UPDATE_INTERVAL = 0.1  // How often to check for updates (default; 0.1)
    private constant integer DEFAULT_CHUNK_SIZE = 32   // Chunk size in the 256-coordinate texture system
    private constant integer DEFAULT_GRID_STEP = 8     // Grid step in the 256-coordinate texture system
    private constant real BOUNDS_PADDING_MULTIPLIER = 1.0  // Camera bounds = chunk size * this (MUST be 1.0 for accurate alignment)
    private constant integer CHUNK_COORDINATE_SYSTEM = 256  // Chunk files use 256-tile coordinate system
    
    // Map Properties -> Size. These bounds drive texture/chunk coordinate math.
    private constant real MAP_WORLD_MIN_X = -29184.0
    private constant real MAP_WORLD_MAX_X = 32256.0
    private constant real MAP_WORLD_MIN_Y = -32256.0
    private constant real MAP_WORLD_MAX_Y = 29184.0

    // Map Properties -> Camera Bounds. These restore the authored full-map camera limits.
    private constant real CAMERA_WORLD_MIN_X = -28672.0
    private constant real CAMERA_WORLD_MAX_X = 31744.0
    private constant real CAMERA_WORLD_MIN_Y = -32000.0
    private constant real CAMERA_WORLD_MAX_Y = 28928.0

    // Minimap-art calibration in world units. Positive values move the art's represented
    // world area east/north. Keep both at 0 until an accurately cropped source is available.
    private constant real MINIMAP_ART_OFFSET_X = 0.0
    private constant real MINIMAP_ART_OFFSET_Y = 0.0

    // SetCameraBounds can crash while the camera faces through this rotation range.
    // GetCameraField returns radians, so the safety check converts it to degrees.
    private constant real ILLEGAL_ROTATION_MIN = 220.0
    private constant real ILLEGAL_ROTATION_MAX = 320.0
    private constant real SAFE_ROTATION_BELOW = 218.0
    private constant real SAFE_ROTATION_ABOVE = 322.0
    private constant real SAFE_ROTATION_SETTLE_TOLERANCE = 0.50
    private constant real ROTATION_LOOKAHEAD_DISTANCE = 1152.0
    private constant real CAMERA_MOVEMENT_EPSILON = 1.0
    private constant integer CAMERA_RESUME_SETTLE_TICKS = 2
    
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
    private integer scriptedCameraSuspendDepth = 0
    private boolean scriptedCameraWasEnabled = false
    private integer cameraResumeSettleTicks = 0
    private boolean cameraResumeRefreshPending = false
    private boolean safeRotationRequested = false
    private real safeRotationTarget = SAFE_ROTATION_BELOW
    private boolean cameraTargetSampled = false
    private real previousCameraTargetX = 0.0
    private real previousCameraTargetY = 0.0

    // Deferred texture/bounds transaction while the current rotation is unsafe.
    private boolean pendingMapUpdate = false
    private boolean pendingTextureChange = false
    private boolean pendingChunkCommit = false
    private string pendingTexturePath = null
    private integer pendingChunkX = -1
    private integer pendingChunkY = -1
    private real pendingBoundsMinX = 0.0
    private real pendingBoundsMinY = 0.0
    private real pendingBoundsMaxX = 0.0
    private real pendingBoundsMaxY = 0.0
    
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

private function GetCameraRotationDegrees takes nothing returns real
    local real rotation = GetCameraField(CAMERA_FIELD_ROTATION) * bj_RADTODEG

    loop
        exitwhen rotation >= 0.0
        set rotation = rotation + 360.0
    endloop
    loop
        exitwhen rotation < 360.0
        set rotation = rotation - 360.0
    endloop
    return rotation
endfunction

private function IsCameraRotationSafe takes nothing returns boolean
    local real rotation = GetCameraRotationDegrees()
    return rotation < ILLEGAL_ROTATION_MIN or rotation > ILLEGAL_ROTATION_MAX
endfunction

function DynamicMinimap_HasSafeRotationRequest takes nothing returns boolean
    return safeRotationRequested and scriptedCameraSuspendDepth == 0
endfunction

function DynamicMinimap_GetSafeRotationTarget takes nothing returns real
    return safeRotationTarget
endfunction

private function CancelSafeRotationRequest takes nothing returns nothing
    set safeRotationRequested = false
endfunction

private function RequestSafeRotation takes nothing returns nothing
    local real rotation = GetCameraRotationDegrees()

    if rotation <= (ILLEGAL_ROTATION_MIN + ILLEGAL_ROTATION_MAX) * 0.5 then
        set safeRotationTarget = SAFE_ROTATION_BELOW
    else
        set safeRotationTarget = SAFE_ROTATION_ABOVE
    endif
    set safeRotationRequested = true
endfunction

private function IsSafeRotationTargetReached takes nothing returns boolean
    local real delta = GetCameraRotationDegrees() - safeRotationTarget

    if delta < 0.0 then
        set delta = -delta
    endif
    if delta > 180.0 then
        set delta = 360.0 - delta
    endif
    return delta <= SAFE_ROTATION_SETTLE_TOLERANCE
endfunction

private function CancelPendingMapUpdate takes nothing returns nothing
    set pendingMapUpdate = false
    set pendingTextureChange = false
    set pendingChunkCommit = false
    set pendingTexturePath = null
    set pendingChunkX = -1
    set pendingChunkY = -1
endfunction

// DynamicMinimap never changes rotation. Unsafe bounds work waits for the camera owner.
private function TryApplyPendingMapUpdate takes nothing returns boolean
    if not pendingMapUpdate then
        return true
    endif

    if not IsCameraRotationSafe() then
        call RequestSafeRotation()
        if DEBUG then
            call BJDebugMsg("|cffFF8800DynamicMinimap: bounds update waiting for a safe camera rotation|r")
        endif
        return false
    endif
    if safeRotationRequested and not IsSafeRotationTargetReached() then
        return false
    endif

    if pendingTextureChange then
        call BlzChangeMinimapTerrainTex(pendingTexturePath)
    endif

    if currentBoundsRect == null then
        set currentBoundsRect = Rect(pendingBoundsMinX, pendingBoundsMinY, pendingBoundsMaxX, pendingBoundsMaxY)
    else
        call SetRect(currentBoundsRect, pendingBoundsMinX, pendingBoundsMinY, pendingBoundsMaxX, pendingBoundsMaxY)
    endif
    call SetCameraBoundsToRect(currentBoundsRect)

    if pendingChunkCommit then
        set lastTileX = pendingChunkX
        set lastTileY = pendingChunkY
    endif

    call CancelSafeRotationRequest()
    call CancelPendingMapUpdate()
    return true
endfunction

private function QueueMapUpdate takes string texturePath, boolean changeTexture, boolean commitChunk, integer chunkX, integer chunkY, real minX, real minY, real maxX, real maxY returns nothing
    if scriptedCameraSuspendDepth > 0 then
        return
    endif

    set pendingTexturePath = texturePath
    set pendingTextureChange = changeTexture
    set pendingChunkCommit = commitChunk
    set pendingChunkX = chunkX
    set pendingChunkY = chunkY
    set pendingBoundsMinX = minX
    set pendingBoundsMinY = minY
    set pendingBoundsMaxX = maxX
    set pendingBoundsMaxY = maxY
    set pendingMapUpdate = true
    call TryApplyPendingMapUpdate()
endfunction

private function RestoreOriginalCameraBounds takes nothing returns nothing
    set lastTileX = -1
    set lastTileY = -1
    call QueueMapUpdate(null, false, false, -1, -1, CAMERA_WORLD_MIN_X, CAMERA_WORLD_MIN_Y, CAMERA_WORLD_MAX_X, CAMERA_WORLD_MAX_Y)
endfunction

private function RequestFullMapUpdate takes nothing returns nothing
    call QueueMapUpdate(FULL_MAP_TEXTURE, true, false, -1, -1, CAMERA_WORLD_MIN_X, CAMERA_WORLD_MIN_Y, CAMERA_WORLD_MAX_X, CAMERA_WORLD_MAX_Y)
endfunction

private function UpdateMinimapAndBounds takes integer chunkCoordX, integer chunkCoordY returns nothing
    local string texturePath
    local real minX
    local real minY
    local real maxX
    local real maxY
    local real centerX
    local real centerY
    local real boundsHalfWidth
    local real boundsHalfHeight
    local real chunkWorldWidth
    local real chunkWorldHeight
    local real scaleX = (MAP_WORLD_MAX_X - MAP_WORLD_MIN_X) / I2R(CHUNK_COORDINATE_SYSTEM)
    local real scaleY = (MAP_WORLD_MAX_Y - MAP_WORLD_MIN_Y) / I2R(CHUNK_COORDINATE_SYSTEM)
    
    // Only update if position changed
    if chunkCoordX == lastTileX and chunkCoordY == lastTileY and not pendingMapUpdate then
        return
    endif

    set texturePath = GetMinimapTexturePath(chunkCoordX, chunkCoordY, currentChunkSize)

    set chunkWorldWidth = I2R(currentChunkSize) * scaleX
    set chunkWorldHeight = I2R(currentChunkSize) * scaleY
    set centerX = MAP_WORLD_MIN_X + MINIMAP_ART_OFFSET_X + I2R(chunkCoordX) * scaleX + chunkWorldWidth * 0.5
    set centerY = MAP_WORLD_MIN_Y + MINIMAP_ART_OFFSET_Y + I2R(chunkCoordY) * scaleY + chunkWorldHeight * 0.5
    set boundsHalfWidth = chunkWorldWidth * BOUNDS_PADDING_MULTIPLIER * 0.5
    set boundsHalfHeight = chunkWorldHeight * BOUNDS_PADDING_MULTIPLIER * 0.5
    set minX = centerX - boundsHalfWidth
    set minY = centerY - boundsHalfHeight
    set maxX = centerX + boundsHalfWidth
    set maxY = centerY + boundsHalfHeight

    call QueueMapUpdate(texturePath, true, true, chunkCoordX, chunkCoordY, minX, minY, maxX, maxY)
    
    if DEBUG then
        call BJDebugMsg("Minimap chunk: " + texturePath)
        call BJDebugMsg("Chunk coords (256-sys): " + I2S(chunkCoordX) + "," + I2S(chunkCoordY))
        call BJDebugMsg("Center world coords: " + R2S(centerX) + "," + R2S(centerY))
        call BJDebugMsg("Bounds rect: (" + R2S(minX) + "," + R2S(minY) + ") to (" + R2S(maxX) + "," + R2S(maxY) + ")")
    endif
endfunction

private function GetChunkCoordinate takes real worldValue, real worldMin, real worldMax, real artOffset returns integer
    local real scale = (worldMax - worldMin) / I2R(CHUNK_COORDINATE_SYSTEM)
    local integer chunkCoord = R2I((worldValue - worldMin - artOffset) / scale - I2R(currentChunkSize) * 0.5)

    set chunkCoord = (chunkCoord / currentGridStep) * currentGridStep
    if chunkCoord < 0 then
        return 0
    elseif chunkCoord > CHUNK_COORDINATE_SYSTEM - currentChunkSize then
        return CHUNK_COORDINATE_SYSTEM - currentChunkSize
    endif
    return chunkCoord
endfunction

private function IsApproachingChunkBorder takes real cameraX, real cameraY, integer chunkX, integer chunkY returns boolean
    local real lookaheadX = cameraX
    local real lookaheadY = cameraY

    if not cameraTargetSampled then
        return false
    endif

    if cameraX > previousCameraTargetX + CAMERA_MOVEMENT_EPSILON then
        set lookaheadX = cameraX + ROTATION_LOOKAHEAD_DISTANCE
    elseif cameraX < previousCameraTargetX - CAMERA_MOVEMENT_EPSILON then
        set lookaheadX = cameraX - ROTATION_LOOKAHEAD_DISTANCE
    endif
    if cameraY > previousCameraTargetY + CAMERA_MOVEMENT_EPSILON then
        set lookaheadY = cameraY + ROTATION_LOOKAHEAD_DISTANCE
    elseif cameraY < previousCameraTargetY - CAMERA_MOVEMENT_EPSILON then
        set lookaheadY = cameraY - ROTATION_LOOKAHEAD_DISTANCE
    endif

    return GetChunkCoordinate(lookaheadX, MAP_WORLD_MIN_X, MAP_WORLD_MAX_X, MINIMAP_ART_OFFSET_X) != chunkX or GetChunkCoordinate(lookaheadY, MAP_WORLD_MIN_Y, MAP_WORLD_MAX_Y, MINIMAP_ART_OFFSET_Y) != chunkY
endfunction

//===========================================================================
// Periodic Update
//===========================================================================
private function PeriodicUpdate takes nothing returns nothing
    local real unitX
    local real unitY
    local integer chunkCoordX
    local integer chunkCoordY
    local boolean approachingBorder

    // No texture or bounds operation may occur while a cinematic owns the camera.
    if scriptedCameraSuspendDepth > 0 then
        return
    endif

    if cameraResumeSettleTicks > 0 then
        set cameraResumeSettleTicks = cameraResumeSettleTicks - 1
        return
    endif

    if cameraResumeRefreshPending then
        set cameraResumeRefreshPending = false
        set lastTileX = -1
        set lastTileY = -1
        if enabled and fullMapMode then
            call RequestFullMapUpdate()
            return
        endif
    endif

    // Finish a queued transaction before calculating another chunk.
    if pendingMapUpdate then
        call TryApplyPendingMapUpdate()
        return
    endif
    
    if not enabled or fullMapMode then
        return
    endif
    
    // Get camera position
    set unitX = GetCameraTargetPositionX()
    set unitY = GetCameraTargetPositionY()
    
    set chunkCoordX = GetChunkCoordinate(unitX, MAP_WORLD_MIN_X, MAP_WORLD_MAX_X, MINIMAP_ART_OFFSET_X)
    set chunkCoordY = GetChunkCoordinate(unitY, MAP_WORLD_MIN_Y, MAP_WORLD_MAX_Y, MINIMAP_ART_OFFSET_Y)
    set approachingBorder = IsApproachingChunkBorder(unitX, unitY, chunkCoordX, chunkCoordY)
    set previousCameraTargetX = unitX
    set previousCameraTargetY = unitY
    set cameraTargetSampled = true

    if approachingBorder or chunkCoordX != lastTileX or chunkCoordY != lastTileY then
        if not IsCameraRotationSafe() then
            call RequestSafeRotation()
        elseif safeRotationRequested and IsSafeRotationTargetReached() then
            call CancelSafeRotationRequest()
        endif
    elseif not pendingMapUpdate then
        call CancelSafeRotationRequest()
    endif
    
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
    if scriptedCameraSuspendDepth > 0 then
        // Remember the requested gameplay state without allowing the cinematic
        // to restart texture or camera-bounds work prematurely.
        set scriptedCameraWasEnabled = enable
        set enabled = false
        return
    endif

    set enabled = enable

    // Stopping the update timer is not enough for a distant cinematic cut:
    // the last chunk bounds otherwise remain active and make the camera walk
    // across chunks instead of reaching the camerasetup in one frame.
    if not enabled then
        call CancelSafeRotationRequest()
        call RestoreOriginalCameraBounds()
    endif
    
    // If re-enabling and in full map mode, switch back to chunked mode
    if enabled and fullMapMode then
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

function DynamicMinimap_SuspendForScriptedCamera takes nothing returns nothing
    if scriptedCameraSuspendDepth == 0 then
        set scriptedCameraWasEnabled = enabled
        set enabled = false
        set cameraResumeSettleTicks = 0
        set cameraResumeRefreshPending = false
        set cameraTargetSampled = false
        set lastTileX = -1
        set lastTileY = -1
        call CancelSafeRotationRequest()
        call CancelPendingMapUpdate()

        // The texture swap itself is safe and ensures cinematics always display
        // the full map. Full bounds are restored only when the entry rotation is
        // safe; no bounds operation may remain queued after camera ownership moves.
        call BlzChangeMinimapTerrainTex(FULL_MAP_TEXTURE)
        if IsCameraRotationSafe() then
            call RestoreOriginalCameraBounds()
        elseif DEBUG then
            call BJDebugMsg("|cffFF8800DynamicMinimap: cinematic suspension skipped unsafe full-bounds update|r")
        endif
    endif

    set scriptedCameraSuspendDepth = scriptedCameraSuspendDepth + 1
endfunction

function DynamicMinimap_ResumeAfterScriptedCamera takes nothing returns nothing
    if scriptedCameraSuspendDepth <= 0 then
        return
    endif

    set scriptedCameraSuspendDepth = scriptedCameraSuspendDepth - 1
    if scriptedCameraSuspendDepth > 0 then
        return
    endif

    set enabled = scriptedCameraWasEnabled
    set cameraTargetSampled = false
    set cameraResumeSettleTicks = CAMERA_RESUME_SETTLE_TICKS
    set cameraResumeRefreshPending = enabled
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
        set fullMapMode = true
        call CancelSafeRotationRequest()
        call RequestFullMapUpdate()
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00DynamicMinimap: Full map mode enabled|r")
        endif
    else
        set fullMapMode = false
        call CancelPendingMapUpdate()
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

        call Interface_NotifyMapClosed()

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

        call Interface_NotifyMapOpened()

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
        // Reassert texture and bounds together so unit icons keep the full-map transform.
        call RequestFullMapUpdate()
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
        call Interface_NotifyMapModeChanged()
        call DynamicMinimap_SetFullMapMode(false)
        if DEBUG then
            call BJDebugMsg("|cff00ff00Map Mode: Chunked (dynamic)|r")
        endif
    else
        // Switch to full map mode
        call Interface_NotifyMapModeChanged()
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
    local timer initTimer = GetExpiredTimer()

    // Get minimap frame and set its level
    set minimapFrame = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    if minimapFrame == null or GetHandleId(minimapFrame) == 0 then
        if DEBUG then
            call BJDebugMsg("|cffFF0000CRITICAL: Failed to get minimap frame (HandleId null)|r")
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
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
    call DestroyTimer(initTimer)
    set initTimer = null
endfunction

private function Init takes nothing returns nothing
    local real startX
    local real startY
    local framehandle gameUI
    local framehandle parentFrame
    
    if DEBUG then
        call BJDebugMsg("|cffFFFF00DynamicMinimap: Starting initialization...|r")
        call BJDebugMsg("|cffAAAAFFMap bounds configured: X(" + R2S(MAP_WORLD_MIN_X) + " to " + R2S(MAP_WORLD_MAX_X) + "), Y(" + R2S(MAP_WORLD_MIN_Y) + " to " + R2S(MAP_WORLD_MAX_Y) + ")|r")
        call BJDebugMsg("|cffAAAAFFCamera bounds configured: X(" + R2S(CAMERA_WORLD_MIN_X) + " to " + R2S(CAMERA_WORLD_MAX_X) + "), Y(" + R2S(CAMERA_WORLD_MIN_Y) + " to " + R2S(CAMERA_WORLD_MAX_Y) + ")|r")
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
    
    // Get initial camera position
    set startX = GetCameraTargetPositionX()
    set startY = GetCameraTargetPositionY()
    
    if DEBUG then
        call BJDebugMsg("|cff00ff00Using camera position for minimap tracking|r")
        call BJDebugMsg("|cffAAAAFFInitial position: (" + R2S(startX) + ", " + R2S(startY) + ")|r")
    endif
    
    // Delay frame initialization until after map load (0.1s for asset-heavy maps)
    call TimerStart(CreateTimer(), 1.0, false, function InitFrames)
    
    // Start update timer
    set updateTimer = CreateTimer()
    call TimerStart(updateTimer, UPDATE_INTERVAL, true, function PeriodicUpdate)
    
    // Set initial minimap texture and camera bounds through the normal conversion path.
    call PeriodicUpdate()

    if DEBUG then
        call BJDebugMsg("|cff00ff00DynamicMinimap: Initialized|r")
        call BJDebugMsg("|cffAAAAFFChunk size: " + I2S(currentChunkSize) + "x" + I2S(currentChunkSize) + " tiles|r")
        call BJDebugMsg("|cffAAAAFFGrid step: " + I2S(currentGridStep) + " tiles|r")
    endif
    set gameUI = null
    set parentFrame = null
endfunction

endlibrary
