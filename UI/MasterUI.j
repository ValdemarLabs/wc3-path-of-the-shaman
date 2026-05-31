library MasterUI initializer AutoInit requires Table
/**
    MasterUI
    
    Author: [Valdemar]
    Version: 1.0

    Description: Serves as the main in-game menu for opening the different info and utility panels.

    Credits: Tasyen (TasQuestBox as inspiration)

**/

globals
    private boolean MUI_Initialized = false

    private framehandle MUI_Parent = null
    private framehandle MUI_OpenButton = null
    private framehandle MUI_CloseButton = null
    private framehandle MUI_Title = null
    private framehandle array MUI_MenuButton
    private Table MUI_ButtonAction = 0

    private trigger MUI_OpenTrigger = null
    private trigger MUI_CloseTrigger = null
    private trigger MUI_MenuTrigger = null
    private trigger MUI_ClearFocusTrigger = null
    private trigger MUI_InitTrigger = null

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
    private constant integer MUI_ACTION_CHEATS = 11
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

private function MUI_HideAllPanels takes nothing returns nothing
    call ExecuteFunc("TasQuestBox_Hide")
    call ExecuteFunc("ProfessionsUI_Hide")
    call ExecuteFunc("ReputationUI_Hide")
    call ExecuteFunc("StatsUI_Hide")
    call ExecuteFunc("AbilitiesLiteUI_Hide")
    call ExecuteFunc("CameraUI_Hide")
    call ExecuteFunc("HintsUI_Hide")
    call ExecuteFunc("AchievementsUI_Hide")
    call ExecuteFunc("SecretsUI_Hide")
    call ExecuteFunc("CommandsUI_Hide")
    call ExecuteFunc("CheatsUI_Hide")
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

private function MUI_OpenCheats takes nothing returns nothing
    call MUI_HideAllPanels()
    call ExecuteFunc("CheatsUI_Show")
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
    elseif actionId == MUI_ACTION_CHEATS then
        call MUI_OpenCheats()
    endif
endfunction

private function MUI_OpenAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(MUI_Parent, not BlzFrameIsVisible(MUI_Parent))
    endif
endfunction

private function MUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(MUI_Parent, false)
    endif
endfunction

private function MUI_MenuAction takes nothing returns nothing
    local integer handleId = GetHandleId(BlzGetTriggerFrame())

    if MUI_ButtonAction.has(handleId) then
        call MUI_RunAction(MUI_ButtonAction.integer[handleId])
        call MUI_HideMaster()
    endif
endfunction

private function MUI_CreateMenuButton takes integer index, string label, integer actionId, real x, real y returns nothing
    set MUI_MenuButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "MasterUIMenuButton" + I2S(index), MUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(MUI_MenuButton[index], 0.105, 0.036)
    call BlzFrameSetPoint(MUI_MenuButton[index], FRAMEPOINT_TOPLEFT, MUI_Parent, FRAMEPOINT_TOPLEFT, x, y)
    call BlzFrameSetText(MUI_MenuButton[index], MUI_FormatButtonLabel(label))
    call BlzTriggerRegisterFrameEvent(MUI_MenuTrigger, MUI_MenuButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MUI_ClearFocusTrigger, MUI_MenuButton[index], FRAMEEVENT_CONTROL_CLICK)
    set MUI_ButtonAction.integer[GetHandleId(MUI_MenuButton[index])] = actionId
endfunction

private function MUI_CreateFrames takes nothing returns nothing
    set MUI_Parent = BlzCreateFrameByType("BACKDROP", "MasterUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(MUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
    call BlzFrameSetAbsPoint(MUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.530, 0.285)

    set MUI_Title = BlzCreateFrameByType("TEXT", "MasterUITitle", MUI_Parent, "", 0)
    call BlzFrameSetPoint(MUI_Title, FRAMEPOINT_TOP, MUI_Parent, FRAMEPOINT_TOP, 0.0, -0.018)
    call BlzFrameSetSize(MUI_Title, 0.290, 0.024)
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

    call MUI_CreateMenuButton(1, "Stats", MUI_ACTION_STATS, 0.020, -0.060)
    call MUI_CreateMenuButton(2, "Reputations", MUI_ACTION_REPUTATIONS, 0.020, -0.102)
    call MUI_CreateMenuButton(3, "Zones", MUI_ACTION_ZONES, 0.020, -0.144)
    call MUI_CreateMenuButton(4, "Professions", MUI_ACTION_PROFESSIONS, 0.020, -0.186)

    call MUI_CreateMenuButton(5, "Abilities", MUI_ACTION_ABILITIES, 0.155, -0.060)
    call MUI_CreateMenuButton(6, "Hints", MUI_ACTION_HINTS, 0.155, -0.102)
    call MUI_CreateMenuButton(7, "Achievements", MUI_ACTION_ACHIEVEMENTS, 0.155, -0.144)
    call MUI_CreateMenuButton(8, "Secrets", MUI_ACTION_SECRETS, 0.155, -0.186)

    call MUI_CreateMenuButton(9, "Camera", MUI_ACTION_CAMERA, 0.290, -0.060)
    call MUI_CreateMenuButton(10, "Commands", MUI_ACTION_COMMANDS, 0.290, -0.102)
    call MUI_CreateMenuButton(11, "Cheats", MUI_ACTION_CHEATS, 0.290, -0.144)

    set MUI_OpenButton = BlzCreateFrameByType("GLUETEXTBUTTON", "MasterUIOpenButton", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "ScriptDialogButton", 0)
    call MUI_PosOpenButton(MUI_OpenButton)
    call BlzFrameSetText(MUI_OpenButton, "|cffffffffGame|r")
    call BlzTriggerRegisterFrameEvent(MUI_OpenTrigger, MUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MUI_ClearFocusTrigger, MUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)

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

    set MUI_OpenTrigger = CreateTrigger()
    call TriggerAddAction(MUI_OpenTrigger, function MUI_OpenAction)

    set MUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(MUI_CloseTrigger, function MUI_CloseAction)

    set MUI_MenuTrigger = CreateTrigger()
    call TriggerAddAction(MUI_MenuTrigger, function MUI_MenuAction)

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
        call BlzFrameSetVisible(MUI_Parent, true)
    endif
endfunction

public function Hide takes nothing returns nothing
    if MUI_Parent != null then
        call BlzFrameSetVisible(MUI_Parent, false)
    endif
endfunction

public function Toggle takes nothing returns nothing
    if not MUI_Initialized then
        call Init()
    endif
    if MUI_Parent != null then
        call BlzFrameSetVisible(MUI_Parent, not BlzFrameIsVisible(MUI_Parent))
    endif
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
