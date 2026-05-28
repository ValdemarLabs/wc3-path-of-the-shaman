library RegionTitles initializer InitRegionTitles

globals
    // CONFIGURATION
    private constant real TITLE_Y = 0.45
    private constant real TITLE_FADE_IN_TIME = 1.2
    private constant real TITLE_DURATION = 4.0
    private constant real TITLE_FADE_OUT_TIME = 3.0

    private framehandle titleFrame = null
    private real titleTime = 0.0
    private boolean fadeActive = false
    private string lastPopup = ""
endglobals

// Public function to show a region title with fade
function ShowRegionTitle takes string title returns nothing
    if lastPopup == title and fadeActive then
        return
    endif
    set lastPopup = title
    set titleTime = 0.0
    set fadeActive = true
    call BlzFrameSetText(titleFrame, title)
    call BlzFrameSetVisible(titleFrame, true)
    call BlzFrameSetAlpha(titleFrame, 0)
endfunction


private function HideTitle takes nothing returns nothing
    call BlzFrameSetVisible(titleFrame, false)
    set fadeActive = false
endfunction


private function FadeTitle takes nothing returns nothing
    if not fadeActive then
        return
    endif
    set titleTime = titleTime + 0.03
    if titleTime < TITLE_FADE_IN_TIME then
        call BlzFrameSetAlpha(titleFrame, R2I(255 * (titleTime / TITLE_FADE_IN_TIME)))
    elseif titleTime < TITLE_FADE_IN_TIME + TITLE_DURATION then
        call BlzFrameSetAlpha(titleFrame, 255)
    elseif titleTime < TITLE_FADE_IN_TIME + TITLE_DURATION + TITLE_FADE_OUT_TIME then
        call BlzFrameSetAlpha(titleFrame, R2I(255 * (1 - (titleTime - TITLE_FADE_IN_TIME - TITLE_DURATION) / TITLE_FADE_OUT_TIME)))
    else
        call HideTitle()
    endif
endfunction

private function Periodic takes nothing returns nothing
    call FadeTitle()
endfunction

// ParentFunc who you want as parent, this runs at InitBlizzard, if you need more control you need to modify the part that calls local function Init()
private function ParentFunc takes nothing returns framehandle
    return BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
endfunction

private function InitRegionTitles takes nothing returns nothing
    // Load custom frame definition
    call BlzLoadTOCFile("RegionTitle.toc")  

    // Create title frame
    set titleFrame = BlzCreateFrameByType("TEXT", "RegionTitle", ParentFunc(), "", 0)
    if GetHandleId(titleFrame) == 0 then
        call BJDebugMsg("Error - RegionTitle Create")
        call BJDebugMsg("Check Imported toc & fdf file")
    endif
    call BlzFrameSetAbsPoint(titleFrame, FRAMEPOINT_CENTER, 0.4, TITLE_Y)
    call BlzFrameSetSize(titleFrame, 0.4, 0.06)
    call BlzFrameSetTextAlignment(titleFrame, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetVisible(titleFrame, false)
    // Periodic for fade
    call TimerStart(CreateTimer(), 0.03, true, function Periodic)
endfunction

endlibrary