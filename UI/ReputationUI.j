library ReputationUI initializer AutoInit requires Table, Reputation, MasterUI
/**
    ReputationUI
    
    Author: [Valdemar]
    Version: 1.0

    Description: Displays the player's standing with visible factions and a short summary of each one.

    Credits: Tasyen (TasQuestBox as inspiration)

**/

globals
    private constant real RUI_REFRESH_INTERVAL = 5.00
    private constant integer RUI_MAX_ROWS = 10
    private constant integer RUI_VISIBLE_ROWS = 6

    private boolean RUI_Initialized = false
    private boolean RUI_IsVisible = false
    private boolean RUI_SyncingListScroll = false
    private integer RUI_SelectedFactionId = 0

    private framehandle RUI_Parent = null
    private framehandle RUI_Title = null
    private framehandle RUI_LeftPane = null
    private framehandle RUI_RightPane = null
    private framehandle RUI_ListWheelArea = null
    private framehandle RUI_CloseButton = null
    private framehandle RUI_ReturnButton = null
    private framehandle RUI_ListScroll = null
    private framehandle RUI_DetailBackdrop = null
    private framehandle RUI_DetailBodyBackdrop = null
    private framehandle RUI_DetailIcon = null
    private framehandle RUI_DetailTitle = null
    private framehandle RUI_DetailValue = null
    private framehandle RUI_DetailDescription = null

    private framehandle array RUI_RowButton
    private framehandle array RUI_RowIcon
    private framehandle array RUI_RowText
    private framehandle array RUI_RowLevel
    private framehandle array RUI_RowHighlight
    private integer array RUI_RowFactionId
    private integer array RUI_ListScrollValue
    private integer array RUI_RowVisibleState
    private integer array RUI_RowHighlightState
    private string array RUI_RowIconCache
    private string array RUI_RowTextCache
    private string array RUI_RowLevelCache
    private integer RUI_ListScrollMaxCache = -1
    private integer RUI_ListScrollValueCache = -1
    private string RUI_DetailIconCache = ""
    private string RUI_DetailTitleCache = ""
    private string RUI_DetailValueCache = ""
    private string RUI_DetailDescriptionCache = ""

    private Table RUI_ButtonRow = 0

    private trigger RUI_CloseTrigger = null
    private trigger RUI_ReturnTrigger = null
    private trigger RUI_RowTrigger = null
    private trigger RUI_ListScrollTrigger = null
    private trigger RUI_ClearFocusTrigger = null
    private trigger RUI_WheelTrigger = null
    private timer RUI_RefreshTimer = null

    private string RUI_DefaultFactionIcon = "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    private string RUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private string RUI_RowHighlightModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
endglobals

private function RUI_IsFactionVisible takes Faction f returns boolean
    return f != 0 and f.isVisible
endfunction

private function RUI_GetFactionIcon takes Faction f returns string
    if f == 0 or f.iconPath == null or f.iconPath == "" then
        return RUI_DefaultFactionIcon
    endif
    return f.iconPath
endfunction

private function RUI_GetFactionDescription takes string factionName returns string
    if factionName == "Horde" then
        return "The main orcish power in the region. Your political standing here shapes access to allied camps and support."
    elseif factionName == "Satyr" then
        return "Corrupted forest raiders and demonic opportunists. They are dangerous, unstable, and rarely forgiving."
    elseif factionName == "Riverbane" then
        return "A hardened human frontier faction controlling key roads and settlements near the eastern reaches."
    elseif factionName == "Alliance" then
        return "The broader human alliance presence. Their opinion determines how safely you can move through their holdings."
    elseif factionName == "Goblins" then
        return "Mercantile opportunists who value profit over loyalty. Reputation here affects trade and tolerance."
    elseif factionName == "Elarindor" then
        return "An elven power with its own guarded agenda. They respond strongly to threats against their territory."
    elseif factionName == "Bonecrusher Clan" then
        return "A brutal clan whose respect is earned through strength, survival, and decisive action."
    elseif factionName == "The True Horde" then
        return "A separate Horde-aligned force with stricter loyalties and a more militant political stance."
    elseif factionName == "Human Citizen" then
        return "Local civilians and town communities. Their reaction reflects everyday order, safety, and trust."
    endif
    return "A regional faction whose standing changes according to your actions, quests, and combat choices."
