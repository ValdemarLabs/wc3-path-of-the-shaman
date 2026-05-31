library AbilitiesLiteUI initializer AutoInit requires Table, MasterUI
/**
    AbilitiesLiteUI

    Author: [Valdemar]
    Version: 1.0

    Description: Shows a selected unit's hardcoded ability list with a simple detail panel and tooltip text.

    Credits: Tasyen (TasQuestBox as inspiration)

**/

globals
    private constant integer AUI_MAX_ROWS = 8
    private constant integer AUI_VISIBLE_ROWS = 6
    private constant integer AUI_MAX_DEFINITIONS = 128
    private constant integer AUI_COMPANION_SHAMAN_TYPE = '061H'         // match this with shaman unit-type (Restoration Shaman)
    private constant integer AUI_KEY_PLAYER_SHAMAN = 900001
    private constant integer AUI_KEY_COMPANION_SHAMAN = 900002
    private constant integer AUI_ABILITY_LIGHTNING_BOLT = 'A61Q'
    private constant integer AUI_ABILITY_HEALING_WAVE = 'A62M'
    private constant integer AUI_ABILITY_STORMSTRIKE = 'A685'
    private constant integer AUI_ABILITY_STONESKIN_TOTEM = 'A68J'
    private constant real AUI_DETAIL_BODY_WIDTH = 0.262
    private constant real AUI_DETAIL_BODY_HEIGHT = 0.170
    private constant integer AUI_MODE_AUTO = 1
    private constant integer AUI_MODE_MANUAL = 2
    private constant boolean AUI_SHOW_PLAYER_LEARN_STATE = true

    private boolean AUI_Initialized = false
    private boolean AUI_SyncingListScroll = false
    private framehandle AUI_Parent = null
    private framehandle AUI_MainBackdrop = null
    private framehandle AUI_Title = null
    private framehandle AUI_ViewingText = null
    private framehandle AUI_LeftPane = null
    private framehandle AUI_RightPane = null
    private framehandle AUI_CloseButton = null
    private framehandle AUI_ReturnButton = null
    private framehandle AUI_DetailIcon = null
    private framehandle AUI_DetailTitle = null
    private framehandle AUI_DetailInfoBackdrop = null
    private framehandle AUI_DetailInfoText = null
    private framehandle AUI_DetailBodyText = null
    private framehandle AUI_ListScroll = null

    private framehandle array AUI_RowButton
    private framehandle array AUI_RowIcon
    private framehandle array AUI_RowText
    private framehandle array AUI_RowLevel
    private framehandle array AUI_RowHighlight

    private integer AUI_DefinitionCount = 0
    private integer array AUI_DefinitionUnitTypeId
    private integer array AUI_DefinitionAbilityId
    private integer array AUI_DefinitionLearnAbilityId
    private integer array AUI_DefinitionMode
    private string array AUI_DefinitionIconPath
    private string array AUI_DefinitionTitleOverride
    private string array AUI_DefinitionInfoOverride
    private string array AUI_DefinitionBodyOverride

    private integer array AUI_RowDefinitionIndex
    private integer array AUI_RowHighlightVisible
    private integer AUI_SelectedDefinition = 0
    private integer AUI_ListScrollValue = 0
    private integer AUI_DetailBodyHash = 0
    private string AUI_DetailBodyCache = ""
    private unit AUI_SelectedUnit = null

    private Table AUI_ButtonRow = 0

    private trigger AUI_CloseTrigger = null
    private trigger AUI_ReturnTrigger = null
    private trigger AUI_RowTrigger = null
    private trigger AUI_ClearFocusTrigger = null
    private trigger AUI_ListScrollTrigger = null
    private trigger AUI_WheelTrigger = null

    private string AUI_TitleText = "|cffffe4a3Abilities|r"
    private string AUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private string AUI_DefaultIcon = "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    private string AUI_RowHighlightModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
    private string AUI_NoUnitText = "No unit selected."
    private string AUI_NoAbilitiesText = "No abilities are configured for this unit type yet."
    private string AUI_NotLearnedText = "|cff808080Not learned|r"
endglobals

private function AUI_GetViewerName takes unit u returns string
    if u == null or GetHandleId(u) == 0 then
        return "No unit"
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHeroProperName(u)
    endif
    return GetUnitName(u)
endfunction

private function AUI_GetUnitIconPath takes unit u returns string
    local string iconPath

    if u == null or GetHandleId(u) == 0 then
        return AUI_DefaultIcon
    endif

    set iconPath = BlzGetAbilityIcon(GetUnitTypeId(u))
    if iconPath == null or iconPath == "" then
        return AUI_DefaultIcon
    endif
    return iconPath
endfunction

private function AUI_IsPlayerOwnedMainHero takes unit u returns boolean
    return u != null and GetHandleId(u) != 0 and GetOwningPlayer(u) == Player(0)
endfunction

private function AUI_IsTrackedUnit takes unit u returns boolean
    local integer i = 1

    if u == null or GetHandleId(u) == 0 then
        return false
    endif
    if u == udg_Nazgrek or u == udg_Zulkis then
        return AUI_IsPlayerOwnedMainHero(u)
    endif
    if u == udg_TamedUnit then
        return true
    endif

    loop
        exitwhen i > udg_CompanionCount
        if udg_CompanionUnit[i] == u then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

