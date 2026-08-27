/**
    MasterUI
    
    Author: Valdemar
    Version: 1.0

    Description: Serves as the main in-game menu for opening the different info and utility panels.

    Credits: Tasyen (TasQuestBox as inspiration)

    How to install:
    Import after Table and Interface and before panels that return to MasterUI.

    API:
    - call MasterUI_Show()
    - call MasterUI_Hide()
    - call MasterUI_Toggle()
    - call MasterUI_ShowGameButton()
    - call MasterUI_HideGameButton()
    - call MasterUI_IsGameButtonVisible()
    - call MasterUI_ClosePanels()
    - call MasterUI_SetHintsUnread(true)

    Pressing ESC closes MasterUI and every panel registered in its centralized
    hide list.

**/
library MasterUI initializer AutoInit requires Table, Interface

globals
    private boolean MUI_Initialized = false
    private boolean MUI_OpenButtonVisible = false
    private boolean MUI_HintsUnread = false

    private framehandle MUI_Parent = null
    private framehandle MUI_OpenButton = null
    private framehandle MUI_OpenButtonHintAlert = null
    private framehandle MUI_HintsButtonAlert = null
    private framehandle MUI_CloseButton = null
    private framehandle MUI_Title = null
    private framehandle array MUI_MenuButton
    private framehandle array MUI_MenuButtonIcon
    private Table MUI_ButtonAction = 0

    private trigger MUI_OpenTrigger = null
    private trigger MUI_CloseTrigger = null
    private trigger MUI_MenuTrigger = null
    private trigger MUI_EscapeTrigger = null
    private trigger MUI_ClearFocusTrigger = null
    private trigger MUI_InitTrigger = null
    private timer MUI_HintFlashTimer = null

    private constant integer MUI_ACTION_ZONES = 1
    private constant integer MUI_ACTION_PROFESSIONS = 2
    private constant integer MUI_ACTION_REPUTATIONS = 3
    private constant integer MUI_ACTION_STATS = 4
    private constant integer MUI_ACTION_ABILITIES = 5
    private constant integer MUI_ACTION_CAMERA = 6
    private constant integer MUI_ACTION_HINTS = 7
    private constant integer MUI_ACTION_ACHIEVEMENTS = 8
    private constant integer MUI_ACTION_SECRETS = 9
    private constant integer MUI_ACTION_COMMANDS = 10
    private constant integer MUI_ACTION_PLAYER_HOME = 11
    private constant integer MUI_ACTION_SETTINGS = 12

    private constant real MUI_PANEL_LEFT = 0.110
    private constant real MUI_PANEL_RIGHT = 0.560
    private constant real MUI_PANEL_TOP = 0.550
    private constant real MUI_PANEL_BOTTOM = 0.285
    private constant real MUI_TITLE_WIDTH = 0.330
    private constant real MUI_MENU_BUTTON_WIDTH = 0.120
    private constant real MUI_MENU_BUTTON_HEIGHT = 0.036
    private constant real MUI_MENU_ICON_SIZE = 0.016
    private constant real MUI_MENU_ICON_OFFSET_X = 0.006
    private constant real MUI_MENU_TEXT_OFFSET_X = 0.027
    private constant real MUI_MENU_TEXT_TOP_OFFSET = -0.004
    private constant real MUI_MENU_TEXT_RIGHT_OFFSET = -0.004
    private constant real MUI_MENU_TEXT_BOTTOM_OFFSET = 0.004
    private constant real MUI_HINT_FLASH_DURATION = 2.00
    private constant string MUI_HINT_ALERT_MODEL = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"

    // Set any icon path to "" to keep that menu button text-only.
    private constant string MUI_ICON_STATS = "ReplaceableTextures\\WorldEditUI\\Editor-MultipleUnits.blp"           // OK? or use attribute bonus icon?
    private constant string MUI_ICON_REPUTATIONS = "ReplaceableTextures\\PassiveButtons\\PASFactionHorde.blp"       // OK?
    private constant string MUI_ICON_ZONES = "ReplaceableTextures\\CommandButtons\\BTNMap03.blp"                     // OK
    private constant string MUI_ICON_PROFESSIONS = "ReplaceableTextures\\CommandButtons\\BTNTrade11.blp"             // OK
    private constant string MUI_ICON_ABILITIES = "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"              // OK
    private constant string MUI_ICON_CAMERA = "ReplaceableTextures\\WorldEditUI\\Doodad-Cinematic.blp"              // OK
    private constant string MUI_ICON_HINTS = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Note_01.blp"         // OK
    private constant string MUI_ICON_ACHIEVEMENTS = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Note_02.blp"  // OK
    private constant string MUI_ICON_SECRETS = "ReplaceableTextures\\CommandButtons\\BTNTicket_Tarot_Madness.blp"   // OK?
    private constant string MUI_ICON_COMMANDS = "ReplaceableTextures\\CommandButtons\\BTNTicket_Tarot_Lunacy.blp"     // OK?
    private constant string MUI_ICON_PLAYER_HOME = "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"
    private constant string MUI_ICON_SETTINGS = "ReplaceableTextures\\CommandButtons\\BTNEngineeringUpgrade.blp"     // OK
