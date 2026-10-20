/**
    ModernAbilityActionBar

    Author: Valdemar
    Version: 0.1.0

    Description:
    Renders the PotS-owned twelve-slot action bar with learned ability icons,
    cooldown shading, mana/readiness state, tooltips, and synchronized click
    activation. It hides the native bottom gameplay HUD without moving or
    reparenting engine-owned command buttons.

    Credits:
    - Blizzard Entertainment, Warcraft III frame API
    - Forgotten Hollow, compact lower-HUD and action-slot inspiration

    How to install:
    Import after Events, FullscreenUI, ModernPlayerHUD, AbilitiesPlayer,
    ShamanCommon, ModernAbilityCatalog, ModernAbilityLoadout, and
    ModernAbilityController.

    API:
    - call ModernAbilityActionBar_Enable()
    - call ModernAbilityActionBar_Disable()
    - call ModernAbilityActionBar_Refresh()
    - set enabled = ModernAbilityActionBar_IsEnabled()

**/
library ModernAbilityActionBar initializer Init requires Events, FullscreenUI, ModernPlayerHUD, AbilitiesPlayer, ShamanCommon, ModernAbilityCatalog, ModernAbilityLoadout, ModernAbilityController

globals
    private constant boolean MAB_AUTO_ENABLE = true
    private constant boolean MAB_HIDE_NATIVE_BOTTOM_HUD = true
    private constant real MAB_UPDATE_INTERVAL = 0.10

    private constant real MAB_ACTION_START_X = 0.190
    private constant real MAB_ACTION_BOTTOM = 0.012
    private constant real MAB_ACTION_SIZE = 0.032
    private constant real MAB_ACTION_GAP = 0.003
    private constant real MAB_TOOLTIP_WIDTH = 0.240
    private constant real MAB_TOOLTIP_HEIGHT = 0.092

    private constant string MAB_SURFACE_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private constant string MAB_EMPTY_ICON = "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"

    private boolean MAB_Initialized = false
    private boolean MAB_FramesCreated = false
    private boolean MAB_Enabled = false
    private boolean MAB_NativeCaptured = false

    private framehandle MAB_ScreenParent = null
    private framehandle MAB_Parent = null
    private framehandle MAB_HeroBorder = null
    private framehandle MAB_HeroIcon = null
    private framehandle MAB_TargetingText = null

    private framehandle array MAB_SlotButton
    private framehandle array MAB_SlotIcon
    private framehandle array MAB_SlotCooldown
    private framehandle array MAB_SlotCooldownText
    private framehandle array MAB_SlotKeyText
    private framehandle array MAB_SlotDisabled
    private framehandle array MAB_SlotTooltip
    private framehandle array MAB_SlotTooltipTitle
    private framehandle array MAB_SlotTooltipBody

    private framehandle array MAB_NativeFrame
    private boolean array MAB_NativeWasVisible
    private integer MAB_NativeFrameCount = 0

    private trigger MAB_SlotTrigger = null
    private trigger MAB_ClearFocusTrigger = null
    private trigger MAB_InitTrigger = null
    private timer MAB_UpdateTimer = null

    private unit MAB_SelectedUnit = null
endglobals

private function MAB_IsValidUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetHandleId(whichUnit) != 0 and GetUnitTypeId(whichUnit) != 0
endfunction

private function MAB_IsPlayerHero takes unit whichUnit returns boolean
    return MAB_IsValidUnit(whichUnit) and GetOwningPlayer(whichUnit) == Player(0) and ShamanCommon_IsPlayerHero(whichUnit)
endfunction

private function MAB_GetSlotLabel takes integer slot returns string
    if slot < 10 then
        return I2S(slot)
    elseif slot == 10 then
        return "0"
    elseif slot == 11 then
        return "-"
    endif
    return "="
endfunction

private function MAB_Clamp takes real value returns real
    if value < 0.00 then
        return 0.00
    elseif value > 1.00 then
        return 1.00
    endif
    return value
endfunction

private function MAB_RegisterNativeFrame takes framehandle whichFrame returns nothing
    if whichFrame != null then
        set MAB_NativeFrame[MAB_NativeFrameCount] = whichFrame
        set MAB_NativeFrameCount = MAB_NativeFrameCount + 1
    endif
    set whichFrame = null