private function AUI_AddDefinition takes integer mode, integer unitTypeId, integer abilityId, integer learnAbilityId, string iconPath, string titleText, string infoText, string bodyText returns nothing
    if AUI_DefinitionCount >= AUI_MAX_DEFINITIONS then
        return
    endif

    set AUI_DefinitionCount = AUI_DefinitionCount + 1
    set AUI_DefinitionMode[AUI_DefinitionCount] = mode
    set AUI_DefinitionUnitTypeId[AUI_DefinitionCount] = unitTypeId
    set AUI_DefinitionAbilityId[AUI_DefinitionCount] = abilityId
    set AUI_DefinitionLearnAbilityId[AUI_DefinitionCount] = learnAbilityId
    set AUI_DefinitionIconPath[AUI_DefinitionCount] = iconPath
    set AUI_DefinitionTitleOverride[AUI_DefinitionCount] = titleText
    set AUI_DefinitionInfoOverride[AUI_DefinitionCount] = infoText
    set AUI_DefinitionBodyOverride[AUI_DefinitionCount] = bodyText
endfunction

public function RegisterAbilityForUnitTypeAuto takes integer unitTypeId, integer abilityId, string titleOverride, string bodyOverride returns nothing
    call AUI_AddDefinition(AUI_MODE_AUTO, unitTypeId, abilityId, abilityId, "", titleOverride, "", bodyOverride)
endfunction

public function RegisterAbilityForUnitTypeManual takes integer unitTypeId, string iconPath, string titleText, string bodyText returns nothing
    call AUI_AddDefinition(AUI_MODE_MANUAL, unitTypeId, 0, 0, iconPath, titleText, "", bodyText)
endfunction

public function RegisterAbilityForUnitTypeManualEx takes integer unitTypeId, string iconPath, string titleText, string infoText, string bodyText returns nothing
    call AUI_AddDefinition(AUI_MODE_MANUAL, unitTypeId, 0, 0, iconPath, titleText, infoText, bodyText)
endfunction

public function RegisterAbilityForUnitTypeManualLearnEx takes integer unitTypeId, integer learnAbilityId, string titleText, string infoText, string bodyText returns nothing
    call AUI_AddDefinition(AUI_MODE_MANUAL, unitTypeId, 0, learnAbilityId, "", titleText, infoText, bodyText)
endfunction

private function AUI_HasManualDefinition takes integer unitTypeId, string titleText returns boolean
    local integer i = 1

    loop
        exitwhen i > AUI_DefinitionCount
        if AUI_DefinitionUnitTypeId[i] == unitTypeId and AUI_DefinitionMode[i] == AUI_MODE_MANUAL and AUI_DefinitionTitleOverride[i] == titleText then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

private function AUI_ColorizeShamanSpec takes string specText returns string
    if specText == "Elemental" then
        return "|cff69ccf0" + specText + "|r"
    elseif specText == "Enhancement" then
        return "|cffc79c6e" + specText + "|r"
    elseif specText == "Restoration" then
        return "|cff00ff96" + specText + "|r"
    elseif specText == "Totemic" then
        return "|cffd9b56d" + specText + "|r"
    endif
    return "|cffbfbfbf" + specText + "|r"
endfunction

private function AUI_RegisterTemplateManualIfMissing takes integer definitionKey, string iconPath, string titleText, string infoText, string bodyText returns nothing
    if not AUI_HasManualDefinition(definitionKey, titleText) then
        call RegisterAbilityForUnitTypeManualEx(definitionKey, iconPath, titleText, infoText, bodyText)
    endif
endfunction

private function AUI_RegisterTemplateManualLearnIfMissing takes integer definitionKey, integer learnAbilityId, string titleText, string infoText, string bodyText returns nothing
    if not AUI_HasManualDefinition(definitionKey, titleText) then
        call RegisterAbilityForUnitTypeManualLearnEx(definitionKey, learnAbilityId, titleText, infoText, bodyText)
    endif
endfunction

private function AUI_RegisterPlayerShamanTemplates takes nothing returns nothing
    local string infoText
    local string bodyText

    if AUI_KEY_PLAYER_SHAMAN == 0 then
        return
    endif

    set infoText = "|cff0070deShaman|r |cff808080/|r " + AUI_ColorizeShamanSpec("Elemental")
    set bodyText = "|cffffcc00Role:|r Direct ranged spell damage|n|nCalls down a bolt of lightning to strike a single enemy target.|nDeals base damage plus heavy Intelligence scaling, making it a reliable single-target finisher for a shaman caster."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_PLAYER_SHAMAN, AUI_ABILITY_LIGHTNING_BOLT, "Lightning Bolt", infoText, bodyText)

    set infoText = "|cff0070deShaman|r |cff808080/|r " + AUI_ColorizeShamanSpec("Enhancement")
    set bodyText = "|cffffcc00Role:|r Melee burst attack|n|nEnergizes the shaman's weapons with lightning and delivers a heavy melee blow.|nBest used when committing to close-range pressure and fast follow-up damage."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_PLAYER_SHAMAN, AUI_ABILITY_STORMSTRIKE, "Stormstrike", infoText, bodyText)

    set infoText = "|cff0070deShaman|r |cff808080/|r " + AUI_ColorizeShamanSpec("Restoration")
    set bodyText = "|cffffcc00Role:|r Direct single-target healing|n|nA reliable healing spell that restores a strong amount of health to one ally.|nThis is the straightforward answer when the group needs quick focused recovery."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_PLAYER_SHAMAN, AUI_ABILITY_HEALING_WAVE, "Healing Wave", infoText, bodyText)

    set infoText = "|cff0070deShaman|r |cff808080/|r " + AUI_ColorizeShamanSpec("Totemic")
    set bodyText = "|cffffcc00Role:|r Defensive support totem|n|nSummons a Stoneskin Totem that hardens nearby allies and increases their armor.|nUseful before sustained pressure, pulls, or any fight where the party expects repeated incoming damage."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_PLAYER_SHAMAN, AUI_ABILITY_STONESKIN_TOTEM, "Stoneskin Totem", infoText, bodyText)
endfunction

