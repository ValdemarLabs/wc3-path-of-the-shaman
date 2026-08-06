/**
    CraftingUI

    Author: Valdemar
    Version: 1.5

    Description: Shared custom-frame crafting panel for profession workstations. Recipe and category data is fetched from Professions and its profession sublibraries.

    Credits: Tasyen (TasQuestBox as inspiration)

    How to install:
    Import this library after Professions, MasterUI, and Interface. Profession sublibraries register workstation unit types; selecting a registered workstation opens this panel for the nearest owned tracked hero.

    API:
    call CraftingUI_OpenForStation(whichStation, whichCrafter)
    call CraftingUI_Hide()
    call CraftingUI_Refresh()

**/

library CraftingUI initializer AutoInit requires Professions, GatherNodeSkills, Table, MasterUI, Interface, DEquipment

globals
    private constant integer CUI_VISIBLE_ROWS = 12
    private constant integer CUI_MAX_CACHED_ENTRIES = 256
    private constant integer CUI_VIEW_ROOT = 1
    private constant integer CUI_VIEW_SUBCATEGORIES = 2
    private constant integer CUI_VIEW_RECIPES = 3
    private constant real CUI_ROW_HEIGHT = 0.020
    private constant real CUI_ROW_GAP = 0.002

    private boolean CUI_Initialized = false
    private boolean CUI_LastRecipeReady = false

    public string TitleText = "|cffffe4a3Crafting|r"
    public string CloseButtonText = "X"
    public string NoStationText = "No workstation"
    public string NoCrafterText = "No tracked crafter"
    public string NoRecipesText = "No recipes configured for this workstation."
    public string CategoryPromptText = "|cffbfbfbfSelect a category from the list.|r"
    public string CategoryIcon = "ReplaceableTextures\\CommandButtons\\BTNTrade11.blp"
    public string FoodCategoryIcon = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Food_15.blp"
    public string BeverageCategoryIcon = "ReplaceableTextures\\CommandButtons\\BTNPotionBlueSmall.blp"
    public string PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    public string QueryStartText = "|cffffcc00Crafting query started.|r Press ESC to stop."
    public string QueryStopText = "|cffffcc00Crafting query stopped.|r"

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
    private framehandle CUI_QueryButton = null
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
    private boolean array CUI_QueryAfterCraft
    private integer array CUI_ListStart
    private integer array CUI_SelectedRecipe
    private string array CUI_SelectedCategory
    private string array CUI_SelectedSubcategory
    private integer array CUI_ViewMode
    private integer array CUI_EntryCount
    private integer array CUI_EntryRecipeId
    private integer array CUI_EntryChildCount
    private string array CUI_EntryName

    private Table CUI_ButtonRow = 0

    private trigger CUI_SelectTrigger = null
    private trigger CUI_CloseTrigger = null
    private trigger CUI_ReturnTrigger = null
    private trigger CUI_RowTrigger = null
    private trigger CUI_PrevTrigger = null
    private trigger CUI_NextTrigger = null
    private trigger CUI_CraftTrigger = null
    private trigger CUI_QueryTrigger = null
    private trigger CUI_EscapeTrigger = null
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

private function CUI_IsValidCrafterCandidateForPlayer takes player whichPlayer, unit whichUnit returns boolean
    if whichPlayer == null or whichUnit == null then
        return false
    endif
    if GetUnitTypeId(whichUnit) == 0 then
        return false
    endif
    return GetOwningPlayer(whichUnit) == whichPlayer and IsUnitType(whichUnit, UNIT_TYPE_HERO) and GNS_IsTrackedGatherer(whichUnit)
endfunction

private function CUI_GetDistanceSq takes unit a, unit b returns real
    local real dx = GetUnitX(a) - GetUnitX(b)
    local real dy = GetUnitY(a) - GetUnitY(b)
    return dx * dx + dy * dy
endfunction

private function CUI_GetCloserCrafter takes player whichPlayer, unit station, unit current, unit candidate returns unit
    if station == null or not CUI_IsValidCrafterCandidateForPlayer(whichPlayer, candidate) then
        return current
    endif
    if current == null or CUI_GetDistanceSq(candidate, station) < CUI_GetDistanceSq(current, station) then
        return candidate
    endif
    return current
endfunction

private function CUI_GetNearestTrackedHero takes player whichPlayer, unit station returns unit
    local unit best = null

    set best = CUI_GetCloserCrafter(whichPlayer, station, best, udg_Nazgrek)
    set best = CUI_GetCloserCrafter(whichPlayer, station, best, udg_Zulkis)
    set best = CUI_GetCloserCrafter(whichPlayer, station, best, GNS_GetUITargetUnit())

    return best
endfunction

private function CUI_GetProfession takes integer pid returns integer
    return Professions_GetStationProfessionByUnitType(CUI_GetStationType(pid))
endfunction

private function CUI_GetSelectedCategory takes integer pid returns string
    if CUI_SelectedCategory[pid] == null then
        return ""
    endif
    return CUI_SelectedCategory[pid]
endfunction

private function CUI_GetSelectedSubcategory takes integer pid returns string
    if CUI_SelectedSubcategory[pid] == null then
        return ""
    endif
    return CUI_SelectedSubcategory[pid]
endfunction

private function CUI_GetCategoryIcon takes string categoryName returns string
    if categoryName == "Food" then
        return FoodCategoryIcon
    elseif categoryName == "Beverages" then
        return BeverageCategoryIcon
    endif
    return CategoryIcon
endfunction

private function CUI_GetMaxListStart takes integer total returns integer
    local integer maxStart = 0

    if total <= CUI_VISIBLE_ROWS then
        return 0
    endif

    loop
        exitwhen maxStart + CUI_VISIBLE_ROWS >= total
        set maxStart = maxStart + CUI_VISIBLE_ROWS
    endloop

    return maxStart
