library StatsUI initializer AutoInit requires Table, MasterUI, DEquipment, AbilitiesLiteUI, QuestGiver
/**
    StatsUI
    
    Author: [Valdemar]
    Version: 1.0

    Description: Shows the current party and companion stats with a quick list and a detailed view.

    Credits: Tasyen (TasQuestBox as inspiration)

**/

globals
    private constant real SUI_REFRESH_INTERVAL = 0.50
    private constant integer SUI_MAX_ROWS = 8
    private constant integer SUI_VISIBLE_ROWS = 6
    private constant integer SUI_SUMMARY_ROWS = 6
    private constant integer SUI_DETAIL_STAT_COLUMNS = 3
    private constant integer SUI_DETAIL_STAT_ROWS = 13

    private boolean SUI_Initialized = false
    private boolean SUI_IsVisible = false
    private boolean SUI_SyncingListScroll = false
    private integer SUI_SelectedRow = 0

    private framehandle SUI_Parent = null
    private framehandle SUI_Title = null
    private framehandle SUI_LeftPane = null
    private framehandle SUI_RightPane = null
    private framehandle SUI_CloseButton = null
    private framehandle SUI_ReturnButton = null
    private framehandle SUI_AbilitiesButton = null
    private framehandle SUI_ListScroll = null
    private framehandle SUI_DetailBackdrop = null
    private framehandle SUI_DetailIcon = null
    private framehandle SUI_DetailTitle = null
    private framehandle SUI_DetailValue = null
    private framehandle array SUI_DetailSummaryLabelLeft
    private framehandle array SUI_DetailSummaryValueLeft
    private framehandle array SUI_DetailSummaryLabelRight
    private framehandle array SUI_DetailSummaryValueRight

    private framehandle array SUI_RowButton
    private framehandle array SUI_RowIcon
    private framehandle array SUI_RowText
    private framehandle array SUI_RowLevel
    private framehandle array SUI_RowHighlight
    private framehandle array SUI_DetailStatLabel
    private framehandle array SUI_DetailStatValue
    private integer array SUI_RowDisplayHandle
    private integer array SUI_RowButtonVisible
    private integer array SUI_RowHighlightVisible
    private integer array SUI_RowStatusHP
    private integer array SUI_RowStatusMP
    private integer array SUI_RowStatusDead
    private real array SUI_DetailStatCache
    private unit SUI_SelectedUnit = null
    private unit array SUI_RowUnit
    private integer array SUI_RowKind
    private integer array SUI_ListScrollValue
    private integer SUI_DetailHeaderUnitHandle = 0
    private integer SUI_DetailHeaderLevel = -1
    private integer SUI_DetailStatsUnitHandle = 0
    private integer SUI_DetailSummaryUnitHandle = 0
    private integer SUI_DetailSummaryDead = -1
    private integer SUI_DetailSummaryHP = -1
    private integer SUI_DetailSummaryMP = -1
    private integer SUI_DetailSummaryLevel = -1
    private integer SUI_DetailSummaryPoints = -1
    private integer SUI_DetailSummaryLife = -1
    private integer SUI_DetailSummaryMaxLife = -1
    private integer SUI_DetailSummaryMana = -1
    private integer SUI_DetailSummaryMaxMana = -1
    private integer SUI_DetailSummaryKills = -1
    private integer SUI_DetailSummaryDeaths = -1
    private integer SUI_DetailSummaryMinDamage = -1
    private integer SUI_DetailSummaryMaxDamage = -1
    private integer SUI_DetailSummaryAttackSpeedHash = 0
    private integer SUI_DetailSummaryClassHash = 0
    private integer SUI_DetailSummaryRoleHash = 0

    private Table SUI_ButtonRow = 0

    private trigger SUI_CloseTrigger = null
    private trigger SUI_ReturnTrigger = null
    private trigger SUI_AbilitiesTrigger = null
    private trigger SUI_RowTrigger = null
    private trigger SUI_ListScrollTrigger = null
    private trigger SUI_ClearFocusTrigger = null
    private trigger SUI_WheelTrigger = null
    private timer SUI_RefreshTimer = null

    private string SUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private string SUI_RowHighlightModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
    private string SUI_DefaultUnitIcon = "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    private string SUI_ShadowclawIcon = "ReplaceableTextures\\CommandButtons\\BTNSpiritWolf.blp"
    private integer SUI_KIND_HERO = 1
    private integer SUI_KIND_PET = 2
    private integer SUI_KIND_COMPANION = 3
    private integer SUI_UNIT_SHADOWCLAW = 'n655'
endglobals

private function SUI_Abs takes real value returns real
    if value < 0.0 then
        return -value
    endif
    return value
endfunction

private function SUI_GetDisplayName takes unit u returns string
    local string displayName
    local integer unitTypeId

    if u == null or GetHandleId(u) == 0 then
        return "Unavailable"
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHeroProperName(u)
    endif

    set unitTypeId = GetUnitTypeId(u)
    set displayName = GetUnitName(u)
    if displayName != null and displayName != "" then
        return displayName
    endif

    set displayName = GetObjectName(unitTypeId)
    if displayName != null and displayName != "" then
        return displayName
    endif

    if u == udg_Shadowclaw or unitTypeId == SUI_UNIT_SHADOWCLAW then
        return "Shadowclaw"
    endif

    return "Unknown"
endfunction

private function SUI_GetKindLabel takes integer kind returns string
    if kind == SUI_KIND_HERO then
        return "|cffffcc00Player|r"
    elseif kind == SUI_KIND_PET then
        return "|cff9fd3ffPet|r"
    endif
    return "|cffffffccCompanion|r"
endfunction

private function SUI_IsPlayerOwnedMainHero takes unit u returns boolean
    return u != null and GetHandleId(u) != 0 and GetOwningPlayer(u) == Player(0)
endfunction

private function SUI_GetUnitIconPath takes unit u returns string
    local string iconPath
    local integer unitTypeId

    if u == null or GetHandleId(u) == 0 then
        return SUI_DefaultUnitIcon
    endif

    set unitTypeId = GetUnitTypeId(u)
    if u == udg_Shadowclaw or unitTypeId == SUI_UNIT_SHADOWCLAW then
        return SUI_ShadowclawIcon
    endif

    set iconPath = QuestGiver_GetCompanionIcon(u)
    if iconPath != null and iconPath != "" then
        return iconPath
    endif

    // Warcraft III exposes no direct unit-icon native, so this remains a best-effort fallback.
    set iconPath = BlzGetAbilityIcon(unitTypeId)
    if iconPath == null or iconPath == "" then
        return SUI_DefaultUnitIcon
    endif
    return iconPath
endfunction

private function SUI_GetHealthColor takes integer percent returns string
    if percent >= 75 then
        return "|cff00ff00"
    elseif percent >= 50 then
        return "|cffffff00"
    elseif percent >= 25 then
        return "|cffff8a0e"
    endif
    return "|cffff0000"
endfunction

