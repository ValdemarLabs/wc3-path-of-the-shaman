library HintsUI initializer AutoInit requires Table, MasterUI
/**
    HintsUI

    Author: [Valdemar]
    Version: 1.0

    Purpose:
    - Stores predefined hints in one JASS library.
    - External systems publish hints with a simple API call.
    - When published, the hint is shown as a chat-style message immediately.
    - Published hints are also collected into this UI for later reading.

    Public API:
    - call HintsUI_Publish(HintsUI_HINT_QUESTS)
    - call HintsUI_PublishForUnit(HintsUI_HINT_GRAVEYARDS, udg_Nazgrek)
    - call HintsUI_Show()
    - call HintsUI_Hide()
    - if HintsUI_IsPublished(HintsUI_HINT_TENT_LIMITATION) then

    How to add a new hint:
    1. Add one new public integer name below, for example:
       public integer HINT_EXAMPLE = 0
    2. Add one registration block inside HUI_InitDefinitions():
       set HINT_EXAMPLE = HUI_RegisterHint("Example", "Hint", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", false)
       call HUI_SetHintText(HINT_EXAMPLE, "First paragraph.")
       call HUI_SetHintText(HINT_EXAMPLE, "Second paragraph.")
    3. If the hint has special runtime text formatting, extend
       HUI_GetFormattedMessage(...).
    4. Publish it from gameplay code with:
       call HintsUI_Publish(HintsUI_HINT_EXAMPLE)
       or
       call HintsUI_PublishForUnit(HintsUI_HINT_EXAMPLE, someUnit)

    Credits: Tasyen (TasQuestBox as inspiration)
    
*/

globals
    public integer HINT_GRAVEYARDS = 0
    public integer HINT_GRAVEYARDS_CHANGE = 0
    public integer HINT_TRAVELERS_JOURNAL_RETURN = 0
    public integer HINT_FREE_FLY_BACK = 0
    public integer HINT_QUESTS = 0
    public integer HINT_TRAVELERS_JOURNAL_LOST = 0
    public integer HINT_TRAVELERS_JOURNAL_UNIQUE = 0
    public integer HINT_TRAVELERS_JOURNAL_CANCEL = 0
    public integer HINT_CAMP_FIRE_OR_TENT = 0
    public integer HINT_TENT_LIMITATION = 0
    public integer HINT_BARRELS_OF_EXPLOSIVES = 0

    private constant integer HUI_BUTTON_COUNT = 8
    private constant integer HUI_FRAME_CONTEXT = 1

    private boolean HUI_Initialized = false
    private integer HUI_DefinitionCount = 0

    private string HUI_TocPath = "war3mapImported/TasQuestBox.toc"
    private string HUI_Title = "Hints"
    private string HUI_NoHintsText = "No hints unlocked yet."
    private string HUI_NoHintsTitle = "Hints - No entries"
    private string HUI_ReturnButtonText = "Return"
    private string HUI_PopupSoundPath = "Sound\\Interface\\Hint.wav"

    private integer array HUI_ViewOffset
    private integer array HUI_SelectedHintId

    private boolean array HUI_Published
    private boolean array HUI_IsWarning
    private string array HUI_HintTitle
    private string array HUI_HintType
    private string array HUI_HintIcon
    private string array HUI_HintText

    private framehandle HUI_Parent = null
    private framehandle HUI_ReturnButton = null
    private framehandle HUI_Slider = null
    private framehandle HUI_TitleFrame = null
    private framehandle HUI_TextArea = null
    private framehandle array HUI_Button
    private framehandle array HUI_ButtonIcon
    private framehandle array HUI_ButtonText

    private trigger HUI_CloseTrigger = null
    private trigger HUI_ReturnTrigger = null
    private trigger HUI_ClearFocusTrigger = null
    private trigger HUI_WheelTrigger = null
    private trigger HUI_SliderTrigger = null
    private trigger HUI_ButtonTrigger = null

    private Table HUI_ButtonRow = 0
endglobals

private function HUI_IsHintIdValid takes integer hintId returns boolean
    return hintId >= 1 and hintId <= HUI_DefinitionCount
