/**
    AbilitiesUI

    Author: Valdemar
    Version:

    Description:
    Trainer-only custom frame UI for learning player shaman abilities and
    specializations from the Elemental, Enhancement, Restoration, and Totemic
    masters. Uses Abilities.j for all learn and reset actions.

    Credits:
    Tasyen (TasQuestBox as inspiration)

    How to install:
    Import after Abilities, AbilitiesPlayer, MasterUI, Table, and Interface.
    AbilityTrainerDialogs opens this UI from the trainer dialog Learn button.

    API:
    - call AbilitiesUI_ShowForTrainer(trainer, hero)
    - call AbilitiesUI_Hide()
    - call AbilitiesUI_Refresh()

**/
library AbilitiesUI initializer AutoInit requires Table, MasterUI, Abilities, AbilitiesPlayer, AbilityPoints, Interface
    globals
        private constant integer ABUI_VISIBLE_ROWS = 8
        private constant real ABUI_ROW_HEIGHT = 0.030
        private constant real ABUI_ROW_GAP = 0.004
        private constant real ABUI_TRAINER_RANGE = 900.00
        private constant real ABUI_TRAINER_RANGE_SQ = 810000.00

        private boolean ABUI_Initialized = false
        private boolean ABUI_SyncingListScroll = false

        private framehandle ABUI_Parent = null
        private framehandle ABUI_Title = null
        private framehandle ABUI_ViewingText = null
        private framehandle ABUI_TrainerText = null
        private framehandle ABUI_CloseButton = null
        private framehandle ABUI_ReturnButton = null
        private framehandle ABUI_LeftPane = null
        private framehandle ABUI_RightPane = null
        private framehandle ABUI_ListScroll = null
        private framehandle ABUI_DetailIcon = null
        private framehandle ABUI_DetailTitle = null
        private framehandle ABUI_DetailInfo = null
        private framehandle ABUI_DetailBody = null
        private framehandle ABUI_DetailFooter = null
        private framehandle ABUI_LearnButton = null
        private framehandle ABUI_ResetAbilitiesButton = null
        private framehandle ABUI_ResetSpecializationButton = null
        private framehandle ABUI_ResetTalentsButton = null

        private framehandle array ABUI_RowButton
        private framehandle array ABUI_RowIcon
        private framehandle array ABUI_RowText
        private framehandle array ABUI_RowState
        private framehandle array ABUI_RowHighlight

        private unit ABUI_SelectedHero = null
        private unit ABUI_SelectedTrainer = null
        private integer ABUI_SelectedTree = AbilitiesPlayer_TREE_NONE
        private integer ABUI_SelectedEntry = 0
        private integer ABUI_ListScrollValue = 0
        private integer ABUI_ListScrollMaxCache = -1
        private integer ABUI_ListScrollFrameValueCache = -1
        private integer array ABUI_RowEntry
        private integer array ABUI_RowHighlightVisible

        private Table ABUI_ButtonRow = 0

        private trigger ABUI_CloseTrigger = null
        private trigger ABUI_ReturnTrigger = null
        private trigger ABUI_RowTrigger = null
        private trigger ABUI_LearnTrigger = null
        private trigger ABUI_ResetAbilitiesTrigger = null
        private trigger ABUI_ResetSpecializationTrigger = null
        private trigger ABUI_ResetTalentsTrigger = null
        private trigger ABUI_ListScrollTrigger = null
        private trigger ABUI_WheelTrigger = null
        private trigger ABUI_ClearFocusTrigger = null

        private string ABUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
        private string ABUI_DefaultIcon = "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"
        private string ABUI_RowHighlightModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
    endglobals

    private function ABUI_GetUnitName takes unit whichUnit returns string
        if whichUnit == null or GetHandleId(whichUnit) == 0 then
            return "No unit"
        endif
        if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
            return GetHeroProperName(whichUnit)
        endif
        return GetUnitName(whichUnit)
    endfunction

    private function ABUI_IsPlayerShamanHero takes unit whichUnit returns boolean
        if whichUnit == null or GetHandleId(whichUnit) == 0 then
            return false
        endif
        if whichUnit != udg_Nazgrek and whichUnit != udg_Zulkis then
            return false
        endif
        return GetOwningPlayer(whichUnit) == Player(0)
    endfunction

    private function ABUI_GetDistanceSq takes unit a, unit b returns real
        local real dx
        local real dy

        if a == null or b == null then
            return 999999999.00
        endif

        set dx = GetUnitX(a) - GetUnitX(b)
        set dy = GetUnitY(a) - GetUnitY(b)
        return dx * dx + dy * dy
    endfunction

    private function ABUI_GetCloserHero takes unit trainer, unit current, unit candidate returns unit
        if not ABUI_IsPlayerShamanHero(candidate) then
            return current
        endif
        if current == null or ABUI_GetDistanceSq(candidate, trainer) < ABUI_GetDistanceSq(current, trainer) then
            return candidate
        endif
        return current
    endfunction

    private function ABUI_GetNearestHero takes unit trainer returns unit
        local unit best = null

        set best = ABUI_GetCloserHero(trainer, best, udg_Nazgrek)
        set best = ABUI_GetCloserHero(trainer, best, udg_Zulkis)

        return best
    endfunction

    private function ABUI_IsHeroNearTrainer takes unit hero, unit trainer returns boolean
        return ABUI_GetDistanceSq(hero, trainer) <= ABUI_TRAINER_RANGE_SQ
    endfunction

    private function ABUI_GetEntryCount takes nothing returns integer
        return AbilitiesPlayer_GetEntryCountForTreePage(ABUI_SelectedTree, AbilitiesPlayer_PAGE_ALL)
    endfunction

    private function ABUI_GetEntryByFilteredIndex takes integer filteredIndex returns integer
        return AbilitiesPlayer_GetEntryByTreePageIndex(ABUI_SelectedTree, AbilitiesPlayer_PAGE_ALL, filteredIndex)
    endfunction

    private function ABUI_GetFilteredIndexForEntry takes integer entryIndex returns integer
        local integer filteredIndex = 1
        local integer currentEntry
        local integer total = ABUI_GetEntryCount()

        loop
            exitwhen filteredIndex > total
            set currentEntry = ABUI_GetEntryByFilteredIndex(filteredIndex)
            if currentEntry == entryIndex then
                return filteredIndex
            endif
            set filteredIndex = filteredIndex + 1
        endloop

        return 0
    endfunction

    private function ABUI_ResetViewState takes nothing returns nothing
        set ABUI_SelectedEntry = 0
        set ABUI_ListScrollValue = 0
        set ABUI_ListScrollFrameValueCache = -1
    endfunction

    private function ABUI_ClampSelection takes nothing returns nothing
        local integer total = ABUI_GetEntryCount()
        local integer maxStart = total - ABUI_VISIBLE_ROWS
        local integer filteredIndex

        if maxStart < 0 then
            set maxStart = 0
        endif
        if ABUI_ListScrollValue < 0 then
            set ABUI_ListScrollValue = 0
        elseif ABUI_ListScrollValue > maxStart then
            set ABUI_ListScrollValue = maxStart
        endif

        if total <= 0 then
            set ABUI_SelectedEntry = 0
            return
        endif

        if ABUI_SelectedEntry == 0 or AbilitiesPlayer_GetEntryTree(ABUI_SelectedEntry) != ABUI_SelectedTree then
            set ABUI_SelectedEntry = ABUI_GetEntryByFilteredIndex(1)
        endif

        set filteredIndex = ABUI_GetFilteredIndexForEntry(ABUI_SelectedEntry)
        if filteredIndex <= 0 then
            set ABUI_SelectedEntry = ABUI_GetEntryByFilteredIndex(1)
        endif
    endfunction

    private function ABUI_SyncListScrollFrame takes integer maxStart returns nothing
        local integer frameValue

        if ABUI_ListScroll == null then
            return
        endif
        if maxStart < 0 then
            set maxStart = 0
        endif
        if ABUI_ListScrollValue < 0 then
            set ABUI_ListScrollValue = 0
        elseif ABUI_ListScrollValue > maxStart then
            set ABUI_ListScrollValue = maxStart
        endif

        set frameValue = maxStart - ABUI_ListScrollValue
        set ABUI_SyncingListScroll = true
        if ABUI_ListScrollMaxCache != maxStart then
            set ABUI_ListScrollMaxCache = maxStart
            call BlzFrameSetMinMaxValue(ABUI_ListScroll, 0.00, I2R(maxStart))
        endif
        if ABUI_ListScrollFrameValueCache != frameValue then
            set ABUI_ListScrollFrameValueCache = frameValue
            call BlzFrameSetValue(ABUI_ListScroll, I2R(frameValue))
        endif
        set ABUI_SyncingListScroll = false
        call BlzFrameSetVisible(ABUI_ListScroll, maxStart > 0)
    endfunction

    private function ABUI_FormatRowTitle takes integer entryIndex returns string
        local string titleText = AbilitiesPlayer_GetEntryTitle(entryIndex)
        local integer kind = AbilitiesPlayer_GetEntryKind(entryIndex)

        if kind == AbilitiesPlayer_ENTRY_SPECIALIZATION then
            set titleText = "[Spec] " + titleText
        elseif kind == AbilitiesPlayer_ENTRY_TALENT then
            set titleText = "[Talent] " + titleText
        endif

        if Abilities_IsEntryMaxed(ABUI_SelectedHero, entryIndex) then
            return "|cffffe4a3" + titleText + "|r"
        elseif Abilities_IsEntryLearned(ABUI_SelectedHero, entryIndex) then
            return "|cffffffff" + titleText + "|r"
        elseif Abilities_CanLearn(ABUI_SelectedHero, entryIndex) then
            return AbilitiesPlayer_GetTreeColor(AbilitiesPlayer_GetEntryTree(entryIndex)) + titleText + "|r"
        endif

        return "|cff808080" + titleText + "|r"
    endfunction

    private function ABUI_UpdateRows takes nothing returns nothing
        local integer rowIndex = 1
        local integer total = ABUI_GetEntryCount()
        local integer maxStart = total - ABUI_VISIBLE_ROWS
        local integer filteredIndex
        local integer entryIndex
        local integer selected

        if maxStart < 0 then
            set maxStart = 0
        endif

        loop
            exitwhen rowIndex > ABUI_VISIBLE_ROWS
            set filteredIndex = ABUI_ListScrollValue + rowIndex
            set entryIndex = ABUI_GetEntryByFilteredIndex(filteredIndex)
            set ABUI_RowEntry[rowIndex] = entryIndex
            if entryIndex != 0 then
                call BlzFrameSetTexture(ABUI_RowIcon[rowIndex], AbilitiesPlayer_GetEntryIcon(entryIndex), 0, true)
                call BlzFrameSetText(ABUI_RowText[rowIndex], ABUI_FormatRowTitle(entryIndex))
                call BlzFrameSetText(ABUI_RowState[rowIndex], Abilities_GetEntryStateText(ABUI_SelectedHero, entryIndex))
                call BlzFrameSetVisible(ABUI_RowButton[rowIndex], true)

                if entryIndex == ABUI_SelectedEntry then
                    set selected = 1
                else
                    set selected = 0
                endif
                if ABUI_RowHighlightVisible[rowIndex] != selected then
                    set ABUI_RowHighlightVisible[rowIndex] = selected
                    call BlzFrameSetVisible(ABUI_RowHighlight[rowIndex], selected == 1)
                endif
            else
                set ABUI_RowHighlightVisible[rowIndex] = 0
                call BlzFrameSetVisible(ABUI_RowButton[rowIndex], false)
                call BlzFrameSetVisible(ABUI_RowHighlight[rowIndex], false)
            endif
            set rowIndex = rowIndex + 1
        endloop

        call ABUI_SyncListScrollFrame(maxStart)
    endfunction

    private function ABUI_UpdateHeader takes nothing returns nothing
        local string treeName = AbilitiesPlayer_GetTreeName(ABUI_SelectedTree)

        call BlzFrameSetText(ABUI_Title, AbilitiesPlayer_GetTreeColor(ABUI_SelectedTree) + treeName + "|r |cffffe4a3Training|r")
        call BlzFrameSetText(ABUI_ViewingText, "Hero: " + ABUI_GetUnitName(ABUI_SelectedHero) + " | AP: " + I2S(AbilityPoints_Get(ABUI_SelectedHero)))
        call BlzFrameSetText(ABUI_TrainerText, "Trainer: " + ABUI_GetUnitName(ABUI_SelectedTrainer))
    endfunction

    private function ABUI_UpdateDetail takes nothing returns nothing
        local integer entryIndex = ABUI_SelectedEntry
        local integer currentLevel
        local integer maxLevel
        local string learnText

        if entryIndex == 0 then
            call BlzFrameSetTexture(ABUI_DetailIcon, ABUI_DefaultIcon, 0, true)
            call BlzFrameSetText(ABUI_DetailTitle, "No abilities")
            call BlzFrameSetText(ABUI_DetailInfo, "")
            call BlzFrameSetText(ABUI_DetailBody, "No abilities are configured for this trainer.")
            call BlzFrameSetText(ABUI_DetailFooter, "")
            call BlzFrameSetText(ABUI_LearnButton, "Learn")
            return
        endif

        set currentLevel = Abilities_GetEntryLevel(ABUI_SelectedHero, entryIndex)
        set maxLevel = AbilitiesPlayer_GetEntryMaxLevel(entryIndex)
        if currentLevel <= 0 then
            set learnText = "Learn"
        elseif currentLevel < maxLevel then
            set learnText = "Upgrade"
        else
            set learnText = "Maxed"
        endif

        call BlzFrameSetTexture(ABUI_DetailIcon, AbilitiesPlayer_GetEntryIcon(entryIndex), 0, true)
        call BlzFrameSetText(ABUI_DetailTitle, "|cffffe4a3" + AbilitiesPlayer_GetEntryTitle(entryIndex) + "|r")
        call BlzFrameSetText(ABUI_DetailInfo, Abilities_GetEntryInfoText(ABUI_SelectedHero, entryIndex))
        call BlzFrameSetText(ABUI_DetailBody, Abilities_GetEntryBodyText(ABUI_SelectedHero, entryIndex))
        call BlzFrameSetText(ABUI_DetailFooter, "Available AP: " + I2S(AbilityPoints_Get(ABUI_SelectedHero)))
        call BlzFrameSetText(ABUI_LearnButton, learnText)
    endfunction

    private function ABUI_Update takes nothing returns nothing
        if ABUI_Parent == null then
            return
        endif

        call ABUI_ClampSelection()
        call ABUI_UpdateHeader()
        call ABUI_UpdateRows()
        call ABUI_UpdateDetail()
    endfunction

    private function ABUI_HideOtherPanels takes nothing returns nothing
        call ExecuteFunc("TasQuestBox_Hide")
        call ExecuteFunc("ProfessionsUI_Hide")
        call ExecuteFunc("CraftingUI_Hide")
        call ExecuteFunc("ReputationUI_Hide")
        call ExecuteFunc("StatsUI_Hide")
        call ExecuteFunc("AbilitiesLiteUI_Hide")
        call ExecuteFunc("TalentsUI_Hide")
        call ExecuteFunc("CameraUI_Hide")
        call ExecuteFunc("HintsUI_Hide")
        call ExecuteFunc("AchievementsUI_Hide")
        call ExecuteFunc("SecretsUI_Hide")
        call ExecuteFunc("CommandsUI_Hide")
        call ExecuteFunc("CheatsUI_Hide")
        call ExecuteFunc("SettingsUI_Hide")
    endfunction

    private function ABUI_OpenForPlayer takes player whichPlayer, unit trainer, unit hero returns nothing
        if whichPlayer != Player(0) then
            return
        endif

        set ABUI_SelectedTrainer = trainer
        set ABUI_SelectedHero = hero
        set ABUI_SelectedTree = AbilitiesPlayer_GetTrainerTreeByUnitType(GetUnitTypeId(trainer))
        call ABUI_ResetViewState()

        call ABUI_HideOtherPanels()
        if ABUI_Parent != null and not BlzFrameIsVisible(ABUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, whichPlayer)
        endif
        call MasterUI_Hide()
        call BlzFrameSetVisible(ABUI_Parent, true)
        call ABUI_Update()
    endfunction

    public function Hide takes nothing returns nothing
        if ABUI_Parent != null then
            if BlzFrameIsVisible(ABUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
            endif
            call BlzFrameSetVisible(ABUI_Parent, false)
        endif
    endfunction

    public function Refresh takes nothing returns nothing
        call ABUI_Update()
    endfunction

    public function ShowForTrainer takes unit trainer, unit hero returns nothing
        if trainer == null or hero == null then
            return
        endif
        if not AbilitiesPlayer_IsTrainerUnitType(GetUnitTypeId(trainer)) then
            return
        endif
        if not ABUI_IsPlayerShamanHero(hero) then
            return
        endif
        call ABUI_OpenForPlayer(GetOwningPlayer(hero), trainer, hero)
    endfunction

    private function ABUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function ABUI_CloseAction takes nothing returns nothing
        call Hide()
    endfunction

    private function ABUI_ReturnAction takes nothing returns nothing
        call Hide()
    endfunction

    private function ABUI_RowAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer rowIndex

        if ABUI_ButtonRow.has(handleId) then
            set rowIndex = ABUI_ButtonRow.integer[handleId]
            if ABUI_RowEntry[rowIndex] != 0 then
                set ABUI_SelectedEntry = ABUI_RowEntry[rowIndex]
                call ABUI_Update()
            endif
        endif
    endfunction

    private function ABUI_LearnAction takes nothing returns nothing
        if ABUI_SelectedHero != null and ABUI_SelectedEntry != 0 then
            call Abilities_Learn(ABUI_SelectedHero, ABUI_SelectedEntry)
            call ABUI_Update()
        endif
    endfunction

    private function ABUI_ResetAbilitiesAction takes nothing returns nothing
        if ABUI_SelectedHero != null then
            set ABUI_SelectedHero = Abilities_ResetAbilities(ABUI_SelectedHero)
            call ABUI_Update()
        endif
    endfunction

    private function ABUI_ResetSpecializationAction takes nothing returns nothing
        if ABUI_SelectedHero != null then
            call Abilities_ResetSpecialization(ABUI_SelectedHero)
            call ABUI_Update()
        endif
    endfunction

    private function ABUI_ResetTalentsAction takes nothing returns nothing
        if ABUI_SelectedHero != null then
            call Abilities_ResetTalents(ABUI_SelectedHero)
            call ABUI_Update()
        endif
    endfunction

    private function ABUI_ListScrollAction takes nothing returns nothing
        local integer maxStart = ABUI_GetEntryCount() - ABUI_VISIBLE_ROWS

        if ABUI_SyncingListScroll then
            return
        endif
        if maxStart < 0 then
            set maxStart = 0
        endif
        set ABUI_ListScrollFrameValueCache = R2I(BlzGetTriggerFrameValue() + 0.50)
        set ABUI_ListScrollValue = maxStart - ABUI_ListScrollFrameValueCache
        call ABUI_Update()
    endfunction

    private function ABUI_WheelAction takes nothing returns nothing
        local real newValue

        if GetLocalPlayer() == GetTriggerPlayer() then
            if ABUI_ListScroll != null and BlzFrameIsVisible(ABUI_ListScroll) then
                if BlzGetTriggerFrameValue() > 0.00 then
                    set newValue = BlzFrameGetValue(ABUI_ListScroll) + 1.00
                else
                    set newValue = BlzFrameGetValue(ABUI_ListScroll) - 1.00
                endif
                if newValue < 0.00 then
                    set newValue = 0.00
                elseif newValue > I2R(ABUI_ListScrollMaxCache) then
                    set newValue = I2R(ABUI_ListScrollMaxCache)
                endif
                call BlzFrameSetValue(ABUI_ListScroll, newValue)
            endif
        endif
    endfunction

    private function ABUI_SelectAction takes nothing returns nothing
        local player triggerPlayer = GetTriggerPlayer()
        local unit trainer = GetTriggerUnit()
        local unit hero

        if triggerPlayer != Player(0) or not AbilitiesPlayer_IsTrainerUnitType(GetUnitTypeId(trainer)) then
            set trainer = null
            set triggerPlayer = null
            return
        endif

        set hero = ABUI_GetNearestHero(trainer)
        if hero == null then
            call DisplayTextToPlayer(triggerPlayer, 0.00, 0.00, "|cffff8080No player shaman hero found.|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, triggerPlayer)
        elseif not ABUI_IsHeroNearTrainer(hero, trainer) then
            call DisplayTextToPlayer(triggerPlayer, 0.00, 0.00, "|cffff8080" + ABUI_GetUnitName(hero) + " is too far from the " + ABUI_GetUnitName(trainer) + ".|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, triggerPlayer)
        else
            call ABUI_OpenForPlayer(triggerPlayer, trainer, hero)
        endif

        set hero = null
        set trainer = null
        set triggerPlayer = null
    endfunction

    private function ABUI_CreateFrames takes nothing returns nothing
        local integer rowIndex = 1
        local real rowTopOffset = -0.010

        set ABUI_Parent = BlzCreateFrameByType("BACKDROP", "AbilitiesUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(ABUI_Parent, FRAMEPOINT_TOPLEFT, 0.10, 0.56)
        call BlzFrameSetAbsPoint(ABUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.68, 0.14)

        set ABUI_Title = BlzCreateFrameByType("TEXT", "AbilitiesUITitle", ABUI_Parent, "", 0)
        call BlzFrameSetPoint(ABUI_Title, FRAMEPOINT_TOPLEFT, ABUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(ABUI_Title, 0.300, 0.018)
        call BlzFrameSetTextAlignment(ABUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(ABUI_Title, 1.10)
        call BlzFrameSetEnable(ABUI_Title, false)

        set ABUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesUIClose", ABUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(ABUI_CloseButton, 0.030, 0.030)
        call BlzFrameSetText(ABUI_CloseButton, "X")
        call BlzFrameSetPoint(ABUI_CloseButton, FRAMEPOINT_TOPRIGHT, ABUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)

        set ABUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesUIReturn", ABUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(ABUI_ReturnButton, 0.065, 0.030)
        call BlzFrameSetText(ABUI_ReturnButton, "Return")
        call BlzFrameSetPoint(ABUI_ReturnButton, FRAMEPOINT_TOPRIGHT, ABUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)

        set ABUI_ViewingText = BlzCreateFrameByType("TEXT", "AbilitiesUIHero", ABUI_Parent, "", 0)
        call BlzFrameSetPoint(ABUI_ViewingText, FRAMEPOINT_TOPLEFT, ABUI_Title, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
        call BlzFrameSetSize(ABUI_ViewingText, 0.300, 0.014)
        call BlzFrameSetTextAlignment(ABUI_ViewingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(ABUI_ViewingText, false)

        set ABUI_TrainerText = BlzCreateFrameByType("TEXT", "AbilitiesUITrainer", ABUI_Parent, "", 0)
        call BlzFrameSetPoint(ABUI_TrainerText, FRAMEPOINT_TOPLEFT, ABUI_ViewingText, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.004)
        call BlzFrameSetSize(ABUI_TrainerText, 0.360, 0.014)
        call BlzFrameSetTextAlignment(ABUI_TrainerText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(ABUI_TrainerText, false)

        set ABUI_LeftPane = BlzCreateFrameByType("BACKDROP", "AbilitiesUILeftPane", ABUI_Parent, "", 0)
        call BlzFrameSetTexture(ABUI_LeftPane, ABUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(ABUI_LeftPane, FRAMEPOINT_TOPLEFT, ABUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.088)
        call BlzFrameSetPoint(ABUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, ABUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.228, 0.064)

        set ABUI_RightPane = BlzCreateFrameByType("BACKDROP", "AbilitiesUIRightPane", ABUI_Parent, "", 0)
        call BlzFrameSetTexture(ABUI_RightPane, ABUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(ABUI_RightPane, FRAMEPOINT_TOPLEFT, ABUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
        call BlzFrameSetPoint(ABUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, ABUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.064)

        set ABUI_ListScroll = BlzCreateFrameByType("SLIDER", "AbilitiesUIListScroll", ABUI_LeftPane, "QuestMainListScrollBar", 0)
        call BlzFrameSetPoint(ABUI_ListScroll, FRAMEPOINT_TOPLEFT, ABUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
        call BlzFrameSetSize(ABUI_ListScroll, BlzFrameGetWidth(ABUI_ListScroll), 0.250)
        call BlzFrameSetMinMaxValue(ABUI_ListScroll, 0.00, 0.00)
        call BlzFrameSetStepSize(ABUI_ListScroll, 1.00)
        call BlzFrameSetValue(ABUI_ListScroll, 0.00)
        call BlzFrameSetVisible(ABUI_ListScroll, false)
        call BlzTriggerRegisterFrameEvent(ABUI_ListScrollTrigger, ABUI_ListScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        call BlzTriggerRegisterFrameEvent(ABUI_WheelTrigger, ABUI_ListScroll, FRAMEEVENT_MOUSE_WHEEL)
        call BlzTriggerRegisterFrameEvent(ABUI_WheelTrigger, ABUI_LeftPane, FRAMEEVENT_MOUSE_WHEEL)

        loop
            exitwhen rowIndex > ABUI_VISIBLE_ROWS
            set ABUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "AbilitiesUIRowButton" + I2S(rowIndex), ABUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
            call BlzFrameSetPoint(ABUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, ABUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
            call BlzFrameSetSize(ABUI_RowButton[rowIndex], 0.202, ABUI_ROW_HEIGHT)
            call BlzFrameSetVisible(ABUI_RowButton[rowIndex], false)
            call BlzTriggerRegisterFrameEvent(ABUI_RowTrigger, ABUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
            call BlzTriggerRegisterFrameEvent(ABUI_ClearFocusTrigger, ABUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
            call BlzTriggerRegisterFrameEvent(ABUI_WheelTrigger, ABUI_RowButton[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
            set ABUI_ButtonRow.integer[GetHandleId(ABUI_RowButton[rowIndex])] = rowIndex

            set ABUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "AbilitiesUIRowIcon" + I2S(rowIndex), ABUI_RowButton[rowIndex], "IconButtonTemplate", 0)
            call BlzFrameSetPoint(ABUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, ABUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
            call BlzFrameSetSize(ABUI_RowIcon[rowIndex], 0.020, 0.020)

            set ABUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "AbilitiesUIRowText" + I2S(rowIndex), ABUI_RowButton[rowIndex], "", 0)
            call BlzFrameSetPoint(ABUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, ABUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
            call BlzFrameSetPoint(ABUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, ABUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.056, 0.004)
            call BlzFrameSetTextAlignment(ABUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
            call BlzFrameSetEnable(ABUI_RowText[rowIndex], false)

            set ABUI_RowState[rowIndex] = BlzCreateFrameByType("TEXT", "AbilitiesUIRowState" + I2S(rowIndex), ABUI_RowButton[rowIndex], "", 0)
            call BlzFrameSetPoint(ABUI_RowState[rowIndex], FRAMEPOINT_TOPRIGHT, ABUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.004)
            call BlzFrameSetPoint(ABUI_RowState[rowIndex], FRAMEPOINT_BOTTOMRIGHT, ABUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.004)
            call BlzFrameSetTextAlignment(ABUI_RowState[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
            call BlzFrameSetScale(ABUI_RowState[rowIndex], 0.84)
            call BlzFrameSetEnable(ABUI_RowState[rowIndex], false)

            set ABUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "AbilitiesUIRowHighlight" + I2S(rowIndex), ABUI_RowButton[rowIndex], "", 0)
            call BlzFrameSetAllPoints(ABUI_RowHighlight[rowIndex], ABUI_RowButton[rowIndex])
            call BlzFrameSetModel(ABUI_RowHighlight[rowIndex], ABUI_RowHighlightModel, 0)
            call BlzFrameSetScale(ABUI_RowHighlight[rowIndex], 0.76)
            call BlzFrameSetVisible(ABUI_RowHighlight[rowIndex], false)
            call BlzFrameSetEnable(ABUI_RowHighlight[rowIndex], false)

            set rowTopOffset = rowTopOffset - ABUI_ROW_HEIGHT - ABUI_ROW_GAP
            set rowIndex = rowIndex + 1
        endloop

        call BlzFrameClearAllPoints(ABUI_ListScroll)
        call BlzFrameSetPoint(ABUI_ListScroll, FRAMEPOINT_TOPLEFT, ABUI_RowButton[1], FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
        call BlzFrameSetSize(ABUI_ListScroll, BlzFrameGetWidth(ABUI_ListScroll), (ABUI_ROW_HEIGHT * I2R(ABUI_VISIBLE_ROWS)) + (ABUI_ROW_GAP * I2R(ABUI_VISIBLE_ROWS - 1)) + 0.004)

        set ABUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "AbilitiesUIDetailIcon", ABUI_RightPane, "IconButtonTemplate", 0)
        call BlzFrameSetPoint(ABUI_DetailIcon, FRAMEPOINT_TOPLEFT, ABUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(ABUI_DetailIcon, 0.044, 0.044)

        set ABUI_DetailTitle = BlzCreateFrameByType("TEXT", "AbilitiesUIDetailTitle", ABUI_RightPane, "", 0)
        call BlzFrameSetPoint(ABUI_DetailTitle, FRAMEPOINT_TOPLEFT, ABUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
        call BlzFrameSetSize(ABUI_DetailTitle, 0.260, 0.018)
        call BlzFrameSetTextAlignment(ABUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(ABUI_DetailTitle, 1.05)
        call BlzFrameSetEnable(ABUI_DetailTitle, false)

        set ABUI_DetailInfo = BlzCreateFrameByType("TEXT", "AbilitiesUIDetailInfo", ABUI_RightPane, "", 0)
        call BlzFrameSetPoint(ABUI_DetailInfo, FRAMEPOINT_TOPLEFT, ABUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
        call BlzFrameSetSize(ABUI_DetailInfo, 0.300, 0.028)
        call BlzFrameSetTextAlignment(ABUI_DetailInfo, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(ABUI_DetailInfo, 0.86)
        call BlzFrameSetEnable(ABUI_DetailInfo, false)

        set ABUI_DetailBody = BlzCreateFrameByType("TEXT", "AbilitiesUIDetailBody", ABUI_RightPane, "", 0)
        call BlzFrameSetPoint(ABUI_DetailBody, FRAMEPOINT_TOPLEFT, ABUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.092)
        call BlzFrameSetPoint(ABUI_DetailBody, FRAMEPOINT_BOTTOMRIGHT, ABUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.018, 0.036)
        call BlzFrameSetTextAlignment(ABUI_DetailBody, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(ABUI_DetailBody, 0.90)
        call BlzFrameSetEnable(ABUI_DetailBody, false)

        set ABUI_DetailFooter = BlzCreateFrameByType("TEXT", "AbilitiesUIDetailFooter", ABUI_RightPane, "", 0)
        call BlzFrameSetPoint(ABUI_DetailFooter, FRAMEPOINT_BOTTOMLEFT, ABUI_RightPane, FRAMEPOINT_BOTTOMLEFT, 0.018, 0.014)
        call BlzFrameSetSize(ABUI_DetailFooter, 0.160, 0.014)
        call BlzFrameSetTextAlignment(ABUI_DetailFooter, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(ABUI_DetailFooter, 0.88)
        call BlzFrameSetEnable(ABUI_DetailFooter, false)

        set ABUI_ResetAbilitiesButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesUIResetAbilities", ABUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(ABUI_ResetAbilitiesButton, 0.105, 0.030)
        call BlzFrameSetText(ABUI_ResetAbilitiesButton, "Reset Abilities")
        call BlzFrameSetPoint(ABUI_ResetAbilitiesButton, FRAMEPOINT_BOTTOMLEFT, ABUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.020, 0.018)

        set ABUI_ResetSpecializationButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesUIResetSpec", ABUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(ABUI_ResetSpecializationButton, 0.105, 0.030)
        call BlzFrameSetText(ABUI_ResetSpecializationButton, "Reset Spec")
        call BlzFrameSetPoint(ABUI_ResetSpecializationButton, FRAMEPOINT_LEFT, ABUI_ResetAbilitiesButton, FRAMEPOINT_RIGHT, 0.008, 0.0)

        set ABUI_ResetTalentsButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesUIResetTalents", ABUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(ABUI_ResetTalentsButton, 0.105, 0.030)
        call BlzFrameSetText(ABUI_ResetTalentsButton, "Reset Talents")
        call BlzFrameSetPoint(ABUI_ResetTalentsButton, FRAMEPOINT_LEFT, ABUI_ResetSpecializationButton, FRAMEPOINT_RIGHT, 0.008, 0.0)

        set ABUI_LearnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesUILearn", ABUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(ABUI_LearnButton, 0.100, 0.032)
        call BlzFrameSetText(ABUI_LearnButton, "Learn")
        call BlzFrameSetPoint(ABUI_LearnButton, FRAMEPOINT_BOTTOMRIGHT, ABUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.024, 0.030)

        call BlzTriggerRegisterFrameEvent(ABUI_CloseTrigger, ABUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ClearFocusTrigger, ABUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ReturnTrigger, ABUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ClearFocusTrigger, ABUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_LearnTrigger, ABUI_LearnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ClearFocusTrigger, ABUI_LearnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ResetAbilitiesTrigger, ABUI_ResetAbilitiesButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ClearFocusTrigger, ABUI_ResetAbilitiesButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ResetSpecializationTrigger, ABUI_ResetSpecializationButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ClearFocusTrigger, ABUI_ResetSpecializationButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ResetTalentsTrigger, ABUI_ResetTalentsButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ABUI_ClearFocusTrigger, ABUI_ResetTalentsButton, FRAMEEVENT_CONTROL_CLICK)

        call BlzFrameSetVisible(ABUI_Parent, false)
    endfunction

    public function Init takes nothing returns nothing
        if ABUI_Initialized then
            return
        endif
        set ABUI_Initialized = true

        set ABUI_ButtonRow = Table.create()

        set ABUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_CloseTrigger, function ABUI_CloseAction)

        set ABUI_ReturnTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_ReturnTrigger, function ABUI_ReturnAction)

        set ABUI_RowTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_RowTrigger, function ABUI_RowAction)

        set ABUI_LearnTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_LearnTrigger, function ABUI_LearnAction)

        set ABUI_ResetAbilitiesTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_ResetAbilitiesTrigger, function ABUI_ResetAbilitiesAction)

        set ABUI_ResetSpecializationTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_ResetSpecializationTrigger, function ABUI_ResetSpecializationAction)

        set ABUI_ResetTalentsTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_ResetTalentsTrigger, function ABUI_ResetTalentsAction)

        set ABUI_ListScrollTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_ListScrollTrigger, function ABUI_ListScrollAction)

        set ABUI_WheelTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_WheelTrigger, function ABUI_WheelAction)

        set ABUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(ABUI_ClearFocusTrigger, function ABUI_ClearFocusAction)

        call ABUI_CreateFrames()
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