endfunction

private function CUI_GetPageStartForIndex takes integer listIndex returns integer
    local integer pageStart = 0

    if listIndex <= 1 then
        return 0
    endif

    loop
        exitwhen pageStart + CUI_VISIBLE_ROWS >= listIndex
        set pageStart = pageStart + CUI_VISIBLE_ROWS
    endloop

    return pageStart
endfunction

private function CUI_GetCategoryCount takes integer pid returns integer
    return Professions_GetRecipeCategoryCountForStation(CUI_GetProfession(pid), CUI_GetStationType(pid))
endfunction

private function CUI_GetSubcategoryCount takes integer pid returns integer
    if CUI_GetSelectedCategory(pid) == "" then
        return 0
    endif
    return Professions_GetRecipeSubcategoryCountForStationCategory(CUI_GetProfession(pid), CUI_GetStationType(pid), CUI_GetSelectedCategory(pid))
endfunction

private function CUI_HasRootSubcategories takes integer pid returns boolean
    local integer index = 1
    local integer total = CUI_GetCategoryCount(pid)
    local string categoryName

    loop
        exitwhen index > total
        set categoryName = Professions_GetRecipeCategoryForStationIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), index)
        if categoryName != "" and Professions_GetRecipeSubcategoryCountForStationCategory(CUI_GetProfession(pid), CUI_GetStationType(pid), categoryName) > 0 then
            return true
        endif
        set index = index + 1
    endloop

    return false
endfunction

private function CUI_UsesCategoryRoot takes integer pid returns boolean
    return CUI_GetCategoryCount(pid) > 1 or CUI_HasRootSubcategories(pid)
endfunction

private function CUI_IsCategoryMode takes integer pid returns boolean
    return CUI_ViewMode[pid] == CUI_VIEW_ROOT
endfunction

private function CUI_IsSubcategoryMode takes integer pid returns boolean
    return CUI_ViewMode[pid] == CUI_VIEW_SUBCATEGORIES
endfunction

private function CUI_RecipeMatchesCurrentPath takes integer pid, integer recipeId returns boolean
    if Professions_GetRecipeProfessionId(recipeId) != CUI_GetProfession(pid) or Professions_GetRecipeStationTypeId(recipeId) != CUI_GetStationType(pid) then
        return false
    endif
    if CUI_GetSelectedCategory(pid) != "" and Professions_GetRecipeCategory(recipeId) != CUI_GetSelectedCategory(pid) then
        return false
    endif
    if CUI_GetSelectedSubcategory(pid) != "" and Professions_GetRecipeSubcategory(recipeId) != CUI_GetSelectedSubcategory(pid) then
        return false
    endif
    return true
endfunction

private function CUI_GetEntryKey takes integer pid, integer listIndex returns integer
    return pid*CUI_MAX_CACHED_ENTRIES + listIndex
endfunction

private function CUI_ClearEntryCache takes integer pid returns nothing
    local integer listIndex = 1
    local integer key

    loop
        exitwhen listIndex > CUI_EntryCount[pid]
        set key = CUI_GetEntryKey(pid, listIndex)
        set CUI_EntryRecipeId[key] = 0
        set CUI_EntryChildCount[key] = 0
        set CUI_EntryName[key] = ""
        set listIndex = listIndex + 1
    endloop
    set CUI_EntryCount[pid] = 0
endfunction

// Navigation changes rebuild once; ordinary row/detail refreshes use this cache.
private function CUI_RebuildEntryCache takes integer pid returns nothing
    local integer listIndex = 1
    local integer total
    local integer key
    local integer recipeId
    local string entryName

    call CUI_ClearEntryCache(pid)
    if CUI_IsCategoryMode(pid) then
        set total = CUI_GetCategoryCount(pid)
        if total > CUI_MAX_CACHED_ENTRIES then
            set total = CUI_MAX_CACHED_ENTRIES
        endif
        loop
            exitwhen listIndex > total
            set key = CUI_GetEntryKey(pid, listIndex)
            set entryName = Professions_GetRecipeCategoryForStationIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), listIndex)
            set CUI_EntryName[key] = entryName
            set CUI_EntryChildCount[key] = Professions_GetRecipeSubcategoryCountForStationCategory(CUI_GetProfession(pid), CUI_GetStationType(pid), entryName)
            if CUI_EntryChildCount[key] <= 0 then
                set CUI_EntryChildCount[key] = Professions_GetRecipeCountForStationCategory(CUI_GetProfession(pid), CUI_GetStationType(pid), entryName)
            endif
            set listIndex = listIndex + 1
        endloop
    elseif CUI_IsSubcategoryMode(pid) then
        set total = CUI_GetSubcategoryCount(pid)
        if total > CUI_MAX_CACHED_ENTRIES then
            set total = CUI_MAX_CACHED_ENTRIES
        endif
        loop
            exitwhen listIndex > total
            set key = CUI_GetEntryKey(pid, listIndex)
            set entryName = Professions_GetRecipeSubcategoryForStationCategoryIndex(CUI_GetProfession(pid), CUI_GetStationType(pid), CUI_GetSelectedCategory(pid), listIndex)
            set CUI_EntryName[key] = entryName
            set CUI_EntryChildCount[key] = Professions_GetRecipeCountForStationSubcategory(CUI_GetProfession(pid), CUI_GetStationType(pid), CUI_GetSelectedCategory(pid), entryName)
            set listIndex = listIndex + 1
        endloop
    else
        set total = 0
        set recipeId = 1
        loop
            exitwhen recipeId > Professions_GetRecipeCount() or total >= CUI_MAX_CACHED_ENTRIES
            if CUI_RecipeMatchesCurrentPath(pid, recipeId) then
                set total = total + 1
                set CUI_EntryRecipeId[CUI_GetEntryKey(pid, total)] = recipeId
            endif
            set recipeId = recipeId + 1
        endloop
    endif
    set CUI_EntryCount[pid] = total
