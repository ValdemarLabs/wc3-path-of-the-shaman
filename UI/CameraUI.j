library CameraUI initializer AutoInit requires Table, MasterUI, CameraControl
/**
    MasterUI
    
    Author: [Valdemar]
    Version: 1.0

    Description: Provides a simple panel for switching camera modes and adjusting the main camera settings.

    Credits: Tasyen (TasQuestBox as inspiration)

**/

globals
    private constant string CUI_TOC_PATH = "war3mapimported\\templates.toc"

    private constant integer CUI_SLIDER_DISTANCE = 1
    private constant integer CUI_SLIDER_FARZ = 2
    private constant integer CUI_SLIDER_ANGLE = 3
    private constant integer CUI_SLIDER_ROTATION = 4
    private constant integer CUI_SLIDER_FOV = 5

    private constant integer CUI_ACTION_NORMAL = 1
    private constant integer CUI_ACTION_ADVANCED = 2
    private constant integer CUI_ACTION_DEVELOPER = 3
    private constant integer CUI_ACTION_DEFAULTS = 4

    private boolean CUI_Initialized = false
    private boolean CUI_Syncing = false

    private framehandle CUI_Parent = null
    private framehandle CUI_Title = null
    private framehandle CUI_LeftPane = null
    private framehandle CUI_RightPane = null
    private framehandle CUI_CloseButton = null
    private framehandle CUI_ReturnButton = null
    private framehandle CUI_ResetButton = null
    private framehandle CUI_TargetTitle = null
    private framehandle CUI_TargetValue = null
    private framehandle CUI_ModeTitle = null
    private framehandle CUI_ModeValue = null
    private framehandle array CUI_ActionButton
    private framehandle array CUI_Slider
    private framehandle array CUI_SliderLabel

    private Table CUI_ButtonAction = 0
    private Table CUI_SliderKind = 0

    private trigger CUI_CloseTrigger = null
    private trigger CUI_ReturnTrigger = null
    private trigger CUI_ResetTrigger = null
    private trigger CUI_ActionTrigger = null
    private trigger CUI_SliderTrigger = null
    private trigger CUI_ClearFocusTrigger = null
    private trigger CUI_SelectTrigger = null
endglobals

private function CUI_LoadToc takes nothing returns nothing
    call BlzLoadTOCFile(CUI_TOC_PATH)
endfunction

private function CUI_GetSliderDisplay takes integer sliderKind, player whichPlayer returns string
    if sliderKind == CUI_SLIDER_DISTANCE then
        return "Distance: " + I2S(R2I(CameraControl_GetDistance(whichPlayer)))
    elseif sliderKind == CUI_SLIDER_FARZ then
        return "Far Z: " + I2S(R2I(CameraControl_GetFarZ(whichPlayer)))
    elseif sliderKind == CUI_SLIDER_ANGLE then
        return "Angle: " + I2S(R2I(CameraControl_GetAngle(whichPlayer)))
    elseif sliderKind == CUI_SLIDER_ROTATION then
        return "Rotation: " + I2S(R2I(CameraControl_GetRotation(whichPlayer)))
    endif
    return "FoV: " + I2S(R2I(CameraControl_GetFov(whichPlayer)))
endfunction

private function CUI_GetSliderValue takes integer sliderKind, player whichPlayer returns real
    if sliderKind == CUI_SLIDER_DISTANCE then
        return CameraControl_GetDistance(whichPlayer)
    elseif sliderKind == CUI_SLIDER_FARZ then
        return CameraControl_GetFarZ(whichPlayer)
    elseif sliderKind == CUI_SLIDER_ANGLE then
        return CameraControl_GetAngle(whichPlayer)
    elseif sliderKind == CUI_SLIDER_ROTATION then
        return CameraControl_GetRotation(whichPlayer)
    endif
    return CameraControl_GetFov(whichPlayer)
endfunction

