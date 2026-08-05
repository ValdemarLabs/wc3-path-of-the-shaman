//===========================================================================
// DynamicMinimap - GUI Template Triggers
// Copy these triggers to your map and customize as needed
//===========================================================================

//===========================================================================
// SETUP: Initialize Minimap Settings (Run at Map Init)
//===========================================================================
function Trig_Minimap_Setup_Actions takes nothing returns nothing
    // Optional: Change chunk size (default 32)
    // call DynamicMinimap_SetChunkSize(32)
    
    // Optional: Change grid step/threshold (default 8, lower = more sensitive)
    call DynamicMinimap_SetGridStep(4)
    
    // Optional: Configure enlarged minimap position (0.0-1.0, default center: 0.4, 0.3)
    // call DynamicMinimap_SetEnlargedPosition(0.4, 0.3)
    
    // Optional: Configure enlarged minimap scale (default 3.0x)
    // call DynamicMinimap_SetEnlargedScale(3.0)
    
    // Optional: Change toggle hotkey (default ESC)
    // call DynamicMinimap_SetToggleKey(OSKEY_M)  // Press M to toggle
    
    call DisplayTextToForce(GetPlayersAll(), "|cff00ff00Minimap System: Ready|r")
endfunction

//===========================================================================
// TRIGGER: Toggle Minimap Size (Manual Button/Hotkey)
//===========================================================================
// Events: Player 1 (Red) presses ESC key (or custom key)
// Note: ESC is already registered by default, this is for additional custom triggers
function Trig_Minimap_Toggle_Actions takes nothing returns nothing
    // Check current state
    if DynamicMinimap_GetMinimapEnlarged() then
        call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cffffcc00Minimap: Normal size|r")
    else
        call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cffffcc00Minimap: Enlarged|r")
    endif
    // Note: Toggle happens automatically via built-in ESC key handler
endfunction

//===========================================================================
// TRIGGER: Hide Minimap (e.g., during cinematic)
//===========================================================================
function Trig_Minimap_Hide_Actions takes nothing returns nothing
    call DynamicMinimap_SetVisible(false)
    call DisplayTextToForce(GetPlayersAll(), "|cffff8800Minimap: Hidden|r")
endfunction

//===========================================================================
// TRIGGER: Show Minimap (e.g., after cinematic)
//===========================================================================
function Trig_Minimap_Show_Actions takes nothing returns nothing
    call DynamicMinimap_SetVisible(true)
    call DisplayTextToForce(GetPlayersAll(), "|cff00ff00Minimap: Visible|r")
endfunction

//===========================================================================
// TRIGGER: Disable Minimap Updates (e.g., during cinematic)
//===========================================================================
function Trig_Minimap_Disable_Actions takes nothing returns nothing
    call DynamicMinimap_Enable(false)
    call DisplayTextToForce(GetPlayersAll(), "|cffff8800Minimap: Updates disabled|r")
endfunction

//===========================================================================
// TRIGGER: Enable Minimap Updates (e.g., after cinematic)
//===========================================================================
function Trig_Minimap_Enable_Actions takes nothing returns nothing
    call DynamicMinimap_Enable(true)
    call DisplayTextToForce(GetPlayersAll(), "|cff00ff00Minimap: Updates enabled|r")
endfunction

//===========================================================================
// TRIGGER: Switch to Full Map View
//===========================================================================
function Trig_Minimap_FullMap_Actions takes nothing returns nothing
    call DynamicMinimap_SetFullMapMode(true)
    call DisplayTextToForce(GetPlayersAll(), "|cff00ff00Minimap: Full map view|r")
endfunction

//===========================================================================
// TRIGGER: Switch to Chunked View
//===========================================================================
function Trig_Minimap_ChunkedView_Actions takes nothing returns nothing
    call DynamicMinimap_SetFullMapMode(false)
    call DisplayTextToForce(GetPlayersAll(), "|cff00ff00Minimap: Chunked view|r")
endfunction

//===========================================================================
// TRIGGER: Force Minimap Update (Manual refresh)
//===========================================================================
function Trig_Minimap_ForceUpdate_Actions takes nothing returns nothing
    call DynamicMinimap_ForceUpdate()
    call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cff00ff00Minimap: Updated|r")
endfunction

