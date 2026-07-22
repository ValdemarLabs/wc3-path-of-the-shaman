/**
    ImagesUI

    Author: Valdemar
    Version:

    Description:
    Small frame UI helper for showing a centered 16:9 preload image over a
    full-screen backing frame. It is currently used by the preload flow before
    the intro/game start trigger is executed.

    Credits:

    How to install:
    Import this library before Preloader.j. Update the image paths passed by
    callers to match imported BLP files or valid game texture paths.

    API:
    call ImagesUI_ShowPreload("war3mapImported\\PreloadStart.blp", "")
    call ImagesUI_SetPreloadImage("war3mapImported\\PreloadSounds.blp")
    call ImagesUI_SetPreloadText("==== Sounds")
    call ImagesUI_HidePreload()

**/
library ImagesUI
    globals
        // Preload overlay configuration. 0.800 x 0.450 keeps a 16:9 image ratio.
        private constant real IMUI_SCREEN_WIDTH = 0.800
        private constant real IMUI_SCREEN_HEIGHT = 0.600
        private constant real IMUI_IMAGE_CENTER_X = 0.400
        private constant real IMUI_IMAGE_CENTER_Y = 0.300
        private constant real IMUI_IMAGE_WIDTH = 0.800
        private constant real IMUI_IMAGE_HEIGHT = 0.450
        private constant real IMUI_TEXT_CENTER_Y = 0.190
        private constant real IMUI_TEXT_WIDTH = 0.520
        private constant real IMUI_TEXT_HEIGHT = 0.032
        private constant real IMUI_TEXT_SCALE = 1.12
        private constant integer IMUI_FRAME_LEVEL = 1
        private constant string IMUI_DEFAULT_IMAGE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"

        private boolean IMUI_Initialized = false
        private framehandle IMUI_Root = null
        private framehandle IMUI_Background = null
        private framehandle IMUI_Image = null
        private framehandle IMUI_Text = null
    endglobals

    private function IMUI_CreateFrames takes nothing returns nothing
        local framehandle gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)

        if IMUI_Initialized then
            set gameUI = null
            return
        endif
        set IMUI_Initialized = true

        set IMUI_Root = BlzCreateFrameByType("FRAME", "ImagesUIPreloadRoot", gameUI, "", 0)
        call BlzFrameSetAbsPoint(IMUI_Root, FRAMEPOINT_CENTER, IMUI_IMAGE_CENTER_X, IMUI_IMAGE_CENTER_Y)
        call BlzFrameSetSize(IMUI_Root, IMUI_SCREEN_WIDTH, IMUI_SCREEN_HEIGHT)
        call BlzFrameSetLevel(IMUI_Root, IMUI_FRAME_LEVEL)

        set IMUI_Background = BlzCreateFrameByType("BACKDROP", "ImagesUIPreloadBackground", IMUI_Root, "", 0)
        call BlzFrameSetAbsPoint(IMUI_Background, FRAMEPOINT_CENTER, IMUI_IMAGE_CENTER_X, IMUI_IMAGE_CENTER_Y)
        call BlzFrameSetSize(IMUI_Background, IMUI_SCREEN_WIDTH, IMUI_SCREEN_HEIGHT)
        call BlzFrameSetTexture(IMUI_Background, IMUI_DEFAULT_IMAGE, 0, true)

        set IMUI_Image = BlzCreateFrameByType("BACKDROP", "ImagesUIPreloadImage", IMUI_Root, "", 0)
        call BlzFrameSetAbsPoint(IMUI_Image, FRAMEPOINT_CENTER, IMUI_IMAGE_CENTER_X, IMUI_IMAGE_CENTER_Y)
        call BlzFrameSetSize(IMUI_Image, IMUI_IMAGE_WIDTH, IMUI_IMAGE_HEIGHT)
        call BlzFrameSetTexture(IMUI_Image, IMUI_DEFAULT_IMAGE, 0, true)

        set IMUI_Text = BlzCreateFrameByType("TEXT", "ImagesUIPreloadText", IMUI_Root, "", 0)
        call BlzFrameSetAbsPoint(IMUI_Text, FRAMEPOINT_CENTER, IMUI_IMAGE_CENTER_X, IMUI_TEXT_CENTER_Y)
        call BlzFrameSetSize(IMUI_Text, IMUI_TEXT_WIDTH, IMUI_TEXT_HEIGHT)
        call BlzFrameSetTextAlignment(IMUI_Text, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(IMUI_Text, IMUI_TEXT_SCALE)
        call BlzFrameSetEnable(IMUI_Text, false)
        call BlzFrameSetText(IMUI_Text, "")

        call BlzFrameSetVisible(IMUI_Root, false)

        set gameUI = null
    endfunction

    public function Init takes nothing returns nothing
        call IMUI_CreateFrames()
    endfunction

    public function SetPreloadImage takes string texturePath returns nothing
        if not IMUI_Initialized then
            call Init()
        endif

        if texturePath == null or texturePath == "" then
            call Preload(IMUI_DEFAULT_IMAGE)
            call BlzFrameSetTexture(IMUI_Image, IMUI_DEFAULT_IMAGE, 0, true)
        else
            call Preload(texturePath)
            call BlzFrameSetTexture(IMUI_Image, texturePath, 0, true)
        endif
    endfunction

    public function SetPreloadText takes string message returns nothing
        if not IMUI_Initialized then
            call Init()
        endif

        if message == null then
            call BlzFrameSetText(IMUI_Text, "")
        else
            call BlzFrameSetText(IMUI_Text, message)
        endif
    endfunction

    public function ShowPreload takes string texturePath, string message returns nothing
        if not IMUI_Initialized then
            call Init()
        endif

        call SetPreloadImage(texturePath)
        call SetPreloadText(message)
        call BlzFrameSetVisible(IMUI_Root, true)
    endfunction

    public function HidePreload takes nothing returns nothing
        if IMUI_Initialized and IMUI_Root != null then
            call BlzFrameSetVisible(IMUI_Root, false)
        endif
    endfunction
endlibrary