private function CUI_SetSliderBounds takes framehandle slider, integer sliderKind returns nothing
    if sliderKind == CUI_SLIDER_DISTANCE then
        call BlzFrameSetMinMaxValue(slider, CameraControl_CAMERA_DISTANCE_MIN, CameraControl_CAMERA_DISTANCE_MAX)
    elseif sliderKind == CUI_SLIDER_FARZ then
        call BlzFrameSetMinMaxValue(slider, CameraControl_CAMERA_FARZ_MIN, CameraControl_CAMERA_FARZ_MAX)
    elseif sliderKind == CUI_SLIDER_ANGLE then
        call BlzFrameSetMinMaxValue(slider, CameraControl_CAMERA_ANGLE_MIN, CameraControl_CAMERA_ANGLE_MAX)
    elseif sliderKind == CUI_SLIDER_ROTATION then
        call BlzFrameSetMinMaxValue(slider, CameraControl_CAMERA_ROTATION_MIN, CameraControl_CAMERA_ROTATION_MAX)
    else
        call BlzFrameSetMinMaxValue(slider, CameraControl_CAMERA_FOV_MIN, CameraControl_CAMERA_FOV_MAX)
    endif
    call BlzFrameSetStepSize(slider, 1.0)
endfunction

private function CUI_ApplySliderChange takes integer sliderKind, player whichPlayer, real value returns nothing
    if sliderKind == CUI_SLIDER_DISTANCE then
        call CameraControl_SetDistance(whichPlayer, value)
    elseif sliderKind == CUI_SLIDER_FARZ then
        call CameraControl_SetFarZ(whichPlayer, value)
    elseif sliderKind == CUI_SLIDER_ANGLE then
        call CameraControl_SetAngle(whichPlayer, value)
    elseif sliderKind == CUI_SLIDER_ROTATION then
        call CameraControl_SetRotation(whichPlayer, value)
    else
        call CameraControl_SetFov(whichPlayer, value)
    endif
endfunction

private function CUI_RefreshFields takes player whichPlayer returns nothing
    local integer i = 1
    if CUI_Parent == null then
        return
    endif
    if GetLocalPlayer() == whichPlayer then
        call BlzFrameSetText(CUI_TargetValue, CameraControl_GetTargetName(whichPlayer))
        call BlzFrameSetText(CUI_ModeValue, CameraControl_GetModeName(whichPlayer))
        loop
            exitwhen i > 5
            call BlzFrameSetText(CUI_SliderLabel[i], CUI_GetSliderDisplay(i, whichPlayer))
            set i = i + 1
        endloop
    endif
endfunction

private function CUI_SyncSliderValues takes player whichPlayer returns nothing
    local integer i = 1

    if CUI_Parent == null then
        return
    endif

    set CUI_Syncing = true
    if GetLocalPlayer() == whichPlayer then
        loop
            exitwhen i > 5
            call BlzFrameSetValue(CUI_Slider[i], CUI_GetSliderValue(i, whichPlayer))
            set i = i + 1
        endloop
    endif
    set CUI_Syncing = false
endfunction

private function CUI_IsVisibleInternal takes nothing returns boolean
    return CUI_Parent != null and BlzFrameIsVisible(CUI_Parent)
endfunction

private function CUI_HideInternal takes nothing returns nothing
    local integer i = 1
    if CUI_Parent != null then
        call BlzFrameSetVisible(CUI_Parent, false)
    endif
    loop
        exitwhen i > 5
        if CUI_Slider[i] != null then
            call BlzFrameSetVisible(CUI_Slider[i], false)
        endif
        set i = i + 1
    endloop
    if CUI_ResetButton != null then
        call BlzFrameSetVisible(CUI_ResetButton, false)
    endif
endfunction

private function CUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function CUI_CloseAction takes nothing returns nothing
    call CUI_HideInternal()
endfunction

private function CUI_ReturnAction takes nothing returns nothing
    call CUI_HideInternal()
    call MasterUI_Show()
endfunction

private function CUI_ResetAction takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    call CameraControl_ResetDefaults(whichPlayer)
    call CUI_SyncSliderValues(whichPlayer)
    call CUI_RefreshFields(whichPlayer)
    set whichPlayer = null
