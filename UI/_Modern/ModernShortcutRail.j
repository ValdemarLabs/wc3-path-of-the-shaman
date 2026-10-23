/**
    ModernShortcutRail

    Author: Valdemar
    Version: 1.0.0

    Description:
    Adds an icon-only shortcut rail beneath the upper-right minimap. The rail
    uses the shared widescreen root so every button remains interactive beyond
    Warcraft III's classic 4:3 frame boundary. Hovering an icon shows its name
    and purpose; persistent overlay icons also display an active-state tint.

    Credits:
    - Blizzard Entertainment, Warcraft III frame API and command icons

    How to install:
    Import after ModernPlayerHUD, WidescreenFrameRoot, MasterUI, and
    AbilitiesLiteUI. Import UI/_Modern/Assets/PotSActionSlot.tga at the exact
    path documented in UI/_Modern/README.md. Optional UI systems automatically
    enable their matching shortcut.

    API:
    - call ModernShortcutRail_Enable()
    - call ModernShortcutRail_Disable()
    - call ModernShortcutRail_Refresh()
    - set enabled = ModernShortcutRail_IsEnabled()

**/
library ModernShortcutRail initializer Init requires FullscreenUI, ModernPlayerHUD, WidescreenFrameRoot, MasterUI, AbilitiesLiteUI, optional DInventory, optional DEquipment, optional TalentsUI, optional StatsUI, optional StatsLiteUI, optional TargetUnitUI

globals
    private constant integer MSR_ACTION_INVENTORY = 0
    private constant integer MSR_ACTION_ABILITIES = 1
    private constant integer MSR_ACTION_TALENTS = 2
    private constant integer MSR_ACTION_STATS = 3
    private constant integer MSR_ACTION_STATS_LITE = 4
    private constant integer MSR_ACTION_THREAT = 5
    private constant integer MSR_ACTION_INSPECT = 6
    private constant integer MSR_BUTTON_COUNT = 7

    private constant real MSR_BUTTON_SIZE = 0.032
    private constant real MSR_BUTTON_GAP = 0.006
    private constant real MSR_RIGHT_MARGIN = 0.009
    private constant real MSR_TOP = 0.378
    private constant string MSR_SLOT_TEXTURE = "UI\\_Modern\\Assets\\PotSActionSlot.tga"
    private constant string MSR_SURFACE_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"

    private boolean MSR_Enabled = true
    private boolean MSR_FramesCreated = false
    private boolean MSR_Visible = false
    private boolean MSR_InspectVisible = false
    private integer MSR_ClientWidthCache = -1
    private integer MSR_ClientHeightCache = -1
    private integer array MSR_ActiveCache
    private framehandle MSR_Root = null
    private framehandle array MSR_Button
    private framehandle array MSR_Icon
    private framehandle array MSR_ActiveLine
    private framehandle MSR_Tooltip = null
    private framehandle MSR_TooltipText = null
    private trigger MSR_ClickTrigger = null
    private trigger MSR_EnterTrigger = null
    private trigger MSR_LeaveTrigger = null
    private trigger MSR_InitTrigger = null
endglobals

private function MSR_GetIcon takes integer action returns string
    if action == MSR_ACTION_INVENTORY then
        return "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp"
    elseif action == MSR_ACTION_ABILITIES then
        return "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"
    elseif action == MSR_ACTION_TALENTS then
        return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    elseif action == MSR_ACTION_STATS then
        return "ReplaceableTextures\\WorldEditUI\\Editor-MultipleUnits.blp"
    elseif action == MSR_ACTION_STATS_LITE then
        return "ReplaceableTextures\\CommandButtons\\BTNAnimalWarTraining.blp"
    elseif action == MSR_ACTION_THREAT then
        return "ReplaceableTextures\\CommandButtons\\BTNEnsnare.blp"
    endif
    return "ReplaceableTextures\\CommandButtons\\BTNSpy.blp"
endfunction

