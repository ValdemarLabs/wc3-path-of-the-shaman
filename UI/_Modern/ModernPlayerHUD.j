/**
    ModernPlayerHUD

    Author: Valdemar
    Version: 0.4.0

    Description:
    Creates the cached modern PotS bottom-center resource shell, twelve custom
    action-slot mounting points, and an ability-book shortcut without moving
    or reparenting native HUD widgets. Its compact art/layout combines the
    reference VideoRPG HUD with Forgotten Hollow's broad centered bars.

    Credits:
    - Blizzard Entertainment, native frame API and frame templates
    - Forgotten Hollow, action-bar and lower-HUD presentation reference

    How to install:
    Import after Events, MasterUI, AbilitiesLiteUI, and FullscreenUI, then
    import ModernAbilityActionBar after this library. No TOC or FDF import is
    required for this implementation. The library creates its
    frames after a short initialization delay and enables itself only after
    FullscreenUI has finished the intro presentation. Set MHUD_AUTO_ENABLE to
    false when an external startup flow should call ModernPlayerHUD_Enable
    instead.

    API:
    - call ModernPlayerHUD_Enable()
    - call ModernPlayerHUD_Disable()
    - call ModernPlayerHUD_SetUnit(whichUnit)
    - call ModernPlayerHUD_Refresh()
    - call ModernPlayerHUD_RegisterUpdate(callback)
    - set enabled = ModernPlayerHUD_IsEnabled()

**/
library ModernPlayerHUD initializer Init requires Events, MasterUI, AbilitiesLiteUI, FullscreenUI

globals
    // Configuration
    private constant boolean MHUD_AUTO_ENABLE = true
    private constant integer MHUD_ACTION_SLOT_COUNT = 12
    private constant real MHUD_UPDATE_INTERVAL = 0.10

    private constant real MHUD_PANEL_LEFT = 0.100
    private constant real MHUD_PANEL_RIGHT = 0.700
    private constant real MHUD_PANEL_TOP = 0.100
    private constant real MHUD_PANEL_BOTTOM = 0.004

    private constant real MHUD_ACTION_START_X = 0.190
    private constant real MHUD_ACTION_BOTTOM = 0.012
    private constant real MHUD_ACTION_SIZE = 0.032
    private constant real MHUD_ACTION_GAP = 0.003

    private constant real MHUD_RESOURCE_BAR_WIDTH = 0.180
    private constant real MHUD_RESOURCE_BAR_HEIGHT = 0.014
    private constant real MHUD_XP_BAR_WIDTH = 0.420
    private constant real MHUD_XP_BAR_HEIGHT = 0.006
    private constant integer MHUD_BAR_HEALTH = 0
    private constant integer MHUD_BAR_MANA = 1
    private constant integer MHUD_BAR_XP = 2

    // Must match Gameplay Constants and the values mirrored by StatsUI.
    private constant integer MHUD_HERO_XP_FORMULA_A = 1
    private constant integer MHUD_HERO_XP_FORMULA_B = 150
    private constant integer MHUD_HERO_XP_FORMULA_C = 0

    private constant string MHUD_SURFACE_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private constant string MHUD_PANEL_TEXTURE = "UI\\_Modern\\Assets\\PotSHUD.tga"
    private constant string MHUD_ACTION_SLOT_TEXTURE = "UI\\_Modern\\Assets\\PotSActionSlot.tga"
    private constant string MHUD_BAR_BACK_TEXTURE = "UI\\_Modern\\Assets\\PotSBarBack.tga"
    private constant string MHUD_BAR_FRAME_TEXTURE = "UI\\_Modern\\Assets\\PotSBarFrame.tga"
    private constant string MHUD_MEDALLION_TEXTURE = "UI\\_Modern\\Assets\\PotSMedallion.tga"
    private constant string MHUD_HEALTH_TEXTURE = "UI\\_Modern\\Assets\\PotSHealth.tga"
    private constant string MHUD_MANA_TEXTURE = "UI\\_Modern\\Assets\\PotSMana.tga"
    private constant string MHUD_XP_TEXTURE = "UI\\_Modern\\Assets\\PotSXP.tga"
    private constant string MHUD_BOOK_ICON = "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"

    private boolean MHUD_Initialized = false
    private boolean MHUD_FramesCreated = false
    private boolean MHUD_Enabled = false
    private boolean MHUD_WasFullscreen = false

    private framehandle MHUD_ScreenParent = null
    private framehandle MHUD_Parent = null
    private framehandle MHUD_Backdrop = null
    private framehandle MHUD_TopTrim = null
    private framehandle MHUD_ResourceBarBack = null
    private framehandle MHUD_ResourceBarFrame = null
    private framehandle MHUD_NameText = null
    private framehandle MHUD_LevelBackdrop = null
    private framehandle MHUD_LevelText = null
    private framehandle MHUD_HealthBack = null
    private framehandle MHUD_HealthFill = null
    private framehandle MHUD_HealthText = null
    private framehandle MHUD_ManaBack = null
    private framehandle MHUD_ManaFill = null
    private framehandle MHUD_ManaText = null
    private framehandle MHUD_XPBack = null
    private framehandle MHUD_XPFill = null
    private framehandle MHUD_XPText = null
    private framehandle MHUD_BookButton = null
    private framehandle MHUD_BookIcon = null
    private framehandle array MHUD_SlotBackdrop

    private trigger MHUD_BookTrigger = null
    private trigger MHUD_ClearFocusTrigger = null
    private trigger MHUD_InitTrigger = null
    private trigger MHUD_UpdateTrigger = null
    private timer MHUD_EnableTimer = null
    private timer MHUD_UpdateTimer = null

    // This is local presentation state and must never drive synchronized gameplay.
    private unit MHUD_SelectedUnit = null
    private unit MHUD_CachedUnit = null
    private boolean MHUD_ParentVisible = false
    private boolean MHUD_ManaVisible = false
    private boolean MHUD_XPVisible = false
    private boolean MHUD_BookVisible = false
    private integer MHUD_CachedLife = -1
    private integer MHUD_CachedMaxLife = -1
    private integer MHUD_CachedMana = -1
    private integer MHUD_CachedMaxMana = -1
    private integer MHUD_CachedLevel = -1
    private integer MHUD_CachedXP = -1
    private integer array MHUD_BarStep