endfunction

private function CUI_ActionAction takes nothing returns nothing
    local integer handleId = GetHandleId(BlzGetTriggerFrame())
    local player whichPlayer = GetTriggerPlayer()
    if CUI_ButtonAction.has(handleId) then
        if CUI_ButtonAction.integer[handleId] == CUI_ACTION_NORMAL then
            call CameraControl_SetModeNormal(whichPlayer)
        elseif CUI_ButtonAction.integer[handleId] == CUI_ACTION_ADVANCED then
            call CameraControl_SetModeAdvanced(whichPlayer)
        elseif CUI_ButtonAction.integer[handleId] == CUI_ACTION_DEVELOPER then
            call CameraControl_SetModeDeveloper(whichPlayer)
        else
            call CameraControl_ResetDefaults(whichPlayer)
        endif
        call CUI_RefreshFields(whichPlayer)
    endif
    set whichPlayer = null
endfunction

private function CUI_SliderAction takes nothing returns nothing
    local integer handleId = GetHandleId(BlzGetTriggerFrame())
    local player whichPlayer = GetTriggerPlayer()
    if CUI_Syncing then
        set whichPlayer = null
        return
    endif
    if CUI_SliderKind.has(handleId) then
        call CUI_ApplySliderChange(CUI_SliderKind.integer[handleId], whichPlayer, BlzGetTriggerFrameValue())
        call CUI_RefreshFields(whichPlayer)
    endif
    set whichPlayer = null
endfunction

private function CUI_SelectAction takes nothing returns nothing
    if CameraControl_IsTrackedCameraUnit(GetTriggerUnit()) and CUI_IsVisibleInternal() then
        call CameraControl_UpdateTargetCache(GetTriggerPlayer())
        call CUI_RefreshFields(GetTriggerPlayer())
    endif
endfunction

private function CUI_CreateActionButton takes integer index, string label, integer actionId, real y returns nothing
    set CUI_ActionButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "CameraUIActionButton" + I2S(index), CUI_LeftPane, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_ActionButton[index], 0.135, 0.030)
    call BlzFrameSetPoint(CUI_ActionButton[index], FRAMEPOINT_TOPLEFT, CUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.010, y)
    call BlzFrameSetText(CUI_ActionButton[index], label)
    call BlzTriggerRegisterFrameEvent(CUI_ActionTrigger, CUI_ActionButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_ActionButton[index], FRAMEEVENT_CONTROL_CLICK)
    set CUI_ButtonAction.integer[GetHandleId(CUI_ActionButton[index])] = actionId
endfunction