private function MSR_GetTooltip takes integer action returns string
    if action == MSR_ACTION_INVENTORY then
        return "|cffffcc00Inventory|r|nOpen bags and equipped items."
    elseif action == MSR_ACTION_ABILITIES then
        return "|cffffcc00Abilities|r|nChoose and arrange action-bar abilities."
    elseif action == MSR_ACTION_TALENTS then
        return "|cffffcc00Talents|r|nOpen the talent interface."
    elseif action == MSR_ACTION_STATS then
        return "|cffffcc00Stats|r|nOpen detailed character statistics."
    elseif action == MSR_ACTION_STATS_LITE then
        return "|cffffcc00Stats overlay|r|nToggle the compact party statistics."
    elseif action == MSR_ACTION_THREAT then
        return "|cffffcc00Threat overlay|r|nToggle target and threat information."
    endif
    return "|cffffcc00Inspect|r|nInspect the selected friendly unit."
endfunction

private function MSR_FindButton takes framehandle whichFrame returns integer
    local integer index = 0

    loop
        exitwhen index >= MSR_BUTTON_COUNT
        if whichFrame == MSR_Button[index] then
            set whichFrame = null
            return index
        endif
        set index = index + 1
    endloop
    set whichFrame = null
    return -1
endfunction

private function MSR_CanInspect takes player viewer returns boolean
    local unit target = null
    local boolean canInspect = false

    static if LIBRARY_DEquipment then
        set target = DInspectResolveSelectedTarget(viewer)
        set canInspect = target != null and GetOwningPlayer(target) != viewer and not IsUnitEnemy(target, viewer)
    endif
    set target = null
    set viewer = null
    return canInspect
endfunction

private function MSR_SetActive takes integer index, boolean active returns nothing
    local integer state = 0

    if active then
        set state = 1
    endif
    if MSR_ActiveCache[index] != state then
        set MSR_ActiveCache[index] = state
        call BlzFrameSetVisible(MSR_ActiveLine[index], active)
        if active then
            call BlzFrameSetVertexColor(MSR_Icon[index], BlzConvertColor(255, 210, 255, 210))
        else
            call BlzFrameSetVertexColor(MSR_Icon[index], BlzConvertColor(255, 255, 255, 255))
        endif
    endif
endfunction

private function MSR_SetInspectVisible takes boolean visible returns nothing
    if MSR_InspectVisible != visible then
        set MSR_InspectVisible = visible
        call BlzFrameSetVisible(MSR_Button[MSR_ACTION_INSPECT], visible)
    endif
endfunction

private function MSR_UpdateScreenLayout takes nothing returns nothing
    local integer clientWidth = BlzGetLocalClientWidth()
    local integer clientHeight = BlzGetLocalClientHeight()
    local real rightEdge
    local integer index = 0

    if clientWidth == MSR_ClientWidthCache and clientHeight == MSR_ClientHeightCache then
        return
    endif
    set MSR_ClientWidthCache = clientWidth
    set MSR_ClientHeightCache = clientHeight
    set rightEdge = WidescreenFrameRoot_GetClientRight() - MSR_RIGHT_MARGIN
    loop
        exitwhen index >= MSR_BUTTON_COUNT
        call BlzFrameClearAllPoints(MSR_Button[index])
        call BlzFrameSetAbsPoint(MSR_Button[index], FRAMEPOINT_TOPRIGHT, rightEdge, MSR_TOP - I2R(index) * (MSR_BUTTON_SIZE + MSR_BUTTON_GAP))
        set index = index + 1
    endloop
endfunction