endfunction

private function RUI_GetFactionCount takes nothing returns integer
    local integer i = 1
    local integer count = 0

    loop
        exitwhen i >= Faction.total
        if RUI_IsFactionVisible(Faction.all[i]) then
            set count = count + 1
        endif
        set i = i + 1
    endloop

    return count
endfunction

private function RUI_GetFirstFactionId takes nothing returns integer
    local integer i = 1

    loop
        exitwhen i >= Faction.total
        if RUI_IsFactionVisible(Faction.all[i]) then
            return Faction.all[i].id
        endif
        set i = i + 1
    endloop

    return 0
endfunction

private function RUI_GetSelectedFaction takes player whichPlayer returns Faction
    local integer factionId = RUI_SelectedFactionId

    if factionId > 0 and RUI_IsFactionVisible(Faction.all[factionId]) then
        return Faction.all[factionId]
    endif

    set factionId = RUI_GetFirstFactionId()
    set RUI_SelectedFactionId = factionId
    if factionId > 0 then
        return Faction.all[factionId]
    endif
    return 0
endfunction

private function RUI_SetRowVisible takes integer rowIndex, boolean visible returns nothing
    local integer visibleState = 0

    if visible then
        set visibleState = 1
    endif
    if RUI_RowVisibleState[rowIndex] != visibleState then
        set RUI_RowVisibleState[rowIndex] = visibleState
        call BlzFrameSetVisible(RUI_RowButton[rowIndex], visible)
    endif
endfunction

private function RUI_SetRowHighlight takes integer rowIndex, boolean visible returns nothing
    local integer visibleState = 0

    if visible then
        set visibleState = 1
    endif
    if RUI_RowHighlightState[rowIndex] != visibleState then
        set RUI_RowHighlightState[rowIndex] = visibleState
        call BlzFrameSetVisible(RUI_RowHighlight[rowIndex], visible)
    endif
endfunction