endglobals

private function MUI_FormatButtonLabel takes string label returns string
    if StringLength(label) <= 0 then
        return label
    endif
    return "|cffffffff" + SubString(label, 0, 1) + "|r|cffffcc00" + SubString(label, 1, StringLength(label)) + "|r"
endfunction

private function MUI_GetMenuTitle takes nothing returns string
    return "|cffffffffP|r|cffffcc00ath |r|cffffffffo|r|cffffcc00f |r|cfffffffft|r|cffffcc00he |r|cffffffffS|r|cffffcc00haman|r"
endfunction

private function MUI_PosOpenButton takes framehandle frame returns nothing
    local framehandle zoneButton = BlzGetFrameByName("MapInfoButton", 0)

    call BlzFrameClearAllPoints(frame)
    if zoneButton != null and GetHandleId(zoneButton) != 0 then
        call BlzFrameSetAllPoints(frame, zoneButton)
    else
        call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.738, 0.600)
        call BlzFrameSetAbsPoint(frame, FRAMEPOINT_BOTTOMRIGHT, 0.858, 0.565)
    endif

    set zoneButton = null
endfunction

private function MUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function MUI_HideMaster takes nothing returns nothing
    if MUI_Parent != null then
        call BlzFrameSetVisible(MUI_Parent, false)
    endif
endfunction

private function MUI_ApplyOpenButtonVisibility takes nothing returns nothing
    if not MUI_OpenButtonVisible then
        call MUI_HideMaster()
    endif
    if MUI_OpenButton != null then
        call BlzFrameSetVisible(MUI_OpenButton, MUI_OpenButtonVisible)
    endif
endfunction

private function MUI_ApplyHintsUnreadState takes nothing returns nothing
    if MUI_HintsButtonAlert != null then
        call BlzFrameSetVisible(MUI_HintsButtonAlert, MUI_HintsUnread)
    endif
endfunction

private function MUI_HideHintOpenButtonAlert takes nothing returns nothing
    if MUI_OpenButtonHintAlert != null then
        call BlzFrameSetVisible(MUI_OpenButtonHintAlert, false)
    endif
endfunction

private function MUI_FlashHintOpenButton takes nothing returns nothing
    if MUI_OpenButtonHintAlert != null and MUI_HintFlashTimer != null then
        call BlzFrameSetSpriteAnimate(MUI_OpenButtonHintAlert, 0, 0)
        call BlzFrameSetVisible(MUI_OpenButtonHintAlert, true)
        call TimerStart(MUI_HintFlashTimer, MUI_HINT_FLASH_DURATION, false, function MUI_HideHintOpenButtonAlert)
    endif
endfunction

public function SetHintsUnread takes boolean unread returns nothing
    set MUI_HintsUnread = unread
    call MUI_ApplyHintsUnreadState()
    if unread then
        call MUI_FlashHintOpenButton()
    else
        if MUI_HintFlashTimer != null then
            call PauseTimer(MUI_HintFlashTimer)
        endif
        call MUI_HideHintOpenButtonAlert()
    endif