private function SUI_GetHealthPercent takes unit u returns integer
    local real maxLife
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    set maxLife = GetUnitState(u, UNIT_STATE_MAX_LIFE)
    if maxLife <= 0.0 then
        return 0
    endif
    return R2I((GetUnitState(u, UNIT_STATE_LIFE) / maxLife) * 100.0)
endfunction

private function SUI_GetManaPercent takes unit u returns integer
    local real maxMana
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    set maxMana = GetUnitState(u, UNIT_STATE_MAX_MANA)
    if maxMana <= 0.0 then
        return 0
    endif
    return R2I((GetUnitState(u, UNIT_STATE_MANA) / maxMana) * 100.0)
endfunction

private function SUI_GetStatusText takes unit u returns string
    local integer hp
    local integer mp

    if u == null or GetHandleId(u) == 0 then
        return "|cff7f7f7fUnavailable|r"
    endif
    if GetWidgetLife(u) <= 0.405 then
        return "|cffff0000Dead|r"
    endif

    set hp = SUI_GetHealthPercent(u)
    set mp = SUI_GetManaPercent(u)
    return SUI_GetHealthColor(hp) + I2S(hp) + "|r / |cff7ebff1" + I2S(mp) + "|r"
endfunction

private function SUI_GetLevelText takes unit u returns string
    if u == null or GetHandleId(u) == 0 then
        return "-"
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return I2S(GetHeroLevel(u))
    endif
    return I2S(GetUnitLevel(u))
endfunction

private function SUI_GetUnitPoints takes unit u returns integer
    if u == udg_Nazgrek then
        return udg_AbilityPointsNazgrek
    elseif u == udg_Zulkis then
        return udg_AbilityPointsZulkis
    endif
    return 0
endfunction

private function SUI_GetUnitKills takes unit u returns integer
    local integer id
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    if u == udg_Nazgrek then
        return udg_NazgrekKillCount
    elseif u == udg_Zulkis then
        return udg_ZulkisKillCount
    elseif u == udg_TamedUnit then
        return udg_TamedUnitKillCount
    endif
    set id = GetUnitUserData(u)
    return udg_CompanionUnitKillCount[id]
endfunction

private function SUI_GetUnitDeaths takes unit u returns integer
    local integer id
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    if u == udg_Nazgrek then
        return udg_NazgrekDeathCount
    elseif u == udg_Zulkis then
        return udg_ZulkisDeathCount
    endif
    set id = GetUnitUserData(u)
    return udg_CompanionUnitDeathCount[id]
endfunction

private function SUI_UsesWholePercentDisplay takes integer statId returns boolean
    return statId == 10 or statId == 27 or statId == 35 or statId == 36 or statId == 37 or statId == 39
endfunction

private function SUI_UsesFlatDisplay takes integer statId returns boolean
    return statId == 38
endfunction

private function SUI_FormatNumber takes real value returns string
    if SUI_Abs(value - I2R(R2I(value))) < 0.01 then
        return I2S(R2I(value))
    endif
    return R2Dec2S(value)
endfunction

private function SUI_GetStatValue takes unit u, integer statId returns real
    local integer id

    if u == null or GetHandleId(u) == 0 then
        return 0.0
    endif

    set id = GetUnitUserData(u)
    if statId == 10 then
        return I2R(udg_Stats_Crit[id])
    elseif statId == 27 then
        return I2R(udg_Stats_Dodge[id])
    elseif statId == 35 then
        return I2R(udg_Stats_Block[id])
    elseif statId == 36 then
        return I2R(udg_Stats_Hit[id])
    elseif statId == 37 then
        return I2R(udg_Stats_SpellPowerPct[id])
    elseif statId == 38 then
        return I2R(udg_Stats_SpellPowerFlat[id])
    endif
    return DEqGetUnitStatById(u, statId)
endfunction

private function SUI_FormatStatValue takes integer statId, real value returns string
    if SUI_UsesFlatDisplay(statId) then
        return SUI_FormatNumber(value)
    endif
    if DisplayAsPercent[statId] then
        if SUI_UsesWholePercentDisplay(statId) then
            return SUI_FormatNumber(value) + "%"
        endif
        return SUI_FormatNumber(value * 100.0) + "%"
    endif
    return SUI_FormatNumber(value)
endfunction

private function SUI_GetCompactStatLabel takes integer statId returns string
    if statId == 5 then
        return "HP Regen"
    elseif statId == 6 then
        return "HP %/Sec"
    elseif statId == 8 then
        return "Mana Regen"
    elseif statId == 9 then
        return "Mana %/Sec"
    elseif statId == 10 then
        return "Crit"
    elseif statId == 11 then
        return "Crit Dmg"
    elseif statId == 13 then
        return "Damage %"
    elseif statId == 14 then
        return "Melee Dmg"
    elseif statId == 15 then
        return "Melee %"
    elseif statId == 16 then
        return "Ranged Dmg"
    elseif statId == 17 then
        return "Ranged %"
    elseif statId == 18 then
        return "Cleave %"
    elseif statId == 19 then
        return "Cleave Dmg"
    elseif statId == 20 then
        return "Atk Speed"
    elseif statId == 21 then
        return "Atk Range"
    elseif statId == 22 then
        return "Lifesteal"
    elseif statId == 24 then
        return "Thorns %"
    elseif statId == 26 then
        return "Armor %"
    elseif statId == 28 then
        return "Spell Taken"
    elseif statId == 29 then
        return "Melee Taken"
    elseif statId == 30 then
        return "Pierce Taken"
    elseif statId == 31 then
        return "Move Speed"
    elseif statId == 32 then
        return "Move %"
    elseif statId == 33 then
        return "Sight"
    elseif statId == 34 then
        return "Inventory"
    elseif statId == 35 then
        return "Block"
    elseif statId == 36 then
        return "Hit"
    elseif statId == 37 then
        return "Spell %"
    elseif statId == 38 then
        return "Spell Power"
    elseif statId == 39 then
        return "Healing"
    endif
    return DEqStatNames[statId]
endfunction

private function SUI_GetKindByUnit takes unit u returns integer
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    if u == udg_Nazgrek or u == udg_Zulkis then
        return SUI_KIND_HERO
    elseif u == udg_TamedUnit then
        return SUI_KIND_PET
    endif
    return SUI_KIND_COMPANION
endfunction

private function SUI_IsTrackedUnit takes unit u returns boolean
    local integer i = 1

    if u == null or GetHandleId(u) == 0 then
        return false
    endif
    if u == udg_Nazgrek or u == udg_Zulkis then
        return SUI_IsPlayerOwnedMainHero(u)
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

private function SUI_InvalidateDetailSummaryCache takes nothing returns nothing
    set SUI_DetailSummaryUnitHandle = 0
    set SUI_DetailSummaryDead = -1
    set SUI_DetailSummaryHP = -1
    set SUI_DetailSummaryMP = -1
    set SUI_DetailSummaryLevel = -1
    set SUI_DetailSummaryPoints = -1
    set SUI_DetailSummaryLife = -1
    set SUI_DetailSummaryMaxLife = -1
    set SUI_DetailSummaryMana = -1
    set SUI_DetailSummaryMaxMana = -1
    set SUI_DetailSummaryKills = -1
    set SUI_DetailSummaryDeaths = -1
    set SUI_DetailSummaryMinDamage = -1
    set SUI_DetailSummaryMaxDamage = -1
    set SUI_DetailSummaryAttackSpeedHash = 0
    set SUI_DetailSummaryClassHash = 0
    set SUI_DetailSummaryRoleHash = 0