//===========================================================================
// EXAMPLE: Chat Command System
//===========================================================================
function Trig_Minimap_ChatCommands_Actions takes nothing returns nothing
    local string msg = GetEventPlayerChatString()
    
    if msg == "-minimap" or msg == "-m" then
        // Toggle visibility
        if DynamicMinimap_GetVisible() then
            call DynamicMinimap_SetVisible(false)
            call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cffff8800Minimap hidden|r")
        else
            call DynamicMinimap_SetVisible(true)
            call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cff00ff00Minimap shown|r")
        endif
    elseif msg == "-minimap full" then
        call DynamicMinimap_SetFullMapMode(true)
        call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cff00ff00Full map view|r")
    elseif msg == "-minimap chunk" then
        call DynamicMinimap_SetFullMapMode(false)
        call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cff00ff00Chunked view|r")
    elseif msg == "-minimap info" then
        call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "|cffffcc00=== Minimap Status ===|r")
        if DynamicMinimap_GetVisible() then
            call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "Visible: |cff00ff00Yes|r")
        else
            call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "Visible: |cffff0000No|r")
        endif
        if DynamicMinimap_GetMinimapEnlarged() then
            call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "Size: |cff00ff00Enlarged|r")
        else
            call DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "Size: |cffffcc00Normal|r")
        endif
    endif
endfunction

//===========================================================================
// HOW TO IMPORT TO WORLD EDITOR (GUI):
//===========================================================================
/*
    1. Open Trigger Editor in World Editor
    2. Create a new trigger for each function above
    3. Convert to custom text (right-click trigger → Convert to Custom Text)
    4. Copy the corresponding function code
    5. Set appropriate events:
    
    TRIGGER EXAMPLES:
    
    ┌─────────────────────────────────────────────────────────────────
    │ Trigger: Minimap Setup
    │ Events:  Map initialization
    │ Actions: (Copy Trig_Minimap_Setup_Actions content)
    └─────────────────────────────────────────────────────────────────
    
    ┌─────────────────────────────────────────────────────────────────
    │ Trigger: Minimap Hide
    │ Events:  Player - Player 1 (Red) types "-hide" as An exact match
    │ Actions: (Copy Trig_Minimap_Hide_Actions content)
    └─────────────────────────────────────────────────────────────────
    
    ┌─────────────────────────────────────────────────────────────────
    │ Trigger: Minimap Show  
    │ Events:  Player - Player 1 (Red) types "-show" as An exact match
    │ Actions: (Copy Trig_Minimap_Show_Actions content)
    └─────────────────────────────────────────────────────────────────
    
    ┌─────────────────────────────────────────────────────────────────
    │ Trigger: Minimap Chat Commands
    │ Events:  Player - Player 1 (Red) types a chat message as A substring
    │ Actions: (Copy Trig_Minimap_ChatCommands_Actions content)
    └─────────────────────────────────────────────────────────────────
    
    ┌─────────────────────────────────────────────────────────────────
    │ Trigger: Cinematic Start (Disable Minimap)
    │ Events:  Your cinematic start event
    │ Actions: (Copy Trig_Minimap_Disable_Actions content)
    └─────────────────────────────────────────────────────────────────
    
    ┌─────────────────────────────────────────────────────────────────
    │ Trigger: Cinematic End (Enable Minimap)
    │ Events:  Your cinematic end event
    │ Actions: (Copy Trig_Minimap_Enable_Actions content)
    └─────────────────────────────────────────────────────────────────

QUICK REFERENCE - All API Functions:
═══════════════════════════════════════════════════════════════════════

DynamicMinimap_SetChunkSize(integer tiles)
    - Change chunk size (default: 32)
    - Must match your texture chunk files

DynamicMinimap_SetGridStep(integer tiles)  
    - Change update threshold (default: 8)
    - Lower = more frequent updates, Higher = less frequent

DynamicMinimap_Enable(boolean enable)
    - Enable/disable system (stops updates)
    - Useful for cinematics

DynamicMinimap_ForceUpdate()
    - Manually trigger texture/bounds update
    - Call after teleporting units

DynamicMinimap_SetEnlargedPosition(real x, real y)
    - Set enlarged minimap position (0.0-1.0)
    - Default: 0.4, 0.3 (center-ish)

DynamicMinimap_SetEnlargedScale(real scale)
    - Set enlarged minimap scale multiplier
    - Default: 3.0 (3x size)

DynamicMinimap_SetToggleKey(oskeytype key)
    - Change toggle hotkey
    - Default: OSKEY_ESCAPE
    - Examples: OSKEY_M, OSKEY_TAB, OSKEY_F1

DynamicMinimap_GetMinimapEnlarged() returns boolean
    - Check if minimap is currently enlarged
    - Returns: true/false

DynamicMinimap_SetFullMapMode(boolean enable)
    - Switch between full map / chunked view
    - Requires minimap_full.blp texture

DynamicMinimap_SetVisible(boolean visible)
    - Show/hide the minimap
    - true = visible, false = hidden

DynamicMinimap_GetVisible() returns boolean
    - Check if minimap is currently visible
    - Returns: true/false

═══════════════════════════════════════════════════════════════════════
*/