endfunction

private function MUI_HideAllPanels takes nothing returns nothing
    call ExecuteFunc("DInventoryEquipment_Hide")
    call ExecuteFunc("TasQuestBox_Hide")
    call ExecuteFunc("ProfessionsUI_Hide")
    call ExecuteFunc("CraftingUI_Hide")
    call ExecuteFunc("ReputationUI_Hide")
    call ExecuteFunc("StatsUI_Hide")
    call ExecuteFunc("AbilitiesLiteUI_Hide")
    call ExecuteFunc("AbilitiesUI_Hide")
    call ExecuteFunc("TalentsUI_Hide")
    call ExecuteFunc("CameraUI_Hide")
    call ExecuteFunc("HintsUI_Hide")
    call ExecuteFunc("AchievementsUI_Hide")
    call ExecuteFunc("SecretsUI_Hide")
    call ExecuteFunc("CommandsUI_Hide")
    call ExecuteFunc("PlayerHomeUI_Hide")
    call ExecuteFunc("SettingsUI_Hide")
    static if LIBRARY_QuestUI then
        call ExecuteFunc("QuestUI_Hide")
    endif
endfunction

public function ClosePanels takes nothing returns nothing
    call MUI_HideMaster()
    call MUI_HideAllPanels()
endfunction

private function MUI_HideAllPanelsForCinematic takes nothing returns nothing
    call MUI_HideMaster()
    call MUI_HideAllPanels()
    call ExecuteFunc("ShopUI_HideForCinematic")
    call ExecuteFunc("StatsLiteUI_HideForCinematic")
endfunction

private function MUI_ShowPlaceholder takes string featureName returns nothing
    call MUI_HideAllPanels()
    call DisplayTextToPlayer(Player(0), 0, 0, "|cffffcc00" + featureName + "|r is not implemented yet.")
endfunction

private function MUI_OpenZones takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("TasQuestBox_Show")
endfunction

private function MUI_OpenProfessions takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("ProfessionsUI_Show")
endfunction

private function MUI_OpenReputations takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("ReputationUI_Show")
endfunction

private function MUI_OpenStats takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("StatsUI_Show")
endfunction

private function MUI_OpenAbilities takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("AbilitiesLiteUI_Show")
endfunction

private function MUI_OpenCamera takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("CameraUI_Show")
endfunction

private function MUI_OpenHints takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("HintsUI_Show")
endfunction

private function MUI_OpenAchievements takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("AchievementsUI_Show")
endfunction

private function MUI_OpenSecrets takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("SecretsUI_Show")
endfunction

private function MUI_OpenCommands takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("CommandsUI_Show")
endfunction

private function MUI_OpenPlayerHome takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("PlayerHomeUI_Show")
endfunction

private function MUI_OpenSettings takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("SettingsUI_Show")
endfunction

private function MUI_RunAction takes integer actionId returns nothing
    if actionId == MUI_ACTION_ZONES then
        call MUI_OpenZones()
    elseif actionId == MUI_ACTION_PROFESSIONS then
        call MUI_OpenProfessions()
    elseif actionId == MUI_ACTION_REPUTATIONS then
        call MUI_OpenReputations()
    elseif actionId == MUI_ACTION_STATS then
        call MUI_OpenStats()
    elseif actionId == MUI_ACTION_ABILITIES then
        call MUI_OpenAbilities()
    elseif actionId == MUI_ACTION_CAMERA then
        call MUI_OpenCamera()
    elseif actionId == MUI_ACTION_HINTS then
        call MUI_OpenHints()
    elseif actionId == MUI_ACTION_ACHIEVEMENTS then
        call MUI_OpenAchievements()
    elseif actionId == MUI_ACTION_SECRETS then
        call MUI_OpenSecrets()
    elseif actionId == MUI_ACTION_COMMANDS then
        call MUI_OpenCommands()
    elseif actionId == MUI_ACTION_PLAYER_HOME then
        call MUI_OpenPlayerHome()
    elseif actionId == MUI_ACTION_SETTINGS then
        call MUI_OpenSettings()
    endif
endfunction