private function AUI_RegisterCompanionShamanTemplates takes nothing returns nothing
    local string bodyText

    if AUI_KEY_COMPANION_SHAMAN == 0 then
        return
    endif

    set bodyText = "Calls down lightning on a single enemy target."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_COMPANION_SHAMAN, AUI_ABILITY_LIGHTNING_BOLT, "Lightning Bolt", "|cff9fd3ffCompanion Ability|r", bodyText)

    set bodyText = "Empowers the next melee strike with storm power for stronger close-range damage."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_COMPANION_SHAMAN, AUI_ABILITY_STORMSTRIKE, "Stormstrike", "|cff9fd3ffCompanion Ability|r", bodyText)

    set bodyText = "Restores health to one nearby ally."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_COMPANION_SHAMAN, AUI_ABILITY_HEALING_WAVE, "Healing Wave", "|cff9fd3ffCompanion Ability|r", bodyText)

    set bodyText = "Drops a defensive totem that helps nearby allies endure incoming damage."
    call AUI_RegisterTemplateManualLearnIfMissing(AUI_KEY_COMPANION_SHAMAN, AUI_ABILITY_STONESKIN_TOTEM, "Stoneskin Totem", "|cff9fd3ffCompanion Ability|r", bodyText)
endfunction

private function AUI_GetDefinitionKeyForUnit takes unit u returns integer
    local integer unitTypeId

    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    if u == udg_Nazgrek or u == udg_Zulkis then
        return AUI_KEY_PLAYER_SHAMAN
    endif

    set unitTypeId = GetUnitTypeId(u)
    if unitTypeId == AUI_COMPANION_SHAMAN_TYPE then
        return AUI_KEY_COMPANION_SHAMAN
    endif
    return unitTypeId
endfunction

private function AUI_EnsureTemplatesForUnit takes unit u returns nothing
    local integer definitionKey

    if u == null or GetHandleId(u) == 0 then
        return
    endif

    set definitionKey = AUI_GetDefinitionKeyForUnit(u)
    if definitionKey == 0 then
        return
    endif

    if u == udg_Nazgrek or u == udg_Zulkis then
        call AUI_RegisterPlayerShamanTemplates()
    elseif definitionKey == AUI_KEY_COMPANION_SHAMAN then
        call AUI_RegisterCompanionShamanTemplates()
    endif
endfunction

private function AUI_ResetViewState takes nothing returns nothing
    set AUI_SelectedDefinition = 0
    set AUI_ListScrollValue = 0
    set AUI_DetailBodyHash = 0
    set AUI_DetailBodyCache = ""
endfunction

private function AUI_GetActiveDefinitionKey takes nothing returns integer
    return AUI_GetDefinitionKeyForUnit(AUI_SelectedUnit)
endfunction

private function AUI_GetDefinitionCountForUnitType takes integer unitTypeId returns integer
    local integer i = 1
    local integer count = 0

    loop
        exitwhen i > AUI_DefinitionCount
        if AUI_DefinitionUnitTypeId[i] == unitTypeId then
            set count = count + 1
        endif
        set i = i + 1
    endloop

    return count
endfunction

private function AUI_GetDefinitionByFilteredIndex takes integer unitTypeId, integer filteredIndex returns integer
    local integer i = 1
    local integer count = 0

    if filteredIndex < 1 then
        return 0
    endif

    loop
        exitwhen i > AUI_DefinitionCount
        if AUI_DefinitionUnitTypeId[i] == unitTypeId then
            set count = count + 1
            if count == filteredIndex then
                return i
            endif
        endif
        set i = i + 1
    endloop

    return 0
endfunction

private function AUI_GetFilteredIndexForDefinition takes integer unitTypeId, integer definitionIndex returns integer
    local integer i = 1
    local integer count = 0

    loop
        exitwhen i > AUI_DefinitionCount
        if AUI_DefinitionUnitTypeId[i] == unitTypeId then
            set count = count + 1
            if i == definitionIndex then
                return count
            endif
        endif
        set i = i + 1
    endloop

    return 0
endfunction

private function AUI_GetFirstDefinitionForUnitType takes integer unitTypeId returns integer
    return AUI_GetDefinitionByFilteredIndex(unitTypeId, 1)
endfunction

private function AUI_GetDefinitionIcon takes integer definitionIndex returns string
    local integer abilityId = AUI_DefinitionAbilityId[definitionIndex]
    local string iconPath

    if AUI_DefinitionIconPath[definitionIndex] != null and AUI_DefinitionIconPath[definitionIndex] != "" then
        return AUI_DefinitionIconPath[definitionIndex]
    endif

    if abilityId == 0 then
        set abilityId = AUI_DefinitionLearnAbilityId[definitionIndex]
    endif
    if abilityId != 0 then
        set iconPath = BlzGetAbilityIcon(abilityId)
        if iconPath != null and iconPath != "" then
            return iconPath
        endif
    endif

    return AUI_DefaultIcon
endfunction

private function AUI_GetDefinitionTitle takes integer definitionIndex returns string
    local integer abilityId = AUI_DefinitionAbilityId[definitionIndex]
    local string titleText = AUI_DefinitionTitleOverride[definitionIndex]

    if titleText != null and titleText != "" then
        return titleText
    endif

    if abilityId != 0 then
        set titleText = GetObjectName(abilityId)
        if titleText != null and titleText != "" then
            return titleText
        endif
        set titleText = BlzGetAbilityTooltip(abilityId, 0)
        if titleText != null and titleText != "" then
            return titleText
        endif
    endif

    return "Ability"
endfunction

private function AUI_GetDefinitionLearnAbilityId takes integer definitionIndex returns integer
    if AUI_DefinitionLearnAbilityId[definitionIndex] != 0 then
        return AUI_DefinitionLearnAbilityId[definitionIndex]
    endif
    return AUI_DefinitionAbilityId[definitionIndex]