endglobals

private function MHUD_IsValidUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetHandleId(whichUnit) != 0 and GetUnitTypeId(whichUnit) != 0
endfunction

private function MHUD_IsPlayerHero takes unit whichUnit returns boolean
    return whichUnit != null and GetOwningPlayer(whichUnit) == Player(0) and (whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis)
endfunction

private function MHUD_GetDisplayName takes unit whichUnit returns string
    if not MHUD_IsValidUnit(whichUnit) then
        return ""
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroProperName(whichUnit)
    endif
    return GetUnitName(whichUnit)
endfunction

private function MHUD_GetDisplayLevel takes unit whichUnit returns integer
    if not MHUD_IsValidUnit(whichUnit) then
        return 0
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroLevel(whichUnit)
    endif
    return GetUnitLevel(whichUnit)
endfunction

private function MHUD_GetHeroXPRequiredForLevel takes integer targetLevel returns integer
    local integer level = 2
    local integer required = 0

    if targetLevel <= 1 then
        return 0
    endif

    loop
        exitwhen level > targetLevel
        set required = MHUD_HERO_XP_FORMULA_A * required + MHUD_HERO_XP_FORMULA_B * level + MHUD_HERO_XP_FORMULA_C
        set level = level + 1
    endloop

    return required
endfunction

private function MHUD_ClampRatio takes real value returns real
    if value < 0.00 then
        return 0.00
    elseif value > 1.00 then
        return 1.00
    endif
    return value
endfunction

private function MHUD_ResetCache takes nothing returns nothing
    set MHUD_CachedUnit = null
    set MHUD_CachedLife = -1
    set MHUD_CachedMaxLife = -1
    set MHUD_CachedMana = -1
    set MHUD_CachedMaxMana = -1
    set MHUD_CachedLevel = -1
    set MHUD_CachedXP = -1
    set MHUD_BarStep[MHUD_BAR_HEALTH] = -1
    set MHUD_BarStep[MHUD_BAR_MANA] = -1
    set MHUD_BarStep[MHUD_BAR_XP] = -1
