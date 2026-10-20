/**
    ModernMinimapHUD

    Author: Valdemar
    Version: 0.1.0

    Description:
    Places the native interactive minimap in a compact PotS-owned upper-left
    shell and provides two custom player-hero selection buttons. This replaces
    the native minimap and hero-button access lost when the console HUD is
    hidden, without moving the native command card or portrait.

    Credits:
    - Blizzard Entertainment, Warcraft III frame API and native minimap
    - VideoRPG reference map, isolated native-minimap parenting pattern

    How to install:
    Import after FullscreenUI and ModernPlayerHUD. Import PotSActionSlot.tga at
    the exact path documented in UI/_Modern/README.md.

    API:
    - call ModernMinimapHUD_Enable()
    - call ModernMinimapHUD_Disable()
    - call ModernMinimapHUD_Refresh()
    - set enabled = ModernMinimapHUD_IsEnabled()

**/
library ModernMinimapHUD initializer Init requires FullscreenUI, ModernPlayerHUD

globals
    private constant real MMH_PANEL_LEFT = 0.006
    private constant real MMH_PANEL_RIGHT = 0.134
    private constant real MMH_PANEL_TOP = 0.558
    private constant real MMH_PANEL_BOTTOM = 0.388
    private constant real MMH_MINIMAP_LEFT = 0.013
    private constant real MMH_MINIMAP_TOP = 0.550
    private constant real MMH_MINIMAP_SIZE = 0.114
    private constant real MMH_HERO_BOTTOM = 0.396
    private constant real MMH_HERO_SIZE = 0.034
    private constant string MMH_SLOT_TEXTURE = "UI\\_Modern\\Assets\\PotSActionSlot.tga"
    private constant string MMH_EMPTY_ICON = "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"

    private boolean MMH_Enabled = true
    private boolean MMH_FramesCreated = false
    private boolean MMH_Visible = false
    private framehandle MMH_Root = null
    private framehandle MMH_Panel = null
    private framehandle MMH_Title = null
    private framehandle MMH_Minimap = null
    private framehandle array MMH_HeroButton
    private framehandle array MMH_HeroBorder
    private framehandle array MMH_HeroIcon
    private framehandle array MMH_HeroLabel
    private unit array MMH_CachedHero
    private integer array MMH_CachedHeroType
    private trigger MMH_HeroTrigger = null
    private trigger MMH_ClearFocusTrigger = null
    private trigger MMH_InitTrigger = null
endglobals

private function MMH_IsValidHero takes unit whichHero returns boolean
    return whichHero != null and GetHandleId(whichHero) != 0 and GetUnitTypeId(whichHero) != 0
endfunction

private function MMH_GetHero takes integer index returns unit
    if index == 0 then
        return udg_Nazgrek
    endif
    return udg_Zulkis
endfunction

private function MMH_SetVisible takes boolean visible returns nothing
    if MMH_Visible != visible then
        set MMH_Visible = visible
        call BlzFrameSetVisible(MMH_Root, visible)
        call BlzFrameSetVisible(MMH_Minimap, visible)
    endif
endfunction

private function MMH_UpdateHero takes integer index returns nothing
    local unit whichHero = MMH_GetHero(index)
    local integer unitTypeId = 0
    local string iconPath

    if MMH_IsValidHero(whichHero) then
        set unitTypeId = GetUnitTypeId(whichHero)
    endif
    if MMH_CachedHero[index] != whichHero or MMH_CachedHeroType[index] != unitTypeId then
        set MMH_CachedHero[index] = whichHero
        set MMH_CachedHeroType[index] = unitTypeId
        if unitTypeId != 0 then
            set iconPath = BlzGetAbilityIcon(unitTypeId)
            if iconPath == null or iconPath == "" then
                set iconPath = MMH_EMPTY_ICON
            endif
            call BlzFrameSetTexture(MMH_HeroIcon[index], iconPath, 0, true)
        endif
        call BlzFrameSetVisible(MMH_HeroButton[index], unitTypeId != 0)
    endif

    set whichHero = null
endfunction

