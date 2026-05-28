// ============================================================
// GatherNodeDebug - Gather Node Debug Commands
// ============================================================
//
// Kept as a separate library/file to avoid mixed-library load-order ambiguity
// while debugging map-load issues.
//
// ============================================================

library GatherNodeDebug initializer Init requires GatherNodes, GatherNodeItems, GatherNodeUnits

globals
    private trigger GND_DebugChatTrigger = null
    private trigger GND_SelectTrigger = null
    private unit GND_LastSelectedUnit = null
endglobals

private function GND_BoolToString takes boolean b returns string
    if b then
        return "true"
    endif
    return "false"
endfunction

private function GND_RefreshAllNodes takes nothing returns nothing
    if not GN_IsSystemEnabled() then
        call BJDebugMsg("|cffff0000[GatherNodes]|r Refresh aborted: system is disabled")
        return
    endif

    call BJDebugMsg("|cff00ff00[GatherNodes]|r Refreshing all gather nodes...")
    call GNI_DebugRefreshAll()
    call GNU_DebugRefreshAll()
    call BJDebugMsg("|cff00ff00[GatherNodes]|r Refresh complete")
endfunction

private function GND_RefreshItemNodes takes nothing returns nothing
    if not GN_IsSystemEnabled() then
        call BJDebugMsg("|cffff0000[GatherNodes]|r Item refresh aborted: system is disabled")
        return
    endif

    call BJDebugMsg("|cff00ff00[GatherNodes]|r Refreshing item gather nodes...")
    call GNI_DebugRefreshAll()
    call BJDebugMsg("|cff00ff00[GatherNodes]|r Item refresh complete")
endfunction

private function GND_RefreshUnitNodes takes nothing returns nothing
    if not GN_IsSystemEnabled() then
        call BJDebugMsg("|cffff0000[GatherNodes]|r Unit refresh aborted: system is disabled")
        return
    endif

    call BJDebugMsg("|cff00ff00[GatherNodes]|r Refreshing unit gather nodes...")
    call GNU_DebugRefreshAll()
    call BJDebugMsg("|cff00ff00[GatherNodes]|r Unit refresh complete")
endfunction

private function GND_GlowTestSelectedUnit takes nothing returns nothing
    local integer handleId

    if GND_LastSelectedUnit == null then
        call BJDebugMsg("|cffff8800[GatherNodes]|r Glow test aborted: no unit selected")
        return
    endif

    set handleId = GetHandleId(GND_LastSelectedUnit)
    call GN_ApplyGlowEffect(GND_LastSelectedUnit, 255, 180, 0, 200, 1.2, 0.0)
    call BJDebugMsg("|cff00ff00[GatherNodes]|r Glow test applied to selected unit: " + GetUnitName(GND_LastSelectedUnit) + " (handle " + I2S(handleId) + ", tracked=" + GND_BoolToString(GN_HasGlowOnHandle(GND_LastSelectedUnit)) + ")")
endfunction

private function GND_ClearGlowTestSelectedUnit takes nothing returns nothing
    local integer handleId
    local boolean hadGlow

    if GND_LastSelectedUnit == null then
        call BJDebugMsg("|cffff8800[GatherNodes]|r Glow clear aborted: no unit selected")
        return
    endif

    set handleId = GetHandleId(GND_LastSelectedUnit)
    set hadGlow = GN_HasGlowOnHandle(GND_LastSelectedUnit)
    call GN_RemoveGlowEffect(GND_LastSelectedUnit)
    call BJDebugMsg("|cff00ff00[GatherNodes]|r Glow test cleared from selected unit: " + GetUnitName(GND_LastSelectedUnit) + " (handle " + I2S(handleId) + ", hadTrackedGlow=" + GND_BoolToString(hadGlow) + ", trackedNow=" + GND_BoolToString(GN_HasGlowOnHandle(GND_LastSelectedUnit)) + ")")
endfunction

private function GND_OnUnitSelected takes nothing returns nothing
    set GND_LastSelectedUnit = GetTriggerUnit()
endfunction

private function GND_OnPlayerChat takes nothing returns nothing
    local string msg = GetEventPlayerChatString()

    if not GN_IsDebugMode() then
        return
    endif

    if msg == "/gathernodes refresh" then
        call GND_RefreshAllNodes()
    elseif msg == "/gathernodes refresh items" then
        call GND_RefreshItemNodes()
    elseif msg == "/gathernodes refresh units" then
        call GND_RefreshUnitNodes()
    elseif msg == "/gathernodes glowtest" then
        call GND_GlowTestSelectedUnit()
    elseif msg == "/gathernodes glowclear" then
        call GND_ClearGlowTestSelectedUnit()
    endif
endfunction

private function GND_RegisterChatCommands takes nothing returns nothing
    set GND_DebugChatTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(GND_DebugChatTrigger, Player(0), "", false)
    call TriggerAddAction(GND_DebugChatTrigger, function GND_OnPlayerChat)
endfunction

private function GND_RegisterSelectionTracking takes nothing returns nothing
    set GND_SelectTrigger = CreateTrigger()
    call TriggerRegisterPlayerUnitEvent(GND_SelectTrigger, Player(0), EVENT_PLAYER_UNIT_SELECTED, null)
    call TriggerAddAction(GND_SelectTrigger, function GND_OnUnitSelected)
endfunction

private function Init takes nothing returns nothing
    if not GN_IsDebugMode() then
        return
    endif

    call GND_RegisterChatCommands()
    call GND_RegisterSelectionTracking()

    call BJDebugMsg("|cff00ff00[GatherNodes]|r Debug commands: /gathernodes refresh, /gathernodes refresh items, /gathernodes refresh units, /gathernodes glowtest, /gathernodes glowclear")
endfunction

endlibrary
