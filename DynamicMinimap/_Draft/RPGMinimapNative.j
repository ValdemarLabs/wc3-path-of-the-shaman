library RPGMinimapNative initializer Init
//===========================================================================
/*
    RPG Minimap - Native Minimap Frame Positioning
    
    Repositions and resizes the native WC3 minimap frame.
    Works together with RPGMinimapTexture for dynamic texture swapping.
    
    Features:
    - Repositioned minimap to bottom-left
    - Customizable size
    - Shows native WC3 minimap with terrain
    
    Note: Camera bounds are handled by RPGMinimapTexture library
    
    API:
        RPGMinimapNative_SetPosition(x, y, width, height)
        RPGMinimapNative_Show(enable)
*/
//===========================================================================

globals
    private constant boolean DEBUG = true
    private constant real MINIMAP_X = 0.020
    private constant real MINIMAP_Y = 0.009
    private constant real MINIMAP_WIDTH = 0.15
    private constant real MINIMAP_HEIGHT = 0.15
    
    private framehandle minimapFrame = null
    private framehandle minimapBorder = null
    private framehandle minimapButtons = null
endglobals

//===========================================================================
// Public API
//===========================================================================
function RPGMinimapNative_SetPosition takes real x, real y, real width, real height returns nothing
    if minimapFrame != null then
        call BlzFrameClearAllPoints(minimapFrame)
        call BlzFrameSetPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), FRAMEPOINT_BOTTOMLEFT, x, y)
        call BlzFrameSetSize(minimapFrame, width, height)
    endif
endfunction

function RPGMinimapNative_Show takes boolean enable returns nothing
    if minimapFrame != null then
        call BlzFrameSetVisible(minimapFrame, enable)
    endif
    if minimapBorder != null then
        call BlzFrameSetVisible(minimapBorder, enable)
    endif
    if minimapButtons != null then
        call BlzFrameSetVisible(minimapButtons, enable)
    endif
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function Init takes nothing returns nothing
    local framehandle gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    
    if DEBUG then
        call BJDebugMsg("|cffFFFF00RPGMinimapNative: Starting initialization...|r")
    endif
    
    // Get the native minimap frame
    set minimapFrame = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    
    // Try to get border and buttons (these may not exist in all versions)
    set minimapBorder = BlzGetFrameByName("MiniMapFrame", 0)
    set minimapButtons = BlzGetFrameByName("MinimapFrame", 0)
    
    if minimapFrame != null then
        // Clear existing positioning
        call BlzFrameClearAllPoints(minimapFrame)
        
        // Reposition to bottom-left
        call BlzFrameSetPoint(minimapFrame, FRAMEPOINT_BOTTOMLEFT, gameUI, FRAMEPOINT_BOTTOMLEFT, MINIMAP_X, MINIMAP_Y)
        
        // Resize
        call BlzFrameSetSize(minimapFrame, MINIMAP_WIDTH, MINIMAP_HEIGHT)
        
        // Make sure it's visible
        call BlzFrameSetVisible(minimapFrame, true)
        
        if DEBUG then
            call BJDebugMsg("|cff00ff00RPGMinimapNative: Minimap repositioned to (" + R2S(MINIMAP_X) + ", " + R2S(MINIMAP_Y) + ")|r")
            call BJDebugMsg("|cff00ff00RPGMinimapNative: Size set to " + R2S(MINIMAP_WIDTH) + "x" + R2S(MINIMAP_HEIGHT) + "|r")
        endif
    else
        if DEBUG then
            call BJDebugMsg("|cffFF0000RPGMinimapNative: ERROR - Could not find minimap frame!|r")
        endif
    endif
    
    // Also reposition border if it exists
    if minimapBorder != null then
        call BlzFrameClearAllPoints(minimapBorder)
        call BlzFrameSetPoint(minimapBorder, FRAMEPOINT_BOTTOMLEFT, gameUI, FRAMEPOINT_BOTTOMLEFT, MINIMAP_X - 0.005, MINIMAP_Y - 0.005)
        call BlzFrameSetSize(minimapBorder, MINIMAP_WIDTH + 0.01, MINIMAP_HEIGHT + 0.01)
    endif
    
    if DEBUG then
        call BJDebugMsg("|cff00ff00RPGMinimapNative: Initialized successfully!|r")
    endif
endfunction

endlibrary