private function MUI_OpenAction takes nothing returns nothing
    local boolean showPanel

    call MUI_HideAllPanels()
    if GetLocalPlayer() == GetTriggerPlayer() then
        set showPanel = not BlzFrameIsVisible(MUI_Parent)
        call BlzFrameSetVisible(MUI_Parent, showPanel)
        if showPanel then
            call Interface_NotifyUIOpened()
        else
            call Interface_NotifyUIClosed()
        endif
    endif
endfunction

private function MUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        if BlzFrameIsVisible(MUI_Parent) then
            call Interface_NotifyUIClosed()
        endif
        call BlzFrameSetVisible(MUI_Parent, false)
    endif
endfunction

private function MUI_EscapeAction takes nothing returns nothing
    if GetTriggerPlayer() != Player(0) then
        return
    endif

    if GetLocalPlayer() == GetTriggerPlayer() then
        if MUI_Parent != null and BlzFrameIsVisible(MUI_Parent) then
            call Interface_NotifyUIClosed()
        endif
        call MUI_HideMaster()
    endif
    call MUI_HideAllPanels()
endfunction

private function MUI_MenuAction takes nothing returns nothing
    local integer handleId = GetHandleId(BlzGetTriggerFrame())

    if MUI_ButtonAction.has(handleId) then
        call MUI_RunAction(MUI_ButtonAction.integer[handleId])
        call MUI_HideMaster()
    endif
endfunction

