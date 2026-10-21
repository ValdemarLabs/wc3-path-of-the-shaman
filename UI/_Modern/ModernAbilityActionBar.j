/**
    ModernAbilityActionBar

    Author: Valdemar
    Version: 0.9.0

    Description:
    Renders the cached PotS-owned twelve-slot action bar with learned ability
    icons, active-cooldown updates, one shared tooltip, synchronized click
    activation, and the four-choice Summon Elemental flyout. Static frame data
    is rebuilt only after an invalidation, while cooldown polling is restricted
    to slots that are actually cooling down. Number-row keys 1 through 0,
    minus, and equals activate the corresponding visible slot.

    Credits:
    - Blizzard Entertainment, Warcraft III frame API
    - Forgotten Hollow, compact lower-HUD and action-slot inspiration

    How to install:
    Import after Events, FullscreenUI, ModernPlayerHUD, AbilitiesPlayer,
    ShamanCommon, ModernAbilityCatalog, ModernAbilityLoadout, and
    ModernAbilityController.

    API:
    - call ModernAbilityActionBar_Enable()
    - call ModernAbilityActionBar_Disable()
    - call ModernAbilityActionBar_Refresh()
    - set enabled = ModernAbilityActionBar_IsEnabled()

**/
library ModernAbilityActionBar initializer Init requires Events, FullscreenUI, ModernPlayerHUD, AbilitiesPlayer, ShamanCommon, ModernAbilityCatalog, ModernAbilityLoadout, ModernAbilityController

globals
    private constant boolean MAB_AUTO_ENABLE = true
    private constant boolean MAB_HIDE_NATIVE_BOTTOM_HUD = true

    private constant real MAB_ACTION_START_X = 0.190
    private constant real MAB_ACTION_BOTTOM = 0.012
    private constant real MAB_ACTION_SIZE = 0.032
    private constant real MAB_ACTION_GAP = 0.003
    private constant real MAB_TOOLTIP_WIDTH = 0.240
    private constant real MAB_TOOLTIP_HEIGHT = 0.092
    private constant integer MAB_ELEMENTAL_COUNT = 4
    private constant real MAB_ELEMENTAL_START_X = 0.318
    private constant real MAB_ELEMENTAL_BOTTOM = 0.124
    private constant real MAB_ELEMENTAL_SIZE = 0.038
    private constant real MAB_ELEMENTAL_GAP = 0.004
    private constant integer MAB_COOLDOWN_STEPS = 20
    private constant integer MAB_NATIVE_HERO_BUTTON_COUNT = 7

    private constant integer MAB_SUMMON_ELEMENTAL = 'A67Q'
    private constant integer MAB_ELEMENTAL_AIR = 'A61K'
    private constant integer MAB_ELEMENTAL_WATER = 'A61L'
    private constant integer MAB_ELEMENTAL_FIRE = 'A61M'
    private constant integer MAB_ELEMENTAL_EARTH = 'A61N'
    private constant integer MAB_CONTEXT_COUNT = 2
    private constant integer MAB_STEALTH = 'A6CR'
    private constant integer MAB_STEALTH_ALT = 'A6CU'
    private constant integer MAB_BLOCK_50 = 'A6AD'
    private constant integer MAB_BLOCK_75 = 'A6AE'
    private constant integer MAB_BLOCK_100 = 'A6AF'

    private constant string MAB_SURFACE_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private constant string MAB_EMPTY_ICON = "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"
    private constant string MAB_MEDALLION_TEXTURE = "UI\\_Modern\\Assets\\PotSMedallion.tga"

    private boolean MAB_Initialized = false
    private boolean MAB_FramesCreated = false
    private boolean MAB_Enabled = false
    private boolean MAB_NativeCaptured = false
    private boolean MAB_ParentVisible = false
    private boolean MAB_TargetingVisible = false
    private boolean MAB_StaticDirty = true
    private boolean MAB_WasFullscreen = false
    private integer MAB_CachedLoadoutRevision = -1
    private integer MAB_LearnScanTick = 0
    private integer MAB_MoveSourceSlot = 0
    private integer MAB_RebindSlot = 0

    private framehandle MAB_ScreenParent = null
    private framehandle MAB_Parent = null
    private framehandle MAB_HeroBorder = null
    private framehandle MAB_HeroIcon = null
    private framehandle MAB_TargetingText = null
    private framehandle MAB_Tooltip = null
    private framehandle MAB_TooltipTitle = null
    private framehandle MAB_TooltipBody = null
    private framehandle MAB_ElementalBackdrop = null
    private framehandle MAB_ElementalTitle = null

    private framehandle array MAB_SlotButton
    private framehandle array MAB_SlotIcon
    private framehandle array MAB_SlotCooldown
    private framehandle array MAB_SlotCooldownText
    private framehandle array MAB_SlotKeyText
    private framehandle array MAB_SlotDisabled
    private framehandle array MAB_ElementalButton
    private framehandle array MAB_ElementalIcon
    private framehandle array MAB_ElementalLabel
    private framehandle array MAB_ElementalDisabled
    private framehandle array MAB_ContextButton
    private framehandle array MAB_ContextIcon
    private framehandle array MAB_ContextLabel

    private framehandle array MAB_NativeFrame
    private boolean array MAB_NativeWasVisible
    private integer MAB_NativeFrameCount = 0

    private trigger MAB_SlotTrigger = null
    private trigger MAB_ElementalTrigger = null
    private trigger MAB_ContextTrigger = null
    private trigger MAB_ClearFocusTrigger = null
    private trigger MAB_HoverTrigger = null
    private trigger MAB_KeyTrigger = null
    private trigger MAB_InitTrigger = null

    private unit MAB_SelectedUnit = null
    private unit MAB_CachedHero = null
    private unit MAB_ElementalHero = null
    private boolean MAB_ElementalOpen = false
    private integer MAB_CachedTargetingAbility = -1
    private integer MAB_CachedTargetingMode = -1
    private integer MAB_CachedMana = -1
    private integer array MAB_CachedAbilityId
    private integer array MAB_CachedAbilityLevel
    private integer array MAB_CachedManaCost
    private integer array MAB_CachedCooldownSecond
    private integer array MAB_CachedCooldownStep
    private boolean array MAB_CachedReady
    private boolean array MAB_CachedDisabled
    private boolean array MAB_CachedCooldownVisible
    private boolean array MAB_CooldownActive
    private string array MAB_CachedTitle
    private string array MAB_CachedBody
    private string array MAB_CachedIcon
    private boolean array MAB_ElementalReady
    private integer array MAB_ContextAbilityId
    private oskeytype array MAB_SlotKey
    private string array MAB_SlotKeyLabel
endglobals

private function MAB_IsValidUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetHandleId(whichUnit) != 0 and GetUnitTypeId(whichUnit) != 0
endfunction

private function MAB_IsPlayerHero takes unit whichUnit returns boolean
    return MAB_IsValidUnit(whichUnit) and GetOwningPlayer(whichUnit) == Player(0) and ShamanCommon_IsPlayerHero(whichUnit)
endfunction

private function MAB_GetSlotLabel takes integer slot returns string
    if slot < 10 then
        return I2S(slot)
    elseif slot == 10 then
        return "0"
    elseif slot == 11 then
        return "-"
    endif
    return "="
endfunction

