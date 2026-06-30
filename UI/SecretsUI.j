library SecretsUI initializer AutoInit requires Table, MasterUI
/**
    SecretsUI

    Author: [Valdemar]
    Version: 1.0

    Purpose:
    - Stores predefined secrets in one JASS library.
    - All secrets are always listed in the UI.
    - Locked secrets stay greyed out as `Undiscovered` until found.
    - External systems unlock found secrets with a simple API call.

    Public API:
    - call SecretsUI_Unlock(SecretsUI_SECRET_OLD_WELL)
    - call SecretsUI_Show()
    - call SecretsUI_Hide()
    - if SecretsUI_IsUnlocked(SecretsUI_SECRET_BURIED_CACHE) then

    Credits: Tasyen (TasQuestBox as inspiration)
    
*/

globals
    public integer SECRET_OLD_WELL = 0
    public integer SECRET_BURIED_CACHE = 0
    public integer SECRET_FORGOTTEN_TRAIL = 0

    private constant integer SUI_BUTTON_COUNT = 8
    private constant integer SUI_FRAME_CONTEXT = 3

    private boolean SUI_Initialized = false
    private boolean SUI_SyncingSlider = false
    private boolean SUI_HandlingSliderAction = false
    private integer SUI_DefinitionCount = 0
    private integer SUI_SliderMaxCache = -1
    private integer SUI_SliderValueCache = -1

    private string SUI_TocPath = "war3mapImported/TasQuestBox.toc"
    private string SUI_Title = "Secrets"
    private string SUI_ReturnButtonText = "Return"
    private string SUI_UnlockSoundPath = "Sound\\Interface\\SecretFound.wav"
    private string SUI_UndiscoveredText = "|cff9f9f9fUndiscovered|r"
    private string SUI_LockedDetailText = "|cff9f9f9fThis secret has not been found yet.|r"
    private string SUI_LockedTag = "|cff9f9f9fUnknown|r"
    private string SUI_FoundTag = "|cff80ff80Found|r"

    private integer array SUI_ViewOffset
    private integer array SUI_SelectedSecretId

    private boolean array SUI_Unlocked
    private string array SUI_SecretTitle
    private string array SUI_SecretCategory
    private string array SUI_SecretIcon
    private string array SUI_SecretBody
    private string array SUI_SecretUnlockMessage

    private framehandle SUI_Parent = null
    private framehandle SUI_ReturnButton = null
    private framehandle SUI_Slider = null
    private framehandle SUI_TitleFrame = null
    private framehandle SUI_TextArea = null
    private framehandle array SUI_Button
    private framehandle array SUI_ButtonIcon
    private framehandle array SUI_ButtonText

    private trigger SUI_CloseTrigger = null
    private trigger SUI_ReturnTrigger = null
    private trigger SUI_ClearFocusTrigger = null
    private trigger SUI_WheelTrigger = null
    private trigger SUI_SliderTrigger = null
    private trigger SUI_ButtonTrigger = null

    private Table SUI_ButtonRow = 0
endglobals

private function SUI_IsSecretIdValid takes integer secretId returns boolean
    return secretId >= 1 and secretId <= SUI_DefinitionCount
endfunction

private function SUI_GetDisplayPlayer takes nothing returns player
    return Player(0)
endfunction

private function SUI_PlayUnlockSound takes nothing returns nothing
    local sound s
    if GetLocalPlayer() == SUI_GetDisplayPlayer() then
        set s = CreateSound(SUI_UnlockSoundPath, false, false, false, 10, 10, "")
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endif
endfunction

private function SUI_GetSecretIcon takes integer secretId returns string
    if not SUI_IsSecretIdValid(secretId) or SUI_SecretIcon[secretId] == null or SUI_SecretIcon[secretId] == "" then
        return ""
    endif
    return SUI_SecretIcon[secretId]
endfunction

private function SUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function SUI_PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction

private function SUI_RegisterSecret takes string title, string category, string iconPath, string bodyText, string unlockMessage returns integer
    local integer secretId = SUI_DefinitionCount + 1
    set SUI_DefinitionCount = secretId
    set SUI_SecretTitle[secretId] = title
    set SUI_SecretCategory[secretId] = category
    set SUI_SecretIcon[secretId] = iconPath
    set SUI_SecretBody[secretId] = bodyText
    set SUI_SecretUnlockMessage[secretId] = unlockMessage
    return secretId
endfunction

private function SUI_InitDefinitions takes nothing returns nothing
    set SECRET_OLD_WELL = SUI_RegisterSecret("Old Well", "Landmark", "ReplaceableTextures\\CommandButtons\\BTNHealingWard.blp", "You found an old forgotten well. Places like this often hint that the world contains more than the main route.", "|cff80ff80Secret found:|r Old Well")
    set SECRET_BURIED_CACHE = SUI_RegisterSecret("Buried Cache", "Treasure", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "A hidden cache was uncovered in an out-of-the-way corner. Secret finds can reward careful exploration.", "|cff80ff80Secret found:|r Buried Cache")
    set SECRET_FORGOTTEN_TRAIL = SUI_RegisterSecret("Forgotten Trail", "Exploration", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "You discovered a forgotten side trail that most travelers walk past without noticing.", "|cff80ff80Secret found:|r Forgotten Trail")
endfunction

private function SUI_GetSelectedSecretId takes player whichPlayer returns integer
    local integer pid = GetPlayerId(whichPlayer)
    if SUI_IsSecretIdValid(SUI_SelectedSecretId[pid]) then
        return SUI_SelectedSecretId[pid]
    endif
    if SUI_DefinitionCount > 0 then
        return 1
    endif
    return 0
endfunction