endfunction

private function CUI_GetRecipeTotal takes integer pid returns integer
    return CUI_EntryCount[pid]
endfunction

private function CUI_GetRecipeIdForListIndex takes integer pid, integer listIndex returns integer
    if listIndex <= 0 or listIndex > CUI_EntryCount[pid] or CUI_IsCategoryMode(pid) or CUI_IsSubcategoryMode(pid) then
        return 0
    endif
    return CUI_EntryRecipeId[CUI_GetEntryKey(pid, listIndex)]
endfunction

private function CUI_GetEntryName takes integer pid, integer listIndex returns string
    if listIndex <= 0 or listIndex > CUI_EntryCount[pid] then
        return ""
    endif
    return CUI_EntryName[CUI_GetEntryKey(pid, listIndex)]
endfunction

private function CUI_GetEntryChildCount takes integer pid, integer listIndex returns integer
    if listIndex <= 0 or listIndex > CUI_EntryCount[pid] then
        return 0
    endif
    return CUI_EntryChildCount[CUI_GetEntryKey(pid, listIndex)]
endfunction

private function CUI_SelectFirstRecipeForCurrentPath takes integer pid returns nothing
    if not CUI_IsCategoryMode(pid) and not CUI_IsSubcategoryMode(pid) then
        set CUI_SelectedRecipe[pid] = CUI_GetRecipeIdForListIndex(pid, CUI_ListStart[pid] + 1)
    else
        set CUI_SelectedRecipe[pid] = 0
    endif
endfunction

private function CUI_GetRecipeIndex takes integer pid, integer recipeId returns integer
    local integer total = CUI_GetRecipeTotal(pid)
    local integer index = 1

    if CUI_IsCategoryMode(pid) or CUI_IsSubcategoryMode(pid) then
        return 0
    endif

    loop
        exitwhen index > total
        if CUI_GetRecipeIdForListIndex(pid, index) == recipeId then
            return index
        endif
        set index = index + 1
    endloop

    return 0
endfunction

private function CUI_ClampForPlayer takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer total = CUI_GetRecipeTotal(pid)
    local integer maxStart = CUI_GetMaxListStart(total)
    local integer selectedIndex

    if CUI_ListStart[pid] < 0 then
        set CUI_ListStart[pid] = 0
    elseif CUI_ListStart[pid] > maxStart then
        set CUI_ListStart[pid] = maxStart
    endif
    if CUI_ListStart[pid] > 0 then
        set CUI_ListStart[pid] = CUI_GetPageStartForIndex(CUI_ListStart[pid] + 1)
        if CUI_ListStart[pid] > maxStart then
            set CUI_ListStart[pid] = maxStart
        endif
    endif

    if total <= 0 then
        set CUI_SelectedRecipe[pid] = 0
        set CUI_ListStart[pid] = 0
        return
    endif

    if CUI_IsCategoryMode(pid) or CUI_IsSubcategoryMode(pid) then
        set CUI_SelectedRecipe[pid] = 0
        return
    endif

    set selectedIndex = CUI_GetRecipeIndex(pid, CUI_SelectedRecipe[pid])
    if selectedIndex <= 0 then
        set CUI_SelectedRecipe[pid] = CUI_GetRecipeIdForListIndex(pid, 1)
        set selectedIndex = 1
    endif

    if selectedIndex <= CUI_ListStart[pid] then
        set CUI_ListStart[pid] = CUI_GetPageStartForIndex(selectedIndex)
    elseif selectedIndex > CUI_ListStart[pid] + CUI_VISIBLE_ROWS then
        set CUI_ListStart[pid] = CUI_GetPageStartForIndex(selectedIndex)
    endif
endfunction

private function CUI_GetRecipeStateText takes unit crafter, unit station, integer recipeId returns string
    local integer requiredSkill
    local integer currentSkill
    local string missingText

    set CUI_LastRecipeReady = false
    if recipeId == 0 then
        return ""
    endif

    set requiredSkill = Professions_GetRecipeRequiredSkill(recipeId)
    set currentSkill = Professions_GetEffectiveSkill(crafter, Professions_GetRecipeProfessionId(recipeId))
    if currentSkill < requiredSkill then
        return "|cffff8080Skill " + I2S(requiredSkill) + "|r"
    endif

    if not Professions_HasRecipeRequiredItem(crafter, recipeId) then
        return "|cffff8080Tool|r"
    endif

    set missingText = Professions_GetMissingRecipeText(crafter, recipeId)
    if missingText != "" then
        return "|cffff8080Mats|r"
    endif

    if not Professions_IsCrafterNearStation(crafter, station) then
        return "|cffff8080Range|r"
    endif

    if Professions_CanStartRecipe(crafter, station, recipeId) then
        set CUI_LastRecipeReady = true
        return "|cff80ff80Ready|r"
    endif

    return "|cffffcc00Busy|r"
endfunction

private function CUI_SetCraftButtons takes boolean canCraft returns nothing
    call BlzFrameSetText(CUI_CraftButton, "Craft")
    call BlzFrameSetEnable(CUI_CraftButton, canCraft)
    call BlzFrameSetText(CUI_QueryButton, "Query")
    call BlzFrameSetEnable(CUI_QueryButton, canCraft)
endfunction