private function MAB_GetKeyLabel takes oskeytype whichKey returns string
    if whichKey == OSKEY_1 then
        return "1"
    elseif whichKey == OSKEY_2 then
        return "2"
    elseif whichKey == OSKEY_3 then
        return "3"
    elseif whichKey == OSKEY_4 then
        return "4"
    elseif whichKey == OSKEY_5 then
        return "5"
    elseif whichKey == OSKEY_6 then
        return "6"
    elseif whichKey == OSKEY_7 then
        return "7"
    elseif whichKey == OSKEY_8 then
        return "8"
    elseif whichKey == OSKEY_9 then
        return "9"
    elseif whichKey == OSKEY_0 then
        return "0"
    elseif whichKey == OSKEY_OEM_MINUS then
        return "-"
    elseif whichKey == OSKEY_OEM_PLUS then
        return "="
    elseif whichKey == OSKEY_Q then
        return "Q"
    elseif whichKey == OSKEY_W then
        return "W"
    elseif whichKey == OSKEY_E then
        return "E"
    elseif whichKey == OSKEY_R then
        return "R"
    elseif whichKey == OSKEY_A then
        return "A"
    elseif whichKey == OSKEY_S then
        return "S"
    elseif whichKey == OSKEY_D then
        return "D"
    elseif whichKey == OSKEY_F then
        return "F"
    elseif whichKey == OSKEY_Z then
        return "Z"
    elseif whichKey == OSKEY_X then
        return "X"
    elseif whichKey == OSKEY_C then
        return "C"
    elseif whichKey == OSKEY_V then
        return "V"
    endif
    return "?"
endfunction

private function MAB_GetAbilityIconPath takes integer abilityId returns string
    local integer entryIndex
    local integer addAbilityId
    local string iconPath = BlzGetAbilityIcon(abilityId)

    if iconPath == null or iconPath == "" then
        set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
        if entryIndex != 0 then
            set addAbilityId = AbilitiesPlayer_GetEntryAddAbilityId(entryIndex)
            if addAbilityId != 0 then
                set iconPath = BlzGetAbilityIcon(addAbilityId)
            endif
        endif
    endif
    if iconPath == null or iconPath == "" then
        set iconPath = MAB_EMPTY_ICON
    endif
    return iconPath
endfunction

private function MAB_GetElementalAbilityId takes integer index returns integer
    if index == 0 then
        return MAB_ELEMENTAL_AIR
    elseif index == 1 then
        return MAB_ELEMENTAL_WATER
    elseif index == 2 then
        return MAB_ELEMENTAL_FIRE
    endif
    return MAB_ELEMENTAL_EARTH
endfunction

private function MAB_IsElementalChoice takes integer abilityId returns boolean
    return abilityId == MAB_ELEMENTAL_AIR or abilityId == MAB_ELEMENTAL_WATER or abilityId == MAB_ELEMENTAL_FIRE or abilityId == MAB_ELEMENTAL_EARTH
endfunction

private function MAB_GetContextAbilityId takes unit whichHero, integer index returns integer
    if index == 0 then
        if GetUnitAbilityLevel(whichHero, MAB_STEALTH) > 0 then
            return MAB_STEALTH
        elseif GetUnitAbilityLevel(whichHero, MAB_STEALTH_ALT) > 0 then
            return MAB_STEALTH_ALT
        endif
    elseif GetUnitAbilityLevel(whichHero, MAB_BLOCK_100) > 0 then
        return MAB_BLOCK_100
    elseif GetUnitAbilityLevel(whichHero, MAB_BLOCK_75) > 0 then
        return MAB_BLOCK_75
    elseif GetUnitAbilityLevel(whichHero, MAB_BLOCK_50) > 0 then
        return MAB_BLOCK_50
    endif
    return 0
endfunction

private function MAB_UpdateContextSlots takes unit whichHero returns nothing
    local integer index = 0
    local integer abilityId
    local string iconPath

    loop
        exitwhen index >= MAB_CONTEXT_COUNT
        set abilityId = MAB_GetContextAbilityId(whichHero, index)
        if abilityId != MAB_ContextAbilityId[index] then
            set MAB_ContextAbilityId[index] = abilityId
            if abilityId != 0 then
                set iconPath = MAB_GetAbilityIconPath(abilityId)
                call BlzFrameSetTexture(MAB_ContextIcon[index], iconPath, 0, true)
            endif
            call BlzFrameSetVisible(MAB_ContextButton[index], abilityId != 0)
        endif
        set index = index + 1
    endloop

    set whichHero = null
endfunction

private function MAB_GetElementalLabel takes integer index returns string
    if index == 0 then
        return "Air"
    elseif index == 1 then
        return "Water"
    elseif index == 2 then
        return "Fire"
    endif
    return "Earth"
endfunction

private function MAB_Clamp takes real value returns real
    if value < 0.00 then
        return 0.00
    elseif value > 1.00 then
        return 1.00
    endif
    return value
endfunction

private function MAB_RegisterNativeFrame takes framehandle whichFrame returns nothing
    if whichFrame != null then
        set MAB_NativeFrame[MAB_NativeFrameCount] = whichFrame
        set MAB_NativeFrameCount = MAB_NativeFrameCount + 1
    endif
    set whichFrame = null
endfunction

private function MAB_FindNativeFrames takes nothing returns nothing
    local integer index = 0

    if MAB_NativeFrameCount > 0 then
        return
    endif

    call MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleBottomBar", 0))
    call MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleBottomBarOverlay", 0))
    call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BAR, 0))
    call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_PORTRAIT, 0))
    loop
        exitwhen index >= MAB_NATIVE_HERO_BUTTON_COUNT
        call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BUTTON, index))
        call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_HP_BAR, index))
        call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_MANA_BAR, index))
        call MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BUTTON_INDICATOR, index))
        set index = index + 1
    endloop
    // Keep this last so child visibility is captured before the parent hides.
    call MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleUIBackdrop", 0))
endfunction

private function MAB_CaptureNativeVisibility takes nothing returns nothing
    local integer index = 0

    if MAB_NativeCaptured or FullscreenUI_IsEnabled() then
        return
    endif

    call MAB_FindNativeFrames()
    loop
        exitwhen index >= MAB_NativeFrameCount
        set MAB_NativeWasVisible[index] = BlzFrameIsVisible(MAB_NativeFrame[index])
        set index = index + 1
    endloop
    set MAB_NativeCaptured = true
endfunction

private function MAB_HideNativeFrames takes nothing returns nothing
    local integer index = 0

    if not MAB_HIDE_NATIVE_BOTTOM_HUD then
        return
    endif

    call MAB_CaptureNativeVisibility()
    if not MAB_NativeCaptured then
        return
    endif
    loop
        exitwhen index >= MAB_NativeFrameCount
        if BlzFrameIsVisible(MAB_NativeFrame[index]) then
            call BlzFrameSetVisible(MAB_NativeFrame[index], false)
        endif
        set index = index + 1
    endloop
endfunction

private function MAB_RestoreNativeFrames takes nothing returns nothing
    local integer index = 0

    if not MAB_NativeCaptured then
        return
    endif
    loop
        exitwhen index >= MAB_NativeFrameCount
        call BlzFrameSetVisible(MAB_NativeFrame[index], MAB_NativeWasVisible[index])
        set index = index + 1
    endloop
    set MAB_NativeCaptured = false
endfunction

private function MAB_CloseTooltip takes nothing returns nothing
    if MAB_Tooltip != null then
        call BlzFrameSetVisible(MAB_Tooltip, false)
    endif
endfunction

private function MAB_SetParentVisible takes boolean visible returns nothing
    if MAB_ParentVisible != visible then
        set MAB_ParentVisible = visible
        call BlzFrameSetVisible(MAB_Parent, visible)
        if not visible then
            call MAB_CloseTooltip()
        endif
    endif
endfunction

