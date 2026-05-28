library RegionTitles initializer InitRegionTitles

globals
    // CONFIGURATION
    private constant real TITLE_Y = 0.45
    private constant real TITLE_FADE_IN_TIME = 1.2
    private constant real TITLE_DURATION = 4.0
    private constant real TITLE_FADE_OUT_TIME = 3.0

    private constant real SMALLTEXT_FADE_IN_TIME = 1.0
    private constant real SMALLTEXT_DURATION = 2.5
    private constant real SMALLTEXT_FADE_OUT_TIME = 1.5

    private constant real MAINTITLE_FADE_IN_TIME = 1.2
    private constant real MAINTITLE_DURATION = 4.0
    private constant real MAINTITLE_FADE_OUT_TIME = 3.0

    private framehandle titleFrame1 = null
    private framehandle Text02 = null
    private real titleTime = 0.0
    private real smallTextTime = 0.0
    private boolean fadeActive = false
    private boolean smallTextActive = false
    private boolean titleActive = false
    private string lastPopupMain = ""
    private string lastPopupSmall = ""
    private real textScale = 3.14
    private real textSmallScale = 1.5
    private real textSmallScale2 = 1.5

    // API: ShowSingleLineText
    // Shows a single line of text with fade in, duration, fade out, and scale.
    // text: the string to display
    // fadeIn: fade in time (seconds)
    // duration: time fully visible (seconds)
    // fadeOut: fade out time (seconds)
    // scale: text scale (1.0 = normal)
    private framehandle SingleLineTextFrame = null
    private real SingleLineTextTime = 0.0
    private real SingleLineTextFadeIn = 1.0
    private real SingleLineTextDuration = 2.0
    private real SingleLineTextFadeOut = 1.0
    private boolean SingleLineTextActive = false
endglobals

// Public function to show a region title with fade
function ShowRegionTitle takes string smallText, string mainTitle returns nothing
    if lastPopupMain == mainTitle and lastPopupSmall == smallText and fadeActive then
        return
    endif
    set lastPopupMain = mainTitle
    set lastPopupSmall = smallText
    set titleTime = 0.0
    set smallTextTime = 0.0
    set fadeActive = true
    set smallTextActive = true
    set titleActive = false
    call BlzFrameSetText(Text02, smallText)
    call BlzFrameSetVisible(Text02, true)
    call BlzFrameSetAlpha(Text02, 0)
    call BlzFrameSetVisible(titleFrame1, false)
    call BlzFrameSetAlpha(titleFrame1, 0)
endfunction

// API: ShowSingleLineText
// Shows a single line of text with fade in, duration, fade out, and scale.
// text: the string to display
// fadeIn: fade in time (seconds)
// duration: time fully visible (seconds)
// fadeOut: fade out time (seconds)
// scale: text scale (1.0 = normal)
function ShowSingleLineText takes string text, real fadeIn, real duration, real fadeOut, real scale returns nothing
    set SingleLineTextFadeIn = fadeIn
    set SingleLineTextDuration = duration
    set SingleLineTextFadeOut = fadeOut
    set SingleLineTextTime = 0.0
    set SingleLineTextActive = true

    call BlzFrameSetText(SingleLineTextFrame, text)
    call BlzFrameSetScale(SingleLineTextFrame, scale)
    call BlzFrameSetAlpha(SingleLineTextFrame, 0)
    call BlzFrameSetVisible(SingleLineTextFrame, true)
endfunction

private function HideTitle takes nothing returns nothing
    call BlzFrameSetVisible(titleFrame1, false)
    call BlzFrameSetVisible(Text02, false)
    set fadeActive = false
    set smallTextActive = false
    set titleActive = false
endfunction

private function FadeTitle takes nothing returns nothing
    if not fadeActive then
        return
    endif
    // Fade in small text first
    if smallTextActive then
        set smallTextTime = smallTextTime + 0.03
        if smallTextTime < SMALLTEXT_FADE_IN_TIME then
            call BlzFrameSetAlpha(Text02, R2I(255 * (smallTextTime / SMALLTEXT_FADE_IN_TIME)))
        elseif smallTextTime < SMALLTEXT_FADE_IN_TIME + SMALLTEXT_DURATION then
            call BlzFrameSetAlpha(Text02, 255)
            // Start main title fade-in after small text is fully visible
            if not titleActive then
                set titleActive = true
                set titleTime = 0.0
                call BlzFrameSetText(titleFrame1, lastPopupMain)
                call BlzFrameSetVisible(titleFrame1, true)
                call BlzFrameSetAlpha(titleFrame1, 0)
            endif
        elseif smallTextTime < SMALLTEXT_FADE_IN_TIME + SMALLTEXT_DURATION + SMALLTEXT_FADE_OUT_TIME then
            call BlzFrameSetAlpha(Text02, R2I(255 * (1 - (smallTextTime - SMALLTEXT_FADE_IN_TIME - SMALLTEXT_DURATION) / SMALLTEXT_FADE_OUT_TIME)))
        else
            call BlzFrameSetVisible(Text02, false)
            set smallTextActive = false
        endif
    endif
    // Fade in main title after small text
    if titleActive then
        set titleTime = titleTime + 0.03
        if titleTime < MAINTITLE_FADE_IN_TIME then
            call BlzFrameSetAlpha(titleFrame1, R2I(255 * (titleTime / MAINTITLE_FADE_IN_TIME)))
        elseif titleTime < MAINTITLE_FADE_IN_TIME + MAINTITLE_DURATION then
            call BlzFrameSetAlpha(titleFrame1, 255)
        elseif titleTime < MAINTITLE_FADE_IN_TIME + MAINTITLE_DURATION + MAINTITLE_FADE_OUT_TIME then
            call BlzFrameSetAlpha(titleFrame1, R2I(255 * (1 - (titleTime - MAINTITLE_FADE_IN_TIME - MAINTITLE_DURATION) / MAINTITLE_FADE_OUT_TIME)))
        else
            call BlzFrameSetVisible(titleFrame1, false)
            set titleActive = false
        endif
    endif
    // When both are done, hide all
    if not smallTextActive and not titleActive then
        call HideTitle()
    endif
