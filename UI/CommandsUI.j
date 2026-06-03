library CommandsUI initializer AutoInit requires Table, MasterUI
/**
    CommandsUI

    Author: [Valdemar]
    Version: 1.0

    Purpose:
    - Shows a predefined list of gameplay commands.
    - All commands are available in the UI at once.
    - Categories are stored per command to keep the list organized.

    Public API:
    - call CommandsUI_Show()
    - call CommandsUI_Hide()

    Credits: Tasyen (TasQuestBox as inspiration)
*/

globals
    private constant integer CUI_BUTTON_COUNT = 8
    private constant integer CUI_FRAME_CONTEXT = 4

    private boolean CUI_Initialized = false
    private boolean CUI_SyncingSlider = false
    private boolean CUI_HandlingSliderAction = false
    private integer CUI_DefinitionCount = 0
    private integer CUI_SliderMaxCache = -1
    private integer CUI_SliderValueCache = -1

    private string CUI_TocPath = "war3mapImported/TasQuestBox.toc"
    private string CUI_Title = "Commands"
    private string CUI_ReturnButtonText = "Return"

    private integer array CUI_ViewOffset
    private integer array CUI_SelectedCommandId

    private string array CUI_CommandName
    private string array CUI_CommandCategory
    private string array CUI_CommandIcon
    private string array CUI_CommandBody

    private framehandle CUI_Parent = null
    private framehandle CUI_ReturnButton = null
    private framehandle CUI_Slider = null
    private framehandle CUI_TitleFrame = null
    private framehandle CUI_TextArea = null
    private framehandle array CUI_Button
    private framehandle array CUI_ButtonIcon
    private framehandle array CUI_ButtonText

    private trigger CUI_CloseTrigger = null
    private trigger CUI_ReturnTrigger = null
    private trigger CUI_ClearFocusTrigger = null
    private trigger CUI_WheelTrigger = null
    private trigger CUI_SliderTrigger = null
    private trigger CUI_ButtonTrigger = null

    private Table CUI_ButtonRow = 0
endglobals

private function CUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function CUI_PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction

private function CUI_RegisterCommand takes string commandName, string category, string iconPath, string bodyText returns integer
    local integer commandId = CUI_DefinitionCount + 1
    set CUI_DefinitionCount = commandId
    set CUI_CommandName[commandId] = commandName
    set CUI_CommandCategory[commandId] = category
    set CUI_CommandIcon[commandId] = iconPath
    set CUI_CommandBody[commandId] = bodyText
    return commandId
endfunction