private function MSR_Update takes nothing returns nothing
    local boolean visible
    local boolean inspectVisible = false
    local player viewer

    if not MSR_FramesCreated then
        return
    endif
    set visible = MSR_Enabled and ModernPlayerHUD_IsEnabled() and not FullscreenUI_IsEnabled()
    if MSR_Visible != visible then
        set MSR_Visible = visible
        call BlzFrameSetVisible(MSR_Root, visible)
        if not visible then
            call BlzFrameSetVisible(MSR_Tooltip, false)
        endif
    endif
    if not visible then
        return
    endif

    call MSR_UpdateScreenLayout()
    set viewer = GetLocalPlayer()
    set inspectVisible = MSR_CanInspect(viewer)
    call MSR_SetInspectVisible(inspectVisible)

    static if LIBRARY_StatsLiteUI then
        call MSR_SetActive(MSR_ACTION_STATS_LITE, StatsLiteUI_IsVisible())
    else
        call MSR_SetActive(MSR_ACTION_STATS_LITE, false)
    endif
    static if LIBRARY_TargetUnitUI then
        call MSR_SetActive(MSR_ACTION_THREAT, TargetUnitUI_IsVisible())
    else
        call MSR_SetActive(MSR_ACTION_THREAT, false)
    endif
    static if LIBRARY_DInventory then
        call MSR_SetActive(MSR_ACTION_INSPECT, DInvIsPlayerInspecting(GetPlayerId(viewer)))
    else
        call MSR_SetActive(MSR_ACTION_INSPECT, false)
    endif
    set viewer = null
endfunction

private function MSR_OpenInventory takes player viewer, unit whichUnit, boolean inspectMode returns nothing
    static if LIBRARY_DInventory then
        call DInvShowUnitForPlayer(viewer, whichUnit, inspectMode)
    endif
    static if LIBRARY_DEquipment then
        call DEqShowUnitForPlayer(viewer, whichUnit, inspectMode)
    endif
    set viewer = null
    set whichUnit = null
endfunction

private function MSR_ClickAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local player viewer = GetTriggerPlayer()
    local unit hero = ModernPlayerHUD_GetUnit()
    local unit target = null
    local integer action = MSR_FindButton(triggerFrame)

    if viewer == GetLocalPlayer() then
        if action == MSR_ACTION_INVENTORY and hero != null then
            call MasterUI_ClosePanels()
            call MSR_OpenInventory(viewer, hero, false)
        elseif action == MSR_ACTION_ABILITIES and hero != null then
            call MasterUI_ClosePanels()
            call AbilitiesLiteUI_ShowForUnit(hero)
        elseif action == MSR_ACTION_TALENTS and hero != null then
            call MasterUI_ClosePanels()
            static if LIBRARY_TalentsUI then
                call TalentsUI_ShowForUnit(hero)
            endif
        elseif action == MSR_ACTION_STATS then
            static if LIBRARY_StatsUI then
                if StatsUI_IsVisible() then
                    call StatsUI_Hide()
                else
                    call MasterUI_ClosePanels()
                    call StatsUI_Show()
                endif
            endif
        elseif action == MSR_ACTION_STATS_LITE then
            static if LIBRARY_StatsLiteUI then
                call StatsLiteUI_Toggle()
            endif
        elseif action == MSR_ACTION_THREAT then
            static if LIBRARY_TargetUnitUI then
                call TargetUnitUI_Toggle()
            endif
        elseif action == MSR_ACTION_INSPECT then
            static if LIBRARY_DInventory then
                if DInvIsPlayerInspecting(GetPlayerId(viewer)) then
                    static if LIBRARY_DEquipment then
                        call DInventoryEquipment_HideForPlayer(viewer)
                    endif
                else
                    static if LIBRARY_DEquipment then
                        set target = DInspectResolveSelectedTarget(viewer)
                        if target != null then
                            call MasterUI_ClosePanels()
                            call MSR_OpenInventory(viewer, target, true)
                        endif
                    endif
                endif
            endif
        endif
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
        call MSR_Update()
    endif

    set target = null
    set hero = null
    set viewer = null
    set triggerFrame = null
endfunction