endfunction

private function HUI_GetDisplayPlayer takes nothing returns player
    return Player(0)
endfunction

private function HUI_PlayHintSound takes nothing returns nothing
    local sound s
    if GetLocalPlayer() == HUI_GetDisplayPlayer() then
        set s = CreateSound(HUI_PopupSoundPath, false, false, false, 10, 10, "")
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endif
endfunction

private function HUI_GetHintIcon takes integer hintId returns string
    if not HUI_IsHintIdValid(hintId) or HUI_HintIcon[hintId] == null or HUI_HintIcon[hintId] == "" then
        return ""
    endif
    return HUI_HintIcon[hintId]
endfunction

private function HUI_GetHintHeader takes integer hintId returns string
    if HUI_IsWarning[hintId] then
        return "|cffff4040Warning|r"
    endif
    return "|cff32CD32Hint|r"
endfunction

private function HUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function HUI_PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction

private function HUI_RegisterHint takes string title, string hintType, string iconPath, boolean isWarning returns integer
    local integer hintId = HUI_DefinitionCount + 1
    set HUI_DefinitionCount = hintId
    set HUI_HintTitle[hintId] = title
    set HUI_HintType[hintId] = hintType
    set HUI_HintIcon[hintId] = iconPath
    set HUI_IsWarning[hintId] = isWarning
    return hintId
endfunction

private function HUI_SetHintText takes integer hintId, string text returns nothing
    if HUI_HintText[hintId] == null or HUI_HintText[hintId] == "" then
        set HUI_HintText[hintId] = text
    else
        set HUI_HintText[hintId] = HUI_HintText[hintId] + "|n|n" + text
    endif
endfunction

private function HUI_FrameTextToChatText takes string text returns string
    local integer i = 0
    local integer length = StringLength(text)
    local string result = ""

    loop
        exitwhen i >= length
        if i + 1 < length and SubString(text, i, i + 2) == "|n" then
            set result = result + "\n"
            set i = i + 2
        else
            set result = result + SubString(text, i, i + 1)
            set i = i + 1
        endif
    endloop

    return result
endfunction

