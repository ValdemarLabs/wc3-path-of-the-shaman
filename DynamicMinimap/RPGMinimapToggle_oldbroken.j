library RPGMinimapToggle initializer Init
//===========================================================================
/*
    RPG Minimap Toggle - Enlarged Minimap Overlay
    
    Provides a large centered minimap that can be toggled with ESC key.
    Normal minimap remains in corner for regular gameplay.
    
    Features:
    - Press ESC to show/hide large centered minimap
    - Pauses game when enlarged minimap is shown
    - Shows full map detail with zoom control
    - Easy to use - no texture imports needed
    
    API:
        RPGMinimapToggle_Show(player, enable) - Show/hide for specific player
        RPGMinimapToggle_SetSize(width, height) - Adjust enlarged minimap size
        RPGMinimapToggle_SetZoom(scale) - Adjust zoom level (1.0 = full map)
*/
//===========================================================================

globals
    private constant boolean DEBUG = true
    private constant real LARGE_SIZE = 0.50      // 50% of screen
    private constant real SCREEN_CENTER_X = 0.40
    private constant real SCREEN_CENTER_Y = 0.00
    private constant integer MINIMAP_ALPHA = 255 // 0-255, 255 = opaque, 128 = 50% transparent
    
    private framehandle minimapFrame = null
    private framehandle backdropFrame = null
    private boolean array isShowing
    private trigger array escTrigger
    // Store original minimap positions to restore them
    private boolean minimapCleared = false
endglobals

//===========================================================================
// Toggle Functions
//===========================================================================
private function ToggleMinimap takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    
    set isShowing[pid] = not isShowing[pid]
    
    // Pause/unpause must be outside GetLocalPlayer to avoid desync
    if isShowing[pid] then
        call PauseGame(true)
    else
        call PauseGame(false)
    endif
    
    if GetLocalPlayer() == whichPlayer then
        if isShowing[pid] then
            // Enlarge and center the minimap
            call BlzFrameSetVisible(backdropFrame, true)
            if not minimapCleared then
                call BlzFrameClearAllPoints(minimapFrame)
                set minimapCleared = true
            endif
            call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, SCREEN_CENTER_X - (LARGE_SIZE/2), SCREEN_CENTER_Y - (LARGE_SIZE/2))
            call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_TOPRIGHT, SCREEN_CENTER_X + (LARGE_SIZE/2), SCREEN_CENTER_Y + (LARGE_SIZE/2))
        else
            // Return to normal - use both corners to resize properly
            call BlzFrameSetVisible(backdropFrame, false)
            call BlzFrameClearAllPoints(minimapFrame)
            // Top-right corner, 0.125x0.125 size
            call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_TOPRIGHT, 0.8, 0.6)
            call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, 0.8 - 0.125, 0.6 - 0.125)
        endif
    endif
    
    if DEBUG then
        if isShowing[pid] then
            call DisplayTextToPlayer(whichPlayer, 0, 0, "Large minimap: ON")
        else
            call DisplayTextToPlayer(whichPlayer, 0, 0, "Large minimap: OFF")
        endif
    endif
endfunction

private function OnEscPressed takes nothing returns boolean
    call ToggleMinimap(GetTriggerPlayer())
    return false
endfunction

//===========================================================================
// Public API
//===========================================================================
function RPGMinimapToggle_Show takes player whichPlayer, boolean enable returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    
    if enable != isShowing[pid] then
        call ToggleMinimap(whichPlayer)
    endif
endfunction

function RPGMinimapToggle_SetSize takes real width, real height returns nothing
    // Not applicable with this approach - size is controlled by positioning
endfunction

function RPGMinimapToggle_SetZoom takes real scale returns nothing
    if minimapFrame != null then
        call BlzFrameSetScale(minimapFrame, scale)
    endif
endfunction

function RPGMinimapToggle_SetAlpha takes integer alpha returns nothing
    if minimapFrame != null then
        call BlzFrameSetAlpha(minimapFrame, alpha)
    endif
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function Init takes nothing returns nothing
    local framehandle gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    local integer i = 0
    local player p
    
    if DEBUG then
        call BJDebugMsg("|cffFFFF00RPGMinimapToggle: Starting initialization...|r")
    endif
    
    // Get the native minimap frame
    set minimapFrame = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    
    // According to Tasyen's tutorial, clear points once at init for proper control
    // The minimap default position is at top-right corner
    // WC3 coords: 0,0 = bottom-left, 0.8,0.6 = top-right
    // Default minimap is 0.125x0.125 in size at top-right
    call BlzFrameClearAllPoints(minimapFrame)
    set minimapCleared = true
    
    // Set to normal position using both corners (this is the key from the tutorial)
    // Place at top-right corner with 0.125 size
    call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_TOPRIGHT, 0.8, 0.6)
    call BlzFrameSetAbsPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, 0.8 - 0.125, 0.6 - 0.125)
    
    // Set minimap transparency
    call BlzFrameSetAlpha(minimapFrame, MINIMAP_ALPHA)
    
    // Create backdrop (dark background)
    set backdropFrame = BlzCreateFrame("BACKDROP", gameUI, 0, 0)
    call BlzFrameSetSize(backdropFrame, LARGE_SIZE + 0.02, LARGE_SIZE + 0.02)
    call BlzFrameSetAbsPoint(backdropFrame, FRAMEPOINT_CENTER, SCREEN_CENTER_X, SCREEN_CENTER_Y)
    call BlzFrameSetTexture(backdropFrame, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
    call BlzFrameSetAlpha(backdropFrame, 200)
    call BlzFrameSetVisible(backdropFrame, false)
    call BlzFrameSetLevel(backdropFrame, 9)
    
    // Set minimap level above backdrop
    call BlzFrameSetLevel(minimapFrame, 10)
    
    // Setup ESC key trigger for each player
    loop
        exitwhen i >= 12
        set p = Player(i)
        
        if GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING then
            set escTrigger[i] = CreateTrigger()
            call TriggerRegisterPlayerEvent(escTrigger[i], p, EVENT_PLAYER_END_CINEMATIC)
            call TriggerAddCondition(escTrigger[i], Filter(function OnEscPressed))
            set isShowing[i] = false
        endif
        
        set i = i + 1
    endloop
    
    if DEBUG then
        call BJDebugMsg("|cff00ff00RPGMinimapToggle: Initialized|r")
        call BJDebugMsg("|cffAAFFAA  Press ESC to toggle large minimap|r")
    endif
endfunction

endlibrary
