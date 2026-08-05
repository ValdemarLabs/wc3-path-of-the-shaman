library MinimapToggle initializer Init
//===========================================================================
/*
    Minimap Toggle - Press ESC to enlarge minimap to center screen
    
    Features:
    - Press ESC to toggle between normal and enlarged minimap
    - Normal: bottom-left corner, standard size
    - Enlarged: center screen, 3x larger
    
    Works with RPGMinimapTexture or standalone
*/
//===========================================================================

globals
    private constant boolean DEBUG = true
    
    // Normal position (bottom-left)
    private constant real NORMAL_X = 0.020
    private constant real NORMAL_Y = 0.009
    private constant real NORMAL_WIDTH = 0.15
    private constant real NORMAL_HEIGHT = 0.15
    
    // Enlarged position (center screen)
    private constant real ENLARGED_X = 0.2875  // (0.8 - 0.45) / 2
    private constant real ENLARGED_Y = 0.175   // (0.6 - 0.45) / 2
    private constant real ENLARGED_WIDTH = 0.45
    private constant real ENLARGED_HEIGHT = 0.45
    
    private framehandle minimapFrame = null
    private boolean isEnlarged = false
    private trigger escTrigger = null
endglobals

//===========================================================================
// Toggle Function
//===========================================================================
private function ToggleMinimap takes nothing returns nothing
    local framehandle gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    
    if minimapFrame == null then
        return
    endif
    
    set isEnlarged = not isEnlarged
    
    call BlzFrameClearAllPoints(minimapFrame)
    
    if isEnlarged then
        // Enlarge to center
        call BlzFrameSetPoint(minimapFrame, FRAMEPOINT_CENTER, gameUI, FRAMEPOINT_CENTER, 0, 0)
        call BlzFrameSetSize(minimapFrame, ENLARGED_WIDTH, ENLARGED_HEIGHT)
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap enlarged to center|r")
        endif
    else
        // Back to normal (bottom-left)
        call BlzFrameSetPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, gameUI, FRAMEPOINT_BOTTOMLEFT, NORMAL_X, NORMAL_Y)
        call BlzFrameSetSize(minimapFrame, NORMAL_WIDTH, NORMAL_HEIGHT)
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00Minimap restored to normal|r")
        endif
    endif
endfunction

//===========================================================================
// ESC Key Detection
//===========================================================================
private function OnEscPressed takes nothing returns nothing
    call ToggleMinimap()
endfunction

private function SetupEscTrigger takes nothing returns nothing
    local integer i
    
    set escTrigger = CreateTrigger()
    
    // Register ESC key (OSKEY_ESCAPE) for all players
    for i = 0 to 11
        if GetPlayerController(Player(i)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING then
            call BlzTriggerRegisterPlayerKeyEvent(escTrigger, Player(i), OSKEY_ESCAPE, 0, false)
        endif
    endfor
    
    call TriggerAddAction(escTrigger, function OnEscPressed)
endfunction

//===========================================================================
// Public API
//===========================================================================
function MinimapToggle_Toggle takes nothing returns nothing
    call ToggleMinimap()
endfunction

function MinimapToggle_IsEnlarged takes nothing returns boolean
    return isEnlarged
endfunction

function MinimapToggle_SetEnlarged takes boolean enlarged returns nothing
    if enlarged != isEnlarged then
        call ToggleMinimap()
    endif
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function Init takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("|cffFFFF00MinimapToggle: Starting initialization...|r")
    endif
    
    // Get the native minimap frame
    set minimapFrame = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    
    if minimapFrame != null then
        // Set to normal position initially
        call BlzFrameClearAllPoints(minimapFrame)
        call BlzFrameSetPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), FRAMEPOINT_BOTTOMLEFT, NORMAL_X, NORMAL_Y)
        call BlzFrameSetSize(minimapFrame, NORMAL_WIDTH, NORMAL_HEIGHT)
        
        // Setup ESC key trigger
        call SetupEscTrigger()
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00MinimapToggle: Initialized successfully!|r")
            call BJDebugMsg("|cffAAAAFFPress ESC to toggle minimap size|r")
        endif
    else
        if DEBUG then
            call BJDebugMsg("|cffFF0000MinimapToggle: ERROR - Could not find minimap frame!|r")
        endif
    endif
endfunction

endlibrary