endfunction

private function SUI_InvalidateDetailStatsCache takes nothing returns nothing
    local integer i = 1

    set SUI_DetailStatsUnitHandle = 0
    loop
        exitwhen i > SUI_DETAIL_STAT_COLUMNS * SUI_DETAIL_STAT_ROWS
        set SUI_DetailStatCache[i] = -999999.0
        set i = i + 1
    endloop
endfunction

private function SUI_UpdateRowFrame takes player whichPlayer, integer rowIndex, unit u, integer kind returns nothing
    local integer handleId = GetHandleId(u)
    local integer hp = 0
    local integer mp = 0
    local integer dead = 0
    local integer selected = 0

    if GetLocalPlayer() != whichPlayer then
        return
    endif

    if SUI_RowDisplayHandle[rowIndex] != handleId then
        set SUI_RowDisplayHandle[rowIndex] = handleId
        set SUI_RowStatusHP[rowIndex] = -1
        set SUI_RowStatusMP[rowIndex] = -1
        set SUI_RowStatusDead[rowIndex] = -1
        call BlzFrameSetTexture(SUI_RowIcon[rowIndex], SUI_GetUnitIconPath(u), 0, true)
        call BlzFrameSetText(SUI_RowText[rowIndex], SUI_GetKindLabel(kind) + " " + SUI_GetDisplayName(u))
    endif

    if GetWidgetLife(u) <= 0.405 then
        set dead = 1
    else
        set hp = SUI_GetHealthPercent(u)
        set mp = SUI_GetManaPercent(u)
    endif

    if SUI_RowStatusDead[rowIndex] != dead or SUI_RowStatusHP[rowIndex] != hp or SUI_RowStatusMP[rowIndex] != mp then
        set SUI_RowStatusDead[rowIndex] = dead
        set SUI_RowStatusHP[rowIndex] = hp
        set SUI_RowStatusMP[rowIndex] = mp
        call BlzFrameSetText(SUI_RowLevel[rowIndex], SUI_GetStatusText(u))
    endif

    if u == SUI_SelectedUnit then
        set selected = 1
    endif
    if SUI_RowHighlightVisible[rowIndex] != selected then
        set SUI_RowHighlightVisible[rowIndex] = selected
        call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], selected == 1)
    endif
    if SUI_RowButtonVisible[rowIndex] != 1 then
        set SUI_RowButtonVisible[rowIndex] = 1
        call BlzFrameSetVisible(SUI_RowButton[rowIndex], true)
    endif
endfunction

private function SUI_GetUnitDamageMin takes unit u returns integer
    local integer baseDamage
    local integer diceCount

    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    set baseDamage = BlzGetUnitBaseDamage(u, 0)
    set diceCount = BlzGetUnitDiceNumber(u, 0)
    if diceCount < 0 then
        set diceCount = 0
    endif
    return baseDamage + diceCount
endfunction

private function SUI_GetUnitDamageMax takes unit u returns integer
    local integer baseDamage
    local integer diceCount
    local integer diceSides

    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    set baseDamage = BlzGetUnitBaseDamage(u, 0)
    set diceCount = BlzGetUnitDiceNumber(u, 0)
    set diceSides = BlzGetUnitDiceSides(u, 0)
    if diceCount < 0 then
        set diceCount = 0
    endif
    if diceSides < 1 then
        set diceSides = 1
    endif
    return baseDamage + (diceCount * diceSides)
endfunction

private function SUI_GetUnitAttackSpeedText takes unit u returns string
    local real cooldown

    if u == null or GetHandleId(u) == 0 then
        return "-"
    endif
    set cooldown = BlzGetUnitAttackCooldown(u, 0)
    if cooldown <= 0.0 then
        return "-"
    endif
    return R2Dec2S(1.0 / cooldown) + " aps"
endfunction

private function SUI_GetClassColor takes string classText returns string
    if classText == "Warrior" then
        return "|cffc79c6e"
    elseif classText == "Paladin" then
        return "|cfff58cba"
    elseif classText == "Shaman" then
        return "|cff0070de"
    elseif classText == "Warlock" then
        return "|cff8788ee"
    elseif classText == "Rogue" then
        return "|cfffff569"
    elseif classText == "Ranger" then
        return "|cffabd473"
    elseif classText == "Engineer" then
        return "|cffffc94d"
    endif
    return "|cffbfbfbf"
endfunction

private function SUI_GetRoleColor takes string roleText returns string
    if roleText == "Tank" then
        return "|cff4a7dff"
    elseif roleText == "Healer" then
        return "|cff00ff96"
    elseif roleText == "Melee Damage" then
        return "|cffff7d0a"
    elseif roleText == "Ranged Damage" then
        return "|cffffff00"
    elseif roleText == "Support" then
        return "|cff00ffff"
    endif
    return "|cffbfbfbf"
endfunction

private function SUI_ColorizeClassText takes string classText returns string
    return SUI_GetClassColor(classText) + classText + "|r"
endfunction

private function SUI_ColorizeRoleText takes string roleText returns string
    return SUI_GetRoleColor(roleText) + roleText + "|r"
endfunction

private function SUI_GetFallbackUnitClassText takes unit u returns string
    local integer unitTypeId

    if u == null or GetHandleId(u) == 0 then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(u)

    // Future companion metadata should override these hardcoded defaults.
    if udg_Nazgrek != null and GetHandleId(udg_Nazgrek) != 0 and unitTypeId == GetUnitTypeId(udg_Nazgrek) then
        return "Shaman"
    elseif unitTypeId == 'H60Y' then
        return "Paladin"
    elseif unitTypeId == '061H' then
        return "Shaman"
    elseif unitTypeId == '0631' then
        return "Rogue"
    elseif unitTypeId == '0629' then
        return "Warrior"
    elseif unitTypeId == 'H60X' then
        return "Warlock"
    elseif unitTypeId == 'N64O' or unitTypeId == 'N661' then
        return "Engineer"
    endif

    return "TBD"
endfunction

private function SUI_GetFallbackUnitRoleText takes unit u returns string
    local integer unitTypeId

    if u == null or GetHandleId(u) == 0 then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(u)

    // Future companion metadata should override these hardcoded defaults.
    if udg_Nazgrek != null and GetHandleId(udg_Nazgrek) != 0 and unitTypeId == GetUnitTypeId(udg_Nazgrek) then
        return "Melee Damage"
    endif

    return "TBD"
endfunction

private function SUI_GetUnitClassText takes unit u returns string
    if u == null or GetHandleId(u) == 0 then
        return "-"
    endif
    return SUI_GetFallbackUnitClassText(u)