private function MSR_EnterAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local integer action = MSR_FindButton(triggerFrame)

    if GetTriggerPlayer() == GetLocalPlayer() and action >= 0 then
        call BlzFrameClearAllPoints(MSR_Tooltip)
        call BlzFrameSetPoint(MSR_Tooltip, FRAMEPOINT_TOPRIGHT, triggerFrame, FRAMEPOINT_TOPLEFT, -0.006, 0.000)
        call BlzFrameSetText(MSR_TooltipText, MSR_GetTooltip(action))
        call BlzFrameSetVisible(MSR_Tooltip, true)
    endif
    set triggerFrame = null
endfunction

private function MSR_LeaveAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetVisible(MSR_Tooltip, false)
    endif
endfunction

private function MSR_CreateButton takes integer index returns nothing
    local framehandle border

    set MSR_Button[index] = BlzCreateFrameByType("BUTTON", "ModernShortcutRailButton" + I2S(index), MSR_Root, "", 0)
    call BlzFrameSetAbsPoint(MSR_Button[index], FRAMEPOINT_TOPRIGHT, 0.791, MSR_TOP - I2R(index) * (MSR_BUTTON_SIZE + MSR_BUTTON_GAP))
    call BlzFrameSetSize(MSR_Button[index], MSR_BUTTON_SIZE, MSR_BUTTON_SIZE)
    call BlzFrameSetLevel(MSR_Button[index], 6)

    set border = BlzCreateFrameByType("BACKDROP", "ModernShortcutRailBorder" + I2S(index), MSR_Button[index], "", 0)
    call BlzFrameSetAllPoints(border, MSR_Button[index])
    call BlzFrameSetTexture(border, MSR_SLOT_TEXTURE, 0, true)
    call BlzFrameSetEnable(border, false)
    call BlzFrameSetLevel(border, 7)

    set MSR_Icon[index] = BlzCreateFrameByType("BACKDROP", "ModernShortcutRailIcon" + I2S(index), MSR_Button[index], "", 0)
    call BlzFrameSetPoint(MSR_Icon[index], FRAMEPOINT_BOTTOMLEFT, MSR_Button[index], FRAMEPOINT_BOTTOMLEFT, 0.004, 0.004)
    call BlzFrameSetPoint(MSR_Icon[index], FRAMEPOINT_TOPRIGHT, MSR_Button[index], FRAMEPOINT_TOPRIGHT, -0.004, -0.004)
    call BlzFrameSetTexture(MSR_Icon[index], MSR_GetIcon(index), 0, true)
    call BlzFrameSetEnable(MSR_Icon[index], false)
    call BlzFrameSetLevel(MSR_Icon[index], 8)

    set MSR_ActiveLine[index] = BlzCreateFrameByType("BACKDROP", "ModernShortcutRailActive" + I2S(index), MSR_Button[index], "", 0)
    call BlzFrameSetPoint(MSR_ActiveLine[index], FRAMEPOINT_BOTTOMLEFT, MSR_Button[index], FRAMEPOINT_BOTTOMLEFT, 0.005, 0.003)
    call BlzFrameSetSize(MSR_ActiveLine[index], MSR_BUTTON_SIZE - 0.010, 0.002)
    call BlzFrameSetTexture(MSR_ActiveLine[index], MSR_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetVertexColor(MSR_ActiveLine[index], BlzConvertColor(255, 64, 255, 96))
    call BlzFrameSetEnable(MSR_ActiveLine[index], false)
    call BlzFrameSetVisible(MSR_ActiveLine[index], false)
    call BlzFrameSetLevel(MSR_ActiveLine[index], 9)

    call BlzTriggerRegisterFrameEvent(MSR_ClickTrigger, MSR_Button[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MSR_EnterTrigger, MSR_Button[index], FRAMEEVENT_MOUSE_ENTER)
    call BlzTriggerRegisterFrameEvent(MSR_LeaveTrigger, MSR_Button[index], FRAMEEVENT_MOUSE_LEAVE)
    set MSR_ActiveCache[index] = -1
    set border = null
endfunction

private function MSR_CreateFrames takes nothing returns nothing
    local framehandle gameUI
    local integer index = 0

    if MSR_FramesCreated then
        return
    endif
    set MSR_FramesCreated = true
    set gameUI = WidescreenFrameRoot_Get()
    call WidescreenFrameRoot_Refresh()
    set MSR_Root = BlzCreateFrameByType("FRAME", "ModernShortcutRailRoot", gameUI, "", 0)
    call BlzFrameSetSize(MSR_Root, 0.0001, 0.0001)
    call BlzFrameSetAbsPoint(MSR_Root, FRAMEPOINT_BOTTOMLEFT, 0.000, 0.000)
    call BlzFrameSetLevel(MSR_Root, 26)

    loop
        exitwhen index >= MSR_BUTTON_COUNT
        call MSR_CreateButton(index)
        set index = index + 1
    endloop
    call BlzFrameSetVisible(MSR_Button[MSR_ACTION_INSPECT], false)

    set MSR_Tooltip = BlzCreateFrameByType("BACKDROP", "ModernShortcutRailTooltip", MSR_Root, "EscMenuBackdrop", 0)
    call BlzFrameSetSize(MSR_Tooltip, 0.152, 0.042)
    call BlzFrameSetEnable(MSR_Tooltip, false)
    call BlzFrameSetLevel(MSR_Tooltip, 20)

    set MSR_TooltipText = BlzCreateFrameByType("TEXT", "ModernShortcutRailTooltipText", MSR_Tooltip, "", 0)
    call BlzFrameSetPoint(MSR_TooltipText, FRAMEPOINT_TOPLEFT, MSR_Tooltip, FRAMEPOINT_TOPLEFT, 0.008, -0.006)
    call BlzFrameSetPoint(MSR_TooltipText, FRAMEPOINT_BOTTOMRIGHT, MSR_Tooltip, FRAMEPOINT_BOTTOMRIGHT, -0.008, 0.006)
    call BlzFrameSetTextAlignment(MSR_TooltipText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(MSR_TooltipText, 0.72)
    call BlzFrameSetEnable(MSR_TooltipText, false)
    call BlzFrameSetLevel(MSR_TooltipText, 21)
    call BlzFrameSetVisible(MSR_Tooltip, false)

    call MSR_UpdateScreenLayout()
    call BlzFrameSetVisible(MSR_Root, false)
    set gameUI = null
endfunction

public function Refresh takes nothing returns nothing
    call MSR_Update()
endfunction

public function Enable takes nothing returns nothing
    set MSR_Enabled = true
    call MSR_Update()
endfunction

public function Disable takes nothing returns nothing
    set MSR_Enabled = false
    if MSR_FramesCreated then
        set MSR_Visible = false
        call BlzFrameSetVisible(MSR_Root, false)
        call BlzFrameSetVisible(MSR_Tooltip, false)
    endif
endfunction

public function IsEnabled takes nothing returns boolean
    return MSR_Enabled
endfunction

private function MSR_DelayedInit takes nothing returns nothing
    call MSR_CreateFrames()
    call MSR_Update()
    call DestroyTrigger(MSR_InitTrigger)
    set MSR_InitTrigger = null
endfunction

private function Init takes nothing returns nothing
    set MSR_ClickTrigger = CreateTrigger()
    call TriggerAddAction(MSR_ClickTrigger, function MSR_ClickAction)
    set MSR_EnterTrigger = CreateTrigger()
    call TriggerAddAction(MSR_EnterTrigger, function MSR_EnterAction)
    set MSR_LeaveTrigger = CreateTrigger()
    call TriggerAddAction(MSR_LeaveTrigger, function MSR_LeaveAction)
    set MSR_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(MSR_InitTrigger, 0.35, false)
    call TriggerAddAction(MSR_InitTrigger, function MSR_DelayedInit)
    call ModernPlayerHUD_RegisterUpdate(function MSR_Update)
endfunction

endlibrary
