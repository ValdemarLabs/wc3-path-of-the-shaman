library HintsUI initializer AutoInit requires Table, MasterUI, Interface
/**
    HintsUI

    Author: [Valdemar]
    Version: 1.0

    Purpose:
    - Stores predefined hints in one JASS library.
    - External systems publish hints with a simple API call.
    - Published hints enter a short, spaced queue before their heading is shown.
    - Published hints are also collected into this UI for later reading.
    - Unread hints mark both the Game button and the Hints menu button.

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
    public integer HINT_ABILITY_POINTS = 0
    public integer HINT_TALENT_POINTS = 0
    public integer HINT_SPECIALIZATIONS = 0
    public integer HINT_SPIRIT_SHARDS = 0
    public integer HINT_COMPANION_CONTROLS = 0
    public integer HINT_COMPANION_PARTY_SIZE = 0
    public integer HINT_FALLEN_COMPANIONS = 0
    public integer HINT_PET_FATIGUE = 0
    public integer HINT_REPUTATION = 0

    private constant integer HUI_BUTTON_COUNT = 8
    private constant integer HUI_FRAME_CONTEXT = 1
    private constant real HUI_INITIAL_DELAY = 3.00
    private constant real HUI_QUEUE_DELAY = 6.00

    private boolean HUI_Initialized = false
    private boolean HUI_SyncingSlider = false
    private boolean HUI_HandlingSliderAction = false
    private integer HUI_DefinitionCount = 0
    private integer HUI_SliderMaxCache = -1
    private integer HUI_SliderValueCache = -1
    private integer HUI_QueueHead = 0
    private integer HUI_QueueTail = 0
    private boolean HUI_QueueActive = false

    private string HUI_TocPath = "war3mapImported/TasQuestBox.toc"
    private string HUI_Title = "Hints"
    private string HUI_NoHintsText = "No hints unlocked yet."
    private string HUI_NoHintsTitle = "Hints - No entries"
    private string HUI_ReturnButtonText = "Return"
    private integer array HUI_ViewOffset
    private integer array HUI_SelectedHintId

    private boolean array HUI_Published
    private boolean array HUI_Queued
    private boolean array HUI_IsWarning
    private string array HUI_HintTitle
    private string array HUI_HintType
    private string array HUI_HintIcon
    private string array HUI_HintText
    private integer array HUI_QueuedHintId
    private unit array HUI_QueuedUnit

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
    private timer HUI_PublishTimer = null

    private Table HUI_ButtonRow = 0
endglobals

private function HUI_IsHintIdValid takes integer hintId returns boolean
    return hintId >= 1 and hintId <= HUI_DefinitionCount
endfunction

private function HUI_GetDisplayPlayer takes nothing returns player
    return Player(0)
endfunction

private function HUI_PlayHintSound takes integer hintId returns nothing
    if HUI_IsHintIdValid(hintId) and HUI_IsWarning[hintId] then
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_HARD_WARNING, HUI_GetDisplayPlayer())
    else
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_QUEST_WRITE, HUI_GetDisplayPlayer())
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
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_LOST, "If you lose your Traveler's Journal, select a nearby world Journal. Your current home can provide a replacement without changing the bound location.")

    set HINT_TRAVELERS_JOURNAL_UNIQUE = HUI_RegisterHint("Traveler's Journal: Hero Item", "Hint", "ReplaceableTextures\\CommandButtons\\BTNScrollOfTownPortal.blp", false)
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_UNIQUE, "Nazgrek and Zul'kis may each carry a Traveler's Journal, but companions cannot use one.")

    set HINT_TRAVELERS_JOURNAL_CANCEL = HUI_RegisterHint("Traveler's Journal: Cancel Return", "Hint", "ReplaceableTextures\\CommandButtons\\BTNScrollOfTownPortal.blp", false)
    call HUI_SetHintText(HINT_TRAVELERS_JOURNAL_CANCEL, "You may cancel the return-home cast by using Stop or Hold Position on the hero.")

    set HINT_CAMP_FIRE_OR_TENT = HUI_RegisterHint("Camp Fire or Tent Limitations", "Hint", "ReplaceableTextures\\CommandButtons\\BTNFarm.blp", false)
    call HUI_SetHintText(HINT_CAMP_FIRE_OR_TENT, "The unit must not be in combat when building a camp fire or tent.")

    set HINT_TENT_LIMITATION = HUI_RegisterHint("Tent Limitation", "Hint", "ReplaceableTextures\\CommandButtons\\BTNFarm.blp", false)
    call HUI_SetHintText(HINT_TENT_LIMITATION, "You may have only one tent at a time.")
    call HUI_SetHintText(HINT_TENT_LIMITATION, "Use the tent's Dismantle ability and, once finished, you can place a new tent.")

    set HINT_BARRELS_OF_EXPLOSIVES = HUI_RegisterHint("Barrels of Explosives", "Warning", "ReplaceableTextures\\CommandButtons\\BTNGoblinLandMine.blp", true)
    call HUI_SetHintText(HINT_BARRELS_OF_EXPLOSIVES, "Placed explosive barrels detonate when their countdown ends and explode immediately if destroyed. Keep the party clear.")

    set HINT_ABILITY_POINTS = HUI_RegisterHint("Ability Points", "Hint", "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp", false)
    call HUI_SetHintText(HINT_ABILITY_POINTS, "Each hero gains separate Ability Points when leveling. Visit Elemental, Enhancement, Restoration, or Totemic trainers to learn and improve abilities.")

    set HINT_TALENT_POINTS = HUI_RegisterHint("Talent Points", "Hint", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", false)
    call HUI_SetHintText(HINT_TALENT_POINTS, "From level 2 onward, each hero gains separate Talent Points. Open Game > Abilities > Talents, preview choices, then Confirm to apply them.")

    set HINT_SPECIALIZATIONS = HUI_RegisterHint("Specializations", "Hint", "ReplaceableTextures\\CommandButtons\\BTNEngineeringUpgrade.blp", false)
    call HUI_SetHintText(HINT_SPECIALIZATIONS, "Each hero may learn one free specialization from a shaman trainer. Choosing one locks the other specializations until that hero's specialization is reset.")

    set HINT_SPIRIT_SHARDS = HUI_RegisterHint("Spirit Shards", "Hint", "ReplaceableTextures\\CommandButtons\\BTNResurrection.blp", false)
    call HUI_SetHintText(HINT_SPIRIT_SHARDS, "Use a Spirit Shard near a fallen ally. Its three-second cast revives the nearest eligible unit within 250 range at half life and mana.")

    set HINT_COMPANION_CONTROLS = HUI_RegisterHint("Companion Controls", "Hint", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", false)
    call HUI_SetHintText(HINT_COMPANION_CONTROLS, "Companion commands set Passive, Normal, Aggressive, or Hold behavior and can focus companions on Nazgrek or Zul'kis.")

    set HINT_COMPANION_PARTY_SIZE = HUI_RegisterHint("Companion Party Size", "Hint", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", false)
    call HUI_SetHintText(HINT_COMPANION_PARTY_SIZE, "Companion capacity is based on the party's highest-level hero. It increases at levels 5, 10, 15, 20, and 25.")

    set HINT_FALLEN_COMPANIONS = HUI_RegisterHint("Fallen Companions", "Hint", "ReplaceableTextures\\CommandButtons\\BTNResurrection.blp", false)
    call HUI_SetHintText(HINT_FALLEN_COMPANIONS, "Spirit Shards can revive fallen companions. Hired non-hero companions remain revivable for 60 seconds before dying permanently.")

    set HINT_PET_FATIGUE = HUI_RegisterHint("Pet Fatigue", "Hint", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", false)
    call HUI_SetHintText(HINT_PET_FATIGUE, "A defeated pet becomes fatigued and recovers automatically after 20 seconds. A Spirit Shard can restore it sooner.")

    set HINT_REPUTATION = HUI_RegisterHint("Reputation", "Hint", "ReplaceableTextures\\PassiveButtons\\PASFactionHorde.blp", false)
    call HUI_SetHintText(HINT_REPUTATION, "Faction reputation affects hostility, NPC interaction, vendors, quests, and companion hiring. Review standings under Game > Reputations.")
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
    if HUI_IsWarning[hintId] then
        return "|cffff4040New Warning:|r " + HUI_HintTitle[hintId]
    endif
    return "|cffffcc00New Hint:|r " + HUI_HintTitle[hintId]
endfunction

private function HUI_DisplayMessage takes string messageText returns nothing
    if messageText == null or messageText == "" then
        return
    endif
    call DisplayTextToPlayer(HUI_GetDisplayPlayer(), 0, 0, messageText)
endfunction

private function HUI_DisplayHintMessages takes integer hintId, unit whichUnit returns nothing
    call HUI_PlayHintSound(hintId)
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
    local integer frameValue

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

    if not HUI_HandlingSliderAction then
        set frameValue = maxPage - (HUI_ViewOffset[pid] / HUI_BUTTON_COUNT)

        set HUI_SyncingSlider = true
        if HUI_SliderMaxCache != maxPage then
            set HUI_SliderMaxCache = maxPage
            call BlzFrameSetMinMaxValue(HUI_Slider, 0.0, I2R(maxPage))
        endif
        if HUI_SliderValueCache != frameValue then
            set HUI_SliderValueCache = frameValue
            call BlzFrameSetValue(HUI_Slider, I2R(frameValue))
        endif
        set HUI_SyncingSlider = false
        call BlzFrameSetVisible(HUI_Slider, maxPage > 0)
    endif

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

private function HUI_ProcessQueuedHint takes nothing returns nothing
    local integer hintId
    local integer pid
    local boolean panelVisible
    local unit whichUnit

    if HUI_QueueHead >= HUI_QueueTail then
        set HUI_QueueHead = 0
        set HUI_QueueTail = 0
        set HUI_QueueActive = false
        set whichUnit = null
        return
    endif

    set HUI_QueueHead = HUI_QueueHead + 1
    set hintId = HUI_QueuedHintId[HUI_QueueHead]
    set whichUnit = HUI_QueuedUnit[HUI_QueueHead]
    set HUI_QueuedHintId[HUI_QueueHead] = 0
    set HUI_QueuedUnit[HUI_QueueHead] = null
    set HUI_Queued[hintId] = false
    set HUI_Published[hintId] = true

    set pid = GetPlayerId(HUI_GetDisplayPlayer())
    set panelVisible = HUI_Parent != null and BlzFrameIsVisible(HUI_Parent)
    if HUI_SelectedHintId[pid] <= 0 or not panelVisible then
        set HUI_SelectedHintId[pid] = hintId
    endif

    call HUI_DisplayHintMessages(hintId, whichUnit)
    if not panelVisible then
        call MasterUI_SetHintsUnread(true)
    endif
    call HUI_UpdateUI()

    if HUI_QueueHead < HUI_QueueTail then
        call TimerStart(HUI_PublishTimer, HUI_QUEUE_DELAY, false, function HUI_ProcessQueuedHint)
    else
        set HUI_QueueHead = 0
        set HUI_QueueTail = 0
        set HUI_QueueActive = false
    endif

    set whichUnit = null
endfunction

public function ForceUpdate takes nothing returns nothing
    call HUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if HUI_Parent != null then
        if BlzFrameIsVisible(HUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
        endif
        call BlzFrameSetVisible(HUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    set HUI_SliderValueCache = -1
    call MasterUI_SetHintsUnread(false)
    if HUI_Parent != null and not BlzFrameIsVisible(HUI_Parent) then
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
    endif
    call BlzFrameSetVisible(HUI_Parent, true)
    call HUI_UpdateUI()
endfunction

private function HUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call Hide()
    endif
endfunction

private function HUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function HUI_SliderAction takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    local integer maxPage = 0
    local integer targetPage

    if HUI_SyncingSlider then
        return
    endif
    set HUI_HandlingSliderAction = true
    if HUI_GetPublishedCount() > HUI_BUTTON_COUNT then
        set maxPage = (HUI_GetPublishedCount() - 1) / HUI_BUTTON_COUNT
    endif
    set HUI_SliderValueCache = R2I(BlzGetTriggerFrameValue() + 0.5)
    set targetPage = maxPage - HUI_SliderValueCache
    if targetPage < 0 then
        set targetPage = 0
    elseif targetPage > maxPage then
        set targetPage = maxPage
    endif
    set HUI_ViewOffset[pid] = targetPage * HUI_BUTTON_COUNT
    call HUI_UpdateUI()
    set HUI_HandlingSliderAction = false
endfunction

private function HUI_WheelAction takes nothing returns nothing
    local real nextValue
    local real maxValue

    if GetLocalPlayer() == GetTriggerPlayer() then
        if HUI_Slider == null or HUI_Parent == null or not BlzFrameIsVisible(HUI_Parent) or not BlzFrameIsVisible(HUI_Slider) then
            return
        endif

        set maxValue = I2R((HUI_GetPublishedCount() - 1) / HUI_BUTTON_COUNT)
        if HUI_GetPublishedCount() <= HUI_BUTTON_COUNT then
            set maxValue = 0.0
        endif
        if maxValue <= 0.0 then
            return
        endif

        set nextValue = BlzFrameGetValue(HUI_Slider)
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

        call BlzFrameSetValue(HUI_Slider, nextValue)
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
    call BlzFrameSetStepSize(HUI_Slider, 1.0)

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

    set HUI_PublishTimer = CreateTimer()

    call HUI_InitFrames()
endfunction

public function IsPublished takes integer hintId returns boolean
    if not HUI_IsHintIdValid(hintId) then
        return false
    endif
    return HUI_Published[hintId] or HUI_Queued[hintId]
endfunction

public function PublishForUnit takes integer hintId, unit whichUnit returns nothing
    if not HUI_IsHintIdValid(hintId) or HUI_Published[hintId] or HUI_Queued[hintId] then
        return
    endif

    set HUI_QueueTail = HUI_QueueTail + 1
    set HUI_QueuedHintId[HUI_QueueTail] = hintId
    set HUI_QueuedUnit[HUI_QueueTail] = whichUnit
    set HUI_Queued[hintId] = true
    if not HUI_QueueActive then
        set HUI_QueueActive = true
        call TimerStart(HUI_PublishTimer, HUI_INITIAL_DELAY, false, function HUI_ProcessQueuedHint)
    endif
endfunction

public function Publish takes integer hintId returns nothing
    call PublishForUnit(hintId, null)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