endfunction

private function SUI_GetUnitRoleText takes unit u returns string
    if u == null or GetHandleId(u) == 0 then
        return "-"
    endif
    return SUI_GetFallbackUnitRoleText(u)
endfunction

private function SUI_SetStatRowVisible takes integer index, boolean flag returns nothing
    call BlzFrameSetVisible(SUI_DetailStatLabel[index], flag)
    call BlzFrameSetVisible(SUI_DetailStatValue[index], flag)
endfunction

private function SUI_ClearDetailStats takes nothing returns nothing
    local integer i = 1

    loop
        exitwhen i > SUI_DETAIL_STAT_COLUMNS * SUI_DETAIL_STAT_ROWS
        call SUI_SetStatRowVisible(i, false)
        set i = i + 1
    endloop
endfunction

private function SUI_ClearDetailSummaryRows takes nothing returns nothing
    local integer row = 1

    loop
        exitwhen row > SUI_SUMMARY_ROWS
        call BlzFrameSetText(SUI_DetailSummaryLabelLeft[row], "")
        call BlzFrameSetText(SUI_DetailSummaryValueLeft[row], "")
        call BlzFrameSetText(SUI_DetailSummaryLabelRight[row], "")
        call BlzFrameSetText(SUI_DetailSummaryValueRight[row], "")
        set row = row + 1
    endloop
endfunction

private function SUI_SetDetailSummaryRow takes integer row, string leftLabel, string leftValue, string rightLabel, string rightValue returns nothing
    call BlzFrameSetText(SUI_DetailSummaryLabelLeft[row], leftLabel)
    call BlzFrameSetText(SUI_DetailSummaryValueLeft[row], leftValue)
    call BlzFrameSetText(SUI_DetailSummaryLabelRight[row], rightLabel)
    call BlzFrameSetText(SUI_DetailSummaryValueRight[row], rightValue)
endfunction

private function SUI_UpdateDetailStats takes player whichPlayer, unit u returns nothing
    local integer statId = 1
    local integer rowIndex = 1
    local integer handleId = 0
    local real statValue

    if GetLocalPlayer() != whichPlayer then
        return
    endif

    if u == null or GetHandleId(u) == 0 then
        call SUI_InvalidateDetailStatsCache()
        call SUI_ClearDetailStats()
        return
    endif

    set handleId = GetHandleId(u)
    if SUI_DetailStatsUnitHandle != handleId then
        set SUI_DetailStatsUnitHandle = handleId
        call SUI_InvalidateDetailStatsCache()
        set SUI_DetailStatsUnitHandle = handleId
    endif

    if DEqStatsCounter <= 0 then
        return
    endif

    loop
        exitwhen statId > DEqStatsCounter or rowIndex > SUI_DETAIL_STAT_COLUMNS * SUI_DETAIL_STAT_ROWS
        if DEqStatNames[statId] != null then
            if SUI_DetailStatCache[rowIndex] <= -999998.0 then
                call BlzFrameSetText(SUI_DetailStatLabel[rowIndex], "|cffffcc00" + SUI_GetCompactStatLabel(statId) + "|r")
            endif
            set statValue = SUI_GetStatValue(u, statId)
            if SUI_Abs(SUI_DetailStatCache[rowIndex] - statValue) > 0.01 then
                set SUI_DetailStatCache[rowIndex] = statValue
                call BlzFrameSetText(SUI_DetailStatValue[rowIndex], "|cffffffff" + SUI_FormatStatValue(statId, statValue) + "|r")
            endif
            call SUI_SetStatRowVisible(rowIndex, true)
            set rowIndex = rowIndex + 1
        endif
        set statId = statId + 1
    endloop

    loop
        exitwhen rowIndex > SUI_DETAIL_STAT_COLUMNS * SUI_DETAIL_STAT_ROWS
        call SUI_SetStatRowVisible(rowIndex, false)
        set rowIndex = rowIndex + 1
    endloop
endfunction

private function SUI_GetRowCount takes nothing returns integer
    local integer count = 0
    local integer i = 1

    if SUI_IsPlayerOwnedMainHero(udg_Nazgrek) then
        set count = count + 1
    endif
    if SUI_IsPlayerOwnedMainHero(udg_Zulkis) then
        set count = count + 1
    endif
    if udg_TamedUnit != null and GetHandleId(udg_TamedUnit) != 0 then
        set count = count + 1
    endif

    loop
        exitwhen i > udg_CompanionCount
        if udg_CompanionUnit[i] != null and GetHandleId(udg_CompanionUnit[i]) != 0 then
            set count = count + 1
        endif
        set i = i + 1
    endloop

    return count
endfunction

private function SUI_GetSelectedUnit takes player whichPlayer returns unit
    local integer rowIndex = 1

    if SUI_IsTrackedUnit(SUI_SelectedUnit) then
        return SUI_SelectedUnit
    endif

    loop
        exitwhen rowIndex > SUI_MAX_ROWS
        if SUI_RowUnit[rowIndex] != null and GetHandleId(SUI_RowUnit[rowIndex]) != 0 then
            set SUI_SelectedRow = rowIndex
            set SUI_SelectedUnit = SUI_RowUnit[rowIndex]
            return SUI_SelectedUnit
        endif
        set rowIndex = rowIndex + 1
    endloop

    set SUI_SelectedRow = 0
    set SUI_SelectedUnit = null
    return null
endfunction