private function CUI_CreateSliderRow takes integer index, string label, integer sliderKind, real y returns nothing
    set CUI_Slider[index] = BlzCreateFrame("EscMenuSliderTemplate", CUI_Parent, 0, index)
    call BlzFrameSetPoint(CUI_Slider[index], FRAMEPOINT_TOPLEFT, CUI_RightPane, FRAMEPOINT_TOPLEFT, 0.052, y)
    call BlzFrameSetSize(CUI_Slider[index], 0.150, 0.018)
    call CUI_SetSliderBounds(CUI_Slider[index], sliderKind)

    set CUI_SliderLabel[index] = BlzCreateFrame("EscMenuLabelTextTemplate", CUI_Slider[index], 0, 0)
    call BlzFrameSetPoint(CUI_SliderLabel[index], FRAMEPOINT_RIGHT, CUI_Slider[index], FRAMEPOINT_LEFT, -0.005, 0.0)
    call BlzFrameSetSize(CUI_SliderLabel[index], 0.092, 0.016)
    call BlzFrameSetTextAlignment(CUI_SliderLabel[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
    call BlzFrameSetText(CUI_SliderLabel[index], label + ": 0")

    set CUI_Syncing = true
    call BlzFrameSetValue(CUI_Slider[index], CUI_GetSliderValue(index, Player(0)))
    set CUI_Syncing = false

    call BlzTriggerRegisterFrameEvent(CUI_SliderTrigger, CUI_Slider[index], FRAMEEVENT_SLIDER_VALUE_CHANGED)
    set CUI_SliderKind.integer[GetHandleId(CUI_Slider[index])] = sliderKind
    call BlzFrameSetVisible(CUI_Slider[index], false)
endfunction

private function CUI_CreateFrames takes nothing returns nothing
    set CUI_Parent = BlzCreateFrameByType("BACKDROP", "CameraUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(CUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
    call BlzFrameSetAbsPoint(CUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.18)

    set CUI_Title = BlzCreateFrameByType("TEXT", "CameraUITitle", CUI_Parent, "", 0)
    call BlzFrameSetPoint(CUI_Title, FRAMEPOINT_TOPLEFT, CUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(CUI_Title, 0.30, 0.018)
    call BlzFrameSetTextAlignment(CUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(CUI_Title, 1.10)
    call BlzFrameSetEnable(CUI_Title, false)
    call BlzFrameSetText(CUI_Title, "|cffffe4a3Camera|r")

    set CUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CameraUIClose", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_CloseButton, 0.03, 0.03)
    call BlzFrameSetText(CUI_CloseButton, "X")
    call BlzFrameSetPoint(CUI_CloseButton, FRAMEPOINT_TOPRIGHT, CUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
    call BlzTriggerRegisterFrameEvent(CUI_CloseTrigger, CUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

    set CUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CameraUIReturn", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(CUI_ReturnButton, "Return")
    call BlzFrameSetPoint(CUI_ReturnButton, FRAMEPOINT_TOPRIGHT, CUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(CUI_ReturnTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    set CUI_LeftPane = BlzCreateFrameByType("BACKDROP", "CameraUILeftPane", CUI_Parent, "", 0)
    call BlzFrameSetTexture(CUI_LeftPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
    call BlzFrameSetPoint(CUI_LeftPane, FRAMEPOINT_TOPLEFT, CUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.058)
    call BlzFrameSetPoint(CUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

    set CUI_RightPane = BlzCreateFrameByType("BACKDROP", "CameraUIRightPane", CUI_Parent, "", 0)
    call BlzFrameSetTexture(CUI_RightPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
    call BlzFrameSetPoint(CUI_RightPane, FRAMEPOINT_TOPLEFT, CUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
    call BlzFrameSetPoint(CUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

    set CUI_TargetTitle = BlzCreateFrameByType("TEXT", "CameraUITargetTitle", CUI_LeftPane, "", 0)
    call BlzFrameSetPoint(CUI_TargetTitle, FRAMEPOINT_TOPLEFT, CUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.010, -0.016)
    call BlzFrameSetSize(CUI_TargetTitle, 0.15, 0.014)
    call BlzFrameSetTextAlignment(CUI_TargetTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_TargetTitle, false)
    call BlzFrameSetText(CUI_TargetTitle, "|cffffcc00Target|r")

    set CUI_TargetValue = BlzCreateFrameByType("TEXT", "CameraUITargetValue", CUI_LeftPane, "", 0)
    call BlzFrameSetPoint(CUI_TargetValue, FRAMEPOINT_TOPLEFT, CUI_TargetTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.004)
    call BlzFrameSetSize(CUI_TargetValue, 0.15, 0.024)
    call BlzFrameSetTextAlignment(CUI_TargetValue, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_TargetValue, false)

    set CUI_ModeTitle = BlzCreateFrameByType("TEXT", "CameraUIModeTitle", CUI_LeftPane, "", 0)
    call BlzFrameSetPoint(CUI_ModeTitle, FRAMEPOINT_TOPLEFT, CUI_TargetValue, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.012)
    call BlzFrameSetSize(CUI_ModeTitle, 0.15, 0.014)
    call BlzFrameSetTextAlignment(CUI_ModeTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_ModeTitle, false)
    call BlzFrameSetText(CUI_ModeTitle, "|cffffcc00Mode|r")

    set CUI_ModeValue = BlzCreateFrameByType("TEXT", "CameraUIModeValue", CUI_LeftPane, "", 0)
    call BlzFrameSetPoint(CUI_ModeValue, FRAMEPOINT_TOPLEFT, CUI_ModeTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.004)
    call BlzFrameSetSize(CUI_ModeValue, 0.15, 0.018)
    call BlzFrameSetTextAlignment(CUI_ModeValue, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_ModeValue, false)

    call CUI_CreateActionButton(1, "Normal", CUI_ACTION_NORMAL, -0.128)
    call CUI_CreateActionButton(2, "Advanced", CUI_ACTION_ADVANCED, -0.168)
    call CUI_CreateActionButton(3, "Developer", CUI_ACTION_DEVELOPER, -0.208)
    call CUI_CreateActionButton(4, "Defaults", CUI_ACTION_DEFAULTS, -0.248)

    call CUI_CreateSliderRow(1, "Distance", CUI_SLIDER_DISTANCE, -0.030)
    call CUI_CreateSliderRow(2, "Far Z", CUI_SLIDER_FARZ, -0.062)
    call CUI_CreateSliderRow(3, "Angle", CUI_SLIDER_ANGLE, -0.094)
    call CUI_CreateSliderRow(4, "Rotation", CUI_SLIDER_ROTATION, -0.126)
    call CUI_CreateSliderRow(5, "FoV", CUI_SLIDER_FOV, -0.158)

    set CUI_ResetButton = BlzCreateFrame("ScriptDialogButton", CUI_Parent, 0, 0)
    call BlzFrameSetSize(CUI_ResetButton, 0.105, 0.028)
    call BlzFrameSetPoint(CUI_ResetButton, FRAMEPOINT_TOPLEFT, CUI_Slider[5], FRAMEPOINT_BOTTOMLEFT, 0.016, -0.010)
    call BlzFrameSetText(CUI_ResetButton, "Reset Sliders")
    call BlzTriggerRegisterFrameEvent(CUI_ResetTrigger, CUI_ResetButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_ResetButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzFrameSetVisible(CUI_ResetButton, false)

    call BlzFrameSetVisible(CUI_Parent, false)
endfunction

public function Hide takes nothing returns nothing
    call CUI_HideInternal()
endfunction

public function Show takes nothing returns nothing
    local integer i = 1
    if CUI_Parent != null then
        call BlzFrameSetVisible(CUI_Parent, true)
    endif
    loop
        exitwhen i > 5
        if CUI_Slider[i] != null then
            call BlzFrameSetVisible(CUI_Slider[i], true)
        endif
        set i = i + 1
    endloop
    if CUI_ResetButton != null then
        call BlzFrameSetVisible(CUI_ResetButton, true)
    endif
    call CUI_RefreshFields(GetLocalPlayer())
endfunction

public function Toggle takes nothing returns nothing
    if CUI_Parent != null and BlzFrameIsVisible(CUI_Parent) then
        call Hide()
    else
        call Show()
    endif
endfunction

public function IsVisible takes nothing returns boolean
    return CUI_IsVisibleInternal()
endfunction

public function Init takes nothing returns nothing
    local integer i = 0
    if CUI_Initialized then
        return
    endif
    set CUI_Initialized = true

    call CUI_LoadToc()

    set CUI_ButtonAction = Table.create()
    set CUI_SliderKind = Table.create()

    set CUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(CUI_CloseTrigger, function CUI_CloseAction)

    set CUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ReturnTrigger, function CUI_ReturnAction)

    set CUI_ResetTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ResetTrigger, function CUI_ResetAction)

    set CUI_ActionTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ActionTrigger, function CUI_ActionAction)

    set CUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(CUI_SliderTrigger, function CUI_SliderAction)

    set CUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ClearFocusTrigger, function CUI_ClearFocusAction)

    set CUI_SelectTrigger = CreateTrigger()
    loop
        exitwhen i >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(CUI_SelectTrigger, Player(i), EVENT_PLAYER_UNIT_SELECTED, null)
        set i = i + 1
    endloop
    call TriggerAddAction(CUI_SelectTrigger, function CUI_SelectAction)

    call CUI_CreateFrames()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
