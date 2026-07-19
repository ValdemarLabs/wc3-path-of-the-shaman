/**
    CraftingUI

    Author: Valdemar
    Version: 1.0

    Description: Shared custom-frame crafting panel for profession workstations. Recipe data is fetched from Professions and its profession sublibraries.

    Credits: Tasyen (TasQuestBox as inspiration)

    How to install:
    Import this library after Professions, MasterUI, and Interface. Profession sublibraries register workstation unit types; selecting a registered workstation opens this panel for the last selected tracked hero.

    API:
    call CraftingUI_OpenForStation(whichStation, whichCrafter)
    call CraftingUI_Hide()
    call CraftingUI_Refresh()

**/

library CraftingUI initializer AutoInit requires Professions, GatherNodeSkills, Table, MasterUI, Interface

globals
    private constant integer CUI_VISIBLE_ROWS = 8
    private constant real CUI_ROW_HEIGHT = 0.030
    private constant real CUI_ROW_GAP = 0.004

    private boolean CUI_Initialized = false

    public string TitleText = "|cffffe4a3Crafting|r"
    public string CloseButtonText = "X"
    public string NoStationText = "No workstation"
    public string NoCrafterText = "No tracked crafter"
    public string NoRecipesText = "No recipes configured for this workstation."
    public string PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"

    private framehandle CUI_Parent = null
    private framehandle CUI_Title = null
    private framehandle CUI_ViewingText = null
    private framehandle CUI_StationText = null
    private framehandle CUI_CloseButton = null
    private framehandle CUI_ReturnButton = null
    private framehandle CUI_LeftPane = null
    private framehandle CUI_RightPane = null
    private framehandle CUI_PrevButton = null
    private framehandle CUI_NextButton = null
    private framehandle CUI_CraftButton = null
    private framehandle CUI_DetailIcon = null
    private framehandle CUI_DetailTitle = null
    private framehandle CUI_DetailInfo = null
    private framehandle CUI_DetailBody = null

    private framehandle array CUI_RowButton
    private framehandle array CUI_RowIcon
    private framehandle array CUI_RowText
    private framehandle array CUI_RowState
    private framehandle array CUI_RowHighlight

    private unit array CUI_Station
    private unit array CUI_Crafter
    private boolean array CUI_ReopenAfterCraft
    private integer array CUI_ListStart
    private integer array CUI_SelectedRecipe

    private Table CUI_ButtonRow = 0

    private trigger CUI_SelectTrigger = null
    private trigger CUI_CloseTrigger = null
    private trigger CUI_ReturnTrigger = null
    private trigger CUI_RowTrigger = null
    private trigger CUI_PrevTrigger = null
    private trigger CUI_NextTrigger = null
    private trigger CUI_CraftTrigger = null
    private trigger CUI_ClearFocusTrigger = null
endglobals

private function CUI_GetUnitName takes unit whichUnit returns string
    if whichUnit == null then
        return NoCrafterText
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroProperName(whichUnit)
    endif
    return GetUnitName(whichUnit)
endfunction

private function CUI_GetStationType takes integer pid returns integer
    if CUI_Station[pid] == null then
        return 0
    endif
    return GetUnitTypeId(CUI_Station[pid])
endfunction

private function CUI_IsValidCrafterCandidate takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and IsUnitType(whichUnit, UNIT_TYPE_HERO) and GNS_IsTrackedGatherer(whichUnit)
endfunction

private function CUI_GetDistanceSq takes unit a, unit b returns real
    local real dx = GetUnitX(a) - GetUnitX(b)
    local real dy = GetUnitY(a) - GetUnitY(b)
    return dx * dx + dy * dy
endfunction

private function CUI_GetCloserCrafter takes unit station, unit current, unit candidate returns unit
    if station == null or not CUI_IsValidCrafterCandidate(candidate) then
        return current
    endif
    if current == null or CUI_GetDistanceSq(candidate, station) < CUI_GetDistanceSq(current, station) then
        return candidate
    endif
    return current
endfunction

private function CUI_GetNearestTrackedHero takes unit station returns unit
    local unit best = null

    set best = CUI_GetCloserCrafter(station, best, udg_Nazgrek)
    set best = CUI_GetCloserCrafter(station, best, udg_Zulkis)
    set best = CUI_GetCloserCrafter(station, best, GNS_GetUITargetUnit())

    return best