private function HUI_InitDefinitions takes nothing returns nothing
    set HINT_GRAVEYARDS = HUI_RegisterHint("Graveyards", "Hint", "ReplaceableTextures\\CommandButtons\\BTNResurrection.blp", false)
    call HUI_SetHintText(HINT_GRAVEYARDS, "Fallen heroes will be revived at the active graveyard.")
    call HUI_SetHintText(HINT_GRAVEYARDS, "Graveyards can be found in multiple locations. Walk over a graveyard to set it as your current revival point.")

    set HINT_GRAVEYARDS_CHANGE = HUI_RegisterHint("Changing Graveyard", "Hint", "ReplaceableTextures\\CommandButtons\\BTNResurrection.blp", false)
    call HUI_SetHintText(HINT_GRAVEYARDS_CHANGE, "You can change your current graveyard simply by walking next to a different graveyard.")

    set HINT_TRAVELERS_JOURNAL_RETURN = HUI_RegisterHint("Traveler's Journal: Return Home", "Hint", "ReplaceableTextures\\CommandButtons\\BTNScrollOfTownPortal.blp", false)
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_RETURN, "You may return to your home location by using the Traveler's Journal in your hero's inventory.")
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_RETURN, "The hero must not perform other actions during the cast, and incoming attacks will cancel the return.")

    set HINT_FREE_FLY_BACK = HUI_RegisterHint("Free Fly Back", "Hint", "ReplaceableTextures\\CommandButtons\\BTNScrollOfTownPortal.blp", false)
    call HUI_SetHintText(HINT_FREE_FLY_BACK, "You can fly back to the Horde Scout Base for free.")

    set HINT_QUESTS = HUI_RegisterHint("Quests", "Hint", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", false)
    call HUI_SetHintText(HINT_QUESTS, "Look for NPCs with a question mark above them to discover available quests.")

    set HINT_TRAVELERS_JOURNAL_LOST = HUI_RegisterHint("Traveler's Journal: Lost Journal", "Hint", "ReplaceableTextures\\CommandButtons\\BTNScrollOfTownPortal.blp", false)
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_LOST, "If you lose your Traveler's Journal, you must select a different journal than the one where your home was previously set.")

    set HINT_TRAVELERS_JOURNAL_UNIQUE = HUI_RegisterHint("Traveler's Journal: Unique Item", "Hint", "ReplaceableTextures\\CommandButtons\\BTNScrollOfTownPortal.blp", false)
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_UNIQUE, "Traveler's Journal is a unique item that can be carried and used only by Nazgrek or Zul'kis, but not by both at the same time.")

    set HINT_TRAVELERS_JOURNAL_CANCEL = HUI_RegisterHint("Traveler's Journal: Cancel Return", "Hint", "ReplaceableTextures\\CommandButtons\\BTNScrollOfTownPortal.blp", false)
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_CANCEL, "You may cancel the return-home cast by using Stop or Hold Position on the hero.")

    set HINT_CAMP_FIRE_OR_TENT = HUI_RegisterHint("Camp Fire or Tent Limitations", "Hint", "ReplaceableTextures\\CommandButtons\\BTNFarm.blp", false)
    call HUI_SetHintText(HINT_CAMP_FIRE_OR_TENT, "The unit must not be in combat when building a camp fire or tent.")

    set HINT_TENT_LIMITATION = HUI_RegisterHint("Tent Limitation", "Hint", "ReplaceableTextures\\CommandButtons\\BTNFarm.blp", false)
    call HUI_SetHintText(HINT_TENT_LIMITATION, "You may have only one tent at a time.")
    call HUI_SetHintText(HINT_TENT_LIMITATION, "Use the tent's Dismantle ability and, once finished, you can place a new tent.")

    set HINT_BARRELS_OF_EXPLOSIVES = HUI_RegisterHint("Barrels of Explosives", "Warning", "ReplaceableTextures\\CommandButtons\\BTNGoblinLandMine.blp", true)
    call HUI_SetHintText(HINT_BARRELS_OF_EXPLOSIVES, "Take care. The explosives are highly unstable and might explode immediately if attacked while carrying one or more in inventory.")
endfunction

private function HUI_GetPublishedCount takes nothing returns integer
    local integer hintId = 1
    local integer count = 0

    loop
        exitwhen hintId > HUI_DefinitionCount
        if HUI_Published[hintId] then
            set count = count + 1
        endif
        set hintId = hintId + 1
    endloop

    return count
endfunction

private function HUI_GetPublishedHintIdAt takes integer index returns integer
    local integer hintId = 1
    local integer count = 0

    loop
        exitwhen hintId > HUI_DefinitionCount
        if HUI_Published[hintId] then
            if count == index then
                return hintId
            endif
            set count = count + 1
        endif
        set hintId = hintId + 1
    endloop

    return 0
endfunction

private function HUI_GetSelectedHintId takes player whichPlayer returns integer
    local integer pid = GetPlayerId(whichPlayer)

    if HUI_IsHintIdValid(HUI_SelectedHintId[pid]) and HUI_Published[HUI_SelectedHintId[pid]] then
        return HUI_SelectedHintId[pid]
    endif
    return HUI_GetPublishedHintIdAt(0)
endfunction

private function HUI_GetFormattedMessage takes integer hintId, unit whichUnit returns string
    if HUI_HintText[hintId] == null or HUI_HintText[hintId] == "" then
        return ""
    endif
    return HUI_GetHintHeader(hintId) + " - " + HUI_HintTitle[hintId] + "\n" + HUI_FrameTextToChatText(HUI_HintText[hintId])
endfunction

private function HUI_DisplayMessage takes string messageText returns nothing
    if messageText == null or messageText == "" then
        return
    endif
    call DisplayTextToPlayer(HUI_GetDisplayPlayer(), 0, 0, messageText)
endfunction