private function MMH_Update takes nothing returns nothing
    local boolean visible

    if not MMH_FramesCreated then
        return
    endif
    set visible = MMH_Enabled and ModernPlayerHUD_IsEnabled() and not FullscreenUI_IsEnabled()
    call MMH_SetVisible(visible)
    if visible then
        call MMH_UpdateHero(0)
        call MMH_UpdateHero(1)
    endif
endfunction

private function MMH_ClearFocusAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()

    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
    endif
    set triggerFrame = null
endfunction

private function MMH_HeroAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local player triggerPlayer = GetTriggerPlayer()
    local unit whichHero = null

    if triggerPlayer == GetLocalPlayer() then
        if triggerFrame == MMH_HeroButton[0] then
            set whichHero = MMH_GetHero(0)
        elseif triggerFrame == MMH_HeroButton[1] then
            set whichHero = MMH_GetHero(1)
        endif
        if MMH_IsValidHero(whichHero) and GetOwningPlayer(whichHero) == triggerPlayer then
            call SelectUnitForPlayerSingle(whichHero, triggerPlayer)
        endif
    endif

    set whichHero = null
    set triggerPlayer = null
    set triggerFrame = null
endfunction

private function MMH_CreateHeroButton takes integer index, real x, string label returns nothing
    set MMH_HeroButton[index] = BlzCreateFrameByType("BUTTON", "ModernMinimapHeroButton" + I2S(index), MMH_Root, "", 0)
    call BlzFrameSetAbsPoint(MMH_HeroButton[index], FRAMEPOINT_BOTTOMLEFT, x, MMH_HERO_BOTTOM)
    call BlzFrameSetSize(MMH_HeroButton[index], MMH_HERO_SIZE, MMH_HERO_SIZE)
    call BlzFrameSetLevel(MMH_HeroButton[index], 6)

    set MMH_HeroBorder[index] = BlzCreateFrameByType("BACKDROP", "ModernMinimapHeroBorder" + I2S(index), MMH_HeroButton[index], "", 0)
    call BlzFrameSetAllPoints(MMH_HeroBorder[index], MMH_HeroButton[index])
    call BlzFrameSetTexture(MMH_HeroBorder[index], MMH_SLOT_TEXTURE, 0, true)
    call BlzFrameSetEnable(MMH_HeroBorder[index], false)
    call BlzFrameSetLevel(MMH_HeroBorder[index], 7)

    set MMH_HeroIcon[index] = BlzCreateFrameByType("BACKDROP", "ModernMinimapHeroIcon" + I2S(index), MMH_HeroButton[index], "IconButtonTemplate", 0)
    call BlzFrameSetPoint(MMH_HeroIcon[index], FRAMEPOINT_BOTTOMLEFT, MMH_HeroButton[index], FRAMEPOINT_BOTTOMLEFT, 0.004, 0.004)
    call BlzFrameSetPoint(MMH_HeroIcon[index], FRAMEPOINT_TOPRIGHT, MMH_HeroButton[index], FRAMEPOINT_TOPRIGHT, -0.004, -0.004)
    call BlzFrameSetEnable(MMH_HeroIcon[index], false)
    call BlzFrameSetLevel(MMH_HeroIcon[index], 8)

    set MMH_HeroLabel[index] = BlzCreateFrameByType("TEXT", "ModernMinimapHeroLabel" + I2S(index), MMH_HeroButton[index], "", 0)
    call BlzFrameSetPoint(MMH_HeroLabel[index], FRAMEPOINT_BOTTOMRIGHT, MMH_HeroButton[index], FRAMEPOINT_BOTTOMRIGHT, -0.002, 0.001)
    call BlzFrameSetSize(MMH_HeroLabel[index], 0.010, 0.009)
    call BlzFrameSetTextAlignment(MMH_HeroLabel[index], TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_RIGHT)
    call BlzFrameSetScale(MMH_HeroLabel[index], 0.52)
    call BlzFrameSetText(MMH_HeroLabel[index], label)
    call BlzFrameSetEnable(MMH_HeroLabel[index], false)
    call BlzFrameSetLevel(MMH_HeroLabel[index], 9)

    call BlzTriggerRegisterFrameEvent(MMH_HeroTrigger, MMH_HeroButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MMH_ClearFocusTrigger, MMH_HeroButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzFrameSetVisible(MMH_HeroButton[index], false)
endfunction

private function MMH_CreateFrames takes nothing returns nothing
    local framehandle gameUI

    if MMH_FramesCreated then
        return
    endif
    set MMH_FramesCreated = true
    set gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    set MMH_Root = BlzCreateFrameByType("FRAME", "ModernMinimapHUDRoot", gameUI, "", 0)
    call BlzFrameSetSize(MMH_Root, 0.0001, 0.0001)
    call BlzFrameSetAbsPoint(MMH_Root, FRAMEPOINT_BOTTOMLEFT, 0.000, 0.000)
    call BlzFrameSetLevel(MMH_Root, 14)

    set MMH_Panel = BlzCreateFrameByType("BACKDROP", "ModernMinimapHUDPanel", MMH_Root, "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(MMH_Panel, FRAMEPOINT_TOPLEFT, MMH_PANEL_LEFT, MMH_PANEL_TOP)
    call BlzFrameSetAbsPoint(MMH_Panel, FRAMEPOINT_BOTTOMRIGHT, MMH_PANEL_RIGHT, MMH_PANEL_BOTTOM)
    call BlzFrameSetEnable(MMH_Panel, false)
    call BlzFrameSetLevel(MMH_Panel, 1)

    set MMH_Title = BlzCreateFrameByType("TEXT", "ModernMinimapHUDTitle", MMH_Root, "", 0)
    call BlzFrameSetAbsPoint(MMH_Title, FRAMEPOINT_BOTTOM, 0.070, 0.432)
    call BlzFrameSetSize(MMH_Title, 0.090, 0.010)
    call BlzFrameSetTextAlignment(MMH_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MMH_Title, 0.55)
    call BlzFrameSetText(MMH_Title, "|cffffe4a3HEROES|r")
    call BlzFrameSetEnable(MMH_Title, false)
    call BlzFrameSetLevel(MMH_Title, 5)

    set MMH_Minimap = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    call BlzFrameSetParent(MMH_Minimap, MMH_Root)
    call BlzFrameClearAllPoints(MMH_Minimap)
    call BlzFrameSetAbsPoint(MMH_Minimap, FRAMEPOINT_TOPLEFT, MMH_MINIMAP_LEFT, MMH_MINIMAP_TOP)
    call BlzFrameSetSize(MMH_Minimap, MMH_MINIMAP_SIZE, MMH_MINIMAP_SIZE)
    call BlzFrameSetLevel(MMH_Minimap, 3)

    call MMH_CreateHeroButton(0, 0.030, "N")
    call MMH_CreateHeroButton(1, 0.076, "Z")
    call BlzFrameSetVisible(MMH_Root, false)
    call BlzFrameSetVisible(MMH_Minimap, false)
    set gameUI = null
endfunction

public function Refresh takes nothing returns nothing
    call MMH_Update()
endfunction

public function Enable takes nothing returns nothing
    set MMH_Enabled = true
    call MMH_Update()
endfunction

public function Disable takes nothing returns nothing
    set MMH_Enabled = false
    call MMH_SetVisible(false)
endfunction

public function IsEnabled takes nothing returns boolean
    return MMH_Enabled
endfunction

private function MMH_DelayedInit takes nothing returns nothing
    call MMH_CreateFrames()
    call MMH_Update()
    call DestroyTrigger(MMH_InitTrigger)
    set MMH_InitTrigger = null
endfunction

private function Init takes nothing returns nothing
    set MMH_HeroTrigger = CreateTrigger()
    call TriggerAddAction(MMH_HeroTrigger, function MMH_HeroAction)
    set MMH_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(MMH_ClearFocusTrigger, function MMH_ClearFocusAction)
    set MMH_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(MMH_InitTrigger, 0.30, false)
    call TriggerAddAction(MMH_InitTrigger, function MMH_DelayedInit)
    call ModernPlayerHUD_RegisterUpdate(function MMH_Update)
endfunction

endlibrary