private function MAB_ResetSlotCache takes nothing returns nothing
    local integer index = 0

    set MAB_CachedHero = null
    set MAB_StaticDirty = true
    set MAB_CachedTargetingAbility = -1
    set MAB_CachedTargetingMode = -1
    set MAB_CachedMana = -1
    set MAB_CachedLoadoutRevision = -1
    set MAB_LearnScanTick = 0
    set MAB_MoveSourceSlot = 0
    set MAB_RebindSlot = 0
    call MAB_CloseTooltip()
    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        set MAB_CachedAbilityId[index] = -1
        set MAB_CachedAbilityLevel[index] = -1
        set MAB_CachedManaCost[index] = -1
        set MAB_CachedCooldownSecond[index] = -1
        set MAB_CachedCooldownStep[index] = -1
        set MAB_CachedReady[index] = false
        set MAB_CachedDisabled[index] = false
        set MAB_CachedCooldownVisible[index] = false
        set MAB_CooldownActive[index] = false
        set MAB_CachedTitle[index] = ""
        set MAB_CachedBody[index] = ""
        set MAB_CachedIcon[index] = ""
        set index = index + 1
    endloop
endfunction

private function MAB_CloseElementalFlyout takes nothing returns nothing
    if not MAB_ElementalOpen then
        return
    endif
    set MAB_ElementalOpen = false
    set MAB_ElementalHero = null
    if MAB_ElementalBackdrop != null then
        call BlzFrameSetVisible(MAB_ElementalBackdrop, false)
    endif
endfunction

private function MAB_OpenElementalFlyout takes unit whichHero returns nothing
    if not MAB_IsPlayerHero(whichHero) or GetUnitAbilityLevel(whichHero, MAB_SUMMON_ELEMENTAL) <= 0 then
        set whichHero = null
        return
    endif

    set MAB_ElementalHero = whichHero
    set MAB_ElementalOpen = true
    call BlzFrameSetVisible(MAB_ElementalBackdrop, true)
    set whichHero = null
endfunction

private function MAB_UpdateElementalFlyout takes nothing returns nothing
    local integer index = 0
    local integer abilityId
    local integer abilityLevel
    local integer manaCost
    local real mana
    local boolean ready

    if not MAB_ElementalOpen then
        return
    endif
    if not MAB_IsPlayerHero(MAB_ElementalHero) or GetUnitAbilityLevel(MAB_ElementalHero, MAB_SUMMON_ELEMENTAL) <= 0 then
        call MAB_CloseElementalFlyout()
        return
    endif

    set mana = GetUnitState(MAB_ElementalHero, UNIT_STATE_MANA)
    loop
        exitwhen index >= MAB_ELEMENTAL_COUNT
        set abilityId = MAB_GetElementalAbilityId(index)
        set abilityLevel = GetUnitAbilityLevel(MAB_ElementalHero, abilityId)
        set manaCost = 0
        if abilityLevel > 0 then
            set manaCost = BlzGetUnitAbilityManaCost(MAB_ElementalHero, abilityId, abilityLevel - 1)
        endif
        set ready = abilityLevel > 0 and BlzGetUnitAbilityCooldownRemaining(MAB_ElementalHero, abilityId) <= 0.00 and mana + 0.01 >= I2R(manaCost)
        if MAB_ElementalReady[index] != ready then
            set MAB_ElementalReady[index] = ready
            call BlzFrameSetEnable(MAB_ElementalButton[index], ready)
            call BlzFrameSetVisible(MAB_ElementalDisabled[index], not ready)
        endif
        set index = index + 1
    endloop
endfunction

private function MAB_SetCooldownVisual takes integer index, unit whichHero, integer abilityId, integer abilityLevel returns nothing
    local real remaining = BlzGetUnitAbilityCooldownRemaining(whichHero, abilityId)
    local real total
    local integer second
    local integer step

    if remaining > 0.00 then
        set MAB_CooldownActive[index] = true
        set total = BlzGetUnitAbilityCooldown(whichHero, abilityId, abilityLevel - 1)
        if total > 0.00 then
            set step = R2I(MAB_Clamp(remaining / total) * I2R(MAB_COOLDOWN_STEPS))
        else
            set step = MAB_COOLDOWN_STEPS
        endif
        if step < 1 then
            set step = 1
        endif
        if step != MAB_CachedCooldownStep[index] then
            set MAB_CachedCooldownStep[index] = step
            call BlzFrameSetSize(MAB_SlotCooldown[index], MAB_ACTION_SIZE - 0.004, (MAB_ACTION_SIZE - 0.004) * I2R(step) / I2R(MAB_COOLDOWN_STEPS))
        endif
        set second = R2I(remaining + 0.99)
        if second != MAB_CachedCooldownSecond[index] then
            set MAB_CachedCooldownSecond[index] = second
            call BlzFrameSetText(MAB_SlotCooldownText[index], I2S(second))
        endif
        if not MAB_CachedCooldownVisible[index] then
            set MAB_CachedCooldownVisible[index] = true
            call BlzFrameSetVisible(MAB_SlotCooldown[index], true)
            call BlzFrameSetVisible(MAB_SlotCooldownText[index], true)
        endif
    else
        set MAB_CooldownActive[index] = false
        if MAB_CachedCooldownVisible[index] then
            set MAB_CachedCooldownVisible[index] = false
            set MAB_CachedCooldownSecond[index] = -1
            set MAB_CachedCooldownStep[index] = -1
            call BlzFrameSetVisible(MAB_SlotCooldown[index], false)
            call BlzFrameSetVisible(MAB_SlotCooldownText[index], false)
        endif
    endif

    set whichHero = null
endfunction

private function MAB_UpdateSlotStatic takes integer index, unit whichHero returns nothing
    local integer slot = index + 1
    local integer abilityId = ModernAbilityLoadout_GetEffectiveAbilityId(whichHero, slot)
    local integer entryIndex
    local integer abilityLevel = 0
    local string iconPath
    local boolean ready

    if abilityId != 0 then
        set abilityLevel = GetUnitAbilityLevel(whichHero, abilityId)
    endif
    if not MAB_StaticDirty and abilityId == MAB_CachedAbilityId[index] and abilityLevel == MAB_CachedAbilityLevel[index] then
        set whichHero = null
        return
    endif

    set MAB_CachedAbilityId[index] = abilityId
    set MAB_CachedAbilityLevel[index] = abilityLevel
    set MAB_CachedCooldownSecond[index] = -1
    set MAB_CachedCooldownStep[index] = -1
    set MAB_CooldownActive[index] = false
    if MAB_CachedCooldownVisible[index] then
        set MAB_CachedCooldownVisible[index] = false
        call BlzFrameSetVisible(MAB_SlotCooldown[index], false)
        call BlzFrameSetVisible(MAB_SlotCooldownText[index], false)
    endif

    if abilityId == 0 then
        set MAB_CachedManaCost[index] = 0
        set MAB_CachedReady[index] = false
        set MAB_CachedDisabled[index] = false
        set MAB_CachedTitle[index] = "Empty slot"
        set MAB_CachedBody[index] = "Choose a learned ability from the Abilities book."
        set MAB_CachedIcon[index] = MAB_EMPTY_ICON
        call BlzFrameSetTexture(MAB_SlotIcon[index], MAB_EMPTY_ICON, 0, true)
        call BlzFrameSetVisible(MAB_SlotIcon[index], false)
        call BlzFrameSetVisible(MAB_SlotDisabled[index], false)
        // Empty slots stay interactive so a player can move an ability into one.
        call BlzFrameSetEnable(MAB_SlotButton[index], true)
        set whichHero = null
        return
    endif

    set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
    set ready = abilityLevel > 0 and ModernAbilityCatalog_IsRuntimeReady(abilityId)
    set iconPath = MAB_GetAbilityIconPath(abilityId)

    set MAB_CachedIcon[index] = iconPath
    set MAB_CachedReady[index] = ready
    set MAB_CachedDisabled[index] = false
    set MAB_CachedTitle[index] = AbilitiesPlayer_GetEntryTitle(entryIndex)
    set MAB_CachedBody[index] = AbilitiesPlayer_GetEntryBodyForLevel(entryIndex, abilityLevel)
    if abilityLevel > 0 then
        set MAB_CachedManaCost[index] = BlzGetUnitAbilityManaCost(whichHero, abilityId, abilityLevel - 1)
    else
        set MAB_CachedManaCost[index] = 0
    endif

    call BlzFrameSetTexture(MAB_SlotIcon[index], MAB_CachedIcon[index], 0, true)
    call BlzFrameSetVisible(MAB_SlotIcon[index], true)
    call BlzFrameSetVisible(MAB_SlotDisabled[index], false)
    call BlzFrameSetEnable(MAB_SlotButton[index], true)
    set whichHero = null