endfunction

private function AUI_ShouldShowNotLearned takes unit u, integer definitionIndex returns boolean
    local integer abilityId

    if not AUI_SHOW_PLAYER_LEARN_STATE or not AUI_IsPlayerOwnedMainHero(u) or (u != udg_Nazgrek and u != udg_Zulkis) then
        return false
    endif

    set abilityId = AUI_GetDefinitionLearnAbilityId(definitionIndex)
    return abilityId != 0 and GetUnitAbilityLevel(u, abilityId) <= 0
endfunction

private function AUI_GetDefinitionLevelText takes unit u, integer definitionIndex returns string
    local integer abilityId = AUI_DefinitionAbilityId[definitionIndex]
    local integer learnAbilityId = AUI_GetDefinitionLearnAbilityId(definitionIndex)
    local string infoText = AUI_DefinitionInfoOverride[definitionIndex]
    local integer level

    if AUI_ShouldShowNotLearned(u, definitionIndex) then
        if infoText != null and infoText != "" then
            return infoText + " |cff808080- Not learned|r"
        endif
        return AUI_NotLearnedText
    endif

    if abilityId != 0 and u != null and GetHandleId(u) != 0 then
        set level = GetUnitAbilityLevel(u, abilityId)
        if infoText != null and infoText != "" then
            if level > 0 then
                return infoText + " - Level " + I2S(level)
            endif
            return infoText
        endif
        if level > 0 then
            return "Level " + I2S(level)
        endif
        return "Object data"
    endif

    if learnAbilityId != 0 and u != null and GetHandleId(u) != 0 then
        set level = GetUnitAbilityLevel(u, learnAbilityId)
        if infoText != null and infoText != "" then
            if level > 0 then
                return infoText + " |cff808080-|r Level " + I2S(level)
            endif
            return infoText
        endif
        if level > 0 then
            return "Level " + I2S(level)
        endif
    endif

    if infoText != null and infoText != "" then
        return infoText
    endif
    if u != null and GetHandleId(u) != 0 then
        return AUI_GetViewerName(u)
    endif
    return ""
endfunction

private function AUI_GetDefinitionBody takes unit u, integer definitionIndex returns string
    local integer abilityId = AUI_DefinitionAbilityId[definitionIndex]
    local integer abilityLevel = 1
    local string bodyText = AUI_DefinitionBodyOverride[definitionIndex]
    local string tooltipText = ""
    local integer learnAbilityId = AUI_GetDefinitionLearnAbilityId(definitionIndex)

    if bodyText != null and bodyText != "" then
        return bodyText
    endif

    if abilityId == 0 then
        set abilityId = learnAbilityId
    endif
    if abilityId != 0 then
        if u != null and GetHandleId(u) != 0 then
            set abilityLevel = GetUnitAbilityLevel(u, abilityId)
            if abilityLevel < 1 then
                set abilityLevel = 1
            endif
        endif

        set tooltipText = BlzGetAbilityExtendedTooltip(abilityId, abilityLevel - 1)
        if tooltipText == null or tooltipText == "" then
            set tooltipText = BlzGetAbilityTooltip(abilityId, abilityLevel - 1)
        endif
        if tooltipText == null or tooltipText == "" then
            set tooltipText = "No description configured yet."
        endif

        if u != null and GetHandleId(u) != 0 and GetUnitAbilityLevel(u, abilityId) > 0 then
            return "|cffffcc00Level:|r " + I2S(GetUnitAbilityLevel(u, abilityId)) + "|n|n" + tooltipText
        endif
        return tooltipText
    endif

    return "No description configured yet."
endfunction