endfunction

private function MHUD_SetParentVisible takes boolean visible returns nothing
    if MHUD_ParentVisible != visible then
        set MHUD_ParentVisible = visible
        call BlzFrameSetVisible(MHUD_Parent, visible)
    endif
endfunction

private function MHUD_SetManaVisible takes boolean visible returns nothing
    if MHUD_ManaVisible != visible then
        set MHUD_ManaVisible = visible
        call BlzFrameSetVisible(MHUD_ManaBack, visible)
    endif
endfunction

private function MHUD_SetXPVisible takes boolean visible returns nothing
    if MHUD_XPVisible != visible then
        set MHUD_XPVisible = visible
        call BlzFrameSetVisible(MHUD_XPBack, visible)
    endif
endfunction

private function MHUD_SetBookVisible takes boolean visible returns nothing
    if MHUD_BookVisible != visible then
        set MHUD_BookVisible = visible
        call BlzFrameSetVisible(MHUD_BookButton, visible)
    endif
endfunction

private function MHUD_SetBarFill takes framehandle fillFrame, real width, real height, real current, real maximum, integer barIndex returns nothing
    local real ratio = 0.00
    local integer step

    if maximum > 0.00 then
        set ratio = MHUD_ClampRatio(current / maximum)
    endif
    set step = R2I(ratio * 1000.00)
    if MHUD_BarStep[barIndex] != step then
        set MHUD_BarStep[barIndex] = step
        if step <= 0 then
            call BlzFrameSetSize(fillFrame, 0.0001, height)
        else
            call BlzFrameSetSize(fillFrame, width * I2R(step) / 1000.00, height)
        endif
    endif

    set fillFrame = null
endfunction

private function MHUD_UpdateXP takes unit whichUnit returns nothing
    local integer level
    local integer currentXP
    local integer previousXP
    local integer nextXP
    local integer progress
    local integer required

    if not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        call MHUD_SetXPVisible(false)
        return
    endif

    set level = GetHeroLevel(whichUnit)
    set currentXP = GetHeroXP(whichUnit)
    call MHUD_SetXPVisible(true)
    if level == MHUD_CachedLevel and currentXP == MHUD_CachedXP then
        return
    endif
    set MHUD_CachedXP = currentXP
    set previousXP = MHUD_GetHeroXPRequiredForLevel(level)
    set nextXP = MHUD_GetHeroXPRequiredForLevel(level + 1)
    set progress = currentXP - previousXP
    set required = nextXP - previousXP

    if progress < 0 then
        set progress = 0
    endif
    if required <= 0 then
        call MHUD_SetBarFill(MHUD_XPFill, MHUD_XP_BAR_WIDTH, MHUD_XP_BAR_HEIGHT, 1.00, 1.00, MHUD_BAR_XP)
        call BlzFrameSetText(MHUD_XPText, "MAX")
    else
        call MHUD_SetBarFill(MHUD_XPFill, MHUD_XP_BAR_WIDTH, MHUD_XP_BAR_HEIGHT, I2R(progress), I2R(required), MHUD_BAR_XP)
        call BlzFrameSetText(MHUD_XPText, I2S(progress) + " / " + I2S(required) + " XP")
    endif
endfunction