private function SUI_UpdateRows takes player whichPlayer returns nothing
    local integer rowIndex = 1
    local integer i = 1
    local integer listStart = SUI_ListScrollValue[GetPlayerId(whichPlayer)]
    local integer skipped = 0
    local integer maxStart = SUI_GetRowCount() - SUI_VISIBLE_ROWS
    local unit u

    if maxStart < 0 then
        set maxStart = 0
    endif
    if listStart < 0 then
        set listStart = 0
        set SUI_ListScrollValue[GetPlayerId(whichPlayer)] = 0
    elseif listStart > maxStart then
        set listStart = maxStart
        set SUI_ListScrollValue[GetPlayerId(whichPlayer)] = maxStart
    endif

    if SUI_IsPlayerOwnedMainHero(udg_Nazgrek) then
        if skipped < listStart then
            set skipped = skipped + 1
        elseif rowIndex <= SUI_VISIBLE_ROWS then
            set SUI_RowUnit[rowIndex] = udg_Nazgrek
            set SUI_RowKind[rowIndex] = SUI_KIND_HERO
            call SUI_UpdateRowFrame(whichPlayer, rowIndex, udg_Nazgrek, SUI_KIND_HERO)
            set rowIndex = rowIndex + 1
        endif
    endif

    if SUI_IsPlayerOwnedMainHero(udg_Zulkis) then
        if skipped < listStart then
            set skipped = skipped + 1
        elseif rowIndex <= SUI_VISIBLE_ROWS then
            set SUI_RowUnit[rowIndex] = udg_Zulkis
            set SUI_RowKind[rowIndex] = SUI_KIND_HERO
            call SUI_UpdateRowFrame(whichPlayer, rowIndex, udg_Zulkis, SUI_KIND_HERO)
            set rowIndex = rowIndex + 1
        endif
    endif

    if udg_TamedUnit != null and GetHandleId(udg_TamedUnit) != 0 then
        if skipped < listStart then
            set skipped = skipped + 1
        elseif rowIndex <= SUI_VISIBLE_ROWS then
            set SUI_RowUnit[rowIndex] = udg_TamedUnit
            set SUI_RowKind[rowIndex] = SUI_KIND_PET
            call SUI_UpdateRowFrame(whichPlayer, rowIndex, udg_TamedUnit, SUI_KIND_PET)
            set rowIndex = rowIndex + 1
        endif
    endif

    loop
        exitwhen i > udg_CompanionCount
        set u = udg_CompanionUnit[i]
        if u != null and GetHandleId(u) != 0 then
            if skipped < listStart then
                set skipped = skipped + 1
            elseif rowIndex <= SUI_VISIBLE_ROWS then
                set SUI_RowUnit[rowIndex] = u
                set SUI_RowKind[rowIndex] = SUI_KIND_COMPANION
                call SUI_UpdateRowFrame(whichPlayer, rowIndex, u, SUI_KIND_COMPANION)
                set rowIndex = rowIndex + 1
            endif
        endif
        set i = i + 1
    endloop

    loop
        exitwhen rowIndex > SUI_MAX_ROWS
        set SUI_RowUnit[rowIndex] = null
        set SUI_RowKind[rowIndex] = 0
        if GetLocalPlayer() == whichPlayer then
            set SUI_RowDisplayHandle[rowIndex] = 0
            set SUI_RowButtonVisible[rowIndex] = 0
            set SUI_RowHighlightVisible[rowIndex] = 0
            set SUI_RowStatusHP[rowIndex] = -1
            set SUI_RowStatusMP[rowIndex] = -1
            set SUI_RowStatusDead[rowIndex] = -1
            call BlzFrameSetVisible(SUI_RowButton[rowIndex], false)
            call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    if GetLocalPlayer() == whichPlayer then
        set SUI_SyncingListScroll = true
        call BlzFrameSetMinMaxValue(SUI_ListScroll, 0.0, I2R(maxStart))
        call BlzFrameSetValue(SUI_ListScroll, I2R(SUI_ListScrollValue[GetPlayerId(whichPlayer)]))
        set SUI_SyncingListScroll = false
        call BlzFrameSetVisible(SUI_ListScroll, maxStart > 0)
    endif

    set u = null
endfunction

private function SUI_UpdateDetailSummary takes player whichPlayer, unit u returns nothing
    local integer handleId
    local integer dead = 0
    local integer hp = 0
    local integer mp = 0
    local integer level = 0
    local integer points = 0
    local integer life = 0
    local integer maxLife = 0
    local integer mana = 0
    local integer maxMana = 0
    local integer kills = 0
    local integer deaths = 0
    local integer minDamage = 0
    local integer maxDamage = 0
    local string attackSpeedText = ""
    local string classText = ""
    local string roleText = ""
    local integer attackSpeedHash
    local integer classHash
    local integer roleHash

    if GetLocalPlayer() != whichPlayer then
        return
    endif

    if u == null or GetHandleId(u) == 0 then
        call SUI_InvalidateDetailSummaryCache()
        call SUI_ClearDetailSummaryRows()
        return
    endif

    set handleId = GetHandleId(u)
    if GetWidgetLife(u) <= 0.405 then
        set dead = 1
    else
        set hp = SUI_GetHealthPercent(u)
        set mp = SUI_GetManaPercent(u)
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        set level = GetHeroLevel(u)
    else
        set level = GetUnitLevel(u)
    endif
    set points = SUI_GetUnitPoints(u)
    set life = R2I(GetUnitState(u, UNIT_STATE_LIFE))
    set maxLife = R2I(GetUnitState(u, UNIT_STATE_MAX_LIFE))
    set mana = R2I(GetUnitState(u, UNIT_STATE_MANA))
    set maxMana = R2I(GetUnitState(u, UNIT_STATE_MAX_MANA))
    set kills = SUI_GetUnitKills(u)
    set deaths = SUI_GetUnitDeaths(u)
    set minDamage = SUI_GetUnitDamageMin(u)
    set maxDamage = SUI_GetUnitDamageMax(u)
    set attackSpeedText = SUI_GetUnitAttackSpeedText(u)
    set classText = SUI_GetUnitClassText(u)
    set roleText = SUI_GetUnitRoleText(u)
    set attackSpeedHash = StringHash(attackSpeedText)
    set classHash = StringHash(classText)
    set roleHash = StringHash(roleText)

    if SUI_DetailSummaryUnitHandle == handleId and SUI_DetailSummaryDead == dead and SUI_DetailSummaryHP == hp and SUI_DetailSummaryMP == mp and SUI_DetailSummaryLevel == level and SUI_DetailSummaryPoints == points and SUI_DetailSummaryLife == life and SUI_DetailSummaryMaxLife == maxLife and SUI_DetailSummaryMana == mana and SUI_DetailSummaryMaxMana == maxMana and SUI_DetailSummaryKills == kills and SUI_DetailSummaryDeaths == deaths and SUI_DetailSummaryMinDamage == minDamage and SUI_DetailSummaryMaxDamage == maxDamage and SUI_DetailSummaryAttackSpeedHash == attackSpeedHash and SUI_DetailSummaryClassHash == classHash and SUI_DetailSummaryRoleHash == roleHash then
        return
    endif

    set SUI_DetailSummaryUnitHandle = handleId
    set SUI_DetailSummaryDead = dead
    set SUI_DetailSummaryHP = hp
    set SUI_DetailSummaryMP = mp
    set SUI_DetailSummaryLevel = level
    set SUI_DetailSummaryPoints = points
    set SUI_DetailSummaryLife = life
    set SUI_DetailSummaryMaxLife = maxLife
    set SUI_DetailSummaryMana = mana
    set SUI_DetailSummaryMaxMana = maxMana
    set SUI_DetailSummaryKills = kills
    set SUI_DetailSummaryDeaths = deaths
    set SUI_DetailSummaryMinDamage = minDamage
    set SUI_DetailSummaryMaxDamage = maxDamage
    set SUI_DetailSummaryAttackSpeedHash = attackSpeedHash
    set SUI_DetailSummaryClassHash = classHash
    set SUI_DetailSummaryRoleHash = roleHash
    call SUI_SetDetailSummaryRow(1, "|cffffcc00Status|r", SUI_GetStatusText(u), "|cffffcc00Level|r", "|cffffffff" + SUI_GetLevelText(u) + "|r")
    call SUI_SetDetailSummaryRow(2, "|cffffcc00Hitpoints|r", "|cffffffff" + I2S(life) + " / " + I2S(maxLife) + "|r", "|cffffcc00Mana|r", "|cffffffff" + I2S(mana) + " / " + I2S(maxMana) + "|r")
    call SUI_SetDetailSummaryRow(3, "|cffffcc00Kills|r", "|cffffffff" + I2S(kills) + "|r", "|cffffcc00Deaths|r", "|cffffffff" + I2S(deaths) + "|r")
    call SUI_SetDetailSummaryRow(4, "|cffffcc00Damage|r", "|cffffffff" + I2S(minDamage) + " - " + I2S(maxDamage) + "|r", "|cffffcc00Atk Speed|r", "|cffffffff" + attackSpeedText + "|r")
    call SUI_SetDetailSummaryRow(5, "|cffffcc00Class|r", SUI_ColorizeClassText(classText), "|cffffcc00Type|r", SUI_ColorizeRoleText(roleText))
    if points > 0 then
        call SUI_SetDetailSummaryRow(6, "|cffffcc00Points|r", "|cffffffff" + I2S(points) + "|r", "", "")
    else
        call SUI_SetDetailSummaryRow(6, "", "", "", "")
    endif