private function AUI_WrapBodyText takes string text returns string
    local integer i = 0
    local integer length = StringLength(text)
    local integer lineChars = 0
    local string result = ""
    local string token
    local string activeColor = ""
    local string word = ""
    local integer wordChars = 0
    local boolean pendingSpace = false
    local integer wrapChars = 31

    loop
        exitwhen i >= length
        if i + 1 < length and SubString(text, i, i + 2) == "|n" then
            if wordChars > 0 then
                if lineChars > 0 and lineChars + wordChars + 1 > wrapChars and pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                    set pendingSpace = false
                elseif lineChars > 0 and lineChars + wordChars > wrapChars and not pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                endif
                if pendingSpace and lineChars > 0 then
                    set result = result + " "
                    set lineChars = lineChars + 1
                endif
                set result = result + word
                set lineChars = lineChars + wordChars
                set word = ""
                set wordChars = 0
                set pendingSpace = false
            endif
            set result = result + "|n"
            set lineChars = 0
            set i = i + 2
            if activeColor != "" then
                set result = result + activeColor
            endif
        elseif i + 1 < length and SubString(text, i, i + 2) == "|r" then
            if wordChars > 0 then
                if lineChars > 0 and lineChars + wordChars + 1 > wrapChars and pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                    set pendingSpace = false
                elseif lineChars > 0 and lineChars + wordChars > wrapChars and not pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                endif
                if pendingSpace and lineChars > 0 then
                    set result = result + " "
                    set lineChars = lineChars + 1
                endif
                set result = result + word
                set lineChars = lineChars + wordChars
                set word = ""
                set wordChars = 0
                set pendingSpace = false
            endif
            set result = result + "|r"
            set activeColor = ""
            set i = i + 2
        elseif i + 9 < length and SubString(text, i, i + 2) == "|c" then
            set token = SubString(text, i, i + 10)
            set activeColor = token
            set result = result + token
            set i = i + 10
        else
            set token = SubString(text, i, i + 1)
            if token == " " then
                if wordChars > 0 then
                    if lineChars > 0 and lineChars + wordChars + 1 > wrapChars and pendingSpace then
                        set result = result + "|n"
                        set lineChars = 0
                        if activeColor != "" then
                            set result = result + activeColor
                        endif
                        set pendingSpace = false
                    elseif lineChars > 0 and lineChars + wordChars > wrapChars and not pendingSpace then
                        set result = result + "|n"
                        set lineChars = 0
                        if activeColor != "" then
                            set result = result + activeColor
                        endif
                    endif
                    if pendingSpace and lineChars > 0 then
                        set result = result + " "
                        set lineChars = lineChars + 1
                    endif
                    set result = result + word
                    set lineChars = lineChars + wordChars
                    set word = ""
                    set wordChars = 0
                endif
                set pendingSpace = lineChars > 0
            else
                if wordChars == 0 and pendingSpace and lineChars >= wrapChars then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                    set pendingSpace = false
                endif
                if wordChars > 0 and lineChars == 0 and wordChars >= wrapChars then
                    set result = result + word + token
                    set lineChars = wordChars + 1
                    set word = ""
                    set wordChars = 0
                else
                    set word = word + token
                    set wordChars = wordChars + 1
                endif
            endif
            set i = i + 1
        endif
    endloop

    if wordChars > 0 then
        if lineChars > 0 and lineChars + wordChars + 1 > wrapChars and pendingSpace then
            set result = result + "|n"
            set lineChars = 0
            if activeColor != "" then
                set result = result + activeColor
            endif
            set pendingSpace = false
        elseif lineChars > 0 and lineChars + wordChars > wrapChars and not pendingSpace then
            set result = result + "|n"
            set lineChars = 0
            if activeColor != "" then
                set result = result + activeColor
            endif
        endif
        if pendingSpace and lineChars > 0 then
            set result = result + " "
        endif
        set result = result + word
    endif

    if activeColor != "" and StringLength(result) >= 2 and SubString(result, StringLength(result) - 2, StringLength(result)) != "|r" then
        set result = result + "|r"
    endif

    return result
endfunction

private function AUI_SetDetailBody takes string bodyText returns nothing
    local integer newHash
    local string wrappedText

    if bodyText == null or bodyText == "" then
        set bodyText = "No description configured yet."
    endif
    set wrappedText = AUI_WrapBodyText(bodyText)
    set newHash = StringHash(wrappedText)
    if AUI_DetailBodyHash != newHash or AUI_DetailBodyCache != wrappedText then
        set AUI_DetailBodyHash = newHash
        set AUI_DetailBodyCache = wrappedText
        call BlzFrameSetText(AUI_DetailBodyText, wrappedText)
    endif
endfunction

private function AUI_ClampSelection takes nothing returns nothing
    local integer unitTypeId = AUI_GetActiveDefinitionKey()
    local integer totalCount = AUI_GetDefinitionCountForUnitType(unitTypeId)
    local integer maxStart = totalCount - AUI_VISIBLE_ROWS
    local integer selectedFilteredIndex

    if maxStart < 0 then
        set maxStart = 0
    endif
    if AUI_ListScrollValue < 0 then
        set AUI_ListScrollValue = 0
    elseif AUI_ListScrollValue > maxStart then
        set AUI_ListScrollValue = maxStart
    endif

    if totalCount <= 0 then
        set AUI_SelectedDefinition = 0
        return
    endif

    if AUI_SelectedDefinition == 0 or AUI_DefinitionUnitTypeId[AUI_SelectedDefinition] != unitTypeId then
        set AUI_SelectedDefinition = AUI_GetFirstDefinitionForUnitType(unitTypeId)
    endif

    set selectedFilteredIndex = AUI_GetFilteredIndexForDefinition(unitTypeId, AUI_SelectedDefinition)
    if selectedFilteredIndex <= 0 then
        set AUI_SelectedDefinition = AUI_GetFirstDefinitionForUnitType(unitTypeId)
    endif
endfunction