endfunction

private function CUI_GetProfession takes integer pid returns integer
    return Professions_GetStationProfessionByUnitType(CUI_GetStationType(pid))
endfunction

private function CUI_GetRecipeTotal takes integer pid returns integer
    return Professions_GetRecipeCountForStation(CUI_GetProfession(pid), CUI_GetStationType(pid))
endfunction

private function CUI_GetRecipeIndex takes integer pid, integer recipeId returns integer
    local integer professionId = CUI_GetProfession(pid)
    local integer stationTypeId = CUI_GetStationType(pid)
    local integer total = Professions_GetRecipeCountForStation(professionId, stationTypeId)
    local integer index = 1

    loop
        exitwhen index > total
        if Professions_GetRecipeIdForStationIndex(professionId, stationTypeId, index) == recipeId then
            return index
        endif
        set index = index + 1
    endloop

    return 0
endfunction

private function CUI_ClampForPlayer takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer total = CUI_GetRecipeTotal(pid)
    local integer maxStart = total - CUI_VISIBLE_ROWS
    local integer selectedIndex

    if maxStart < 0 then
        set maxStart = 0
    endif
    if CUI_ListStart[pid] < 0 then
        set CUI_ListStart[pid] = 0
    elseif CUI_ListStart[pid] > maxStart then
        set CUI_ListStart[pid] = maxStart
    endif

    if total <= 0 then
        set CUI_SelectedRecipe[pid] = 0
        set CUI_ListStart[pid] = 0
        return
    endif

    set selectedIndex = CUI_GetRecipeIndex(pid, CUI_SelectedRecipe[pid])
    if selectedIndex <= 0 then
        set CUI_SelectedRecipe[pid] = Professions_GetRecipeIdForStationIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), 1)
        set selectedIndex = 1
    endif

    if selectedIndex <= CUI_ListStart[pid] then
        set CUI_ListStart[pid] = selectedIndex - 1
    elseif selectedIndex > CUI_ListStart[pid] + CUI_VISIBLE_ROWS then
        set CUI_ListStart[pid] = selectedIndex - CUI_VISIBLE_ROWS
    endif
endfunction

private function CUI_GetRecipeStateText takes unit crafter, unit station, integer recipeId returns string
    local integer requiredSkill
    local integer currentSkill
    local string missingText

    if recipeId == 0 then
        return ""
    endif

    set requiredSkill = Professions_GetRecipeRequiredSkill(recipeId)
    set currentSkill = GNS_GetSkill(crafter, Professions_GetRecipeProfessionId(recipeId))
    if currentSkill < requiredSkill then
        return "|cffff8080Skill " + I2S(requiredSkill) + "|r"
    endif

    set missingText = Professions_GetMissingRecipeText(crafter, recipeId)
    if missingText != "" then
        return "|cffff8080Mats|r"
    endif

    if not Professions_IsCrafterNearStation(crafter, station) then
        return "|cffff8080Range|r"
    endif

    if Professions_CanStartRecipe(crafter, station, recipeId) then
        return "|cff80ff80Ready|r"
    endif

    return "|cffffcc00Busy|r"
endfunction

private function CUI_GetDetailBody takes unit crafter, unit station, integer recipeId returns string
    local integer materialCount
    local integer slot = 1
    local integer professionId
    local integer currentSkill
    local integer requiredSkill
    local string body
    local string description

    if recipeId == 0 then
        return NoRecipesText
    endif

    set professionId = Professions_GetRecipeProfessionId(recipeId)
    set currentSkill = GNS_GetSkill(crafter, professionId)
    set requiredSkill = Professions_GetRecipeRequiredSkill(recipeId)
    set description = Professions_GetRecipeDescription(recipeId)
    if description == null or description == "" then
        set description = "No recipe description configured."
    endif

    set body = description + "|n|n|cffffcc00Crafting|r"
    set body = body + "|n|cffbfbfbfProfession: " + GNS_GetProfessionName(professionId) + "|r"
    set body = body + "|n|cffbfbfbfSkill: " + I2S(currentSkill) + " / " + I2S(requiredSkill) + "|r"
    set body = body + "|n|cffbfbfbfTime: " + R2SW(Professions_GetRecipeCraftTime(recipeId), 1, 1) + " sec|r"
    set body = body + "|n|n|cffffcc00Materials|r"

    set materialCount = Professions_GetRecipeMaterialCount(recipeId)
    if materialCount <= 0 then
        set body = body + "|n|cffbfbfbfNo materials configured.|r"
    else
        loop
            exitwhen slot > materialCount
            set body = body + "|n" + Professions_GetRecipeMaterialLine(crafter, recipeId, slot)
            set slot = slot + 1
        endloop
    endif

    return body