private function MHUD_Update takes nothing returns nothing
    local unit whichUnit = MHUD_SelectedUnit
    local integer life
    local integer maxLife
    local integer mana
    local integer maxMana
    local integer level
    local boolean playerHero

    if not MHUD_Enabled or MHUD_Parent == null then
        set whichUnit = null
        return
    endif

    if FullscreenUI_IsEnabled() then
        set MHUD_WasFullscreen = true
        call MHUD_SetParentVisible(false)
        set whichUnit = null
        return
    endif

    if MHUD_WasFullscreen then
        set MHUD_WasFullscreen = false
    endif

    if not MHUD_IsValidUnit(whichUnit) and GetLocalPlayer() == Player(0) and MHUD_IsValidUnit(udg_Nazgrek) then
        set whichUnit = udg_Nazgrek
        set MHUD_SelectedUnit = whichUnit
    endif

    if not MHUD_IsValidUnit(whichUnit) then
        call MHUD_SetParentVisible(false)
        set whichUnit = null
        return
    endif

    if MHUD_CachedUnit != whichUnit then
        call MHUD_ResetCache()
        set MHUD_CachedUnit = whichUnit
        call BlzFrameSetText(MHUD_NameText, "|cffffe4a3" + MHUD_GetDisplayName(whichUnit) + "|r")
    endif

    set life = R2I(GetWidgetLife(whichUnit))
    set maxLife = BlzGetUnitMaxHP(whichUnit)
    set mana = R2I(GetUnitState(whichUnit, UNIT_STATE_MANA))
    set maxMana = BlzGetUnitMaxMana(whichUnit)
    set level = MHUD_GetDisplayLevel(whichUnit)
    set playerHero = MHUD_IsPlayerHero(whichUnit)

    call MHUD_SetParentVisible(true)
    if level != MHUD_CachedLevel then
        set MHUD_CachedLevel = level
        set MHUD_CachedXP = -1
        call BlzFrameSetText(MHUD_LevelText, I2S(level))
    endif
    if life != MHUD_CachedLife or maxLife != MHUD_CachedMaxLife then
        set MHUD_CachedLife = life
        set MHUD_CachedMaxLife = maxLife
        call BlzFrameSetText(MHUD_HealthText, I2S(life) + " / " + I2S(maxLife))
        call MHUD_SetBarFill(MHUD_HealthFill, MHUD_RESOURCE_BAR_WIDTH, MHUD_RESOURCE_BAR_HEIGHT, I2R(life), I2R(maxLife), MHUD_BAR_HEALTH)
    endif

    if maxMana > 0 then
        call MHUD_SetManaVisible(true)
        if mana != MHUD_CachedMana or maxMana != MHUD_CachedMaxMana then
            set MHUD_CachedMana = mana
            set MHUD_CachedMaxMana = maxMana
            call BlzFrameSetText(MHUD_ManaText, I2S(mana) + " / " + I2S(maxMana))
            call MHUD_SetBarFill(MHUD_ManaFill, MHUD_RESOURCE_BAR_WIDTH, MHUD_RESOURCE_BAR_HEIGHT, I2R(mana), I2R(maxMana), MHUD_BAR_MANA)
        endif
    else
        call MHUD_SetManaVisible(false)
    endif

    call MHUD_UpdateXP(whichUnit)
    call MHUD_SetBookVisible(playerHero)

    set whichUnit = null
endfunction

private function MHUD_Tick takes nothing returns nothing
    call MHUD_Update()
    call TriggerExecute(MHUD_UpdateTrigger)
endfunction

private function MHUD_ClearFocusAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()

    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
    endif

    set triggerFrame = null
endfunction

private function MHUD_BookAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() and MHUD_IsPlayerHero(MHUD_SelectedUnit) then
        call MasterUI_ClosePanels()
        call AbilitiesLiteUI_ShowForUnit(MHUD_SelectedUnit)
    endif
endfunction