private function SUI_UpdateUI takes nothing returns nothing
    local integer pid = GetPlayerId(GetLocalPlayer())
    local integer rowIndex = 1
    local integer secretId
    local integer maxPage = 0
    local integer selectedSecretId
    local string detailText
    local integer frameValue

    if SUI_Parent == null or not BlzFrameIsVisible(SUI_Parent) then
        return
    endif

    if SUI_DefinitionCount > SUI_BUTTON_COUNT then
        set maxPage = (SUI_DefinitionCount - 1) / SUI_BUTTON_COUNT
    endif
    if SUI_ViewOffset[pid] < 0 then
        set SUI_ViewOffset[pid] = 0
    elseif SUI_ViewOffset[pid] > maxPage * SUI_BUTTON_COUNT then
        set SUI_ViewOffset[pid] = maxPage * SUI_BUTTON_COUNT
    endif

    if not SUI_HandlingSliderAction then
        set frameValue = maxPage - (SUI_ViewOffset[pid] / SUI_BUTTON_COUNT)

        set SUI_SyncingSlider = true
        if SUI_SliderMaxCache != maxPage then
            set SUI_SliderMaxCache = maxPage
            call BlzFrameSetMinMaxValue(SUI_Slider, 0.0, I2R(maxPage))
        endif
        if SUI_SliderValueCache != frameValue then
            set SUI_SliderValueCache = frameValue
            call BlzFrameSetValue(SUI_Slider, I2R(frameValue))
        endif
        set SUI_SyncingSlider = false
        call BlzFrameSetVisible(SUI_Slider, maxPage > 0)
    endif

    loop
        exitwhen rowIndex > SUI_BUTTON_COUNT
        set secretId = SUI_ViewOffset[pid] + rowIndex
        if secretId <= SUI_DefinitionCount then
            if SUI_Unlocked[secretId] then
                if SUI_GetSecretIcon(secretId) != "" then
                    call BlzFrameSetTexture(SUI_ButtonIcon[rowIndex], SUI_GetSecretIcon(secretId), 0, false)
                    call BlzFrameSetVisible(SUI_ButtonIcon[rowIndex], true)
                else
                    call BlzFrameSetVisible(SUI_ButtonIcon[rowIndex], false)
                endif
                call BlzFrameSetText(SUI_ButtonText[rowIndex], "|cffffffff" + SUI_SecretTitle[secretId] + "|r")
            else
                call BlzFrameSetVisible(SUI_ButtonIcon[rowIndex], false)
                call BlzFrameSetText(SUI_ButtonText[rowIndex], SUI_UndiscoveredText)
            endif
            call BlzFrameSetVisible(SUI_Button[rowIndex], true)
        else
            call BlzFrameSetVisible(SUI_Button[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    set selectedSecretId = SUI_GetSelectedSecretId(GetLocalPlayer())
    if selectedSecretId <= 0 then
        call BlzFrameSetText(SUI_TitleFrame, SUI_Title)
        call BlzFrameSetText(SUI_TextArea, "No secrets configured.")
        return
    endif

    set SUI_SelectedSecretId[pid] = selectedSecretId
    if SUI_Unlocked[selectedSecretId] then
        set detailText = SUI_FoundTag + " - " + SUI_SecretCategory[selectedSecretId] + "|n|n" + SUI_SecretBody[selectedSecretId]
        call BlzFrameSetText(SUI_TitleFrame, SUI_Title + " - " + SUI_SecretTitle[selectedSecretId])
    else
        set detailText = SUI_LockedTag + " - " + SUI_SecretCategory[selectedSecretId] + "|n|n" + SUI_LockedDetailText
        call BlzFrameSetText(SUI_TitleFrame, SUI_Title + " - Undiscovered")
    endif
    call BlzFrameSetText(SUI_TextArea, detailText)
endfunction

public function ForceUpdate takes nothing returns nothing
    call SUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if SUI_Parent != null then
        call BlzFrameSetVisible(SUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    set SUI_SliderValueCache = -1
    call BlzFrameSetVisible(SUI_Parent, true)
    call SUI_UpdateUI()
endfunction

private function SUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(SUI_Parent, false)
    endif
endfunction

private function SUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function SUI_SliderAction takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    local integer maxPage = 0
    local integer targetPage

    if SUI_SyncingSlider then
        return
    endif
    set SUI_HandlingSliderAction = true
    if SUI_DefinitionCount > SUI_BUTTON_COUNT then
        set maxPage = (SUI_DefinitionCount - 1) / SUI_BUTTON_COUNT
    endif
    set SUI_SliderValueCache = R2I(BlzGetTriggerFrameValue() + 0.5)
    set targetPage = maxPage - SUI_SliderValueCache
    if targetPage < 0 then
        set targetPage = 0
    elseif targetPage > maxPage then
        set targetPage = maxPage
    endif
    set SUI_ViewOffset[pid] = targetPage * SUI_BUTTON_COUNT
    call SUI_UpdateUI()
    set SUI_HandlingSliderAction = false
endfunction

private function SUI_WheelAction takes nothing returns nothing
    local real nextValue
    local real maxValue

    if GetLocalPlayer() == GetTriggerPlayer() then
        if SUI_Slider == null or SUI_Parent == null or not BlzFrameIsVisible(SUI_Parent) or not BlzFrameIsVisible(SUI_Slider) then
            return
        endif

        if SUI_DefinitionCount > SUI_BUTTON_COUNT then
            set maxValue = I2R((SUI_DefinitionCount - 1) / SUI_BUTTON_COUNT)
        else
            set maxValue = 0.0
        endif
        if maxValue <= 0.0 then
            return
        endif

        set nextValue = BlzFrameGetValue(SUI_Slider)
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

        call BlzFrameSetValue(SUI_Slider, nextValue)
    endif
endfunction

private function SUI_ButtonAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = 0
    local integer secretId = 0

    if SUI_ButtonRow.has(GetHandleId(BlzGetTriggerFrame())) then
        set rowIndex = SUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
        set secretId = SUI_ViewOffset[pid] + rowIndex
        if secretId <= SUI_DefinitionCount then
            set SUI_SelectedSecretId[pid] = secretId
            if GetLocalPlayer() == p then
                call SUI_UpdateUI()
            endif
        endif
    endif

    set p = null
endfunction

private function SUI_InitFrames takes nothing returns nothing
    local framehandle frame
    local integer rowIndex = 1

    call BlzLoadTOCFile(SUI_TocPath)

    set SUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, SUI_FRAME_CONTEXT)
    call SUI_PosBox(SUI_Parent)

    set SUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", SUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(SUI_SliderTrigger, SUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(SUI_Slider, 0.0, 0.0)
    call BlzFrameSetStepSize(SUI_Slider, 1.0)

    set frame = BlzCreateFrameByType("SLIDER", "SecretsUIMoreScroll", SUI_Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, frame, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, SUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMLEFT, SUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set SUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", SUI_FRAME_CONTEXT)
    set SUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", SUI_FRAME_CONTEXT)
    call BlzFrameSetText(SUI_TitleFrame, SUI_Title)

    call BlzTriggerRegisterFrameEvent(SUI_CloseTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", SUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", SUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)

    set SUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "SecretsUIReturnButton", SUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(SUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(SUI_ReturnButton, SUI_ReturnButtonText)
    call BlzFrameSetPoint(SUI_ReturnButton, FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("TasQuestBoxCloseButton1", SUI_FRAME_CONTEXT), FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(SUI_ReturnTrigger, SUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen rowIndex > SUI_BUTTON_COUNT
        set SUI_Button[rowIndex] = BlzCreateFrame("TasQuestBoxButton", SUI_Parent, 0, rowIndex + 300)
        if rowIndex > 1 then
            call BlzFrameSetPoint(SUI_Button[rowIndex], FRAMEPOINT_TOPLEFT, SUI_Button[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        set SUI_ButtonIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", rowIndex + 300)
        set SUI_ButtonText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", rowIndex + 300)
        set SUI_ButtonRow.integer[GetHandleId(SUI_Button[rowIndex])] = rowIndex
        call BlzTriggerRegisterFrameEvent(SUI_ButtonTrigger, SUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_Button[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(SUI_Button[1], FRAMEPOINT_TOPRIGHT, SUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)

    call BlzFrameSetVisible(SUI_Parent, false)
endfunction

public function Init takes nothing returns nothing
    if SUI_Initialized then
        return
    endif
    set SUI_Initialized = true

    set SUI_ButtonRow = Table.create()
    call SUI_InitDefinitions()

    set SUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(SUI_CloseTrigger, function SUI_CloseAction)

    set SUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ReturnTrigger, function SUI_ReturnAction)

    set SUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ClearFocusTrigger, function SUI_ClearFocusAction)

    set SUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ButtonTrigger, function SUI_ButtonAction)

    set SUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(SUI_SliderTrigger, function SUI_SliderAction)

    set SUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(SUI_WheelTrigger, function SUI_WheelAction)

    call SUI_InitFrames()
endfunction

public function IsUnlocked takes integer secretId returns boolean
    if not SUI_IsSecretIdValid(secretId) then
        return false
    endif
    return SUI_Unlocked[secretId]
endfunction

public function Unlock takes integer secretId returns nothing
    local integer pid

    if not SUI_IsSecretIdValid(secretId) or SUI_Unlocked[secretId] then
        return
    endif

    set SUI_Unlocked[secretId] = true
    set pid = GetPlayerId(SUI_GetDisplayPlayer())
    if SUI_SelectedSecretId[pid] <= 0 then
        set SUI_SelectedSecretId[pid] = secretId
    endif

    call SUI_PlayUnlockSound()
    if SUI_SecretUnlockMessage[secretId] != null and SUI_SecretUnlockMessage[secretId] != "" then
        call DisplayTextToPlayer(SUI_GetDisplayPlayer(), 0, 0, SUI_SecretUnlockMessage[secretId])
    endif
    call SUI_UpdateUI()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