endfunction

private function MAB_FindNativeFrames takes nothing returns nothing
    if MAB_NativeFrameCount > 0 then
        return
    endif

    call MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleBottomBar", 0))
    call MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleBottomBarOverlay", 0))
    call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BAR, 0))
    call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0))
    call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_PORTRAIT, 0))
endfunction

private function MAB_CaptureNativeVisibility takes nothing returns nothing
    local integer index = 0

    if MAB_NativeCaptured or FullscreenUI_IsEnabled() then
        return
    endif

    call MAB_FindNativeFrames()
    loop
        exitwhen index >= MAB_NativeFrameCount
        set MAB_NativeWasVisible[index] = BlzFrameIsVisible(MAB_NativeFrame[index])
        set index = index + 1
    endloop
    set MAB_NativeCaptured = true
endfunction

private function MAB_HideNativeFrames takes nothing returns nothing
    local integer index = 0

    if not MAB_HIDE_NATIVE_BOTTOM_HUD then
        return
    endif

    call MAB_CaptureNativeVisibility()
    if not MAB_NativeCaptured then
        return
    endif
    loop
        exitwhen index >= MAB_NativeFrameCount
        if BlzFrameIsVisible(MAB_NativeFrame[index]) then
            call BlzFrameSetVisible(MAB_NativeFrame[index], false)
        endif
        set index = index + 1
    endloop
endfunction

private function MAB_RestoreNativeFrames takes nothing returns nothing
    local integer index = 0

    if not MAB_NativeCaptured then
        return
    endif
    loop
        exitwhen index >= MAB_NativeFrameCount
        call BlzFrameSetVisible(MAB_NativeFrame[index], MAB_NativeWasVisible[index])
        set index = index + 1
    endloop
    set MAB_NativeCaptured = false
endfunction

private function MAB_SetCooldownVisual takes integer index, unit whichHero, integer abilityId, integer abilityLevel returns nothing
    local real remaining = BlzGetUnitAbilityCooldownRemaining(whichHero, abilityId)
    local real total = BlzGetUnitAbilityCooldown(whichHero, abilityId, abilityLevel - 1)
    local real ratio = 0.00

    if remaining > 0.00 then
        if total > 0.00 then
            set ratio = MAB_Clamp(remaining / total)
        else
            set ratio = 1.00
        endif
        call BlzFrameSetSize(MAB_SlotCooldown[index], MAB_ACTION_SIZE - 0.004, (MAB_ACTION_SIZE - 0.004) * ratio)
        call BlzFrameSetText(MAB_SlotCooldownText[index], I2S(R2I(remaining + 0.99)))
        call BlzFrameSetVisible(MAB_SlotCooldown[index], true)
        call BlzFrameSetVisible(MAB_SlotCooldownText[index], true)
    else
        call BlzFrameSetVisible(MAB_SlotCooldown[index], false)
        call BlzFrameSetVisible(MAB_SlotCooldownText[index], false)
    endif

    set whichHero = null
endfunction