endfunction

private function CUI_UpdateRows takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer rowIndex = 1
    local integer recipeId
    local integer listIndex
    local string rowName

    if GetLocalPlayer() != whichPlayer then
        return
    endif

    loop
        exitwhen rowIndex > CUI_VISIBLE_ROWS
        set listIndex = CUI_ListStart[pid] + rowIndex
        set recipeId = Professions_GetRecipeIdForStationIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), listIndex)
        if recipeId != 0 then
            set rowName = Professions_GetRecipeName(recipeId)
            if recipeId == CUI_SelectedRecipe[pid] then
                set rowName = "|cffffe4a3" + rowName + "|r"
            elseif Professions_CanStartRecipe(CUI_Crafter[pid], CUI_Station[pid], recipeId) then
                set rowName = "|cffffffff" + rowName + "|r"
            else
                set rowName = "|cff9a9a9a" + rowName + "|r"
            endif

            call BlzFrameSetTexture(CUI_RowIcon[rowIndex], Professions_GetRecipeIcon(recipeId), 0, true)
            call BlzFrameSetText(CUI_RowText[rowIndex], rowName)
            call BlzFrameSetText(CUI_RowState[rowIndex], CUI_GetRecipeStateText(CUI_Crafter[pid], CUI_Station[pid], recipeId))
            call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], recipeId == CUI_SelectedRecipe[pid])
            call BlzFrameSetVisible(CUI_RowButton[rowIndex], true)
        else
            call BlzFrameSetVisible(CUI_RowButton[rowIndex], false)
            call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop
endfunction

private function CUI_UpdateDetail takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer recipeId = CUI_SelectedRecipe[pid]
    local boolean canCraft = false
    local string infoText

    if GetLocalPlayer() != whichPlayer then
        return
    endif

    if CUI_Station[pid] == null or GetUnitTypeId(CUI_Station[pid]) == 0 then
        call BlzFrameSetTexture(CUI_DetailIcon, "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", 0, true)
        call BlzFrameSetText(CUI_DetailTitle, NoStationText)
        call BlzFrameSetText(CUI_DetailInfo, "")
        call BlzFrameSetText(CUI_DetailBody, NoRecipesText)
        call BlzFrameSetText(CUI_CraftButton, "Craft")
        call BlzFrameSetEnable(CUI_CraftButton, false)
        return
    endif

    if recipeId == 0 then
        call BlzFrameSetTexture(CUI_DetailIcon, "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", 0, true)
        call BlzFrameSetText(CUI_DetailTitle, Professions_GetStationNameByUnitType(CUI_GetStationType(pid)))
        call BlzFrameSetText(CUI_DetailInfo, GNS_GetProfessionName(CUI_GetProfession(pid)))
        call BlzFrameSetText(CUI_DetailBody, NoRecipesText)
        call BlzFrameSetText(CUI_CraftButton, "Craft")
        call BlzFrameSetEnable(CUI_CraftButton, false)
        return
    endif

    set canCraft = Professions_CanStartRecipe(CUI_Crafter[pid], CUI_Station[pid], recipeId)
    set infoText = GNS_GetProfessionName(Professions_GetRecipeProfessionId(recipeId)) + " " + I2S(Professions_GetRecipeRequiredSkill(recipeId))
    call BlzFrameSetTexture(CUI_DetailIcon, Professions_GetRecipeIcon(recipeId), 0, true)
    call BlzFrameSetText(CUI_DetailTitle, "|cffffe4a3" + Professions_GetRecipeName(recipeId) + "|r")
    call BlzFrameSetText(CUI_DetailInfo, "|cffbfbfbf" + infoText + "|r")
    call BlzFrameSetText(CUI_DetailBody, CUI_GetDetailBody(CUI_Crafter[pid], CUI_Station[pid], recipeId))
    if canCraft then
        call BlzFrameSetText(CUI_CraftButton, "Craft")
    else
        call BlzFrameSetText(CUI_CraftButton, "Unavailable")
    endif
    call BlzFrameSetEnable(CUI_CraftButton, canCraft)