endfunction

private function MAB_UpdateSlotReadiness takes integer index, unit whichHero, real mana returns nothing
    local integer abilityId = MAB_CachedAbilityId[index]
    local integer abilityLevel = MAB_CachedAbilityLevel[index]
    local boolean disabled

    if abilityId <= 0 or abilityLevel <= 0 then
        set whichHero = null
        return
    endif

    set disabled = not MAB_CachedReady[index] or mana + 0.01 < I2R(MAB_CachedManaCost[index])
    if disabled != MAB_CachedDisabled[index] then
        set MAB_CachedDisabled[index] = disabled
        call BlzFrameSetVisible(MAB_SlotDisabled[index], disabled)
    endif
    set whichHero = null
endfunction

private function MAB_UpdateCooldowns takes unit whichHero, boolean discover returns nothing
    local integer index = 0

    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        if (discover or MAB_CooldownActive[index]) and MAB_CachedAbilityId[index] > 0 and MAB_CachedAbilityLevel[index] > 0 then
            call MAB_SetCooldownVisual(index, whichHero, MAB_CachedAbilityId[index], MAB_CachedAbilityLevel[index])
        endif
        set index = index + 1
    endloop

    set whichHero = null
endfunction

private function MAB_UpdateTargetingText takes nothing returns nothing
    local player localPlayer = GetLocalPlayer()
    local integer abilityId = AbilitiesLiteUI_GetModernPendingAbilityId()
    local integer mode = 0
    local integer payload = 0
    local integer entryIndex = 0
    local string text = ""

    if abilityId > 0 then
        set mode = 1
        set payload = abilityId
    elseif MAB_RebindSlot > 0 then
        set mode = 2
        set payload = MAB_RebindSlot
    elseif MAB_MoveSourceSlot > 0 then
        set mode = 3
        set payload = MAB_MoveSourceSlot
    elseif ModernAbilityController_IsTargetingLocal(localPlayer) then
        set mode = 4
        set abilityId = ModernAbilityController_GetPendingAbilityId(localPlayer)
        set payload = abilityId
    endif

    if mode != MAB_CachedTargetingMode or payload != MAB_CachedTargetingAbility then
        set MAB_CachedTargetingMode = mode
        set MAB_CachedTargetingAbility = payload
        if mode == 1 then
            set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(payload)
            set text = "|cffffcc00Assign " + AbilitiesPlayer_GetEntryTitle(entryIndex) + ":|r click an action-bar slot.  |cffaaaaaa(Right-click another ability to change selection)|r"
        elseif mode == 2 then
            set text = "|cffffcc00Rebind slot " + I2S(payload) + ":|r press 1-0, -, =, QWER, ASDF, or ZXCV.  |cffaaaaaa(Right-click a slot to cancel)|r"
        elseif mode == 3 then
            set text = "|cffffcc00Move slot " + I2S(payload) + ":|r click another slot to swap.  |cffaaaaaa(Right-click the source again to cancel)|r"
        elseif mode == 4 then
            set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
            set text = "|cffffcc00Choose target:|r " + AbilitiesPlayer_GetEntryTitle(entryIndex) + "  |cffaaaaaa(Right-click cancels)|r"
        endif
        if mode > 0 then
            call BlzFrameSetText(MAB_TargetingText, text)
        endif
    endif

    if mode > 0 then
        if not MAB_TargetingVisible then
            set MAB_TargetingVisible = true
            call BlzFrameSetVisible(MAB_TargetingText, true)
        endif
    elseif MAB_TargetingVisible then
        set MAB_TargetingVisible = false
        call BlzFrameSetVisible(MAB_TargetingText, false)
    endif

    set localPlayer = null
endfunction

private function MAB_Update takes nothing returns nothing
    local unit whichHero = MAB_SelectedUnit
    local integer index = 0
    local string heroIcon
    local integer mana
    local boolean rebuild
    local integer revision

    if not MAB_Enabled or not ModernPlayerHUD_IsEnabled() or FullscreenUI_IsEnabled() then
        if FullscreenUI_IsEnabled() then
            set MAB_WasFullscreen = true
        endif
        call MAB_SetParentVisible(false)
        call MAB_CloseElementalFlyout()
        set whichHero = null
        return
    endif

    if MAB_WasFullscreen or not MAB_NativeCaptured then
        set MAB_WasFullscreen = false
        call MAB_HideNativeFrames()
    endif
    if not MAB_IsValidUnit(whichHero) and GetLocalPlayer() == Player(0) and MAB_IsValidUnit(udg_Nazgrek) then
        set whichHero = udg_Nazgrek
        set MAB_SelectedUnit = whichHero
    endif
    if not MAB_IsPlayerHero(whichHero) then
        call MAB_SetParentVisible(false)
        call MAB_CloseElementalFlyout()
        set whichHero = null
        return
    endif

    if MAB_CachedHero != whichHero then
        call MAB_ResetSlotCache()
        set MAB_CachedHero = whichHero
        set heroIcon = BlzGetAbilityIcon(GetUnitTypeId(whichHero))
        if heroIcon == null or heroIcon == "" then
            set heroIcon = MAB_EMPTY_ICON
        endif
        call BlzFrameSetTexture(MAB_HeroIcon, heroIcon, 0, true)
    endif

    set MAB_LearnScanTick = MAB_LearnScanTick + 1
    if MAB_LearnScanTick >= 8 then
        set MAB_LearnScanTick = 0
        call ModernAbilityLoadout_AppendNewLearned(whichHero)
    endif
    set revision = ModernAbilityLoadout_GetRevision(whichHero)
    if revision != MAB_CachedLoadoutRevision then
        set MAB_CachedLoadoutRevision = revision
        set MAB_StaticDirty = true
    endif

    call MAB_SetParentVisible(true)
    set rebuild = MAB_StaticDirty
    if rebuild then
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            call MAB_UpdateSlotStatic(index, whichHero)
            set index = index + 1
        endloop
        set MAB_StaticDirty = false
    endif

    set mana = R2I(GetUnitState(whichHero, UNIT_STATE_MANA))
    if rebuild or mana != MAB_CachedMana then
        set MAB_CachedMana = mana
        set index = 0
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            call MAB_UpdateSlotReadiness(index, whichHero, I2R(mana))
            set index = index + 1
        endloop
    endif
    call MAB_UpdateCooldowns(whichHero, rebuild)
    call MAB_UpdateContextSlots(whichHero)
    if MAB_ElementalOpen then
        call MAB_UpdateElementalFlyout()
    endif
    call MAB_UpdateTargetingText()

    set whichHero = null
endfunction

private function MAB_ClearFocusAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()

    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
    endif
    set triggerFrame = null
endfunction

private function MAB_ActivateSlotLocal takes player whichPlayer, integer index returns nothing
    local integer abilityId

    if whichPlayer != GetLocalPlayer() or index < 0 or index >= ModernAbilityLoadout_SLOT_COUNT or not MAB_IsPlayerHero(MAB_SelectedUnit) then
        set whichPlayer = null
        return
    endif

    set abilityId = ModernAbilityLoadout_GetEffectiveAbilityId(MAB_SelectedUnit, index + 1)
    if abilityId == MAB_SUMMON_ELEMENTAL then
        if MAB_ElementalOpen and MAB_ElementalHero == MAB_SelectedUnit then
            call MAB_CloseElementalFlyout()
        else
            call MAB_OpenElementalFlyout(MAB_SelectedUnit)
            call MAB_UpdateElementalFlyout()
        endif
    else
        call MAB_CloseElementalFlyout()
        call ModernAbilityController_BeginLocal(whichPlayer, MAB_SelectedUnit, index + 1)
    endif

    set whichPlayer = null
