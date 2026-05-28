//===========================================================================
/*
    Dynamic Camera Bounds System v1.0
    
    Automatically adjusts camera bounds based on camera location.
    The camera bounds follow the camera position to create a smooth
    minimap experience without manual frame manipulation.
    
    Features:
    - Periodic camera position tracking
    - Dynamic camera bounds adjustment
    - Per-player independent bounds
    - Configurable bound sizes
    - Multiple preset sizes (small, medium, large, full map)
    
    How it works:
    - Timer checks camera position periodically
    - When camera moves, bounds are updated to center on camera
    - Bounds size determines how much area is visible on minimap
    - Smaller bounds = more zoomed in minimap
    
    API:
    
    // Set bounds size for specific player (width, height in world coords)
    call DynamicCameraBounds_SetSize(player, width, height)
    
    // Use preset sizes
    call DynamicCameraBounds_SetPreset(player, "small")   // ~2000x2000
    call DynamicCameraBounds_SetPreset(player, "medium")  // ~4000x4000
    call DynamicCameraBounds_SetPreset(player, "large")   // ~6000x6000
    call DynamicCameraBounds_SetPreset(player, "xlarge")  // ~8000x8000
    call DynamicCameraBounds_SetPreset(player, "full")    // Entire map
    
    // Enable/disable dynamic bounds for player
    call DynamicCameraBounds_Enable(player, true/false)
    
    // Set update frequency (default 0.1 seconds)
    call DynamicCameraBounds_SetUpdateInterval(seconds)
    
    // Reset to default map bounds
    call DynamicCameraBounds_Reset(player)
    
    // Get current bounds info
    call DynamicCameraBounds_GetBoundsWidth(player) returns real
    call DynamicCameraBounds_GetBoundsHeight(player) returns real
    
    // Advanced: Set custom bounds padding (adds extra space around camera)
    call DynamicCameraBounds_SetPadding(player, paddingX, paddingY)
*/
//===========================================================================

library DynamicCameraBounds initializer Init

//===========================================================================
// CONFIGURATION
//===========================================================================
globals
    private constant boolean DEBUG_MODE = true
    
    // Default update interval (how often to check camera position)
    private constant real DEFAULT_UPDATE_INTERVAL = 0.1
    
    // Preset bound sizes (world coordinates)
    private constant real PRESET_SMALL_WIDTH    = 2000.0
    private constant real PRESET_SMALL_HEIGHT   = 2000.0
    private constant real PRESET_MEDIUM_WIDTH   = 4000.0
    private constant real PRESET_MEDIUM_HEIGHT  = 4000.0
    private constant real PRESET_LARGE_WIDTH    = 6000.0
    private constant real PRESET_LARGE_HEIGHT   = 6000.0
    private constant real PRESET_XLARGE_WIDTH   = 8000.0
    private constant real PRESET_XLARGE_HEIGHT  = 8000.0
    
    // Default bounds size
    private constant real DEFAULT_BOUNDS_WIDTH  = 4000.0
    private constant real DEFAULT_BOUNDS_HEIGHT = 4000.0
    
    // Minimum bounds size to prevent issues
    private constant real MIN_BOUNDS_SIZE       = 500.0
endglobals

//===========================================================================
// SYSTEM DATA
//===========================================================================
globals
    // Per-player settings
    private boolean array PlayerEnabled         // Is dynamic bounds enabled
    private real array BoundsWidth              // Current bounds width
    private real array BoundsHeight             // Current bounds height
    private real array PaddingX                 // Extra padding X
    private real array PaddingY                 // Extra padding Y
    private real array LastCameraX              // Last known camera X
    private real array LastCameraY              // Last known camera Y
    
    // Map bounds (stored at init)
    private real MapMinX
    private real MapMinY
    private real MapMaxX
    private real MapMaxY
    private real MapWidth
    private real MapHeight
    
    // System state
    private timer UpdateTimer = null
    private real UpdateInterval = DEFAULT_UPDATE_INTERVAL
    private integer ActivePlayers = 0
endglobals

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================

// Debug output
private function Debug takes string msg returns nothing
    if DEBUG_MODE then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cffFFCC00[DynBounds]|r " + msg)
    endif
endfunction

// Clamp value between min and max
private function Clamp takes real value, real minVal, real maxVal returns real
    if value < minVal then
        return minVal
    elseif value > maxVal then
        return maxVal
    endif
    return value
endfunction

// Get map bounds
private function GetMapBounds takes nothing returns nothing
    local rect mapRect = GetPlayableMapRect()
    
    set MapMinX = GetRectMinX(mapRect)
    set MapMinY = GetRectMinY(mapRect)
    set MapMaxX = GetRectMaxX(mapRect)
    set MapMaxY = GetRectMaxY(mapRect)
    set MapWidth = MapMaxX - MapMinX
    set MapHeight = MapMaxY - MapMinY
    
    set mapRect = null
    
    call Debug("Map bounds: " + R2S(MapWidth) + "x" + R2S(MapHeight))