endfunction

private function CUI_UpdateForPlayer takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer total
    local integer maxStart
    local string stationName

    if CUI_Parent == null then
        return
    endif

    call CUI_ClampForPlayer(whichPlayer)
    set total = CUI_GetRecipeTotal(pid)
    set maxStart = total - CUI_VISIBLE_ROWS
    if maxStart < 0 then
        set maxStart = 0
    endif

    if GetLocalPlayer() == whichPlayer then
        set stationName = Professions_GetStationNameByUnitType(CUI_GetStationType(pid))
        call BlzFrameSetText(CUI_Title, TitleText)
        call BlzFrameSetText(CUI_ViewingText, "Crafter: " + CUI_GetUnitName(CUI_Crafter[pid]))
        call BlzFrameSetText(CUI_StationText, "Station: " + stationName + " | " + GNS_GetProfessionName(CUI_GetProfession(pid)))
        call BlzFrameSetVisible(CUI_PrevButton, CUI_ListStart[pid] > 0)
        call BlzFrameSetVisible(CUI_NextButton, CUI_ListStart[pid] < maxStart)
    endif

    call CUI_UpdateRows(whichPlayer)
    call CUI_UpdateDetail(whichPlayer)
endfunction

private function CUI_HideForPlayer takes player whichPlayer returns nothing
    if CUI_Parent != null and GetLocalPlayer() == whichPlayer then
        if BlzFrameIsVisible(CUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, whichPlayer)
        endif
        call BlzFrameSetVisible(CUI_Parent, false)
    endif
endfunction

private function CUI_OpenForPlayer takes player whichPlayer, unit station, unit crafter returns nothing
    local integer pid

    if whichPlayer == null or station == null or crafter == null then
        return
    endif

    set pid = GetPlayerId(whichPlayer)
    set CUI_Station[pid] = station
    set CUI_Crafter[pid] = crafter
    set CUI_ListStart[pid] = 0
    set CUI_SelectedRecipe[pid] = 0
    call CUI_ClampForPlayer(whichPlayer)

    if GetLocalPlayer() == whichPlayer then
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, whichPlayer)
        call BlzFrameSetVisible(CUI_Parent, true)
    endif

    call CUI_UpdateForPlayer(whichPlayer)
endfunction

private function CUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function CUI_CloseAction takes nothing returns nothing
    call CUI_HideForPlayer(GetTriggerPlayer())
endfunction

private function CUI_ReturnAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    call CUI_HideForPlayer(p)
    call MasterUI_Show()
    set p = null
endfunction

private function CUI_RowAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = CUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
    local integer recipeId = Professions_GetRecipeIdForStationIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), CUI_ListStart[pid] + rowIndex)

    if recipeId != 0 then
        set CUI_SelectedRecipe[pid] = recipeId
        call CUI_UpdateForPlayer(p)
    endif

    set p = null
endfunction

private function CUI_PrevAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)

    if CUI_ListStart[pid] > 0 then
        set CUI_ListStart[pid] = CUI_ListStart[pid] - CUI_VISIBLE_ROWS
        if CUI_ListStart[pid] < 0 then
            set CUI_ListStart[pid] = 0
        endif
        set CUI_SelectedRecipe[pid] = Professions_GetRecipeIdForStationIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), CUI_ListStart[pid] + 1)
        call CUI_UpdateForPlayer(p)
    endif

    set p = null
endfunction

