library CheatsUI initializer AutoInit requires Table, MasterUI
/**
    CheatsUI

    Author: [Valdemar]
    Version: 1.0

    Purpose:
    - Shows a predefined list of cheat/debug commands.
    - All cheat entries are visible in the UI at once.
    - Categories are stored per cheat to keep the list organized.

    Public API:
    - call CheatsUI_Show()
    - call CheatsUI_Hide()

    Credits: Tasyen (TasQuestBox as inspiration)
*/

globals
    private constant integer XUI_BUTTON_COUNT = 8
    private constant integer XUI_FRAME_CONTEXT = 5

    private boolean XUI_Initialized = false
    private integer XUI_DefinitionCount = 0

    private string XUI_TocPath = "war3mapImported/TasQuestBox.toc"
    private string XUI_Title = "Cheats"
    private string XUI_ReturnButtonText = "Return"

    private integer array XUI_ViewOffset
    private integer array XUI_SelectedCheatId

    private string array XUI_CheatName
    private string array XUI_CheatCategory
    private string array XUI_CheatIcon
    private string array XUI_CheatBody

    private framehandle XUI_Parent = null
    private framehandle XUI_ReturnButton = null
    private framehandle XUI_Slider = null
    private framehandle XUI_TitleFrame = null
    private framehandle XUI_TextArea = null
    private framehandle array XUI_Button
    private framehandle array XUI_ButtonIcon
    private framehandle array XUI_ButtonText

    private trigger XUI_CloseTrigger = null
    private trigger XUI_ReturnTrigger = null
    private trigger XUI_ClearFocusTrigger = null
    private trigger XUI_WheelTrigger = null
    private trigger XUI_SliderTrigger = null
    private trigger XUI_ButtonTrigger = null

    private Table XUI_ButtonRow = 0
endglobals

private function XUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function XUI_PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction

private function XUI_RegisterCheat takes string cheatName, string category, string iconPath, string bodyText returns integer
    local integer cheatId = XUI_DefinitionCount + 1
    set XUI_DefinitionCount = cheatId
    set XUI_CheatName[cheatId] = cheatName
    set XUI_CheatCategory[cheatId] = category
    set XUI_CheatIcon[cheatId] = iconPath
    set XUI_CheatBody[cheatId] = bodyText
    return cheatId
endfunction

