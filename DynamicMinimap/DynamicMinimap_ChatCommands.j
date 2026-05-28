library DynamicMinimapChatCommands initializer Init requires DynamicMinimap
//===========================================================================
// DynamicMinimap - Chat Command System
// Complete JASS implementation for tracking player chat commands
// 
// IMPORTANT: This library must be placed AFTER DynamicMinimap.j in your map script
//===========================================================================

globals
    private trigger chatTrigger = null
endglobals

//===========================================================================
// Chat Command Handler
//===========================================================================
private function OnChatCommand takes nothing returns nothing
    local string msg = GetEventPlayerChatString()
    local player p = GetTriggerPlayer()
    
    if msg == "-minimap" or msg == "-m" then
        // Toggle visibility
        if DynamicMinimap_GetVisible() then
            call DynamicMinimap_SetVisible(false)
            call DisplayTextToPlayer(p, 0, 0, "|cffff8800Minimap hidden|r")
        else
            call DynamicMinimap_SetVisible(true)
            call DisplayTextToPlayer(p, 0, 0, "|cff00ff00Minimap shown|r")
        endif
        
    elseif msg == "-minimap full" then
        call DynamicMinimap_SetFullMapMode(true)
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00Full map view|r")
        
    elseif msg == "-minimap chunk" then
        call DynamicMinimap_SetFullMapMode(false)
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00Chunked view|r")
        
    elseif msg == "-minimap update" then
        call DynamicMinimap_ForceUpdate()
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00Minimap updated|r")
        
    elseif msg == "-minimap info" then
        call DisplayTextToPlayer(p, 0, 0, "|cffffcc00=== Minimap Status ===|r")
        if DynamicMinimap_GetVisible() then
            call DisplayTextToPlayer(p, 0, 0, "Visible: |cff00ff00Yes|r")
        else
            call DisplayTextToPlayer(p, 0, 0, "Visible: |cffff0000No|r")
        endif
        if DynamicMinimap_GetMinimapEnlarged() then
            call DisplayTextToPlayer(p, 0, 0, "Size: |cff00ff00Enlarged|r")
        else
            call DisplayTextToPlayer(p, 0, 0, "Size: |cffffcc00Normal|r")
        endif
        
    elseif msg == "-minimap help" then
        call DisplayTextToPlayer(p, 0, 0, "|cffffcc00=== Minimap Commands ===|r")
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00-minimap|r or |cff00ff00-m|r - Toggle visibility")
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00-minimap full|r - Full map view")
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00-minimap chunk|r - Chunked view")
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00-minimap update|r - Force update")
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00-minimap info|r - Show status")
        call DisplayTextToPlayer(p, 0, 0, "|cff00ff00-minimap help|r - Show this help")
    endif
endfunction

//===========================================================================
// Initialization - Register chat events for all players
//===========================================================================
private function Init takes nothing returns nothing
    local integer i = 0
    
    set chatTrigger = CreateTrigger()
    
    // Register chat events for all players (0-11)
    loop
        exitwhen i > 11
        call TriggerRegisterPlayerChatEvent(chatTrigger, Player(i), "-minimap", false)
        call TriggerRegisterPlayerChatEvent(chatTrigger, Player(i), "-m", false)
        set i = i + 1
    endloop
    
    call TriggerAddAction(chatTrigger, function OnChatCommand)
    
    call DisplayTextToForce(GetPlayersAll(), "|cff00ff00Minimap chat commands enabled. Type |cffffcc00-minimap help|r")
endfunction

endlibrary
