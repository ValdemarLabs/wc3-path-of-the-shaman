/**
    WidescreenFrameRoot

    Author: Valdemar
    Version: 1.1.0

    Description:
    Creates one zero-sized Leaderboard frame that can parent interactive
    non-simple frames outside Warcraft III's classic 4:3 UI bounds. The
    Leaderboard visuals remain hidden while its frame stays visible so child
    controls can render and receive frame events across the full client width.

    Credits:
    - Tasyen, documented Leaderboard-parent widescreen frame technique

    How to install:
    Import before any UI library that requires WidescreenFrameRoot. The owner
    leaderboard must not be destroyed while child frames are active.

    API:
    - set root = WidescreenFrameRoot_Get()
    - call WidescreenFrameRoot_Refresh()
    - set width = WidescreenFrameRoot_GetClientUIWidth()
    - set left = WidescreenFrameRoot_GetClientLeft()
    - set right = WidescreenFrameRoot_GetClientRight()

**/
library WidescreenFrameRoot initializer Init

globals
    private constant real WFR_UI_HEIGHT = 0.600
    private constant real WFR_UI_CENTER_X = 0.400

    private leaderboard WFR_Owner = null
    private framehandle WFR_Root = null
    private framehandle WFR_Backdrop = null
    private framehandle WFR_Title = null
endglobals

private function WFR_Ensure takes nothing returns nothing
    if WFR_Root != null then
        return
    endif

    set WFR_Owner = CreateLeaderboard()
    call LeaderboardSetLabel(WFR_Owner, "")
    call LeaderboardDisplay(WFR_Owner, true)
    set WFR_Root = BlzGetFrameByName("Leaderboard", 0)
    set WFR_Backdrop = BlzGetFrameByName("LeaderboardBackdrop", 0)
    set WFR_Title = BlzGetFrameByName("LeaderboardTitle", 0)

    if WFR_Root == null then
        set WFR_Root = BlzGetFrameByName("ConsoleUIBackdrop", 0)
    endif
    if WFR_Root == null then
        set WFR_Root = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    endif

    call BlzFrameSetSize(WFR_Root, 0.0001, 0.0001)
    call BlzFrameSetVisible(WFR_Root, true)
    if WFR_Backdrop != null then
        call BlzFrameSetVisible(WFR_Backdrop, false)
    endif
    if WFR_Title != null then
        call BlzFrameSetVisible(WFR_Title, false)
    endif
endfunction

public function Refresh takes nothing returns nothing
    call WFR_Ensure()
    call BlzFrameSetVisible(WFR_Root, true)
    if WFR_Backdrop != null then
        call BlzFrameSetVisible(WFR_Backdrop, false)
    endif
    if WFR_Title != null then
        call BlzFrameSetVisible(WFR_Title, false)
    endif
endfunction

public function Get takes nothing returns framehandle
    call WFR_Ensure()
    return WFR_Root
endfunction

public function GetClientUIWidth takes nothing returns real
    local integer clientWidth = BlzGetLocalClientWidth()
    local integer clientHeight = BlzGetLocalClientHeight()

    if clientHeight <= 0 then
        return 0.800
    endif
    return I2R(clientWidth) / I2R(clientHeight) * WFR_UI_HEIGHT
endfunction

public function GetClientLeft takes nothing returns real
    local real width = GetClientUIWidth()

    if width < 0.800 then
        set width = 0.800
    endif
    return WFR_UI_CENTER_X - width * 0.50
endfunction

public function GetClientRight takes nothing returns real
    local real width = GetClientUIWidth()

    if width < 0.800 then
        set width = 0.800
    endif
    return WFR_UI_CENTER_X + width * 0.50
endfunction

private function Init takes nothing returns nothing
    call WFR_Ensure()
endfunction

endlibrary