endfunction

private function SUI_UpdateDetail takes player whichPlayer, boolean refreshStats returns nothing
    local unit u = SUI_GetSelectedUnit(whichPlayer)
    local integer kind
    local string headerText
    local integer handleId
    local integer level

    if u == null then
        if GetLocalPlayer() == whichPlayer then
            set SUI_DetailHeaderUnitHandle = 0
            set SUI_DetailHeaderLevel = -1
            call BlzFrameSetTexture(SUI_DetailIcon, SUI_DefaultUnitIcon, 0, true)
            call BlzFrameSetText(SUI_DetailTitle, "No unit")
            call BlzFrameSetText(SUI_DetailValue, "No tracked units are currently available.")
            call BlzFrameSetVisible(SUI_AbilitiesButton, false)
        endif
        call SUI_UpdateDetailSummary(whichPlayer, null)
        if refreshStats then
            call SUI_UpdateDetailStats(whichPlayer, null)
        endif
        return
    endif

    set kind = SUI_GetKindByUnit(u)
    set handleId = GetHandleId(u)
    if IsUnitType(u, UNIT_TYPE_HERO) then
        set level = GetHeroLevel(u)
    else
        set level = GetUnitLevel(u)
    endif

    if GetLocalPlayer() == whichPlayer then
        if SUI_DetailHeaderUnitHandle != handleId or SUI_DetailHeaderLevel != level then
            set SUI_DetailHeaderUnitHandle = handleId
            set SUI_DetailHeaderLevel = level
            set headerText = SUI_GetKindLabel(kind) + " " + SUI_GetDisplayName(u)
            call BlzFrameSetTexture(SUI_DetailIcon, SUI_GetUnitIconPath(u), 0, true)
            call BlzFrameSetText(SUI_DetailTitle, headerText)
            call BlzFrameSetText(SUI_DetailValue, "Level " + I2S(level))
        endif
        call BlzFrameSetVisible(SUI_AbilitiesButton, true)
    endif
    call SUI_UpdateDetailSummary(whichPlayer, u)
    if refreshStats then
        call SUI_UpdateDetailStats(whichPlayer, u)
    endif

    set u = null
endfunction

private function SUI_Update takes player whichPlayer, boolean refreshStats returns nothing
    if SUI_Parent == null then
        return
    endif

    if not SUI_IsTrackedUnit(SUI_SelectedUnit) and SUI_GetRowCount() > 0 then
        set SUI_SelectedRow = 1
    endif

    call SUI_UpdateRows(whichPlayer)
    call SUI_UpdateDetail(whichPlayer, refreshStats)
endfunction

private function SUI_PeriodicRefresh takes nothing returns nothing
    if SUI_Parent != null and BlzFrameIsVisible(SUI_Parent) then
        call SUI_Update(GetLocalPlayer(), false)
    endif
endfunction

private function SUI_SetRefreshActive takes boolean active returns nothing
    if SUI_RefreshTimer == null then
        return
    endif
    if active then
        call TimerStart(SUI_RefreshTimer, SUI_REFRESH_INTERVAL, true, function SUI_PeriodicRefresh)
    else
        call PauseTimer(SUI_RefreshTimer)
    endif
endfunction

private function SUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

public function Hide takes nothing returns nothing
    call SUI_SetRefreshActive(false)
    call SUI_InvalidateDetailSummaryCache()
    call SUI_InvalidateDetailStatsCache()
    set SUI_DetailHeaderUnitHandle = 0
    set SUI_DetailHeaderLevel = -1
    if SUI_Parent != null then
        call BlzFrameSetVisible(SUI_Parent, false)
    endif
endfunction

private function SUI_CloseAction takes nothing returns nothing
    call Hide()
endfunction

private function SUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function SUI_AbilitiesAction takes nothing returns nothing
    if SUI_IsTrackedUnit(SUI_SelectedUnit) then
        call Hide()
        call AbilitiesLiteUI_ShowForUnit(SUI_SelectedUnit)
    endif
endfunction

private function SUI_RowAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer handleId = GetHandleId(BlzGetTriggerFrame())

    if SUI_ButtonRow.has(handleId) then
        set SUI_SelectedRow = SUI_ButtonRow.integer[handleId]
        set SUI_SelectedUnit = SUI_RowUnit[SUI_SelectedRow]
        call SUI_InvalidateDetailSummaryCache()
        call SUI_InvalidateDetailStatsCache()
        set SUI_DetailHeaderUnitHandle = 0
        set SUI_DetailHeaderLevel = -1
        call SUI_Update(p, true)
    endif

    set p = null
endfunction

private function SUI_ListScrollAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    if SUI_SyncingListScroll then
        set p = null
        return
    endif
    set SUI_ListScrollValue[GetPlayerId(p)] = R2I(BlzGetTriggerFrameValue())
    call SUI_Update(p, false)
    set p = null
endfunction

private function SUI_WheelAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()

    if GetLocalPlayer() == GetTriggerPlayer() then
        if (triggerFrame == SUI_ListScroll or triggerFrame == SUI_LeftPane) and SUI_ListScroll != null and BlzFrameIsVisible(SUI_ListScroll) then
            if BlzGetTriggerFrameValue() > 0 then
                call BlzFrameSetValue(SUI_ListScroll, BlzFrameGetValue(SUI_ListScroll) + 1.0)
            else
                call BlzFrameSetValue(SUI_ListScroll, BlzFrameGetValue(SUI_ListScroll) - 1.0)
            endif
        endif
    endif
    set triggerFrame = null
endfunction