private function CUI_InitDefinitions takes nothing returns nothing
    call CUI_RegisterCommand("/help", "General", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Category: General|n|nDisplays the general help text or command overview when implemented in gameplay logic.")
    call CUI_RegisterCommand("/skills", "Professions", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Category: Professions|n|nShows the current tracked gather/profession skill values for the selected supported hero.")
    call CUI_RegisterCommand("/leave arena", "Arena", "ReplaceableTextures\\CommandButtons\\BTNBootsOfSpeed.blp", "Category: Arena|n|nLeaves the arena map section when arena gameplay is active.")
    call CUI_RegisterCommand("/gathernodes refresh", "Gather Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Category: Gather Debug|n|nRefreshes gather nodes for debugging. Intended for testing only.")
endfunction

private function CUI_GetSelectedCommandId takes player whichPlayer returns integer
    local integer pid = GetPlayerId(whichPlayer)
    if CUI_SelectedCommandId[pid] >= 1 and CUI_SelectedCommandId[pid] <= CUI_DefinitionCount then
        return CUI_SelectedCommandId[pid]
    endif
    if CUI_DefinitionCount > 0 then
        return 1
    endif
    return 0
endfunction

private function CUI_UpdateUI takes nothing returns nothing
    local integer pid = GetPlayerId(GetLocalPlayer())
    local integer rowIndex = 1
    local integer commandId
    local integer maxPage = 0
    local integer selectedCommandId
    local integer frameValue

    if CUI_Parent == null or not BlzFrameIsVisible(CUI_Parent) then
        return
    endif

    if CUI_DefinitionCount > CUI_BUTTON_COUNT then
        set maxPage = (CUI_DefinitionCount - 1) / CUI_BUTTON_COUNT
    endif
    if CUI_ViewOffset[pid] < 0 then
        set CUI_ViewOffset[pid] = 0
    elseif CUI_ViewOffset[pid] > maxPage * CUI_BUTTON_COUNT then
        set CUI_ViewOffset[pid] = maxPage * CUI_BUTTON_COUNT
    endif

    if not CUI_HandlingSliderAction then
        set frameValue = maxPage - (CUI_ViewOffset[pid] / CUI_BUTTON_COUNT)

        set CUI_SyncingSlider = true
        if CUI_SliderMaxCache != maxPage then
            set CUI_SliderMaxCache = maxPage
            call BlzFrameSetMinMaxValue(CUI_Slider, 0.0, I2R(maxPage))
        endif
        if CUI_SliderValueCache != frameValue then
            set CUI_SliderValueCache = frameValue
            call BlzFrameSetValue(CUI_Slider, I2R(frameValue))
        endif
        set CUI_SyncingSlider = false
        call BlzFrameSetVisible(CUI_Slider, maxPage > 0)
    endif

    loop
        exitwhen rowIndex > CUI_BUTTON_COUNT
        set commandId = CUI_ViewOffset[pid] + rowIndex
        if commandId <= CUI_DefinitionCount then
            if CUI_CommandIcon[commandId] != "" then
                call BlzFrameSetTexture(CUI_ButtonIcon[rowIndex], CUI_CommandIcon[commandId], 0, false)
                call BlzFrameSetVisible(CUI_ButtonIcon[rowIndex], true)
            else
                call BlzFrameSetVisible(CUI_ButtonIcon[rowIndex], false)
            endif
            call BlzFrameSetText(CUI_ButtonText[rowIndex], CUI_CommandName[commandId])
            call BlzFrameSetVisible(CUI_Button[rowIndex], true)
        else
            call BlzFrameSetVisible(CUI_Button[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    set selectedCommandId = CUI_GetSelectedCommandId(GetLocalPlayer())
    if selectedCommandId <= 0 then
        call BlzFrameSetText(CUI_TitleFrame, CUI_Title)
        call BlzFrameSetText(CUI_TextArea, "No commands configured.")
        return
    endif

    set CUI_SelectedCommandId[pid] = selectedCommandId
    call BlzFrameSetText(CUI_TitleFrame, CUI_Title + " - " + CUI_CommandName[selectedCommandId])
    call BlzFrameSetText(CUI_TextArea, CUI_CommandBody[selectedCommandId])
endfunction

public function ForceUpdate takes nothing returns nothing
    call CUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if CUI_Parent != null then
        call BlzFrameSetVisible(CUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    set CUI_SliderValueCache = -1
    call BlzFrameSetVisible(CUI_Parent, true)
    call CUI_UpdateUI()
endfunction

private function CUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(CUI_Parent, false)
    endif
endfunction

private function CUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function CUI_SliderAction takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    local integer maxPage = 0
    local integer targetPage

    if CUI_SyncingSlider then
        return
    endif
    set CUI_HandlingSliderAction = true
    if CUI_DefinitionCount > CUI_BUTTON_COUNT then
        set maxPage = (CUI_DefinitionCount - 1) / CUI_BUTTON_COUNT
    endif
    set CUI_SliderValueCache = R2I(BlzGetTriggerFrameValue() + 0.5)
    set targetPage = maxPage - CUI_SliderValueCache
    if targetPage < 0 then
        set targetPage = 0
    elseif targetPage > maxPage then
        set targetPage = maxPage
    endif
    set CUI_ViewOffset[pid] = targetPage * CUI_BUTTON_COUNT
    call CUI_UpdateUI()
    set CUI_HandlingSliderAction = false
endfunction

private function CUI_WheelAction takes nothing returns nothing
    local real nextValue
    local real maxValue

    if GetLocalPlayer() == GetTriggerPlayer() then
        if CUI_Slider == null or CUI_Parent == null or not BlzFrameIsVisible(CUI_Parent) or not BlzFrameIsVisible(CUI_Slider) then
            return
        endif

        if CUI_DefinitionCount > CUI_BUTTON_COUNT then
            set maxValue = I2R((CUI_DefinitionCount - 1) / CUI_BUTTON_COUNT)
        else
            set maxValue = 0.0
        endif
        if maxValue <= 0.0 then
            return
        endif

        set nextValue = BlzFrameGetValue(CUI_Slider)
        if BlzGetTriggerFrameValue() > 0.0 then
            set nextValue = nextValue + 1.0
        else
            set nextValue = nextValue - 1.0
        endif

        if nextValue < 0.0 then
            set nextValue = 0.0
        elseif nextValue > maxValue then
            set nextValue = maxValue
        endif

        call BlzFrameSetValue(CUI_Slider, nextValue)
    endif
endfunction

private function CUI_ButtonAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = 0
    local integer commandId = 0

    if CUI_ButtonRow.has(GetHandleId(BlzGetTriggerFrame())) then
        set rowIndex = CUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
        set commandId = CUI_ViewOffset[pid] + rowIndex
        if commandId <= CUI_DefinitionCount then
            set CUI_SelectedCommandId[pid] = commandId
            if GetLocalPlayer() == p then
                call CUI_UpdateUI()
            endif
        endif
    endif

    set p = null
endfunction

private function CUI_InitFrames takes nothing returns nothing
    local framehandle frame
    local integer rowIndex = 1

    call BlzLoadTOCFile(CUI_TocPath)

    set CUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, CUI_FRAME_CONTEXT)
    call CUI_PosBox(CUI_Parent)

    set CUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", CUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(CUI_SliderTrigger, CUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(CUI_WheelTrigger, CUI_Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(CUI_Slider, 0.0, 0.0)
    call BlzFrameSetStepSize(CUI_Slider, 1.0)

    set frame = BlzCreateFrameByType("SLIDER", "CommandsUIMoreScroll", CUI_Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(CUI_WheelTrigger, frame, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, CUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMLEFT, CUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set CUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", CUI_FRAME_CONTEXT)
    set CUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", CUI_FRAME_CONTEXT)
    call BlzFrameSetText(CUI_TitleFrame, CUI_Title)

    call BlzTriggerRegisterFrameEvent(CUI_CloseTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", CUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", CUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)

    set CUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CommandsUIReturnButton", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(CUI_ReturnButton, CUI_ReturnButtonText)
    call BlzFrameSetPoint(CUI_ReturnButton, FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("TasQuestBoxCloseButton1", CUI_FRAME_CONTEXT), FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(CUI_ReturnTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen rowIndex > CUI_BUTTON_COUNT
        set CUI_Button[rowIndex] = BlzCreateFrame("TasQuestBoxButton", CUI_Parent, 0, rowIndex + 400)
        if rowIndex > 1 then
            call BlzFrameSetPoint(CUI_Button[rowIndex], FRAMEPOINT_TOPLEFT, CUI_Button[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        set CUI_ButtonIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", rowIndex + 400)
        set CUI_ButtonText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", rowIndex + 400)
        set CUI_ButtonRow.integer[GetHandleId(CUI_Button[rowIndex])] = rowIndex
        call BlzTriggerRegisterFrameEvent(CUI_ButtonTrigger, CUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(CUI_WheelTrigger, CUI_Button[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(CUI_Button[1], FRAMEPOINT_TOPRIGHT, CUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)

    call BlzFrameSetVisible(CUI_Parent, false)
endfunction

public function Init takes nothing returns nothing
    if CUI_Initialized then
        return
    endif
    set CUI_Initialized = true

    set CUI_ButtonRow = Table.create()
    call CUI_InitDefinitions()

    set CUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(CUI_CloseTrigger, function CUI_CloseAction)

    set CUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ReturnTrigger, function CUI_ReturnAction)

    set CUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ClearFocusTrigger, function CUI_ClearFocusAction)

    set CUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ButtonTrigger, function CUI_ButtonAction)

    set CUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(CUI_SliderTrigger, function CUI_SliderAction)

    set CUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(CUI_WheelTrigger, function CUI_WheelAction)

    call CUI_InitFrames()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