private function CUI_GetDetailBody takes unit crafter, unit station, integer recipeId returns string
    local integer materialCount
    local integer slot = 1
    local integer professionId
    local integer outputItemCode
    local integer currentSkill
    local integer requiredSkill
    local string body
    local string description
    local string itemTooltip

    if recipeId == 0 then
        return NoRecipesText
    endif

    set professionId = Professions_GetRecipeProfessionId(recipeId)
    set currentSkill = Professions_GetEffectiveSkill(crafter, professionId)
    set requiredSkill = Professions_GetRecipeRequiredSkill(recipeId)
    set description = Professions_GetRecipeDescription(recipeId)
    set outputItemCode = Professions_GetRecipeOutputItemCode(recipeId)
    set itemTooltip = ""
    if outputItemCode != 0 then
        set itemTooltip = BlzGetAbilityExtendedTooltip(outputItemCode, 0)
    endif
    if description == null or description == "" then
        set description = "No recipe description configured."
    endif

    set body = description
    if itemTooltip != null and itemTooltip != "" then
        set body = body + "|n|n|cffffcc00Crafted item|r|n" + itemTooltip
    endif
    set body = body + "|n|n|cffffcc00Crafting|r"
    set body = body + "|n|cffbfbfbfProfession: " + GNS_GetProfessionName(professionId) + "|r"
    set body = body + "|n|cffbfbfbfSkill: " + I2S(currentSkill) + " / " + I2S(requiredSkill) + "|r"
    set body = body + "|n|cffbfbfbfTime: " + R2SW(Professions_GetRecipeCraftTime(recipeId), 1, 1) + " sec|r"
    if Professions_GetRecipeRequiredItemCode(recipeId) != 0 then
        set body = body + "|n|cffbfbfbfTool:|r " + Professions_GetRecipeRequiredItemLine(crafter, recipeId)
    endif
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

private function CUI_HideRow takes integer rowIndex returns nothing
    call BlzFrameSetText(CUI_RowText[rowIndex], "")
    call BlzFrameSetText(CUI_RowState[rowIndex], "")
    call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], false)
    call BlzFrameSetVisible(CUI_RowButton[rowIndex], false)
endfunction

private function CUI_UpdateRows takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer rowIndex = 1
    local integer recipeId
    local integer listIndex
    local integer entryCount
    local boolean canCraft
    local string stateText
    local string rowName
    local string categoryName
    local string subcategoryName

    if GetLocalPlayer() != whichPlayer then
        return
    endif

    loop
        exitwhen rowIndex > CUI_VISIBLE_ROWS
        set listIndex = CUI_ListStart[pid] + rowIndex

        if CUI_IsCategoryMode(pid) then
            set categoryName = CUI_GetEntryName(pid, listIndex)
            if categoryName != "" then
                set entryCount = CUI_GetEntryChildCount(pid, listIndex)
                call BlzFrameSetTexture(CUI_RowIcon[rowIndex], CUI_GetCategoryIcon(categoryName), 0, true)
                call BlzFrameSetText(CUI_RowText[rowIndex], "|cffffffff" + categoryName + "|r")
                call BlzFrameSetText(CUI_RowState[rowIndex], I2S(entryCount))
                call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], false)
                call BlzFrameSetVisible(CUI_RowButton[rowIndex], true)
            else
                call CUI_HideRow(rowIndex)
            endif
        elseif CUI_IsSubcategoryMode(pid) then
            set subcategoryName = CUI_GetEntryName(pid, listIndex)
            if subcategoryName != "" then
                set entryCount = CUI_GetEntryChildCount(pid, listIndex)
                call BlzFrameSetTexture(CUI_RowIcon[rowIndex], CUI_GetCategoryIcon(subcategoryName), 0, true)
                call BlzFrameSetText(CUI_RowText[rowIndex], "|cffffffff" + subcategoryName + "|r")
                call BlzFrameSetText(CUI_RowState[rowIndex], I2S(entryCount))
                call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], false)
                call BlzFrameSetVisible(CUI_RowButton[rowIndex], true)
            else
                call CUI_HideRow(rowIndex)
            endif
        else
            set recipeId = CUI_GetRecipeIdForListIndex(pid, listIndex)
            if recipeId != 0 then
                set stateText = CUI_GetRecipeStateText(CUI_Crafter[pid], CUI_Station[pid], recipeId)
                set canCraft = CUI_LastRecipeReady
                set rowName = Professions_GetRecipeName(recipeId)
                if recipeId == CUI_SelectedRecipe[pid] then
                    set rowName = "|cffffe4a3" + rowName + "|r"
                elseif canCraft then
                    set rowName = "|cffffffff" + rowName + "|r"
                else
                    set rowName = "|cff9a9a9a" + rowName + "|r"
                endif

                call BlzFrameSetTexture(CUI_RowIcon[rowIndex], Professions_GetRecipeIcon(recipeId), 0, true)
                call BlzFrameSetText(CUI_RowText[rowIndex], rowName)
                call BlzFrameSetText(CUI_RowState[rowIndex], stateText)
                call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], recipeId == CUI_SelectedRecipe[pid])
                call BlzFrameSetVisible(CUI_RowButton[rowIndex], true)
            else
                call CUI_HideRow(rowIndex)
            endif
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

    if not Professions_IsStationUnit(CUI_Station[pid]) then
        call BlzFrameSetTexture(CUI_DetailIcon, CategoryIcon, 0, true)
        call BlzFrameSetText(CUI_DetailTitle, NoStationText)
        call BlzFrameSetText(CUI_DetailInfo, "")
        call BlzFrameSetText(CUI_DetailBody, NoRecipesText)
        call CUI_SetCraftButtons(false)
        return
    endif

    if CUI_IsCategoryMode(pid) then
        call BlzFrameSetTexture(CUI_DetailIcon, CategoryIcon, 0, true)
        call BlzFrameSetText(CUI_DetailTitle, Professions_GetStationNameByUnitType(CUI_GetStationType(pid)))
        call BlzFrameSetText(CUI_DetailInfo, GNS_GetProfessionName(CUI_GetProfession(pid)))
        call BlzFrameSetText(CUI_DetailBody, CategoryPromptText)
        call CUI_SetCraftButtons(false)
        return
    endif

    if CUI_IsSubcategoryMode(pid) then
        call BlzFrameSetTexture(CUI_DetailIcon, CUI_GetCategoryIcon(CUI_GetSelectedCategory(pid)), 0, true)
        call BlzFrameSetText(CUI_DetailTitle, "|cffffe4a3" + CUI_GetSelectedCategory(pid) + "|r")
        call BlzFrameSetText(CUI_DetailInfo, GNS_GetProfessionName(CUI_GetProfession(pid)))
        call BlzFrameSetText(CUI_DetailBody, CategoryPromptText)
        call CUI_SetCraftButtons(false)
        return
    endif

    if recipeId == 0 then
        call BlzFrameSetTexture(CUI_DetailIcon, CategoryIcon, 0, true)
        call BlzFrameSetText(CUI_DetailTitle, Professions_GetStationNameByUnitType(CUI_GetStationType(pid)))
        call BlzFrameSetText(CUI_DetailInfo, GNS_GetProfessionName(CUI_GetProfession(pid)))
        call BlzFrameSetText(CUI_DetailBody, NoRecipesText)
        call CUI_SetCraftButtons(false)
        return
    endif

    set canCraft = Professions_CanStartRecipe(CUI_Crafter[pid], CUI_Station[pid], recipeId)
    set infoText = GNS_GetProfessionName(Professions_GetRecipeProfessionId(recipeId)) + " " + I2S(Professions_GetRecipeRequiredSkill(recipeId))
    call BlzFrameSetTexture(CUI_DetailIcon, Professions_GetRecipeIcon(recipeId), 0, true)
    call BlzFrameSetText(CUI_DetailTitle, "|cffffe4a3" + Professions_GetRecipeName(recipeId) + "|r")
    call BlzFrameSetText(CUI_DetailInfo, "|cffbfbfbf" + infoText + "|r")
    call BlzFrameSetText(CUI_DetailBody, CUI_GetDetailBody(CUI_Crafter[pid], CUI_Station[pid], recipeId))
    call CUI_SetCraftButtons(canCraft)