private function RUI_UpdateRows takes player whichPlayer returns nothing
    local integer i = 1
    local integer rowIndex = 1
    local integer skipped = 0
    local integer maxStart = RUI_GetFactionCount() - RUI_VISIBLE_ROWS
    local Faction f
    local string iconPath
    local string rowText
    local string rowLevel

    if maxStart < 0 then
        set maxStart = 0
    endif
    if RUI_ListScrollValue[GetPlayerId(whichPlayer)] < 0 then
        set RUI_ListScrollValue[GetPlayerId(whichPlayer)] = 0
    elseif RUI_ListScrollValue[GetPlayerId(whichPlayer)] > maxStart then
        set RUI_ListScrollValue[GetPlayerId(whichPlayer)] = maxStart
    endif

    loop
        exitwhen i >= Faction.total
        set f = Faction.all[i]
        if RUI_IsFactionVisible(f) then
            if skipped < RUI_ListScrollValue[GetPlayerId(whichPlayer)] then
                set skipped = skipped + 1
            elseif rowIndex <= RUI_VISIBLE_ROWS then
                set RUI_RowFactionId[rowIndex] = f.id
                if GetLocalPlayer() == whichPlayer then
                    set iconPath = RUI_GetFactionIcon(f)
                    set rowText = "|cff80a0ff" + f.name + "|r"
                    set rowLevel = Reputation.getStatus(Player(0), f)
                    if RUI_RowIconCache[rowIndex] != iconPath then
                        set RUI_RowIconCache[rowIndex] = iconPath
                        call BlzFrameSetTexture(RUI_RowIcon[rowIndex], iconPath, 0, true)
                    endif
                    if RUI_RowTextCache[rowIndex] != rowText then
                        set RUI_RowTextCache[rowIndex] = rowText
                        call BlzFrameSetText(RUI_RowText[rowIndex], rowText)
                    endif
                    if RUI_RowLevelCache[rowIndex] != rowLevel then
                        set RUI_RowLevelCache[rowIndex] = rowLevel
                        call BlzFrameSetText(RUI_RowLevel[rowIndex], rowLevel)
                    endif
                    call RUI_SetRowHighlight(rowIndex, f.id == RUI_SelectedFactionId)
                    call RUI_SetRowVisible(rowIndex, true)
                endif
                set rowIndex = rowIndex + 1
            endif
        endif
        set i = i + 1
    endloop

    loop
        exitwhen rowIndex > RUI_MAX_ROWS
        set RUI_RowFactionId[rowIndex] = 0
        if GetLocalPlayer() == whichPlayer then
            set RUI_RowIconCache[rowIndex] = ""
            set RUI_RowTextCache[rowIndex] = ""
            set RUI_RowLevelCache[rowIndex] = ""
            call RUI_SetRowVisible(rowIndex, false)
            call RUI_SetRowHighlight(rowIndex, false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    if GetLocalPlayer() == whichPlayer then
        set RUI_SyncingListScroll = true
        if RUI_ListScrollMaxCache != maxStart then
            set RUI_ListScrollMaxCache = maxStart
            call BlzFrameSetMinMaxValue(RUI_ListScroll, 0.0, I2R(maxStart))
        endif
        if RUI_ListScrollValueCache != maxStart - RUI_ListScrollValue[GetPlayerId(whichPlayer)] then
            set RUI_ListScrollValueCache = maxStart - RUI_ListScrollValue[GetPlayerId(whichPlayer)]
            call BlzFrameSetValue(RUI_ListScroll, I2R(RUI_ListScrollValueCache))
        endif
        set RUI_SyncingListScroll = false
        call BlzFrameSetVisible(RUI_ListScroll, maxStart > 0)
    endif
endfunction

private function RUI_UpdateDetail takes player whichPlayer returns nothing
    local Faction f = RUI_GetSelectedFaction(whichPlayer)
    local integer rep
    local string detailText
    local string iconPath
    local string titleText
    local string valueText

    if f == 0 then
        if GetLocalPlayer() == whichPlayer then
            if RUI_DetailIconCache != RUI_DefaultFactionIcon then
                set RUI_DetailIconCache = RUI_DefaultFactionIcon
                call BlzFrameSetTexture(RUI_DetailIcon, RUI_DefaultFactionIcon, 0, true)
            endif
            if RUI_DetailTitleCache != "No faction" then
                set RUI_DetailTitleCache = "No faction"
                call BlzFrameSetText(RUI_DetailTitle, "No faction")
            endif
            if RUI_DetailValueCache != "" then
                set RUI_DetailValueCache = ""
                call BlzFrameSetText(RUI_DetailValue, "")
            endif
            if RUI_DetailDescriptionCache != "No visible factions configured." then
                set RUI_DetailDescriptionCache = "No visible factions configured."
                call BlzFrameSetText(RUI_DetailDescription, "No visible factions configured.")
            endif
        endif
        return
    endif

    set rep = Reputation.getRep(Player(0), f)
    set iconPath = RUI_GetFactionIcon(f)
    set titleText = "|cff80a0ff" + f.name + "|r"
    set valueText = Reputation.getStatus(Player(0), f)
    set detailText = RUI_GetFactionDescription(f.name) + "|n|nCurrent status: " + valueText + "|nReputation value: |cffffffff" + I2S(rep) + "|r"
    if GetLocalPlayer() == whichPlayer then
        if RUI_DetailIconCache != iconPath then
            set RUI_DetailIconCache = iconPath
            call BlzFrameSetTexture(RUI_DetailIcon, iconPath, 0, true)
        endif
        if RUI_DetailTitleCache != titleText then
            set RUI_DetailTitleCache = titleText
            call BlzFrameSetText(RUI_DetailTitle, titleText)
        endif
        if RUI_DetailValueCache != valueText then
            set RUI_DetailValueCache = valueText
            call BlzFrameSetText(RUI_DetailValue, valueText)
        endif
        if RUI_DetailDescriptionCache != detailText then
            set RUI_DetailDescriptionCache = detailText
            call BlzFrameSetText(RUI_DetailDescription, detailText)
        endif
    endif
endfunction

private function RUI_RefreshVisibleData takes player whichPlayer returns nothing
    local integer rowIndex = 1
    local integer factionId
    local Faction f
    local string rowLevel

    if RUI_Parent == null or not BlzFrameIsVisible(RUI_Parent) then
        return
    endif

    if GetLocalPlayer() == whichPlayer then
        loop
            exitwhen rowIndex > RUI_VISIBLE_ROWS
            set factionId = RUI_RowFactionId[rowIndex]
            if factionId > 0 then
                set f = Faction.all[factionId]
                if f != 0 then
                    set rowLevel = Reputation.getStatus(Player(0), f)
                    if RUI_RowLevelCache[rowIndex] != rowLevel then
                        set RUI_RowLevelCache[rowIndex] = rowLevel
                        call BlzFrameSetText(RUI_RowLevel[rowIndex], rowLevel)
                    endif
                endif
            endif
            set rowIndex = rowIndex + 1
        endloop
    endif

    call RUI_UpdateDetail(whichPlayer)
endfunction

private function RUI_Update takes player whichPlayer returns nothing
    if RUI_Parent == null then
        return
    endif

    if RUI_SelectedFactionId <= 0 and RUI_GetFactionCount() > 0 then
        set RUI_SelectedFactionId = RUI_GetFirstFactionId()
    endif

    call RUI_UpdateRows(whichPlayer)
    call RUI_UpdateDetail(whichPlayer)
endfunction

private function RUI_PeriodicRefresh takes nothing returns nothing
    if RUI_Parent != null and BlzFrameIsVisible(RUI_Parent) then
        call RUI_RefreshVisibleData(GetLocalPlayer())
    endif
endfunction

private function RUI_SetRefreshActive takes boolean active returns nothing
    if RUI_RefreshTimer == null then
        return
    endif
    if active then
        call TimerStart(RUI_RefreshTimer, RUI_REFRESH_INTERVAL, true, function RUI_PeriodicRefresh)
    else
        call PauseTimer(RUI_RefreshTimer)
    endif
endfunction

private function RUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

public function Hide takes nothing returns nothing
    call RUI_SetRefreshActive(false)
    if RUI_Parent != null then
        call BlzFrameSetVisible(RUI_Parent, false)
    endif
endfunction

private function RUI_CloseAction takes nothing returns nothing
    call Hide()
endfunction

private function RUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function RUI_RowAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer handleId = GetHandleId(BlzGetTriggerFrame())
    local integer rowIndex

    if RUI_ButtonRow.has(handleId) then
        set rowIndex = RUI_ButtonRow.integer[handleId]
        if RUI_RowFactionId[rowIndex] > 0 then
            set RUI_SelectedFactionId = RUI_RowFactionId[rowIndex]
            call RUI_Update(p)
        endif
    endif

    set p = null
endfunction

private function RUI_ListScrollAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer maxStart = RUI_GetFactionCount() - RUI_VISIBLE_ROWS
    if RUI_SyncingListScroll then
        set p = null
        return
    endif
    if maxStart < 0 then
        set maxStart = 0
    endif
    set RUI_ListScrollValueCache = R2I(BlzGetTriggerFrameValue() + 0.5)
    set RUI_ListScrollValue[GetPlayerId(p)] = maxStart - RUI_ListScrollValueCache
    call RUI_Update(p)
    set p = null
endfunction

private function RUI_WheelAction takes nothing returns nothing
    local real newValue

    if GetLocalPlayer() == GetTriggerPlayer() and RUI_ListScroll != null and BlzFrameIsVisible(RUI_ListScroll) then
        if BlzGetTriggerFrameValue() > 0 then
            set newValue = BlzFrameGetValue(RUI_ListScroll) + 1.0
        else
            set newValue = BlzFrameGetValue(RUI_ListScroll) - 1.0
        endif
        if newValue < 0.0 then
            set newValue = 0.0
        elseif newValue > I2R(RUI_ListScrollMaxCache) then
            set newValue = I2R(RUI_ListScrollMaxCache)
        endif
        call BlzFrameSetValue(RUI_ListScroll, newValue)
    endif
endfunction

private function RUI_CreateFrames takes nothing returns nothing
    local integer rowIndex = 1
    local real rowTopOffset = -0.012
    local real rowHeight = 0.033
    local real rowGap = 0.003

    set RUI_Parent = BlzCreateFrameByType("BACKDROP", "ReputationUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(RUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
    call BlzFrameSetAbsPoint(RUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.18)

    set RUI_Title = BlzCreateFrameByType("TEXT", "ReputationUITitle", RUI_Parent, "", 0)
    call BlzFrameSetPoint(RUI_Title, FRAMEPOINT_TOPLEFT, RUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(RUI_Title, 0.30, 0.018)
    call BlzFrameSetTextAlignment(RUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(RUI_Title, 1.10)
    call BlzFrameSetEnable(RUI_Title, false)
    call BlzFrameSetText(RUI_Title, "|cffffe4a3Reputations|r")

    set RUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ReputationUIClose", RUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(RUI_CloseButton, 0.03, 0.03)
    call BlzFrameSetText(RUI_CloseButton, "X")
    call BlzFrameSetPoint(RUI_CloseButton, FRAMEPOINT_TOPRIGHT, RUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
    call BlzTriggerRegisterFrameEvent(RUI_CloseTrigger, RUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(RUI_ClearFocusTrigger, RUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

    set RUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ReputationUIReturn", RUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(RUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(RUI_ReturnButton, "Return")
    call BlzFrameSetPoint(RUI_ReturnButton, FRAMEPOINT_TOPRIGHT, RUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(RUI_ReturnTrigger, RUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(RUI_ClearFocusTrigger, RUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    set RUI_LeftPane = BlzCreateFrameByType("BACKDROP", "ReputationUILeftPane", RUI_Parent, "", 0)
    call BlzFrameSetTexture(RUI_LeftPane, RUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(RUI_LeftPane, FRAMEPOINT_TOPLEFT, RUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.078)
    call BlzFrameSetPoint(RUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, RUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

    set RUI_ListScroll = BlzCreateFrameByType("SLIDER", "ReputationUIListScroll", RUI_LeftPane, "QuestMainListScrollBar", 0)
    call BlzFrameSetPoint(RUI_ListScroll, FRAMEPOINT_TOPLEFT, RUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
    call BlzFrameSetSize(RUI_ListScroll, BlzFrameGetWidth(RUI_ListScroll), BlzFrameGetHeight(RUI_LeftPane) - 0.004)
    call BlzFrameSetMinMaxValue(RUI_ListScroll, 0.0, 0.0)
    call BlzFrameSetStepSize(RUI_ListScroll, 1.0)
    call BlzFrameSetValue(RUI_ListScroll, 0.0)
    call BlzFrameSetVisible(RUI_ListScroll, false)
    call BlzTriggerRegisterFrameEvent(RUI_ListScrollTrigger, RUI_ListScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(RUI_WheelTrigger, RUI_ListScroll, FRAMEEVENT_MOUSE_WHEEL)
    call BlzTriggerRegisterFrameEvent(RUI_WheelTrigger, RUI_LeftPane, FRAMEEVENT_MOUSE_WHEEL)

    set RUI_ListWheelArea = BlzCreateFrameByType("SLIDER", "ReputationUIWheelArea", RUI_Parent, "", 0)
    call BlzFrameSetPoint(RUI_ListWheelArea, FRAMEPOINT_TOPRIGHT, RUI_ListScroll, FRAMEPOINT_TOPLEFT, -0.006, 0.000)
    call BlzFrameSetPoint(RUI_ListWheelArea, FRAMEPOINT_BOTTOMLEFT, RUI_LeftPane, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)
    call BlzFrameSetEnable(RUI_ListWheelArea, false)
    call BlzFrameSetVisible(RUI_ListWheelArea, false)

    set RUI_RightPane = BlzCreateFrameByType("BACKDROP", "ReputationUIRightPane", RUI_Parent, "", 0)
    call BlzFrameSetTexture(RUI_RightPane, RUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(RUI_RightPane, FRAMEPOINT_TOPLEFT, RUI_ListScroll, FRAMEPOINT_TOPRIGHT, 0.010, 0.0)
    call BlzFrameSetPoint(RUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, RUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

    set RUI_DetailBackdrop = BlzCreateFrameByType("BACKDROP", "ReputationUIDetailBackdrop", RUI_RightPane, "", 0)
    call BlzFrameSetTexture(RUI_DetailBackdrop, RUI_PanelTexture, 0, false)
    call BlzFrameSetPoint(RUI_DetailBackdrop, FRAMEPOINT_TOPLEFT, RUI_RightPane, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
    call BlzFrameSetPoint(RUI_DetailBackdrop, FRAMEPOINT_BOTTOMRIGHT, RUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
    call BlzFrameSetAlpha(RUI_DetailBackdrop, 255)
    call BlzFrameSetVertexColor(RUI_DetailBackdrop, BlzConvertColor(255, 0, 0, 0))
    call BlzFrameSetEnable(RUI_DetailBackdrop, false)

    set RUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "ReputationUIDetailIcon", RUI_DetailBackdrop, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(RUI_DetailIcon, FRAMEPOINT_TOPLEFT, RUI_DetailBackdrop, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(RUI_DetailIcon, 0.042, 0.042)

    set RUI_DetailTitle = BlzCreateFrameByType("TEXT", "ReputationUIDetailTitle", RUI_DetailBackdrop, "", 0)
    call BlzFrameSetPoint(RUI_DetailTitle, FRAMEPOINT_TOPLEFT, RUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
    call BlzFrameSetSize(RUI_DetailTitle, 0.260, 0.018)
    call BlzFrameSetTextAlignment(RUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(RUI_DetailTitle, 1.05)
    call BlzFrameSetEnable(RUI_DetailTitle, false)

    set RUI_DetailValue = BlzCreateFrameByType("TEXT", "ReputationUIDetailValue", RUI_DetailBackdrop, "", 0)
    call BlzFrameSetPoint(RUI_DetailValue, FRAMEPOINT_TOPLEFT, RUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.004)
    call BlzFrameSetSize(RUI_DetailValue, 0.260, 0.018)
    call BlzFrameSetTextAlignment(RUI_DetailValue, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(RUI_DetailValue, 0.98)
    call BlzFrameSetEnable(RUI_DetailValue, false)

    set RUI_DetailBodyBackdrop = BlzCreateFrameByType("BACKDROP", "ReputationUIDetailBodyBackdrop", RUI_DetailBackdrop, "", 0)
    call BlzFrameSetTexture(RUI_DetailBodyBackdrop, RUI_PanelTexture, 0, false)
    call BlzFrameSetPoint(RUI_DetailBodyBackdrop, FRAMEPOINT_TOPLEFT, RUI_DetailIcon, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.020)
    call BlzFrameSetPoint(RUI_DetailBodyBackdrop, FRAMEPOINT_BOTTOMRIGHT, RUI_DetailBackdrop, FRAMEPOINT_BOTTOMRIGHT, -0.004, 0.004)
    call BlzFrameSetAlpha(RUI_DetailBodyBackdrop, 235)
    call BlzFrameSetVertexColor(RUI_DetailBodyBackdrop, BlzConvertColor(235, 12, 12, 12))
    call BlzFrameSetEnable(RUI_DetailBodyBackdrop, false)

    set RUI_DetailDescription = BlzCreateFrameByType("TEXT", "ReputationUIDetailDescription", RUI_DetailBodyBackdrop, "", 0)
    call BlzFrameSetPoint(RUI_DetailDescription, FRAMEPOINT_TOPLEFT, RUI_DetailBodyBackdrop, FRAMEPOINT_TOPLEFT, 0.008, -0.008)
    call BlzFrameSetPoint(RUI_DetailDescription, FRAMEPOINT_BOTTOMRIGHT, RUI_DetailBodyBackdrop, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.008)
    call BlzFrameSetTextAlignment(RUI_DetailDescription, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(RUI_DetailDescription, 0.95)
    call BlzFrameSetEnable(RUI_DetailDescription, false)

    loop
        exitwhen rowIndex > RUI_MAX_ROWS
        set RUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "ReputationUIRowButton" + I2S(rowIndex), RUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetPoint(RUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, RUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
        call BlzFrameSetSize(RUI_RowButton[rowIndex], 0.156, rowHeight)
        call BlzTriggerRegisterFrameEvent(RUI_RowTrigger, RUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(RUI_ClearFocusTrigger, RUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(RUI_WheelTrigger, RUI_RowButton[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set RUI_ButtonRow.integer[GetHandleId(RUI_RowButton[rowIndex])] = rowIndex
        set RUI_RowVisibleState[rowIndex] = -1
        call BlzFrameSetVisible(RUI_RowButton[rowIndex], false)

        set RUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "ReputationUIRowIcon" + I2S(rowIndex), RUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(RUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, RUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
        call BlzFrameSetSize(RUI_RowIcon[rowIndex], 0.02, 0.02)

        set RUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "ReputationUIRowText" + I2S(rowIndex), RUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(RUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, RUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
        call BlzFrameSetPoint(RUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, RUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.05, 0.004)
        call BlzFrameSetTextAlignment(RUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(RUI_RowText[rowIndex], false)

        set RUI_RowLevel[rowIndex] = BlzCreateFrameByType("TEXT", "ReputationUIRowLevel" + I2S(rowIndex), RUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(RUI_RowLevel[rowIndex], FRAMEPOINT_TOPRIGHT, RUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.004)
        call BlzFrameSetPoint(RUI_RowLevel[rowIndex], FRAMEPOINT_BOTTOMRIGHT, RUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.004)
        call BlzFrameSetTextAlignment(RUI_RowLevel[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetEnable(RUI_RowLevel[rowIndex], false)

        set RUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "ReputationUIRowHighlight" + I2S(rowIndex), RUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetAllPoints(RUI_RowHighlight[rowIndex], RUI_RowButton[rowIndex])
        call BlzFrameSetModel(RUI_RowHighlight[rowIndex], RUI_RowHighlightModel, 0)
        call BlzFrameSetScale(RUI_RowHighlight[rowIndex], 0.76)
        set RUI_RowHighlightState[rowIndex] = -1
        call BlzFrameSetVisible(RUI_RowHighlight[rowIndex], false)
        call BlzFrameSetEnable(RUI_RowHighlight[rowIndex], false)

        set rowTopOffset = rowTopOffset - rowHeight - rowGap
        set rowIndex = rowIndex + 1
    endloop

    call BlzFrameClearAllPoints(RUI_ListScroll)
    call BlzFrameSetPoint(RUI_ListScroll, FRAMEPOINT_TOPLEFT, RUI_RowButton[1], FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
    call BlzFrameSetSize(RUI_ListScroll, BlzFrameGetWidth(RUI_ListScroll), (rowHeight * I2R(RUI_VISIBLE_ROWS)) + (rowGap * I2R(RUI_VISIBLE_ROWS - 1)) + 0.004)

    call BlzFrameClearAllPoints(RUI_ListWheelArea)
    call BlzFrameSetPoint(RUI_ListWheelArea, FRAMEPOINT_TOPRIGHT, RUI_ListScroll, FRAMEPOINT_TOPLEFT, -0.006, 0.000)
    call BlzFrameSetPoint(RUI_ListWheelArea, FRAMEPOINT_BOTTOMLEFT, RUI_RowButton[RUI_VISIBLE_ROWS], FRAMEPOINT_BOTTOMLEFT, 0.006, 0.002)

    call BlzFrameSetVisible(RUI_Parent, false)
endfunction

public function Show takes nothing returns nothing
    local player p = GetLocalPlayer()
    call BlzFrameSetVisible(RUI_ListScroll, false)
    call BlzFrameSetVisible(RUI_Parent, true)
    set RUI_ListScrollValue[GetPlayerId(p)] = 0
    set RUI_ListScrollValueCache = -1
    call RUI_Update(p)
    call RUI_SetRefreshActive(true)
    set p = null
endfunction

public function Refresh takes nothing returns nothing
    local player p = GetLocalPlayer()
    if RUI_Parent == null or not BlzFrameIsVisible(RUI_Parent) then
        set p = null
        return
    endif
    set RUI_ListScrollValueCache = -1
    call RUI_Update(p)
    set p = null
endfunction

public function Toggle takes nothing returns nothing
    if RUI_Parent != null and BlzFrameIsVisible(RUI_Parent) then
        call Hide()
    else
        call Show()
    endif
endfunction

public function IsVisible takes nothing returns boolean
    return RUI_Parent != null and BlzFrameIsVisible(RUI_Parent)
endfunction

public function Init takes nothing returns nothing
    if RUI_Initialized then
        return
    endif
    set RUI_Initialized = true

    set RUI_ButtonRow = Table.create()

    set RUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(RUI_CloseTrigger, function RUI_CloseAction)

    set RUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(RUI_ReturnTrigger, function RUI_ReturnAction)

    set RUI_RowTrigger = CreateTrigger()
    call TriggerAddAction(RUI_RowTrigger, function RUI_RowAction)

    set RUI_ListScrollTrigger = CreateTrigger()
    call TriggerAddAction(RUI_ListScrollTrigger, function RUI_ListScrollAction)

    set RUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(RUI_ClearFocusTrigger, function RUI_ClearFocusAction)

    set RUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(RUI_WheelTrigger, function RUI_WheelAction)

    call RUI_CreateFrames()

    set RUI_RefreshTimer = CreateTimer()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