private function MAB_UpdateSlot takes integer index, unit whichHero returns nothing
    local integer slot = index + 1
    local integer abilityId = ModernAbilityLoadout_GetEffectiveAbilityId(whichHero, slot)
    local integer entryIndex
    local integer abilityLevel
    local integer manaCost
    local real mana
    local string iconPath
    local string titleText
    local string bodyText
    local boolean ready

    if abilityId == 0 then
        call BlzFrameSetTexture(MAB_SlotIcon[index], MAB_EMPTY_ICON, 0, true)
        call BlzFrameSetVisible(MAB_SlotIcon[index], false)
        call BlzFrameSetVisible(MAB_SlotCooldown[index], false)
        call BlzFrameSetVisible(MAB_SlotCooldownText[index], false)
        call BlzFrameSetVisible(MAB_SlotDisabled[index], false)
        call BlzFrameSetEnable(MAB_SlotButton[index], false)
        call BlzFrameSetText(MAB_SlotTooltipTitle[index], "Empty slot")
        call BlzFrameSetText(MAB_SlotTooltipBody[index], "Choose a learned ability from the Abilities book.")
        set whichHero = null
        return
    endif

    set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
    set abilityLevel = GetUnitAbilityLevel(whichHero, abilityId)
    set ready = abilityLevel > 0 and ModernAbilityCatalog_IsRuntimeReady(abilityId)
    set iconPath = BlzGetAbilityIcon(abilityId)
    if iconPath == null or iconPath == "" then
        set iconPath = MAB_EMPTY_ICON
    endif

    call BlzFrameSetTexture(MAB_SlotIcon[index], iconPath, 0, true)
    call BlzFrameSetVisible(MAB_SlotIcon[index], true)
    call BlzFrameSetEnable(MAB_SlotButton[index], true)

    if abilityLevel > 0 then
        set manaCost = BlzGetUnitAbilityManaCost(whichHero, abilityId, abilityLevel - 1)
        set mana = GetUnitState(whichHero, UNIT_STATE_MANA)
        call MAB_SetCooldownVisual(index, whichHero, abilityId, abilityLevel)
    else
        set manaCost = 0
        set mana = 0.00
        call BlzFrameSetVisible(MAB_SlotCooldown[index], false)
        call BlzFrameSetVisible(MAB_SlotCooldownText[index], false)
    endif
    call BlzFrameSetVisible(MAB_SlotDisabled[index], not ready or mana + 0.01 < I2R(manaCost))

    set titleText = AbilitiesPlayer_GetEntryTitle(entryIndex)
    if ready then
        call BlzFrameSetText(MAB_SlotTooltipTitle[index], "|cffffe4a3" + titleText + "|r")
    else
        call BlzFrameSetText(MAB_SlotTooltipTitle[index], "|cff808080" + titleText + " - unavailable|r")
    endif
    set bodyText = AbilitiesPlayer_GetEntryBodyForLevel(entryIndex, abilityLevel)
    call BlzFrameSetText(MAB_SlotTooltipBody[index], bodyText)

    set whichHero = null
endfunction

private function MAB_UpdateTargetingText takes nothing returns nothing
    local player localPlayer = GetLocalPlayer()
    local integer abilityId
    local integer entryIndex

    if ModernAbilityController_IsTargetingLocal(localPlayer) then
        set abilityId = ModernAbilityController_GetPendingAbilityId(localPlayer)
        set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
        call BlzFrameSetText(MAB_TargetingText, "|cffffcc00Choose target:|r " + AbilitiesPlayer_GetEntryTitle(entryIndex) + "  |cffaaaaaa(Right-click cancels)|r")
        call BlzFrameSetVisible(MAB_TargetingText, true)
    else
        call BlzFrameSetVisible(MAB_TargetingText, false)
    endif

    set localPlayer = null
endfunction

private function MAB_Update takes nothing returns nothing
    local unit whichHero = MAB_SelectedUnit
    local integer index = 0
    local string heroIcon

    if not MAB_Enabled or not ModernPlayerHUD_IsEnabled() or FullscreenUI_IsEnabled() then
        if MAB_Parent != null then
            call BlzFrameSetVisible(MAB_Parent, false)
        endif
        set whichHero = null
        return
    endif

    call MAB_HideNativeFrames()
    if not MAB_IsValidUnit(whichHero) and GetLocalPlayer() == Player(0) and MAB_IsValidUnit(udg_Nazgrek) then
        set whichHero = udg_Nazgrek
        set MAB_SelectedUnit = whichHero
    endif
    if not MAB_IsPlayerHero(whichHero) then
        call BlzFrameSetVisible(MAB_Parent, false)
        set whichHero = null
        return
    endif

    call BlzFrameSetVisible(MAB_Parent, true)
    set heroIcon = BlzGetAbilityIcon(GetUnitTypeId(whichHero))
    if heroIcon == null or heroIcon == "" then
        set heroIcon = MAB_EMPTY_ICON
    endif
    call BlzFrameSetTexture(MAB_HeroIcon, heroIcon, 0, true)

    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        call MAB_UpdateSlot(index, whichHero)
        set index = index + 1
    endloop
    call MAB_UpdateTargetingText()

    set whichHero = null
endfunction

private function MAB_ClearFocusAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()

    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
    endif
    set triggerFrame = null
endfunction