private function XUI_InitDefinitions takes nothing returns nothing
    call XUI_RegisterCheat("/torch", "Utility", "ReplaceableTextures\\CommandButtons\\BTNTorch.blp", "Category: Utility|n|nExample cheat command. Intended as a quick test or debug toggle for torch-like utility behavior.")
    call XUI_RegisterCheat("/day", "Environment", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Category: Environment|n|nExample environment cheat entry. Replace or expand later with the real implemented cheat command list.")
    call XUI_RegisterCheat("/night", "Environment", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Category: Environment|n|nExample environment cheat entry for forcing night conditions.")
endfunction

private function XUI_GetSelectedCheatId takes player whichPlayer returns integer
    local integer pid = GetPlayerId(whichPlayer)
    if XUI_SelectedCheatId[pid] >= 1 and XUI_SelectedCheatId[pid] <= XUI_DefinitionCount then
        return XUI_SelectedCheatId[pid]
    endif
    if XUI_DefinitionCount > 0 then
        return 1
    endif
    return 0
endfunction

private function XUI_UpdateUI takes nothing returns nothing
    local integer pid = GetPlayerId(GetLocalPlayer())
    local integer rowIndex = 1
    local integer cheatId
    local integer maxPage = 0
    local integer selectedCheatId

    if XUI_Parent == null or not BlzFrameIsVisible(XUI_Parent) then
        return
    endif

    if XUI_DefinitionCount > XUI_BUTTON_COUNT then
        set maxPage = (XUI_DefinitionCount - 1) / XUI_BUTTON_COUNT
    endif
    if XUI_ViewOffset[pid] < 0 then
        set XUI_ViewOffset[pid] = 0
    elseif XUI_ViewOffset[pid] > maxPage * XUI_BUTTON_COUNT then
        set XUI_ViewOffset[pid] = maxPage * XUI_BUTTON_COUNT
    endif

    call BlzFrameSetMinMaxValue(XUI_Slider, 0.0, I2R(maxPage))
    call BlzFrameSetValue(XUI_Slider, I2R(XUI_ViewOffset[pid] / XUI_BUTTON_COUNT))

    loop
        exitwhen rowIndex > XUI_BUTTON_COUNT
        set cheatId = XUI_ViewOffset[pid] + rowIndex
        if cheatId <= XUI_DefinitionCount then
            if XUI_CheatIcon[cheatId] != "" then
                call BlzFrameSetTexture(XUI_ButtonIcon[rowIndex], XUI_CheatIcon[cheatId], 0, false)
                call BlzFrameSetVisible(XUI_ButtonIcon[rowIndex], true)
            else
                call BlzFrameSetVisible(XUI_ButtonIcon[rowIndex], false)
            endif
            call BlzFrameSetText(XUI_ButtonText[rowIndex], XUI_CheatName[cheatId])
            call BlzFrameSetVisible(XUI_Button[rowIndex], true)
        else
            call BlzFrameSetVisible(XUI_Button[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    set selectedCheatId = XUI_GetSelectedCheatId(GetLocalPlayer())
    if selectedCheatId <= 0 then
        call BlzFrameSetText(XUI_TitleFrame, XUI_Title)
        call BlzFrameSetText(XUI_TextArea, "No cheats configured.")
        return
    endif

    set XUI_SelectedCheatId[pid] = selectedCheatId
    call BlzFrameSetText(XUI_TitleFrame, XUI_Title + " - " + XUI_CheatName[selectedCheatId])
    call BlzFrameSetText(XUI_TextArea, XUI_CheatBody[selectedCheatId])
endfunction

public function ForceUpdate takes nothing returns nothing
    call XUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if XUI_Parent != null then
        call BlzFrameSetVisible(XUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    call BlzFrameSetVisible(XUI_Parent, true)
    call XUI_UpdateUI()
endfunction

private function XUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(XUI_Parent, false)
    endif
endfunction

private function XUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function XUI_SliderAction takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    set XUI_ViewOffset[pid] = R2I(BlzGetTriggerFrameValue()) * XUI_BUTTON_COUNT
    call XUI_UpdateUI()
endfunction

private function XUI_WheelAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        if BlzGetTriggerFrameValue() > 0.0 then
            call BlzFrameSetValue(XUI_Slider, BlzFrameGetValue(XUI_Slider) + 1.0)
        else
            call BlzFrameSetValue(XUI_Slider, BlzFrameGetValue(XUI_Slider) - 1.0)
        endif
    endif
endfunction

private function XUI_ButtonAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = 0
    local integer cheatId = 0

    if XUI_ButtonRow.has(GetHandleId(BlzGetTriggerFrame())) then
        set rowIndex = XUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
        set cheatId = XUI_ViewOffset[pid] + rowIndex
        if cheatId <= XUI_DefinitionCount then
            set XUI_SelectedCheatId[pid] = cheatId
            if GetLocalPlayer() == p then
                call XUI_UpdateUI()
            endif
        endif
    endif

    set p = null
endfunction

private function XUI_InitFrames takes nothing returns nothing
    local framehandle frame
    local integer rowIndex = 1

    call BlzLoadTOCFile(XUI_TocPath)

    set XUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, XUI_FRAME_CONTEXT)
    call XUI_PosBox(XUI_Parent)

    set XUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", XUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(XUI_SliderTrigger, XUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(XUI_WheelTrigger, XUI_Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(XUI_Slider, 0.0, 0.0)

    set frame = BlzCreateFrameByType("SLIDER", "CheatsUIMoreScroll", XUI_Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(XUI_WheelTrigger, frame, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, XUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMLEFT, XUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set XUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", XUI_FRAME_CONTEXT)
    set XUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", XUI_FRAME_CONTEXT)
    call BlzFrameSetText(XUI_TitleFrame, XUI_Title)

    call BlzTriggerRegisterFrameEvent(XUI_CloseTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", XUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(XUI_ClearFocusTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", XUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)

    set XUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CheatsUIReturnButton", XUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(XUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(XUI_ReturnButton, XUI_ReturnButtonText)
    call BlzFrameSetPoint(XUI_ReturnButton, FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("TasQuestBoxCloseButton1", XUI_FRAME_CONTEXT), FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(XUI_ReturnTrigger, XUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(XUI_ClearFocusTrigger, XUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen rowIndex > XUI_BUTTON_COUNT
        set XUI_Button[rowIndex] = BlzCreateFrame("TasQuestBoxButton", XUI_Parent, 0, rowIndex + 500)
        if rowIndex > 1 then
            call BlzFrameSetPoint(XUI_Button[rowIndex], FRAMEPOINT_TOPLEFT, XUI_Button[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        set XUI_ButtonIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", rowIndex + 500)
        set XUI_ButtonText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", rowIndex + 500)
        set XUI_ButtonRow.integer[GetHandleId(XUI_Button[rowIndex])] = rowIndex
        call BlzTriggerRegisterFrameEvent(XUI_ButtonTrigger, XUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(XUI_ClearFocusTrigger, XUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(XUI_WheelTrigger, XUI_Button[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(XUI_Button[1], FRAMEPOINT_TOPRIGHT, XUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)

    call BlzFrameSetVisible(XUI_Parent, false)
endfunction

public function Init takes nothing returns nothing
    if XUI_Initialized then
        return
    endif
    set XUI_Initialized = true

    set XUI_ButtonRow = Table.create()
    call XUI_InitDefinitions()

    set XUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(XUI_CloseTrigger, function XUI_CloseAction)

    set XUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(XUI_ReturnTrigger, function XUI_ReturnAction)

    set XUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(XUI_ClearFocusTrigger, function XUI_ClearFocusAction)

    set XUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(XUI_ButtonTrigger, function XUI_ButtonAction)

    set XUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(XUI_SliderTrigger, function XUI_SliderAction)

    set XUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(XUI_WheelTrigger, function XUI_WheelAction)

    call XUI_InitFrames()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