endfunction

private function FadeSingleLineText takes nothing returns nothing
    if not SingleLineTextActive then
        return
    endif
    set SingleLineTextTime = SingleLineTextTime + 0.03
    if SingleLineTextTime < SingleLineTextFadeIn then
        call BlzFrameSetAlpha(SingleLineTextFrame, R2I(255 * (SingleLineTextTime / SingleLineTextFadeIn)))
    elseif SingleLineTextTime < SingleLineTextFadeIn + SingleLineTextDuration then
        call BlzFrameSetAlpha(SingleLineTextFrame, 255)
    elseif SingleLineTextTime < SingleLineTextFadeIn + SingleLineTextDuration + SingleLineTextFadeOut then
        call BlzFrameSetAlpha(SingleLineTextFrame, R2I(255 * (1 - (SingleLineTextTime - SingleLineTextFadeIn - SingleLineTextDuration) / SingleLineTextFadeOut)))
    else
        call BlzFrameSetVisible(SingleLineTextFrame, false)
        set SingleLineTextActive = false
    endif
endfunction

private function Periodic takes nothing returns nothing
    call FadeTitle()
    call FadeSingleLineText()
endfunction

// ParentFunc who you want as parent, this runs at InitBlizzard, if you need more control you need to modify the part that calls local function Init()
private function ParentFunc takes nothing returns framehandle
    return BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
endfunction

private function InitRegionTitles takes nothing returns nothing
    // Load custom frame definition
    call BlzLoadTOCFile("RegionTitle.toc")  

    // Create title frame
    set titleFrame1 = BlzCreateFrameByType("TEXT", "RegionTitle", ParentFunc(), "", 0)
    call BlzFrameSetAbsPoint(titleFrame1, FRAMEPOINT_TOPLEFT, 0.0990500, 0.481780)
    call BlzFrameSetAbsPoint(titleFrame1, FRAMEPOINT_BOTTOMRIGHT, 0.712120, 0.330110)
    call BlzFrameSetEnable(titleFrame1, false)
    call BlzFrameSetScale(titleFrame1, textScale)
    call BlzFrameSetTextAlignment(titleFrame1, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)
    call BlzFrameSetVisible(titleFrame1, false)
    call BlzFrameSetAlpha(titleFrame1, 0)

    // Smaller text frame
    set Text02 = BlzCreateFrameByType("TEXT", "RegionTitle", ParentFunc(), "", 0)
    call BlzFrameSetAbsPoint(Text02, FRAMEPOINT_TOPLEFT, 0.298940, 0.475090)
    call BlzFrameSetAbsPoint(Text02, FRAMEPOINT_BOTTOMRIGHT, 0.506650, 0.426020)
    call BlzFrameSetEnable(Text02, false)
    call BlzFrameSetScale(Text02, textSmallScale)
    call BlzFrameSetTextAlignment(Text02, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)
    call BlzFrameSetVisible(Text02, false)
    call BlzFrameSetAlpha(Text02, 0)

    // Single line text frame
    set SingleLineTextFrame = BlzCreateFrameByType("TEXT", "RegionTitle", ParentFunc(), "", 0)
    call BlzFrameSetPoint(SingleLineTextFrame, FRAMEPOINT_CENTER, ParentFunc(), FRAMEPOINT_CENTER, 0.0, 0.05)
    call BlzFrameSetEnable(SingleLineTextFrame, false)
    call BlzFrameSetScale(SingleLineTextFrame, textSmallScale2)
    call BlzFrameSetTextAlignment(SingleLineTextFrame, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)
    call BlzFrameSetVisible(SingleLineTextFrame, false)
    call BlzFrameSetAlpha(SingleLineTextFrame, 0)

    // Periodic for fade
    call TimerStart(CreateTimer(), 0.03, true, function Periodic)
endfunction

endlibrary