private function MAB_SlotAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local player triggerPlayer = GetTriggerPlayer()
    local integer index = 0

    if triggerPlayer == GetLocalPlayer() and MAB_IsPlayerHero(MAB_SelectedUnit) then
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            if triggerFrame == MAB_SlotButton[index] then
                call ModernAbilityController_BeginLocal(triggerPlayer, MAB_SelectedUnit, index + 1)
                set index = ModernAbilityLoadout_SLOT_COUNT
            else
                set index = index + 1
            endif
        endloop
    endif

    set triggerFrame = null
    set triggerPlayer = null
endfunction

private function MAB_CreateSlot takes integer index returns nothing
    local real x = MAB_ACTION_START_X + I2R(index) * (MAB_ACTION_SIZE + MAB_ACTION_GAP)

    set MAB_SlotButton[index] = BlzCreateFrameByType("GLUEBUTTON", "ModernAbilityActionButton" + I2S(index), MAB_Parent, "ScoreScreenTabButtonTemplate", 0)
    call BlzFrameSetAbsPoint(MAB_SlotButton[index], FRAMEPOINT_BOTTOMLEFT, x, MAB_ACTION_BOTTOM)
    call BlzFrameSetSize(MAB_SlotButton[index], MAB_ACTION_SIZE, MAB_ACTION_SIZE)
    call BlzFrameSetLevel(MAB_SlotButton[index], 4)

    set MAB_SlotIcon[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityActionIcon" + I2S(index), MAB_SlotButton[index], "IconButtonTemplate", 0)
    call BlzFrameSetPoint(MAB_SlotIcon[index], FRAMEPOINT_BOTTOMLEFT, MAB_SlotButton[index], FRAMEPOINT_BOTTOMLEFT, 0.002, 0.002)
    call BlzFrameSetPoint(MAB_SlotIcon[index], FRAMEPOINT_TOPRIGHT, MAB_SlotButton[index], FRAMEPOINT_TOPRIGHT, -0.002, -0.002)
    call BlzFrameSetEnable(MAB_SlotIcon[index], false)
    call BlzFrameSetLevel(MAB_SlotIcon[index], 5)

    set MAB_SlotCooldown[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityCooldown" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetTexture(MAB_SlotCooldown[index], MAB_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(MAB_SlotCooldown[index], FRAMEPOINT_BOTTOM, MAB_SlotIcon[index], FRAMEPOINT_BOTTOM, 0.000, 0.000)
    call BlzFrameSetVertexColor(MAB_SlotCooldown[index], BlzConvertColor(190, 0, 0, 0))
    call BlzFrameSetEnable(MAB_SlotCooldown[index], false)
    call BlzFrameSetLevel(MAB_SlotCooldown[index], 6)

    set MAB_SlotDisabled[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityDisabled" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetTexture(MAB_SlotDisabled[index], MAB_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetAllPoints(MAB_SlotDisabled[index], MAB_SlotIcon[index])
    call BlzFrameSetVertexColor(MAB_SlotDisabled[index], BlzConvertColor(150, 30, 30, 30))
    call BlzFrameSetEnable(MAB_SlotDisabled[index], false)
    call BlzFrameSetLevel(MAB_SlotDisabled[index], 7)

    set MAB_SlotCooldownText[index] = BlzCreateFrameByType("TEXT", "ModernAbilityCooldownText" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetAllPoints(MAB_SlotCooldownText[index], MAB_SlotButton[index])
    call BlzFrameSetTextAlignment(MAB_SlotCooldownText[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MAB_SlotCooldownText[index], 0.82)
    call BlzFrameSetEnable(MAB_SlotCooldownText[index], false)
    call BlzFrameSetLevel(MAB_SlotCooldownText[index], 8)

    set MAB_SlotKeyText[index] = BlzCreateFrameByType("TEXT", "ModernAbilityKeyText" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetPoint(MAB_SlotKeyText[index], FRAMEPOINT_TOPLEFT, MAB_SlotButton[index], FRAMEPOINT_TOPLEFT, 0.003, -0.002)
    call BlzFrameSetSize(MAB_SlotKeyText[index], 0.012, 0.010)
    call BlzFrameSetTextAlignment(MAB_SlotKeyText[index], TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(MAB_SlotKeyText[index], 0.60)
    call BlzFrameSetText(MAB_SlotKeyText[index], MAB_GetSlotLabel(index + 1))
    call BlzFrameSetEnable(MAB_SlotKeyText[index], false)
    call BlzFrameSetLevel(MAB_SlotKeyText[index], 9)

    set MAB_SlotTooltip[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityTooltip" + I2S(index), MAB_ScreenParent, "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(MAB_SlotTooltip[index], FRAMEPOINT_BOTTOM, 0.400, 0.130)
    call BlzFrameSetSize(MAB_SlotTooltip[index], MAB_TOOLTIP_WIDTH, MAB_TOOLTIP_HEIGHT)
    call BlzFrameSetLevel(MAB_SlotTooltip[index], 40)

    set MAB_SlotTooltipTitle[index] = BlzCreateFrameByType("TEXT", "ModernAbilityTooltipTitle" + I2S(index), MAB_SlotTooltip[index], "", 0)
    call BlzFrameSetPoint(MAB_SlotTooltipTitle[index], FRAMEPOINT_TOPLEFT, MAB_SlotTooltip[index], FRAMEPOINT_TOPLEFT, 0.010, -0.010)
    call BlzFrameSetSize(MAB_SlotTooltipTitle[index], MAB_TOOLTIP_WIDTH - 0.020, 0.016)
    call BlzFrameSetTextAlignment(MAB_SlotTooltipTitle[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(MAB_SlotTooltipTitle[index], 0.86)
    call BlzFrameSetEnable(MAB_SlotTooltipTitle[index], false)

    set MAB_SlotTooltipBody[index] = BlzCreateFrameByType("TEXT", "ModernAbilityTooltipBody" + I2S(index), MAB_SlotTooltip[index], "", 0)
    call BlzFrameSetPoint(MAB_SlotTooltipBody[index], FRAMEPOINT_TOPLEFT, MAB_SlotTooltipTitle[index], FRAMEPOINT_BOTTOMLEFT, 0.000, -0.006)
    call BlzFrameSetSize(MAB_SlotTooltipBody[index], MAB_TOOLTIP_WIDTH - 0.020, MAB_TOOLTIP_HEIGHT - 0.036)
    call BlzFrameSetTextAlignment(MAB_SlotTooltipBody[index], TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(MAB_SlotTooltipBody[index], 0.72)
    call BlzFrameSetEnable(MAB_SlotTooltipBody[index], false)
    call BlzFrameSetTooltip(MAB_SlotButton[index], MAB_SlotTooltip[index])
    call BlzFrameSetVisible(MAB_SlotTooltip[index], false)

    call BlzTriggerRegisterFrameEvent(MAB_SlotTrigger, MAB_SlotButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MAB_ClearFocusTrigger, MAB_SlotButton[index], FRAMEEVENT_CONTROL_CLICK)
endfunction

private function MAB_CreateFrames takes nothing returns nothing
    local integer index = 0

    if MAB_FramesCreated then
        return
    endif
    set MAB_FramesCreated = true
    set MAB_ScreenParent = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    set MAB_Parent = BlzCreateFrameByType("FRAME", "ModernAbilityActionBar", MAB_ScreenParent, "", 0)
    call BlzFrameSetAllPoints(MAB_Parent, MAB_ScreenParent)
    call BlzFrameSetLevel(MAB_Parent, 30)

    set MAB_HeroBorder = BlzCreateFrameByType("BACKDROP", "ModernAbilityHeroBorder", MAB_Parent, "", 0)
    call BlzFrameSetTexture(MAB_HeroBorder, MAB_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetAbsPoint(MAB_HeroBorder, FRAMEPOINT_BOTTOMLEFT, 0.126, 0.012)
    call BlzFrameSetSize(MAB_HeroBorder, 0.052, 0.052)
    call BlzFrameSetVertexColor(MAB_HeroBorder, BlzConvertColor(255, 110, 82, 40))
    call BlzFrameSetEnable(MAB_HeroBorder, false)
    call BlzFrameSetLevel(MAB_HeroBorder, 4)

    set MAB_HeroIcon = BlzCreateFrameByType("BACKDROP", "ModernAbilityHeroIcon", MAB_HeroBorder, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(MAB_HeroIcon, FRAMEPOINT_BOTTOMLEFT, MAB_HeroBorder, FRAMEPOINT_BOTTOMLEFT, 0.003, 0.003)
    call BlzFrameSetPoint(MAB_HeroIcon, FRAMEPOINT_TOPRIGHT, MAB_HeroBorder, FRAMEPOINT_TOPRIGHT, -0.003, -0.003)
    call BlzFrameSetEnable(MAB_HeroIcon, false)
    call BlzFrameSetLevel(MAB_HeroIcon, 5)

    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        call MAB_CreateSlot(index)
        set index = index + 1
    endloop

    set MAB_TargetingText = BlzCreateFrameByType("TEXT", "ModernAbilityTargetingText", MAB_Parent, "", 0)
    call BlzFrameSetAbsPoint(MAB_TargetingText, FRAMEPOINT_BOTTOM, 0.400, 0.118)
    call BlzFrameSetSize(MAB_TargetingText, 0.420, 0.016)
    call BlzFrameSetTextAlignment(MAB_TargetingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MAB_TargetingText, 0.78)
    call BlzFrameSetEnable(MAB_TargetingText, false)
    call BlzFrameSetLevel(MAB_TargetingText, 12)
    call BlzFrameSetVisible(MAB_TargetingText, false)
    call BlzFrameSetVisible(MAB_Parent, false)
endfunction

public function Refresh takes nothing returns nothing
    call MAB_Update()
endfunction

public function Enable takes nothing returns nothing
    if not MAB_Initialized then
        return
    endif
    if not MAB_FramesCreated then
        call MAB_CreateFrames()
    endif
    set MAB_Enabled = true
    call TimerStart(MAB_UpdateTimer, MAB_UPDATE_INTERVAL, true, function MAB_Update)
    call MAB_Update()
endfunction

public function Disable takes nothing returns nothing
    set MAB_Enabled = false
    call PauseTimer(MAB_UpdateTimer)
    call ModernAbilityController_CancelLocal(GetLocalPlayer())
    if MAB_Parent != null then
        call BlzFrameSetVisible(MAB_Parent, false)
    endif
    call MAB_RestoreNativeFrames()
endfunction

public function IsEnabled takes nothing returns boolean
    return MAB_Enabled
endfunction

private function MAB_OnUnitSelected takes nothing returns nothing
    local unit selectedUnit = GetTriggerUnit()
    local player selectingPlayer = GetTriggerPlayer()

    if selectingPlayer == GetLocalPlayer() then
        set MAB_SelectedUnit = selectedUnit
    endif
    set selectedUnit = null
    set selectingPlayer = null
endfunction

private function MAB_OnUnitDeselected takes nothing returns nothing
    local unit deselectedUnit = GetTriggerUnit()
    local player deselectingPlayer = GetTriggerPlayer()

    if deselectingPlayer == GetLocalPlayer() and MAB_SelectedUnit == deselectedUnit then
        set MAB_SelectedUnit = null
    endif
    set deselectedUnit = null
    set deselectingPlayer = null
endfunction

private function MAB_DelayedInit takes nothing returns nothing
    call MAB_CreateFrames()
    if MAB_AUTO_ENABLE then
        call Enable()
    endif
    call DestroyTrigger(MAB_InitTrigger)
    set MAB_InitTrigger = null
endfunction

private function Init takes nothing returns nothing
    if MAB_Initialized then
        return
    endif
    set MAB_Initialized = true

    set MAB_SlotTrigger = CreateTrigger()
    call TriggerAddAction(MAB_SlotTrigger, function MAB_SlotAction)
    set MAB_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(MAB_ClearFocusTrigger, function MAB_ClearFocusAction)
    set MAB_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(MAB_InitTrigger, 0.25, false)
    call TriggerAddAction(MAB_InitTrigger, function MAB_DelayedInit)
    set MAB_UpdateTimer = CreateTimer()

    call Events_RegisterPlayerUnitEvent(function MAB_OnUnitSelected, EVENT_PLAYER_UNIT_SELECTED)
    call Events_RegisterPlayerUnitEvent(function MAB_OnUnitDeselected, EVENT_PLAYER_UNIT_DESELECTED)
endfunction

endlibrary