private function MHUD_CreateFrames takes nothing returns nothing
    local integer index = 0
    local real x

    if MHUD_FramesCreated then
        return
    endif
    set MHUD_FramesCreated = true

    // ConsoleUIBackdrop is below the Warcraft III 2.x bottom-console layers.
    // Own custom frames directly under GameUI so the restored native HUD does
    // not cover them after FullscreenUI ends.
    set MHUD_ScreenParent = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)

    set MHUD_Parent = BlzCreateFrameByType("FRAME", "ModernPlayerHUDPanel", MHUD_ScreenParent, "", 0)
    call BlzFrameSetAbsPoint(MHUD_Parent, FRAMEPOINT_TOPLEFT, MHUD_PANEL_LEFT, MHUD_PANEL_TOP)
    call BlzFrameSetAbsPoint(MHUD_Parent, FRAMEPOINT_BOTTOMRIGHT, MHUD_PANEL_RIGHT, MHUD_PANEL_BOTTOM)
    call BlzFrameSetLevel(MHUD_Parent, 20)

    set MHUD_Backdrop = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDBackdrop", MHUD_Parent, "", 0)
    call BlzFrameSetPoint(MHUD_Backdrop, FRAMEPOINT_BOTTOM, MHUD_Parent, FRAMEPOINT_BOTTOM, 0.000, 0.000)
    call BlzFrameSetSize(MHUD_Backdrop, 0.540, 0.061)
    call BlzFrameSetTexture(MHUD_Backdrop, MHUD_PANEL_TEXTURE, 0, true)
    call BlzFrameSetEnable(MHUD_Backdrop, false)
    call BlzFrameSetLevel(MHUD_Backdrop, 1)

    set MHUD_TopTrim = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDTopTrim", MHUD_Parent, "", 0)
    call BlzFrameSetTexture(MHUD_TopTrim, MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(MHUD_TopTrim, FRAMEPOINT_TOP, MHUD_Parent, FRAMEPOINT_TOP, 0.000, -0.002)
    call BlzFrameSetSize(MHUD_TopTrim, MHUD_PANEL_RIGHT - MHUD_PANEL_LEFT - 0.050, 0.0015)
    call BlzFrameSetVertexColor(MHUD_TopTrim, BlzConvertColor(220, 188, 145, 74))
    call BlzFrameSetEnable(MHUD_TopTrim, false)
    call BlzFrameSetLevel(MHUD_TopTrim, 2)

    set MHUD_NameText = BlzCreateFrameByType("TEXT", "ModernPlayerHUDName", MHUD_Parent, "", 0)
    call BlzFrameSetPoint(MHUD_NameText, FRAMEPOINT_TOP, MHUD_Parent, FRAMEPOINT_TOP, 0.000, -0.001)
    call BlzFrameSetSize(MHUD_NameText, 0.180, 0.014)
    call BlzFrameSetTextAlignment(MHUD_NameText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MHUD_NameText, 0.72)
    call BlzFrameSetEnable(MHUD_NameText, false)
    call BlzFrameSetLevel(MHUD_NameText, 6)

    set MHUD_ResourceBarBack = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDResourceBarBack", MHUD_Parent, "", 0)
    call BlzFrameSetTexture(MHUD_ResourceBarBack, MHUD_BAR_BACK_TEXTURE, 0, true)
    call BlzFrameSetPoint(MHUD_ResourceBarBack, FRAMEPOINT_TOP, MHUD_Parent, FRAMEPOINT_TOP, 0.000, -0.016)
    call BlzFrameSetSize(MHUD_ResourceBarBack, 0.408, 0.024)
    call BlzFrameSetEnable(MHUD_ResourceBarBack, false)
    call BlzFrameSetLevel(MHUD_ResourceBarBack, 2)

    set MHUD_ResourceBarFrame = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDResourceBarFrame", MHUD_Parent, "", 0)
    call BlzFrameSetTexture(MHUD_ResourceBarFrame, MHUD_BAR_FRAME_TEXTURE, 0, true)
    call BlzFrameSetAllPoints(MHUD_ResourceBarFrame, MHUD_ResourceBarBack)
    call BlzFrameSetEnable(MHUD_ResourceBarFrame, false)
    call BlzFrameSetLevel(MHUD_ResourceBarFrame, 5)

    set MHUD_LevelBackdrop = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDLevelBackdrop", MHUD_Parent, "", 0)
    call BlzFrameSetTexture(MHUD_LevelBackdrop, MHUD_MEDALLION_TEXTURE, 0, true)
    call BlzFrameSetPoint(MHUD_LevelBackdrop, FRAMEPOINT_TOP, MHUD_Parent, FRAMEPOINT_TOP, 0.000, -0.007)
    call BlzFrameSetSize(MHUD_LevelBackdrop, 0.044, 0.044)
    call BlzFrameSetEnable(MHUD_LevelBackdrop, false)
    call BlzFrameSetLevel(MHUD_LevelBackdrop, 7)

    set MHUD_LevelText = BlzCreateFrameByType("TEXT", "ModernPlayerHUDLevel", MHUD_LevelBackdrop, "", 0)
    call BlzFrameSetAllPoints(MHUD_LevelText, MHUD_LevelBackdrop)
    call BlzFrameSetTextAlignment(MHUD_LevelText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MHUD_LevelText, 0.82)
    call BlzFrameSetEnable(MHUD_LevelText, false)
    call BlzFrameSetLevel(MHUD_LevelText, 8)

    set MHUD_HealthBack = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDHealthBack", MHUD_Parent, "", 0)
    call BlzFrameSetTexture(MHUD_HealthBack, MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(MHUD_HealthBack, FRAMEPOINT_TOPRIGHT, MHUD_LevelBackdrop, FRAMEPOINT_TOPLEFT, -0.004, -0.011)
    call BlzFrameSetSize(MHUD_HealthBack, MHUD_RESOURCE_BAR_WIDTH, MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetVertexColor(MHUD_HealthBack, BlzConvertColor(210, 18, 14, 12))
    call BlzFrameSetEnable(MHUD_HealthBack, false)
    call BlzFrameSetLevel(MHUD_HealthBack, 3)

    set MHUD_HealthFill = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDHealthFill", MHUD_HealthBack, "", 0)
    call BlzFrameSetTexture(MHUD_HealthFill, MHUD_HEALTH_TEXTURE, 0, false)
    call BlzFrameSetPoint(MHUD_HealthFill, FRAMEPOINT_LEFT, MHUD_HealthBack, FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(MHUD_HealthFill, MHUD_RESOURCE_BAR_WIDTH, MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetEnable(MHUD_HealthFill, false)
    call BlzFrameSetLevel(MHUD_HealthFill, 4)

    set MHUD_HealthText = BlzCreateFrameByType("TEXT", "ModernPlayerHUDHealthText", MHUD_HealthBack, "", 0)
    call BlzFrameSetAllPoints(MHUD_HealthText, MHUD_HealthBack)
    call BlzFrameSetTextAlignment(MHUD_HealthText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MHUD_HealthText, 0.58)
    call BlzFrameSetEnable(MHUD_HealthText, false)
    call BlzFrameSetLevel(MHUD_HealthText, 6)

    set MHUD_ManaBack = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDManaBack", MHUD_Parent, "", 0)
    call BlzFrameSetTexture(MHUD_ManaBack, MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(MHUD_ManaBack, FRAMEPOINT_TOPLEFT, MHUD_LevelBackdrop, FRAMEPOINT_TOPRIGHT, 0.004, -0.011)
    call BlzFrameSetSize(MHUD_ManaBack, MHUD_RESOURCE_BAR_WIDTH, MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetVertexColor(MHUD_ManaBack, BlzConvertColor(210, 18, 14, 12))
    call BlzFrameSetEnable(MHUD_ManaBack, false)
    call BlzFrameSetLevel(MHUD_ManaBack, 3)

    set MHUD_ManaFill = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDManaFill", MHUD_ManaBack, "", 0)
    call BlzFrameSetTexture(MHUD_ManaFill, MHUD_MANA_TEXTURE, 0, false)
    call BlzFrameSetPoint(MHUD_ManaFill, FRAMEPOINT_LEFT, MHUD_ManaBack, FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(MHUD_ManaFill, MHUD_RESOURCE_BAR_WIDTH, MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetEnable(MHUD_ManaFill, false)
    call BlzFrameSetLevel(MHUD_ManaFill, 4)

    set MHUD_ManaText = BlzCreateFrameByType("TEXT", "ModernPlayerHUDManaText", MHUD_ManaBack, "", 0)
    call BlzFrameSetAllPoints(MHUD_ManaText, MHUD_ManaBack)
    call BlzFrameSetTextAlignment(MHUD_ManaText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MHUD_ManaText, 0.58)
    call BlzFrameSetEnable(MHUD_ManaText, false)
    call BlzFrameSetLevel(MHUD_ManaText, 6)

    set MHUD_XPBack = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDXPBack", MHUD_Parent, "", 0)
    call BlzFrameSetTexture(MHUD_XPBack, MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(MHUD_XPBack, FRAMEPOINT_TOP, MHUD_Parent, FRAMEPOINT_TOP, 0.000, -0.049)
    call BlzFrameSetSize(MHUD_XPBack, MHUD_XP_BAR_WIDTH, MHUD_XP_BAR_HEIGHT)
    call BlzFrameSetVertexColor(MHUD_XPBack, BlzConvertColor(235, 38, 38, 38))
    call BlzFrameSetEnable(MHUD_XPBack, false)
    call BlzFrameSetLevel(MHUD_XPBack, 3)

    set MHUD_XPFill = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDXPFill", MHUD_XPBack, "", 0)
    call BlzFrameSetTexture(MHUD_XPFill, MHUD_XP_TEXTURE, 0, true)
    call BlzFrameSetPoint(MHUD_XPFill, FRAMEPOINT_LEFT, MHUD_XPBack, FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(MHUD_XPFill, MHUD_XP_BAR_WIDTH, MHUD_XP_BAR_HEIGHT)
    call BlzFrameSetEnable(MHUD_XPFill, false)
    call BlzFrameSetLevel(MHUD_XPFill, 4)

    set MHUD_XPText = BlzCreateFrameByType("TEXT", "ModernPlayerHUDXPText", MHUD_XPBack, "", 0)
    call BlzFrameSetAllPoints(MHUD_XPText, MHUD_XPBack)
    call BlzFrameSetTextAlignment(MHUD_XPText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MHUD_XPText, 0.46)
    call BlzFrameSetEnable(MHUD_XPText, false)
    call BlzFrameSetLevel(MHUD_XPText, 5)

    loop
        exitwhen index >= MHUD_ACTION_SLOT_COUNT
        set x = MHUD_ACTION_START_X + I2R(index) * (MHUD_ACTION_SIZE + MHUD_ACTION_GAP)
        set MHUD_SlotBackdrop[index] = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDSlot" + I2S(index), MHUD_Parent, "", 0)
        call BlzFrameSetTexture(MHUD_SlotBackdrop[index], MHUD_ACTION_SLOT_TEXTURE, 0, true)
        call BlzFrameSetAbsPoint(MHUD_SlotBackdrop[index], FRAMEPOINT_BOTTOMLEFT, x - 0.001, MHUD_ACTION_BOTTOM - 0.001)
        call BlzFrameSetSize(MHUD_SlotBackdrop[index], MHUD_ACTION_SIZE + 0.002, MHUD_ACTION_SIZE + 0.002)
        call BlzFrameSetEnable(MHUD_SlotBackdrop[index], false)
        call BlzFrameSetLevel(MHUD_SlotBackdrop[index], 3)
        call BlzFrameSetVisible(MHUD_SlotBackdrop[index], true)
        set index = index + 1
    endloop

    set MHUD_BookButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ModernPlayerHUDBookButton", MHUD_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetAbsPoint(MHUD_BookButton, FRAMEPOINT_BOTTOMLEFT, 0.611, MHUD_ACTION_BOTTOM)
    call BlzFrameSetSize(MHUD_BookButton, 0.064, MHUD_ACTION_SIZE)
    call BlzFrameSetText(MHUD_BookButton, "ABILITIES")
    call BlzFrameSetLevel(MHUD_BookButton, 7)

    set MHUD_BookIcon = BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDBookIcon", MHUD_BookButton, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(MHUD_BookIcon, FRAMEPOINT_LEFT, MHUD_BookButton, FRAMEPOINT_LEFT, 0.003, 0.000)
    call BlzFrameSetSize(MHUD_BookIcon, 0.016, 0.016)
    call BlzFrameSetTexture(MHUD_BookIcon, MHUD_BOOK_ICON, 0, true)
    call BlzFrameSetEnable(MHUD_BookIcon, false)
    call BlzFrameSetLevel(MHUD_BookIcon, 8)

    call BlzTriggerRegisterFrameEvent(MHUD_BookTrigger, MHUD_BookButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(MHUD_ClearFocusTrigger, MHUD_BookButton, FRAMEEVENT_CONTROL_CLICK)

    call BlzFrameSetVisible(MHUD_Parent, false)
endfunction

public function SetUnit takes unit whichUnit returns nothing
    if MHUD_SelectedUnit != whichUnit then
        set MHUD_SelectedUnit = whichUnit
        call MHUD_ResetCache()
    endif
    call MHUD_Tick()
    set whichUnit = null
endfunction

public function Refresh takes nothing returns nothing
    if MHUD_Enabled then
        call MHUD_Tick()
    endif
endfunction

public function RegisterUpdate takes code callback returns nothing
    call TriggerAddAction(MHUD_UpdateTrigger, callback)
endfunction

public function Enable takes nothing returns nothing
    if not MHUD_Initialized or FullscreenUI_IsEnabled() then
        return
    endif
    if not MHUD_FramesCreated then
        call MHUD_CreateFrames()
    endif

    set MHUD_Enabled = true
    set MHUD_WasFullscreen = false
    call MHUD_ResetCache()
    call TimerStart(MHUD_UpdateTimer, MHUD_UPDATE_INTERVAL, true, function MHUD_Tick)
    call MHUD_Tick()
endfunction

public function Disable takes nothing returns nothing
    set MHUD_Enabled = false
    set MHUD_WasFullscreen = false
    call PauseTimer(MHUD_EnableTimer)
    call PauseTimer(MHUD_UpdateTimer)
    if MHUD_Parent != null then
        call MHUD_SetParentVisible(false)
    endif
    call MHUD_ResetCache()
endfunction

public function IsEnabled takes nothing returns boolean
    return MHUD_Enabled
endfunction

private function MHUD_OnUnitSelected takes nothing returns nothing
    local unit selectedUnit = GetTriggerUnit()
    local player selectingPlayer = GetTriggerPlayer()

    if selectingPlayer == GetLocalPlayer() then
        if MHUD_SelectedUnit != selectedUnit then
            set MHUD_SelectedUnit = selectedUnit
            call MHUD_ResetCache()
        endif
    endif

    set selectedUnit = null
    set selectingPlayer = null
endfunction

private function MHUD_OnUnitDeselected takes nothing returns nothing
    local unit deselectedUnit = GetTriggerUnit()
    local player deselectingPlayer = GetTriggerPlayer()

    if deselectingPlayer == GetLocalPlayer() and MHUD_SelectedUnit == deselectedUnit then
        set MHUD_SelectedUnit = null
        call MHUD_ResetCache()
    endif

    set deselectedUnit = null
    set deselectingPlayer = null
endfunction

private function MHUD_WaitForGameplay takes nothing returns nothing
    if not FullscreenUI_IsEnabled() and not MHUD_IsPlayerHero(MHUD_SelectedUnit) and GetLocalPlayer() == Player(0) then
        if MHUD_IsPlayerHero(udg_Nazgrek) then
            set MHUD_SelectedUnit = udg_Nazgrek
            call MHUD_ResetCache()
        elseif MHUD_IsPlayerHero(udg_Zulkis) then
            set MHUD_SelectedUnit = udg_Zulkis
            call MHUD_ResetCache()
        endif
    endif

    if not FullscreenUI_IsEnabled() and MHUD_IsPlayerHero(MHUD_SelectedUnit) then
        call PauseTimer(MHUD_EnableTimer)
        call Enable()
    endif
endfunction

private function MHUD_DelayedInit takes nothing returns nothing
    call MHUD_CreateFrames()
    if MHUD_AUTO_ENABLE then
        call TimerStart(MHUD_EnableTimer, MHUD_UPDATE_INTERVAL, true, function MHUD_WaitForGameplay)
    endif
    call DestroyTrigger(MHUD_InitTrigger)
    set MHUD_InitTrigger = null
endfunction

private function Init takes nothing returns nothing
    if MHUD_Initialized then
        return
    endif
    set MHUD_Initialized = true

    set MHUD_BookTrigger = CreateTrigger()
    call TriggerAddAction(MHUD_BookTrigger, function MHUD_BookAction)

    set MHUD_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(MHUD_ClearFocusTrigger, function MHUD_ClearFocusAction)

    set MHUD_UpdateTrigger = CreateTrigger()

    set MHUD_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(MHUD_InitTrigger, 0.20, false)
    call TriggerAddAction(MHUD_InitTrigger, function MHUD_DelayedInit)

    set MHUD_EnableTimer = CreateTimer()
    set MHUD_UpdateTimer = CreateTimer()

    call Events_RegisterPlayerUnitEvent(function MHUD_OnUnitSelected, EVENT_PLAYER_UNIT_SELECTED)
    call Events_RegisterPlayerUnitEvent(function MHUD_OnUnitDeselected, EVENT_PLAYER_UNIT_DESELECTED)
endfunction

endlibrary