private function MUI_CreateMenuButton takes integer index, string label, string iconPath, integer actionId, real x, real y returns nothing
    local framehandle iconFrame = null
    local framehandle textFrame = null
    local real textLeftOffset = 0.008

    set MUI_MenuButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "MasterUIMenuButton" + I2S(index), MUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(MUI_MenuButton[index], MUI_MENU_BUTTON_WIDTH, MUI_MENU_BUTTON_HEIGHT)
    call BlzFrameSetPoint(MUI_MenuButton[index], FRAMEPOINT_TOPLEFT, MUI_Parent, FRAMEPOINT_TOPLEFT, x, y)
    call BlzFrameSetText(MUI_MenuButton[index], "")

    if iconPath != "" then
        set iconFrame = BlzCreateFrameByType("BACKDROP", "MasterUIMenuButtonIcon" + I2S(index), MUI_MenuButton[index], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(iconFrame, FRAMEPOINT_LEFT, MUI_MenuButton[index], FRAMEPOINT_LEFT, MUI_MENU_ICON_OFFSET_X, 0.0)
        call BlzFrameSetSize(iconFrame, MUI_MENU_ICON_SIZE, MUI_MENU_ICON_SIZE)
        call BlzFrameSetTexture(iconFrame, iconPath, 0, true)
        set MUI_MenuButtonIcon[index] = iconFrame
        set textLeftOffset = MUI_MENU_TEXT_OFFSET_X
    endif

    set textFrame = BlzCreateFrameByType("TEXT", "MasterUIMenuButtonText" + I2S(index), MUI_MenuButton[index], "", 0)
    call BlzFrameSetPoint(textFrame, FRAMEPOINT_TOPLEFT, MUI_MenuButton[index], FRAMEPOINT_TOPLEFT, textLeftOffset, MUI_MENU_TEXT_TOP_OFFSET)
    call BlzFrameSetPoint(textFrame, FRAMEPOINT_BOTTOMRIGHT, MUI_MenuButton[index], FRAMEPOINT_BOTTOMRIGHT, MUI_MENU_TEXT_RIGHT_OFFSET, MUI_MENU_TEXT_BOTTOM_OFFSET)
    call BlzFrameSetTextAlignment(textFrame, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetText(textFrame, MUI_FormatButtonLabel(label))
    call BlzFrameSetEnable(textFrame, false)

    call BlzTriggerRegisterFrameEvent(MUI_MenuTrigger, MUI_MenuButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MUI_ClearFocusTrigger, MUI_MenuButton[index], FRAMEEVENT_CONTROL_CLICK)
    set MUI_ButtonAction.integer[GetHandleId(MUI_MenuButton[index])] = actionId

    set textFrame = null
    set iconFrame = null
endfunction

private function MUI_CreateHintAlert takes framehandle parent, string frameName, real modelScale returns framehandle
    local framehandle alertFrame = BlzCreateFrameByType("SPRITE", frameName, parent, "", 0)

    call BlzFrameSetAllPoints(alertFrame, parent)
    call BlzFrameSetModel(alertFrame, MUI_HINT_ALERT_MODEL, 0)
    call BlzFrameSetScale(alertFrame, modelScale)
    call BlzFrameSetLevel(alertFrame, 7)
    call BlzFrameSetEnable(alertFrame, false)
    call BlzFrameSetVisible(alertFrame, false)
    return alertFrame
endfunction

private function MUI_CreateFrames takes nothing returns nothing
    set MUI_Parent = BlzCreateFrameByType("BACKDROP", "MasterUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(MUI_Parent, FRAMEPOINT_TOPLEFT, MUI_PANEL_LEFT, MUI_PANEL_TOP)
    call BlzFrameSetAbsPoint(MUI_Parent, FRAMEPOINT_BOTTOMRIGHT, MUI_PANEL_RIGHT, MUI_PANEL_BOTTOM)

    set MUI_Title = BlzCreateFrameByType("TEXT", "MasterUITitle", MUI_Parent, "", 0)
    call BlzFrameSetPoint(MUI_Title, FRAMEPOINT_TOP, MUI_Parent, FRAMEPOINT_TOP, 0.0, -0.018)
    call BlzFrameSetSize(MUI_Title, MUI_TITLE_WIDTH, 0.024)
    call BlzFrameSetTextAlignment(MUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MUI_Title, 1.22)
    call BlzFrameSetEnable(MUI_Title, false)
    call BlzFrameSetText(MUI_Title, MUI_GetMenuTitle())

    set MUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "MasterUIClose", MUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(MUI_CloseButton, 0.03, 0.03)
    call BlzFrameSetText(MUI_CloseButton, "X")
    call BlzFrameSetPoint(MUI_CloseButton, FRAMEPOINT_TOPRIGHT, MUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
    call BlzTriggerRegisterFrameEvent(MUI_CloseTrigger, MUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MUI_ClearFocusTrigger, MUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

    call MUI_CreateMenuButton(1, "Stats", MUI_ICON_STATS, MUI_ACTION_STATS, 0.020, -0.060)
    call MUI_CreateMenuButton(2, "Reputations", MUI_ICON_REPUTATIONS, MUI_ACTION_REPUTATIONS, 0.020, -0.102)
    call MUI_CreateMenuButton(3, "Zones", MUI_ICON_ZONES, MUI_ACTION_ZONES, 0.020, -0.144)
    call MUI_CreateMenuButton(4, "Professions", MUI_ICON_PROFESSIONS, MUI_ACTION_PROFESSIONS, 0.020, -0.186)

    call MUI_CreateMenuButton(5, "Abilities", MUI_ICON_ABILITIES, MUI_ACTION_ABILITIES, 0.160, -0.060)
    call MUI_CreateMenuButton(6, "Hints", MUI_ICON_HINTS, MUI_ACTION_HINTS, 0.160, -0.102)
    call MUI_CreateMenuButton(7, "Achievements", MUI_ICON_ACHIEVEMENTS, MUI_ACTION_ACHIEVEMENTS, 0.160, -0.144)
    call MUI_CreateMenuButton(8, "Secrets", MUI_ICON_SECRETS, MUI_ACTION_SECRETS, 0.160, -0.186)

    call MUI_CreateMenuButton(9, "Camera", MUI_ICON_CAMERA, MUI_ACTION_CAMERA, 0.300, -0.060)
    call MUI_CreateMenuButton(10, "Commands", MUI_ICON_COMMANDS, MUI_ACTION_COMMANDS, 0.300, -0.102)
    call MUI_CreateMenuButton(11, "Traveler's Journal", MUI_ICON_PLAYER_HOME, MUI_ACTION_PLAYER_HOME, 0.300, -0.144)
    call MUI_CreateMenuButton(12, "Settings", MUI_ICON_SETTINGS, MUI_ACTION_SETTINGS, 0.300, -0.186)

    set MUI_HintsButtonAlert = MUI_CreateHintAlert(MUI_MenuButton[6], "MasterUIHintsButtonAlert", 0.76)

    set MUI_OpenButton = BlzCreateFrameByType("GLUETEXTBUTTON", "MasterUIOpenButton", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "ScriptDialogButton", 0)
    call MUI_PosOpenButton(MUI_OpenButton)
    call BlzFrameSetText(MUI_OpenButton, "|cffffffffGame|r")
    call BlzTriggerRegisterFrameEvent(MUI_OpenTrigger, MUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MUI_ClearFocusTrigger, MUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)
    call MUI_ApplyOpenButtonVisibility()
    set MUI_OpenButtonHintAlert = MUI_CreateHintAlert(MUI_OpenButton, "MasterUIOpenButtonHintAlert", 0.76)
    call MUI_ApplyHintsUnreadState()
    if MUI_HintsUnread then
        call MUI_FlashHintOpenButton()
    endif

    call BlzFrameSetVisible(MUI_Parent, false)
endfunction

private function MUI_DelayedInit takes nothing returns nothing
    call MUI_CreateFrames()
endfunction

public function Init takes nothing returns nothing
    if MUI_Initialized then
        return
    endif
    set MUI_Initialized = true

    set MUI_ButtonAction = Table.create()
    set MUI_HintFlashTimer = CreateTimer()

    set MUI_OpenTrigger = CreateTrigger()
    call TriggerAddAction(MUI_OpenTrigger, function MUI_OpenAction)

    set MUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(MUI_CloseTrigger, function MUI_CloseAction)

    set MUI_MenuTrigger = CreateTrigger()
    call TriggerAddAction(MUI_MenuTrigger, function MUI_MenuAction)

    set MUI_EscapeTrigger = CreateTrigger()
    call BlzTriggerRegisterPlayerKeyEvent(MUI_EscapeTrigger, Player(0), OSKEY_ESCAPE, 0, true)
    call TriggerAddAction(MUI_EscapeTrigger, function MUI_EscapeAction)

    set MUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(MUI_ClearFocusTrigger, function MUI_ClearFocusAction)

    set MUI_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(MUI_InitTrigger, 0.20, false)
    call TriggerAddAction(MUI_InitTrigger, function MUI_DelayedInit)
endfunction

public function Show takes nothing returns nothing
    if not MUI_Initialized then
        call Init()
    endif
    if MUI_Parent != null then
        call MUI_HideAllPanels()
        if not BlzFrameIsVisible(MUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
        endif
        call BlzFrameSetVisible(MUI_Parent, true)
    endif
endfunction

public function Hide takes nothing returns nothing
    if MUI_Parent != null then
        if BlzFrameIsVisible(MUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
        endif
        call BlzFrameSetVisible(MUI_Parent, false)
    endif
endfunction

public function ShowGameButton takes nothing returns nothing
    if not MUI_Initialized then
        call Init()
    endif
    set MUI_OpenButtonVisible = true
    call MUI_ApplyOpenButtonVisibility()
    static if LIBRARY_QuestUI then
        call ExecuteFunc("QuestUI_ShowButton")
    endif
    call ExecuteFunc("StatsLiteUI_ShowAfterCinematic")
endfunction

public function HideGameButton takes nothing returns nothing
    if not MUI_Initialized then
        call Init()
    endif
    call MUI_HideAllPanelsForCinematic()
    set MUI_OpenButtonVisible = false
    call MUI_ApplyOpenButtonVisibility()
    static if LIBRARY_QuestUI then
        call ExecuteFunc("QuestUI_HideButton")
    endif
endfunction

public function IsGameButtonVisible takes nothing returns boolean
    if not MUI_Initialized then
        call Init()
    endif
    return MUI_OpenButtonVisible
endfunction

public function Toggle takes nothing returns nothing
    if not MUI_Initialized then
        call Init()
    endif
    if MUI_Parent != null then
        if BlzFrameIsVisible(MUI_Parent) then
            call Hide()
        else
            call Show()
        endif
    endif
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