private function SUI_CreateFrames takes nothing returns nothing
    local integer rowIndex = 1
    local real rowTopOffset = -0.012
    local real rowHeight = 0.033
    local real rowGap = 0.003
    local integer summaryRow = 1
    local integer statIndex = 1
    local integer col
    local integer statRow
    local real summaryTopOffset
    local real summaryLeftColumn = 0.018
    local real summaryRightColumn = 0.156
    local real summaryValueOffset = 0.050
    local real statTopOffset
    local real statLeftOffset

    set SUI_Parent = BlzCreateFrameByType("BACKDROP", "StatsUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(SUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
    call BlzFrameSetAbsPoint(SUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.18)

    set SUI_Title = BlzCreateFrameByType("TEXT", "StatsUITitle", SUI_Parent, "", 0)
    call BlzFrameSetPoint(SUI_Title, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(SUI_Title, 0.30, 0.018)
    call BlzFrameSetTextAlignment(SUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(SUI_Title, 1.10)
    call BlzFrameSetEnable(SUI_Title, false)
    call BlzFrameSetText(SUI_Title, "|cffffe4a3Stats|r")

    set SUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsUIClose", SUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(SUI_CloseButton, 0.03, 0.03)
    call BlzFrameSetText(SUI_CloseButton, "X")
    call BlzFrameSetPoint(SUI_CloseButton, FRAMEPOINT_TOPRIGHT, SUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
    call BlzTriggerRegisterFrameEvent(SUI_CloseTrigger, SUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

    set SUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsUIReturn", SUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(SUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(SUI_ReturnButton, "Return")
    call BlzFrameSetPoint(SUI_ReturnButton, FRAMEPOINT_TOPRIGHT, SUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(SUI_ReturnTrigger, SUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    set SUI_LeftPane = BlzCreateFrameByType("BACKDROP", "StatsUILeftPane", SUI_Parent, "", 0)
    call BlzFrameSetTexture(SUI_LeftPane, SUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(SUI_LeftPane, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.058)
    call BlzFrameSetPoint(SUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, SUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

    set SUI_ListScroll = BlzCreateFrameByType("SLIDER", "StatsUIListScroll", SUI_LeftPane, "QuestMainListScrollBar", 0)
    call BlzFrameSetPoint(SUI_ListScroll, FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
    call BlzFrameSetPoint(SUI_ListScroll, FRAMEPOINT_BOTTOMLEFT, SUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, 0.004, 0.002)
    call BlzFrameSetMinMaxValue(SUI_ListScroll, 0.0, 0.0)
    call BlzFrameSetStepSize(SUI_ListScroll, 1.0)
    call BlzFrameSetValue(SUI_ListScroll, 0.0)
    call BlzTriggerRegisterFrameEvent(SUI_ListScrollTrigger, SUI_ListScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_ListScroll, FRAMEEVENT_MOUSE_WHEEL)
    call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_LeftPane, FRAMEEVENT_MOUSE_WHEEL)

    set SUI_RightPane = BlzCreateFrameByType("BACKDROP", "StatsUIRightPane", SUI_Parent, "", 0)
    call BlzFrameSetTexture(SUI_RightPane, SUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(SUI_RightPane, FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
    call BlzFrameSetPoint(SUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, SUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

    set SUI_DetailBackdrop = BlzCreateFrameByType("BACKDROP", "StatsUIDetailBackdrop", SUI_RightPane, "", 0)
    call BlzFrameSetTexture(SUI_DetailBackdrop, SUI_PanelTexture, 0, false)
    call BlzFrameSetPoint(SUI_DetailBackdrop, FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
    call BlzFrameSetPoint(SUI_DetailBackdrop, FRAMEPOINT_BOTTOMRIGHT, SUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
    call BlzFrameSetAlpha(SUI_DetailBackdrop, 255)
    call BlzFrameSetVertexColor(SUI_DetailBackdrop, BlzConvertColor(255, 0, 0, 0))

    set SUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "StatsUIDetailIcon", SUI_RightPane, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(SUI_DetailIcon, FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(SUI_DetailIcon, 0.042, 0.042)

    set SUI_DetailTitle = BlzCreateFrameByType("TEXT", "StatsUIDetailTitle", SUI_RightPane, "", 0)
    call BlzFrameSetPoint(SUI_DetailTitle, FRAMEPOINT_TOPLEFT, SUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
    call BlzFrameSetSize(SUI_DetailTitle, 0.190, 0.018)
    call BlzFrameSetTextAlignment(SUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(SUI_DetailTitle, 1.05)
    call BlzFrameSetEnable(SUI_DetailTitle, false)

    set SUI_DetailValue = BlzCreateFrameByType("TEXT", "StatsUIDetailValue", SUI_RightPane, "", 0)
    call BlzFrameSetPoint(SUI_DetailValue, FRAMEPOINT_TOPLEFT, SUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.004)
    call BlzFrameSetSize(SUI_DetailValue, 0.190, 0.018)
    call BlzFrameSetTextAlignment(SUI_DetailValue, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(SUI_DetailValue, 0.98)
    call BlzFrameSetEnable(SUI_DetailValue, false)

    set SUI_AbilitiesButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsUIAbilities", SUI_RightPane, "ScriptDialogButton", 0)
    call BlzFrameSetSize(SUI_AbilitiesButton, 0.060, 0.022)
    call BlzFrameSetText(SUI_AbilitiesButton, "Abilities")
    call BlzFrameSetPoint(SUI_AbilitiesButton, FRAMEPOINT_TOPRIGHT, SUI_RightPane, FRAMEPOINT_TOPRIGHT, -0.018, -0.022)
    call BlzTriggerRegisterFrameEvent(SUI_AbilitiesTrigger, SUI_AbilitiesButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_AbilitiesButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzFrameSetVisible(SUI_AbilitiesButton, false)

    loop
        exitwhen summaryRow > SUI_SUMMARY_ROWS
        set summaryTopOffset = -0.108 - (I2R(summaryRow - 1) * 0.015)

        set SUI_DetailSummaryLabelLeft[summaryRow] = BlzCreateFrameByType("TEXT", "StatsUISummaryLabelLeft" + I2S(summaryRow), SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailSummaryLabelLeft[summaryRow], FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, summaryLeftColumn, summaryTopOffset)
        call BlzFrameSetSize(SUI_DetailSummaryLabelLeft[summaryRow], 0.050, 0.013)
        call BlzFrameSetTextAlignment(SUI_DetailSummaryLabelLeft[summaryRow], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailSummaryLabelLeft[summaryRow], 0.74)
        call BlzFrameSetEnable(SUI_DetailSummaryLabelLeft[summaryRow], false)

        set SUI_DetailSummaryValueLeft[summaryRow] = BlzCreateFrameByType("TEXT", "StatsUISummaryValueLeft" + I2S(summaryRow), SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailSummaryValueLeft[summaryRow], FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, summaryLeftColumn + summaryValueOffset, summaryTopOffset)
        call BlzFrameSetSize(SUI_DetailSummaryValueLeft[summaryRow], 0.080, 0.013)
        call BlzFrameSetTextAlignment(SUI_DetailSummaryValueLeft[summaryRow], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailSummaryValueLeft[summaryRow], 0.74)
        call BlzFrameSetEnable(SUI_DetailSummaryValueLeft[summaryRow], false)

        set SUI_DetailSummaryLabelRight[summaryRow] = BlzCreateFrameByType("TEXT", "StatsUISummaryLabelRight" + I2S(summaryRow), SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailSummaryLabelRight[summaryRow], FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, summaryRightColumn, summaryTopOffset)
        call BlzFrameSetSize(SUI_DetailSummaryLabelRight[summaryRow], 0.050, 0.013)
        call BlzFrameSetTextAlignment(SUI_DetailSummaryLabelRight[summaryRow], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailSummaryLabelRight[summaryRow], 0.74)
        call BlzFrameSetEnable(SUI_DetailSummaryLabelRight[summaryRow], false)

        set SUI_DetailSummaryValueRight[summaryRow] = BlzCreateFrameByType("TEXT", "StatsUISummaryValueRight" + I2S(summaryRow), SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailSummaryValueRight[summaryRow], FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, summaryRightColumn + summaryValueOffset, summaryTopOffset)
        call BlzFrameSetSize(SUI_DetailSummaryValueRight[summaryRow], 0.108, 0.013)
        call BlzFrameSetTextAlignment(SUI_DetailSummaryValueRight[summaryRow], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailSummaryValueRight[summaryRow], 0.74)
        call BlzFrameSetEnable(SUI_DetailSummaryValueRight[summaryRow], false)

        set summaryRow = summaryRow + 1
    endloop

    loop
        exitwhen statIndex > SUI_DETAIL_STAT_COLUMNS * SUI_DETAIL_STAT_ROWS
        set col = (statIndex - 1) / SUI_DETAIL_STAT_ROWS
        set statRow = statIndex - (col * SUI_DETAIL_STAT_ROWS)
        set statTopOffset = -0.258 - (I2R(statRow - 1) * 0.0115)
        set statLeftOffset = 0.042 + (I2R(col) * 0.110)

        set SUI_DetailStatLabel[statIndex] = BlzCreateFrameByType("TEXT", "StatsUIDetailStatLabel" + I2S(statIndex), SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailStatLabel[statIndex], FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, statLeftOffset, statTopOffset)
        call BlzFrameSetSize(SUI_DetailStatLabel[statIndex], 0.072, 0.012)
        call BlzFrameSetTextAlignment(SUI_DetailStatLabel[statIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailStatLabel[statIndex], 0.68)
        call BlzFrameSetEnable(SUI_DetailStatLabel[statIndex], false)
        call BlzFrameSetVisible(SUI_DetailStatLabel[statIndex], false)
        if statIndex <= DEqStatsCounter and DEqStatNames[statIndex] != null then
            call BlzFrameSetText(SUI_DetailStatLabel[statIndex], "|cffffcc00" + SUI_GetCompactStatLabel(statIndex) + "|r")
        endif

        set SUI_DetailStatValue[statIndex] = BlzCreateFrameByType("TEXT", "StatsUIDetailStatValue" + I2S(statIndex), SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailStatValue[statIndex], FRAMEPOINT_TOPRIGHT, SUI_RightPane, FRAMEPOINT_TOPLEFT, statLeftOffset + 0.090, statTopOffset)
        call BlzFrameSetSize(SUI_DetailStatValue[statIndex], 0.030, 0.012)
        call BlzFrameSetTextAlignment(SUI_DetailStatValue[statIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetScale(SUI_DetailStatValue[statIndex], 0.68)
        call BlzFrameSetEnable(SUI_DetailStatValue[statIndex], false)
        call BlzFrameSetVisible(SUI_DetailStatValue[statIndex], false)
        set SUI_DetailStatCache[statIndex] = -999999.0

        set statIndex = statIndex + 1
    endloop

    loop
        exitwhen rowIndex > SUI_MAX_ROWS
        set SUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "StatsUIRowButton" + I2S(rowIndex), SUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetPoint(SUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
        call BlzFrameSetSize(SUI_RowButton[rowIndex], 0.156, rowHeight)
        call BlzTriggerRegisterFrameEvent(SUI_RowTrigger, SUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        set SUI_ButtonRow.integer[GetHandleId(SUI_RowButton[rowIndex])] = rowIndex

        set SUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsUIRowIcon" + I2S(rowIndex), SUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(SUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, SUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
        call BlzFrameSetSize(SUI_RowIcon[rowIndex], 0.02, 0.02)

        set SUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "StatsUIRowText" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, SUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
        call BlzFrameSetPoint(SUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.05, 0.004)
        call BlzFrameSetTextAlignment(SUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(SUI_RowText[rowIndex], false)

        set SUI_RowLevel[rowIndex] = BlzCreateFrameByType("TEXT", "StatsUIRowLevel" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SUI_RowLevel[rowIndex], FRAMEPOINT_TOPRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.004)
        call BlzFrameSetPoint(SUI_RowLevel[rowIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.004)
        call BlzFrameSetTextAlignment(SUI_RowLevel[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetEnable(SUI_RowLevel[rowIndex], false)

        set SUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "StatsUIRowHighlight" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetAllPoints(SUI_RowHighlight[rowIndex], SUI_RowButton[rowIndex])
        call BlzFrameSetModel(SUI_RowHighlight[rowIndex], SUI_RowHighlightModel, 0)
        call BlzFrameSetScale(SUI_RowHighlight[rowIndex], 0.76)
        call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], false)
        call BlzFrameSetEnable(SUI_RowHighlight[rowIndex], false)

        set rowTopOffset = rowTopOffset - rowHeight - rowGap
        set rowIndex = rowIndex + 1
    endloop

    call BlzFrameSetVisible(SUI_Parent, false)
endfunction

public function Show takes nothing returns nothing
    local player p = GetLocalPlayer()
    call SUI_InvalidateDetailSummaryCache()
    call SUI_InvalidateDetailStatsCache()
    set SUI_DetailHeaderUnitHandle = 0
    set SUI_DetailHeaderLevel = -1
    call SUI_Update(p, true)
    call SUI_SetRefreshActive(true)
    call BlzFrameSetVisible(SUI_Parent, true)
    set p = null
endfunction

public function Toggle takes nothing returns nothing
    if SUI_Parent != null and BlzFrameIsVisible(SUI_Parent) then
        call Hide()
    else
        call Show()
    endif
endfunction

public function IsVisible takes nothing returns boolean
    return SUI_Parent != null and BlzFrameIsVisible(SUI_Parent)
endfunction

public function Init takes nothing returns nothing
    if SUI_Initialized then
        return
    endif
    set SUI_Initialized = true

    set SUI_ButtonRow = Table.create()

    set SUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(SUI_CloseTrigger, function SUI_CloseAction)

    set SUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ReturnTrigger, function SUI_ReturnAction)

    set SUI_AbilitiesTrigger = CreateTrigger()
    call TriggerAddAction(SUI_AbilitiesTrigger, function SUI_AbilitiesAction)

    set SUI_RowTrigger = CreateTrigger()
    call TriggerAddAction(SUI_RowTrigger, function SUI_RowAction)

    set SUI_ListScrollTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ListScrollTrigger, function SUI_ListScrollAction)

    set SUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ClearFocusTrigger, function SUI_ClearFocusAction)

    set SUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(SUI_WheelTrigger, function SUI_WheelAction)

    call SUI_CreateFrames()

    set SUI_RefreshTimer = CreateTimer()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