private function AUI_UpdateRows takes nothing returns nothing
    local integer rowIndex = 1
    local integer unitTypeId = AUI_GetActiveDefinitionKey()
    local integer totalCount = AUI_GetDefinitionCountForUnitType(unitTypeId)
    local integer maxStart = totalCount - AUI_VISIBLE_ROWS
    local integer filteredIndex
    local integer definitionIndex
    local integer abilityLevel
    local integer learnAbilityId
    local integer selected
    local string levelText
    local string titleText

    if maxStart < 0 then
        set maxStart = 0
    endif

    loop
        exitwhen rowIndex > AUI_VISIBLE_ROWS
        set filteredIndex = AUI_ListScrollValue + rowIndex
        set definitionIndex = AUI_GetDefinitionByFilteredIndex(unitTypeId, filteredIndex)
        set AUI_RowDefinitionIndex[rowIndex] = definitionIndex
        if definitionIndex != 0 then
            set titleText = AUI_GetDefinitionTitle(definitionIndex)
            if AUI_ShouldShowNotLearned(AUI_SelectedUnit, definitionIndex) then
                set titleText = "|cff808080" + titleText + "|r"
                set levelText = AUI_NotLearnedText
            else
                set learnAbilityId = AUI_GetDefinitionLearnAbilityId(definitionIndex)
                if learnAbilityId != 0 and AUI_SelectedUnit != null and GetHandleId(AUI_SelectedUnit) != 0 then
                    set abilityLevel = GetUnitAbilityLevel(AUI_SelectedUnit, learnAbilityId)
                    if abilityLevel > 0 then
                        set levelText = "Lvl " + I2S(abilityLevel)
                    else
                        set levelText = ""
                    endif
                else
                    set levelText = ""
                endif
            endif

            call BlzFrameSetTexture(AUI_RowIcon[rowIndex], AUI_GetDefinitionIcon(definitionIndex), 0, true)
            call BlzFrameSetText(AUI_RowText[rowIndex], titleText)
            call BlzFrameSetText(AUI_RowLevel[rowIndex], levelText)
            call BlzFrameSetVisible(AUI_RowButton[rowIndex], true)

            if definitionIndex == AUI_SelectedDefinition then
                set selected = 1
            else
                set selected = 0
            endif
            if AUI_RowHighlightVisible[rowIndex] != selected then
                set AUI_RowHighlightVisible[rowIndex] = selected
                call BlzFrameSetVisible(AUI_RowHighlight[rowIndex], selected == 1)
            endif
        else
            set AUI_RowHighlightVisible[rowIndex] = 0
            call BlzFrameSetVisible(AUI_RowButton[rowIndex], false)
            call BlzFrameSetVisible(AUI_RowHighlight[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    loop
        exitwhen rowIndex > AUI_MAX_ROWS
        set AUI_RowDefinitionIndex[rowIndex] = 0
        set AUI_RowHighlightVisible[rowIndex] = 0
        call BlzFrameSetVisible(AUI_RowButton[rowIndex], false)
        call BlzFrameSetVisible(AUI_RowHighlight[rowIndex], false)
        set rowIndex = rowIndex + 1
    endloop

    if maxStart > 0 then
        set AUI_SyncingListScroll = true
        call BlzFrameSetMinMaxValue(AUI_ListScroll, 0.0, I2R(maxStart))
        call BlzFrameSetValue(AUI_ListScroll, I2R(AUI_ListScrollValue))
        set AUI_SyncingListScroll = false
    endif
    call BlzFrameSetVisible(AUI_ListScroll, maxStart > 0)
endfunction

private function AUI_UpdateDetail takes nothing returns nothing
    local integer definitionIndex = AUI_SelectedDefinition
    local string bodyText

    if AUI_SelectedUnit == null or GetHandleId(AUI_SelectedUnit) == 0 then
        call BlzFrameSetTexture(AUI_DetailIcon, AUI_DefaultIcon, 0, true)
        call BlzFrameSetText(AUI_DetailTitle, "No unit")
        call BlzFrameSetText(AUI_DetailInfoText, "")
        call AUI_SetDetailBody(AUI_NoUnitText)
        return
    endif

    if definitionIndex == 0 then
        call BlzFrameSetTexture(AUI_DetailIcon, AUI_GetUnitIconPath(AUI_SelectedUnit), 0, true)
        call BlzFrameSetText(AUI_DetailTitle, "No abilities")
        call BlzFrameSetText(AUI_DetailInfoText, AUI_GetViewerName(AUI_SelectedUnit))
        call AUI_SetDetailBody(AUI_NoAbilitiesText)
        return
    endif

    call BlzFrameSetTexture(AUI_DetailIcon, AUI_GetDefinitionIcon(definitionIndex), 0, true)
    if AUI_ShouldShowNotLearned(AUI_SelectedUnit, definitionIndex) then
        call BlzFrameSetText(AUI_DetailTitle, "|cff808080" + AUI_GetDefinitionTitle(definitionIndex) + "|r")
    else
        call BlzFrameSetText(AUI_DetailTitle, "|cffffe4a3" + AUI_GetDefinitionTitle(definitionIndex) + "|r")
    endif
    call BlzFrameSetText(AUI_DetailInfoText, AUI_GetDefinitionLevelText(AUI_SelectedUnit, definitionIndex))

    set bodyText = AUI_GetDefinitionBody(AUI_SelectedUnit, definitionIndex)
    call AUI_SetDetailBody(bodyText)
endfunction

private function AUI_Update takes nothing returns nothing
    if AUI_Parent == null then
        return
    endif

    call AUI_ClampSelection()
    call BlzFrameSetText(AUI_ViewingText, "Viewing: " + AUI_GetViewerName(AUI_SelectedUnit))
    call AUI_UpdateRows()
    call AUI_UpdateDetail()
endfunction

public function Hide takes nothing returns nothing
    if AUI_Parent != null then
        call BlzFrameSetVisible(AUI_Parent, false)
    endif
endfunction

private function AUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function AUI_CloseAction takes nothing returns nothing
    call Hide()
endfunction

private function AUI_ReturnAction takes nothing returns nothing
    call Hide()
    call ExecuteFunc("StatsUI_Show")
endfunction

private function AUI_RowAction takes nothing returns nothing
    local integer handleId = GetHandleId(BlzGetTriggerFrame())
    local integer rowIndex

    if AUI_ButtonRow.has(handleId) then
        set rowIndex = AUI_ButtonRow.integer[handleId]
        if rowIndex >= 1 and rowIndex <= AUI_MAX_ROWS and AUI_RowDefinitionIndex[rowIndex] != 0 then
            set AUI_SelectedDefinition = AUI_RowDefinitionIndex[rowIndex]
            set AUI_DetailBodyHash = 0
            call AUI_Update()
        endif
    endif
endfunction

private function AUI_ListScrollAction takes nothing returns nothing
    if AUI_SyncingListScroll then
        return
    endif
    set AUI_ListScrollValue = R2I(BlzGetTriggerFrameValue())
    call AUI_Update()
endfunction

private function AUI_WheelAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local real newValue

    if GetLocalPlayer() == GetTriggerPlayer() then
        if (triggerFrame == AUI_ListScroll or triggerFrame == AUI_LeftPane) and AUI_ListScroll != null and BlzFrameIsVisible(AUI_ListScroll) then
            if BlzGetTriggerFrameValue() > 0 then
                set newValue = BlzFrameGetValue(AUI_ListScroll) + 1.0
            else
                set newValue = BlzFrameGetValue(AUI_ListScroll) - 1.0
            endif
            if newValue < 0.0 then
                set newValue = 0.0
            endif
            call BlzFrameSetValue(AUI_ListScroll, newValue)
        endif
    endif
    set triggerFrame = null
endfunction

private function AUI_CreateFrames takes nothing returns nothing
    local integer rowIndex = 1
    local real rowTopOffset = -0.012
    local real rowHeight = 0.033
    local real rowGap = 0.003

    set AUI_Parent = BlzCreateFrameByType("BACKDROP", "AbilitiesLiteUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(AUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
    call BlzFrameSetAbsPoint(AUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.18)

    set AUI_MainBackdrop = BlzCreateFrameByType("BACKDROP", "AbilitiesLiteUIMainBackdrop", AUI_Parent, "", 0)
    call BlzFrameSetTexture(AUI_MainBackdrop, AUI_PanelTexture, 0, false)
    call BlzFrameSetPoint(AUI_MainBackdrop, FRAMEPOINT_TOPLEFT, AUI_Parent, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
    call BlzFrameSetPoint(AUI_MainBackdrop, FRAMEPOINT_BOTTOMRIGHT, AUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
    call BlzFrameSetAlpha(AUI_MainBackdrop, 255)
    call BlzFrameSetVertexColor(AUI_MainBackdrop, BlzConvertColor(255, 0, 0, 0))
    call BlzFrameSetEnable(AUI_MainBackdrop, false)

    set AUI_Title = BlzCreateFrameByType("TEXT", "AbilitiesLiteUITitle", AUI_Parent, "", 0)
    call BlzFrameSetPoint(AUI_Title, FRAMEPOINT_TOPLEFT, AUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(AUI_Title, 0.30, 0.018)
    call BlzFrameSetTextAlignment(AUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(AUI_Title, 1.10)
    call BlzFrameSetEnable(AUI_Title, false)
    call BlzFrameSetText(AUI_Title, AUI_TitleText)

    set AUI_ViewingText = BlzCreateFrameByType("TEXT", "AbilitiesLiteUIViewing", AUI_Parent, "", 0)
    call BlzFrameSetPoint(AUI_ViewingText, FRAMEPOINT_TOPLEFT, AUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.048)
    call BlzFrameSetSize(AUI_ViewingText, 0.42, 0.016)
    call BlzFrameSetTextAlignment(AUI_ViewingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(AUI_ViewingText, 0.96)
    call BlzFrameSetEnable(AUI_ViewingText, false)

    set AUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesLiteUIClose", AUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(AUI_CloseButton, 0.03, 0.03)
    call BlzFrameSetText(AUI_CloseButton, "X")
    call BlzFrameSetPoint(AUI_CloseButton, FRAMEPOINT_TOPRIGHT, AUI_Parent, FRAMEPOINT_TOPRIGHT, -0.01, -0.01)

    set AUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AbilitiesLiteUIReturn", AUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(AUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(AUI_ReturnButton, "Return")
    call BlzFrameSetPoint(AUI_ReturnButton, FRAMEPOINT_TOPRIGHT, AUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)

    set AUI_LeftPane = BlzCreateFrameByType("BACKDROP", "AbilitiesLiteUILeftPane", AUI_Parent, "", 0)
    call BlzFrameSetTexture(AUI_LeftPane, AUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(AUI_LeftPane, FRAMEPOINT_TOPLEFT, AUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.078)
    call BlzFrameSetPoint(AUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, AUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

    set AUI_RightPane = BlzCreateFrameByType("BACKDROP", "AbilitiesLiteUIRightPane", AUI_Parent, "", 0)
    call BlzFrameSetTexture(AUI_RightPane, AUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(AUI_RightPane, FRAMEPOINT_TOPLEFT, AUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
    call BlzFrameSetPoint(AUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, AUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

    set AUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "AbilitiesLiteUIDetailIcon", AUI_RightPane, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(AUI_DetailIcon, FRAMEPOINT_TOPLEFT, AUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(AUI_DetailIcon, 0.042, 0.042)

    set AUI_DetailTitle = BlzCreateFrameByType("TEXT", "AbilitiesLiteUIDetailTitle", AUI_RightPane, "", 0)
    call BlzFrameSetPoint(AUI_DetailTitle, FRAMEPOINT_TOPLEFT, AUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
    call BlzFrameSetSize(AUI_DetailTitle, 0.250, 0.018)
    call BlzFrameSetTextAlignment(AUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(AUI_DetailTitle, 1.05)
    call BlzFrameSetEnable(AUI_DetailTitle, false)

    set AUI_DetailInfoBackdrop = BlzCreateFrameByType("BACKDROP", "AbilitiesLiteUIInfoBackdrop", AUI_RightPane, "", 0)
    call BlzFrameSetTexture(AUI_DetailInfoBackdrop, AUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(AUI_DetailInfoBackdrop, FRAMEPOINT_TOPLEFT, AUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, -0.001, -0.008)
    call BlzFrameSetSize(AUI_DetailInfoBackdrop, 0.250, 0.018)

    set AUI_DetailInfoText = BlzCreateFrameByType("TEXT", "AbilitiesLiteUIInfoText", AUI_DetailInfoBackdrop, "", 0)
    call BlzFrameSetPoint(AUI_DetailInfoText, FRAMEPOINT_TOPLEFT, AUI_DetailInfoBackdrop, FRAMEPOINT_TOPLEFT, 0.006, -0.001)
    call BlzFrameSetSize(AUI_DetailInfoText, 0.238, 0.016)
    call BlzFrameSetTextAlignment(AUI_DetailInfoText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(AUI_DetailInfoText, 0.92)
    call BlzFrameSetEnable(AUI_DetailInfoText, false)

    set AUI_DetailBodyText = BlzCreateFrameByType("TEXT", "AbilitiesLiteUIDetailBody", AUI_RightPane, "", 0)
    call BlzFrameSetPoint(AUI_DetailBodyText, FRAMEPOINT_TOPLEFT, AUI_RightPane, FRAMEPOINT_TOPLEFT, 0.074, -0.155)
    call BlzFrameSetSize(AUI_DetailBodyText, AUI_DETAIL_BODY_WIDTH, AUI_DETAIL_BODY_HEIGHT)
    call BlzFrameSetTextAlignment(AUI_DetailBodyText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(AUI_DetailBodyText, 0.90)
    call BlzFrameSetEnable(AUI_DetailBodyText, false)

    set AUI_ListScroll = BlzCreateFrameByType("SLIDER", "AbilitiesLiteUIListScroll", AUI_LeftPane, "QuestMainListScrollBar", 0)
    call BlzFrameSetPoint(AUI_ListScroll, FRAMEPOINT_TOPLEFT, AUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
    call BlzFrameSetPoint(AUI_ListScroll, FRAMEPOINT_BOTTOMLEFT, AUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, 0.004, 0.002)
    call BlzFrameSetMinMaxValue(AUI_ListScroll, 0.0, 0.0)
    call BlzFrameSetStepSize(AUI_ListScroll, 1.0)
    call BlzFrameSetValue(AUI_ListScroll, 0.0)
    call BlzTriggerRegisterFrameEvent(AUI_ListScrollTrigger, AUI_ListScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(AUI_WheelTrigger, AUI_ListScroll, FRAMEEVENT_MOUSE_WHEEL)
    call BlzTriggerRegisterFrameEvent(AUI_WheelTrigger, AUI_LeftPane, FRAMEEVENT_MOUSE_WHEEL)

    loop
        exitwhen rowIndex > AUI_MAX_ROWS

        set AUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "AbilitiesLiteUIRowButton" + I2S(rowIndex), AUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetPoint(AUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, AUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
        call BlzFrameSetSize(AUI_RowButton[rowIndex], 0.156, rowHeight)
        call BlzTriggerRegisterFrameEvent(AUI_RowTrigger, AUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(AUI_ClearFocusTrigger, AUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        set AUI_ButtonRow.integer[GetHandleId(AUI_RowButton[rowIndex])] = rowIndex

        set AUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "AbilitiesLiteUIRowIcon" + I2S(rowIndex), AUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(AUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, AUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
        call BlzFrameSetSize(AUI_RowIcon[rowIndex], 0.02, 0.02)

        set AUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "AbilitiesLiteUIRowText" + I2S(rowIndex), AUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(AUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, AUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
        call BlzFrameSetPoint(AUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, AUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.05, 0.004)
        call BlzFrameSetTextAlignment(AUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(AUI_RowText[rowIndex], false)

        set AUI_RowLevel[rowIndex] = BlzCreateFrameByType("TEXT", "AbilitiesLiteUIRowLevel" + I2S(rowIndex), AUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(AUI_RowLevel[rowIndex], FRAMEPOINT_TOPRIGHT, AUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.004)
        call BlzFrameSetPoint(AUI_RowLevel[rowIndex], FRAMEPOINT_BOTTOMRIGHT, AUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.004)
        call BlzFrameSetTextAlignment(AUI_RowLevel[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetEnable(AUI_RowLevel[rowIndex], false)

        set AUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "AbilitiesLiteUIRowHighlight" + I2S(rowIndex), AUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetAllPoints(AUI_RowHighlight[rowIndex], AUI_RowButton[rowIndex])
        call BlzFrameSetModel(AUI_RowHighlight[rowIndex], AUI_RowHighlightModel, 0)
        call BlzFrameSetScale(AUI_RowHighlight[rowIndex], 0.76)
        call BlzFrameSetVisible(AUI_RowHighlight[rowIndex], false)
        call BlzFrameSetEnable(AUI_RowHighlight[rowIndex], false)

        set rowTopOffset = rowTopOffset - rowHeight - rowGap
        set rowIndex = rowIndex + 1
    endloop

    call BlzTriggerRegisterFrameEvent(AUI_CloseTrigger, AUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(AUI_ClearFocusTrigger, AUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(AUI_ReturnTrigger, AUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(AUI_ClearFocusTrigger, AUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    call BlzFrameSetVisible(AUI_Parent, false)
endfunction

public function ShowForUnit takes unit u returns nothing
    set AUI_SelectedUnit = u
    call AUI_EnsureTemplatesForUnit(u)
    call AUI_ResetViewState()
    call BlzFrameSetVisible(AUI_Parent, true)
    call AUI_Update()
endfunction

public function Show takes nothing returns nothing
    call BlzFrameSetVisible(AUI_Parent, true)
    call AUI_Update()
endfunction

public function Init takes nothing returns nothing
    if AUI_Initialized then
        return
    endif
    set AUI_Initialized = true

    set AUI_ButtonRow = Table.create()

    set AUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(AUI_CloseTrigger, function AUI_CloseAction)

    set AUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(AUI_ReturnTrigger, function AUI_ReturnAction)

    set AUI_RowTrigger = CreateTrigger()
    call TriggerAddAction(AUI_RowTrigger, function AUI_RowAction)

    set AUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(AUI_ClearFocusTrigger, function AUI_ClearFocusAction)

    set AUI_ListScrollTrigger = CreateTrigger()
    call TriggerAddAction(AUI_ListScrollTrigger, function AUI_ListScrollAction)

    set AUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(AUI_WheelTrigger, function AUI_WheelAction)

    call AUI_CreateFrames()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