endfunction

private function MAB_SlotAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local player triggerPlayer = GetTriggerPlayer()
    local integer index = 0
    local integer slot
    local boolean rightClick

    if triggerPlayer == GetLocalPlayer() and MAB_IsPlayerHero(MAB_SelectedUnit) then
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            if triggerFrame == MAB_SlotButton[index] then
                set slot = index + 1
                set rightClick = BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT
                if rightClick then
                    call ModernAbilityController_CancelLocal(triggerPlayer)
                    call MAB_CloseElementalFlyout()
                    if BlzIsMetaKeyPressed(1) then
                        set MAB_MoveSourceSlot = 0
                        if MAB_RebindSlot == slot then
                            set MAB_RebindSlot = 0
                        else
                            set MAB_RebindSlot = slot
                        endif
                    elseif MAB_MoveSourceSlot == slot then
                        set MAB_MoveSourceSlot = 0
                        set MAB_RebindSlot = 0
                    else
                        set MAB_MoveSourceSlot = slot
                        set MAB_RebindSlot = 0
                    endif
                elseif AbilitiesLiteUI_GetModernPendingAbilityId() > 0 then
                    call ModernAbilityController_AssignSlotLocal(triggerPlayer, MAB_SelectedUnit, slot, AbilitiesLiteUI_GetModernPendingAbilityId())
                    call AbilitiesLiteUI_ClearModernPendingAbility()
                    set MAB_MoveSourceSlot = 0
                    set MAB_RebindSlot = 0
                elseif MAB_MoveSourceSlot > 0 then
                    call ModernAbilityController_SwapSlotsLocal(triggerPlayer, MAB_SelectedUnit, MAB_MoveSourceSlot, slot)
                    set MAB_MoveSourceSlot = 0
                    set MAB_RebindSlot = 0
                elseif MAB_CachedAbilityId[index] > 0 then
                    call MAB_ActivateSlotLocal(triggerPlayer, index)
                endif
                set index = ModernAbilityLoadout_SLOT_COUNT
            else
                set index = index + 1
            endif
        endloop
    endif

    set triggerFrame = null
    set triggerPlayer = null
endfunction

private function MAB_GetKeySlot takes oskeytype whichKey returns integer
    local integer index = 0

    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        if MAB_SlotKey[index] == whichKey then
            return index
        endif
        set index = index + 1
    endloop
    return -1
endfunction

private function MAB_KeyAction takes nothing returns nothing
    local player triggerPlayer = GetTriggerPlayer()
    local oskeytype triggerKey = BlzGetTriggerPlayerKey()
    local integer slot = MAB_GetKeySlot(triggerKey)
    local integer previousSlot
    local oskeytype previousKey
    local string previousLabel

    if triggerPlayer == GetLocalPlayer() and MAB_RebindSlot > 0 then
        set previousSlot = slot
        set slot = MAB_RebindSlot - 1
        set previousKey = MAB_SlotKey[slot]
        set previousLabel = MAB_SlotKeyLabel[slot]
        set MAB_SlotKey[slot] = triggerKey
        set MAB_SlotKeyLabel[slot] = MAB_GetKeyLabel(triggerKey)
        call BlzFrameSetText(MAB_SlotKeyText[slot], MAB_SlotKeyLabel[slot])
        if previousSlot >= 0 and previousSlot != slot then
            set MAB_SlotKey[previousSlot] = previousKey
            set MAB_SlotKeyLabel[previousSlot] = previousLabel
            call BlzFrameSetText(MAB_SlotKeyText[previousSlot], previousLabel)
        endif
        set MAB_RebindSlot = 0
        set previousKey = null
        set triggerKey = null
        set triggerPlayer = null
        return
    endif

    if triggerPlayer == GetLocalPlayer() and AbilitiesLiteUI_GetModernPendingAbilityId() > 0 and slot >= 0 then
        call ModernAbilityController_AssignSlotLocal(triggerPlayer, MAB_SelectedUnit, slot + 1, AbilitiesLiteUI_GetModernPendingAbilityId())
        call AbilitiesLiteUI_ClearModernPendingAbility()
        set triggerKey = null
        set triggerPlayer = null
        return
    endif

    if triggerPlayer == GetLocalPlayer() and MAB_Enabled and MAB_ParentVisible and not FullscreenUI_IsEnabled() and slot >= 0 then
        call MAB_ActivateSlotLocal(triggerPlayer, slot)
    endif

    set triggerKey = null
    set triggerPlayer = null
endfunction

private function MAB_ElementalAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local player triggerPlayer = GetTriggerPlayer()
    local integer index = 0

    if triggerPlayer == GetLocalPlayer() and MAB_ElementalOpen and MAB_IsPlayerHero(MAB_ElementalHero) then
        loop
            exitwhen index >= MAB_ELEMENTAL_COUNT
            if triggerFrame == MAB_ElementalButton[index] then
                call ModernAbilityController_BeginElementalLocal(triggerPlayer, MAB_ElementalHero, MAB_GetElementalAbilityId(index))
                call MAB_CloseElementalFlyout()
                set index = MAB_ELEMENTAL_COUNT
            else
                set index = index + 1
            endif
        endloop
    endif

    set triggerFrame = null
    set triggerPlayer = null
endfunction

private function MAB_ContextAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local player triggerPlayer = GetTriggerPlayer()
    local integer index = 0

    if triggerPlayer == GetLocalPlayer() and MAB_IsPlayerHero(MAB_SelectedUnit) then
        loop
            exitwhen index >= MAB_CONTEXT_COUNT
            if triggerFrame == MAB_ContextButton[index] then
                call MAB_CloseElementalFlyout()
                call ModernAbilityController_CancelLocal(triggerPlayer)
                call ModernAbilityController_BeginContextLocal(triggerPlayer, MAB_SelectedUnit, MAB_ContextAbilityId[index])
                set index = MAB_CONTEXT_COUNT
            else
                set index = index + 1
            endif
        endloop
    endif

    set triggerPlayer = null
    set triggerFrame = null
endfunction

private function MAB_HoverAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()
    local frameeventtype triggerEvent = BlzGetTriggerFrameEvent()
    local integer index = 0

    if GetTriggerPlayer() == GetLocalPlayer() then
        if triggerEvent == FRAMEEVENT_MOUSE_LEAVE then
            call MAB_CloseTooltip()
            set triggerEvent = null
            set triggerFrame = null
            return
        endif
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            if triggerFrame == MAB_SlotButton[index] then
                if MAB_CachedAbilityId[index] > 0 then
                    if MAB_CachedReady[index] then
                        call BlzFrameSetText(MAB_TooltipTitle, "|cffffcc00" + MAB_CachedTitle[index] + "|r")
                    else
                        call BlzFrameSetText(MAB_TooltipTitle, "|cffff5555" + MAB_CachedTitle[index] + "|r")
                    endif
                    call BlzFrameSetText(MAB_TooltipBody, MAB_CachedBody[index])
                else
                    call BlzFrameSetText(MAB_TooltipTitle, "|cffaaaaaaEmpty slot|r")
                    call BlzFrameSetText(MAB_TooltipBody, "Choose a learned ability from the Abilities book.")
                endif
                call BlzFrameSetVisible(MAB_Tooltip, true)
                set index = ModernAbilityLoadout_SLOT_COUNT
            else
                set index = index + 1
            endif
        endloop
    endif

    set triggerEvent = null
    set triggerFrame = null