endfunction

private function CUI_UpdateRecipeSelection takes player whichPlayer, integer previousRecipeId returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer rowIndex = 1
    local integer recipeId
    local boolean canCraft
    local string rowName
    local string stateText

    if GetLocalPlayer() != whichPlayer then
        return
    endif

    loop
        exitwhen rowIndex > CUI_VISIBLE_ROWS
        set recipeId = CUI_GetRecipeIdForListIndex(pid, CUI_ListStart[pid] + rowIndex)
        if recipeId == CUI_SelectedRecipe[pid] then
            call BlzFrameSetText(CUI_RowText[rowIndex], "|cffffe4a3" + Professions_GetRecipeName(recipeId) + "|r")
            call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], true)
        elseif recipeId == previousRecipeId then
            set stateText = CUI_GetRecipeStateText(CUI_Crafter[pid], CUI_Station[pid], recipeId)
            set canCraft = CUI_LastRecipeReady
            set rowName = Professions_GetRecipeName(recipeId)
            if canCraft then
                set rowName = "|cffffffff" + rowName + "|r"
            else
                set rowName = "|cff9a9a9a" + rowName + "|r"
            endif
            call BlzFrameSetText(CUI_RowText[rowIndex], rowName)
            call BlzFrameSetText(CUI_RowState[rowIndex], stateText)
            call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    call CUI_UpdateDetail(whichPlayer)
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
    set maxStart = CUI_GetMaxListStart(total)

    if GetLocalPlayer() == whichPlayer then
        set stationName = Professions_GetStationNameByUnitType(CUI_GetStationType(pid))
        call BlzFrameSetText(CUI_Title, TitleText)
        call BlzFrameSetText(CUI_ViewingText, "Crafter: " + CUI_GetUnitName(CUI_Crafter[pid]))
        if CUI_GetSelectedCategory(pid) != "" then
            set stationName = stationName + " | " + GNS_GetProfessionName(CUI_GetProfession(pid)) + " | " + CUI_GetSelectedCategory(pid)
            if CUI_GetSelectedSubcategory(pid) != "" then
                set stationName = stationName + " | " + CUI_GetSelectedSubcategory(pid)
            endif
            call BlzFrameSetText(CUI_ReturnButton, "Back")
        else
            set stationName = stationName + " | " + GNS_GetProfessionName(CUI_GetProfession(pid))
            call BlzFrameSetText(CUI_ReturnButton, "Return")
        endif
        call BlzFrameSetText(CUI_StationText, "Station: " + stationName)
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

private function CUI_OpenForPlayerEx takes player whichPlayer, unit station, unit crafter, string categoryName, string subcategoryName returns nothing
    local integer pid

    if whichPlayer == null or station == null or crafter == null then
        return
    endif

    set pid = GetPlayerId(whichPlayer)
    call DInventoryEquipment_HideForPlayer(whichPlayer)
    set CUI_Station[pid] = station
    set CUI_Crafter[pid] = crafter
    set CUI_ListStart[pid] = 0
    set CUI_SelectedRecipe[pid] = 0
    set CUI_ReopenAfterCraft[pid] = false
    set CUI_QueryAfterCraft[pid] = false
    if categoryName == null then
        set CUI_SelectedCategory[pid] = ""
    else
        set CUI_SelectedCategory[pid] = categoryName
    endif
    if subcategoryName == null then
        set CUI_SelectedSubcategory[pid] = ""
    else
        set CUI_SelectedSubcategory[pid] = subcategoryName
    endif

    if CUI_GetSelectedSubcategory(pid) != "" then
        set CUI_ViewMode[pid] = CUI_VIEW_RECIPES
    elseif CUI_GetSelectedCategory(pid) != "" and CUI_GetSubcategoryCount(pid) > 0 then
        set CUI_ViewMode[pid] = CUI_VIEW_SUBCATEGORIES
    elseif CUI_GetSelectedCategory(pid) != "" then
        set CUI_ViewMode[pid] = CUI_VIEW_RECIPES
    elseif CUI_UsesCategoryRoot(pid) then
        set CUI_ViewMode[pid] = CUI_VIEW_ROOT
    else
        set CUI_ViewMode[pid] = CUI_VIEW_RECIPES
    endif
    call CUI_RebuildEntryCache(pid)
    call CUI_SelectFirstRecipeForCurrentPath(pid)
    call CUI_ClampForPlayer(whichPlayer)

    if GetLocalPlayer() == whichPlayer then
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, whichPlayer)
        call BlzFrameSetVisible(CUI_Parent, true)
    endif

    call CUI_UpdateForPlayer(whichPlayer)