private function HUI_DisplayHintMessages takes integer hintId, unit whichUnit returns nothing
    call HUI_PlayHintSound()
    call HUI_DisplayMessage(HUI_GetFormattedMessage(hintId, whichUnit))
endfunction

private function HUI_UpdateUI takes nothing returns nothing
    local integer pid = GetPlayerId(GetLocalPlayer())
    local integer rowIndex = 1
    local integer hintId
    local integer publishedCount = HUI_GetPublishedCount()
    local integer maxPage = 0
    local integer selectedHintId
    local string detailText

    if HUI_Parent == null or not BlzFrameIsVisible(HUI_Parent) then
        return
    endif

    if publishedCount > HUI_BUTTON_COUNT then
        set maxPage = (publishedCount - 1) / HUI_BUTTON_COUNT
    endif
    if HUI_ViewOffset[pid] < 0 then
        set HUI_ViewOffset[pid] = 0
    elseif HUI_ViewOffset[pid] > maxPage * HUI_BUTTON_COUNT then
        set HUI_ViewOffset[pid] = maxPage * HUI_BUTTON_COUNT
    endif

    call BlzFrameSetMinMaxValue(HUI_Slider, 0.0, I2R(maxPage))
    call BlzFrameSetValue(HUI_Slider, I2R(HUI_ViewOffset[pid] / HUI_BUTTON_COUNT))

    loop
        exitwhen rowIndex > HUI_BUTTON_COUNT
        set hintId = HUI_GetPublishedHintIdAt(HUI_ViewOffset[pid] + rowIndex - 1)
        if hintId > 0 then
            if HUI_GetHintIcon(hintId) != "" then
                call BlzFrameSetTexture(HUI_ButtonIcon[rowIndex], HUI_GetHintIcon(hintId), 0, false)
                call BlzFrameSetVisible(HUI_ButtonIcon[rowIndex], true)
            else
                call BlzFrameSetVisible(HUI_ButtonIcon[rowIndex], false)
            endif
            call BlzFrameSetText(HUI_ButtonText[rowIndex], HUI_HintTitle[hintId])
            call BlzFrameSetVisible(HUI_Button[rowIndex], true)
        else
            call BlzFrameSetVisible(HUI_Button[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    set selectedHintId = HUI_GetSelectedHintId(GetLocalPlayer())
    if selectedHintId <= 0 then
        call BlzFrameSetText(HUI_TitleFrame, HUI_NoHintsTitle)
        call BlzFrameSetText(HUI_TextArea, HUI_NoHintsText)
        return
    endif

    set HUI_SelectedHintId[pid] = selectedHintId
    set detailText = HUI_GetHintHeader(selectedHintId) + " - " + HUI_HintTitle[selectedHintId] + "|n" + HUI_HintText[selectedHintId]
    call BlzFrameSetText(HUI_TitleFrame, HUI_Title + " - " + HUI_HintTitle[selectedHintId])
    call BlzFrameSetText(HUI_TextArea, detailText)
endfunction

public function ForceUpdate takes nothing returns nothing
    call HUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if HUI_Parent != null then
        call BlzFrameSetVisible(HUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    call BlzFrameSetVisible(HUI_Parent, true)
    call HUI_UpdateUI()
endfunction

private function HUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(HUI_Parent, false)
    endif
endfunction

private function HUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function HUI_SliderAction takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    set HUI_ViewOffset[pid] = R2I(BlzGetTriggerFrameValue()) * HUI_BUTTON_COUNT
    call HUI_UpdateUI()
endfunction

private function HUI_WheelAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        if BlzGetTriggerFrameValue() > 0.0 then
            call BlzFrameSetValue(HUI_Slider, BlzFrameGetValue(HUI_Slider) + 1.0)
        else
            call BlzFrameSetValue(HUI_Slider, BlzFrameGetValue(HUI_Slider) - 1.0)
        endif
    endif
endfunction

private function HUI_ButtonAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = 0
    local integer hintId = 0

    if HUI_ButtonRow.has(GetHandleId(BlzGetTriggerFrame())) then
        set rowIndex = HUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
        set hintId = HUI_GetPublishedHintIdAt(HUI_ViewOffset[pid] + rowIndex - 1)
        if hintId > 0 then
            set HUI_SelectedHintId[pid] = hintId
            if GetLocalPlayer() == p then
                call HUI_UpdateUI()
            endif
        endif
    endif

    set p = null
endfunction

private function HUI_InitFrames takes nothing returns nothing
    local framehandle frame
    local integer rowIndex = 1

    call BlzLoadTOCFile(HUI_TocPath)

    set HUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, HUI_FRAME_CONTEXT)
    call HUI_PosBox(HUI_Parent)

    set HUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", HUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(HUI_SliderTrigger, HUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(HUI_WheelTrigger, HUI_Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(HUI_Slider, 0.0, 0.0)

    set frame = BlzCreateFrameByType("SLIDER", "HintsUIMoreScroll", HUI_Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(HUI_WheelTrigger, frame, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, HUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMLEFT, HUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set HUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", HUI_FRAME_CONTEXT)
    set HUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", HUI_FRAME_CONTEXT)
    call BlzFrameSetText(HUI_TitleFrame, HUI_Title)

    call BlzTriggerRegisterFrameEvent(HUI_CloseTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", HUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(HUI_ClearFocusTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", HUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)

    set HUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "HintsUIReturnButton", HUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(HUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(HUI_ReturnButton, HUI_ReturnButtonText)
    call BlzFrameSetPoint(HUI_ReturnButton, FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("TasQuestBoxCloseButton1", HUI_FRAME_CONTEXT), FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(HUI_ReturnTrigger, HUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(HUI_ClearFocusTrigger, HUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen rowIndex > HUI_BUTTON_COUNT
        set HUI_Button[rowIndex] = BlzCreateFrame("TasQuestBoxButton", HUI_Parent, 0, rowIndex + 100)
        if rowIndex > 1 then
            call BlzFrameSetPoint(HUI_Button[rowIndex], FRAMEPOINT_TOPLEFT, HUI_Button[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        set HUI_ButtonIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", rowIndex + 100)
        set HUI_ButtonText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", rowIndex + 100)
        set HUI_ButtonRow.integer[GetHandleId(HUI_Button[rowIndex])] = rowIndex
        call BlzTriggerRegisterFrameEvent(HUI_ButtonTrigger, HUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(HUI_ClearFocusTrigger, HUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(HUI_WheelTrigger, HUI_Button[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(HUI_Button[1], FRAMEPOINT_TOPRIGHT, HUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)

    call BlzFrameSetVisible(HUI_Parent, false)
endfunction

public function Init takes nothing returns nothing
    if HUI_Initialized then
        return
    endif
    set HUI_Initialized = true

    set HUI_ButtonRow = Table.create()
    call HUI_InitDefinitions()

    set HUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(HUI_CloseTrigger, function HUI_CloseAction)

    set HUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(HUI_ReturnTrigger, function HUI_ReturnAction)

    set HUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(HUI_ClearFocusTrigger, function HUI_ClearFocusAction)

    set HUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(HUI_ButtonTrigger, function HUI_ButtonAction)

    set HUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(HUI_SliderTrigger, function HUI_SliderAction)

    set HUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(HUI_WheelTrigger, function HUI_WheelAction)

    call HUI_InitFrames()
endfunction

public function IsPublished takes integer hintId returns boolean
    if not HUI_IsHintIdValid(hintId) then
        return false
    endif
    return HUI_Published[hintId]
endfunction

public function PublishForUnit takes integer hintId, unit whichUnit returns nothing
    local integer pid
    if not HUI_IsHintIdValid(hintId) or HUI_Published[hintId] then
        return
    endif

    set HUI_Published[hintId] = true
    set pid = GetPlayerId(HUI_GetDisplayPlayer())
    if HUI_SelectedHintId[pid] <= 0 then
        set HUI_SelectedHintId[pid] = hintId
    endif

    call HUI_DisplayHintMessages(hintId, whichUnit)
    call HUI_UpdateUI()
endfunction

public function Publish takes integer hintId returns nothing
    call PublishForUnit(hintId, null)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