private function CUI_NextAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer maxStart = CUI_GetRecipeTotal(pid) - CUI_VISIBLE_ROWS

    if maxStart < 0 then
        set maxStart = 0
    endif
    if CUI_ListStart[pid] < maxStart then
        set CUI_ListStart[pid] = CUI_ListStart[pid] + CUI_VISIBLE_ROWS
        if CUI_ListStart[pid] > maxStart then
            set CUI_ListStart[pid] = maxStart
        endif
        set CUI_SelectedRecipe[pid] = Professions_GetRecipeIdForStationIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), CUI_ListStart[pid] + 1)
        call CUI_UpdateForPlayer(p)
    endif

    set p = null
endfunction

private function CUI_CraftAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)

    if CUI_SelectedRecipe[pid] != 0 then
        if Professions_StartRecipe(CUI_Crafter[pid], CUI_Station[pid], CUI_SelectedRecipe[pid]) then
            set CUI_ReopenAfterCraft[pid] = true
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, p)
            call CUI_HideForPlayer(p)
            call ExecuteFunc("ProfessionsUI_Refresh")
        else
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call CUI_UpdateForPlayer(p)
        endif
    endif

    set p = null
endfunction

private function CUI_SelectAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local unit station = GetTriggerUnit()
    local unit crafter

    if not Professions_IsStationUnit(station) then
        set p = null
        set station = null
        return
    endif

    set crafter = CUI_GetNearestTrackedHero(station)
    if crafter == null or not GNS_IsTrackedGatherer(crafter) then
        call DisplayTextToPlayer(p, 0.00, 0.00, "|cffff8080" + NoCrafterText + "|r")
    elseif not Professions_IsCrafterNearStation(crafter, station) then
        call DisplayTextToPlayer(p, 0.00, 0.00, "|cffff8080" + CUI_GetUnitName(crafter) + " is too far from the " + Professions_GetStationNameByUnitType(GetUnitTypeId(station)) + ".|r")
    else
        call CUI_OpenForPlayer(p, station, crafter)
    endif

    set crafter = null
    set station = null
    set p = null
endfunction