endfunction

private function CUI_OpenForPlayer takes player whichPlayer, unit station, unit crafter returns nothing
    call CUI_OpenForPlayerEx(whichPlayer, station, crafter, "", "")
endfunction

private function CUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function CUI_StopQueryForPlayer takes player whichPlayer, boolean showMessage returns boolean
    local integer pid

    if whichPlayer == null then
        return false
    endif

    set pid = GetPlayerId(whichPlayer)
    if not CUI_QueryAfterCraft[pid] then
        return false
    endif

    set CUI_QueryAfterCraft[pid] = false
    set CUI_ReopenAfterCraft[pid] = false
    call Professions_CancelUnitCraft(CUI_Crafter[pid])
    if showMessage then
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, QueryStopText)
    endif

    return true
endfunction

private function CUI_EscapeAction takes nothing returns nothing
    call CUI_StopQueryForPlayer(GetTriggerPlayer(), true)
endfunction

private function CUI_CloseAction takes nothing returns nothing
    set CUI_QueryAfterCraft[GetPlayerId(GetTriggerPlayer())] = false
    call CUI_HideForPlayer(GetTriggerPlayer())
endfunction

private function CUI_ReturnAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)

    if CUI_IsSubcategoryMode(pid) then
        set CUI_SelectedCategory[pid] = ""
        set CUI_SelectedSubcategory[pid] = ""
        set CUI_ViewMode[pid] = CUI_VIEW_ROOT
        set CUI_SelectedRecipe[pid] = 0
        set CUI_ListStart[pid] = 0
        call CUI_RebuildEntryCache(pid)
        call CUI_UpdateForPlayer(p)
    elseif CUI_GetSelectedSubcategory(pid) != "" then
        set CUI_SelectedSubcategory[pid] = ""
        set CUI_ViewMode[pid] = CUI_VIEW_SUBCATEGORIES
        set CUI_SelectedRecipe[pid] = 0
        set CUI_ListStart[pid] = 0
        call CUI_RebuildEntryCache(pid)
        call CUI_UpdateForPlayer(p)
    elseif CUI_GetSelectedCategory(pid) != "" and CUI_UsesCategoryRoot(pid) then
        set CUI_SelectedCategory[pid] = ""
        set CUI_ViewMode[pid] = CUI_VIEW_ROOT
        set CUI_SelectedRecipe[pid] = 0
        set CUI_ListStart[pid] = 0
        call CUI_RebuildEntryCache(pid)
        call CUI_UpdateForPlayer(p)
    else
        set CUI_QueryAfterCraft[pid] = false
        call CUI_HideForPlayer(p)
        call MasterUI_Show()
    endif
    set p = null
endfunction

private function CUI_RowAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = CUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
    local integer recipeId
    local integer previousRecipeId
    local string categoryName
    local string subcategoryName

    if CUI_IsCategoryMode(pid) then
        set categoryName = CUI_GetEntryName(pid, CUI_ListStart[pid] + rowIndex)
        if categoryName != "" then
            set CUI_SelectedCategory[pid] = categoryName
            set CUI_SelectedSubcategory[pid] = ""
            set CUI_SelectedRecipe[pid] = 0
            set CUI_ListStart[pid] = 0
            if CUI_GetSubcategoryCount(pid) > 0 then
                set CUI_ViewMode[pid] = CUI_VIEW_SUBCATEGORIES
            else
                set CUI_ViewMode[pid] = CUI_VIEW_RECIPES
            endif
            call CUI_RebuildEntryCache(pid)
            call CUI_SelectFirstRecipeForCurrentPath(pid)
            call CUI_UpdateForPlayer(p)
        endif
    elseif CUI_IsSubcategoryMode(pid) then
        set subcategoryName = CUI_GetEntryName(pid, CUI_ListStart[pid] + rowIndex)
        if subcategoryName != "" then
            set CUI_SelectedSubcategory[pid] = subcategoryName
            set CUI_ViewMode[pid] = CUI_VIEW_RECIPES
            set CUI_ListStart[pid] = 0
            call CUI_RebuildEntryCache(pid)
            call CUI_SelectFirstRecipeForCurrentPath(pid)
            call CUI_UpdateForPlayer(p)
        endif
    else
        set recipeId = CUI_GetRecipeIdForListIndex(pid, CUI_ListStart[pid] + rowIndex)
        if recipeId != 0 then
            set previousRecipeId = CUI_SelectedRecipe[pid]
            set CUI_SelectedRecipe[pid] = recipeId
            call CUI_UpdateRecipeSelection(p, previousRecipeId)
        endif
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
        if CUI_IsCategoryMode(pid) or CUI_IsSubcategoryMode(pid) then
            set CUI_SelectedRecipe[pid] = 0
        else
            set CUI_SelectedRecipe[pid] = CUI_GetRecipeIdForListIndex(pid, CUI_ListStart[pid] + 1)
        endif
        call CUI_UpdateForPlayer(p)
    endif

    set p = null