endfunction

private function MAB_CreateTooltip takes nothing returns nothing
    set MAB_Tooltip = BlzCreateFrameByType("BACKDROP", "ModernAbilityTooltip", MAB_ScreenParent, "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(MAB_Tooltip, FRAMEPOINT_BOTTOM, 0.400, 0.130)
    call BlzFrameSetSize(MAB_Tooltip, MAB_TOOLTIP_WIDTH, MAB_TOOLTIP_HEIGHT)
    call BlzFrameSetEnable(MAB_Tooltip, false)
    call BlzFrameSetLevel(MAB_Tooltip, 40)

    set MAB_TooltipTitle = BlzCreateFrameByType("TEXT", "ModernAbilityTooltipTitle", MAB_Tooltip, "", 0)
    call BlzFrameSetPoint(MAB_TooltipTitle, FRAMEPOINT_TOPLEFT, MAB_Tooltip, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
    call BlzFrameSetSize(MAB_TooltipTitle, MAB_TOOLTIP_WIDTH - 0.020, 0.016)
    call BlzFrameSetTextAlignment(MAB_TooltipTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(MAB_TooltipTitle, 0.86)
    call BlzFrameSetEnable(MAB_TooltipTitle, false)

    set MAB_TooltipBody = BlzCreateFrameByType("TEXT", "ModernAbilityTooltipBody", MAB_Tooltip, "", 0)
    call BlzFrameSetPoint(MAB_TooltipBody, FRAMEPOINT_TOPLEFT, MAB_TooltipTitle, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.006)
    call BlzFrameSetSize(MAB_TooltipBody, MAB_TOOLTIP_WIDTH - 0.020, MAB_TOOLTIP_HEIGHT - 0.036)
    call BlzFrameSetTextAlignment(MAB_TooltipBody, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(MAB_TooltipBody, 0.72)
    call BlzFrameSetEnable(MAB_TooltipBody, false)
    call BlzFrameSetVisible(MAB_Tooltip, false)
endfunction

private function MAB_CreateSlot takes integer index returns nothing
    local real x = MAB_ACTION_START_X + I2R(index) * (MAB_ACTION_SIZE + MAB_ACTION_GAP)

    set MAB_SlotButton[index] = BlzCreateFrameByType("BUTTON", "ModernAbilityActionButton" + I2S(index), MAB_Parent, "", 0)
    call BlzFrameSetAbsPoint(MAB_SlotButton[index], FRAMEPOINT_BOTTOMLEFT, x, MAB_ACTION_BOTTOM)
    call BlzFrameSetSize(MAB_SlotButton[index], MAB_ACTION_SIZE, MAB_ACTION_SIZE)
    call BlzFrameSetLevel(MAB_SlotButton[index], 4)

    set MAB_SlotIcon[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityActionIcon" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetPoint(MAB_SlotIcon[index], FRAMEPOINT_BOTTOMLEFT, MAB_SlotButton[index], FRAMEPOINT_BOTTOMLEFT, 0.002, 0.002)
    call BlzFrameSetPoint(MAB_SlotIcon[index], FRAMEPOINT_TOPRIGHT, MAB_SlotButton[index], FRAMEPOINT_TOPRIGHT, -0.002, -0.002)
    call BlzFrameSetEnable(MAB_SlotIcon[index], false)
    call BlzFrameSetLevel(MAB_SlotIcon[index], 5)

    set MAB_SlotCooldown[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityCooldown" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetTexture(MAB_SlotCooldown[index], MAB_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(MAB_SlotCooldown[index], FRAMEPOINT_BOTTOM, MAB_SlotIcon[index], FRAMEPOINT_BOTTOM, 0.000, 0.000)
    call BlzFrameSetVertexColor(MAB_SlotCooldown[index], BlzConvertColor(190, 0, 0, 0))
    call BlzFrameSetEnable(MAB_SlotCooldown[index], false)
    call BlzFrameSetLevel(MAB_SlotCooldown[index], 6)

    set MAB_SlotDisabled[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityDisabled" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetTexture(MAB_SlotDisabled[index], MAB_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetAllPoints(MAB_SlotDisabled[index], MAB_SlotIcon[index])
    call BlzFrameSetVertexColor(MAB_SlotDisabled[index], BlzConvertColor(150, 30, 30, 30))
    call BlzFrameSetEnable(MAB_SlotDisabled[index], false)
    call BlzFrameSetLevel(MAB_SlotDisabled[index], 7)

    set MAB_SlotCooldownText[index] = BlzCreateFrameByType("TEXT", "ModernAbilityCooldownText" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetAllPoints(MAB_SlotCooldownText[index], MAB_SlotButton[index])
    call BlzFrameSetTextAlignment(MAB_SlotCooldownText[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MAB_SlotCooldownText[index], 0.82)
    call BlzFrameSetEnable(MAB_SlotCooldownText[index], false)
    call BlzFrameSetLevel(MAB_SlotCooldownText[index], 8)

    set MAB_SlotKeyText[index] = BlzCreateFrameByType("TEXT", "ModernAbilityKeyText" + I2S(index), MAB_SlotButton[index], "", 0)
    call BlzFrameSetPoint(MAB_SlotKeyText[index], FRAMEPOINT_TOPLEFT, MAB_SlotButton[index], FRAMEPOINT_TOPLEFT, 0.003, -0.002)
    call BlzFrameSetSize(MAB_SlotKeyText[index], 0.012, 0.010)
    call BlzFrameSetTextAlignment(MAB_SlotKeyText[index], TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(MAB_SlotKeyText[index], 0.60)
        call BlzFrameSetText(MAB_SlotKeyText[index], MAB_SlotKeyLabel[index])
    call BlzFrameSetEnable(MAB_SlotKeyText[index], false)
    call BlzFrameSetLevel(MAB_SlotKeyText[index], 9)

    call BlzTriggerRegisterFrameEvent(MAB_SlotTrigger, MAB_SlotButton[index], FRAMEEVENT_MOUSE_DOWN)
    call BlzTriggerRegisterFrameEvent(MAB_ClearFocusTrigger, MAB_SlotButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MAB_HoverTrigger, MAB_SlotButton[index], FRAMEEVENT_MOUSE_ENTER)
    call BlzTriggerRegisterFrameEvent(MAB_HoverTrigger, MAB_SlotButton[index], FRAMEEVENT_MOUSE_LEAVE)
endfunction

private function MAB_CreateElementalFlyout takes nothing returns nothing
    local integer index = 0
    local integer abilityId
    local real x
    local string iconPath

    set MAB_ElementalBackdrop = BlzCreateFrameByType("BACKDROP", "ModernElementalFlyoutBackdrop", MAB_Parent, "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(MAB_ElementalBackdrop, FRAMEPOINT_BOTTOMLEFT, 0.304, 0.115)
    call BlzFrameSetSize(MAB_ElementalBackdrop, 0.192, 0.064)
    call BlzFrameSetLevel(MAB_ElementalBackdrop, 34)

    set MAB_ElementalTitle = BlzCreateFrameByType("TEXT", "ModernElementalFlyoutTitle", MAB_ElementalBackdrop, "", 0)
    call BlzFrameSetPoint(MAB_ElementalTitle, FRAMEPOINT_TOP, MAB_ElementalBackdrop, FRAMEPOINT_TOP, 0.000, -0.005)
    call BlzFrameSetSize(MAB_ElementalTitle, 0.160, 0.012)
    call BlzFrameSetTextAlignment(MAB_ElementalTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MAB_ElementalTitle, 0.72)
    call BlzFrameSetText(MAB_ElementalTitle, "Choose Elemental")
    call BlzFrameSetEnable(MAB_ElementalTitle, false)
    call BlzFrameSetLevel(MAB_ElementalTitle, 35)

    loop
        exitwhen index >= MAB_ELEMENTAL_COUNT
        set abilityId = MAB_GetElementalAbilityId(index)
        set x = MAB_ELEMENTAL_START_X + I2R(index) * (MAB_ELEMENTAL_SIZE + MAB_ELEMENTAL_GAP)
        set iconPath = MAB_GetAbilityIconPath(abilityId)

        set MAB_ElementalButton[index] = BlzCreateFrameByType("GLUEBUTTON", "ModernElementalFlyoutButton" + I2S(index), MAB_ElementalBackdrop, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetAbsPoint(MAB_ElementalButton[index], FRAMEPOINT_BOTTOMLEFT, x, MAB_ELEMENTAL_BOTTOM)
        call BlzFrameSetSize(MAB_ElementalButton[index], MAB_ELEMENTAL_SIZE, MAB_ELEMENTAL_SIZE)
        call BlzFrameSetLevel(MAB_ElementalButton[index], 36)

        set MAB_ElementalIcon[index] = BlzCreateFrameByType("BACKDROP", "ModernElementalFlyoutIcon" + I2S(index), MAB_ElementalButton[index], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(MAB_ElementalIcon[index], FRAMEPOINT_BOTTOMLEFT, MAB_ElementalButton[index], FRAMEPOINT_BOTTOMLEFT, 0.002, 0.002)
        call BlzFrameSetPoint(MAB_ElementalIcon[index], FRAMEPOINT_TOPRIGHT, MAB_ElementalButton[index], FRAMEPOINT_TOPRIGHT, -0.002, -0.002)
        call BlzFrameSetTexture(MAB_ElementalIcon[index], iconPath, 0, true)
        call BlzFrameSetEnable(MAB_ElementalIcon[index], false)
        call BlzFrameSetLevel(MAB_ElementalIcon[index], 37)

        set MAB_ElementalDisabled[index] = BlzCreateFrameByType("BACKDROP", "ModernElementalFlyoutDisabled" + I2S(index), MAB_ElementalButton[index], "", 0)
        call BlzFrameSetTexture(MAB_ElementalDisabled[index], MAB_SURFACE_TEXTURE, 0, false)
        call BlzFrameSetAllPoints(MAB_ElementalDisabled[index], MAB_ElementalIcon[index])
        call BlzFrameSetVertexColor(MAB_ElementalDisabled[index], BlzConvertColor(160, 25, 25, 25))
        call BlzFrameSetEnable(MAB_ElementalDisabled[index], false)
        call BlzFrameSetLevel(MAB_ElementalDisabled[index], 38)
        call BlzFrameSetEnable(MAB_ElementalButton[index], false)
        call BlzFrameSetVisible(MAB_ElementalDisabled[index], true)
        set MAB_ElementalReady[index] = false

        set MAB_ElementalLabel[index] = BlzCreateFrameByType("TEXT", "ModernElementalFlyoutLabel" + I2S(index), MAB_ElementalButton[index], "", 0)
        call BlzFrameSetPoint(MAB_ElementalLabel[index], FRAMEPOINT_BOTTOM, MAB_ElementalButton[index], FRAMEPOINT_BOTTOM, 0.000, 0.002)
        call BlzFrameSetSize(MAB_ElementalLabel[index], MAB_ELEMENTAL_SIZE - 0.004, 0.010)
        call BlzFrameSetTextAlignment(MAB_ElementalLabel[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(MAB_ElementalLabel[index], 0.58)
        call BlzFrameSetText(MAB_ElementalLabel[index], MAB_GetElementalLabel(index))
        call BlzFrameSetEnable(MAB_ElementalLabel[index], false)
        call BlzFrameSetLevel(MAB_ElementalLabel[index], 39)

        call BlzTriggerRegisterFrameEvent(MAB_ElementalTrigger, MAB_ElementalButton[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(MAB_ClearFocusTrigger, MAB_ElementalButton[index], FRAMEEVENT_CONTROL_CLICK)
        set index = index + 1
    endloop

    call BlzFrameSetVisible(MAB_ElementalBackdrop, false)
endfunction

private function MAB_CreateContextSlot takes integer index, real x, string label returns nothing
    set MAB_ContextButton[index] = BlzCreateFrameByType("BUTTON", "ModernAbilityContextButton" + I2S(index), MAB_Parent, "", 0)
    call BlzFrameSetAbsPoint(MAB_ContextButton[index], FRAMEPOINT_BOTTOMLEFT, x, 0.075)
    call BlzFrameSetSize(MAB_ContextButton[index], 0.028, 0.028)
    call BlzFrameSetLevel(MAB_ContextButton[index], 14)

    set MAB_ContextIcon[index] = BlzCreateFrameByType("BACKDROP", "ModernAbilityContextIcon" + I2S(index), MAB_ContextButton[index], "IconButtonTemplate", 0)
    call BlzFrameSetPoint(MAB_ContextIcon[index], FRAMEPOINT_BOTTOMLEFT, MAB_ContextButton[index], FRAMEPOINT_BOTTOMLEFT, 0.002, 0.002)
    call BlzFrameSetPoint(MAB_ContextIcon[index], FRAMEPOINT_TOPRIGHT, MAB_ContextButton[index], FRAMEPOINT_TOPRIGHT, -0.002, -0.002)
    call BlzFrameSetEnable(MAB_ContextIcon[index], false)
    call BlzFrameSetLevel(MAB_ContextIcon[index], 15)

    set MAB_ContextLabel[index] = BlzCreateFrameByType("TEXT", "ModernAbilityContextLabel" + I2S(index), MAB_ContextButton[index], "", 0)
    call BlzFrameSetPoint(MAB_ContextLabel[index], FRAMEPOINT_BOTTOMRIGHT, MAB_ContextButton[index], FRAMEPOINT_BOTTOMRIGHT, -0.002, 0.001)
    call BlzFrameSetSize(MAB_ContextLabel[index], 0.016, 0.009)
    call BlzFrameSetTextAlignment(MAB_ContextLabel[index], TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_RIGHT)
    call BlzFrameSetScale(MAB_ContextLabel[index], 0.48)
    call BlzFrameSetText(MAB_ContextLabel[index], label)
    call BlzFrameSetEnable(MAB_ContextLabel[index], false)
    call BlzFrameSetLevel(MAB_ContextLabel[index], 16)

    call BlzTriggerRegisterFrameEvent(MAB_ContextTrigger, MAB_ContextButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MAB_ClearFocusTrigger, MAB_ContextButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzFrameSetVisible(MAB_ContextButton[index], false)
endfunction

private function MAB_CreateFrames takes nothing returns nothing
    local integer index = 0

    if MAB_FramesCreated then
        return
    endif
    set MAB_FramesCreated = true
    set MAB_ScreenParent = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    set MAB_Parent = BlzCreateFrameByType("FRAME", "ModernAbilityActionBar", MAB_ScreenParent, "", 0)
    // Full-screen FRAME parents consume mouse input even without a texture.
    // Children use absolute points, so keep this logical parent effectively empty.
    call BlzFrameSetSize(MAB_Parent, 0.0001, 0.0001)
    call BlzFrameSetAbsPoint(MAB_Parent, FRAMEPOINT_BOTTOMLEFT, 0.000, 0.000)
    call BlzFrameSetLevel(MAB_Parent, 30)

    set MAB_HeroBorder = BlzCreateFrameByType("BACKDROP", "ModernAbilityHeroBorder", MAB_Parent, "", 0)
    call BlzFrameSetTexture(MAB_HeroBorder, MAB_MEDALLION_TEXTURE, 0, true)
    call BlzFrameSetAbsPoint(MAB_HeroBorder, FRAMEPOINT_BOTTOMLEFT, 0.132, 0.010)
    call BlzFrameSetSize(MAB_HeroBorder, 0.056, 0.056)
    call BlzFrameSetEnable(MAB_HeroBorder, false)
    call BlzFrameSetLevel(MAB_HeroBorder, 4)

    set MAB_HeroIcon = BlzCreateFrameByType("BACKDROP", "ModernAbilityHeroIcon", MAB_HeroBorder, "", 0)
    call BlzFrameSetPoint(MAB_HeroIcon, FRAMEPOINT_BOTTOMLEFT, MAB_HeroBorder, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)
    call BlzFrameSetPoint(MAB_HeroIcon, FRAMEPOINT_TOPRIGHT, MAB_HeroBorder, FRAMEPOINT_TOPRIGHT, -0.006, -0.006)
    call BlzFrameSetEnable(MAB_HeroIcon, false)
    call BlzFrameSetLevel(MAB_HeroIcon, 5)

    call MAB_CreateTooltip()
    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        call MAB_CreateSlot(index)
        set index = index + 1
    endloop
    call MAB_CreateElementalFlyout()
    call MAB_CreateContextSlot(0, 0.128, "Stealth")
    call MAB_CreateContextSlot(1, 0.158, "Block")

    set MAB_TargetingText = BlzCreateFrameByType("TEXT", "ModernAbilityTargetingText", MAB_Parent, "", 0)
    call BlzFrameSetAbsPoint(MAB_TargetingText, FRAMEPOINT_BOTTOM, 0.400, 0.151)
    call BlzFrameSetSize(MAB_TargetingText, 0.420, 0.016)
    call BlzFrameSetTextAlignment(MAB_TargetingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MAB_TargetingText, 0.78)
    call BlzFrameSetEnable(MAB_TargetingText, false)
    call BlzFrameSetLevel(MAB_TargetingText, 12)
    call BlzFrameSetVisible(MAB_TargetingText, false)
    call BlzFrameSetVisible(MAB_Parent, false)
endfunction

public function Refresh takes nothing returns nothing
    call ModernAbilityLoadout_RefreshDefaults(MAB_SelectedUnit)
    set MAB_StaticDirty = true
    call MAB_Update()
endfunction

public function Enable takes nothing returns nothing
    if not MAB_Initialized then
        return
    endif
    if not MAB_FramesCreated then
        call MAB_CreateFrames()
    endif
    set MAB_Enabled = true
    set MAB_WasFullscreen = false
    call MAB_ResetSlotCache()
    call MAB_Update()
endfunction

public function Disable takes nothing returns nothing
    set MAB_Enabled = false
    call ModernAbilityController_CancelLocal(GetLocalPlayer())
    call MAB_CloseElementalFlyout()
    call MAB_SetParentVisible(false)
    call MAB_ResetSlotCache()
    call MAB_RestoreNativeFrames()
endfunction

public function IsEnabled takes nothing returns boolean
    return MAB_Enabled
endfunction

private function MAB_OnUnitSelected takes nothing returns nothing
    local unit selectedUnit = GetTriggerUnit()
    local player selectingPlayer = GetTriggerPlayer()

    if selectingPlayer == GetLocalPlayer() and MAB_IsPlayerHero(selectedUnit) then
        if MAB_ElementalHero != null and MAB_ElementalHero != selectedUnit then
            call MAB_CloseElementalFlyout()
        endif
        set MAB_SelectedUnit = selectedUnit
        call MAB_ResetSlotCache()
    endif
    set selectedUnit = null
    set selectingPlayer = null
endfunction

private function MAB_OnUnitDeselected takes nothing returns nothing
    local unit deselectedUnit = GetTriggerUnit()
    local player deselectingPlayer = GetTriggerPlayer()

    // Keep the last player hero as the HUD subject while the player selects a
    // world target or an inspect target.
    set deselectedUnit = null
    set deselectingPlayer = null
endfunction

private function MAB_OnHeroSkill takes nothing returns nothing
    local unit whichHero = GetTriggerUnit()

    if whichHero == MAB_SelectedUnit then
        call Refresh()
    endif
    set whichHero = null
endfunction

private function MAB_OnSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer slot
    local integer index

    if caster == MAB_CachedHero and MAB_Enabled then
        if MAB_IsElementalChoice(abilityId) then
            set abilityId = MAB_SUMMON_ELEMENTAL
        endif
        set slot = ModernAbilityLoadout_FindSlot(caster, abilityId)
        if slot > 0 then
            set index = slot - 1
            set MAB_CooldownActive[index] = true
        endif
    endif

    set caster = null
endfunction

private function MAB_DelayedInit takes nothing returns nothing
    call MAB_CreateFrames()
    if MAB_AUTO_ENABLE then
        call Enable()
    endif
    call DestroyTrigger(MAB_InitTrigger)
    set MAB_InitTrigger = null
endfunction

private function Init takes nothing returns nothing
    local integer keyIndex = 0
    local oskeytype array actionKey

    if MAB_Initialized then
        return
    endif
    set MAB_Initialized = true

    set MAB_SlotTrigger = CreateTrigger()
    call TriggerAddAction(MAB_SlotTrigger, function MAB_SlotAction)
    set MAB_ElementalTrigger = CreateTrigger()
    call TriggerAddAction(MAB_ElementalTrigger, function MAB_ElementalAction)
    set MAB_ContextTrigger = CreateTrigger()
    call TriggerAddAction(MAB_ContextTrigger, function MAB_ContextAction)
    set MAB_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(MAB_ClearFocusTrigger, function MAB_ClearFocusAction)
    set MAB_HoverTrigger = CreateTrigger()
    call TriggerAddAction(MAB_HoverTrigger, function MAB_HoverAction)
    set actionKey[0] = OSKEY_1
    set actionKey[1] = OSKEY_2
    set actionKey[2] = OSKEY_3
    set actionKey[3] = OSKEY_4
    set actionKey[4] = OSKEY_5
    set actionKey[5] = OSKEY_6
    set actionKey[6] = OSKEY_7
    set actionKey[7] = OSKEY_8
    set actionKey[8] = OSKEY_9
    set actionKey[9] = OSKEY_0
    set actionKey[10] = OSKEY_OEM_MINUS
    set actionKey[11] = OSKEY_OEM_PLUS
    set MAB_KeyTrigger = CreateTrigger()
    loop
        exitwhen keyIndex >= ModernAbilityLoadout_SLOT_COUNT
        set MAB_SlotKey[keyIndex] = actionKey[keyIndex]
        set MAB_SlotKeyLabel[keyIndex] = MAB_GetSlotLabel(keyIndex + 1)
        call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), actionKey[keyIndex], 0, true)
        set actionKey[keyIndex] = null
        set keyIndex = keyIndex + 1
    endloop
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_Q, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_W, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_E, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_R, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_A, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_S, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_D, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_F, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_Z, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_X, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_C, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(MAB_KeyTrigger, Player(0), OSKEY_V, 0, true)
    call TriggerAddAction(MAB_KeyTrigger, function MAB_KeyAction)
    set MAB_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(MAB_InitTrigger, 0.25, false)
    call TriggerAddAction(MAB_InitTrigger, function MAB_DelayedInit)
    call Events_RegisterPlayerUnitEvent(function MAB_OnUnitSelected, EVENT_PLAYER_UNIT_SELECTED)
    call Events_RegisterPlayerUnitEvent(function MAB_OnUnitDeselected, EVENT_PLAYER_UNIT_DESELECTED)
    call Events_RegisterPlayerUnitEvent(function MAB_OnHeroSkill, EVENT_PLAYER_HERO_SKILL)
    call Events_RegisterSpellEffect(function MAB_OnSpellEffect)
    call ModernPlayerHUD_RegisterUpdate(function MAB_Update)
endfunction

endlibrary