private function CUI_CreateFrames takes nothing returns nothing
    local integer rowIndex = 1
    local real rowTopOffset = -0.010

    set CUI_Parent = BlzCreateFrameByType("BACKDROP", "CraftingUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(CUI_Parent, FRAMEPOINT_TOPLEFT, 0.10, 0.56)
    call BlzFrameSetAbsPoint(CUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.68, 0.14)

    set CUI_Title = BlzCreateFrameByType("TEXT", "CraftingUITitle", CUI_Parent, "", 0)
    call BlzFrameSetPoint(CUI_Title, FRAMEPOINT_TOPLEFT, CUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(CUI_Title, 0.30, 0.018)
    call BlzFrameSetTextAlignment(CUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(CUI_Title, 1.10)
    call BlzFrameSetEnable(CUI_Title, false)
    call BlzFrameSetText(CUI_Title, TitleText)

    set CUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CraftingUIClose", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_CloseButton, 0.030, 0.030)
    call BlzFrameSetText(CUI_CloseButton, CloseButtonText)
    call BlzFrameSetPoint(CUI_CloseButton, FRAMEPOINT_TOPRIGHT, CUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)

    set CUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CraftingUIReturn", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_ReturnButton, 0.065, 0.030)
    call BlzFrameSetText(CUI_ReturnButton, "Return")
    call BlzFrameSetPoint(CUI_ReturnButton, FRAMEPOINT_TOPRIGHT, CUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)

    set CUI_ViewingText = BlzCreateFrameByType("TEXT", "CraftingUICrafter", CUI_Parent, "", 0)
    call BlzFrameSetPoint(CUI_ViewingText, FRAMEPOINT_TOPLEFT, CUI_Title, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
    call BlzFrameSetSize(CUI_ViewingText, 0.260, 0.014)
    call BlzFrameSetTextAlignment(CUI_ViewingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_ViewingText, false)

    set CUI_StationText = BlzCreateFrameByType("TEXT", "CraftingUIStation", CUI_Parent, "", 0)
    call BlzFrameSetPoint(CUI_StationText, FRAMEPOINT_TOPLEFT, CUI_ViewingText, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.004)
    call BlzFrameSetSize(CUI_StationText, 0.380, 0.014)
    call BlzFrameSetTextAlignment(CUI_StationText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_StationText, false)

    set CUI_LeftPane = BlzCreateFrameByType("BACKDROP", "CraftingUILeftPane", CUI_Parent, "", 0)
    call BlzFrameSetTexture(CUI_LeftPane, PanelTexture, 0, true)
    call BlzFrameSetPoint(CUI_LeftPane, FRAMEPOINT_TOPLEFT, CUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.088)
    call BlzFrameSetPoint(CUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.228, 0.052)

    set CUI_RightPane = BlzCreateFrameByType("BACKDROP", "CraftingUIRightPane", CUI_Parent, "", 0)
    call BlzFrameSetTexture(CUI_RightPane, PanelTexture, 0, true)
    call BlzFrameSetPoint(CUI_RightPane, FRAMEPOINT_TOPLEFT, CUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
    call BlzFrameSetPoint(CUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.052)

    loop
        exitwhen rowIndex > CUI_VISIBLE_ROWS
        set CUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "CraftingUIRowButton" + I2S(rowIndex), CUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetPoint(CUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, CUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
        call BlzFrameSetSize(CUI_RowButton[rowIndex], 0.202, CUI_ROW_HEIGHT)
        call BlzFrameSetVisible(CUI_RowButton[rowIndex], false)
        call BlzTriggerRegisterFrameEvent(CUI_RowTrigger, CUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        set CUI_ButtonRow.integer[GetHandleId(CUI_RowButton[rowIndex])] = rowIndex

        set CUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "CraftingUIRowIcon" + I2S(rowIndex), CUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(CUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, CUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
        call BlzFrameSetSize(CUI_RowIcon[rowIndex], 0.020, 0.020)

        set CUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "CraftingUIRowText" + I2S(rowIndex), CUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(CUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, CUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
        call BlzFrameSetPoint(CUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, CUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.052, 0.004)
        call BlzFrameSetTextAlignment(CUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(CUI_RowText[rowIndex], false)

        set CUI_RowState[rowIndex] = BlzCreateFrameByType("TEXT", "CraftingUIRowState" + I2S(rowIndex), CUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(CUI_RowState[rowIndex], FRAMEPOINT_TOPRIGHT, CUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.004)
        call BlzFrameSetPoint(CUI_RowState[rowIndex], FRAMEPOINT_BOTTOMRIGHT, CUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.004)
        call BlzFrameSetTextAlignment(CUI_RowState[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetScale(CUI_RowState[rowIndex], 0.86)
        call BlzFrameSetEnable(CUI_RowState[rowIndex], false)

        set CUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "CraftingUIRowHighlight" + I2S(rowIndex), CUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetAllPoints(CUI_RowHighlight[rowIndex], CUI_RowButton[rowIndex])
        call BlzFrameSetModel(CUI_RowHighlight[rowIndex], "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx", 0)
        call BlzFrameSetScale(CUI_RowHighlight[rowIndex], 0.76)
        call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], false)
        call BlzFrameSetEnable(CUI_RowHighlight[rowIndex], false)

        set rowTopOffset = rowTopOffset - CUI_ROW_HEIGHT - CUI_ROW_GAP
        set rowIndex = rowIndex + 1
    endloop

    set CUI_PrevButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CraftingUIPrev", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_PrevButton, 0.070, 0.030)
    call BlzFrameSetText(CUI_PrevButton, "Prev")
    call BlzFrameSetPoint(CUI_PrevButton, FRAMEPOINT_BOTTOMLEFT, CUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.020, 0.016)

    set CUI_NextButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CraftingUINext", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_NextButton, 0.070, 0.030)
    call BlzFrameSetText(CUI_NextButton, "Next")
    call BlzFrameSetPoint(CUI_NextButton, FRAMEPOINT_LEFT, CUI_PrevButton, FRAMEPOINT_RIGHT, 0.010, 0.0)

    set CUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "CraftingUIDetailIcon", CUI_RightPane, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(CUI_DetailIcon, FRAMEPOINT_TOPLEFT, CUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(CUI_DetailIcon, 0.044, 0.044)

    set CUI_DetailTitle = BlzCreateFrameByType("TEXT", "CraftingUIDetailTitle", CUI_RightPane, "", 0)
    call BlzFrameSetPoint(CUI_DetailTitle, FRAMEPOINT_TOPLEFT, CUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
    call BlzFrameSetSize(CUI_DetailTitle, 0.260, 0.018)
    call BlzFrameSetTextAlignment(CUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(CUI_DetailTitle, 1.05)
    call BlzFrameSetEnable(CUI_DetailTitle, false)

    set CUI_DetailInfo = BlzCreateFrameByType("TEXT", "CraftingUIDetailInfo", CUI_RightPane, "", 0)
    call BlzFrameSetPoint(CUI_DetailInfo, FRAMEPOINT_TOPLEFT, CUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
    call BlzFrameSetSize(CUI_DetailInfo, 0.260, 0.014)
    call BlzFrameSetTextAlignment(CUI_DetailInfo, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_DetailInfo, false)

    set CUI_DetailBody = BlzCreateFrameByType("TEXT", "CraftingUIDetailBody", CUI_RightPane, "", 0)
    call BlzFrameSetPoint(CUI_DetailBody, FRAMEPOINT_TOPLEFT, CUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.082)
    call BlzFrameSetPoint(CUI_DetailBody, FRAMEPOINT_BOTTOMRIGHT, CUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.018, 0.014)
    call BlzFrameSetTextAlignment(CUI_DetailBody, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(CUI_DetailBody, 0.94)
    call BlzFrameSetEnable(CUI_DetailBody, false)

    set CUI_CraftButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CraftingUICraft", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_CraftButton, 0.100, 0.032)
    call BlzFrameSetText(CUI_CraftButton, "Craft")
    call BlzFrameSetPoint(CUI_CraftButton, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.024, 0.030)

    call BlzTriggerRegisterFrameEvent(CUI_CloseTrigger, CUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ReturnTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_PrevTrigger, CUI_PrevButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_PrevButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_NextTrigger, CUI_NextButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_NextButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_CraftTrigger, CUI_CraftButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_CraftButton, FRAMEEVENT_CONTROL_CLICK)

    call BlzFrameSetVisible(CUI_Parent, false)
endfunction

public function Hide takes nothing returns nothing
    if CUI_Parent != null then
        call BlzFrameSetVisible(CUI_Parent, false)
    endif
endfunction

public function ReopenAfterCraft takes nothing returns nothing
    local integer playerIndex = 0

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        if CUI_ReopenAfterCraft[playerIndex] and CUI_Station[playerIndex] != null and CUI_Crafter[playerIndex] != null then
            set CUI_ReopenAfterCraft[playerIndex] = false
            call CUI_OpenForPlayer(Player(playerIndex), CUI_Station[playerIndex], CUI_Crafter[playerIndex])
        endif
        set playerIndex = playerIndex + 1
    endloop
endfunction

public function Refresh takes nothing returns nothing
    call CUI_UpdateForPlayer(GetLocalPlayer())
endfunction

public function OpenForStation takes unit station, unit crafter returns nothing
    if crafter == null then
        return
    endif
    call CUI_OpenForPlayer(GetOwningPlayer(crafter), station, crafter)
endfunction

public function Init takes nothing returns nothing
    local integer playerIndex = 0

    if CUI_Initialized then
        return
    endif
    set CUI_Initialized = true

    set CUI_ButtonRow = Table.create()

    set CUI_SelectTrigger = CreateTrigger()
    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(CUI_SelectTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_SELECTED, null)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(CUI_SelectTrigger, function CUI_SelectAction)

    set CUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(CUI_CloseTrigger, function CUI_CloseAction)

    set CUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ReturnTrigger, function CUI_ReturnAction)

    set CUI_RowTrigger = CreateTrigger()
    call TriggerAddAction(CUI_RowTrigger, function CUI_RowAction)

    set CUI_PrevTrigger = CreateTrigger()
    call TriggerAddAction(CUI_PrevTrigger, function CUI_PrevAction)

    set CUI_NextTrigger = CreateTrigger()
    call TriggerAddAction(CUI_NextTrigger, function CUI_NextAction)

    set CUI_CraftTrigger = CreateTrigger()
    call TriggerAddAction(CUI_CraftTrigger, function CUI_CraftAction)

    set CUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ClearFocusTrigger, function CUI_ClearFocusAction)

    call CUI_CreateFrames()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