endfunction

private function CUI_NextAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer maxStart = CUI_GetMaxListStart(CUI_GetRecipeTotal(pid))

    if CUI_ListStart[pid] < maxStart then
        set CUI_ListStart[pid] = CUI_ListStart[pid] + CUI_VISIBLE_ROWS
        if CUI_ListStart[pid] > maxStart then
            set CUI_ListStart[pid] = maxStart
        endif
        if CUI_IsCategoryMode(pid) or CUI_IsSubcategoryMode(pid) then
            set CUI_SelectedRecipe[pid] = 0
        else
            set CUI_SelectedRecipe[pid] = CUI_GetRecipeIdForListIndex(pid, CUI_ListStart[pid] + 1)
        endif
        call CUI_UpdateForPlayer(p)
    endif

    set p = null
endfunction

private function CUI_CraftAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)

    if not CUI_IsCategoryMode(pid) and not CUI_IsSubcategoryMode(pid) and CUI_SelectedRecipe[pid] != 0 then
        if Professions_StartRecipe(CUI_Crafter[pid], CUI_Station[pid], CUI_SelectedRecipe[pid]) then
            set CUI_ReopenAfterCraft[pid] = true
            set CUI_QueryAfterCraft[pid] = false
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

private function CUI_QueryAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)

    if not CUI_IsCategoryMode(pid) and not CUI_IsSubcategoryMode(pid) and CUI_SelectedRecipe[pid] != 0 then
        if Professions_StartRecipe(CUI_Crafter[pid], CUI_Station[pid], CUI_SelectedRecipe[pid]) then
            set CUI_ReopenAfterCraft[pid] = true
            set CUI_QueryAfterCraft[pid] = true
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, p)
            call DisplayTextToPlayer(p, 0.00, 0.00, QueryStartText)
            call CUI_HideForPlayer(p)
            call ExecuteFunc("ProfessionsUI_Refresh")
        else
            set CUI_QueryAfterCraft[pid] = false
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

    set crafter = CUI_GetNearestTrackedHero(p, station)
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
    local real rowTopOffset = -0.006

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
    call BlzFrameSetSize(CUI_StationText, 0.460, 0.014)
    call BlzFrameSetTextAlignment(CUI_StationText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_StationText, false)

    set CUI_LeftPane = BlzCreateFrameByType("BACKDROP", "CraftingUILeftPane", CUI_Parent, "", 0)
    call BlzFrameSetTexture(CUI_LeftPane, PanelTexture, 0, true)
    call BlzFrameSetPoint(CUI_LeftPane, FRAMEPOINT_TOPLEFT, CUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.088)
    call BlzFrameSetPoint(CUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.228, 0.052)
    call BlzFrameSetLevel(CUI_LeftPane, 1)

    set CUI_RightPane = BlzCreateFrameByType("BACKDROP", "CraftingUIRightPane", CUI_Parent, "", 0)
    call BlzFrameSetTexture(CUI_RightPane, PanelTexture, 0, true)
    call BlzFrameSetPoint(CUI_RightPane, FRAMEPOINT_TOPLEFT, CUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
    call BlzFrameSetPoint(CUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.052)
    call BlzFrameSetLevel(CUI_RightPane, 1)

    loop
        exitwhen rowIndex > CUI_VISIBLE_ROWS
        set CUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "CraftingUIRowButton" + I2S(rowIndex), CUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetPoint(CUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, CUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
        call BlzFrameSetSize(CUI_RowButton[rowIndex], 0.202, CUI_ROW_HEIGHT)
        call BlzFrameSetLevel(CUI_RowButton[rowIndex], 3)
        call BlzFrameSetVisible(CUI_RowButton[rowIndex], false)
        call BlzTriggerRegisterFrameEvent(CUI_RowTrigger, CUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        set CUI_ButtonRow.integer[GetHandleId(CUI_RowButton[rowIndex])] = rowIndex

        set CUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "CraftingUIRowIcon" + I2S(rowIndex), CUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(CUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, CUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
        call BlzFrameSetSize(CUI_RowIcon[rowIndex], 0.018, 0.018)
        call BlzFrameSetLevel(CUI_RowIcon[rowIndex], 4)

        set CUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "CraftingUIRowText" + I2S(rowIndex), CUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(CUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, CUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.030, -0.002)
        call BlzFrameSetPoint(CUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, CUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.052, 0.002)
        call BlzFrameSetTextAlignment(CUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(CUI_RowText[rowIndex], 0.88)
        call BlzFrameSetEnable(CUI_RowText[rowIndex], false)
        call BlzFrameSetLevel(CUI_RowText[rowIndex], 4)

        set CUI_RowState[rowIndex] = BlzCreateFrameByType("TEXT", "CraftingUIRowState" + I2S(rowIndex), CUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(CUI_RowState[rowIndex], FRAMEPOINT_TOPRIGHT, CUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.002)
        call BlzFrameSetPoint(CUI_RowState[rowIndex], FRAMEPOINT_BOTTOMRIGHT, CUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.002)
        call BlzFrameSetTextAlignment(CUI_RowState[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetScale(CUI_RowState[rowIndex], 0.80)
        call BlzFrameSetEnable(CUI_RowState[rowIndex], false)
        call BlzFrameSetLevel(CUI_RowState[rowIndex], 4)

        set CUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "CraftingUIRowHighlight" + I2S(rowIndex), CUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetAllPoints(CUI_RowHighlight[rowIndex], CUI_RowButton[rowIndex])
        call BlzFrameSetModel(CUI_RowHighlight[rowIndex], "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx", 0)
        call BlzFrameSetScale(CUI_RowHighlight[rowIndex], 0.76)
        call BlzFrameSetVisible(CUI_RowHighlight[rowIndex], false)
        call BlzFrameSetEnable(CUI_RowHighlight[rowIndex], false)
        call BlzFrameSetLevel(CUI_RowHighlight[rowIndex], 5)

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
    call BlzFrameSetLevel(CUI_DetailIcon, 4)

    set CUI_DetailTitle = BlzCreateFrameByType("TEXT", "CraftingUIDetailTitle", CUI_RightPane, "", 0)
    call BlzFrameSetPoint(CUI_DetailTitle, FRAMEPOINT_TOPLEFT, CUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
    call BlzFrameSetSize(CUI_DetailTitle, 0.245, 0.018)
    call BlzFrameSetTextAlignment(CUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(CUI_DetailTitle, 1.05)
    call BlzFrameSetEnable(CUI_DetailTitle, false)
    call BlzFrameSetLevel(CUI_DetailTitle, 5)

    set CUI_DetailInfo = BlzCreateFrameByType("TEXT", "CraftingUIDetailInfo", CUI_RightPane, "", 0)
    call BlzFrameSetPoint(CUI_DetailInfo, FRAMEPOINT_TOPLEFT, CUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
    call BlzFrameSetSize(CUI_DetailInfo, 0.245, 0.014)
    call BlzFrameSetTextAlignment(CUI_DetailInfo, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(CUI_DetailInfo, false)
    call BlzFrameSetLevel(CUI_DetailInfo, 5)

    set CUI_DetailBody = BlzCreateFrameByType("TEXT", "CraftingUIDetailBody", CUI_RightPane, "", 0)
    call BlzFrameSetPoint(CUI_DetailBody, FRAMEPOINT_TOPLEFT, CUI_DetailIcon, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.018)
    call BlzFrameSetPoint(CUI_DetailBody, FRAMEPOINT_BOTTOMRIGHT, CUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
    call BlzFrameSetTextAlignment(CUI_DetailBody, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(CUI_DetailBody, 0.90)
    call BlzFrameSetEnable(CUI_DetailBody, false)
    call BlzFrameSetLevel(CUI_DetailBody, 5)

    set CUI_CraftButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CraftingUICraft", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_CraftButton, 0.100, 0.032)
    call BlzFrameSetText(CUI_CraftButton, "Craft")

    set CUI_QueryButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CraftingUIQuery", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_QueryButton, 0.100, 0.032)
    call BlzFrameSetText(CUI_QueryButton, "Query")
    call BlzFrameSetPoint(CUI_QueryButton, FRAMEPOINT_BOTTOMRIGHT, CUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.024, 0.030)
    call BlzFrameSetPoint(CUI_CraftButton, FRAMEPOINT_BOTTOMRIGHT, CUI_QueryButton, FRAMEPOINT_BOTTOMLEFT, -0.010, 0.000)

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
    call BlzTriggerRegisterFrameEvent(CUI_QueryTrigger, CUI_QueryButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_QueryButton, FRAMEEVENT_CONTROL_CLICK)

    call BlzFrameSetVisible(CUI_Parent, false)
endfunction

public function Hide takes nothing returns nothing
    if CUI_Parent != null then
        call BlzFrameSetVisible(CUI_Parent, false)
    endif
endfunction

public function TryContinueQueryCraft takes nothing returns nothing
    local integer playerIndex = 0
    local integer recipeId
    local boolean started = false

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS or started
        if CUI_ReopenAfterCraft[playerIndex] and CUI_QueryAfterCraft[playerIndex] and CUI_Station[playerIndex] != null and CUI_Crafter[playerIndex] != null then
            set recipeId = CUI_SelectedRecipe[playerIndex]
            if recipeId != 0 and Professions_CanStartRecipe(CUI_Crafter[playerIndex], CUI_Station[playerIndex], recipeId) then
                if Professions_StartRecipeContinuation(CUI_Crafter[playerIndex], CUI_Station[playerIndex], recipeId) then
                    set CUI_ReopenAfterCraft[playerIndex] = true
                    set started = true
                    call ExecuteFunc("ProfessionsUI_Refresh")
                else
                    set CUI_QueryAfterCraft[playerIndex] = false
                endif
            endif
        endif
        set playerIndex = playerIndex + 1
    endloop
endfunction

public function ReopenAfterCraft takes nothing returns nothing
    local integer playerIndex = 0

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        if CUI_ReopenAfterCraft[playerIndex] and CUI_Station[playerIndex] != null and CUI_Crafter[playerIndex] != null then
            set CUI_ReopenAfterCraft[playerIndex] = false
            set CUI_QueryAfterCraft[playerIndex] = false
            call CUI_OpenForPlayerEx(Player(playerIndex), CUI_Station[playerIndex], CUI_Crafter[playerIndex], CUI_SelectedCategory[playerIndex], CUI_SelectedSubcategory[playerIndex])
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
    if not CUI_IsValidCrafterCandidateForPlayer(GetOwningPlayer(crafter), crafter) then
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

    set CUI_QueryTrigger = CreateTrigger()
    call TriggerAddAction(CUI_QueryTrigger, function CUI_QueryAction)

    set CUI_EscapeTrigger = CreateTrigger()
    set playerIndex = 0
    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call BlzTriggerRegisterPlayerKeyEvent(CUI_EscapeTrigger, Player(playerIndex), OSKEY_ESCAPE, 0, true)
        call TriggerRegisterPlayerEvent(CUI_EscapeTrigger, Player(playerIndex), EVENT_PLAYER_END_CINEMATIC)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(CUI_EscapeTrigger, function CUI_EscapeAction)

    set CUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ClearFocusTrigger, function CUI_ClearFocusAction)

    call CUI_CreateFrames()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
