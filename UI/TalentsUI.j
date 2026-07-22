/**
    TalentsUI

    Author: Valdemar
    Version:

    Description:
    Custom frame talent tree UI for player shaman heroes. Displays Elemental,
    Enhancement, Restoration, and Totemic talent trees in a grid with pending
    allocation, confirm/cancel controls, stable hover tooltips, and dependency
    links. Talent reset is only enabled while the hero is near a configured
    ability trainer.

    Credits:
    Tasyen (TasQuestBox as inspiration)

    How to install:
    Import after Talents, AbilitiesPlayer, MasterUI, Table, and Interface.
    AbilitiesLiteUI can open this UI through TalentsUI_ShowForUnit.

    API:
    - call TalentsUI_ShowForUnit(hero)
    - call TalentsUI_Show()
    - call TalentsUI_Hide()
    - call TalentsUI_Refresh()

**/
library TalentsUI initializer AutoInit requires Table, MasterUI, Talents, AbilitiesPlayer, Interface
    globals
        private constant integer TUI_TREE_BUTTON_COUNT = 4
        private constant integer TUI_GRID_ROWS = 6
        private constant integer TUI_GRID_COLUMNS = 5
        private constant integer TUI_GRID_SLOTS = 30
        private constant real TUI_TALENT_SIZE = 0.030
        private constant real TUI_TALENT_GAP_X = 0.024
        private constant real TUI_TALENT_GAP_Y = 0.014
        private constant real TUI_TALENT_START_X = 0.032
        private constant real TUI_TALENT_START_Y = -0.018
        private constant real TUI_LINK_THICKNESS = 0.005
        private constant real TUI_TOOLTIP_WIDTH = 0.235
        private constant real TUI_TOOLTIP_HEIGHT = 0.130
        private constant real TUI_TRAINER_RESET_RANGE = 900.00
        private constant integer TUI_LINK_LEFT = 1
        private constant integer TUI_LINK_UP = 2
        private constant integer TUI_LINK_RIGHT = 3
        private constant integer TUI_LINK_DOWN = 4

        private boolean TUI_Initialized = false

        private framehandle TUI_Parent = null
        private framehandle TUI_Title = null
        private framehandle TUI_ViewingText = null
        private framehandle TUI_TreePane = null
        private framehandle TUI_DetailPane = null
        private framehandle TUI_DetailIcon = null
        private framehandle TUI_DetailTitle = null
        private framehandle TUI_DetailInfo = null
        private framehandle TUI_DetailBody = null
        private framehandle TUI_DetailFooter = null
        private framehandle TUI_CloseButton = null
        private framehandle TUI_ReturnButton = null
        private framehandle TUI_LearnButton = null
        private framehandle TUI_RemoveButton = null
        private framehandle TUI_ConfirmButton = null
        private framehandle TUI_CancelButton = null
        private framehandle TUI_ResetButton = null

        private framehandle array TUI_TreeButton
        private framehandle array TUI_TalentButton
        private framehandle array TUI_TalentIcon
        private framehandle array TUI_TalentOverlay
        private framehandle array TUI_TalentRankText
        private framehandle array TUI_TalentHighlight
        private framehandle array TUI_TalentLinkLeft
        private framehandle array TUI_TalentLinkUp
        private framehandle array TUI_TalentLinkRight
        private framehandle array TUI_TalentLinkDown
        private framehandle array TUI_TalentTooltipBox
        private framehandle array TUI_TalentTooltipText
        private framehandle array TUI_TalentTooltipRank

        private unit TUI_SelectedHero = null
        private integer TUI_SelectedTree = AbilitiesPlayer_TREE_ELEMENTAL
        private integer TUI_SelectedTalent = 0
        private integer TUI_HoverTalent = 0
        private integer array TUI_TreeButtonTree
        private integer array TUI_TalentSlotIndex
        private integer array TUI_TalentHighlightVisible

        private Table TUI_ButtonTree = 0
        private Table TUI_ButtonTalent = 0
        private group TUI_TrainerScanGroup = null

        private trigger TUI_CloseTrigger = null
        private trigger TUI_ReturnTrigger = null
        private trigger TUI_TreeTrigger = null
        private trigger TUI_TalentTrigger = null
        private trigger TUI_TalentEnterTrigger = null
        private trigger TUI_TalentLeaveTrigger = null
        private trigger TUI_LearnTrigger = null
        private trigger TUI_RemoveTrigger = null
        private trigger TUI_ConfirmTrigger = null
        private trigger TUI_CancelTrigger = null
        private trigger TUI_ResetTrigger = null
        private trigger TUI_ClearFocusTrigger = null

        private string TUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
        private string TUI_DefaultIcon = "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"
        private string TUI_TalentHighlightTexture = "UI\\Widgets\\Console\\Human\\CommandButton\\human-activebutton.blp"
        private string TUI_LinkActiveTexture = "Textures\\Water00.blp"
        private string TUI_LinkInactiveTexture = "UI\\Widgets\\Console\\Human\\human-inventory-slotfiller.blp"
    endglobals

    private function TUI_GetUnitName takes unit whichUnit returns string
        if whichUnit == null or GetHandleId(whichUnit) == 0 then
            return "No unit"
        endif
        if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
            return GetHeroProperName(whichUnit)
        endif
        return GetUnitName(whichUnit)
    endfunction

    private function TUI_IsPlayerShamanHero takes unit whichUnit returns boolean
        if whichUnit == null or GetHandleId(whichUnit) == 0 then
            return false
        endif
        if whichUnit != udg_Nazgrek and whichUnit != udg_Zulkis then
            return false
        endif
        return GetOwningPlayer(whichUnit) == Player(0)
    endfunction

    private function TUI_IsHeroNearTrainer takes unit hero returns boolean
        local unit enumUnit
        local boolean foundTrainer = false

        if hero == null or TUI_TrainerScanGroup == null then
            set enumUnit = null
            return false
        endif

        call GroupEnumUnitsInRange(TUI_TrainerScanGroup, GetUnitX(hero), GetUnitY(hero), TUI_TRAINER_RESET_RANGE, null)
        loop
            set enumUnit = FirstOfGroup(TUI_TrainerScanGroup)
            exitwhen enumUnit == null
            call GroupRemoveUnit(TUI_TrainerScanGroup, enumUnit)
            if AbilitiesPlayer_IsTrainerUnitType(GetUnitTypeId(enumUnit)) then
                set foundTrainer = true
            endif
        endloop

        set enumUnit = null
        return foundTrainer
    endfunction

    private function TUI_CanResetTalents takes nothing returns boolean
        return TUI_IsPlayerShamanHero(TUI_SelectedHero) and TUI_IsHeroNearTrainer(TUI_SelectedHero)
    endfunction

    private function TUI_GetDefaultHero takes nothing returns unit
        if TUI_IsPlayerShamanHero(udg_Nazgrek) then
            return udg_Nazgrek
        elseif TUI_IsPlayerShamanHero(udg_Zulkis) then
            return udg_Zulkis
        endif
        return null
    endfunction

    private function TUI_GetSlotIndex takes integer row, integer column returns integer
        return (row - 1) * TUI_GRID_COLUMNS + column
    endfunction

    private function TUI_GetFirstTalentForTree takes integer treeId returns integer
        return Talents_GetTalentByTreeIndex(treeId, 1)
    endfunction

    private function TUI_HideOtherPanels takes nothing returns nothing
        call ExecuteFunc("TasQuestBox_Hide")
        call ExecuteFunc("ProfessionsUI_Hide")
        call ExecuteFunc("CraftingUI_Hide")
        call ExecuteFunc("ReputationUI_Hide")
        call ExecuteFunc("StatsUI_Hide")
        call ExecuteFunc("AbilitiesLiteUI_Hide")
        call ExecuteFunc("AbilitiesUI_Hide")
        call ExecuteFunc("CameraUI_Hide")
        call ExecuteFunc("HintsUI_Hide")
        call ExecuteFunc("AchievementsUI_Hide")
        call ExecuteFunc("SecretsUI_Hide")
        call ExecuteFunc("CommandsUI_Hide")
        call ExecuteFunc("CheatsUI_Hide")
        call ExecuteFunc("SettingsUI_Hide")
    endfunction

    private function TUI_ClampSelection takes nothing returns nothing
        if TUI_SelectedTalent == 0 or Talents_GetTalentTree(TUI_SelectedTalent) != TUI_SelectedTree then
            set TUI_SelectedTalent = TUI_GetFirstTalentForTree(TUI_SelectedTree)
        endif
        if TUI_HoverTalent != 0 and Talents_GetTalentTree(TUI_HoverTalent) != TUI_SelectedTree then
            set TUI_HoverTalent = 0
        endif
    endfunction

    private function TUI_FormatTreeButtonText takes integer treeId returns string
        local string treeName = AbilitiesPlayer_GetTreeName(treeId)

        if treeId == TUI_SelectedTree then
            return AbilitiesPlayer_GetTreeColor(treeId) + treeName + "|r"
        endif
        return "|cffbfbfbf" + treeName + "|r"
    endfunction

    private function TUI_FormatRankText takes integer talentIndex returns string
        local integer rank = Talents_GetTalentPreviewRank(TUI_SelectedHero, talentIndex)
        local integer pending = Talents_GetTalentPendingRank(TUI_SelectedHero, talentIndex)
        local integer maxRank = Talents_GetTalentMaxRank(talentIndex)

        if rank >= maxRank then
            return "|cffffcc00" + I2S(rank) + "|r"
        elseif pending > 0 then
            return "|cff80ff80" + I2S(rank) + "|r"
        elseif rank > 0 then
            return "|cffffffff" + I2S(rank) + "|r"
        endif
        return ""
    endfunction

    private function TUI_GetDetailTalent takes nothing returns integer
        if TUI_HoverTalent != 0 and Talents_GetTalentTree(TUI_HoverTalent) == TUI_SelectedTree then
            return TUI_HoverTalent
        endif
        return TUI_SelectedTalent
    endfunction

    private function TUI_SetLinkFrame takes framehandle whichFrame, boolean visible, boolean active returns nothing
        call BlzFrameSetVisible(whichFrame, visible)
        if active then
            call BlzFrameSetTexture(whichFrame, TUI_LinkActiveTexture, 0, true)
        else
            call BlzFrameSetTexture(whichFrame, TUI_LinkInactiveTexture, 0, true)
        endif
    endfunction

    private function TUI_ClearSlotLinks takes integer slotIndex returns nothing
        call BlzFrameSetVisible(TUI_TalentLinkLeft[slotIndex], false)
        call BlzFrameSetVisible(TUI_TalentLinkUp[slotIndex], false)
        call BlzFrameSetVisible(TUI_TalentLinkRight[slotIndex], false)
        call BlzFrameSetVisible(TUI_TalentLinkDown[slotIndex], false)
    endfunction

    private function TUI_UpdateTalentLinks takes integer slotIndex, integer talentIndex returns nothing
        local integer requiredTalentIndex
        local integer requiredTalentId
        local integer requiredRank
        local integer row
        local integer column
        local integer requiredRow
        local integer requiredColumn
        local boolean active

        call TUI_ClearSlotLinks(slotIndex)
        if talentIndex == 0 then
            return
        endif

        set requiredTalentId = Talents_GetTalentRequiredTalentId(talentIndex)
        if requiredTalentId == 0 then
            return
        endif

        set requiredTalentIndex = Talents_GetTalentIndexById(requiredTalentId)
        if requiredTalentIndex == 0 or Talents_GetTalentTree(requiredTalentIndex) != TUI_SelectedTree then
            return
        endif

        set requiredRank = Talents_GetTalentRequiredTalentRank(talentIndex)
        set active = Talents_GetTalentPreviewRank(TUI_SelectedHero, requiredTalentIndex) >= requiredRank
        set row = Talents_GetTalentRow(talentIndex)
        set column = Talents_GetTalentColumn(talentIndex)
        set requiredRow = Talents_GetTalentRow(requiredTalentIndex)
        set requiredColumn = Talents_GetTalentColumn(requiredTalentIndex)

        if requiredColumn < column then
            call TUI_SetLinkFrame(TUI_TalentLinkLeft[slotIndex], true, active)
        elseif requiredColumn > column then
            call TUI_SetLinkFrame(TUI_TalentLinkRight[slotIndex], true, active)
        endif
        if requiredRow < row then
            call TUI_SetLinkFrame(TUI_TalentLinkUp[slotIndex], true, active)
        elseif requiredRow > row then
            call TUI_SetLinkFrame(TUI_TalentLinkDown[slotIndex], true, active)
        endif
    endfunction

    private function TUI_UpdateTalentTooltip takes integer slotIndex, integer talentIndex returns nothing
        local string failureText = ""
        local string tooltipText = ""
        local string rankText = ""

        if talentIndex == 0 then
            call BlzFrameSetText(TUI_TalentTooltipText[slotIndex], "")
            call BlzFrameSetText(TUI_TalentTooltipRank[slotIndex], "")
            return
        endif

        set failureText = Talents_GetAllocateFailureText(TUI_SelectedHero, talentIndex)
        set rankText = "Rank " + I2S(Talents_GetTalentPreviewRank(TUI_SelectedHero, talentIndex)) + "/" + I2S(Talents_GetTalentMaxRank(talentIndex))
        set tooltipText = "|cffffe4a3" + Talents_GetTalentTitle(talentIndex) + "|r|n" + Talents_GetTalentPreviewInfoText(TUI_SelectedHero, talentIndex)
        if failureText != "" and not Talents_IsTalentPreviewMaxed(TUI_SelectedHero, talentIndex) then
            set tooltipText = tooltipText + "|n|n" + failureText
        endif
        if Talents_GetTalentPendingRank(TUI_SelectedHero, talentIndex) > 0 then
            set tooltipText = tooltipText + "|n|n|cff80ff80Pending ranks: " + I2S(Talents_GetTalentPendingRank(TUI_SelectedHero, talentIndex)) + "|r"
        endif
        set tooltipText = tooltipText + "|n|n" + Talents_GetTalentPreviewBodyText(TUI_SelectedHero, talentIndex)

        call BlzFrameSetText(TUI_TalentTooltipText[slotIndex], tooltipText)
        call BlzFrameSetText(TUI_TalentTooltipRank[slotIndex], rankText)
    endfunction

    private function TUI_HideTalentTooltips takes nothing returns nothing
        local integer slotIndex = 1

        loop
            exitwhen slotIndex > TUI_GRID_SLOTS
            if TUI_TalentTooltipBox[slotIndex] != null then
                call BlzFrameSetVisible(TUI_TalentTooltipBox[slotIndex], false)
            endif
            set slotIndex = slotIndex + 1
        endloop
    endfunction

    private function TUI_PositionTalentTooltip takes integer slotIndex returns nothing
        local integer row = R2I(I2R(slotIndex - 1) / I2R(TUI_GRID_COLUMNS)) + 1
        local integer column = ModuloInteger(slotIndex - 1, TUI_GRID_COLUMNS) + 1

        call BlzFrameClearAllPoints(TUI_TalentTooltipBox[slotIndex])
        if column >= TUI_GRID_COLUMNS - 1 then
            if row >= TUI_GRID_ROWS - 1 then
                call BlzFrameSetPoint(TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_BOTTOMRIGHT, TUI_TalentButton[slotIndex], FRAMEPOINT_TOPLEFT, -0.008, 0.006)
            else
                call BlzFrameSetPoint(TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_TOPRIGHT, TUI_TalentButton[slotIndex], FRAMEPOINT_TOPLEFT, -0.008, 0.006)
            endif
        elseif row >= TUI_GRID_ROWS - 1 then
            call BlzFrameSetPoint(TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_BOTTOMLEFT, TUI_TalentButton[slotIndex], FRAMEPOINT_TOPRIGHT, 0.008, 0.006)
        else
            call BlzFrameSetPoint(TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_TOPLEFT, TUI_TalentButton[slotIndex], FRAMEPOINT_TOPRIGHT, 0.008, 0.006)
        endif
    endfunction

    private function TUI_ShowTalentTooltip takes integer slotIndex returns nothing
        local integer talentIndex

        if slotIndex < 1 or slotIndex > TUI_GRID_SLOTS then
            return
        endif

        set talentIndex = TUI_TalentSlotIndex[slotIndex]
        if talentIndex == 0 then
            return
        endif

        call TUI_HideTalentTooltips()
        call TUI_UpdateTalentTooltip(slotIndex, talentIndex)
        call TUI_PositionTalentTooltip(slotIndex)
        call BlzFrameSetVisible(TUI_TalentTooltipBox[slotIndex], true)
    endfunction

    private function TUI_UpdateTabs takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > TUI_TREE_BUTTON_COUNT
            call BlzFrameSetText(TUI_TreeButton[index], TUI_FormatTreeButtonText(TUI_TreeButtonTree[index]))
            set index = index + 1
        endloop
    endfunction

    private function TUI_UpdateHeader takes nothing returns nothing
        local integer pending = Talents_GetPendingSpentPoints(TUI_SelectedHero)
        local string text = "Hero: " + TUI_GetUnitName(TUI_SelectedHero) + " | Talent Points: " + I2S(Talents_GetPreviewAvailablePoints(TUI_SelectedHero)) + "/" + I2S(Talents_GetTotalPoints(TUI_SelectedHero))

        if pending > 0 then
            set text = text + " |cff80ff80Pending: " + I2S(pending) + "|r"
        endif

        call BlzFrameSetText(TUI_Title, "|cffffe4a3Talent Tree|r")
        call BlzFrameSetText(TUI_ViewingText, text)
    endfunction

    private function TUI_UpdateGrid takes nothing returns nothing
        local integer row = 1
        local integer column
        local integer slotIndex
        local integer talentIndex
        local integer selected
        local integer treeRows = Talents_GetTreeRows(TUI_SelectedTree)
        local integer treeColumns = Talents_GetTreeColumns(TUI_SelectedTree)
        local boolean unavailable

        loop
            exitwhen row > TUI_GRID_ROWS
            set column = 1
            loop
                exitwhen column > TUI_GRID_COLUMNS
                set slotIndex = TUI_GetSlotIndex(row, column)
                if row <= treeRows and column <= treeColumns then
                    set talentIndex = Talents_GetTalentByTreePosition(TUI_SelectedTree, row, column)
                else
                    set talentIndex = 0
                endif
                set TUI_TalentSlotIndex[slotIndex] = talentIndex

                if talentIndex != 0 then
                    call BlzFrameSetTexture(TUI_TalentIcon[slotIndex], Talents_GetTalentIcon(talentIndex), 0, true)
                    call BlzFrameSetText(TUI_TalentRankText[slotIndex], TUI_FormatRankText(talentIndex))
                    call TUI_UpdateTalentTooltip(slotIndex, talentIndex)
                    call TUI_UpdateTalentLinks(slotIndex, talentIndex)
                    call BlzFrameSetVisible(TUI_TalentButton[slotIndex], true)

                    set unavailable = not Talents_CanAllocate(TUI_SelectedHero, talentIndex) and Talents_GetTalentPreviewRank(TUI_SelectedHero, talentIndex) <= 0
                    call BlzFrameSetVisible(TUI_TalentOverlay[slotIndex], unavailable)

                    if talentIndex == TUI_SelectedTalent or Talents_CanAllocate(TUI_SelectedHero, talentIndex) then
                        set selected = 1
                    else
                        set selected = 0
                    endif
                    if TUI_TalentHighlightVisible[slotIndex] != selected then
                        set TUI_TalentHighlightVisible[slotIndex] = selected
                        call BlzFrameSetVisible(TUI_TalentHighlight[slotIndex], selected == 1)
                    endif
                else
                    set TUI_TalentSlotIndex[slotIndex] = 0
                    set TUI_TalentHighlightVisible[slotIndex] = 0
                    call BlzFrameSetVisible(TUI_TalentButton[slotIndex], false)
                    call BlzFrameSetVisible(TUI_TalentHighlight[slotIndex], false)
                    call BlzFrameSetVisible(TUI_TalentTooltipBox[slotIndex], false)
                    call TUI_ClearSlotLinks(slotIndex)
                endif

                set column = column + 1
            endloop
            set row = row + 1
        endloop
    endfunction

    private function TUI_UpdateResetButton takes nothing returns nothing
        local boolean canReset = TUI_CanResetTalents()

        call BlzFrameSetEnable(TUI_ResetButton, canReset)
    endfunction

    private function TUI_UpdateDetail takes nothing returns nothing
        local integer talentIndex = TUI_GetDetailTalent()
        local integer pending = Talents_GetPendingSpentPoints(TUI_SelectedHero)
        local string buttonText = "Add Rank"
        local string footerText
        local string failureText

        call TUI_UpdateResetButton()
        if talentIndex == 0 then
            call BlzFrameSetTexture(TUI_DetailIcon, TUI_DefaultIcon, 0, true)
            call BlzFrameSetText(TUI_DetailTitle, "No talents")
            call BlzFrameSetText(TUI_DetailInfo, "")
            call BlzFrameSetText(TUI_DetailBody, "No talents are configured for this tree.")
            call BlzFrameSetText(TUI_DetailFooter, "")
            call BlzFrameSetText(TUI_LearnButton, buttonText)
            call BlzFrameSetEnable(TUI_LearnButton, false)
            call BlzFrameSetEnable(TUI_RemoveButton, false)
            call BlzFrameSetEnable(TUI_ConfirmButton, pending > 0)
            call BlzFrameSetEnable(TUI_CancelButton, pending > 0)
            return
        endif

        if Talents_IsTalentPreviewMaxed(TUI_SelectedHero, talentIndex) then
            set buttonText = "Maxed"
        elseif not Talents_CanAllocate(TUI_SelectedHero, talentIndex) then
            set buttonText = "Locked"
        endif

        set failureText = Talents_GetAllocateFailureText(TUI_SelectedHero, talentIndex)
        set footerText = "Tree points: " + I2S(Talents_GetTreePreviewSpentPoints(TUI_SelectedHero, TUI_SelectedTree)) + " | Available: " + I2S(Talents_GetPreviewAvailablePoints(TUI_SelectedHero))
        if pending > 0 then
            set footerText = footerText + " |cffffcc80-|r |cff80ff80Pending: " + I2S(pending) + "|r"
        endif
        if failureText != "" and not Talents_IsTalentPreviewMaxed(TUI_SelectedHero, talentIndex) then
            set footerText = footerText + "|n" + failureText
        elseif pending > 0 then
            set footerText = footerText + "|n|cff80ff80Confirm pending ranks to apply talent effects.|r"
        endif

        call BlzFrameSetTexture(TUI_DetailIcon, Talents_GetTalentIcon(talentIndex), 0, true)
        call BlzFrameSetText(TUI_DetailTitle, "|cffffe4a3" + Talents_GetTalentTitle(talentIndex) + "|r")
        call BlzFrameSetText(TUI_DetailInfo, Talents_GetTalentPreviewInfoText(TUI_SelectedHero, talentIndex))
        call BlzFrameSetText(TUI_DetailBody, Talents_GetTalentPreviewBodyText(TUI_SelectedHero, talentIndex))
        call BlzFrameSetText(TUI_DetailFooter, footerText)
        call BlzFrameSetText(TUI_LearnButton, buttonText)
        call BlzFrameSetText(TUI_ConfirmButton, "Confirm")
        if pending > 0 then
            call BlzFrameSetText(TUI_ConfirmButton, "Confirm (" + I2S(pending) + ")")
        endif
        call BlzFrameSetEnable(TUI_LearnButton, Talents_CanAllocate(TUI_SelectedHero, talentIndex))
        call BlzFrameSetEnable(TUI_RemoveButton, Talents_CanDeallocate(TUI_SelectedHero, talentIndex))
        call BlzFrameSetEnable(TUI_ConfirmButton, pending > 0)
        call BlzFrameSetEnable(TUI_CancelButton, pending > 0)
    endfunction

    private function TUI_Update takes nothing returns nothing
        if TUI_Parent == null then
            return
        endif

        call TUI_ClampSelection()
        call TUI_UpdateHeader()
        call TUI_UpdateTabs()
        call TUI_UpdateGrid()
        call TUI_UpdateDetail()
    endfunction

    private function TUI_OpenForHero takes unit hero returns nothing
        if not TUI_IsPlayerShamanHero(hero) then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080No player shaman hero selected.|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
            return
        endif

        set TUI_SelectedHero = hero
        if TUI_SelectedTree == AbilitiesPlayer_TREE_NONE then
            set TUI_SelectedTree = AbilitiesPlayer_TREE_ELEMENTAL
        endif
        set TUI_SelectedTalent = TUI_GetFirstTalentForTree(TUI_SelectedTree)
        set TUI_HoverTalent = 0
        call TUI_HideTalentTooltips()

        call TUI_HideOtherPanels()
        if TUI_Parent != null and not BlzFrameIsVisible(TUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
        endif
        call MasterUI_Hide()
        call BlzFrameSetVisible(TUI_Parent, true)
        call TUI_Update()
    endfunction

    public function Hide takes nothing returns nothing
        if TUI_Parent != null then
            if BlzFrameIsVisible(TUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
            endif
            set TUI_HoverTalent = 0
            call TUI_HideTalentTooltips()
            call BlzFrameSetVisible(TUI_Parent, false)
        endif
    endfunction

    public function Refresh takes nothing returns nothing
        call TUI_Update()
    endfunction

    public function ShowForUnit takes unit hero returns nothing
        call TUI_OpenForHero(hero)
    endfunction

    public function Show takes nothing returns nothing
        local unit hero = TUI_GetDefaultHero()

        call TUI_OpenForHero(hero)

        set hero = null
    endfunction

    private function TUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function TUI_CloseAction takes nothing returns nothing
        call Hide()
    endfunction

    private function TUI_ReturnAction takes nothing returns nothing
        call Hide()
        call ExecuteFunc("AbilitiesLiteUI_Show")
    endfunction

    private function TUI_TreeAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())

        if TUI_ButtonTree.has(handleId) then
            set TUI_SelectedTree = TUI_ButtonTree.integer[handleId]
            set TUI_SelectedTalent = TUI_GetFirstTalentForTree(TUI_SelectedTree)
            set TUI_HoverTalent = 0
            call TUI_HideTalentTooltips()
            call TUI_Update()
        endif
    endfunction

    private function TUI_TalentAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer slotIndex

        if TUI_ButtonTalent.has(handleId) then
            set slotIndex = TUI_ButtonTalent.integer[handleId]
            if TUI_TalentSlotIndex[slotIndex] != 0 then
                set TUI_SelectedTalent = TUI_TalentSlotIndex[slotIndex]
                call TUI_Update()
            endif
        endif
    endfunction

    private function TUI_TalentEnterAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer slotIndex

        if TUI_ButtonTalent.has(handleId) then
            set slotIndex = TUI_ButtonTalent.integer[handleId]
            if TUI_TalentSlotIndex[slotIndex] != 0 then
                set TUI_HoverTalent = TUI_TalentSlotIndex[slotIndex]
                call TUI_ShowTalentTooltip(slotIndex)
                call TUI_UpdateDetail()
            endif
        endif
    endfunction

    private function TUI_TalentLeaveAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer slotIndex

        if TUI_ButtonTalent.has(handleId) then
            set slotIndex = TUI_ButtonTalent.integer[handleId]
            if TUI_HoverTalent == TUI_TalentSlotIndex[slotIndex] then
                set TUI_HoverTalent = 0
                call BlzFrameSetVisible(TUI_TalentTooltipBox[slotIndex], false)
                call TUI_UpdateDetail()
            endif
        endif
    endfunction

    private function TUI_LearnAction takes nothing returns nothing
        if TUI_SelectedHero != null and TUI_SelectedTalent != 0 then
            call Talents_Allocate(TUI_SelectedHero, TUI_SelectedTalent)
            call TUI_Update()
        endif
    endfunction

    private function TUI_RemoveAction takes nothing returns nothing
        if TUI_SelectedHero != null and TUI_SelectedTalent != 0 then
            call Talents_Deallocate(TUI_SelectedHero, TUI_SelectedTalent)
            call TUI_Update()
        endif
    endfunction

    private function TUI_ConfirmAction takes nothing returns nothing
        if TUI_SelectedHero != null then
            call Talents_ConfirmPending(TUI_SelectedHero)
            call TUI_Update()
        endif
    endfunction

    private function TUI_CancelAction takes nothing returns nothing
        if TUI_SelectedHero != null then
            call Talents_CancelPending(TUI_SelectedHero)
            call TUI_Update()
        endif
    endfunction

    private function TUI_ResetAction takes nothing returns nothing
        if TUI_SelectedHero != null then
            if not TUI_CanResetTalents() then
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Talent reset requires an ability trainer.|r")
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
                return
            endif
            call Talents_ResetHeroTalents(TUI_SelectedHero)
            set TUI_HoverTalent = 0
            call TUI_HideTalentTooltips()
            call TUI_Update()
        endif
    endfunction

    private function TUI_CreateTreeButton takes integer index, integer treeId, real xOffset returns nothing
        set TUI_TreeButtonTree[index] = treeId
        set TUI_TreeButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUITreeButton" + I2S(index), TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_TreeButton[index], 0.092, 0.026)
        call BlzFrameSetPoint(TUI_TreeButton[index], FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, xOffset, -0.058)
        call BlzFrameSetText(TUI_TreeButton[index], AbilitiesPlayer_GetTreeName(treeId))
        call BlzTriggerRegisterFrameEvent(TUI_TreeTrigger, TUI_TreeButton[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_TreeButton[index], FRAMEEVENT_CONTROL_CLICK)
        set TUI_ButtonTree.integer[GetHandleId(TUI_TreeButton[index])] = treeId
    endfunction

    private function TUI_SetupLinkFrame takes framehandle linkFrame, framehandle buttonFrame, integer direction returns nothing
        call BlzFrameSetTexture(linkFrame, TUI_LinkInactiveTexture, 0, true)
        call BlzFrameSetLevel(linkFrame, 1)
        call BlzFrameSetVisible(linkFrame, false)
        call BlzFrameSetEnable(linkFrame, false)

        if direction == TUI_LINK_LEFT then
            call BlzFrameSetSize(linkFrame, TUI_TALENT_GAP_X + 0.004, TUI_LINK_THICKNESS)
            call BlzFrameSetPoint(linkFrame, FRAMEPOINT_RIGHT, buttonFrame, FRAMEPOINT_LEFT, 0.002, 0.0)
        elseif direction == TUI_LINK_UP then
            call BlzFrameSetSize(linkFrame, TUI_LINK_THICKNESS, TUI_TALENT_GAP_Y + 0.004)
            call BlzFrameSetPoint(linkFrame, FRAMEPOINT_BOTTOM, buttonFrame, FRAMEPOINT_TOP, 0.0, -0.002)
        elseif direction == TUI_LINK_RIGHT then
            call BlzFrameSetSize(linkFrame, TUI_TALENT_GAP_X + 0.004, TUI_LINK_THICKNESS)
            call BlzFrameSetPoint(linkFrame, FRAMEPOINT_LEFT, buttonFrame, FRAMEPOINT_RIGHT, -0.002, 0.0)
        elseif direction == TUI_LINK_DOWN then
            call BlzFrameSetSize(linkFrame, TUI_LINK_THICKNESS, TUI_TALENT_GAP_Y + 0.004)
            call BlzFrameSetPoint(linkFrame, FRAMEPOINT_TOP, buttonFrame, FRAMEPOINT_BOTTOM, 0.0, 0.002)
        endif
    endfunction

    private function TUI_CreateFrames takes nothing returns nothing
        local integer row = 1
        local integer column
        local integer slotIndex
        local real xOffset
        local real yOffset

        set TUI_Parent = BlzCreateFrameByType("BACKDROP", "TalentsUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(TUI_Parent, FRAMEPOINT_TOPLEFT, 0.10, 0.56)
        call BlzFrameSetAbsPoint(TUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.68, 0.14)

        set TUI_Title = BlzCreateFrameByType("TEXT", "TalentsUITitle", TUI_Parent, "", 0)
        call BlzFrameSetPoint(TUI_Title, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(TUI_Title, 0.260, 0.018)
        call BlzFrameSetTextAlignment(TUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_Title, 1.10)
        call BlzFrameSetEnable(TUI_Title, false)

        set TUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUIClose", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_CloseButton, 0.030, 0.030)
        call BlzFrameSetText(TUI_CloseButton, "X")
        call BlzFrameSetPoint(TUI_CloseButton, FRAMEPOINT_TOPRIGHT, TUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)

        set TUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUIReturn", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_ReturnButton, 0.065, 0.030)
        call BlzFrameSetText(TUI_ReturnButton, "Return")
        call BlzFrameSetPoint(TUI_ReturnButton, FRAMEPOINT_TOPRIGHT, TUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)

        set TUI_ViewingText = BlzCreateFrameByType("TEXT", "TalentsUIViewing", TUI_Parent, "", 0)
        call BlzFrameSetPoint(TUI_ViewingText, FRAMEPOINT_TOPLEFT, TUI_Title, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
        call BlzFrameSetSize(TUI_ViewingText, 0.360, 0.014)
        call BlzFrameSetTextAlignment(TUI_ViewingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(TUI_ViewingText, false)

        call TUI_CreateTreeButton(1, AbilitiesPlayer_TREE_ELEMENTAL, 0.018)
        call TUI_CreateTreeButton(2, AbilitiesPlayer_TREE_ENHANCEMENT, 0.116)
        call TUI_CreateTreeButton(3, AbilitiesPlayer_TREE_RESTORATION, 0.214)
        call TUI_CreateTreeButton(4, AbilitiesPlayer_TREE_TOTEMIC, 0.312)

        set TUI_TreePane = BlzCreateFrameByType("BACKDROP", "TalentsUITreePane", TUI_Parent, "", 0)
        call BlzFrameSetTexture(TUI_TreePane, TUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(TUI_TreePane, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.088)
        call BlzFrameSetPoint(TUI_TreePane, FRAMEPOINT_BOTTOMRIGHT, TUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.338, 0.050)

        set TUI_DetailPane = BlzCreateFrameByType("BACKDROP", "TalentsUIDetailPane", TUI_Parent, "", 0)
        call BlzFrameSetTexture(TUI_DetailPane, TUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(TUI_DetailPane, FRAMEPOINT_TOPLEFT, TUI_TreePane, FRAMEPOINT_TOPRIGHT, 0.014, 0.0)
        call BlzFrameSetPoint(TUI_DetailPane, FRAMEPOINT_BOTTOMRIGHT, TUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.050)

        loop
            exitwhen row > TUI_GRID_ROWS
            set column = 1
            loop
                exitwhen column > TUI_GRID_COLUMNS
                set slotIndex = TUI_GetSlotIndex(row, column)
                set xOffset = TUI_TALENT_START_X + (TUI_TALENT_SIZE + TUI_TALENT_GAP_X) * I2R(column - 1)
                set yOffset = TUI_TALENT_START_Y - (TUI_TALENT_SIZE + TUI_TALENT_GAP_Y) * I2R(row - 1)

                set TUI_TalentButton[slotIndex] = BlzCreateFrameByType("GLUEBUTTON", "TalentsUITalentButton" + I2S(slotIndex), TUI_TreePane, "ScoreScreenTabButtonTemplate", 0)
                call BlzFrameSetPoint(TUI_TalentButton[slotIndex], FRAMEPOINT_TOPLEFT, TUI_TreePane, FRAMEPOINT_TOPLEFT, xOffset, yOffset)
                call BlzFrameSetSize(TUI_TalentButton[slotIndex], TUI_TALENT_SIZE, TUI_TALENT_SIZE)
                call BlzFrameSetLevel(TUI_TalentButton[slotIndex], 2)
                call BlzFrameSetVisible(TUI_TalentButton[slotIndex], false)
                call BlzTriggerRegisterFrameEvent(TUI_TalentTrigger, TUI_TalentButton[slotIndex], FRAMEEVENT_CONTROL_CLICK)
                call BlzTriggerRegisterFrameEvent(TUI_TalentEnterTrigger, TUI_TalentButton[slotIndex], FRAMEEVENT_MOUSE_ENTER)
                call BlzTriggerRegisterFrameEvent(TUI_TalentLeaveTrigger, TUI_TalentButton[slotIndex], FRAMEEVENT_MOUSE_LEAVE)
                call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_TalentButton[slotIndex], FRAMEEVENT_CONTROL_CLICK)
                set TUI_ButtonTalent.integer[GetHandleId(TUI_TalentButton[slotIndex])] = slotIndex

                set TUI_TalentLinkLeft[slotIndex] = BlzCreateFrameByType("BACKDROP", "TalentsUITalentLinkLeft" + I2S(slotIndex), TUI_TreePane, "", 0)
                set TUI_TalentLinkUp[slotIndex] = BlzCreateFrameByType("BACKDROP", "TalentsUITalentLinkUp" + I2S(slotIndex), TUI_TreePane, "", 0)
                set TUI_TalentLinkRight[slotIndex] = BlzCreateFrameByType("BACKDROP", "TalentsUITalentLinkRight" + I2S(slotIndex), TUI_TreePane, "", 0)
                set TUI_TalentLinkDown[slotIndex] = BlzCreateFrameByType("BACKDROP", "TalentsUITalentLinkDown" + I2S(slotIndex), TUI_TreePane, "", 0)
                call TUI_SetupLinkFrame(TUI_TalentLinkLeft[slotIndex], TUI_TalentButton[slotIndex], TUI_LINK_LEFT)
                call TUI_SetupLinkFrame(TUI_TalentLinkUp[slotIndex], TUI_TalentButton[slotIndex], TUI_LINK_UP)
                call TUI_SetupLinkFrame(TUI_TalentLinkRight[slotIndex], TUI_TalentButton[slotIndex], TUI_LINK_RIGHT)
                call TUI_SetupLinkFrame(TUI_TalentLinkDown[slotIndex], TUI_TalentButton[slotIndex], TUI_LINK_DOWN)

                set TUI_TalentIcon[slotIndex] = BlzCreateFrameByType("BACKDROP", "TalentsUITalentIcon" + I2S(slotIndex), TUI_TalentButton[slotIndex], "IconButtonTemplate", 0)
                call BlzFrameSetAllPoints(TUI_TalentIcon[slotIndex], TUI_TalentButton[slotIndex])

                set TUI_TalentOverlay[slotIndex] = BlzCreateFrameByType("BACKDROP", "TalentsUITalentOverlay" + I2S(slotIndex), TUI_TalentButton[slotIndex], "", 0)
                call BlzFrameSetTexture(TUI_TalentOverlay[slotIndex], TUI_PanelTexture, 0, false)
                call BlzFrameSetAllPoints(TUI_TalentOverlay[slotIndex], TUI_TalentButton[slotIndex])
                call BlzFrameSetAlpha(TUI_TalentOverlay[slotIndex], 128)
                call BlzFrameSetVertexColor(TUI_TalentOverlay[slotIndex], BlzConvertColor(128, 0, 0, 0))
                call BlzFrameSetEnable(TUI_TalentOverlay[slotIndex], false)

                set TUI_TalentRankText[slotIndex] = BlzCreateFrameByType("TEXT", "TalentsUITalentRank" + I2S(slotIndex), TUI_TalentButton[slotIndex], "", 0)
                call BlzFrameSetPoint(TUI_TalentRankText[slotIndex], FRAMEPOINT_BOTTOMRIGHT, TUI_TalentButton[slotIndex], FRAMEPOINT_BOTTOMRIGHT, -0.001, 0.001)
                call BlzFrameSetSize(TUI_TalentRankText[slotIndex], 0.018, 0.010)
                call BlzFrameSetTextAlignment(TUI_TalentRankText[slotIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
                call BlzFrameSetScale(TUI_TalentRankText[slotIndex], 0.74)
                call BlzFrameSetEnable(TUI_TalentRankText[slotIndex], false)

                set TUI_TalentHighlight[slotIndex] = BlzCreateFrameByType("BACKDROP", "TalentsUITalentHighlight" + I2S(slotIndex), TUI_TalentButton[slotIndex], "", 0)
                call BlzFrameSetPoint(TUI_TalentHighlight[slotIndex], FRAMEPOINT_CENTER, TUI_TalentButton[slotIndex], FRAMEPOINT_CENTER, 0.0, 0.0)
                call BlzFrameSetSize(TUI_TalentHighlight[slotIndex], TUI_TALENT_SIZE + 0.006, TUI_TALENT_SIZE + 0.006)
                call BlzFrameSetTexture(TUI_TalentHighlight[slotIndex], TUI_TalentHighlightTexture, 0, true)
                call BlzFrameSetLevel(TUI_TalentHighlight[slotIndex], 4)
                call BlzFrameSetVisible(TUI_TalentHighlight[slotIndex], false)
                call BlzFrameSetEnable(TUI_TalentHighlight[slotIndex], false)

                set TUI_TalentTooltipBox[slotIndex] = BlzCreateFrame("ListBoxWar3", TUI_TalentButton[slotIndex], 0, slotIndex)
                call BlzFrameSetPoint(TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_TOPLEFT, TUI_TalentButton[slotIndex], FRAMEPOINT_TOPRIGHT, 0.008, 0.006)
                call BlzFrameSetSize(TUI_TalentTooltipBox[slotIndex], TUI_TOOLTIP_WIDTH, TUI_TOOLTIP_HEIGHT)
                call BlzFrameSetEnable(TUI_TalentTooltipBox[slotIndex], false)
                call BlzFrameSetVisible(TUI_TalentTooltipBox[slotIndex], false)

                set TUI_TalentTooltipText[slotIndex] = BlzCreateFrameByType("TEXT", "TalentsUITalentTooltipText" + I2S(slotIndex), TUI_TalentTooltipBox[slotIndex], "", 0)
                call BlzFrameSetPoint(TUI_TalentTooltipText[slotIndex], FRAMEPOINT_TOPLEFT, TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_TOPLEFT, 0.010, -0.020)
                call BlzFrameSetPoint(TUI_TalentTooltipText[slotIndex], FRAMEPOINT_BOTTOMRIGHT, TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
                call BlzFrameSetTextAlignment(TUI_TalentTooltipText[slotIndex], TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
                call BlzFrameSetScale(TUI_TalentTooltipText[slotIndex], 0.82)
                call BlzFrameSetEnable(TUI_TalentTooltipText[slotIndex], false)

                set TUI_TalentTooltipRank[slotIndex] = BlzCreateFrameByType("TEXT", "TalentsUITalentTooltipRank" + I2S(slotIndex), TUI_TalentTooltipBox[slotIndex], "", 0)
                call BlzFrameSetPoint(TUI_TalentTooltipRank[slotIndex], FRAMEPOINT_TOPRIGHT, TUI_TalentTooltipBox[slotIndex], FRAMEPOINT_TOPRIGHT, -0.010, -0.006)
                call BlzFrameSetSize(TUI_TalentTooltipRank[slotIndex], 0.120, 0.014)
                call BlzFrameSetTextAlignment(TUI_TalentTooltipRank[slotIndex], TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_RIGHT)
                call BlzFrameSetScale(TUI_TalentTooltipRank[slotIndex], 0.78)
                call BlzFrameSetEnable(TUI_TalentTooltipRank[slotIndex], false)

                set column = column + 1
            endloop
            set row = row + 1
        endloop

        set TUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "TalentsUIDetailIcon", TUI_DetailPane, "IconButtonTemplate", 0)
        call BlzFrameSetPoint(TUI_DetailIcon, FRAMEPOINT_TOPLEFT, TUI_DetailPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(TUI_DetailIcon, 0.044, 0.044)

        set TUI_DetailTitle = BlzCreateFrameByType("TEXT", "TalentsUIDetailTitle", TUI_DetailPane, "", 0)
        call BlzFrameSetPoint(TUI_DetailTitle, FRAMEPOINT_TOPLEFT, TUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
        call BlzFrameSetSize(TUI_DetailTitle, 0.190, 0.018)
        call BlzFrameSetTextAlignment(TUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_DetailTitle, 1.05)
        call BlzFrameSetEnable(TUI_DetailTitle, false)

        set TUI_DetailInfo = BlzCreateFrameByType("TEXT", "TalentsUIDetailInfo", TUI_DetailPane, "", 0)
        call BlzFrameSetPoint(TUI_DetailInfo, FRAMEPOINT_TOPLEFT, TUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
        call BlzFrameSetSize(TUI_DetailInfo, 0.190, 0.034)
        call BlzFrameSetTextAlignment(TUI_DetailInfo, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_DetailInfo, 0.86)
        call BlzFrameSetEnable(TUI_DetailInfo, false)

        set TUI_DetailBody = BlzCreateFrameByType("TEXT", "TalentsUIDetailBody", TUI_DetailPane, "", 0)
        call BlzFrameSetPoint(TUI_DetailBody, FRAMEPOINT_TOPLEFT, TUI_DetailPane, FRAMEPOINT_TOPLEFT, 0.018, -0.098)
        call BlzFrameSetPoint(TUI_DetailBody, FRAMEPOINT_BOTTOMRIGHT, TUI_DetailPane, FRAMEPOINT_BOTTOMRIGHT, -0.018, 0.060)
        call BlzFrameSetTextAlignment(TUI_DetailBody, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_DetailBody, 0.90)
        call BlzFrameSetEnable(TUI_DetailBody, false)

        set TUI_DetailFooter = BlzCreateFrameByType("TEXT", "TalentsUIDetailFooter", TUI_DetailPane, "", 0)
        call BlzFrameSetPoint(TUI_DetailFooter, FRAMEPOINT_BOTTOMLEFT, TUI_DetailPane, FRAMEPOINT_BOTTOMLEFT, 0.018, 0.010)
        call BlzFrameSetSize(TUI_DetailFooter, 0.240, 0.040)
        call BlzFrameSetTextAlignment(TUI_DetailFooter, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_DetailFooter, 0.82)
        call BlzFrameSetEnable(TUI_DetailFooter, false)

        set TUI_ResetButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUIReset", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_ResetButton, 0.105, 0.030)
        call BlzFrameSetText(TUI_ResetButton, "Reset Talents")
        call BlzFrameSetPoint(TUI_ResetButton, FRAMEPOINT_BOTTOMLEFT, TUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.020, 0.018)

        set TUI_CancelButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUICancel", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_CancelButton, 0.074, 0.030)
        call BlzFrameSetText(TUI_CancelButton, "Cancel")
        call BlzFrameSetPoint(TUI_CancelButton, FRAMEPOINT_LEFT, TUI_ResetButton, FRAMEPOINT_RIGHT, 0.010, 0.0)

        set TUI_ConfirmButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUIConfirm", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_ConfirmButton, 0.092, 0.030)
        call BlzFrameSetText(TUI_ConfirmButton, "Confirm")
        call BlzFrameSetPoint(TUI_ConfirmButton, FRAMEPOINT_LEFT, TUI_CancelButton, FRAMEPOINT_RIGHT, 0.008, 0.0)

        set TUI_LearnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUILearn", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_LearnButton, 0.088, 0.030)
        call BlzFrameSetText(TUI_LearnButton, "Add Rank")
        call BlzFrameSetPoint(TUI_LearnButton, FRAMEPOINT_BOTTOMRIGHT, TUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.024, 0.018)

        set TUI_RemoveButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TalentsUIRemove", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_RemoveButton, 0.078, 0.030)
        call BlzFrameSetText(TUI_RemoveButton, "Remove")
        call BlzFrameSetPoint(TUI_RemoveButton, FRAMEPOINT_RIGHT, TUI_LearnButton, FRAMEPOINT_LEFT, -0.008, 0.0)

        call BlzTriggerRegisterFrameEvent(TUI_CloseTrigger, TUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ReturnTrigger, TUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_LearnTrigger, TUI_LearnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_LearnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_RemoveTrigger, TUI_RemoveButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_RemoveButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ConfirmTrigger, TUI_ConfirmButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_ConfirmButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_CancelTrigger, TUI_CancelButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_CancelButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ResetTrigger, TUI_ResetButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_ResetButton, FRAMEEVENT_CONTROL_CLICK)

        call BlzFrameSetVisible(TUI_Parent, false)
    endfunction

    public function Init takes nothing returns nothing
        if TUI_Initialized then
            return
        endif
        set TUI_Initialized = true

        set TUI_ButtonTree = Table.create()
        set TUI_ButtonTalent = Table.create()
        set TUI_TrainerScanGroup = CreateGroup()

        set TUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(TUI_CloseTrigger, function TUI_CloseAction)

        set TUI_ReturnTrigger = CreateTrigger()
        call TriggerAddAction(TUI_ReturnTrigger, function TUI_ReturnAction)

        set TUI_TreeTrigger = CreateTrigger()
        call TriggerAddAction(TUI_TreeTrigger, function TUI_TreeAction)

        set TUI_TalentTrigger = CreateTrigger()
        call TriggerAddAction(TUI_TalentTrigger, function TUI_TalentAction)

        set TUI_TalentEnterTrigger = CreateTrigger()
        call TriggerAddAction(TUI_TalentEnterTrigger, function TUI_TalentEnterAction)

        set TUI_TalentLeaveTrigger = CreateTrigger()
        call TriggerAddAction(TUI_TalentLeaveTrigger, function TUI_TalentLeaveAction)

        set TUI_LearnTrigger = CreateTrigger()
        call TriggerAddAction(TUI_LearnTrigger, function TUI_LearnAction)

        set TUI_RemoveTrigger = CreateTrigger()
        call TriggerAddAction(TUI_RemoveTrigger, function TUI_RemoveAction)

        set TUI_ConfirmTrigger = CreateTrigger()
        call TriggerAddAction(TUI_ConfirmTrigger, function TUI_ConfirmAction)

        set TUI_CancelTrigger = CreateTrigger()
        call TriggerAddAction(TUI_CancelTrigger, function TUI_CancelAction)

        set TUI_ResetTrigger = CreateTrigger()
        call TriggerAddAction(TUI_ResetTrigger, function TUI_ResetAction)

        set TUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(TUI_ClearFocusTrigger, function TUI_ClearFocusAction)

        call TUI_CreateFrames()
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
