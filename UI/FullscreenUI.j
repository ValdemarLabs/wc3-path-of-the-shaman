/**
    FullscreenUI

    Author: Valdemar

    Description:
    Enables a clean fullscreen cinematic interface while preserving native
    cinematic transmissions.

    While enabled:
    - The normal Warcraft III interface is hidden.
    - Native transmissions use their normal cinematic-mode layout.
    - Cinematic borders and backgrounds are transparent.
    - The transmission portrait, speaker name, and dialogue remain visible.

    Usage:

        call FullscreenUI_SetEnabled(true)

        // Send native transmissions normally.

        call FullscreenUI_SetEnabled(false)

    Important:
    Do not combine this library with:

        call BlzHideCinematicPanels(true)
        call BlzHideCinematicPanels(false)

        call BlzHideOriginFrames(true)
        call BlzHideOriginFrames(false)

        call CinematicModeBJ(true, bj_FORCE_ALL_PLAYERS)
        call CinematicModeBJ(false, bj_FORCE_ALL_PLAYERS)
*/
library FullscreenUI initializer DelayedInit

globals
    /*
     * Warcraft III 2.x interface parents that may remain visible even
     * while the standard interface is hidden.
     */
    private framehandle array FullscreenUI_Frame
    private boolean array FullscreenUI_WasVisible
    private integer FullscreenUI_FrameCount = 0

    /*
     * Decorative cinematic frames.
     *
     * Their alpha is changed instead of their visibility so that the
     * cinematic frame hierarchy and native transmission layout remain
     * intact.
     */
    private framehandle array FullscreenUI_Decoration
    private integer array FullscreenUI_DecorationAlpha
    private integer FullscreenUI_DecorationCount = 0

    private boolean FullscreenUI_Initialized = false
    private boolean FullscreenUI_Enabled = false

    private trigger FullscreenUI_InitTrigger = CreateTrigger()
endglobals

private function RegisterUIFrame takes string frameName returns nothing
    local framehandle frame = BlzGetFrameByName(frameName, 0)

    if frame != null then
        set FullscreenUI_Frame[FullscreenUI_FrameCount] = frame
        set FullscreenUI_FrameCount = FullscreenUI_FrameCount + 1
    endif

    set frame = null
endfunction

private function RegisterDecoration takes string frameName returns nothing
    local framehandle frame = BlzGetFrameByName(frameName, 0)

    if frame != null then
        set FullscreenUI_Decoration[FullscreenUI_DecorationCount] = frame

        set FullscreenUI_DecorationCount = /*
            */ FullscreenUI_DecorationCount + 1
    endif

    set frame = null
endfunction

private function HideDecorations takes nothing returns nothing
    local integer index = 0

    loop
        exitwhen index >= FullscreenUI_DecorationCount

        call BlzFrameSetAlpha(FullscreenUI_Decoration[index], 0)

        set index = index + 1
    endloop
endfunction

private function RestoreDecorations takes nothing returns nothing
    local integer index = 0

    loop
        exitwhen index >= FullscreenUI_DecorationCount

        call BlzFrameSetAlpha(FullscreenUI_Decoration[index], FullscreenUI_DecorationAlpha[index])

        set index = index + 1
    endloop
endfunction

private function Init takes nothing returns nothing
    if FullscreenUI_Initialized then
        return
    endif

    set FullscreenUI_Initialized = true

    /*
     * Warcraft III 2.x console parents.
     */
    call RegisterUIFrame("ConsoleTopBar")
    call RegisterUIFrame("ConsoleBottomBar")
    call RegisterUIFrame("ConsoleBottomBarOverlay")
    call RegisterUIFrame("ConsoleUIBackdrop")

    /*
     * Full-screen cinematic background and borders.
     */
    call RegisterDecoration("HDCinematicBackground")
    call RegisterDecoration("CinematicTopBorder")
    call RegisterDecoration("CinematicBottomBorder")

    /*
     * Transmission portrait decorations.
     *
     * These are hidden because only the actual portrait model and text
     * should remain visible.
     */
    call RegisterDecoration("CinematicPortraitBackground")
    call RegisterDecoration("CinematicPortraitCover")
    call RegisterDecoration("HDCinematicPortraitCover")
endfunction

public function Enable takes nothing returns nothing
    local integer index = 0

    if not FullscreenUI_Initialized then
        call Init()
    endif

    if FullscreenUI_Enabled then
        return
    endif

    set FullscreenUI_Enabled = true

    /*
     * Store the original state before ShowInterface changes the UI.
     */
    loop
        exitwhen index >= FullscreenUI_FrameCount

        set FullscreenUI_WasVisible[index] = /*
            */ BlzFrameIsVisible(FullscreenUI_Frame[index])

        set index = index + 1
    endloop

    /*
     * Store cinematic decoration alpha values.
     */
    set index = 0

    loop
        exitwhen index >= FullscreenUI_DecorationCount

        set FullscreenUI_DecorationAlpha[index] = /*
            */ BlzFrameGetAlpha(FullscreenUI_Decoration[index])

        set index = index + 1
    endloop

    /*
     * This activates the same interface layout used by native cinematic
     * mode without changing fog, game speed, audio, random seed, or other
     * global cinematic settings.
     */
    call ClearTextMessages()
    call ShowInterface(false, 0.00)

    /*
     * Warcraft III 2.x added console parents that may not follow the older
     * interface/origin-frame visibility behavior.
     */
    set index = 0

    loop
        exitwhen index >= FullscreenUI_FrameCount

        call BlzFrameSetVisible(FullscreenUI_Frame[index], false)

        set index = index + 1
    endloop

    /*
     * Preserve the native cinematic layout while removing its artwork.
     */
    call HideDecorations()
endfunction

public function Disable takes nothing returns nothing
    local integer index

    if not FullscreenUI_Enabled then
        return
    endif

    set FullscreenUI_Enabled = false

    /*
     * Restore cinematic artwork before leaving the cinematic interface
     * layout.
     */
    call RestoreDecorations()

    /*
     * Restore the standard gameplay interface and layout.
     */
    call ShowInterface(true, 0.00)

    /*
     * Restore the Warcraft III 2.x parents to their previous states.
     */
    set index = FullscreenUI_FrameCount - 1

    loop
        exitwhen index < 0

        call BlzFrameSetVisible(FullscreenUI_Frame[index], FullscreenUI_WasVisible[index])

        set index = index - 1
    endloop
endfunction

/*
 * Reapply transparency after a native transmission begins.
 *
 * Normally SetCinematicScene does not need this, but calling Refresh after
 * a transmission is harmless and protects against patch-specific resets.
 */
public function Refresh takes nothing returns nothing
    if FullscreenUI_Enabled then
        call HideDecorations()
    endif
endfunction

public function SetEnabled takes boolean enabled returns nothing
    if enabled then
        call Enable()
    else
        call Disable()
    endif
endfunction

public function IsEnabled takes nothing returns boolean
    return FullscreenUI_Enabled
endfunction

private function DelayedInit takes nothing returns nothing
    call TriggerRegisterTimerEvent(FullscreenUI_InitTrigger, 0.10, false)

    call TriggerAddAction(FullscreenUI_InitTrigger, function Init)
endfunction

endlibrary