endfunction

//===========================================================================
// CAMERA BOUNDS MANAGEMENT
//===========================================================================

// Set camera bounds for a specific player
private function SetPlayerCameraBounds takes player p, real minX, real minY, real maxX, real maxY returns nothing
    if GetLocalPlayer() == p then
        call SetCameraBounds(minX + GetCameraMargin(CAMERA_MARGIN_LEFT), minY + GetCameraMargin(CAMERA_MARGIN_BOTTOM), maxX - GetCameraMargin(CAMERA_MARGIN_RIGHT), maxY - GetCameraMargin(CAMERA_MARGIN_TOP), minX + GetCameraMargin(CAMERA_MARGIN_LEFT), maxY - GetCameraMargin(CAMERA_MARGIN_TOP), maxX - GetCameraMargin(CAMERA_MARGIN_RIGHT), minY + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    endif
endfunction

// Update camera bounds based on camera position
private function UpdateCameraBoundsForPlayer takes player p returns nothing
    local integer pid = GetPlayerId(p)
    local real camX
    local real camY
    local real halfWidth
    local real halfHeight
    local real minX
    local real minY
    local real maxX
    local real maxY
    
    if not PlayerEnabled[pid] then
        return
    endif
    
    // Get camera position (only works for local player, but that's what we want)
    if GetLocalPlayer() == p then
        set camX = GetCameraTargetPositionX()
        set camY = GetCameraTargetPositionY()
        
        // Calculate bounds
        set halfWidth = (BoundsWidth[pid] + PaddingX[pid]) / 2.0
        set halfHeight = (BoundsHeight[pid] + PaddingY[pid]) / 2.0
        
        // Calculate new bounds centered on camera
        set minX = camX - halfWidth
        set minY = camY - halfHeight
        set maxX = camX + halfWidth
        set maxY = camY + halfHeight
        
        // Clamp to map bounds
        set minX = Clamp(minX, MapMinX, MapMaxX - BoundsWidth[pid])
        set minY = Clamp(minY, MapMinY, MapMaxY - BoundsHeight[pid])
        set maxX = Clamp(maxX, MapMinX + BoundsWidth[pid], MapMaxX)
        set maxY = Clamp(maxY, MapMinY + BoundsHeight[pid], MapMaxY)
        
        // Apply bounds
        call SetCameraBounds(minX + GetCameraMargin(CAMERA_MARGIN_LEFT), minY + GetCameraMargin(CAMERA_MARGIN_BOTTOM), maxX - GetCameraMargin(CAMERA_MARGIN_RIGHT), maxY - GetCameraMargin(CAMERA_MARGIN_TOP), minX + GetCameraMargin(CAMERA_MARGIN_LEFT), maxY - GetCameraMargin(CAMERA_MARGIN_TOP), maxX - GetCameraMargin(CAMERA_MARGIN_RIGHT), minY + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
        
        // Store last position
        set LastCameraX[pid] = camX
        set LastCameraY[pid] = camY
    endif
endfunction

// Periodic update callback
private function UpdateAllPlayers takes nothing returns nothing
    local integer i = 0
    local player p
    
    loop
        exitwhen i >= 12
        set p = Player(i)
        
        if PlayerEnabled[i] and GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING then
            call UpdateCameraBoundsForPlayer(p)
        endif
        
        set i = i + 1
    endloop
endfunction

//===========================================================================
// PUBLIC API
//===========================================================================

// Enable or disable dynamic camera bounds for a player
public function Enable takes player p, boolean enable returns nothing
    local integer pid = GetPlayerId(p)
    
    set PlayerEnabled[pid] = enable
    
    if enable then
        call Debug("Enabled for Player " + I2S(pid + 1))
        call UpdateCameraBoundsForPlayer(p)
    else
        call Debug("Disabled for Player " + I2S(pid + 1))
        // Reset to full map bounds
        call SetPlayerCameraBounds(p, MapMinX, MapMinY, MapMaxX, MapMaxY)
    endif
endfunction

// Set custom bounds size (world coordinates)
public function SetSize takes player p, real width, real height returns nothing
    local integer pid = GetPlayerId(p)
    
    // Validate size
    if width < MIN_BOUNDS_SIZE then
        set width = MIN_BOUNDS_SIZE
    endif
    if height < MIN_BOUNDS_SIZE then
        set height = MIN_BOUNDS_SIZE
    endif
    
    set BoundsWidth[pid] = width
    set BoundsHeight[pid] = height
    
    call Debug("Player " + I2S(pid + 1) + " bounds: " + R2S(width) + "x" + R2S(height))
    
    // Update immediately if enabled
    if PlayerEnabled[pid] then
        call UpdateCameraBoundsForPlayer(p)
    endif
endfunction

// Set preset bounds size
public function SetPreset takes player p, string preset returns nothing
    local integer pid = GetPlayerId(p)
    local real width
    local real height
    
    if preset == "small" then
        set width = PRESET_SMALL_WIDTH
        set height = PRESET_SMALL_HEIGHT
    elseif preset == "medium" then
        set width = PRESET_MEDIUM_WIDTH
        set height = PRESET_MEDIUM_HEIGHT
    elseif preset == "large" then
        set width = PRESET_LARGE_WIDTH
        set height = PRESET_LARGE_HEIGHT
    elseif preset == "xlarge" then
        set width = PRESET_XLARGE_WIDTH
        set height = PRESET_XLARGE_HEIGHT
    elseif preset == "full" then
        set width = MapWidth
        set height = MapHeight
    else
        call Debug("Unknown preset: " + preset)
        return
    endif
    
    call SetSize(p, width, height)
endfunction

// Set padding (extra space around camera)
public function SetPadding takes player p, real paddingX, real paddingY returns nothing
    local integer pid = GetPlayerId(p)
    
    set PaddingX[pid] = paddingX
    set PaddingY[pid] = paddingY
    
    // Update immediately if enabled
    if PlayerEnabled[pid] then
        call UpdateCameraBoundsForPlayer(p)
    endif
endfunction

// Reset player to full map bounds
public function Reset takes player p returns nothing
    local integer pid = GetPlayerId(p)
    
    set PlayerEnabled[pid] = false
    set BoundsWidth[pid] = MapWidth
    set BoundsHeight[pid] = MapHeight
    set PaddingX[pid] = 0.0
    set PaddingY[pid] = 0.0
    
    call SetPlayerCameraBounds(p, MapMinX, MapMinY, MapMaxX, MapMaxY)
    call Debug("Player " + I2S(pid + 1) + " reset to full map")
endfunction

// Set update interval (how often to check camera position)
public function SetUpdateInterval takes real interval returns nothing
    if interval < 0.03 then
        set interval = 0.03  // Minimum safe interval
    endif
    
    set UpdateInterval = interval
    
    // Restart timer with new interval
    call PauseTimer(UpdateTimer)
    call TimerStart(UpdateTimer, UpdateInterval, true, function UpdateAllPlayers)
    
    call Debug("Update interval: " + R2S(interval) + "s")
endfunction

// Query: Get current bounds width for player
public function GetBoundsWidth takes player p returns real
    return BoundsWidth[GetPlayerId(p)]
endfunction

// Query: Get current bounds height for player
public function GetBoundsHeight takes player p returns real
    return BoundsHeight[GetPlayerId(p)]
endfunction

// Enable for all players at once
public function EnableAll takes boolean enable returns nothing
    local integer i = 0
    
    loop
        exitwhen i >= 12
        if GetPlayerController(Player(i)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING then
            call Enable(Player(i), enable)
        endif
        set i = i + 1
    endloop
endfunction

// Set same size for all players
public function SetSizeAll takes real width, real height returns nothing
    local integer i = 0
    
    loop
        exitwhen i >= 12
        if GetPlayerController(Player(i)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING then
            call SetSize(Player(i), width, height)
        endif
        set i = i + 1
    endloop
endfunction

// Set same preset for all players
public function SetPresetAll takes string preset returns nothing
    local integer i = 0
    
    loop
        exitwhen i >= 12
        if GetPlayerController(Player(i)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING then
            call SetPreset(Player(i), preset)
        endif
        set i = i + 1
    endloop
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================

private function Init takes nothing returns nothing
    local integer i = 0
    local player p
    
    // Get map bounds
    call GetMapBounds()
    
    // Initialize player data
    loop
        exitwhen i >= 12
        set p = Player(i)
        
        set PlayerEnabled[i] = false
        set BoundsWidth[i] = DEFAULT_BOUNDS_WIDTH
        set BoundsHeight[i] = DEFAULT_BOUNDS_HEIGHT
        set PaddingX[i] = 0.0
        set PaddingY[i] = 0.0
        set LastCameraX[i] = 0.0
        set LastCameraY[i] = 0.0
        
        if GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING then
            set ActivePlayers = ActivePlayers + 1
        endif
        
        set i = i + 1
    endloop
    
    // Start update timer
    set UpdateTimer = CreateTimer()
    call TimerStart(UpdateTimer, UpdateInterval, true, function UpdateAllPlayers)
    
    call Debug("System initialized - " + I2S(ActivePlayers) + " active players")
endfunction

endlibrary
