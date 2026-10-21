globals
//globals from AbilitiesLiteUI:
constant boolean LIBRARY_AbilitiesLiteUI=true
//endglobals from AbilitiesLiteUI
//globals from AbilitiesPlayer:
constant boolean LIBRARY_AbilitiesPlayer=true
constant integer AbilitiesPlayer_ENTRY_ABILITY= 1
//endglobals from AbilitiesPlayer
//globals from DEquipment:
constant boolean LIBRARY_DEquipment=true
//endglobals from DEquipment
//globals from DInventory:
constant boolean LIBRARY_DInventory=true
//endglobals from DInventory
//globals from DynamicMinimap:
constant boolean LIBRARY_DynamicMinimap=true
//endglobals from DynamicMinimap
//globals from Events:
constant boolean LIBRARY_Events=true
//endglobals from Events
//globals from FullscreenUI:
constant boolean LIBRARY_FullscreenUI=true
//endglobals from FullscreenUI
//globals from MasterUI:
constant boolean LIBRARY_MasterUI=true
//endglobals from MasterUI
//globals from ShamanCommon:
constant boolean LIBRARY_ShamanCommon=true
constant integer ShamanCommon_HERO_SLOT_NONE= 0
constant integer ShamanCommon_HERO_SLOT_NAZGREK= 1
constant integer ShamanCommon_HERO_SLOT_ZULKIS= 2
//endglobals from ShamanCommon
//globals from Totems:
constant boolean LIBRARY_Totems=true
constant integer Totems_SLOT_EARTH= 1
constant integer Totems_SLOT_FIRE= 2
constant integer Totems_SLOT_WATER= 3
constant integer Totems_SLOT_WIND= 4
//endglobals from Totems
//globals from ModernAbilityCatalog:
constant boolean LIBRARY_ModernAbilityCatalog=true
constant integer ModernAbilityCatalog_ACTION_NONE= 0
constant integer ModernAbilityCatalog_ACTION_PASSIVE= 1
constant integer ModernAbilityCatalog_ACTION_IMMEDIATE= 2
constant integer ModernAbilityCatalog_ACTION_UNIT= 3
constant integer ModernAbilityCatalog_ACTION_POINT= 4
constant integer ModernAbilityCatalog_ACTION_SUBMENU= 5

constant integer ModernAbilityCatalog_TARGET_NONE= 0
constant integer ModernAbilityCatalog_TARGET_SELF= 1
constant integer ModernAbilityCatalog_TARGET_SOFT_HOSTILE= 2
constant integer ModernAbilityCatalog_TARGET_SOFT_FRIENDLY= 3
constant integer ModernAbilityCatalog_TARGET_MELEE_AUTO= 4
constant integer ModernAbilityCatalog_TARGET_APPROXIMATE_POINT= 5
constant integer ModernAbilityCatalog_TARGET_PRECISE_POINT= 6

constant real ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS= 180.00
constant real ModernAbilityCatalog__MAC_DEFAULT_MELEE_RADIUS= 250.00

integer array ModernAbilityCatalog__MAC_ActionKind
integer array ModernAbilityCatalog__MAC_TargetPolicy
real array ModernAbilityCatalog__MAC_AcquireRadius
boolean array ModernAbilityCatalog__MAC_SelfFallback
integer array ModernAbilityCatalog__MAC_OrderId
boolean array ModernAbilityCatalog__MAC_RuntimeReady
boolean array ModernAbilityCatalog__MAC_UsesChannelOrder
//endglobals from ModernAbilityCatalog
//globals from ModernPlayerHUD:
constant boolean LIBRARY_ModernPlayerHUD=true
    // Configuration
constant boolean ModernPlayerHUD__MHUD_AUTO_ENABLE= true
constant integer ModernPlayerHUD__MHUD_ACTION_SLOT_COUNT= 12
constant real ModernPlayerHUD__MHUD_UPDATE_INTERVAL= 0.25

constant real ModernPlayerHUD__MHUD_PANEL_LEFT= 0.100
constant real ModernPlayerHUD__MHUD_PANEL_RIGHT= 0.700
constant real ModernPlayerHUD__MHUD_PANEL_TOP= 0.100
constant real ModernPlayerHUD__MHUD_PANEL_BOTTOM= 0.004

constant real ModernPlayerHUD__MHUD_ACTION_START_X= 0.190
constant real ModernPlayerHUD__MHUD_ACTION_BOTTOM= 0.012
constant real ModernPlayerHUD__MHUD_ACTION_SIZE= 0.032
constant real ModernPlayerHUD__MHUD_ACTION_GAP= 0.003

constant real ModernPlayerHUD__MHUD_RESOURCE_BAR_WIDTH= 0.174
constant real ModernPlayerHUD__MHUD_RESOURCE_BAR_HEIGHT= 0.010
constant real ModernPlayerHUD__MHUD_XP_BAR_WIDTH= 0.404
constant real ModernPlayerHUD__MHUD_XP_BAR_HEIGHT= 0.006
constant integer ModernPlayerHUD__MHUD_XP_SEGMENT_COUNT= 10
constant integer ModernPlayerHUD__MHUD_BAR_HEALTH= 0
constant integer ModernPlayerHUD__MHUD_BAR_MANA= 1
constant integer ModernPlayerHUD__MHUD_BAR_XP= 2

    // Must match Gameplay Constants and the values mirrored by StatsUI.
constant integer ModernPlayerHUD__MHUD_HERO_XP_FORMULA_A= 1
constant integer ModernPlayerHUD__MHUD_HERO_XP_FORMULA_B= 150
constant integer ModernPlayerHUD__MHUD_HERO_XP_FORMULA_C= 0

constant string ModernPlayerHUD__MHUD_SURFACE_TEXTURE= "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
constant string ModernPlayerHUD__MHUD_PANEL_TEXTURE= "UI\\_Modern\\Assets\\PotSHUD.tga"
constant string ModernPlayerHUD__MHUD_ACTION_SLOT_TEXTURE= "UI\\_Modern\\Assets\\PotSActionSlot.tga"
constant string ModernPlayerHUD__MHUD_BAR_BACK_TEXTURE= "UI\\_Modern\\Assets\\PotSBarBack.tga"
constant string ModernPlayerHUD__MHUD_BAR_FRAME_TEXTURE= "UI\\_Modern\\Assets\\PotSBarFrame.tga"
constant string ModernPlayerHUD__MHUD_MEDALLION_TEXTURE= "UI\\_Modern\\Assets\\PotSMedallion.tga"
constant string ModernPlayerHUD__MHUD_HEALTH_TEXTURE= "UI\\_Modern\\Assets\\PotSHealth.tga"
constant string ModernPlayerHUD__MHUD_MANA_TEXTURE= "UI\\_Modern\\Assets\\PotSMana.tga"
constant string ModernPlayerHUD__MHUD_XP_TEXTURE= "UI\\_Modern\\Assets\\PotSXP.tga"
constant string ModernPlayerHUD__MHUD_BOOK_ICON= "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"
constant string ModernPlayerHUD__MHUD_BAG_ICON= "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp"
constant string ModernPlayerHUD__MHUD_GEAR_ICON= "ReplaceableTextures\\CommandButtons\\BTNThoriumArmor.blp"
constant string ModernPlayerHUD__MHUD_INSPECT_ICON= "ReplaceableTextures\\CommandButtons\\BTNSpy.blp"

boolean ModernPlayerHUD__MHUD_Initialized= false
boolean ModernPlayerHUD__MHUD_FramesCreated= false
boolean ModernPlayerHUD__MHUD_Enabled= false
boolean ModernPlayerHUD__MHUD_WasFullscreen= false

framehandle ModernPlayerHUD__MHUD_ScreenParent= null
framehandle ModernPlayerHUD__MHUD_Parent= null
framehandle ModernPlayerHUD__MHUD_Backdrop= null
framehandle ModernPlayerHUD__MHUD_TopTrim= null
framehandle ModernPlayerHUD__MHUD_ResourceBarBack= null
framehandle ModernPlayerHUD__MHUD_ResourceBarFrame= null
framehandle ModernPlayerHUD__MHUD_NameText= null
framehandle ModernPlayerHUD__MHUD_LevelBackdrop= null
framehandle ModernPlayerHUD__MHUD_LevelText= null
framehandle ModernPlayerHUD__MHUD_HealthBack= null
framehandle ModernPlayerHUD__MHUD_HealthFill= null
framehandle ModernPlayerHUD__MHUD_HealthText= null
framehandle ModernPlayerHUD__MHUD_ManaBack= null
framehandle ModernPlayerHUD__MHUD_ManaFill= null
framehandle ModernPlayerHUD__MHUD_ManaText= null
framehandle ModernPlayerHUD__MHUD_XPBack= null
framehandle ModernPlayerHUD__MHUD_XPFill= null
framehandle ModernPlayerHUD__MHUD_XPText= null
framehandle ModernPlayerHUD__MHUD_BookButton= null
framehandle ModernPlayerHUD__MHUD_BookIcon= null
framehandle ModernPlayerHUD__MHUD_InventoryButton= null
framehandle ModernPlayerHUD__MHUD_EquipmentButton= null
framehandle ModernPlayerHUD__MHUD_InspectButton= null
framehandle array ModernPlayerHUD__MHUD_SlotBackdrop
framehandle array ModernPlayerHUD__MHUD_XPSegment

trigger ModernPlayerHUD__MHUD_BookTrigger= null
trigger ModernPlayerHUD__MHUD_UtilityTrigger= null
trigger ModernPlayerHUD__MHUD_ClearFocusTrigger= null
trigger ModernPlayerHUD__MHUD_InitTrigger= null
trigger ModernPlayerHUD__MHUD_UpdateTrigger= null
timer ModernPlayerHUD__MHUD_EnableTimer= null
timer ModernPlayerHUD__MHUD_UpdateTimer= null

    // This is local presentation state and must never drive synchronized gameplay.
unit ModernPlayerHUD__MHUD_SelectedUnit= null
unit ModernPlayerHUD__MHUD_CachedUnit= null
boolean ModernPlayerHUD__MHUD_ParentVisible= false
boolean ModernPlayerHUD__MHUD_ManaVisible= false
boolean ModernPlayerHUD__MHUD_XPVisible= false
boolean ModernPlayerHUD__MHUD_BookVisible= false
integer ModernPlayerHUD__MHUD_CachedLife= - 1
integer ModernPlayerHUD__MHUD_CachedMaxLife= - 1
integer ModernPlayerHUD__MHUD_CachedMana= - 1
integer ModernPlayerHUD__MHUD_CachedMaxMana= - 1
integer ModernPlayerHUD__MHUD_CachedLevel= - 1
integer ModernPlayerHUD__MHUD_CachedXP= - 1
integer array ModernPlayerHUD__MHUD_BarStep
//endglobals from ModernPlayerHUD
//globals from ModernAbilityLoadout:
constant boolean LIBRARY_ModernAbilityLoadout=true
constant integer ModernAbilityLoadout_SLOT_COUNT= 12

integer array ModernAbilityLoadout__MAL_AbilityId
boolean array ModernAbilityLoadout__MAL_Explicit
boolean array ModernAbilityLoadout__MAL_DefaultsMaterialized
integer array ModernAbilityLoadout__MAL_Revision
//endglobals from ModernAbilityLoadout
//globals from ModernAbilityTargeting:
constant boolean LIBRARY_ModernAbilityTargeting=true
constant real ModernAbilityTargeting__MAT_SELF_CLICK_RADIUS= 96.00
constant real ModernAbilityTargeting__MAT_DISTANCE_EPSILON= 0.01

group ModernAbilityTargeting__MAT_SearchGroup= CreateGroup()
//endglobals from ModernAbilityTargeting
//globals from ModernMinimapHUD:
constant boolean LIBRARY_ModernMinimapHUD=true
constant real ModernMinimapHUD__MMH_PANEL_LEFT= 0.006
constant real ModernMinimapHUD__MMH_PANEL_RIGHT= 0.134
constant real ModernMinimapHUD__MMH_PANEL_TOP= 0.558
constant real ModernMinimapHUD__MMH_PANEL_BOTTOM= 0.348
constant real ModernMinimapHUD__MMH_MINIMAP_LEFT= 0.013
constant real ModernMinimapHUD__MMH_MINIMAP_TOP= 0.550
constant real ModernMinimapHUD__MMH_MINIMAP_SIZE= 0.114
constant real ModernMinimapHUD__MMH_HERO_BOTTOM= 0.374
constant real ModernMinimapHUD__MMH_HERO_SIZE= 0.034
constant real ModernMinimapHUD__MMH_CONTROL_BOTTOM= 0.352
constant real ModernMinimapHUD__MMH_CONTROL_SIZE= 0.018
constant integer ModernMinimapHUD__MMH_CONTROL_COUNT= 5
constant string ModernMinimapHUD__MMH_SLOT_TEXTURE= "UI\\_Modern\\Assets\\PotSActionSlot.tga"
constant string ModernMinimapHUD__MMH_EMPTY_ICON= "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"

boolean ModernMinimapHUD__MMH_Enabled= true
boolean ModernMinimapHUD__MMH_FramesCreated= false
boolean ModernMinimapHUD__MMH_Visible= false
boolean ModernMinimapHUD__MMH_WasEnlarged= false
framehandle ModernMinimapHUD__MMH_Root= null
framehandle ModernMinimapHUD__MMH_Panel= null
framehandle ModernMinimapHUD__MMH_Title= null
framehandle ModernMinimapHUD__MMH_Minimap= null
framehandle array ModernMinimapHUD__MMH_HeroButton
framehandle array ModernMinimapHUD__MMH_HeroBorder
framehandle array ModernMinimapHUD__MMH_HeroIcon
framehandle array ModernMinimapHUD__MMH_HeroLabel
framehandle array ModernMinimapHUD__MMH_ControlButton
unit array ModernMinimapHUD__MMH_CachedHero
integer array ModernMinimapHUD__MMH_CachedHeroType
trigger ModernMinimapHUD__MMH_HeroTrigger= null
trigger ModernMinimapHUD__MMH_ClearFocusTrigger= null
trigger ModernMinimapHUD__MMH_InitTrigger= null
//endglobals from ModernMinimapHUD
//globals from ModernTotemTracker:
constant boolean LIBRARY_ModernTotemTracker=true
constant integer ModernTotemTracker___MTT_ELEMENT_COUNT= 4
constant real ModernTotemTracker___MTT_START_X= 0.332
constant real ModernTotemTracker___MTT_BOTTOM= 0.105
constant real ModernTotemTracker___MTT_SLOT_SIZE= 0.030
constant real ModernTotemTracker___MTT_SLOT_GAP= 0.005
constant real ModernTotemTracker___MTT_ACTIVE_SIZE= 0.030
constant real ModernTotemTracker___MTT_INACTIVE_SIZE= 0.022
constant real ModernTotemTracker___MTT_PROGRESS_WIDTH= 0.026
constant real ModernTotemTracker___MTT_PROGRESS_HEIGHT= 0.002
constant integer ModernTotemTracker___MTT_PROGRESS_STEPS= 20

constant string ModernTotemTracker___MTT_SURFACE_TEXTURE= "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
constant string ModernTotemTracker___MTT_EARTH_TEXTURE= "UI\\_Modern\\Assets\\PotSTotemEarth.tga"
constant string ModernTotemTracker___MTT_FIRE_TEXTURE= "UI\\_Modern\\Assets\\PotSTotemFire.tga"
constant string ModernTotemTracker___MTT_WATER_TEXTURE= "UI\\_Modern\\Assets\\PotSTotemWater.tga"
constant string ModernTotemTracker___MTT_AIR_TEXTURE= "UI\\_Modern\\Assets\\PotSTotemAir.tga"

boolean ModernTotemTracker___MTT_FramesCreated= false
boolean ModernTotemTracker___MTT_ParentVisible= false
framehandle ModernTotemTracker___MTT_Parent= null
framehandle array ModernTotemTracker___MTT_Slot
framehandle array ModernTotemTracker___MTT_Icon
framehandle array ModernTotemTracker___MTT_InactiveShade
framehandle array ModernTotemTracker___MTT_ProgressBack
framehandle array ModernTotemTracker___MTT_ProgressFill
framehandle array ModernTotemTracker___MTT_TimerText
framehandle array ModernTotemTracker___MTT_ElementLabel
trigger ModernTotemTracker___MTT_InitTrigger= null
unit ModernTotemTracker___MTT_CachedUnit= null
integer array ModernTotemTracker___MTT_CachedActive
integer array ModernTotemTracker___MTT_CachedSecond
integer array ModernTotemTracker___MTT_CachedProgress
//endglobals from ModernTotemTracker
//globals from ModernAbilityController:
constant boolean LIBRARY_ModernAbilityController=true
constant string ModernAbilityController__MAC_SYNC_PREFIX= "POTS_MAB_CAST"
constant string ModernAbilityController__MAC_ELEMENTAL_SYNC_PREFIX= "POTS_MAB_ELEMENTAL"
constant string ModernAbilityController__MAC_SWAP_SYNC_PREFIX= "POTS_MAB_SWAP"
constant string ModernAbilityController__MAC_CONTEXT_SYNC_PREFIX= "POTS_MAB_CONTEXT"
constant string ModernAbilityController__MAC_ASSIGN_SYNC_PREFIX= "POTS_MAB_ASSIGN"

constant integer ModernAbilityController__MAC_SUMMON_ELEMENTAL= 'A67Q'
constant integer ModernAbilityController__MAC_ELEMENTAL_AIR= 'A61K'
constant integer ModernAbilityController__MAC_ELEMENTAL_WATER= 'A61L'
constant integer ModernAbilityController__MAC_ELEMENTAL_FIRE= 'A61M'
constant integer ModernAbilityController__MAC_ELEMENTAL_EARTH= 'A61N'
constant integer ModernAbilityController__MAC_STEALTH= 'A6CR'
constant integer ModernAbilityController__MAC_STEALTH_ALT= 'A6CU'
constant integer ModernAbilityController__MAC_BLOCK_50= 'A6AD'
constant integer ModernAbilityController__MAC_BLOCK_75= 'A6AE'
constant integer ModernAbilityController__MAC_BLOCK_100= 'A6AF'

boolean array ModernAbilityController__MAC_Targeting
boolean array ModernAbilityController__MAC_TargetingArmed
integer array ModernAbilityController__MAC_PendingHeroSlot
integer array ModernAbilityController__MAC_PendingSlot

trigger ModernAbilityController__MAC_MouseTrigger= CreateTrigger()
trigger ModernAbilityController__MAC_SyncTrigger= CreateTrigger()
timer ModernAbilityController__MAC_TargetingArmTimer= CreateTimer()
//endglobals from ModernAbilityController
//globals from ModernAbilityActionBar:
constant boolean LIBRARY_ModernAbilityActionBar=true
constant boolean ModernAbilityActionBar__MAB_AUTO_ENABLE= true
constant boolean ModernAbilityActionBar__MAB_HIDE_NATIVE_BOTTOM_HUD= true

constant real ModernAbilityActionBar__MAB_ACTION_START_X= 0.190
constant real ModernAbilityActionBar__MAB_ACTION_BOTTOM= 0.012
constant real ModernAbilityActionBar__MAB_ACTION_SIZE= 0.032
constant real ModernAbilityActionBar__MAB_ACTION_GAP= 0.003
constant real ModernAbilityActionBar__MAB_TOOLTIP_WIDTH= 0.240
constant real ModernAbilityActionBar__MAB_TOOLTIP_HEIGHT= 0.092
constant integer ModernAbilityActionBar__MAB_ELEMENTAL_COUNT= 4
constant real ModernAbilityActionBar__MAB_ELEMENTAL_START_X= 0.318
constant real ModernAbilityActionBar__MAB_ELEMENTAL_BOTTOM= 0.124
constant real ModernAbilityActionBar__MAB_ELEMENTAL_SIZE= 0.038
constant real ModernAbilityActionBar__MAB_ELEMENTAL_GAP= 0.004
constant integer ModernAbilityActionBar__MAB_COOLDOWN_STEPS= 20
constant integer ModernAbilityActionBar__MAB_NATIVE_HERO_BUTTON_COUNT= 7

constant integer ModernAbilityActionBar__MAB_SUMMON_ELEMENTAL= 'A67Q'
constant integer ModernAbilityActionBar__MAB_ELEMENTAL_AIR= 'A61K'
constant integer ModernAbilityActionBar__MAB_ELEMENTAL_WATER= 'A61L'
constant integer ModernAbilityActionBar__MAB_ELEMENTAL_FIRE= 'A61M'
constant integer ModernAbilityActionBar__MAB_ELEMENTAL_EARTH= 'A61N'
constant integer ModernAbilityActionBar__MAB_CONTEXT_COUNT= 2
constant integer ModernAbilityActionBar__MAB_STEALTH= 'A6CR'
constant integer ModernAbilityActionBar__MAB_STEALTH_ALT= 'A6CU'
constant integer ModernAbilityActionBar__MAB_BLOCK_50= 'A6AD'
constant integer ModernAbilityActionBar__MAB_BLOCK_75= 'A6AE'
constant integer ModernAbilityActionBar__MAB_BLOCK_100= 'A6AF'

constant string ModernAbilityActionBar__MAB_SURFACE_TEXTURE= "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
constant string ModernAbilityActionBar__MAB_EMPTY_ICON= "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"
constant string ModernAbilityActionBar__MAB_MEDALLION_TEXTURE= "UI\\_Modern\\Assets\\PotSMedallion.tga"

boolean ModernAbilityActionBar__MAB_Initialized= false
boolean ModernAbilityActionBar__MAB_FramesCreated= false
boolean ModernAbilityActionBar__MAB_Enabled= false
boolean ModernAbilityActionBar__MAB_NativeCaptured= false
boolean ModernAbilityActionBar__MAB_ParentVisible= false
boolean ModernAbilityActionBar__MAB_TargetingVisible= false
boolean ModernAbilityActionBar__MAB_StaticDirty= true
boolean ModernAbilityActionBar__MAB_WasFullscreen= false
integer ModernAbilityActionBar__MAB_CachedLoadoutRevision= - 1
integer ModernAbilityActionBar__MAB_LearnScanTick= 0
integer ModernAbilityActionBar__MAB_MoveSourceSlot= 0
integer ModernAbilityActionBar__MAB_RebindSlot= 0

framehandle ModernAbilityActionBar__MAB_ScreenParent= null
framehandle ModernAbilityActionBar__MAB_Parent= null
framehandle ModernAbilityActionBar__MAB_HeroBorder= null
framehandle ModernAbilityActionBar__MAB_HeroIcon= null
framehandle ModernAbilityActionBar__MAB_TargetingText= null
framehandle ModernAbilityActionBar__MAB_Tooltip= null
framehandle ModernAbilityActionBar__MAB_TooltipTitle= null
framehandle ModernAbilityActionBar__MAB_TooltipBody= null
framehandle ModernAbilityActionBar__MAB_ElementalBackdrop= null
framehandle ModernAbilityActionBar__MAB_ElementalTitle= null

framehandle array ModernAbilityActionBar__MAB_SlotButton
framehandle array ModernAbilityActionBar__MAB_SlotIcon
framehandle array ModernAbilityActionBar__MAB_SlotCooldown
framehandle array ModernAbilityActionBar__MAB_SlotCooldownText
framehandle array ModernAbilityActionBar__MAB_SlotKeyText
framehandle array ModernAbilityActionBar__MAB_SlotDisabled
framehandle array ModernAbilityActionBar__MAB_ElementalButton
framehandle array ModernAbilityActionBar__MAB_ElementalIcon
framehandle array ModernAbilityActionBar__MAB_ElementalLabel
framehandle array ModernAbilityActionBar__MAB_ElementalDisabled
framehandle array ModernAbilityActionBar__MAB_ContextButton
framehandle array ModernAbilityActionBar__MAB_ContextIcon
framehandle array ModernAbilityActionBar__MAB_ContextLabel

framehandle array ModernAbilityActionBar__MAB_NativeFrame
boolean array ModernAbilityActionBar__MAB_NativeWasVisible
integer ModernAbilityActionBar__MAB_NativeFrameCount= 0

trigger ModernAbilityActionBar__MAB_SlotTrigger= null
trigger ModernAbilityActionBar__MAB_ElementalTrigger= null
trigger ModernAbilityActionBar__MAB_ContextTrigger= null
trigger ModernAbilityActionBar__MAB_ClearFocusTrigger= null
trigger ModernAbilityActionBar__MAB_HoverTrigger= null
trigger ModernAbilityActionBar__MAB_KeyTrigger= null
trigger ModernAbilityActionBar__MAB_InitTrigger= null

unit ModernAbilityActionBar__MAB_SelectedUnit= null
unit ModernAbilityActionBar__MAB_CachedHero= null
unit ModernAbilityActionBar__MAB_ElementalHero= null
boolean ModernAbilityActionBar__MAB_ElementalOpen= false
integer ModernAbilityActionBar__MAB_CachedTargetingAbility= - 1
integer ModernAbilityActionBar__MAB_CachedTargetingMode= - 1
integer ModernAbilityActionBar__MAB_CachedMana= - 1
integer array ModernAbilityActionBar__MAB_CachedAbilityId
integer array ModernAbilityActionBar__MAB_CachedAbilityLevel
integer array ModernAbilityActionBar__MAB_CachedManaCost
integer array ModernAbilityActionBar__MAB_CachedCooldownSecond
integer array ModernAbilityActionBar__MAB_CachedCooldownStep
boolean array ModernAbilityActionBar__MAB_CachedReady
boolean array ModernAbilityActionBar__MAB_CachedDisabled
boolean array ModernAbilityActionBar__MAB_CachedCooldownVisible
boolean array ModernAbilityActionBar__MAB_CooldownActive
string array ModernAbilityActionBar__MAB_CachedTitle
string array ModernAbilityActionBar__MAB_CachedBody
string array ModernAbilityActionBar__MAB_CachedIcon
boolean array ModernAbilityActionBar__MAB_ElementalReady
integer array ModernAbilityActionBar__MAB_ContextAbilityId
oskeytype array ModernAbilityActionBar__MAB_SlotKey
string array ModernAbilityActionBar__MAB_SlotKeyLabel
//endglobals from ModernAbilityActionBar
unit udg_Nazgrek= null
unit udg_Zulkis= null

trigger l__library_init

//JASSHelper struct globals:

endglobals


//library AbilitiesLiteUI:
    function AbilitiesLiteUI_ShowForUnit takes unit whichUnit returns nothing
        set whichUnit=null
    endfunction
    function AbilitiesLiteUI_GetModernPendingAbilityId takes nothing returns integer
        return 0
    endfunction
    function AbilitiesLiteUI_ClearModernPendingAbility takes nothing returns nothing
    endfunction

//library AbilitiesLiteUI ends
//library AbilitiesPlayer:
    function AbilitiesPlayer_EnsureInitialized takes nothing returns nothing
    endfunction
    function AbilitiesPlayer_GetEntryCount takes nothing returns integer
        return 0
    endfunction
    function AbilitiesPlayer_GetEntryKind takes integer entryIndex returns integer
        return AbilitiesPlayer_ENTRY_ABILITY
    endfunction
    function AbilitiesPlayer_GetEntryAbilityId takes integer entryIndex returns integer
        return 0
    endfunction
    function AbilitiesPlayer_GetEntryAddAbilityId takes integer entryIndex returns integer
        return 0
    endfunction
    function AbilitiesPlayer_GetEntryByAbilityId takes integer abilityId returns integer
        return 0
    endfunction
    function AbilitiesPlayer_GetEntryTitle takes integer entryIndex returns string
        return ""
    endfunction
    function AbilitiesPlayer_GetEntryBodyForLevel takes integer entryIndex,integer abilityLevel returns string
        return ""
    endfunction

//library AbilitiesPlayer ends
//library DEquipment:
    function ToggleDEqUIForUnit takes integer playerId,unit whichUnit returns boolean
        set whichUnit=null
        return true
    endfunction
    function DInspectResolveSelectedTarget takes player viewer returns unit
        set viewer=null
        return null
    endfunction
    function DEqShowUnitForPlayer takes player viewer,unit whichUnit,boolean inspectMode returns boolean
        set viewer=null
        set whichUnit=null
        return true
    endfunction
    function DInventoryEquipment_HideForPlayer takes player viewer returns nothing
        set viewer=null
    endfunction

//library DEquipment ends
//library DInventory:
    function DInvToggleUnitForPlayer takes player viewer,unit whichUnit,boolean inspectMode returns boolean
        set viewer=null
        set whichUnit=null
        return true
    endfunction
    function DInvShowUnitForPlayer takes player viewer,unit whichUnit,boolean inspectMode returns boolean
        set viewer=null
        set whichUnit=null
        return true
    endfunction
    function DInvIsPlayerInspecting takes integer playerId returns boolean
        return false
    endfunction

//library DInventory ends
//library DynamicMinimap:
    function DynamicMinimap_GetMinimapEnlarged takes nothing returns boolean
        return false
    endfunction

//library DynamicMinimap ends
//library Events:
    function Events_RegisterPlayerUnitEvent takes code callback,playerunitevent whichEvent returns nothing
    endfunction
    function Events_RegisterSpellEffect takes code callback returns nothing
    endfunction

//library Events ends
//library FullscreenUI:
    function FullscreenUI_IsEnabled takes nothing returns boolean
        return false
    endfunction

//library FullscreenUI ends
//library MasterUI:
    function MasterUI_ClosePanels takes nothing returns nothing
    endfunction

//library MasterUI ends
//library ShamanCommon:
    function ShamanCommon_IsAlive takes unit whichUnit returns boolean
        set whichUnit=null
        return true
    endfunction
    function ShamanCommon_IsPlayerHero takes unit whichUnit returns boolean
        set whichUnit=null
        return true
    endfunction
    function ShamanCommon_GetHeroSlot takes unit whichUnit returns integer
        set whichUnit=null
        return ShamanCommon_HERO_SLOT_NAZGREK
    endfunction
    function ShamanCommon_GetHeroBySlot takes integer heroSlot returns unit
        return udg_Nazgrek
    endfunction

//library ShamanCommon ends
//library Totems:
    function Totems_GetLiveTotemForSlot takes unit caster,integer slot returns unit
        set caster=null
        return null
    endfunction
    function Totems_GetRemainingDuration takes unit totem returns real
        set totem=null
        return 0.00
    endfunction
    function Totems_GetTotalDuration takes unit totem returns real
        set totem=null
        return 0.00
    endfunction

//library Totems ends
//library ModernAbilityCatalog:


function ModernAbilityCatalog__MAC_Register takes integer abilityId,integer actionKind,integer targetPolicy,real acquireRadius,boolean selfFallback returns nothing
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return
    endif

    set ModernAbilityCatalog__MAC_ActionKind[entryIndex]=actionKind
    set ModernAbilityCatalog__MAC_TargetPolicy[entryIndex]=targetPolicy
    set ModernAbilityCatalog__MAC_AcquireRadius[entryIndex]=acquireRadius
    set ModernAbilityCatalog__MAC_SelfFallback[entryIndex]=selfFallback
endfunction

function ModernAbilityCatalog__MAC_RegisterOrder takes integer abilityId,string orderString,boolean runtimeReady returns nothing
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return
    endif

    if orderString != null and orderString != "" then
        set ModernAbilityCatalog__MAC_OrderId[entryIndex]=OrderId(orderString)
    endif
    set ModernAbilityCatalog__MAC_RuntimeReady[entryIndex]=runtimeReady and ( ModernAbilityCatalog__MAC_OrderId[entryIndex] != 0 or ModernAbilityCatalog__MAC_ActionKind[entryIndex] == ModernAbilityCatalog_ACTION_SUBMENU )
endfunction

function ModernAbilityCatalog__MAC_RegisterChannelOrder takes integer abilityId,string orderString returns nothing
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    call ModernAbilityCatalog__MAC_RegisterOrder(abilityId , orderString , true)
    if entryIndex != 0 then
        set ModernAbilityCatalog__MAC_UsesChannelOrder[entryIndex]=true
    endif
endfunction

function ModernAbilityCatalog__MAC_RegisterElemental takes nothing returns nothing
    call ModernAbilityCatalog__MAC_Register('A6A0' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Lightning Bolt
    call ModernAbilityCatalog__MAC_Register('A67H' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_APPROXIMATE_POINT , 0.00 , false) // Lightning Strike
    call ModernAbilityCatalog__MAC_Register('A67L' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Chain Lightning
    call ModernAbilityCatalog__MAC_Register('A67J' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Fire Shock
    call ModernAbilityCatalog__MAC_Register('A69L' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Frost Shock
    call ModernAbilityCatalog__MAC_Register('A69N' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Nature Shock
    call ModernAbilityCatalog__MAC_Register('A68H' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SELF , 0.00 , true) // Lightning Shield
    call ModernAbilityCatalog__MAC_Register('A67Q' , ModernAbilityCatalog_ACTION_SUBMENU , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Summon Elemental
endfunction

function ModernAbilityCatalog__MAC_RegisterEnhancement takes nothing returns nothing
    call ModernAbilityCatalog__MAC_Register('A685' , ModernAbilityCatalog_ACTION_IMMEDIATE , ModernAbilityCatalog_TARGET_MELEE_AUTO , ModernAbilityCatalog__MAC_DEFAULT_MELEE_RADIUS , false) // Stormstrike
    call ModernAbilityCatalog__MAC_Register('A6DP' , ModernAbilityCatalog_ACTION_IMMEDIATE , ModernAbilityCatalog_TARGET_MELEE_AUTO , ModernAbilityCatalog__MAC_DEFAULT_MELEE_RADIUS , false) // Whirlwind
    call ModernAbilityCatalog__MAC_Register('A026' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Wind Shear
    call ModernAbilityCatalog__MAC_Register('A022' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Primal Force
    call ModernAbilityCatalog__MAC_Register('A67N' , ModernAbilityCatalog_ACTION_IMMEDIATE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Bloodlust
    call ModernAbilityCatalog__MAC_Register('A68Y' , ModernAbilityCatalog_ACTION_IMMEDIATE , ModernAbilityCatalog_TARGET_SELF , 0.00 , true) // Ghost Wolf
    call ModernAbilityCatalog__MAC_Register('A679' , ModernAbilityCatalog_ACTION_IMMEDIATE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Feral Spirits
    call ModernAbilityCatalog__MAC_Register('A673' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Hex
    call ModernAbilityCatalog__MAC_Register('A675' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_HOSTILE , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , false) // Voodoo Curse
    call ModernAbilityCatalog__MAC_Register('A677' , ModernAbilityCatalog_ACTION_IMMEDIATE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Voodoo Spirits
endfunction

function ModernAbilityCatalog__MAC_RegisterRestoration takes nothing returns nothing
    call ModernAbilityCatalog__MAC_Register('A66Y' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_FRIENDLY , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , true) // Healing Wave
    call ModernAbilityCatalog__MAC_Register('A672' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_FRIENDLY , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , true) // Chain Heal
    call ModernAbilityCatalog__MAC_Register('A66W' , ModernAbilityCatalog_ACTION_IMMEDIATE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Healing Rain
    call ModernAbilityCatalog__MAC_Register('A69W' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_FRIENDLY , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , true) // Rejuvenation
    call ModernAbilityCatalog__MAC_Register('A62Z' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SELF , 0.00 , true) // Water Shield
    call ModernAbilityCatalog__MAC_Register('A01Z' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_FRIENDLY , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , true) // Spirit Link
    call ModernAbilityCatalog__MAC_Register('A6AL' , ModernAbilityCatalog_ACTION_UNIT , ModernAbilityCatalog_TARGET_SOFT_FRIENDLY , ModernAbilityCatalog__MAC_DEFAULT_SOFT_RADIUS , true) // Ancestral Ward
    call ModernAbilityCatalog__MAC_Register('A638' , ModernAbilityCatalog_ACTION_PASSIVE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Spiritual Healing
    call ModernAbilityCatalog__MAC_Register('A69Y' , ModernAbilityCatalog_ACTION_PASSIVE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Totemic Resurgence
    call ModernAbilityCatalog__MAC_Register('A68A' , ModernAbilityCatalog_ACTION_PASSIVE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Reincarnation
endfunction

function ModernAbilityCatalog__MAC_RegisterTotemic takes nothing returns nothing
    call ModernAbilityCatalog__MAC_Register('A63F' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Earth Totem
    call ModernAbilityCatalog__MAC_Register('A63G' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Fire Totem
    call ModernAbilityCatalog__MAC_Register('A63H' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Water Totem
    call ModernAbilityCatalog__MAC_Register('A63I' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Wind Totem
    call ModernAbilityCatalog__MAC_Register('A68J' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Stoneskin Totem
    call ModernAbilityCatalog__MAC_Register('A68L' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Earthbind Totem
    call ModernAbilityCatalog__MAC_Register('A68F' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Cleansing Totem
    call ModernAbilityCatalog__MAC_Register('A68T' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Windfury Totem
    call ModernAbilityCatalog__MAC_Register('A01U' , ModernAbilityCatalog_ACTION_POINT , ModernAbilityCatalog_TARGET_PRECISE_POINT , 0.00 , false) // Skyfury Totem
    call ModernAbilityCatalog__MAC_Register('A636' , ModernAbilityCatalog_ACTION_PASSIVE , ModernAbilityCatalog_TARGET_NONE , 0.00 , false) // Totem Master
endfunction

function ModernAbilityCatalog__MAC_RegisterOrders takes nothing returns nothing
    call ModernAbilityCatalog__MAC_RegisterOrder('A6A0' , "firebolt" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A67H' , "blizzard" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A67L' , "chainlightning" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A67J' , "firebolt" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A69L' , "frostnova" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A69N' , "thunderbolt" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A68H' , "lightningshield" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A67Q' , "" , true)

    call ModernAbilityCatalog__MAC_RegisterOrder('A685' , "summongrizzly" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A6DP' , "whirlwind" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A026' , "thunderbolt" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A022' , "thunderbolt" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A67N' , "berserk" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A68Y' , "fanofknives" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A679' , "spiritwolf" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A673' , "hex" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A675' , "acidbomb" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A677' , "locustswarm" , true)

    call ModernAbilityCatalog__MAC_RegisterOrder('A66Y' , "holybolt" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A672' , "healingwave" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A66W' , "tranquility" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A69W' , "rejuvination" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A62Z' , "innerfire" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A01Z' , "spiritlink" , true)
    call ModernAbilityCatalog__MAC_RegisterOrder('A6AL' , "innerfire" , true)

    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A63F' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A63G' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A63H' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A63I' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A68J' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A68L' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A68F' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A68T' , "undeadbuild")
    call ModernAbilityCatalog__MAC_RegisterChannelOrder('A01U' , "undeadbuild")
endfunction

function ModernAbilityCatalog_GetActionKind takes integer abilityId returns integer
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return ModernAbilityCatalog_ACTION_NONE
    endif
    return ModernAbilityCatalog__MAC_ActionKind[entryIndex]
endfunction

function ModernAbilityCatalog_GetTargetPolicy takes integer abilityId returns integer
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return ModernAbilityCatalog_TARGET_NONE
    endif
    return ModernAbilityCatalog__MAC_TargetPolicy[entryIndex]
endfunction

function ModernAbilityCatalog_GetAcquireRadius takes integer abilityId returns real
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return 0.00
    endif
    return ModernAbilityCatalog__MAC_AcquireRadius[entryIndex]
endfunction

function ModernAbilityCatalog_GetOrderId takes integer abilityId returns integer
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return 0
    endif
    return ModernAbilityCatalog__MAC_OrderId[entryIndex]
endfunction

function ModernAbilityCatalog_UsesChannelOrder takes integer abilityId returns boolean
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    return entryIndex != 0 and ModernAbilityCatalog__MAC_UsesChannelOrder[entryIndex]
endfunction

function ModernAbilityCatalog_IsRuntimeReady takes integer abilityId returns boolean
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    return entryIndex != 0 and ModernAbilityCatalog__MAC_RuntimeReady[entryIndex]
endfunction

function ModernAbilityCatalog_AllowsSelfFallback takes integer abilityId returns boolean
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    return entryIndex != 0 and ModernAbilityCatalog__MAC_SelfFallback[entryIndex]
endfunction

function ModernAbilityCatalog_IsAssignable takes integer abilityId returns boolean
    local integer actionKind= ModernAbilityCatalog_GetActionKind(abilityId)

    return actionKind == ModernAbilityCatalog_ACTION_IMMEDIATE or actionKind == ModernAbilityCatalog_ACTION_UNIT or actionKind == ModernAbilityCatalog_ACTION_POINT or actionKind == ModernAbilityCatalog_ACTION_SUBMENU
endfunction

function ModernAbilityCatalog__Init takes nothing returns nothing
    call AbilitiesPlayer_EnsureInitialized()
    call ModernAbilityCatalog__MAC_RegisterElemental()
    call ModernAbilityCatalog__MAC_RegisterEnhancement()
    call ModernAbilityCatalog__MAC_RegisterRestoration()
    call ModernAbilityCatalog__MAC_RegisterTotemic()
    call ModernAbilityCatalog__MAC_RegisterOrders()
endfunction


//library ModernAbilityCatalog ends
//library ModernPlayerHUD:


function ModernPlayerHUD__MHUD_IsValidUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetHandleId(whichUnit) != 0 and GetUnitTypeId(whichUnit) != 0
endfunction

function ModernPlayerHUD__MHUD_IsPlayerHero takes unit whichUnit returns boolean
    return whichUnit != null and GetOwningPlayer(whichUnit) == Player(0) and ( whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis )
endfunction

function ModernPlayerHUD__MHUD_GetDisplayName takes unit whichUnit returns string
    if not ModernPlayerHUD__MHUD_IsValidUnit(whichUnit) then
        return ""
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroProperName(whichUnit)
    endif
    return GetUnitName(whichUnit)
endfunction

function ModernPlayerHUD__MHUD_GetDisplayLevel takes unit whichUnit returns integer
    if not ModernPlayerHUD__MHUD_IsValidUnit(whichUnit) then
        return 0
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroLevel(whichUnit)
    endif
    return GetUnitLevel(whichUnit)
endfunction

function ModernPlayerHUD__MHUD_GetHeroXPRequiredForLevel takes integer targetLevel returns integer
    local integer level= 2
    local integer required= 0

    if targetLevel <= 1 then
        return 0
    endif

    loop
        exitwhen level > targetLevel
        set required=ModernPlayerHUD__MHUD_HERO_XP_FORMULA_A * required + ModernPlayerHUD__MHUD_HERO_XP_FORMULA_B * level + ModernPlayerHUD__MHUD_HERO_XP_FORMULA_C
        set level=level + 1
    endloop

    return required
endfunction

function ModernPlayerHUD__MHUD_ClampRatio takes real value returns real
    if value < 0.00 then
        return 0.00
    elseif value > 1.00 then
        return 1.00
    endif
    return value
endfunction

function ModernPlayerHUD__MHUD_FormatResourceText takes integer current,integer maximum returns string
    local integer percent= 0

    if maximum > 0 then
        set percent=R2I(100.00 * I2R(current) / I2R(maximum) + 0.50)
    endif
    if percent < 0 then
        set percent=0
    elseif percent > 100 then
        set percent=100
    endif
    return I2S(current) + " / " + I2S(maximum) + "  (" + I2S(percent) + "%)"
endfunction

function ModernPlayerHUD__MHUD_ResetCache takes nothing returns nothing
    set ModernPlayerHUD__MHUD_CachedUnit=null
    set ModernPlayerHUD__MHUD_CachedLife=- 1
    set ModernPlayerHUD__MHUD_CachedMaxLife=- 1
    set ModernPlayerHUD__MHUD_CachedMana=- 1
    set ModernPlayerHUD__MHUD_CachedMaxMana=- 1
    set ModernPlayerHUD__MHUD_CachedLevel=- 1
    set ModernPlayerHUD__MHUD_CachedXP=- 1
    set ModernPlayerHUD__MHUD_BarStep[ModernPlayerHUD__MHUD_BAR_HEALTH]=- 1
    set ModernPlayerHUD__MHUD_BarStep[ModernPlayerHUD__MHUD_BAR_MANA]=- 1
    set ModernPlayerHUD__MHUD_BarStep[ModernPlayerHUD__MHUD_BAR_XP]=- 1
endfunction

function ModernPlayerHUD__MHUD_SetParentVisible takes boolean visible returns nothing
    if ModernPlayerHUD__MHUD_ParentVisible != visible then
        set ModernPlayerHUD__MHUD_ParentVisible=visible
        call BlzFrameSetVisible(ModernPlayerHUD__MHUD_Parent, visible)
    endif
endfunction

function ModernPlayerHUD__MHUD_SetManaVisible takes boolean visible returns nothing
    if ModernPlayerHUD__MHUD_ManaVisible != visible then
        set ModernPlayerHUD__MHUD_ManaVisible=visible
        call BlzFrameSetVisible(ModernPlayerHUD__MHUD_ManaBack, visible)
    endif
endfunction

function ModernPlayerHUD__MHUD_SetXPVisible takes boolean visible returns nothing
    if ModernPlayerHUD__MHUD_XPVisible != visible then
        set ModernPlayerHUD__MHUD_XPVisible=visible
        call BlzFrameSetVisible(ModernPlayerHUD__MHUD_XPBack, visible)
    endif
endfunction

function ModernPlayerHUD__MHUD_SetBookVisible takes boolean visible returns nothing
    if ModernPlayerHUD__MHUD_BookVisible != visible then
        set ModernPlayerHUD__MHUD_BookVisible=visible
        call BlzFrameSetVisible(ModernPlayerHUD__MHUD_BookButton, visible)
    endif
endfunction

function ModernPlayerHUD__MHUD_SetBarFill takes framehandle fillFrame,real width,real height,real current,real maximum,integer barIndex returns nothing
    local real ratio= 0.00
    local integer step

    if maximum > 0.00 then
        set ratio=ModernPlayerHUD__MHUD_ClampRatio(current / maximum)
    endif
    set step=R2I(ratio * 1000.00)
    if ModernPlayerHUD__MHUD_BarStep[barIndex] != step then
        set ModernPlayerHUD__MHUD_BarStep[barIndex]=step
        if step <= 0 then
            call BlzFrameSetSize(fillFrame, 0.0001, height)
        else
            call BlzFrameSetSize(fillFrame, width * I2R(step) / 1000.00, height)
        endif
    endif

    set fillFrame=null
endfunction

function ModernPlayerHUD__MHUD_UpdateXP takes unit whichUnit returns nothing
    local integer level
    local integer currentXP
    local integer previousXP
    local integer nextXP
    local integer progress
    local integer required

    if not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        call ModernPlayerHUD__MHUD_SetXPVisible(false)
        return
    endif

    set level=GetHeroLevel(whichUnit)
    set currentXP=GetHeroXP(whichUnit)
    call ModernPlayerHUD__MHUD_SetXPVisible(true)
    if level == ModernPlayerHUD__MHUD_CachedLevel and currentXP == ModernPlayerHUD__MHUD_CachedXP then
        return
    endif
    set ModernPlayerHUD__MHUD_CachedXP=currentXP
    set previousXP=ModernPlayerHUD__MHUD_GetHeroXPRequiredForLevel(level)
    set nextXP=ModernPlayerHUD__MHUD_GetHeroXPRequiredForLevel(level + 1)
    set progress=currentXP - previousXP
    set required=nextXP - previousXP

    if progress < 0 then
        set progress=0
    endif
    if required <= 0 then
        call ModernPlayerHUD__MHUD_SetBarFill(ModernPlayerHUD__MHUD_XPFill , ModernPlayerHUD__MHUD_XP_BAR_WIDTH , ModernPlayerHUD__MHUD_XP_BAR_HEIGHT , 1.00 , 1.00 , ModernPlayerHUD__MHUD_BAR_XP)
        call BlzFrameSetText(ModernPlayerHUD__MHUD_XPText, "MAX")
    else
        call ModernPlayerHUD__MHUD_SetBarFill(ModernPlayerHUD__MHUD_XPFill , ModernPlayerHUD__MHUD_XP_BAR_WIDTH , ModernPlayerHUD__MHUD_XP_BAR_HEIGHT , I2R(progress) , I2R(required) , ModernPlayerHUD__MHUD_BAR_XP)
        call BlzFrameSetText(ModernPlayerHUD__MHUD_XPText, I2S(progress) + " / " + I2S(required) + " XP")
    endif
endfunction

function ModernPlayerHUD__MHUD_Update takes nothing returns nothing
    local unit whichUnit= ModernPlayerHUD__MHUD_SelectedUnit
    local integer life
    local integer maxLife
    local integer mana
    local integer maxMana
    local integer level
    local boolean playerHero

    if not ModernPlayerHUD__MHUD_Enabled or ModernPlayerHUD__MHUD_Parent == null then
        set whichUnit=null
        return
    endif

    if (false) then // INLINED!!
        set ModernPlayerHUD__MHUD_WasFullscreen=true
        call ModernPlayerHUD__MHUD_SetParentVisible(false)
        set whichUnit=null
        return
    endif

    if ModernPlayerHUD__MHUD_WasFullscreen then
        set ModernPlayerHUD__MHUD_WasFullscreen=false
    endif

    if not ModernPlayerHUD__MHUD_IsValidUnit(whichUnit) and GetLocalPlayer() == Player(0) and ModernPlayerHUD__MHUD_IsValidUnit(udg_Nazgrek) then
        set whichUnit=udg_Nazgrek
        set ModernPlayerHUD__MHUD_SelectedUnit=whichUnit
    endif

    if not ModernPlayerHUD__MHUD_IsValidUnit(whichUnit) then
        call ModernPlayerHUD__MHUD_SetParentVisible(false)
        set whichUnit=null
        return
    endif

    if ModernPlayerHUD__MHUD_CachedUnit != whichUnit then
        call ModernPlayerHUD__MHUD_ResetCache()
        set ModernPlayerHUD__MHUD_CachedUnit=whichUnit
        call BlzFrameSetText(ModernPlayerHUD__MHUD_NameText, "|cffffe4a3" + ModernPlayerHUD__MHUD_GetDisplayName(whichUnit) + "|r")
    endif

    set life=R2I(GetWidgetLife(whichUnit))
    set maxLife=BlzGetUnitMaxHP(whichUnit)
    set mana=R2I(GetUnitState(whichUnit, UNIT_STATE_MANA))
    set maxMana=BlzGetUnitMaxMana(whichUnit)
    set level=ModernPlayerHUD__MHUD_GetDisplayLevel(whichUnit)
    set playerHero=ModernPlayerHUD__MHUD_IsPlayerHero(whichUnit)

    call ModernPlayerHUD__MHUD_SetParentVisible(true)
    if level != ModernPlayerHUD__MHUD_CachedLevel then
        set ModernPlayerHUD__MHUD_CachedLevel=level
        set ModernPlayerHUD__MHUD_CachedXP=- 1
        call BlzFrameSetText(ModernPlayerHUD__MHUD_LevelText, I2S(level))
    endif
    if life != ModernPlayerHUD__MHUD_CachedLife or maxLife != ModernPlayerHUD__MHUD_CachedMaxLife then
        set ModernPlayerHUD__MHUD_CachedLife=life
        set ModernPlayerHUD__MHUD_CachedMaxLife=maxLife
        call BlzFrameSetText(ModernPlayerHUD__MHUD_HealthText, ModernPlayerHUD__MHUD_FormatResourceText(life , maxLife))
        call ModernPlayerHUD__MHUD_SetBarFill(ModernPlayerHUD__MHUD_HealthFill , ModernPlayerHUD__MHUD_RESOURCE_BAR_WIDTH , ModernPlayerHUD__MHUD_RESOURCE_BAR_HEIGHT , I2R(life) , I2R(maxLife) , ModernPlayerHUD__MHUD_BAR_HEALTH)
    endif

    if maxMana > 0 then
        call ModernPlayerHUD__MHUD_SetManaVisible(true)
        if mana != ModernPlayerHUD__MHUD_CachedMana or maxMana != ModernPlayerHUD__MHUD_CachedMaxMana then
            set ModernPlayerHUD__MHUD_CachedMana=mana
            set ModernPlayerHUD__MHUD_CachedMaxMana=maxMana
            call BlzFrameSetText(ModernPlayerHUD__MHUD_ManaText, ModernPlayerHUD__MHUD_FormatResourceText(mana , maxMana))
            call ModernPlayerHUD__MHUD_SetBarFill(ModernPlayerHUD__MHUD_ManaFill , ModernPlayerHUD__MHUD_RESOURCE_BAR_WIDTH , ModernPlayerHUD__MHUD_RESOURCE_BAR_HEIGHT , I2R(mana) , I2R(maxMana) , ModernPlayerHUD__MHUD_BAR_MANA)
        endif
    else
        call ModernPlayerHUD__MHUD_SetManaVisible(false)
    endif

    call ModernPlayerHUD__MHUD_UpdateXP(whichUnit)
    call ModernPlayerHUD__MHUD_SetBookVisible(playerHero)

    set whichUnit=null
endfunction

function ModernPlayerHUD__MHUD_Tick takes nothing returns nothing
    call ModernPlayerHUD__MHUD_Update()
    call TriggerExecute(ModernPlayerHUD__MHUD_UpdateTrigger)
endfunction

function ModernPlayerHUD__MHUD_ClearFocusAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()

    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
    endif

    set triggerFrame=null
endfunction

function ModernPlayerHUD__MHUD_BookAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() and ModernPlayerHUD__MHUD_IsPlayerHero(ModernPlayerHUD__MHUD_SelectedUnit) then
        call MasterUI_ClosePanels()
        call AbilitiesLiteUI_ShowForUnit(ModernPlayerHUD__MHUD_SelectedUnit)
    endif
endfunction

function ModernPlayerHUD__MHUD_UtilityAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()
    local player viewer= GetTriggerPlayer()
    local integer pid= GetPlayerId(viewer)
    local unit target= null
    local boolean opened= false

    if viewer == GetLocalPlayer() and ModernPlayerHUD__MHUD_IsPlayerHero(ModernPlayerHUD__MHUD_SelectedUnit) then
        call MasterUI_ClosePanels()

            if triggerFrame == ModernPlayerHUD__MHUD_InventoryButton then
                call DInvToggleUnitForPlayer(viewer , ModernPlayerHUD__MHUD_SelectedUnit , false)
            endif


            if triggerFrame == ModernPlayerHUD__MHUD_EquipmentButton then
                call ToggleDEqUIForUnit(pid , ModernPlayerHUD__MHUD_SelectedUnit)
            elseif triggerFrame == ModernPlayerHUD__MHUD_InspectButton then
                if DInvIsPlayerInspecting(pid) then
                    call DInventoryEquipment_HideForPlayer(viewer)
                else
                    set target=DInspectResolveSelectedTarget(viewer)
                    if target != null then

                            set opened=DInvShowUnitForPlayer(viewer , target , true)

                        if DEqShowUnitForPlayer(viewer , target , true) then
                            set opened=true
                        endif
                    endif
                    if not opened then
                        call DisplayTimedTextToPlayer(viewer, 0.00, 0.00, 2.00, "|cffffcc00Select an inspectable hero or companion first.|r")
                    endif
                endif
            endif

    endif

    set target=null
    set viewer=null
    set triggerFrame=null
endfunction

function ModernPlayerHUD__MHUD_CreateUtilityButton takes string frameName,string label,string iconPath,real x returns framehandle
    local framehandle utilityButton= BlzCreateFrameByType("BUTTON", frameName, ModernPlayerHUD__MHUD_Parent, "", 0)
    local framehandle border= BlzCreateFrameByType("BACKDROP", frameName + "Border", utilityButton, "", 0)
    local framehandle icon= BlzCreateFrameByType("BACKDROP", frameName + "Icon", utilityButton, "", 0)
    local framehandle labelText= BlzCreateFrameByType("TEXT", frameName + "Label", utilityButton, "", 0)

    call BlzFrameSetAbsPoint(utilityButton, FRAMEPOINT_BOTTOMLEFT, x, ModernPlayerHUD__MHUD_ACTION_BOTTOM)
    call BlzFrameSetSize(utilityButton, 0.032, ModernPlayerHUD__MHUD_ACTION_SIZE)
    call BlzFrameSetLevel(utilityButton, 7)

    call BlzFrameSetAllPoints(border, utilityButton)
    call BlzFrameSetTexture(border, ModernPlayerHUD__MHUD_ACTION_SLOT_TEXTURE, 0, true)
    call BlzFrameSetEnable(border, false)
    call BlzFrameSetLevel(border, 8)

    call BlzFrameSetPoint(icon, FRAMEPOINT_BOTTOMLEFT, utilityButton, FRAMEPOINT_BOTTOMLEFT, 0.003, 0.003)
    call BlzFrameSetPoint(icon, FRAMEPOINT_TOPRIGHT, utilityButton, FRAMEPOINT_TOPRIGHT, - 0.003, - 0.003)
    call BlzFrameSetTexture(icon, iconPath, 0, true)
    call BlzFrameSetEnable(icon, false)
    call BlzFrameSetLevel(icon, 9)

    call BlzFrameSetPoint(labelText, FRAMEPOINT_BOTTOM, utilityButton, FRAMEPOINT_BOTTOM, 0.000, 0.001)
    call BlzFrameSetSize(labelText, 0.028, 0.008)
    call BlzFrameSetTextAlignment(labelText, TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(labelText, 0.48)
    call BlzFrameSetText(labelText, "|cffffd36b" + label + "|r")
    call BlzFrameSetEnable(labelText, false)
    call BlzFrameSetLevel(labelText, 10)

    call BlzTriggerRegisterFrameEvent(ModernPlayerHUD__MHUD_UtilityTrigger, utilityButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(ModernPlayerHUD__MHUD_ClearFocusTrigger, utilityButton, FRAMEEVENT_CONTROL_CLICK)
    set border=null
    set icon=null
    set labelText=null
    return utilityButton
endfunction

function ModernPlayerHUD__MHUD_CreateFrames takes nothing returns nothing
    local integer index= 0
    local real x

    if ModernPlayerHUD__MHUD_FramesCreated then
        return
    endif
    set ModernPlayerHUD__MHUD_FramesCreated=true

    // ConsoleUIBackdrop is below the Warcraft III 2.x bottom-console layers.
    // Own custom frames directly under GameUI so the restored native HUD does
    // not cover them after FullscreenUI ends.
    set ModernPlayerHUD__MHUD_ScreenParent=BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)

    set ModernPlayerHUD__MHUD_Parent=BlzCreateFrameByType("FRAME", "ModernPlayerHUDPanel", ModernPlayerHUD__MHUD_ScreenParent, "", 0)
    call BlzFrameSetAbsPoint(ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_TOPLEFT, ModernPlayerHUD__MHUD_PANEL_LEFT, ModernPlayerHUD__MHUD_PANEL_TOP)
    call BlzFrameSetAbsPoint(ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_BOTTOMRIGHT, ModernPlayerHUD__MHUD_PANEL_RIGHT, ModernPlayerHUD__MHUD_PANEL_BOTTOM)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_Parent, 20)

    set ModernPlayerHUD__MHUD_Backdrop=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDBackdrop", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_Backdrop, FRAMEPOINT_BOTTOM, ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_BOTTOM, 0.000, 0.000)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_Backdrop, 0.540, 0.061)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_Backdrop, ModernPlayerHUD__MHUD_PANEL_TEXTURE, 0, true)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_Backdrop, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_Backdrop, 1)

    set ModernPlayerHUD__MHUD_TopTrim=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDTopTrim", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_TopTrim, ModernPlayerHUD__MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_TopTrim, FRAMEPOINT_TOP, ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_TOP, 0.000, - 0.002)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_TopTrim, ModernPlayerHUD__MHUD_PANEL_RIGHT - ModernPlayerHUD__MHUD_PANEL_LEFT - 0.050, 0.0015)
    call BlzFrameSetVertexColor(ModernPlayerHUD__MHUD_TopTrim, BlzConvertColor(220, 188, 145, 74))
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_TopTrim, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_TopTrim, 2)

    set ModernPlayerHUD__MHUD_NameText=BlzCreateFrameByType("TEXT", "ModernPlayerHUDName", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_NameText, FRAMEPOINT_TOP, ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_TOP, 0.000, - 0.001)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_NameText, 0.180, 0.014)
    call BlzFrameSetTextAlignment(ModernPlayerHUD__MHUD_NameText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernPlayerHUD__MHUD_NameText, 0.72)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_NameText, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_NameText, 6)

    set ModernPlayerHUD__MHUD_ResourceBarBack=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDResourceBarBack", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_ResourceBarBack, ModernPlayerHUD__MHUD_BAR_BACK_TEXTURE, 0, true)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_ResourceBarBack, FRAMEPOINT_TOP, ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_TOP, 0.000, - 0.016)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_ResourceBarBack, 0.420, 0.024)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_ResourceBarBack, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_ResourceBarBack, 2)

    set ModernPlayerHUD__MHUD_ResourceBarFrame=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDResourceBarFrame", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_ResourceBarFrame, ModernPlayerHUD__MHUD_BAR_FRAME_TEXTURE, 0, true)
    call BlzFrameSetAllPoints(ModernPlayerHUD__MHUD_ResourceBarFrame, ModernPlayerHUD__MHUD_ResourceBarBack)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_ResourceBarFrame, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_ResourceBarFrame, 5)

    set ModernPlayerHUD__MHUD_LevelBackdrop=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDLevelBackdrop", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_LevelBackdrop, ModernPlayerHUD__MHUD_MEDALLION_TEXTURE, 0, true)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_LevelBackdrop, FRAMEPOINT_TOP, ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_TOP, 0.000, - 0.007)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_LevelBackdrop, 0.044, 0.044)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_LevelBackdrop, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_LevelBackdrop, 7)

    set ModernPlayerHUD__MHUD_LevelText=BlzCreateFrameByType("TEXT", "ModernPlayerHUDLevel", ModernPlayerHUD__MHUD_LevelBackdrop, "", 0)
    call BlzFrameSetAllPoints(ModernPlayerHUD__MHUD_LevelText, ModernPlayerHUD__MHUD_LevelBackdrop)
    call BlzFrameSetTextAlignment(ModernPlayerHUD__MHUD_LevelText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernPlayerHUD__MHUD_LevelText, 0.82)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_LevelText, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_LevelText, 8)

    set ModernPlayerHUD__MHUD_HealthBack=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDHealthBack", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_HealthBack, ModernPlayerHUD__MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_HealthBack, FRAMEPOINT_TOPRIGHT, ModernPlayerHUD__MHUD_LevelBackdrop, FRAMEPOINT_TOPLEFT, - 0.006, - 0.016)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_HealthBack, ModernPlayerHUD__MHUD_RESOURCE_BAR_WIDTH, ModernPlayerHUD__MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetVertexColor(ModernPlayerHUD__MHUD_HealthBack, BlzConvertColor(210, 18, 14, 12))
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_HealthBack, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_HealthBack, 3)

    set ModernPlayerHUD__MHUD_HealthFill=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDHealthFill", ModernPlayerHUD__MHUD_HealthBack, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_HealthFill, ModernPlayerHUD__MHUD_HEALTH_TEXTURE, 0, false)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_HealthFill, FRAMEPOINT_LEFT, ModernPlayerHUD__MHUD_HealthBack, FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_HealthFill, ModernPlayerHUD__MHUD_RESOURCE_BAR_WIDTH, ModernPlayerHUD__MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_HealthFill, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_HealthFill, 4)

    set ModernPlayerHUD__MHUD_HealthText=BlzCreateFrameByType("TEXT", "ModernPlayerHUDHealthText", ModernPlayerHUD__MHUD_HealthBack, "", 0)
    call BlzFrameSetAllPoints(ModernPlayerHUD__MHUD_HealthText, ModernPlayerHUD__MHUD_HealthBack)
    call BlzFrameSetTextAlignment(ModernPlayerHUD__MHUD_HealthText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernPlayerHUD__MHUD_HealthText, 0.55)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_HealthText, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_HealthText, 6)

    set ModernPlayerHUD__MHUD_ManaBack=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDManaBack", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_ManaBack, ModernPlayerHUD__MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_ManaBack, FRAMEPOINT_TOPLEFT, ModernPlayerHUD__MHUD_LevelBackdrop, FRAMEPOINT_TOPRIGHT, 0.006, - 0.016)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_ManaBack, ModernPlayerHUD__MHUD_RESOURCE_BAR_WIDTH, ModernPlayerHUD__MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetVertexColor(ModernPlayerHUD__MHUD_ManaBack, BlzConvertColor(210, 18, 14, 12))
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_ManaBack, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_ManaBack, 3)

    set ModernPlayerHUD__MHUD_ManaFill=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDManaFill", ModernPlayerHUD__MHUD_ManaBack, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_ManaFill, ModernPlayerHUD__MHUD_MANA_TEXTURE, 0, false)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_ManaFill, FRAMEPOINT_LEFT, ModernPlayerHUD__MHUD_ManaBack, FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_ManaFill, ModernPlayerHUD__MHUD_RESOURCE_BAR_WIDTH, ModernPlayerHUD__MHUD_RESOURCE_BAR_HEIGHT)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_ManaFill, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_ManaFill, 4)

    set ModernPlayerHUD__MHUD_ManaText=BlzCreateFrameByType("TEXT", "ModernPlayerHUDManaText", ModernPlayerHUD__MHUD_ManaBack, "", 0)
    call BlzFrameSetAllPoints(ModernPlayerHUD__MHUD_ManaText, ModernPlayerHUD__MHUD_ManaBack)
    call BlzFrameSetTextAlignment(ModernPlayerHUD__MHUD_ManaText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernPlayerHUD__MHUD_ManaText, 0.55)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_ManaText, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_ManaText, 6)

    set ModernPlayerHUD__MHUD_XPBack=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDXPBack", ModernPlayerHUD__MHUD_Parent, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_XPBack, ModernPlayerHUD__MHUD_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_XPBack, FRAMEPOINT_TOP, ModernPlayerHUD__MHUD_Parent, FRAMEPOINT_TOP, 0.000, - 0.049)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_XPBack, ModernPlayerHUD__MHUD_XP_BAR_WIDTH, ModernPlayerHUD__MHUD_XP_BAR_HEIGHT)
    call BlzFrameSetVertexColor(ModernPlayerHUD__MHUD_XPBack, BlzConvertColor(235, 38, 38, 38))
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_XPBack, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_XPBack, 3)

    set ModernPlayerHUD__MHUD_XPFill=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDXPFill", ModernPlayerHUD__MHUD_XPBack, "", 0)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_XPFill, ModernPlayerHUD__MHUD_XP_TEXTURE, 0, true)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_XPFill, FRAMEPOINT_LEFT, ModernPlayerHUD__MHUD_XPBack, FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_XPFill, ModernPlayerHUD__MHUD_XP_BAR_WIDTH, ModernPlayerHUD__MHUD_XP_BAR_HEIGHT)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_XPFill, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_XPFill, 4)

    set ModernPlayerHUD__MHUD_XPText=BlzCreateFrameByType("TEXT", "ModernPlayerHUDXPText", ModernPlayerHUD__MHUD_XPBack, "", 0)
    call BlzFrameSetAllPoints(ModernPlayerHUD__MHUD_XPText, ModernPlayerHUD__MHUD_XPBack)
    call BlzFrameSetTextAlignment(ModernPlayerHUD__MHUD_XPText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernPlayerHUD__MHUD_XPText, 0.46)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_XPText, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_XPText, 7)

    set index=1
    loop
        exitwhen index >= ModernPlayerHUD__MHUD_XP_SEGMENT_COUNT
        set ModernPlayerHUD__MHUD_XPSegment[index]=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDXPSegment" + I2S(index), ModernPlayerHUD__MHUD_XPBack, "", 0)
        call BlzFrameSetTexture(ModernPlayerHUD__MHUD_XPSegment[index], ModernPlayerHUD__MHUD_SURFACE_TEXTURE, 0, false)
        call BlzFrameSetPoint(ModernPlayerHUD__MHUD_XPSegment[index], FRAMEPOINT_CENTER, ModernPlayerHUD__MHUD_XPBack, FRAMEPOINT_LEFT, ModernPlayerHUD__MHUD_XP_BAR_WIDTH * I2R(index) / I2R(ModernPlayerHUD__MHUD_XP_SEGMENT_COUNT), 0.000)
        call BlzFrameSetSize(ModernPlayerHUD__MHUD_XPSegment[index], 0.0007, ModernPlayerHUD__MHUD_XP_BAR_HEIGHT)
        call BlzFrameSetVertexColor(ModernPlayerHUD__MHUD_XPSegment[index], BlzConvertColor(210, 8, 6, 12))
        call BlzFrameSetEnable(ModernPlayerHUD__MHUD_XPSegment[index], false)
        call BlzFrameSetLevel(ModernPlayerHUD__MHUD_XPSegment[index], 6)
        set index=index + 1
    endloop

    set index=0
    loop
        exitwhen index >= ModernPlayerHUD__MHUD_ACTION_SLOT_COUNT
        set x=ModernPlayerHUD__MHUD_ACTION_START_X + I2R(index) * ( ModernPlayerHUD__MHUD_ACTION_SIZE + ModernPlayerHUD__MHUD_ACTION_GAP )
        set ModernPlayerHUD__MHUD_SlotBackdrop[index]=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDSlot" + I2S(index), ModernPlayerHUD__MHUD_Parent, "", 0)
        call BlzFrameSetTexture(ModernPlayerHUD__MHUD_SlotBackdrop[index], ModernPlayerHUD__MHUD_ACTION_SLOT_TEXTURE, 0, true)
        call BlzFrameSetAbsPoint(ModernPlayerHUD__MHUD_SlotBackdrop[index], FRAMEPOINT_BOTTOMLEFT, x - 0.001, ModernPlayerHUD__MHUD_ACTION_BOTTOM - 0.001)
        call BlzFrameSetSize(ModernPlayerHUD__MHUD_SlotBackdrop[index], ModernPlayerHUD__MHUD_ACTION_SIZE + 0.002, ModernPlayerHUD__MHUD_ACTION_SIZE + 0.002)
        call BlzFrameSetEnable(ModernPlayerHUD__MHUD_SlotBackdrop[index], false)
        call BlzFrameSetLevel(ModernPlayerHUD__MHUD_SlotBackdrop[index], 3)
        call BlzFrameSetVisible(ModernPlayerHUD__MHUD_SlotBackdrop[index], true)
        set index=index + 1
    endloop

    set ModernPlayerHUD__MHUD_BookButton=BlzCreateFrameByType("GLUETEXTBUTTON", "ModernPlayerHUDBookButton", ModernPlayerHUD__MHUD_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetAbsPoint(ModernPlayerHUD__MHUD_BookButton, FRAMEPOINT_BOTTOMLEFT, 0.610, ModernPlayerHUD__MHUD_ACTION_BOTTOM)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_BookButton, 0.076, ModernPlayerHUD__MHUD_ACTION_SIZE)
    call BlzFrameSetText(ModernPlayerHUD__MHUD_BookButton, "    Abilities")
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_BookButton, 7)

    set ModernPlayerHUD__MHUD_BookIcon=BlzCreateFrameByType("BACKDROP", "ModernPlayerHUDBookIcon", ModernPlayerHUD__MHUD_BookButton, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(ModernPlayerHUD__MHUD_BookIcon, FRAMEPOINT_LEFT, ModernPlayerHUD__MHUD_BookButton, FRAMEPOINT_LEFT, 0.006, 0.000)
    call BlzFrameSetSize(ModernPlayerHUD__MHUD_BookIcon, 0.014, 0.014)
    call BlzFrameSetTexture(ModernPlayerHUD__MHUD_BookIcon, ModernPlayerHUD__MHUD_BOOK_ICON, 0, true)
    call BlzFrameSetEnable(ModernPlayerHUD__MHUD_BookIcon, false)
    call BlzFrameSetLevel(ModernPlayerHUD__MHUD_BookIcon, 8)

    call BlzTriggerRegisterFrameEvent(ModernPlayerHUD__MHUD_BookTrigger, ModernPlayerHUD__MHUD_BookButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(ModernPlayerHUD__MHUD_ClearFocusTrigger, ModernPlayerHUD__MHUD_BookButton, FRAMEEVENT_CONTROL_CLICK)


        set ModernPlayerHUD__MHUD_InventoryButton=ModernPlayerHUD__MHUD_CreateUtilityButton("ModernPlayerHUDInventoryButton" , "Bag" , ModernPlayerHUD__MHUD_BAG_ICON , 0.690)


        set ModernPlayerHUD__MHUD_EquipmentButton=ModernPlayerHUD__MHUD_CreateUtilityButton("ModernPlayerHUDEquipmentButton" , "Gear" , ModernPlayerHUD__MHUD_GEAR_ICON , 0.724)
        set ModernPlayerHUD__MHUD_InspectButton=ModernPlayerHUD__MHUD_CreateUtilityButton("ModernPlayerHUDInspectButton" , "Look" , ModernPlayerHUD__MHUD_INSPECT_ICON , 0.758)


    call BlzFrameSetVisible(ModernPlayerHUD__MHUD_Parent, false)
endfunction

function ModernPlayerHUD_SetUnit takes unit whichUnit returns nothing
    if ModernPlayerHUD__MHUD_SelectedUnit != whichUnit then
        set ModernPlayerHUD__MHUD_SelectedUnit=whichUnit
        call ModernPlayerHUD__MHUD_ResetCache()
    endif
    call ModernPlayerHUD__MHUD_Tick()
    set whichUnit=null
endfunction

function ModernPlayerHUD_GetUnit takes nothing returns unit
    return ModernPlayerHUD__MHUD_SelectedUnit
endfunction

function ModernPlayerHUD_Refresh takes nothing returns nothing
    if ModernPlayerHUD__MHUD_Enabled then
        call ModernPlayerHUD__MHUD_Tick()
    endif
endfunction

function ModernPlayerHUD_RegisterUpdate takes code callback returns nothing
    call TriggerAddAction(ModernPlayerHUD__MHUD_UpdateTrigger, callback)
endfunction

function ModernPlayerHUD_Enable takes nothing returns nothing
    if not ModernPlayerHUD__MHUD_Initialized or (false) then // INLINED!!
        return
    endif
    if not ModernPlayerHUD__MHUD_FramesCreated then
        call ModernPlayerHUD__MHUD_CreateFrames()
    endif

    set ModernPlayerHUD__MHUD_Enabled=true
    set ModernPlayerHUD__MHUD_WasFullscreen=false
    call ModernPlayerHUD__MHUD_ResetCache()
    call TimerStart(ModernPlayerHUD__MHUD_UpdateTimer, ModernPlayerHUD__MHUD_UPDATE_INTERVAL, true, function ModernPlayerHUD__MHUD_Tick)
    call ModernPlayerHUD__MHUD_Tick()
endfunction

function ModernPlayerHUD_Disable takes nothing returns nothing
    set ModernPlayerHUD__MHUD_Enabled=false
    set ModernPlayerHUD__MHUD_WasFullscreen=false
    call PauseTimer(ModernPlayerHUD__MHUD_EnableTimer)
    call PauseTimer(ModernPlayerHUD__MHUD_UpdateTimer)
    if ModernPlayerHUD__MHUD_Parent != null then
        call ModernPlayerHUD__MHUD_SetParentVisible(false)
    endif
    call ModernPlayerHUD__MHUD_ResetCache()
endfunction

function ModernPlayerHUD_IsEnabled takes nothing returns boolean
    return ModernPlayerHUD__MHUD_Enabled
endfunction

function ModernPlayerHUD__MHUD_OnUnitSelected takes nothing returns nothing
    local unit selectedUnit= GetTriggerUnit()
    local player selectingPlayer= GetTriggerPlayer()

    if selectingPlayer == GetLocalPlayer() and ModernPlayerHUD__MHUD_IsPlayerHero(selectedUnit) then
        if ModernPlayerHUD__MHUD_SelectedUnit != selectedUnit then
            set ModernPlayerHUD__MHUD_SelectedUnit=selectedUnit
            call ModernPlayerHUD__MHUD_ResetCache()
        endif
    endif

    set selectedUnit=null
    set selectingPlayer=null
endfunction

function ModernPlayerHUD__MHUD_OnUnitDeselected takes nothing returns nothing
    local unit deselectedUnit= GetTriggerUnit()
    local player deselectingPlayer= GetTriggerPlayer()

    // Keep the last player hero in the HUD while another world unit is
    // selected for targeting or inspection.

    set deselectedUnit=null
    set deselectingPlayer=null
endfunction

function ModernPlayerHUD__MHUD_WaitForGameplay takes nothing returns nothing
    if not (false) and not ModernPlayerHUD__MHUD_IsPlayerHero(ModernPlayerHUD__MHUD_SelectedUnit) and GetLocalPlayer() == Player(0) then // INLINED!!
        if ModernPlayerHUD__MHUD_IsPlayerHero(udg_Nazgrek) then
            set ModernPlayerHUD__MHUD_SelectedUnit=udg_Nazgrek
            call ModernPlayerHUD__MHUD_ResetCache()
        elseif ModernPlayerHUD__MHUD_IsPlayerHero(udg_Zulkis) then
            set ModernPlayerHUD__MHUD_SelectedUnit=udg_Zulkis
            call ModernPlayerHUD__MHUD_ResetCache()
        endif
    endif

    if not (false) and ModernPlayerHUD__MHUD_IsPlayerHero(ModernPlayerHUD__MHUD_SelectedUnit) then // INLINED!!
        call PauseTimer(ModernPlayerHUD__MHUD_EnableTimer)
        call ModernPlayerHUD_Enable()
    endif
endfunction

function ModernPlayerHUD__MHUD_DelayedInit takes nothing returns nothing
    call ModernPlayerHUD__MHUD_CreateFrames()
    if ModernPlayerHUD__MHUD_AUTO_ENABLE then
        call TimerStart(ModernPlayerHUD__MHUD_EnableTimer, ModernPlayerHUD__MHUD_UPDATE_INTERVAL, true, function ModernPlayerHUD__MHUD_WaitForGameplay)
    endif
    call DestroyTrigger(ModernPlayerHUD__MHUD_InitTrigger)
    set ModernPlayerHUD__MHUD_InitTrigger=null
endfunction

function ModernPlayerHUD__Init takes nothing returns nothing
    if ModernPlayerHUD__MHUD_Initialized then
        return
    endif
    set ModernPlayerHUD__MHUD_Initialized=true

    set ModernPlayerHUD__MHUD_BookTrigger=CreateTrigger()
    call TriggerAddAction(ModernPlayerHUD__MHUD_BookTrigger, function ModernPlayerHUD__MHUD_BookAction)
    set ModernPlayerHUD__MHUD_UtilityTrigger=CreateTrigger()
    call TriggerAddAction(ModernPlayerHUD__MHUD_UtilityTrigger, function ModernPlayerHUD__MHUD_UtilityAction)

    set ModernPlayerHUD__MHUD_ClearFocusTrigger=CreateTrigger()
    call TriggerAddAction(ModernPlayerHUD__MHUD_ClearFocusTrigger, function ModernPlayerHUD__MHUD_ClearFocusAction)

    set ModernPlayerHUD__MHUD_UpdateTrigger=CreateTrigger()

    set ModernPlayerHUD__MHUD_InitTrigger=CreateTrigger()
    call TriggerRegisterTimerEvent(ModernPlayerHUD__MHUD_InitTrigger, 0.20, false)
    call TriggerAddAction(ModernPlayerHUD__MHUD_InitTrigger, function ModernPlayerHUD__MHUD_DelayedInit)

    set ModernPlayerHUD__MHUD_EnableTimer=CreateTimer()
    set ModernPlayerHUD__MHUD_UpdateTimer=CreateTimer()

    call Events_RegisterPlayerUnitEvent(function ModernPlayerHUD__MHUD_OnUnitSelected , EVENT_PLAYER_UNIT_SELECTED)
    call Events_RegisterPlayerUnitEvent(function ModernPlayerHUD__MHUD_OnUnitDeselected , EVENT_PLAYER_UNIT_DESELECTED)
endfunction


//library ModernPlayerHUD ends
//library ModernAbilityLoadout:


function ModernAbilityLoadout__MAL_GetStorageIndex takes integer heroSlot,integer slot returns integer
    if heroSlot < ShamanCommon_HERO_SLOT_NAZGREK or heroSlot > ShamanCommon_HERO_SLOT_ZULKIS or slot < 1 or slot > ModernAbilityLoadout_SLOT_COUNT then
        return 0
    endif
    return heroSlot * ModernAbilityLoadout_SLOT_COUNT + slot
endfunction

function ModernAbilityLoadout__MAL_GetCanonicalAbilityId takes integer abilityId returns integer
    local integer entryIndex= AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return 0
    endif
    return AbilitiesPlayer_GetEntryAbilityId(entryIndex)
endfunction

function ModernAbilityLoadout__MAL_IsLearnedActiveAbility takes unit whichHero,integer abilityId returns boolean
    local integer entryIndex
    local integer canonicalAbilityId= ModernAbilityLoadout__MAL_GetCanonicalAbilityId(abilityId)

    if whichHero == null or canonicalAbilityId == 0 or not ModernAbilityCatalog_IsAssignable(canonicalAbilityId) then
        return false
    endif

    set entryIndex=AbilitiesPlayer_GetEntryByAbilityId(canonicalAbilityId)
    return AbilitiesPlayer_GetEntryKind(entryIndex) == AbilitiesPlayer_ENTRY_ABILITY and GetUnitAbilityLevel(whichHero, canonicalAbilityId) > 0
endfunction

function ModernAbilityLoadout_GetAbilityId takes unit whichHero,integer slot returns integer
    local integer storageIndex= ModernAbilityLoadout__MAL_GetStorageIndex(ShamanCommon_GetHeroSlot(whichHero) , slot)

    if storageIndex == 0 then
        return 0
    endif
    return ModernAbilityLoadout__MAL_AbilityId[storageIndex]
endfunction

function ModernAbilityLoadout__MAL_MaterializeDefaults takes unit whichHero,integer heroSlot returns nothing
    local integer entryIndex= 1
    local integer entryCount= (0) // INLINED!!
    local integer abilityId
    local integer slot= 1

    if heroSlot == ShamanCommon_HERO_SLOT_NONE or ModernAbilityLoadout__MAL_Explicit[heroSlot] or ModernAbilityLoadout__MAL_DefaultsMaterialized[heroSlot] then
        return
    endif

    loop
        exitwhen entryIndex > entryCount or slot > ModernAbilityLoadout_SLOT_COUNT
        set abilityId=AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        if ModernAbilityLoadout__MAL_IsLearnedActiveAbility(whichHero , abilityId) then
            set ModernAbilityLoadout__MAL_AbilityId[ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)]=abilityId
            set slot=slot + 1
        endif
        set entryIndex=entryIndex + 1
    endloop
    set ModernAbilityLoadout__MAL_DefaultsMaterialized[heroSlot]=true
    set ModernAbilityLoadout__MAL_Revision[heroSlot]=ModernAbilityLoadout__MAL_Revision[heroSlot] + 1
endfunction

function ModernAbilityLoadout_GetRevision takes unit whichHero returns integer
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)

    if heroSlot == ShamanCommon_HERO_SLOT_NONE then
        return 0
    endif
    return ModernAbilityLoadout__MAL_Revision[heroSlot]
endfunction

function ModernAbilityLoadout_GetEffectiveAbilityId takes unit whichHero,integer slot returns integer
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer storageIndex= ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)

    if storageIndex == 0 then
        return 0
    endif
    call ModernAbilityLoadout__MAL_MaterializeDefaults(whichHero , heroSlot)
    return ModernAbilityLoadout__MAL_AbilityId[storageIndex]
endfunction

function ModernAbilityLoadout_FindSlot takes unit whichHero,integer abilityId returns integer
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer canonicalAbilityId= ModernAbilityLoadout__MAL_GetCanonicalAbilityId(abilityId)
    local integer slot= 1
    local integer storageIndex

    if canonicalAbilityId == 0 then
        return 0
    endif

    loop
        exitwhen slot > ModernAbilityLoadout_SLOT_COUNT
        set storageIndex=ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)
        if storageIndex != 0 and ModernAbilityLoadout_GetEffectiveAbilityId(whichHero , slot) == canonicalAbilityId then
            return slot
        endif
        set slot=slot + 1
    endloop

    return 0
endfunction

function ModernAbilityLoadout_Assign takes unit whichHero,integer slot,integer abilityId returns boolean
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer storageIndex= ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)
    local integer canonicalAbilityId= ModernAbilityLoadout__MAL_GetCanonicalAbilityId(abilityId)
    local integer previousSlot

    if storageIndex == 0 or not ModernAbilityLoadout__MAL_IsLearnedActiveAbility(whichHero , canonicalAbilityId) then
        return false
    endif

    call ModernAbilityLoadout__MAL_MaterializeDefaults(whichHero , heroSlot)
    set previousSlot=ModernAbilityLoadout_FindSlot(whichHero , canonicalAbilityId)
    if previousSlot != 0 and previousSlot != slot then
        set ModernAbilityLoadout__MAL_AbilityId[ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , previousSlot)]=0
    endif

    set ModernAbilityLoadout__MAL_AbilityId[storageIndex]=canonicalAbilityId
    set ModernAbilityLoadout__MAL_Explicit[heroSlot]=true
    set ModernAbilityLoadout__MAL_Revision[heroSlot]=ModernAbilityLoadout__MAL_Revision[heroSlot] + 1
    return true
endfunction

function ModernAbilityLoadout_Clear takes unit whichHero,integer slot returns boolean
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer storageIndex= ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)

    if storageIndex == 0 then
        return false
    endif

    call ModernAbilityLoadout__MAL_MaterializeDefaults(whichHero , heroSlot)
    set ModernAbilityLoadout__MAL_AbilityId[storageIndex]=0
    set ModernAbilityLoadout__MAL_Explicit[heroSlot]=true
    set ModernAbilityLoadout__MAL_Revision[heroSlot]=ModernAbilityLoadout__MAL_Revision[heroSlot] + 1
    return true
endfunction

function ModernAbilityLoadout_Swap takes unit whichHero,integer firstSlot,integer secondSlot returns boolean
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer firstIndex= ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , firstSlot)
    local integer secondIndex= ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , secondSlot)
    local integer firstAbilityId

    if firstIndex == 0 or secondIndex == 0 or firstSlot == secondSlot then
        return false
    endif

    call ModernAbilityLoadout__MAL_MaterializeDefaults(whichHero , heroSlot)
    set firstAbilityId=ModernAbilityLoadout__MAL_AbilityId[firstIndex]
    set ModernAbilityLoadout__MAL_AbilityId[firstIndex]=ModernAbilityLoadout__MAL_AbilityId[secondIndex]
    set ModernAbilityLoadout__MAL_AbilityId[secondIndex]=firstAbilityId
    set ModernAbilityLoadout__MAL_Explicit[heroSlot]=true
    set ModernAbilityLoadout__MAL_Revision[heroSlot]=ModernAbilityLoadout__MAL_Revision[heroSlot] + 1
    return true
endfunction

function ModernAbilityLoadout_AppendNewLearned takes unit whichHero returns boolean
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer entryIndex= 1
    local integer entryCount= (0) // INLINED!!
    local integer abilityId
    local integer slot
    local boolean changed= false

    if heroSlot == ShamanCommon_HERO_SLOT_NONE then
        return false
    endif

    call ModernAbilityLoadout__MAL_MaterializeDefaults(whichHero , heroSlot)
    loop
        exitwhen entryIndex > entryCount
        set abilityId=AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        if ModernAbilityLoadout__MAL_IsLearnedActiveAbility(whichHero , abilityId) and ModernAbilityLoadout_FindSlot(whichHero , abilityId) == 0 then
            set slot=1
            loop
                exitwhen slot > ModernAbilityLoadout_SLOT_COUNT or ModernAbilityLoadout__MAL_AbilityId[ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)] == 0
                set slot=slot + 1
            endloop
            if slot <= ModernAbilityLoadout_SLOT_COUNT then
                set ModernAbilityLoadout__MAL_AbilityId[ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)]=abilityId
                set changed=true
            endif
        endif
        set entryIndex=entryIndex + 1
    endloop

    if changed then
        set ModernAbilityLoadout__MAL_Explicit[heroSlot]=true
        set ModernAbilityLoadout__MAL_Revision[heroSlot]=ModernAbilityLoadout__MAL_Revision[heroSlot] + 1
    endif
    return changed
endfunction

function ModernAbilityLoadout_Reset takes unit whichHero returns nothing
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer slot= 1
    local integer storageIndex

    loop
        exitwhen slot > ModernAbilityLoadout_SLOT_COUNT
        set storageIndex=ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)
        if storageIndex != 0 then
            set ModernAbilityLoadout__MAL_AbilityId[storageIndex]=0
        endif
        set slot=slot + 1
    endloop
    if heroSlot != ShamanCommon_HERO_SLOT_NONE then
        set ModernAbilityLoadout__MAL_Explicit[heroSlot]=false
        set ModernAbilityLoadout__MAL_DefaultsMaterialized[heroSlot]=false
        set ModernAbilityLoadout__MAL_Revision[heroSlot]=ModernAbilityLoadout__MAL_Revision[heroSlot] + 1
    endif
endfunction

function ModernAbilityLoadout_RefreshDefaults takes unit whichHero returns nothing
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)
    local integer slot= 1

    if heroSlot == ShamanCommon_HERO_SLOT_NONE or ModernAbilityLoadout__MAL_Explicit[heroSlot] then
        return
    endif

    loop
        exitwhen slot > ModernAbilityLoadout_SLOT_COUNT
        set ModernAbilityLoadout__MAL_AbilityId[ModernAbilityLoadout__MAL_GetStorageIndex(heroSlot , slot)]=0
        set slot=slot + 1
    endloop
    set ModernAbilityLoadout__MAL_DefaultsMaterialized[heroSlot]=false
    call ModernAbilityLoadout__MAL_MaterializeDefaults(whichHero , heroSlot)
endfunction

function ModernAbilityLoadout_FillFirstLearned takes unit whichHero returns nothing
    local integer heroSlot= ShamanCommon_GetHeroSlot(whichHero)

    if heroSlot == ShamanCommon_HERO_SLOT_NONE then
        return
    endif

    call ModernAbilityLoadout_Reset(whichHero)
    call ModernAbilityLoadout__MAL_MaterializeDefaults(whichHero , heroSlot)
endfunction


//library ModernAbilityLoadout ends
//library ModernAbilityTargeting:


function ModernAbilityTargeting__MAT_DistanceSquared takes real ax,real ay,real bx,real by returns real
    local real dx= ax - bx
    local real dy= ay - by

    return dx * dx + dy * dy
endfunction

function ModernAbilityTargeting__MAT_IsGeneralCandidate takes unit candidate returns boolean
    return candidate != null and ShamanCommon_IsAlive(candidate) and not IsUnitHidden(candidate) and not IsUnitType(candidate, UNIT_TYPE_STRUCTURE) and GetUnitAbilityLevel(candidate, 'Aloc') == 0
endfunction

function ModernAbilityTargeting__MAT_IsBetterCandidate takes unit candidate,unit current,real pointX,real pointY,boolean preferWounded returns boolean
    local real candidateDistance
    local real currentDistance
    local real candidateLife= 1.00
    local real currentLife= 1.00
    local integer candidateIndex
    local integer currentIndex

    if current == null then
        return true
    endif

    set candidateDistance=ModernAbilityTargeting__MAT_DistanceSquared(GetUnitX(candidate) , GetUnitY(candidate) , pointX , pointY)
    set currentDistance=ModernAbilityTargeting__MAT_DistanceSquared(GetUnitX(current) , GetUnitY(current) , pointX , pointY)
    if candidateDistance + ModernAbilityTargeting__MAT_DISTANCE_EPSILON < currentDistance then
        return true
    elseif currentDistance + ModernAbilityTargeting__MAT_DISTANCE_EPSILON < candidateDistance then
        return false
    endif

    if preferWounded then
        if BlzGetUnitMaxHP(candidate) > 0 then
            set candidateLife=GetWidgetLife(candidate) / I2R(BlzGetUnitMaxHP(candidate))
        endif
        if BlzGetUnitMaxHP(current) > 0 then
            set currentLife=GetWidgetLife(current) / I2R(BlzGetUnitMaxHP(current))
        endif
        if candidateLife + ModernAbilityTargeting__MAT_DISTANCE_EPSILON < currentLife then
            return true
        elseif currentLife + ModernAbilityTargeting__MAT_DISTANCE_EPSILON < candidateLife then
            return false
        endif
    endif

    set candidateIndex=GetUnitUserData(candidate)
    set currentIndex=GetUnitUserData(current)
    return candidateIndex > 0 and ( currentIndex <= 0 or candidateIndex < currentIndex )
endfunction

function ModernAbilityTargeting__MAT_FindUnit takes unit caster,real pointX,real pointY,real radius,boolean friendly returns unit
    local player owner
    local unit candidate
    local unit best= null

    if caster == null or radius <= 0.00 then
        return null
    endif

    set owner=GetOwningPlayer(caster)
    call GroupEnumUnitsInRange(ModernAbilityTargeting__MAT_SearchGroup, pointX, pointY, radius, null)
    loop
        set candidate=FirstOfGroup(ModernAbilityTargeting__MAT_SearchGroup)
        exitwhen candidate == null
        call GroupRemoveUnit(ModernAbilityTargeting__MAT_SearchGroup, candidate)

        if ModernAbilityTargeting__MAT_IsGeneralCandidate(candidate) then
            if friendly and IsUnitAlly(candidate, owner) and ModernAbilityTargeting__MAT_IsBetterCandidate(candidate , best , pointX , pointY , true) then
                set best=candidate
            elseif not friendly and IsUnitEnemy(candidate, owner) and ModernAbilityTargeting__MAT_IsBetterCandidate(candidate , best , pointX , pointY , false) then
                set best=candidate
            endif
        endif
    endloop

    set owner=null
    set candidate=null
    return best
endfunction

function ModernAbilityTargeting_ResolveUnit takes unit caster,integer abilityId,real pointX,real pointY returns unit
    local integer targetPolicy= ModernAbilityCatalog_GetTargetPolicy(abilityId)
    local real radius= ModernAbilityCatalog_GetAcquireRadius(abilityId)
    local unit result= null

    if caster == null then
        return null
    endif

    if targetPolicy == ModernAbilityCatalog_TARGET_SOFT_FRIENDLY then
        if ModernAbilityCatalog_AllowsSelfFallback(abilityId) and ModernAbilityTargeting__MAT_DistanceSquared(GetUnitX(caster) , GetUnitY(caster) , pointX , pointY) <= ModernAbilityTargeting__MAT_SELF_CLICK_RADIUS * ModernAbilityTargeting__MAT_SELF_CLICK_RADIUS then
            return caster
        endif
        set result=ModernAbilityTargeting__MAT_FindUnit(caster , pointX , pointY , radius , true)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_SOFT_HOSTILE then
        set result=ModernAbilityTargeting__MAT_FindUnit(caster , pointX , pointY , radius , false)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_MELEE_AUTO then
        set result=ModernAbilityTargeting__MAT_FindUnit(caster , GetUnitX(caster) , GetUnitY(caster) , radius , false)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_SELF then
        set result=caster
    endif

    return result
endfunction

function ModernAbilityTargeting_ResolveMeleeUnit takes unit caster,integer abilityId returns unit
    if caster == null then
        return null
    endif
    return ModernAbilityTargeting_ResolveUnit(caster , abilityId , GetUnitX(caster) , GetUnitY(caster))
endfunction

function ModernAbilityTargeting_UsesPrecisePoint takes integer abilityId returns boolean
    return ModernAbilityCatalog_GetTargetPolicy(abilityId) == ModernAbilityCatalog_TARGET_PRECISE_POINT
endfunction


//library ModernAbilityTargeting ends
//library ModernMinimapHUD:


function ModernMinimapHUD__MMH_IsValidHero takes unit whichHero returns boolean
    return whichHero != null and GetHandleId(whichHero) != 0 and GetUnitTypeId(whichHero) != 0
endfunction

function ModernMinimapHUD__MMH_GetHero takes integer index returns unit
    if index == 0 then
        return udg_Nazgrek
    endif
    return udg_Zulkis
endfunction

function ModernMinimapHUD__MMH_SetVisible takes boolean visible returns nothing
    local integer index= 0

    if ModernMinimapHUD__MMH_Visible != visible then
        set ModernMinimapHUD__MMH_Visible=visible
        call BlzFrameSetVisible(ModernMinimapHUD__MMH_Root, visible)
        call BlzFrameSetVisible(ModernMinimapHUD__MMH_Minimap, visible)
        loop
            exitwhen index >= ModernMinimapHUD__MMH_CONTROL_COUNT
            if ModernMinimapHUD__MMH_ControlButton[index] != null then
                call BlzFrameSetVisible(ModernMinimapHUD__MMH_ControlButton[index], visible)
            endif
            set index=index + 1
        endloop
    endif
endfunction

function ModernMinimapHUD__MMH_SetShellVisible takes boolean visible returns nothing
    local integer index= 0

    call BlzFrameSetVisible(ModernMinimapHUD__MMH_Panel, visible)
    call BlzFrameSetVisible(ModernMinimapHUD__MMH_Title, visible)
    loop
        exitwhen index >= 2
        call BlzFrameSetVisible(ModernMinimapHUD__MMH_HeroButton[index], visible and ModernMinimapHUD__MMH_CachedHeroType[index] != 0)
        set index=index + 1
    endloop
    set index=0
    loop
        exitwhen index >= ModernMinimapHUD__MMH_CONTROL_COUNT
        if ModernMinimapHUD__MMH_ControlButton[index] != null then
            call BlzFrameSetVisible(ModernMinimapHUD__MMH_ControlButton[index], visible)
        endif
        set index=index + 1
    endloop
endfunction

function ModernMinimapHUD__MMH_ApplyCompactLayout takes nothing returns nothing
    call BlzFrameClearAllPoints(ModernMinimapHUD__MMH_Minimap)
    call BlzFrameSetAbsPoint(ModernMinimapHUD__MMH_Minimap, FRAMEPOINT_TOPLEFT, ModernMinimapHUD__MMH_MINIMAP_LEFT, ModernMinimapHUD__MMH_MINIMAP_TOP)
    call BlzFrameSetSize(ModernMinimapHUD__MMH_Minimap, ModernMinimapHUD__MMH_MINIMAP_SIZE, ModernMinimapHUD__MMH_MINIMAP_SIZE)
    call BlzFrameSetScale(ModernMinimapHUD__MMH_Minimap, 1.00)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_Minimap, 3)
endfunction

function ModernMinimapHUD__MMH_UpdateHero takes integer index returns nothing
    local unit whichHero= ModernMinimapHUD__MMH_GetHero(index)
    local integer unitTypeId= 0
    local string iconPath

    if ModernMinimapHUD__MMH_IsValidHero(whichHero) then
        set unitTypeId=GetUnitTypeId(whichHero)
    endif
    if ModernMinimapHUD__MMH_CachedHero[index] != whichHero or ModernMinimapHUD__MMH_CachedHeroType[index] != unitTypeId then
        set ModernMinimapHUD__MMH_CachedHero[index]=whichHero
        set ModernMinimapHUD__MMH_CachedHeroType[index]=unitTypeId
        if unitTypeId != 0 then
            set iconPath=BlzGetAbilityIcon(unitTypeId)
            if iconPath == null or iconPath == "" then
                set iconPath=ModernMinimapHUD__MMH_EMPTY_ICON
            endif
            call BlzFrameSetTexture(ModernMinimapHUD__MMH_HeroIcon[index], iconPath, 0, true)
        endif
        call BlzFrameSetVisible(ModernMinimapHUD__MMH_HeroButton[index], unitTypeId != 0)
    endif

    set whichHero=null
endfunction

function ModernMinimapHUD__MMH_Update takes nothing returns nothing
    local boolean visible
    local boolean enlarged= false

    if not ModernMinimapHUD__MMH_FramesCreated then
        return
    endif
    set visible=ModernMinimapHUD__MMH_Enabled and (ModernPlayerHUD__MHUD_Enabled) and not (false) // INLINED!!
    call ModernMinimapHUD__MMH_SetVisible(visible)
    if visible then

            set enlarged=(false) // INLINED!!

        if enlarged then
            if not ModernMinimapHUD__MMH_WasEnlarged then
                set ModernMinimapHUD__MMH_WasEnlarged=true
                call ModernMinimapHUD__MMH_SetShellVisible(false)
            endif
        else
            if ModernMinimapHUD__MMH_WasEnlarged then
                set ModernMinimapHUD__MMH_WasEnlarged=false
                call ModernMinimapHUD__MMH_ApplyCompactLayout()
                call ModernMinimapHUD__MMH_SetShellVisible(true)
            endif
            call ModernMinimapHUD__MMH_UpdateHero(0)
            call ModernMinimapHUD__MMH_UpdateHero(1)
        endif
    endif
endfunction

function ModernMinimapHUD__MMH_ClearFocusAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()

    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
    endif
    set triggerFrame=null
endfunction

function ModernMinimapHUD__MMH_HeroAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()
    local player triggerPlayer= GetTriggerPlayer()
    local unit whichHero= null

    if triggerPlayer == GetLocalPlayer() then
        if triggerFrame == ModernMinimapHUD__MMH_HeroButton[0] then
            set whichHero=ModernMinimapHUD__MMH_GetHero(0)
        elseif triggerFrame == ModernMinimapHUD__MMH_HeroButton[1] then
            set whichHero=ModernMinimapHUD__MMH_GetHero(1)
        endif
        if ModernMinimapHUD__MMH_IsValidHero(whichHero) and GetOwningPlayer(whichHero) == triggerPlayer then
            call SelectUnitForPlayerSingle(whichHero, triggerPlayer)
        endif
    endif

    set whichHero=null
    set triggerPlayer=null
    set triggerFrame=null
endfunction

function ModernMinimapHUD__MMH_CreateHeroButton takes integer index,real x,string label returns nothing
    set ModernMinimapHUD__MMH_HeroButton[index]=BlzCreateFrameByType("BUTTON", "ModernMinimapHeroButton" + I2S(index), ModernMinimapHUD__MMH_Root, "", 0)
    call BlzFrameSetAbsPoint(ModernMinimapHUD__MMH_HeroButton[index], FRAMEPOINT_BOTTOMLEFT, x, ModernMinimapHUD__MMH_HERO_BOTTOM)
    call BlzFrameSetSize(ModernMinimapHUD__MMH_HeroButton[index], ModernMinimapHUD__MMH_HERO_SIZE, ModernMinimapHUD__MMH_HERO_SIZE)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_HeroButton[index], 6)

    set ModernMinimapHUD__MMH_HeroBorder[index]=BlzCreateFrameByType("BACKDROP", "ModernMinimapHeroBorder" + I2S(index), ModernMinimapHUD__MMH_HeroButton[index], "", 0)
    call BlzFrameSetAllPoints(ModernMinimapHUD__MMH_HeroBorder[index], ModernMinimapHUD__MMH_HeroButton[index])
    call BlzFrameSetTexture(ModernMinimapHUD__MMH_HeroBorder[index], ModernMinimapHUD__MMH_SLOT_TEXTURE, 0, true)
    call BlzFrameSetEnable(ModernMinimapHUD__MMH_HeroBorder[index], false)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_HeroBorder[index], 7)

    set ModernMinimapHUD__MMH_HeroIcon[index]=BlzCreateFrameByType("BACKDROP", "ModernMinimapHeroIcon" + I2S(index), ModernMinimapHUD__MMH_HeroButton[index], "IconButtonTemplate", 0)
    call BlzFrameSetPoint(ModernMinimapHUD__MMH_HeroIcon[index], FRAMEPOINT_BOTTOMLEFT, ModernMinimapHUD__MMH_HeroButton[index], FRAMEPOINT_BOTTOMLEFT, 0.004, 0.004)
    call BlzFrameSetPoint(ModernMinimapHUD__MMH_HeroIcon[index], FRAMEPOINT_TOPRIGHT, ModernMinimapHUD__MMH_HeroButton[index], FRAMEPOINT_TOPRIGHT, - 0.004, - 0.004)
    call BlzFrameSetEnable(ModernMinimapHUD__MMH_HeroIcon[index], false)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_HeroIcon[index], 8)

    set ModernMinimapHUD__MMH_HeroLabel[index]=BlzCreateFrameByType("TEXT", "ModernMinimapHeroLabel" + I2S(index), ModernMinimapHUD__MMH_HeroButton[index], "", 0)
    call BlzFrameSetPoint(ModernMinimapHUD__MMH_HeroLabel[index], FRAMEPOINT_BOTTOMRIGHT, ModernMinimapHUD__MMH_HeroButton[index], FRAMEPOINT_BOTTOMRIGHT, - 0.002, 0.001)
    call BlzFrameSetSize(ModernMinimapHUD__MMH_HeroLabel[index], 0.010, 0.009)
    call BlzFrameSetTextAlignment(ModernMinimapHUD__MMH_HeroLabel[index], TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_RIGHT)
    call BlzFrameSetScale(ModernMinimapHUD__MMH_HeroLabel[index], 0.52)
    call BlzFrameSetText(ModernMinimapHUD__MMH_HeroLabel[index], label)
    call BlzFrameSetEnable(ModernMinimapHUD__MMH_HeroLabel[index], false)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_HeroLabel[index], 9)

    call BlzTriggerRegisterFrameEvent(ModernMinimapHUD__MMH_HeroTrigger, ModernMinimapHUD__MMH_HeroButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(ModernMinimapHUD__MMH_ClearFocusTrigger, ModernMinimapHUD__MMH_HeroButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzFrameSetVisible(ModernMinimapHUD__MMH_HeroButton[index], false)
endfunction

function ModernMinimapHUD__MMH_CreateFrames takes nothing returns nothing
    local framehandle gameUI
    local integer index= 0

    if ModernMinimapHUD__MMH_FramesCreated then
        return
    endif
    set ModernMinimapHUD__MMH_FramesCreated=true
    set gameUI=BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    set ModernMinimapHUD__MMH_Root=BlzCreateFrameByType("FRAME", "ModernMinimapHUDRoot", gameUI, "", 0)
    call BlzFrameSetSize(ModernMinimapHUD__MMH_Root, 0.0001, 0.0001)
    call BlzFrameSetAbsPoint(ModernMinimapHUD__MMH_Root, FRAMEPOINT_BOTTOMLEFT, 0.000, 0.000)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_Root, 14)

    set ModernMinimapHUD__MMH_Panel=BlzCreateFrameByType("BACKDROP", "ModernMinimapHUDPanel", ModernMinimapHUD__MMH_Root, "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(ModernMinimapHUD__MMH_Panel, FRAMEPOINT_TOPLEFT, ModernMinimapHUD__MMH_PANEL_LEFT, ModernMinimapHUD__MMH_PANEL_TOP)
    call BlzFrameSetAbsPoint(ModernMinimapHUD__MMH_Panel, FRAMEPOINT_BOTTOMRIGHT, ModernMinimapHUD__MMH_PANEL_RIGHT, ModernMinimapHUD__MMH_PANEL_BOTTOM)
    call BlzFrameSetEnable(ModernMinimapHUD__MMH_Panel, false)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_Panel, 1)

    set ModernMinimapHUD__MMH_Title=BlzCreateFrameByType("TEXT", "ModernMinimapHUDTitle", ModernMinimapHUD__MMH_Root, "", 0)
    call BlzFrameSetAbsPoint(ModernMinimapHUD__MMH_Title, FRAMEPOINT_BOTTOM, 0.070, 0.432)
    call BlzFrameSetSize(ModernMinimapHUD__MMH_Title, 0.090, 0.010)
    call BlzFrameSetTextAlignment(ModernMinimapHUD__MMH_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernMinimapHUD__MMH_Title, 0.55)
    call BlzFrameSetText(ModernMinimapHUD__MMH_Title, "|cffffe4a3HEROES|r")
    call BlzFrameSetEnable(ModernMinimapHUD__MMH_Title, false)
    call BlzFrameSetLevel(ModernMinimapHUD__MMH_Title, 5)

    set ModernMinimapHUD__MMH_Minimap=BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
    call BlzFrameSetParent(ModernMinimapHUD__MMH_Minimap, ModernMinimapHUD__MMH_Root)
    call ModernMinimapHUD__MMH_ApplyCompactLayout()

    loop
        exitwhen index >= ModernMinimapHUD__MMH_CONTROL_COUNT
        set ModernMinimapHUD__MMH_ControlButton[index]=BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP_BUTTON, index)
        if ModernMinimapHUD__MMH_ControlButton[index] != null then
            call BlzFrameSetParent(ModernMinimapHUD__MMH_ControlButton[index], ModernMinimapHUD__MMH_Root)
            call BlzFrameClearAllPoints(ModernMinimapHUD__MMH_ControlButton[index])
            call BlzFrameSetAbsPoint(ModernMinimapHUD__MMH_ControlButton[index], FRAMEPOINT_BOTTOMLEFT, 0.014 + I2R(index) * 0.023, ModernMinimapHUD__MMH_CONTROL_BOTTOM)
            call BlzFrameSetSize(ModernMinimapHUD__MMH_ControlButton[index], ModernMinimapHUD__MMH_CONTROL_SIZE, ModernMinimapHUD__MMH_CONTROL_SIZE)
            call BlzFrameSetLevel(ModernMinimapHUD__MMH_ControlButton[index], 6)
        endif
        set index=index + 1
    endloop

    call ModernMinimapHUD__MMH_CreateHeroButton(0 , 0.030 , "N")
    call ModernMinimapHUD__MMH_CreateHeroButton(1 , 0.076 , "Z")
    call BlzFrameSetVisible(ModernMinimapHUD__MMH_Root, false)
    call BlzFrameSetVisible(ModernMinimapHUD__MMH_Minimap, false)
    set gameUI=null
endfunction

function ModernMinimapHUD_Refresh takes nothing returns nothing
    call ModernMinimapHUD__MMH_Update()
endfunction

function ModernMinimapHUD_Enable takes nothing returns nothing
    set ModernMinimapHUD__MMH_Enabled=true
    call ModernMinimapHUD__MMH_Update()
endfunction

function ModernMinimapHUD_Disable takes nothing returns nothing
    set ModernMinimapHUD__MMH_Enabled=false
    call ModernMinimapHUD__MMH_SetVisible(false)
endfunction

function ModernMinimapHUD_IsEnabled takes nothing returns boolean
    return ModernMinimapHUD__MMH_Enabled
endfunction

function ModernMinimapHUD__MMH_DelayedInit takes nothing returns nothing
    call ModernMinimapHUD__MMH_CreateFrames()
    call ModernMinimapHUD__MMH_Update()
    call DestroyTrigger(ModernMinimapHUD__MMH_InitTrigger)
    set ModernMinimapHUD__MMH_InitTrigger=null
endfunction

function ModernMinimapHUD__Init takes nothing returns nothing
    set ModernMinimapHUD__MMH_HeroTrigger=CreateTrigger()
    call TriggerAddAction(ModernMinimapHUD__MMH_HeroTrigger, function ModernMinimapHUD__MMH_HeroAction)
    set ModernMinimapHUD__MMH_ClearFocusTrigger=CreateTrigger()
    call TriggerAddAction(ModernMinimapHUD__MMH_ClearFocusTrigger, function ModernMinimapHUD__MMH_ClearFocusAction)
    set ModernMinimapHUD__MMH_InitTrigger=CreateTrigger()
    call TriggerRegisterTimerEvent(ModernMinimapHUD__MMH_InitTrigger, 0.30, false)
    call TriggerAddAction(ModernMinimapHUD__MMH_InitTrigger, function ModernMinimapHUD__MMH_DelayedInit)
    call TriggerAddAction(ModernPlayerHUD__MHUD_UpdateTrigger, (function ModernMinimapHUD__MMH_Update)) // INLINED!!
endfunction


//library ModernMinimapHUD ends
//library ModernTotemTracker:


function ModernTotemTracker___MTT_GetSlot takes integer index returns integer
    if index == 0 then
        return Totems_SLOT_EARTH
    elseif index == 1 then
        return Totems_SLOT_FIRE
    elseif index == 2 then
        return Totems_SLOT_WATER
    endif
    return Totems_SLOT_WIND
endfunction

function ModernTotemTracker___MTT_GetTexture takes integer index returns string
    if index == 0 then
        return ModernTotemTracker___MTT_EARTH_TEXTURE
    elseif index == 1 then
        return ModernTotemTracker___MTT_FIRE_TEXTURE
    elseif index == 2 then
        return ModernTotemTracker___MTT_WATER_TEXTURE
    endif
    return ModernTotemTracker___MTT_AIR_TEXTURE
endfunction

function ModernTotemTracker___MTT_GetLabel takes integer index returns string
    if index == 0 then
        return "E"
    elseif index == 1 then
        return "F"
    elseif index == 2 then
        return "W"
    endif
    return "A"
endfunction

function ModernTotemTracker___MTT_GetColor takes integer index returns integer
    if index == 0 then
        return BlzConvertColor(255, 218, 151, 54)
    elseif index == 1 then
        return BlzConvertColor(255, 255, 82, 25)
    elseif index == 2 then
        return BlzConvertColor(255, 42, 151, 255)
    endif
    return BlzConvertColor(255, 180, 235, 255)
endfunction

function ModernTotemTracker___MTT_IsPlayerHero takes unit whichUnit returns boolean
    return whichUnit != null and GetOwningPlayer(whichUnit) == Player(0) and ShamanCommon_IsPlayerHero(whichUnit)
endfunction

function ModernTotemTracker___MTT_SetParentVisible takes boolean visible returns nothing
    if ModernTotemTracker___MTT_ParentVisible != visible then
        set ModernTotemTracker___MTT_ParentVisible=visible
        call BlzFrameSetVisible(ModernTotemTracker___MTT_Parent, visible)
    endif
endfunction

function ModernTotemTracker___MTT_ResetCache takes nothing returns nothing
    local integer index= 0
    set ModernTotemTracker___MTT_CachedUnit=null
    loop
        exitwhen index >= ModernTotemTracker___MTT_ELEMENT_COUNT
        set ModernTotemTracker___MTT_CachedActive[index]=- 1
        set ModernTotemTracker___MTT_CachedSecond[index]=- 1
        set ModernTotemTracker___MTT_CachedProgress[index]=- 1
        set index=index + 1
    endloop
endfunction

function ModernTotemTracker___MTT_UpdateElement takes integer index,unit whichHero returns nothing
    local unit totem= Totems_GetLiveTotemForSlot(whichHero , ModernTotemTracker___MTT_GetSlot(index))
    local integer active= 0
    local integer second
    local integer progress= 0
    local real remaining
    local real total

    if totem != null then
        set active=1
    endif

    if ModernTotemTracker___MTT_CachedActive[index] != active then
        set ModernTotemTracker___MTT_CachedActive[index]=active
        if active == 1 then
            call BlzFrameSetSize(ModernTotemTracker___MTT_Icon[index], ModernTotemTracker___MTT_ACTIVE_SIZE, ModernTotemTracker___MTT_ACTIVE_SIZE)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_InactiveShade[index], false)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_ElementLabel[index], false)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_ProgressBack[index], true)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_TimerText[index], true)
        else
            call BlzFrameSetSize(ModernTotemTracker___MTT_Icon[index], ModernTotemTracker___MTT_INACTIVE_SIZE, ModernTotemTracker___MTT_INACTIVE_SIZE)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_InactiveShade[index], true)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_ElementLabel[index], true)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_ProgressBack[index], false)
            call BlzFrameSetVisible(ModernTotemTracker___MTT_TimerText[index], false)
            set ModernTotemTracker___MTT_CachedSecond[index]=- 1
            set ModernTotemTracker___MTT_CachedProgress[index]=- 1
        endif
    endif

    if active == 1 then
        set remaining=Totems_GetRemainingDuration(totem)
        set total=Totems_GetTotalDuration(totem)
        set second=R2I(remaining + 0.99)
        if total > 0.00 then
            set progress=R2I(remaining / total * I2R(ModernTotemTracker___MTT_PROGRESS_STEPS))
        endif
        if progress < 0 then
            set progress=0
        elseif progress > ModernTotemTracker___MTT_PROGRESS_STEPS then
            set progress=ModernTotemTracker___MTT_PROGRESS_STEPS
        endif
        if ModernTotemTracker___MTT_CachedSecond[index] != second then
            set ModernTotemTracker___MTT_CachedSecond[index]=second
            call BlzFrameSetText(ModernTotemTracker___MTT_TimerText[index], I2S(second))
        endif
        if ModernTotemTracker___MTT_CachedProgress[index] != progress then
            set ModernTotemTracker___MTT_CachedProgress[index]=progress
            if progress <= 0 then
                call BlzFrameSetSize(ModernTotemTracker___MTT_ProgressFill[index], 0.0001, ModernTotemTracker___MTT_PROGRESS_HEIGHT)
            else
                call BlzFrameSetSize(ModernTotemTracker___MTT_ProgressFill[index], ModernTotemTracker___MTT_PROGRESS_WIDTH * I2R(progress) / I2R(ModernTotemTracker___MTT_PROGRESS_STEPS), ModernTotemTracker___MTT_PROGRESS_HEIGHT)
            endif
        endif
    endif

    set totem=null
    set whichHero=null
endfunction

function ModernTotemTracker___MTT_Update takes nothing returns nothing
    local unit whichHero
    local integer index= 0

    if not ModernTotemTracker___MTT_FramesCreated or not (ModernPlayerHUD__MHUD_Enabled) or (false) then // INLINED!!
        if ModernTotemTracker___MTT_FramesCreated then
            call ModernTotemTracker___MTT_SetParentVisible(false)
        endif
        return
    endif

    set whichHero=(ModernPlayerHUD__MHUD_SelectedUnit) // INLINED!!
    if not ModernTotemTracker___MTT_IsPlayerHero(whichHero) then
        call ModernTotemTracker___MTT_SetParentVisible(false)
        set whichHero=null
        return
    endif

    if ModernTotemTracker___MTT_CachedUnit != whichHero then
        call ModernTotemTracker___MTT_ResetCache()
        set ModernTotemTracker___MTT_CachedUnit=whichHero
    endif

    call ModernTotemTracker___MTT_SetParentVisible(true)
    loop
        exitwhen index >= ModernTotemTracker___MTT_ELEMENT_COUNT
        call ModernTotemTracker___MTT_UpdateElement(index , whichHero)
        set index=index + 1
    endloop
    set whichHero=null
endfunction

function ModernTotemTracker___MTT_CreateElement takes integer index returns nothing
    local real x= ModernTotemTracker___MTT_START_X + I2R(index) * ( ModernTotemTracker___MTT_SLOT_SIZE + ModernTotemTracker___MTT_SLOT_GAP )

    set ModernTotemTracker___MTT_Slot[index]=BlzCreateFrameByType("FRAME", "ModernTotemTrackerSlot" + I2S(index), ModernTotemTracker___MTT_Parent, "", 0)
    call BlzFrameSetAbsPoint(ModernTotemTracker___MTT_Slot[index], FRAMEPOINT_BOTTOMLEFT, x, ModernTotemTracker___MTT_BOTTOM)
    call BlzFrameSetSize(ModernTotemTracker___MTT_Slot[index], ModernTotemTracker___MTT_SLOT_SIZE, ModernTotemTracker___MTT_SLOT_SIZE)
    call BlzFrameSetEnable(ModernTotemTracker___MTT_Slot[index], false)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_Slot[index], 32)

    set ModernTotemTracker___MTT_Icon[index]=BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerIcon" + I2S(index), ModernTotemTracker___MTT_Slot[index], "", 0)
    call BlzFrameSetPoint(ModernTotemTracker___MTT_Icon[index], FRAMEPOINT_CENTER, ModernTotemTracker___MTT_Slot[index], FRAMEPOINT_CENTER, 0.000, 0.000)
    call BlzFrameSetSize(ModernTotemTracker___MTT_Icon[index], ModernTotemTracker___MTT_INACTIVE_SIZE, ModernTotemTracker___MTT_INACTIVE_SIZE)
    call BlzFrameSetTexture(ModernTotemTracker___MTT_Icon[index], ModernTotemTracker___MTT_GetTexture(index), 0, true)
    call BlzFrameSetEnable(ModernTotemTracker___MTT_Icon[index], false)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_Icon[index], 33)

    set ModernTotemTracker___MTT_InactiveShade[index]=BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerShade" + I2S(index), ModernTotemTracker___MTT_Icon[index], "", 0)
    call BlzFrameSetAllPoints(ModernTotemTracker___MTT_InactiveShade[index], ModernTotemTracker___MTT_Icon[index])
    call BlzFrameSetTexture(ModernTotemTracker___MTT_InactiveShade[index], ModernTotemTracker___MTT_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetVertexColor(ModernTotemTracker___MTT_InactiveShade[index], BlzConvertColor(72, 0, 0, 0))
    call BlzFrameSetEnable(ModernTotemTracker___MTT_InactiveShade[index], false)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_InactiveShade[index], 34)

    set ModernTotemTracker___MTT_ElementLabel[index]=BlzCreateFrameByType("TEXT", "ModernTotemTrackerLabel" + I2S(index), ModernTotemTracker___MTT_Slot[index], "", 0)
    call BlzFrameSetAllPoints(ModernTotemTracker___MTT_ElementLabel[index], ModernTotemTracker___MTT_Slot[index])
    call BlzFrameSetTextAlignment(ModernTotemTracker___MTT_ElementLabel[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernTotemTracker___MTT_ElementLabel[index], 0.58)
    call BlzFrameSetText(ModernTotemTracker___MTT_ElementLabel[index], "|cffffe4a3" + ModernTotemTracker___MTT_GetLabel(index) + "|r")
    call BlzFrameSetEnable(ModernTotemTracker___MTT_ElementLabel[index], false)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_ElementLabel[index], 35)

    set ModernTotemTracker___MTT_ProgressBack[index]=BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerProgressBack" + I2S(index), ModernTotemTracker___MTT_Slot[index], "", 0)
    call BlzFrameSetPoint(ModernTotemTracker___MTT_ProgressBack[index], FRAMEPOINT_BOTTOM, ModernTotemTracker___MTT_Slot[index], FRAMEPOINT_BOTTOM, 0.000, 0.001)
    call BlzFrameSetSize(ModernTotemTracker___MTT_ProgressBack[index], ModernTotemTracker___MTT_PROGRESS_WIDTH, ModernTotemTracker___MTT_PROGRESS_HEIGHT)
    call BlzFrameSetTexture(ModernTotemTracker___MTT_ProgressBack[index], ModernTotemTracker___MTT_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetVertexColor(ModernTotemTracker___MTT_ProgressBack[index], BlzConvertColor(220, 8, 8, 8))
    call BlzFrameSetEnable(ModernTotemTracker___MTT_ProgressBack[index], false)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_ProgressBack[index], 35)

    set ModernTotemTracker___MTT_ProgressFill[index]=BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerProgressFill" + I2S(index), ModernTotemTracker___MTT_ProgressBack[index], "", 0)
    call BlzFrameSetPoint(ModernTotemTracker___MTT_ProgressFill[index], FRAMEPOINT_LEFT, ModernTotemTracker___MTT_ProgressBack[index], FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(ModernTotemTracker___MTT_ProgressFill[index], 0.0001, ModernTotemTracker___MTT_PROGRESS_HEIGHT)
    call BlzFrameSetTexture(ModernTotemTracker___MTT_ProgressFill[index], ModernTotemTracker___MTT_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetVertexColor(ModernTotemTracker___MTT_ProgressFill[index], ModernTotemTracker___MTT_GetColor(index))
    call BlzFrameSetEnable(ModernTotemTracker___MTT_ProgressFill[index], false)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_ProgressFill[index], 36)

    set ModernTotemTracker___MTT_TimerText[index]=BlzCreateFrameByType("TEXT", "ModernTotemTrackerTimer" + I2S(index), ModernTotemTracker___MTT_Slot[index], "", 0)
    call BlzFrameSetAllPoints(ModernTotemTracker___MTT_TimerText[index], ModernTotemTracker___MTT_Slot[index])
    call BlzFrameSetTextAlignment(ModernTotemTracker___MTT_TimerText[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernTotemTracker___MTT_TimerText[index], 0.70)
    call BlzFrameSetEnable(ModernTotemTracker___MTT_TimerText[index], false)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_TimerText[index], 37)

    call BlzFrameSetVisible(ModernTotemTracker___MTT_ProgressBack[index], false)
    call BlzFrameSetVisible(ModernTotemTracker___MTT_TimerText[index], false)
endfunction

function ModernTotemTracker___MTT_CreateFrames takes nothing returns nothing
    local integer index= 0
    local framehandle gameUI

    if ModernTotemTracker___MTT_FramesCreated then
        return
    endif
    set ModernTotemTracker___MTT_FramesCreated=true
    set gameUI=BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    set ModernTotemTracker___MTT_Parent=BlzCreateFrameByType("FRAME", "ModernTotemTracker", gameUI, "", 0)
    // A full-screen logical FRAME blocks unrelated UI and world clicks.
    call BlzFrameSetSize(ModernTotemTracker___MTT_Parent, 0.0001, 0.0001)
    call BlzFrameSetAbsPoint(ModernTotemTracker___MTT_Parent, FRAMEPOINT_BOTTOMLEFT, 0.000, 0.000)
    call BlzFrameSetLevel(ModernTotemTracker___MTT_Parent, 31)

    loop
        exitwhen index >= ModernTotemTracker___MTT_ELEMENT_COUNT
        call ModernTotemTracker___MTT_CreateElement(index)
        set index=index + 1
    endloop

    call ModernTotemTracker___MTT_ResetCache()
    call BlzFrameSetVisible(ModernTotemTracker___MTT_Parent, false)
    set gameUI=null
endfunction

function ModernTotemTracker_Refresh takes nothing returns nothing
    call ModernTotemTracker___MTT_Update()
endfunction

function ModernTotemTracker___MTT_DelayedInit takes nothing returns nothing
    call ModernTotemTracker___MTT_CreateFrames()
    call ModernTotemTracker___MTT_Update()
    call DestroyTrigger(ModernTotemTracker___MTT_InitTrigger)
    set ModernTotemTracker___MTT_InitTrigger=null
endfunction

function ModernTotemTracker___Init takes nothing returns nothing
    set ModernTotemTracker___MTT_InitTrigger=CreateTrigger()
    call TriggerRegisterTimerEvent(ModernTotemTracker___MTT_InitTrigger, 0.30, false)
    call TriggerAddAction(ModernTotemTracker___MTT_InitTrigger, function ModernTotemTracker___MTT_DelayedInit)
    call TriggerAddAction(ModernPlayerHUD__MHUD_UpdateTrigger, (function ModernTotemTracker___MTT_Update)) // INLINED!!
endfunction


//library ModernTotemTracker ends
//library ModernAbilityController:


function ModernAbilityController__MAC_IsElementalChoice takes integer abilityId returns boolean
    return abilityId == ModernAbilityController__MAC_ELEMENTAL_AIR or abilityId == ModernAbilityController__MAC_ELEMENTAL_WATER or abilityId == ModernAbilityController__MAC_ELEMENTAL_FIRE or abilityId == ModernAbilityController__MAC_ELEMENTAL_EARTH
endfunction

function ModernAbilityController__MAC_IsContextAbility takes integer abilityId returns boolean
    return abilityId == ModernAbilityController__MAC_STEALTH or abilityId == ModernAbilityController__MAC_STEALTH_ALT or abilityId == ModernAbilityController__MAC_BLOCK_50 or abilityId == ModernAbilityController__MAC_BLOCK_75 or abilityId == ModernAbilityController__MAC_BLOCK_100
endfunction

function ModernAbilityController__MAC_GetRuntimeOrderId takes unit caster,integer abilityId returns integer
    local integer abilityLevel= GetUnitAbilityLevel(caster, abilityId)
    local integer orderId= ModernAbilityCatalog_GetOrderId(abilityId)
    local ability whichAbility= null
    local string baseOrder

    if abilityLevel > 0 and ( ModernAbilityCatalog_UsesChannelOrder(abilityId) or ModernAbilityController__MAC_IsContextAbility(abilityId) ) then
        set whichAbility=BlzGetUnitAbility(caster, abilityId)
        if whichAbility != null then
            set baseOrder=BlzGetAbilityStringLevelField(whichAbility, ABILITY_SLF_BASE_ORDER_ID_NCL6, abilityLevel - 1)
            if baseOrder != null and baseOrder != "" then
                set orderId=OrderId(baseOrder)
            endif
        endif
    endif

    set whichAbility=null
    return orderId
endfunction

function ModernAbilityController__MAC_FindSeparator takes string source,integer startIndex returns integer
    local integer sourceLength= StringLength(source)
    local integer index= startIndex

    loop
        exitwhen index >= sourceLength
        if SubString(source, index, index + 1) == "," then
            return index
        endif
        set index=index + 1
    endloop

    return - 1
endfunction

function ModernAbilityController__MAC_ArmTargetingLocal takes nothing returns nothing
    local integer playerIndex= GetPlayerId(GetLocalPlayer())

    if ModernAbilityController__MAC_Targeting[playerIndex] then
        set ModernAbilityController__MAC_TargetingArmed[playerIndex]=true
    endif
endfunction

function ModernAbilityController__MAC_SetOrderCollisionsDisabled takes unit caster,integer selectedAbilityId,boolean disabled returns nothing
    local integer selectedOrderId= ModernAbilityController__MAC_GetRuntimeOrderId(caster , selectedAbilityId)
    local integer entryIndex= 1
    local integer entryCount= (0) // INLINED!!
    local integer abilityId

    if caster == null or selectedOrderId == 0 then
        return
    endif

    loop
        exitwhen entryIndex > entryCount
        set abilityId=AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        if abilityId != selectedAbilityId and GetUnitAbilityLevel(caster, abilityId) > 0 and ModernAbilityController__MAC_GetRuntimeOrderId(caster , abilityId) == selectedOrderId then
            call BlzUnitDisableAbility(caster, abilityId, disabled, false)
        endif
        set entryIndex=entryIndex + 1
    endloop
endfunction

function ModernAbilityController__MAC_Execute takes player sourcePlayer,integer heroSlot,integer slot,real pointX,real pointY returns nothing
    local unit caster= ShamanCommon_GetHeroBySlot(heroSlot)
    local unit target= null
    local integer abilityId
    local integer actionKind
    local integer targetPolicy
    local integer orderId
    local boolean issued= false

    if caster == null or GetOwningPlayer(caster) != sourcePlayer then
        set sourcePlayer=null
        set caster=null
        return
    endif

    set abilityId=ModernAbilityLoadout_GetEffectiveAbilityId(caster , slot)
    if abilityId == 0 or GetUnitAbilityLevel(caster, abilityId) <= 0 or not ModernAbilityCatalog_IsRuntimeReady(abilityId) then
        call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080That action is not ready for the modern bar yet.|r")
        set sourcePlayer=null
        set caster=null
        return
    endif

    set actionKind=ModernAbilityCatalog_GetActionKind(abilityId)
    set targetPolicy=ModernAbilityCatalog_GetTargetPolicy(abilityId)
    set orderId=ModernAbilityController__MAC_GetRuntimeOrderId(caster , abilityId)

    call ModernAbilityController__MAC_SetOrderCollisionsDisabled(caster , abilityId , true)
    if actionKind == ModernAbilityCatalog_ACTION_IMMEDIATE then
        set issued=IssueImmediateOrderById(caster, orderId)
    elseif actionKind == ModernAbilityCatalog_ACTION_UNIT then
        set target=ModernAbilityTargeting_ResolveUnit(caster , abilityId , pointX , pointY)
        if target != null then
            set issued=IssueTargetOrderById(caster, orderId, target)
        endif
    elseif actionKind == ModernAbilityCatalog_ACTION_POINT then
        set issued=IssuePointOrderById(caster, orderId, pointX, pointY)
    endif
    call ModernAbilityController__MAC_SetOrderCollisionsDisabled(caster , abilityId , false)

    if not issued then
        if actionKind == ModernAbilityCatalog_ACTION_UNIT and target == null then
            call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080No valid target was found near that point.|r")
        else
            call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080The ability could not be cast.|r")
        endif
    endif

    set sourcePlayer=null
    set caster=null
    set target=null
endfunction

function ModernAbilityController__MAC_ExecuteElemental takes player sourcePlayer,integer heroSlot,integer abilityId returns nothing
    local unit caster= ShamanCommon_GetHeroBySlot(heroSlot)
    local ability whichAbility= null
    local integer abilityLevel
    local string orderString
    local boolean issued= false

    if caster == null or GetOwningPlayer(caster) != sourcePlayer or not ModernAbilityController__MAC_IsElementalChoice(abilityId) then
        set sourcePlayer=null
        set caster=null
        return
    endif

    set abilityLevel=GetUnitAbilityLevel(caster, abilityId)
    if GetUnitAbilityLevel(caster, ModernAbilityController__MAC_SUMMON_ELEMENTAL) <= 0 or abilityLevel <= 0 then
        call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080That elemental is not available.|r")
        set sourcePlayer=null
        set caster=null
        return
    endif

    set whichAbility=BlzGetUnitAbility(caster, abilityId)
    if whichAbility != null then
        set orderString=BlzGetAbilityStringLevelField(whichAbility, ABILITY_SLF_BASE_ORDER_ID_NCL6, abilityLevel - 1)
    endif
    if orderString != null and orderString != "" then
        set issued=IssueImmediateOrder(caster, orderString)
    endif
    if not issued then
        call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080The elemental summon could not be started.|r")
    endif

    set whichAbility=null
    set sourcePlayer=null
    set caster=null
endfunction

function ModernAbilityController__MAC_ExecuteContext takes player sourcePlayer,integer heroSlot,integer abilityId returns nothing
    local unit caster= ShamanCommon_GetHeroBySlot(heroSlot)
    local integer orderId
    local boolean issued= false

    if caster == null or GetOwningPlayer(caster) != sourcePlayer or not ModernAbilityController__MAC_IsContextAbility(abilityId) or GetUnitAbilityLevel(caster, abilityId) <= 0 then
        set sourcePlayer=null
        set caster=null
        return
    endif

    set orderId=ModernAbilityController__MAC_GetRuntimeOrderId(caster , abilityId)
    if orderId == 0 and ( abilityId == ModernAbilityController__MAC_STEALTH or abilityId == ModernAbilityController__MAC_STEALTH_ALT ) then
        set orderId=OrderId("windwalk")
    endif
    if orderId != 0 then
        set issued=IssueImmediateOrderById(caster, orderId)
    endif
    if not issued then
        call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080The contextual ability could not be cast.|r")
    endif

    set sourcePlayer=null
    set caster=null
endfunction

function ModernAbilityController__MAC_SendCast takes integer heroSlot,integer slot,real pointX,real pointY returns nothing
    call BlzSendSyncData(ModernAbilityController__MAC_SYNC_PREFIX, I2S(heroSlot) + "," + I2S(slot) + "," + R2S(pointX) + "," + R2S(pointY))
endfunction

function ModernAbilityController__MAC_SendElemental takes integer heroSlot,integer abilityId returns nothing
    call BlzSendSyncData(ModernAbilityController__MAC_ELEMENTAL_SYNC_PREFIX, I2S(heroSlot) + "," + I2S(abilityId))
endfunction

function ModernAbilityController_SwapSlotsLocal takes player whichPlayer,unit whichHero,integer firstSlot,integer secondSlot returns nothing
    local integer heroSlot

    if whichPlayer == null or whichHero == null or whichPlayer != GetLocalPlayer() or GetOwningPlayer(whichHero) != whichPlayer then
        set whichPlayer=null
        set whichHero=null
        return
    endif

    set heroSlot=ShamanCommon_GetHeroSlot(whichHero)
    if heroSlot != ShamanCommon_HERO_SLOT_NONE and firstSlot >= 1 and firstSlot <= ModernAbilityLoadout_SLOT_COUNT and secondSlot >= 1 and secondSlot <= ModernAbilityLoadout_SLOT_COUNT and firstSlot != secondSlot then
        call BlzSendSyncData(ModernAbilityController__MAC_SWAP_SYNC_PREFIX, I2S(heroSlot) + "," + I2S(firstSlot) + "," + I2S(secondSlot))
    endif

    set whichPlayer=null
    set whichHero=null
endfunction

function ModernAbilityController_BeginContextLocal takes player whichPlayer,unit whichHero,integer abilityId returns nothing
    local integer heroSlot

    if whichPlayer == null or whichHero == null or whichPlayer != GetLocalPlayer() or GetOwningPlayer(whichHero) != whichPlayer or not ModernAbilityController__MAC_IsContextAbility(abilityId) then
        set whichPlayer=null
        set whichHero=null
        return
    endif

    set heroSlot=ShamanCommon_GetHeroSlot(whichHero)
    if heroSlot != ShamanCommon_HERO_SLOT_NONE and GetUnitAbilityLevel(whichHero, abilityId) > 0 then
        call BlzSendSyncData(ModernAbilityController__MAC_CONTEXT_SYNC_PREFIX, I2S(heroSlot) + "," + I2S(abilityId))
    endif

    set whichPlayer=null
    set whichHero=null
endfunction

function ModernAbilityController_AssignSlotLocal takes player whichPlayer,unit whichHero,integer slot,integer abilityId returns nothing
    local integer heroSlot

    if whichPlayer == null or whichHero == null or whichPlayer != GetLocalPlayer() or GetOwningPlayer(whichHero) != whichPlayer then
        set whichPlayer=null
        set whichHero=null
        return
    endif

    set heroSlot=ShamanCommon_GetHeroSlot(whichHero)
    if heroSlot != ShamanCommon_HERO_SLOT_NONE and slot >= 1 and slot <= ModernAbilityLoadout_SLOT_COUNT and ModernAbilityCatalog_IsAssignable(abilityId) and GetUnitAbilityLevel(whichHero, abilityId) > 0 then
        call BlzSendSyncData(ModernAbilityController__MAC_ASSIGN_SYNC_PREFIX, I2S(heroSlot) + "," + I2S(slot) + "," + I2S(abilityId))
    endif

    set whichPlayer=null
    set whichHero=null
endfunction

function ModernAbilityController_CancelLocal takes player whichPlayer returns nothing
    local integer playerIndex

    if whichPlayer == null or whichPlayer != GetLocalPlayer() then
        set whichPlayer=null
        return
    endif

    set playerIndex=GetPlayerId(whichPlayer)
    call PauseTimer(ModernAbilityController__MAC_TargetingArmTimer)
    set ModernAbilityController__MAC_Targeting[playerIndex]=false
    set ModernAbilityController__MAC_TargetingArmed[playerIndex]=false
    set ModernAbilityController__MAC_PendingHeroSlot[playerIndex]=0
    set ModernAbilityController__MAC_PendingSlot[playerIndex]=0
    set whichPlayer=null
endfunction

function ModernAbilityController_IsTargetingLocal takes player whichPlayer returns boolean
    local boolean active= false

    if whichPlayer != null and whichPlayer == GetLocalPlayer() then
        set active=ModernAbilityController__MAC_Targeting[GetPlayerId(whichPlayer)]
    endif
    set whichPlayer=null
    return active
endfunction

function ModernAbilityController_GetPendingAbilityId takes player whichPlayer returns integer
    local integer playerIndex
    local unit caster
    local integer abilityId= 0

    if whichPlayer == null or whichPlayer != GetLocalPlayer() then
        set whichPlayer=null
        return 0
    endif

    set playerIndex=GetPlayerId(whichPlayer)
    if ModernAbilityController__MAC_Targeting[playerIndex] then
        set caster=ShamanCommon_GetHeroBySlot(ModernAbilityController__MAC_PendingHeroSlot[playerIndex])
        set abilityId=ModernAbilityLoadout_GetEffectiveAbilityId(caster , ModernAbilityController__MAC_PendingSlot[playerIndex])
    endif

    set whichPlayer=null
    set caster=null
    return abilityId
endfunction

function ModernAbilityController_BeginLocal takes player whichPlayer,unit whichHero,integer slot returns nothing
    local integer playerIndex
    local integer heroSlot
    local integer abilityId
    local integer actionKind
    local integer targetPolicy

    if whichPlayer == null or whichHero == null or whichPlayer != GetLocalPlayer() or GetOwningPlayer(whichHero) != whichPlayer then
        set whichPlayer=null
        set whichHero=null
        return
    endif

    set playerIndex=GetPlayerId(whichPlayer)
    set heroSlot=ShamanCommon_GetHeroSlot(whichHero)
    set abilityId=ModernAbilityLoadout_GetEffectiveAbilityId(whichHero , slot)
    if heroSlot == ShamanCommon_HERO_SLOT_NONE or abilityId == 0 or not ModernAbilityCatalog_IsRuntimeReady(abilityId) then
        call DisplayTimedTextToPlayer(whichPlayer, 0.00, 0.00, 2.00, "|cffff8080That action is not ready for the modern bar yet.|r")
        set whichPlayer=null
        set whichHero=null
        return
    endif

    set actionKind=ModernAbilityCatalog_GetActionKind(abilityId)
    set targetPolicy=ModernAbilityCatalog_GetTargetPolicy(abilityId)
    if ( actionKind == ModernAbilityCatalog_ACTION_UNIT and targetPolicy != ModernAbilityCatalog_TARGET_SELF and targetPolicy != ModernAbilityCatalog_TARGET_MELEE_AUTO ) or actionKind == ModernAbilityCatalog_ACTION_POINT then
        set ModernAbilityController__MAC_Targeting[playerIndex]=true
        set ModernAbilityController__MAC_TargetingArmed[playerIndex]=false
        set ModernAbilityController__MAC_PendingHeroSlot[playerIndex]=heroSlot
        set ModernAbilityController__MAC_PendingSlot[playerIndex]=slot
        call TimerStart(ModernAbilityController__MAC_TargetingArmTimer, 0.00, false, function ModernAbilityController__MAC_ArmTargetingLocal)
        call DisplayTimedTextToPlayer(whichPlayer, 0.00, 0.00, 2.00, "|cffffcc00Choose a world target. Right-click to cancel.|r")
    else
        call BlzSendSyncData(ModernAbilityController__MAC_SYNC_PREFIX, I2S((heroSlot )) + "," + I2S(( slot )) + "," + R2S((( GetUnitX(whichHero) )*1.0)) + "," + R2S((( GetUnitY(whichHero))*1.0))) // INLINED!!
    endif

    set whichPlayer=null
    set whichHero=null
endfunction

function ModernAbilityController_BeginElementalLocal takes player whichPlayer,unit whichHero,integer abilityId returns nothing
    local integer heroSlot

    if whichPlayer == null or whichHero == null or whichPlayer != GetLocalPlayer() or GetOwningPlayer(whichHero) != whichPlayer or not ModernAbilityController__MAC_IsElementalChoice(abilityId) then
        set whichPlayer=null
        set whichHero=null
        return
    endif

    set heroSlot=ShamanCommon_GetHeroSlot(whichHero)
    if heroSlot == ShamanCommon_HERO_SLOT_NONE or GetUnitAbilityLevel(whichHero, ModernAbilityController__MAC_SUMMON_ELEMENTAL) <= 0 or GetUnitAbilityLevel(whichHero, abilityId) <= 0 then
        call DisplayTimedTextToPlayer(whichPlayer, 0.00, 0.00, 2.00, "|cffff8080That elemental is not available.|r")
    else
        call BlzSendSyncData(ModernAbilityController__MAC_ELEMENTAL_SYNC_PREFIX, I2S((heroSlot )) + "," + I2S(( abilityId))) // INLINED!!
    endif

    set whichPlayer=null
    set whichHero=null
endfunction

function ModernAbilityController__MAC_OnMouseDown takes nothing returns nothing
    local player whichPlayer= GetTriggerPlayer()
    local integer playerIndex= GetPlayerId(whichPlayer)
    local mousebuttontype mouseButton

    if whichPlayer == GetLocalPlayer() and ModernAbilityController__MAC_Targeting[playerIndex] and ModernAbilityController__MAC_TargetingArmed[playerIndex] then
        set mouseButton=BlzGetTriggerPlayerMouseButton()
        if mouseButton == MOUSE_BUTTON_TYPE_RIGHT then
            call ModernAbilityController_CancelLocal(whichPlayer)
        elseif mouseButton == MOUSE_BUTTON_TYPE_LEFT then
            call BlzSendSyncData(ModernAbilityController__MAC_SYNC_PREFIX, I2S((ModernAbilityController__MAC_PendingHeroSlot[playerIndex] )) + "," + I2S(( ModernAbilityController__MAC_PendingSlot[playerIndex] )) + "," + R2S((( BlzGetTriggerPlayerMouseX() )*1.0)) + "," + R2S((( BlzGetTriggerPlayerMouseY())*1.0))) // INLINED!!
            set ModernAbilityController__MAC_Targeting[playerIndex]=false
            set ModernAbilityController__MAC_TargetingArmed[playerIndex]=false
            set ModernAbilityController__MAC_PendingHeroSlot[playerIndex]=0
            set ModernAbilityController__MAC_PendingSlot[playerIndex]=0
        endif
    endif

    set mouseButton=null
    set whichPlayer=null
endfunction

function ModernAbilityController__MAC_HandleElementalSync takes player sourcePlayer,string data returns nothing
    local integer separator= ModernAbilityController__MAC_FindSeparator(data , 0)
    local integer heroSlot
    local integer abilityId

    if separator <= 0 then
        set sourcePlayer=null
        return
    endif
    set heroSlot=S2I(SubString(data, 0, separator))
    set abilityId=S2I(SubString(data, separator + 1, StringLength(data)))
    call ModernAbilityController__MAC_ExecuteElemental(sourcePlayer , heroSlot , abilityId)
    set sourcePlayer=null
endfunction

function ModernAbilityController__MAC_HandleSwapSync takes player sourcePlayer,string data returns nothing
    local integer separator1= ModernAbilityController__MAC_FindSeparator(data , 0)
    local integer separator2
    local integer heroSlot
    local integer firstSlot
    local integer secondSlot
    local unit caster

    if separator1 <= 0 then
        set sourcePlayer=null
        return
    endif
    set separator2=ModernAbilityController__MAC_FindSeparator(data , separator1 + 1)
    if separator2 <= separator1 then
        set sourcePlayer=null
        return
    endif

    set heroSlot=S2I(SubString(data, 0, separator1))
    set firstSlot=S2I(SubString(data, separator1 + 1, separator2))
    set secondSlot=S2I(SubString(data, separator2 + 1, StringLength(data)))
    set caster=ShamanCommon_GetHeroBySlot(heroSlot)
    if caster != null and GetOwningPlayer(caster) == sourcePlayer and firstSlot >= 1 and firstSlot <= ModernAbilityLoadout_SLOT_COUNT and secondSlot >= 1 and secondSlot <= ModernAbilityLoadout_SLOT_COUNT then
        call ModernAbilityLoadout_Swap(caster , firstSlot , secondSlot)
    endif

    set caster=null
    set sourcePlayer=null
endfunction

function ModernAbilityController__MAC_HandleContextSync takes player sourcePlayer,string data returns nothing
    local integer separator= ModernAbilityController__MAC_FindSeparator(data , 0)
    local integer heroSlot
    local integer abilityId

    if separator <= 0 then
        set sourcePlayer=null
        return
    endif
    set heroSlot=S2I(SubString(data, 0, separator))
    set abilityId=S2I(SubString(data, separator + 1, StringLength(data)))
    call ModernAbilityController__MAC_ExecuteContext(sourcePlayer , heroSlot , abilityId)
    set sourcePlayer=null
endfunction

function ModernAbilityController__MAC_HandleAssignSync takes player sourcePlayer,string data returns nothing
    local integer separator1= ModernAbilityController__MAC_FindSeparator(data , 0)
    local integer separator2
    local integer heroSlot
    local integer slot
    local integer abilityId
    local unit caster

    if separator1 <= 0 then
        set sourcePlayer=null
        return
    endif
    set separator2=ModernAbilityController__MAC_FindSeparator(data , separator1 + 1)
    if separator2 <= separator1 then
        set sourcePlayer=null
        return
    endif

    set heroSlot=S2I(SubString(data, 0, separator1))
    set slot=S2I(SubString(data, separator1 + 1, separator2))
    set abilityId=S2I(SubString(data, separator2 + 1, StringLength(data)))
    set caster=ShamanCommon_GetHeroBySlot(heroSlot)
    if caster != null and GetOwningPlayer(caster) == sourcePlayer and slot >= 1 and slot <= ModernAbilityLoadout_SLOT_COUNT and ModernAbilityCatalog_IsAssignable(abilityId) and GetUnitAbilityLevel(caster, abilityId) > 0 then
        call ModernAbilityLoadout_Assign(caster , slot , abilityId)
    endif

    set caster=null
    set sourcePlayer=null
endfunction

function ModernAbilityController__MAC_OnSync takes nothing returns nothing
    local string data= BlzGetTriggerSyncData()
    local integer separator1= ModernAbilityController__MAC_FindSeparator(data , 0)
    local integer separator2
    local integer separator3
    local integer heroSlot
    local integer slot
    local real pointX
    local real pointY
    local player sourcePlayer= GetTriggerPlayer()

    if BlzGetTriggerSyncPrefix() == ModernAbilityController__MAC_ELEMENTAL_SYNC_PREFIX then
        call ModernAbilityController__MAC_HandleElementalSync(sourcePlayer , data)
        set sourcePlayer=null
        return
    endif
    if BlzGetTriggerSyncPrefix() == ModernAbilityController__MAC_SWAP_SYNC_PREFIX then
        call ModernAbilityController__MAC_HandleSwapSync(sourcePlayer , data)
        set sourcePlayer=null
        return
    endif
    if BlzGetTriggerSyncPrefix() == ModernAbilityController__MAC_CONTEXT_SYNC_PREFIX then
        call ModernAbilityController__MAC_HandleContextSync(sourcePlayer , data)
        set sourcePlayer=null
        return
    endif
    if BlzGetTriggerSyncPrefix() == ModernAbilityController__MAC_ASSIGN_SYNC_PREFIX then
        call ModernAbilityController__MAC_HandleAssignSync(sourcePlayer , data)
        set sourcePlayer=null
        return
    endif

    if separator1 <= 0 then
        set sourcePlayer=null
        return
    endif
    set separator2=ModernAbilityController__MAC_FindSeparator(data , separator1 + 1)
    if separator2 <= separator1 then
        set sourcePlayer=null
        return
    endif
    set separator3=ModernAbilityController__MAC_FindSeparator(data , separator2 + 1)
    if separator3 <= separator2 then
        set sourcePlayer=null
        return
    endif

    set heroSlot=S2I(SubString(data, 0, separator1))
    set slot=S2I(SubString(data, separator1 + 1, separator2))
    set pointX=S2R(SubString(data, separator2 + 1, separator3))
    set pointY=S2R(SubString(data, separator3 + 1, StringLength(data)))
    if slot >= 1 and slot <= ModernAbilityLoadout_SLOT_COUNT then
        call ModernAbilityController__MAC_Execute(sourcePlayer , heroSlot , slot , pointX , pointY)
    endif

    set sourcePlayer=null
endfunction

function ModernAbilityController__Init takes nothing returns nothing
    local integer playerIndex= 0

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerEvent(ModernAbilityController__MAC_MouseTrigger, Player(playerIndex), EVENT_PLAYER_MOUSE_DOWN)
        call BlzTriggerRegisterPlayerSyncEvent(ModernAbilityController__MAC_SyncTrigger, Player(playerIndex), ModernAbilityController__MAC_SYNC_PREFIX, false)
        call BlzTriggerRegisterPlayerSyncEvent(ModernAbilityController__MAC_SyncTrigger, Player(playerIndex), ModernAbilityController__MAC_ELEMENTAL_SYNC_PREFIX, false)
        call BlzTriggerRegisterPlayerSyncEvent(ModernAbilityController__MAC_SyncTrigger, Player(playerIndex), ModernAbilityController__MAC_SWAP_SYNC_PREFIX, false)
        call BlzTriggerRegisterPlayerSyncEvent(ModernAbilityController__MAC_SyncTrigger, Player(playerIndex), ModernAbilityController__MAC_CONTEXT_SYNC_PREFIX, false)
        call BlzTriggerRegisterPlayerSyncEvent(ModernAbilityController__MAC_SyncTrigger, Player(playerIndex), ModernAbilityController__MAC_ASSIGN_SYNC_PREFIX, false)
        set playerIndex=playerIndex + 1
    endloop
    call TriggerAddAction(ModernAbilityController__MAC_MouseTrigger, function ModernAbilityController__MAC_OnMouseDown)
    call TriggerAddAction(ModernAbilityController__MAC_SyncTrigger, function ModernAbilityController__MAC_OnSync)
endfunction


//library ModernAbilityController ends
//library ModernAbilityActionBar:


function ModernAbilityActionBar__MAB_IsValidUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetHandleId(whichUnit) != 0 and GetUnitTypeId(whichUnit) != 0
endfunction

function ModernAbilityActionBar__MAB_IsPlayerHero takes unit whichUnit returns boolean
    return ModernAbilityActionBar__MAB_IsValidUnit(whichUnit) and GetOwningPlayer(whichUnit) == Player(0) and ShamanCommon_IsPlayerHero(whichUnit)
endfunction

function ModernAbilityActionBar__MAB_GetSlotLabel takes integer slot returns string
    if slot < 10 then
        return I2S(slot)
    elseif slot == 10 then
        return "0"
    elseif slot == 11 then
        return "-"
    endif
    return "="
endfunction

function ModernAbilityActionBar__MAB_GetKeyLabel takes oskeytype whichKey returns string
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

function ModernAbilityActionBar__MAB_GetAbilityIconPath takes integer abilityId returns string
    local integer entryIndex
    local integer addAbilityId
    local string iconPath= BlzGetAbilityIcon(abilityId)

    if iconPath == null or iconPath == "" then
        set entryIndex=AbilitiesPlayer_GetEntryByAbilityId(abilityId)
        if entryIndex != 0 then
            set addAbilityId=AbilitiesPlayer_GetEntryAddAbilityId(entryIndex)
            if addAbilityId != 0 then
                set iconPath=BlzGetAbilityIcon(addAbilityId)
            endif
        endif
    endif
    if iconPath == null or iconPath == "" then
        set iconPath=ModernAbilityActionBar__MAB_EMPTY_ICON
    endif
    return iconPath
endfunction

function ModernAbilityActionBar__MAB_GetElementalAbilityId takes integer index returns integer
    if index == 0 then
        return ModernAbilityActionBar__MAB_ELEMENTAL_AIR
    elseif index == 1 then
        return ModernAbilityActionBar__MAB_ELEMENTAL_WATER
    elseif index == 2 then
        return ModernAbilityActionBar__MAB_ELEMENTAL_FIRE
    endif
    return ModernAbilityActionBar__MAB_ELEMENTAL_EARTH
endfunction

function ModernAbilityActionBar__MAB_IsElementalChoice takes integer abilityId returns boolean
    return abilityId == ModernAbilityActionBar__MAB_ELEMENTAL_AIR or abilityId == ModernAbilityActionBar__MAB_ELEMENTAL_WATER or abilityId == ModernAbilityActionBar__MAB_ELEMENTAL_FIRE or abilityId == ModernAbilityActionBar__MAB_ELEMENTAL_EARTH
endfunction

function ModernAbilityActionBar__MAB_GetContextAbilityId takes unit whichHero,integer index returns integer
    if index == 0 then
        if GetUnitAbilityLevel(whichHero, ModernAbilityActionBar__MAB_STEALTH) > 0 then
            return ModernAbilityActionBar__MAB_STEALTH
        elseif GetUnitAbilityLevel(whichHero, ModernAbilityActionBar__MAB_STEALTH_ALT) > 0 then
            return ModernAbilityActionBar__MAB_STEALTH_ALT
        endif
    elseif GetUnitAbilityLevel(whichHero, ModernAbilityActionBar__MAB_BLOCK_100) > 0 then
        return ModernAbilityActionBar__MAB_BLOCK_100
    elseif GetUnitAbilityLevel(whichHero, ModernAbilityActionBar__MAB_BLOCK_75) > 0 then
        return ModernAbilityActionBar__MAB_BLOCK_75
    elseif GetUnitAbilityLevel(whichHero, ModernAbilityActionBar__MAB_BLOCK_50) > 0 then
        return ModernAbilityActionBar__MAB_BLOCK_50
    endif
    return 0
endfunction

function ModernAbilityActionBar__MAB_UpdateContextSlots takes unit whichHero returns nothing
    local integer index= 0
    local integer abilityId
    local string iconPath

    loop
        exitwhen index >= ModernAbilityActionBar__MAB_CONTEXT_COUNT
        set abilityId=ModernAbilityActionBar__MAB_GetContextAbilityId(whichHero , index)
        if abilityId != ModernAbilityActionBar__MAB_ContextAbilityId[index] then
            set ModernAbilityActionBar__MAB_ContextAbilityId[index]=abilityId
            if abilityId != 0 then
                set iconPath=ModernAbilityActionBar__MAB_GetAbilityIconPath(abilityId)
                call BlzFrameSetTexture(ModernAbilityActionBar__MAB_ContextIcon[index], iconPath, 0, true)
            endif
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_ContextButton[index], abilityId != 0)
        endif
        set index=index + 1
    endloop

    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_GetElementalLabel takes integer index returns string
    if index == 0 then
        return "Air"
    elseif index == 1 then
        return "Water"
    elseif index == 2 then
        return "Fire"
    endif
    return "Earth"
endfunction

function ModernAbilityActionBar__MAB_Clamp takes real value returns real
    if value < 0.00 then
        return 0.00
    elseif value > 1.00 then
        return 1.00
    endif
    return value
endfunction

function ModernAbilityActionBar__MAB_RegisterNativeFrame takes framehandle whichFrame returns nothing
    if whichFrame != null then
        set ModernAbilityActionBar__MAB_NativeFrame[ModernAbilityActionBar__MAB_NativeFrameCount]=whichFrame
        set ModernAbilityActionBar__MAB_NativeFrameCount=ModernAbilityActionBar__MAB_NativeFrameCount + 1
    endif
    set whichFrame=null
endfunction

function ModernAbilityActionBar__MAB_FindNativeFrames takes nothing returns nothing
    local integer index= 0

    if ModernAbilityActionBar__MAB_NativeFrameCount > 0 then
        return
    endif

    call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleBottomBar", 0))
    call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleBottomBarOverlay", 0))
    call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BAR, 0))
    call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_PORTRAIT, 0))
    loop
        exitwhen index >= ModernAbilityActionBar__MAB_NATIVE_HERO_BUTTON_COUNT
        call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BUTTON, index))
        call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_HP_BAR, index))
        call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_MANA_BAR, index))
        call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BUTTON_INDICATOR, index))
        set index=index + 1
    endloop
    // Keep this last so child visibility is captured before the parent hides.
    call ModernAbilityActionBar__MAB_RegisterNativeFrame(BlzGetFrameByName("ConsoleUIBackdrop", 0))
endfunction

function ModernAbilityActionBar__MAB_CaptureNativeVisibility takes nothing returns nothing
    local integer index= 0

    if ModernAbilityActionBar__MAB_NativeCaptured or (false) then // INLINED!!
        return
    endif

    call ModernAbilityActionBar__MAB_FindNativeFrames()
    loop
        exitwhen index >= ModernAbilityActionBar__MAB_NativeFrameCount
        set ModernAbilityActionBar__MAB_NativeWasVisible[index]=BlzFrameIsVisible(ModernAbilityActionBar__MAB_NativeFrame[index])
        set index=index + 1
    endloop
    set ModernAbilityActionBar__MAB_NativeCaptured=true
endfunction

function ModernAbilityActionBar__MAB_HideNativeFrames takes nothing returns nothing
    local integer index= 0

    if not ModernAbilityActionBar__MAB_HIDE_NATIVE_BOTTOM_HUD then
        return
    endif

    call ModernAbilityActionBar__MAB_CaptureNativeVisibility()
    if not ModernAbilityActionBar__MAB_NativeCaptured then
        return
    endif
    loop
        exitwhen index >= ModernAbilityActionBar__MAB_NativeFrameCount
        if BlzFrameIsVisible(ModernAbilityActionBar__MAB_NativeFrame[index]) then
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_NativeFrame[index], false)
        endif
        set index=index + 1
    endloop
endfunction

function ModernAbilityActionBar__MAB_RestoreNativeFrames takes nothing returns nothing
    local integer index= 0

    if not ModernAbilityActionBar__MAB_NativeCaptured then
        return
    endif
    loop
        exitwhen index >= ModernAbilityActionBar__MAB_NativeFrameCount
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_NativeFrame[index], ModernAbilityActionBar__MAB_NativeWasVisible[index])
        set index=index + 1
    endloop
    set ModernAbilityActionBar__MAB_NativeCaptured=false
endfunction

function ModernAbilityActionBar__MAB_CloseTooltip takes nothing returns nothing
    if ModernAbilityActionBar__MAB_Tooltip != null then
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_Tooltip, false)
    endif
endfunction

function ModernAbilityActionBar__MAB_SetParentVisible takes boolean visible returns nothing
    if ModernAbilityActionBar__MAB_ParentVisible != visible then
        set ModernAbilityActionBar__MAB_ParentVisible=visible
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_Parent, visible)
        if not visible then
            call ModernAbilityActionBar__MAB_CloseTooltip()
        endif
    endif
endfunction

function ModernAbilityActionBar__MAB_ResetSlotCache takes nothing returns nothing
    local integer index= 0

    set ModernAbilityActionBar__MAB_CachedHero=null
    set ModernAbilityActionBar__MAB_StaticDirty=true
    set ModernAbilityActionBar__MAB_CachedTargetingAbility=- 1
    set ModernAbilityActionBar__MAB_CachedTargetingMode=- 1
    set ModernAbilityActionBar__MAB_CachedMana=- 1
    set ModernAbilityActionBar__MAB_CachedLoadoutRevision=- 1
    set ModernAbilityActionBar__MAB_LearnScanTick=0
    set ModernAbilityActionBar__MAB_MoveSourceSlot=0
    set ModernAbilityActionBar__MAB_RebindSlot=0
    call ModernAbilityActionBar__MAB_CloseTooltip()
    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        set ModernAbilityActionBar__MAB_CachedAbilityId[index]=- 1
        set ModernAbilityActionBar__MAB_CachedAbilityLevel[index]=- 1
        set ModernAbilityActionBar__MAB_CachedManaCost[index]=- 1
        set ModernAbilityActionBar__MAB_CachedCooldownSecond[index]=- 1
        set ModernAbilityActionBar__MAB_CachedCooldownStep[index]=- 1
        set ModernAbilityActionBar__MAB_CachedReady[index]=false
        set ModernAbilityActionBar__MAB_CachedDisabled[index]=false
        set ModernAbilityActionBar__MAB_CachedCooldownVisible[index]=false
        set ModernAbilityActionBar__MAB_CooldownActive[index]=false
        set ModernAbilityActionBar__MAB_CachedTitle[index]=""
        set ModernAbilityActionBar__MAB_CachedBody[index]=""
        set ModernAbilityActionBar__MAB_CachedIcon[index]=""
        set index=index + 1
    endloop
endfunction

function ModernAbilityActionBar__MAB_CloseElementalFlyout takes nothing returns nothing
    if not ModernAbilityActionBar__MAB_ElementalOpen then
        return
    endif
    set ModernAbilityActionBar__MAB_ElementalOpen=false
    set ModernAbilityActionBar__MAB_ElementalHero=null
    if ModernAbilityActionBar__MAB_ElementalBackdrop != null then
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_ElementalBackdrop, false)
    endif
endfunction

function ModernAbilityActionBar__MAB_OpenElementalFlyout takes unit whichHero returns nothing
    if not ModernAbilityActionBar__MAB_IsPlayerHero(whichHero) or GetUnitAbilityLevel(whichHero, ModernAbilityActionBar__MAB_SUMMON_ELEMENTAL) <= 0 then
        set whichHero=null
        return
    endif

    set ModernAbilityActionBar__MAB_ElementalHero=whichHero
    set ModernAbilityActionBar__MAB_ElementalOpen=true
    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_ElementalBackdrop, true)
    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_UpdateElementalFlyout takes nothing returns nothing
    local integer index= 0
    local integer abilityId
    local integer abilityLevel
    local integer manaCost
    local real mana
    local boolean ready

    if not ModernAbilityActionBar__MAB_ElementalOpen then
        return
    endif
    if not ModernAbilityActionBar__MAB_IsPlayerHero(ModernAbilityActionBar__MAB_ElementalHero) or GetUnitAbilityLevel(ModernAbilityActionBar__MAB_ElementalHero, ModernAbilityActionBar__MAB_SUMMON_ELEMENTAL) <= 0 then
        call ModernAbilityActionBar__MAB_CloseElementalFlyout()
        return
    endif

    set mana=GetUnitState(ModernAbilityActionBar__MAB_ElementalHero, UNIT_STATE_MANA)
    loop
        exitwhen index >= ModernAbilityActionBar__MAB_ELEMENTAL_COUNT
        set abilityId=ModernAbilityActionBar__MAB_GetElementalAbilityId(index)
        set abilityLevel=GetUnitAbilityLevel(ModernAbilityActionBar__MAB_ElementalHero, abilityId)
        set manaCost=0
        if abilityLevel > 0 then
            set manaCost=BlzGetUnitAbilityManaCost(ModernAbilityActionBar__MAB_ElementalHero, abilityId, abilityLevel - 1)
        endif
        set ready=abilityLevel > 0 and BlzGetUnitAbilityCooldownRemaining(ModernAbilityActionBar__MAB_ElementalHero, abilityId) <= 0.00 and mana + 0.01 >= I2R(manaCost)
        if ModernAbilityActionBar__MAB_ElementalReady[index] != ready then
            set ModernAbilityActionBar__MAB_ElementalReady[index]=ready
            call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ElementalButton[index], ready)
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_ElementalDisabled[index], not ready)
        endif
        set index=index + 1
    endloop
endfunction

function ModernAbilityActionBar__MAB_SetCooldownVisual takes integer index,unit whichHero,integer abilityId,integer abilityLevel returns nothing
    local real remaining= BlzGetUnitAbilityCooldownRemaining(whichHero, abilityId)
    local real total
    local integer second
    local integer step

    if remaining > 0.00 then
        set ModernAbilityActionBar__MAB_CooldownActive[index]=true
        set total=BlzGetUnitAbilityCooldown(whichHero, abilityId, abilityLevel - 1)
        if total > 0.00 then
            set step=R2I(ModernAbilityActionBar__MAB_Clamp(remaining / total) * I2R(ModernAbilityActionBar__MAB_COOLDOWN_STEPS))
        else
            set step=ModernAbilityActionBar__MAB_COOLDOWN_STEPS
        endif
        if step < 1 then
            set step=1
        endif
        if step != ModernAbilityActionBar__MAB_CachedCooldownStep[index] then
            set ModernAbilityActionBar__MAB_CachedCooldownStep[index]=step
            call BlzFrameSetSize(ModernAbilityActionBar__MAB_SlotCooldown[index], ModernAbilityActionBar__MAB_ACTION_SIZE - 0.004, ( ModernAbilityActionBar__MAB_ACTION_SIZE - 0.004 ) * I2R(step) / I2R(ModernAbilityActionBar__MAB_COOLDOWN_STEPS))
        endif
        set second=R2I(remaining + 0.99)
        if second != ModernAbilityActionBar__MAB_CachedCooldownSecond[index] then
            set ModernAbilityActionBar__MAB_CachedCooldownSecond[index]=second
            call BlzFrameSetText(ModernAbilityActionBar__MAB_SlotCooldownText[index], I2S(second))
        endif
        if not ModernAbilityActionBar__MAB_CachedCooldownVisible[index] then
            set ModernAbilityActionBar__MAB_CachedCooldownVisible[index]=true
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotCooldown[index], true)
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotCooldownText[index], true)
        endif
    else
        set ModernAbilityActionBar__MAB_CooldownActive[index]=false
        if ModernAbilityActionBar__MAB_CachedCooldownVisible[index] then
            set ModernAbilityActionBar__MAB_CachedCooldownVisible[index]=false
            set ModernAbilityActionBar__MAB_CachedCooldownSecond[index]=- 1
            set ModernAbilityActionBar__MAB_CachedCooldownStep[index]=- 1
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotCooldown[index], false)
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotCooldownText[index], false)
        endif
    endif

    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_UpdateSlotStatic takes integer index,unit whichHero returns nothing
    local integer slot= index + 1
    local integer abilityId= ModernAbilityLoadout_GetEffectiveAbilityId(whichHero , slot)
    local integer entryIndex
    local integer abilityLevel= 0
    local string iconPath
    local boolean ready

    if abilityId != 0 then
        set abilityLevel=GetUnitAbilityLevel(whichHero, abilityId)
    endif
    if not ModernAbilityActionBar__MAB_StaticDirty and abilityId == ModernAbilityActionBar__MAB_CachedAbilityId[index] and abilityLevel == ModernAbilityActionBar__MAB_CachedAbilityLevel[index] then
        set whichHero=null
        return
    endif

    set ModernAbilityActionBar__MAB_CachedAbilityId[index]=abilityId
    set ModernAbilityActionBar__MAB_CachedAbilityLevel[index]=abilityLevel
    set ModernAbilityActionBar__MAB_CachedCooldownSecond[index]=- 1
    set ModernAbilityActionBar__MAB_CachedCooldownStep[index]=- 1
    set ModernAbilityActionBar__MAB_CooldownActive[index]=false
    if ModernAbilityActionBar__MAB_CachedCooldownVisible[index] then
        set ModernAbilityActionBar__MAB_CachedCooldownVisible[index]=false
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotCooldown[index], false)
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotCooldownText[index], false)
    endif

    if abilityId == 0 then
        set ModernAbilityActionBar__MAB_CachedManaCost[index]=0
        set ModernAbilityActionBar__MAB_CachedReady[index]=false
        set ModernAbilityActionBar__MAB_CachedDisabled[index]=false
        set ModernAbilityActionBar__MAB_CachedTitle[index]="Empty slot"
        set ModernAbilityActionBar__MAB_CachedBody[index]="Choose a learned ability from the Abilities book."
        set ModernAbilityActionBar__MAB_CachedIcon[index]=ModernAbilityActionBar__MAB_EMPTY_ICON
        call BlzFrameSetTexture(ModernAbilityActionBar__MAB_SlotIcon[index], ModernAbilityActionBar__MAB_EMPTY_ICON, 0, true)
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotIcon[index], false)
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotDisabled[index], false)
        // Empty slots stay interactive so a player can move an ability into one.
        call BlzFrameSetEnable(ModernAbilityActionBar__MAB_SlotButton[index], true)
        set whichHero=null
        return
    endif

    set entryIndex=AbilitiesPlayer_GetEntryByAbilityId(abilityId)
    set ready=abilityLevel > 0 and ModernAbilityCatalog_IsRuntimeReady(abilityId)
    set iconPath=ModernAbilityActionBar__MAB_GetAbilityIconPath(abilityId)

    set ModernAbilityActionBar__MAB_CachedIcon[index]=iconPath
    set ModernAbilityActionBar__MAB_CachedReady[index]=ready
    set ModernAbilityActionBar__MAB_CachedDisabled[index]=false
    set ModernAbilityActionBar__MAB_CachedTitle[index]=AbilitiesPlayer_GetEntryTitle(entryIndex)
    set ModernAbilityActionBar__MAB_CachedBody[index]=AbilitiesPlayer_GetEntryBodyForLevel(entryIndex , abilityLevel)
    if abilityLevel > 0 then
        set ModernAbilityActionBar__MAB_CachedManaCost[index]=BlzGetUnitAbilityManaCost(whichHero, abilityId, abilityLevel - 1)
    else
        set ModernAbilityActionBar__MAB_CachedManaCost[index]=0
    endif

    call BlzFrameSetTexture(ModernAbilityActionBar__MAB_SlotIcon[index], ModernAbilityActionBar__MAB_CachedIcon[index], 0, true)
    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotIcon[index], true)
    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotDisabled[index], false)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_SlotButton[index], true)
    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_UpdateSlotReadiness takes integer index,unit whichHero,real mana returns nothing
    local integer abilityId= ModernAbilityActionBar__MAB_CachedAbilityId[index]
    local integer abilityLevel= ModernAbilityActionBar__MAB_CachedAbilityLevel[index]
    local boolean disabled

    if abilityId <= 0 or abilityLevel <= 0 then
        set whichHero=null
        return
    endif

    set disabled=not ModernAbilityActionBar__MAB_CachedReady[index] or mana + 0.01 < I2R(ModernAbilityActionBar__MAB_CachedManaCost[index])
    if disabled != ModernAbilityActionBar__MAB_CachedDisabled[index] then
        set ModernAbilityActionBar__MAB_CachedDisabled[index]=disabled
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_SlotDisabled[index], disabled)
    endif
    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_UpdateCooldowns takes unit whichHero,boolean discover returns nothing
    local integer index= 0

    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        if ( discover or ModernAbilityActionBar__MAB_CooldownActive[index] ) and ModernAbilityActionBar__MAB_CachedAbilityId[index] > 0 and ModernAbilityActionBar__MAB_CachedAbilityLevel[index] > 0 then
            call ModernAbilityActionBar__MAB_SetCooldownVisual(index , whichHero , ModernAbilityActionBar__MAB_CachedAbilityId[index] , ModernAbilityActionBar__MAB_CachedAbilityLevel[index])
        endif
        set index=index + 1
    endloop

    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_UpdateTargetingText takes nothing returns nothing
    local player localPlayer= GetLocalPlayer()
    local integer abilityId= (0) // INLINED!!
    local integer mode= 0
    local integer payload= 0
    local integer entryIndex= 0
    local string text= ""

    if abilityId > 0 then
        set mode=1
        set payload=abilityId
    elseif ModernAbilityActionBar__MAB_RebindSlot > 0 then
        set mode=2
        set payload=ModernAbilityActionBar__MAB_RebindSlot
    elseif ModernAbilityActionBar__MAB_MoveSourceSlot > 0 then
        set mode=3
        set payload=ModernAbilityActionBar__MAB_MoveSourceSlot
    elseif ModernAbilityController_IsTargetingLocal(localPlayer) then
        set mode=4
        set abilityId=ModernAbilityController_GetPendingAbilityId(localPlayer)
        set payload=abilityId
    endif

    if mode != ModernAbilityActionBar__MAB_CachedTargetingMode or payload != ModernAbilityActionBar__MAB_CachedTargetingAbility then
        set ModernAbilityActionBar__MAB_CachedTargetingMode=mode
        set ModernAbilityActionBar__MAB_CachedTargetingAbility=payload
        if mode == 1 then
            set entryIndex=AbilitiesPlayer_GetEntryByAbilityId(payload)
            set text="|cffffcc00Assign " + AbilitiesPlayer_GetEntryTitle(entryIndex) + ":|r click an action-bar slot.  |cffaaaaaa(Right-click another ability to change selection)|r"
        elseif mode == 2 then
            set text="|cffffcc00Rebind slot " + I2S(payload) + ":|r press 1-0, -, =, QWER, ASDF, or ZXCV.  |cffaaaaaa(Right-click a slot to cancel)|r"
        elseif mode == 3 then
            set text="|cffffcc00Move slot " + I2S(payload) + ":|r click another slot to swap.  |cffaaaaaa(Right-click the source again to cancel)|r"
        elseif mode == 4 then
            set entryIndex=AbilitiesPlayer_GetEntryByAbilityId(abilityId)
            set text="|cffffcc00Choose target:|r " + AbilitiesPlayer_GetEntryTitle(entryIndex) + "  |cffaaaaaa(Right-click cancels)|r"
        endif
        if mode > 0 then
            call BlzFrameSetText(ModernAbilityActionBar__MAB_TargetingText, text)
        endif
    endif

    if mode > 0 then
        if not ModernAbilityActionBar__MAB_TargetingVisible then
            set ModernAbilityActionBar__MAB_TargetingVisible=true
            call BlzFrameSetVisible(ModernAbilityActionBar__MAB_TargetingText, true)
        endif
    elseif ModernAbilityActionBar__MAB_TargetingVisible then
        set ModernAbilityActionBar__MAB_TargetingVisible=false
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_TargetingText, false)
    endif

    set localPlayer=null
endfunction

function ModernAbilityActionBar__MAB_Update takes nothing returns nothing
    local unit whichHero= ModernAbilityActionBar__MAB_SelectedUnit
    local integer index= 0
    local string heroIcon
    local integer mana
    local boolean rebuild
    local integer revision

    if not ModernAbilityActionBar__MAB_Enabled or not (ModernPlayerHUD__MHUD_Enabled) or (false) then // INLINED!!
        if (false) then // INLINED!!
            set ModernAbilityActionBar__MAB_WasFullscreen=true
        endif
        call ModernAbilityActionBar__MAB_SetParentVisible(false)
        call ModernAbilityActionBar__MAB_CloseElementalFlyout()
        set whichHero=null
        return
    endif

    if ModernAbilityActionBar__MAB_WasFullscreen or not ModernAbilityActionBar__MAB_NativeCaptured then
        set ModernAbilityActionBar__MAB_WasFullscreen=false
        call ModernAbilityActionBar__MAB_HideNativeFrames()
    endif
    if not ModernAbilityActionBar__MAB_IsValidUnit(whichHero) and GetLocalPlayer() == Player(0) and ModernAbilityActionBar__MAB_IsValidUnit(udg_Nazgrek) then
        set whichHero=udg_Nazgrek
        set ModernAbilityActionBar__MAB_SelectedUnit=whichHero
    endif
    if not ModernAbilityActionBar__MAB_IsPlayerHero(whichHero) then
        call ModernAbilityActionBar__MAB_SetParentVisible(false)
        call ModernAbilityActionBar__MAB_CloseElementalFlyout()
        set whichHero=null
        return
    endif

    if ModernAbilityActionBar__MAB_CachedHero != whichHero then
        call ModernAbilityActionBar__MAB_ResetSlotCache()
        set ModernAbilityActionBar__MAB_CachedHero=whichHero
        set heroIcon=BlzGetAbilityIcon(GetUnitTypeId(whichHero))
        if heroIcon == null or heroIcon == "" then
            set heroIcon=ModernAbilityActionBar__MAB_EMPTY_ICON
        endif
        call BlzFrameSetTexture(ModernAbilityActionBar__MAB_HeroIcon, heroIcon, 0, true)
    endif

    set ModernAbilityActionBar__MAB_LearnScanTick=ModernAbilityActionBar__MAB_LearnScanTick + 1
    if ModernAbilityActionBar__MAB_LearnScanTick >= 8 then
        set ModernAbilityActionBar__MAB_LearnScanTick=0
        call ModernAbilityLoadout_AppendNewLearned(whichHero)
    endif
    set revision=ModernAbilityLoadout_GetRevision(whichHero)
    if revision != ModernAbilityActionBar__MAB_CachedLoadoutRevision then
        set ModernAbilityActionBar__MAB_CachedLoadoutRevision=revision
        set ModernAbilityActionBar__MAB_StaticDirty=true
    endif

    call ModernAbilityActionBar__MAB_SetParentVisible(true)
    set rebuild=ModernAbilityActionBar__MAB_StaticDirty
    if rebuild then
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            call ModernAbilityActionBar__MAB_UpdateSlotStatic(index , whichHero)
            set index=index + 1
        endloop
        set ModernAbilityActionBar__MAB_StaticDirty=false
    endif

    set mana=R2I(GetUnitState(whichHero, UNIT_STATE_MANA))
    if rebuild or mana != ModernAbilityActionBar__MAB_CachedMana then
        set ModernAbilityActionBar__MAB_CachedMana=mana
        set index=0
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            call ModernAbilityActionBar__MAB_UpdateSlotReadiness(index , whichHero , I2R(mana))
            set index=index + 1
        endloop
    endif
    call ModernAbilityActionBar__MAB_UpdateCooldowns(whichHero , rebuild)
    call ModernAbilityActionBar__MAB_UpdateContextSlots(whichHero)
    if ModernAbilityActionBar__MAB_ElementalOpen then
        call ModernAbilityActionBar__MAB_UpdateElementalFlyout()
    endif
    call ModernAbilityActionBar__MAB_UpdateTargetingText()

    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_ClearFocusAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()

    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(triggerFrame, false)
        call BlzFrameSetEnable(triggerFrame, true)
    endif
    set triggerFrame=null
endfunction

function ModernAbilityActionBar__MAB_ActivateSlotLocal takes player whichPlayer,integer index returns nothing
    local integer abilityId

    if whichPlayer != GetLocalPlayer() or index < 0 or index >= ModernAbilityLoadout_SLOT_COUNT or not ModernAbilityActionBar__MAB_IsPlayerHero(ModernAbilityActionBar__MAB_SelectedUnit) then
        set whichPlayer=null
        return
    endif

    set abilityId=ModernAbilityLoadout_GetEffectiveAbilityId(ModernAbilityActionBar__MAB_SelectedUnit , index + 1)
    if abilityId == ModernAbilityActionBar__MAB_SUMMON_ELEMENTAL then
        if ModernAbilityActionBar__MAB_ElementalOpen and ModernAbilityActionBar__MAB_ElementalHero == ModernAbilityActionBar__MAB_SelectedUnit then
            call ModernAbilityActionBar__MAB_CloseElementalFlyout()
        else
            call ModernAbilityActionBar__MAB_OpenElementalFlyout(ModernAbilityActionBar__MAB_SelectedUnit)
            call ModernAbilityActionBar__MAB_UpdateElementalFlyout()
        endif
    else
        call ModernAbilityActionBar__MAB_CloseElementalFlyout()
        call ModernAbilityController_BeginLocal(whichPlayer , ModernAbilityActionBar__MAB_SelectedUnit , index + 1)
    endif

    set whichPlayer=null
endfunction

function ModernAbilityActionBar__MAB_SlotAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()
    local player triggerPlayer= GetTriggerPlayer()
    local integer index= 0
    local integer slot
    local boolean rightClick

    if triggerPlayer == GetLocalPlayer() and ModernAbilityActionBar__MAB_IsPlayerHero(ModernAbilityActionBar__MAB_SelectedUnit) then
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            if triggerFrame == ModernAbilityActionBar__MAB_SlotButton[index] then
                set slot=index + 1
                set rightClick=BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT
                if rightClick then
                    call ModernAbilityController_CancelLocal(triggerPlayer)
                    call ModernAbilityActionBar__MAB_CloseElementalFlyout()
                    if BlzIsMetaKeyPressed(1) then
                        set ModernAbilityActionBar__MAB_MoveSourceSlot=0
                        if ModernAbilityActionBar__MAB_RebindSlot == slot then
                            set ModernAbilityActionBar__MAB_RebindSlot=0
                        else
                            set ModernAbilityActionBar__MAB_RebindSlot=slot
                        endif
                    elseif ModernAbilityActionBar__MAB_MoveSourceSlot == slot then
                        set ModernAbilityActionBar__MAB_MoveSourceSlot=0
                        set ModernAbilityActionBar__MAB_RebindSlot=0
                    else
                        set ModernAbilityActionBar__MAB_MoveSourceSlot=slot
                        set ModernAbilityActionBar__MAB_RebindSlot=0
                    endif
                elseif (0) > 0 then // INLINED!!
                    call ModernAbilityController_AssignSlotLocal(triggerPlayer , ModernAbilityActionBar__MAB_SelectedUnit , slot , (0)) // INLINED!!
                    call AbilitiesLiteUI_ClearModernPendingAbility()
                    set ModernAbilityActionBar__MAB_MoveSourceSlot=0
                    set ModernAbilityActionBar__MAB_RebindSlot=0
                elseif ModernAbilityActionBar__MAB_MoveSourceSlot > 0 then
                    call ModernAbilityController_SwapSlotsLocal(triggerPlayer , ModernAbilityActionBar__MAB_SelectedUnit , ModernAbilityActionBar__MAB_MoveSourceSlot , slot)
                    set ModernAbilityActionBar__MAB_MoveSourceSlot=0
                    set ModernAbilityActionBar__MAB_RebindSlot=0
                elseif ModernAbilityActionBar__MAB_CachedAbilityId[index] > 0 then
                    call ModernAbilityActionBar__MAB_ActivateSlotLocal(triggerPlayer , index)
                endif
                set index=ModernAbilityLoadout_SLOT_COUNT
            else
                set index=index + 1
            endif
        endloop
    endif

    set triggerFrame=null
    set triggerPlayer=null
endfunction

function ModernAbilityActionBar__MAB_GetKeySlot takes oskeytype whichKey returns integer
    local integer index= 0

    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        if ModernAbilityActionBar__MAB_SlotKey[index] == whichKey then
            return index
        endif
        set index=index + 1
    endloop
    return - 1
endfunction

function ModernAbilityActionBar__MAB_KeyAction takes nothing returns nothing
    local player triggerPlayer= GetTriggerPlayer()
    local oskeytype triggerKey= BlzGetTriggerPlayerKey()
    local integer slot= ModernAbilityActionBar__MAB_GetKeySlot(triggerKey)
    local integer previousSlot
    local oskeytype previousKey
    local string previousLabel

    if triggerPlayer == GetLocalPlayer() and ModernAbilityActionBar__MAB_RebindSlot > 0 then
        set previousSlot=slot
        set slot=ModernAbilityActionBar__MAB_RebindSlot - 1
        set previousKey=ModernAbilityActionBar__MAB_SlotKey[slot]
        set previousLabel=ModernAbilityActionBar__MAB_SlotKeyLabel[slot]
        set ModernAbilityActionBar__MAB_SlotKey[slot]=triggerKey
        set ModernAbilityActionBar__MAB_SlotKeyLabel[slot]=ModernAbilityActionBar__MAB_GetKeyLabel(triggerKey)
        call BlzFrameSetText(ModernAbilityActionBar__MAB_SlotKeyText[slot], ModernAbilityActionBar__MAB_SlotKeyLabel[slot])
        if previousSlot >= 0 and previousSlot != slot then
            set ModernAbilityActionBar__MAB_SlotKey[previousSlot]=previousKey
            set ModernAbilityActionBar__MAB_SlotKeyLabel[previousSlot]=previousLabel
            call BlzFrameSetText(ModernAbilityActionBar__MAB_SlotKeyText[previousSlot], previousLabel)
        endif
        set ModernAbilityActionBar__MAB_RebindSlot=0
        set previousKey=null
        set triggerKey=null
        set triggerPlayer=null
        return
    endif

    if triggerPlayer == GetLocalPlayer() and (0) > 0 and slot >= 0 then // INLINED!!
        call ModernAbilityController_AssignSlotLocal(triggerPlayer , ModernAbilityActionBar__MAB_SelectedUnit , slot + 1 , (0)) // INLINED!!
        call AbilitiesLiteUI_ClearModernPendingAbility()
        set triggerKey=null
        set triggerPlayer=null
        return
    endif

    if triggerPlayer == GetLocalPlayer() and ModernAbilityActionBar__MAB_Enabled and ModernAbilityActionBar__MAB_ParentVisible and not (false) and slot >= 0 then // INLINED!!
        call ModernAbilityActionBar__MAB_ActivateSlotLocal(triggerPlayer , slot)
    endif

    set triggerKey=null
    set triggerPlayer=null
endfunction

function ModernAbilityActionBar__MAB_ElementalAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()
    local player triggerPlayer= GetTriggerPlayer()
    local integer index= 0

    if triggerPlayer == GetLocalPlayer() and ModernAbilityActionBar__MAB_ElementalOpen and ModernAbilityActionBar__MAB_IsPlayerHero(ModernAbilityActionBar__MAB_ElementalHero) then
        loop
            exitwhen index >= ModernAbilityActionBar__MAB_ELEMENTAL_COUNT
            if triggerFrame == ModernAbilityActionBar__MAB_ElementalButton[index] then
                call ModernAbilityController_BeginElementalLocal(triggerPlayer , ModernAbilityActionBar__MAB_ElementalHero , ModernAbilityActionBar__MAB_GetElementalAbilityId(index))
                call ModernAbilityActionBar__MAB_CloseElementalFlyout()
                set index=ModernAbilityActionBar__MAB_ELEMENTAL_COUNT
            else
                set index=index + 1
            endif
        endloop
    endif

    set triggerFrame=null
    set triggerPlayer=null
endfunction

function ModernAbilityActionBar__MAB_ContextAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()
    local player triggerPlayer= GetTriggerPlayer()
    local integer index= 0

    if triggerPlayer == GetLocalPlayer() and ModernAbilityActionBar__MAB_IsPlayerHero(ModernAbilityActionBar__MAB_SelectedUnit) then
        loop
            exitwhen index >= ModernAbilityActionBar__MAB_CONTEXT_COUNT
            if triggerFrame == ModernAbilityActionBar__MAB_ContextButton[index] then
                call ModernAbilityActionBar__MAB_CloseElementalFlyout()
                call ModernAbilityController_CancelLocal(triggerPlayer)
                call ModernAbilityController_BeginContextLocal(triggerPlayer , ModernAbilityActionBar__MAB_SelectedUnit , ModernAbilityActionBar__MAB_ContextAbilityId[index])
                set index=ModernAbilityActionBar__MAB_CONTEXT_COUNT
            else
                set index=index + 1
            endif
        endloop
    endif

    set triggerPlayer=null
    set triggerFrame=null
endfunction

function ModernAbilityActionBar__MAB_HoverAction takes nothing returns nothing
    local framehandle triggerFrame= BlzGetTriggerFrame()
    local frameeventtype triggerEvent= BlzGetTriggerFrameEvent()
    local integer index= 0

    if GetTriggerPlayer() == GetLocalPlayer() then
        if triggerEvent == FRAMEEVENT_MOUSE_LEAVE then
            call ModernAbilityActionBar__MAB_CloseTooltip()
            set triggerEvent=null
            set triggerFrame=null
            return
        endif
        loop
            exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
            if triggerFrame == ModernAbilityActionBar__MAB_SlotButton[index] then
                if ModernAbilityActionBar__MAB_CachedAbilityId[index] > 0 then
                    if ModernAbilityActionBar__MAB_CachedReady[index] then
                        call BlzFrameSetText(ModernAbilityActionBar__MAB_TooltipTitle, "|cffffcc00" + ModernAbilityActionBar__MAB_CachedTitle[index] + "|r")
                    else
                        call BlzFrameSetText(ModernAbilityActionBar__MAB_TooltipTitle, "|cffff5555" + ModernAbilityActionBar__MAB_CachedTitle[index] + "|r")
                    endif
                    call BlzFrameSetText(ModernAbilityActionBar__MAB_TooltipBody, ModernAbilityActionBar__MAB_CachedBody[index])
                else
                    call BlzFrameSetText(ModernAbilityActionBar__MAB_TooltipTitle, "|cffaaaaaaEmpty slot|r")
                    call BlzFrameSetText(ModernAbilityActionBar__MAB_TooltipBody, "Choose a learned ability from the Abilities book.")
                endif
                call BlzFrameSetVisible(ModernAbilityActionBar__MAB_Tooltip, true)
                set index=ModernAbilityLoadout_SLOT_COUNT
            else
                set index=index + 1
            endif
        endloop
    endif

    set triggerEvent=null
    set triggerFrame=null
endfunction

function ModernAbilityActionBar__MAB_CreateTooltip takes nothing returns nothing
    set ModernAbilityActionBar__MAB_Tooltip=BlzCreateFrameByType("BACKDROP", "ModernAbilityTooltip", ModernAbilityActionBar__MAB_ScreenParent, "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_Tooltip, FRAMEPOINT_BOTTOM, 0.400, 0.130)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_Tooltip, ModernAbilityActionBar__MAB_TOOLTIP_WIDTH, ModernAbilityActionBar__MAB_TOOLTIP_HEIGHT)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_Tooltip, false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_Tooltip, 40)

    set ModernAbilityActionBar__MAB_TooltipTitle=BlzCreateFrameByType("TEXT", "ModernAbilityTooltipTitle", ModernAbilityActionBar__MAB_Tooltip, "", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_TooltipTitle, FRAMEPOINT_TOPLEFT, ModernAbilityActionBar__MAB_Tooltip, FRAMEPOINT_TOPLEFT, 0.010, - 0.010)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_TooltipTitle, ModernAbilityActionBar__MAB_TOOLTIP_WIDTH - 0.020, 0.016)
    call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_TooltipTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(ModernAbilityActionBar__MAB_TooltipTitle, 0.86)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_TooltipTitle, false)

    set ModernAbilityActionBar__MAB_TooltipBody=BlzCreateFrameByType("TEXT", "ModernAbilityTooltipBody", ModernAbilityActionBar__MAB_Tooltip, "", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_TooltipBody, FRAMEPOINT_TOPLEFT, ModernAbilityActionBar__MAB_TooltipTitle, FRAMEPOINT_BOTTOMLEFT, 0.000, - 0.006)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_TooltipBody, ModernAbilityActionBar__MAB_TOOLTIP_WIDTH - 0.020, ModernAbilityActionBar__MAB_TOOLTIP_HEIGHT - 0.036)
    call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_TooltipBody, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(ModernAbilityActionBar__MAB_TooltipBody, 0.72)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_TooltipBody, false)
    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_Tooltip, false)
endfunction

function ModernAbilityActionBar__MAB_CreateSlot takes integer index returns nothing
    local real x= ModernAbilityActionBar__MAB_ACTION_START_X + I2R(index) * ( ModernAbilityActionBar__MAB_ACTION_SIZE + ModernAbilityActionBar__MAB_ACTION_GAP )

    set ModernAbilityActionBar__MAB_SlotButton[index]=BlzCreateFrameByType("BUTTON", "ModernAbilityActionButton" + I2S(index), ModernAbilityActionBar__MAB_Parent, "", 0)
    call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_SlotButton[index], FRAMEPOINT_BOTTOMLEFT, x, ModernAbilityActionBar__MAB_ACTION_BOTTOM)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_SlotButton[index], ModernAbilityActionBar__MAB_ACTION_SIZE, ModernAbilityActionBar__MAB_ACTION_SIZE)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_SlotButton[index], 4)

    set ModernAbilityActionBar__MAB_SlotIcon[index]=BlzCreateFrameByType("BACKDROP", "ModernAbilityActionIcon" + I2S(index), ModernAbilityActionBar__MAB_SlotButton[index], "", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_SlotIcon[index], FRAMEPOINT_BOTTOMLEFT, ModernAbilityActionBar__MAB_SlotButton[index], FRAMEPOINT_BOTTOMLEFT, 0.002, 0.002)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_SlotIcon[index], FRAMEPOINT_TOPRIGHT, ModernAbilityActionBar__MAB_SlotButton[index], FRAMEPOINT_TOPRIGHT, - 0.002, - 0.002)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_SlotIcon[index], false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_SlotIcon[index], 5)

    set ModernAbilityActionBar__MAB_SlotCooldown[index]=BlzCreateFrameByType("BACKDROP", "ModernAbilityCooldown" + I2S(index), ModernAbilityActionBar__MAB_SlotButton[index], "", 0)
    call BlzFrameSetTexture(ModernAbilityActionBar__MAB_SlotCooldown[index], ModernAbilityActionBar__MAB_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_SlotCooldown[index], FRAMEPOINT_BOTTOM, ModernAbilityActionBar__MAB_SlotIcon[index], FRAMEPOINT_BOTTOM, 0.000, 0.000)
    call BlzFrameSetVertexColor(ModernAbilityActionBar__MAB_SlotCooldown[index], BlzConvertColor(190, 0, 0, 0))
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_SlotCooldown[index], false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_SlotCooldown[index], 6)

    set ModernAbilityActionBar__MAB_SlotDisabled[index]=BlzCreateFrameByType("BACKDROP", "ModernAbilityDisabled" + I2S(index), ModernAbilityActionBar__MAB_SlotButton[index], "", 0)
    call BlzFrameSetTexture(ModernAbilityActionBar__MAB_SlotDisabled[index], ModernAbilityActionBar__MAB_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetAllPoints(ModernAbilityActionBar__MAB_SlotDisabled[index], ModernAbilityActionBar__MAB_SlotIcon[index])
    call BlzFrameSetVertexColor(ModernAbilityActionBar__MAB_SlotDisabled[index], BlzConvertColor(150, 30, 30, 30))
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_SlotDisabled[index], false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_SlotDisabled[index], 7)

    set ModernAbilityActionBar__MAB_SlotCooldownText[index]=BlzCreateFrameByType("TEXT", "ModernAbilityCooldownText" + I2S(index), ModernAbilityActionBar__MAB_SlotButton[index], "", 0)
    call BlzFrameSetAllPoints(ModernAbilityActionBar__MAB_SlotCooldownText[index], ModernAbilityActionBar__MAB_SlotButton[index])
    call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_SlotCooldownText[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernAbilityActionBar__MAB_SlotCooldownText[index], 0.82)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_SlotCooldownText[index], false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_SlotCooldownText[index], 8)

    set ModernAbilityActionBar__MAB_SlotKeyText[index]=BlzCreateFrameByType("TEXT", "ModernAbilityKeyText" + I2S(index), ModernAbilityActionBar__MAB_SlotButton[index], "", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_SlotKeyText[index], FRAMEPOINT_TOPLEFT, ModernAbilityActionBar__MAB_SlotButton[index], FRAMEPOINT_TOPLEFT, 0.003, - 0.002)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_SlotKeyText[index], 0.012, 0.010)
    call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_SlotKeyText[index], TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(ModernAbilityActionBar__MAB_SlotKeyText[index], 0.60)
        call BlzFrameSetText(ModernAbilityActionBar__MAB_SlotKeyText[index], ModernAbilityActionBar__MAB_SlotKeyLabel[index])
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_SlotKeyText[index], false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_SlotKeyText[index], 9)

    call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_SlotTrigger, ModernAbilityActionBar__MAB_SlotButton[index], FRAMEEVENT_MOUSE_DOWN)
    call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_ClearFocusTrigger, ModernAbilityActionBar__MAB_SlotButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_HoverTrigger, ModernAbilityActionBar__MAB_SlotButton[index], FRAMEEVENT_MOUSE_ENTER)
    call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_HoverTrigger, ModernAbilityActionBar__MAB_SlotButton[index], FRAMEEVENT_MOUSE_LEAVE)
endfunction

function ModernAbilityActionBar__MAB_CreateElementalFlyout takes nothing returns nothing
    local integer index= 0
    local integer abilityId
    local real x
    local string iconPath

    set ModernAbilityActionBar__MAB_ElementalBackdrop=BlzCreateFrameByType("BACKDROP", "ModernElementalFlyoutBackdrop", ModernAbilityActionBar__MAB_Parent, "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_ElementalBackdrop, FRAMEPOINT_BOTTOMLEFT, 0.304, 0.115)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_ElementalBackdrop, 0.192, 0.064)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ElementalBackdrop, 34)

    set ModernAbilityActionBar__MAB_ElementalTitle=BlzCreateFrameByType("TEXT", "ModernElementalFlyoutTitle", ModernAbilityActionBar__MAB_ElementalBackdrop, "", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_ElementalTitle, FRAMEPOINT_TOP, ModernAbilityActionBar__MAB_ElementalBackdrop, FRAMEPOINT_TOP, 0.000, - 0.005)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_ElementalTitle, 0.160, 0.012)
    call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_ElementalTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernAbilityActionBar__MAB_ElementalTitle, 0.72)
    call BlzFrameSetText(ModernAbilityActionBar__MAB_ElementalTitle, "Choose Elemental")
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ElementalTitle, false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ElementalTitle, 35)

    loop
        exitwhen index >= ModernAbilityActionBar__MAB_ELEMENTAL_COUNT
        set abilityId=ModernAbilityActionBar__MAB_GetElementalAbilityId(index)
        set x=ModernAbilityActionBar__MAB_ELEMENTAL_START_X + I2R(index) * ( ModernAbilityActionBar__MAB_ELEMENTAL_SIZE + ModernAbilityActionBar__MAB_ELEMENTAL_GAP )
        set iconPath=ModernAbilityActionBar__MAB_GetAbilityIconPath(abilityId)

        set ModernAbilityActionBar__MAB_ElementalButton[index]=BlzCreateFrameByType("GLUEBUTTON", "ModernElementalFlyoutButton" + I2S(index), ModernAbilityActionBar__MAB_ElementalBackdrop, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_ElementalButton[index], FRAMEPOINT_BOTTOMLEFT, x, ModernAbilityActionBar__MAB_ELEMENTAL_BOTTOM)
        call BlzFrameSetSize(ModernAbilityActionBar__MAB_ElementalButton[index], ModernAbilityActionBar__MAB_ELEMENTAL_SIZE, ModernAbilityActionBar__MAB_ELEMENTAL_SIZE)
        call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ElementalButton[index], 36)

        set ModernAbilityActionBar__MAB_ElementalIcon[index]=BlzCreateFrameByType("BACKDROP", "ModernElementalFlyoutIcon" + I2S(index), ModernAbilityActionBar__MAB_ElementalButton[index], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(ModernAbilityActionBar__MAB_ElementalIcon[index], FRAMEPOINT_BOTTOMLEFT, ModernAbilityActionBar__MAB_ElementalButton[index], FRAMEPOINT_BOTTOMLEFT, 0.002, 0.002)
        call BlzFrameSetPoint(ModernAbilityActionBar__MAB_ElementalIcon[index], FRAMEPOINT_TOPRIGHT, ModernAbilityActionBar__MAB_ElementalButton[index], FRAMEPOINT_TOPRIGHT, - 0.002, - 0.002)
        call BlzFrameSetTexture(ModernAbilityActionBar__MAB_ElementalIcon[index], iconPath, 0, true)
        call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ElementalIcon[index], false)
        call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ElementalIcon[index], 37)

        set ModernAbilityActionBar__MAB_ElementalDisabled[index]=BlzCreateFrameByType("BACKDROP", "ModernElementalFlyoutDisabled" + I2S(index), ModernAbilityActionBar__MAB_ElementalButton[index], "", 0)
        call BlzFrameSetTexture(ModernAbilityActionBar__MAB_ElementalDisabled[index], ModernAbilityActionBar__MAB_SURFACE_TEXTURE, 0, false)
        call BlzFrameSetAllPoints(ModernAbilityActionBar__MAB_ElementalDisabled[index], ModernAbilityActionBar__MAB_ElementalIcon[index])
        call BlzFrameSetVertexColor(ModernAbilityActionBar__MAB_ElementalDisabled[index], BlzConvertColor(160, 25, 25, 25))
        call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ElementalDisabled[index], false)
        call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ElementalDisabled[index], 38)
        call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ElementalButton[index], false)
        call BlzFrameSetVisible(ModernAbilityActionBar__MAB_ElementalDisabled[index], true)
        set ModernAbilityActionBar__MAB_ElementalReady[index]=false

        set ModernAbilityActionBar__MAB_ElementalLabel[index]=BlzCreateFrameByType("TEXT", "ModernElementalFlyoutLabel" + I2S(index), ModernAbilityActionBar__MAB_ElementalButton[index], "", 0)
        call BlzFrameSetPoint(ModernAbilityActionBar__MAB_ElementalLabel[index], FRAMEPOINT_BOTTOM, ModernAbilityActionBar__MAB_ElementalButton[index], FRAMEPOINT_BOTTOM, 0.000, 0.002)
        call BlzFrameSetSize(ModernAbilityActionBar__MAB_ElementalLabel[index], ModernAbilityActionBar__MAB_ELEMENTAL_SIZE - 0.004, 0.010)
        call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_ElementalLabel[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(ModernAbilityActionBar__MAB_ElementalLabel[index], 0.58)
        call BlzFrameSetText(ModernAbilityActionBar__MAB_ElementalLabel[index], ModernAbilityActionBar__MAB_GetElementalLabel(index))
        call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ElementalLabel[index], false)
        call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ElementalLabel[index], 39)

        call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_ElementalTrigger, ModernAbilityActionBar__MAB_ElementalButton[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_ClearFocusTrigger, ModernAbilityActionBar__MAB_ElementalButton[index], FRAMEEVENT_CONTROL_CLICK)
        set index=index + 1
    endloop

    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_ElementalBackdrop, false)
endfunction

function ModernAbilityActionBar__MAB_CreateContextSlot takes integer index,real x,string label returns nothing
    set ModernAbilityActionBar__MAB_ContextButton[index]=BlzCreateFrameByType("BUTTON", "ModernAbilityContextButton" + I2S(index), ModernAbilityActionBar__MAB_Parent, "", 0)
    call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_ContextButton[index], FRAMEPOINT_BOTTOMLEFT, x, 0.075)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_ContextButton[index], 0.028, 0.028)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ContextButton[index], 14)

    set ModernAbilityActionBar__MAB_ContextIcon[index]=BlzCreateFrameByType("BACKDROP", "ModernAbilityContextIcon" + I2S(index), ModernAbilityActionBar__MAB_ContextButton[index], "IconButtonTemplate", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_ContextIcon[index], FRAMEPOINT_BOTTOMLEFT, ModernAbilityActionBar__MAB_ContextButton[index], FRAMEPOINT_BOTTOMLEFT, 0.002, 0.002)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_ContextIcon[index], FRAMEPOINT_TOPRIGHT, ModernAbilityActionBar__MAB_ContextButton[index], FRAMEPOINT_TOPRIGHT, - 0.002, - 0.002)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ContextIcon[index], false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ContextIcon[index], 15)

    set ModernAbilityActionBar__MAB_ContextLabel[index]=BlzCreateFrameByType("TEXT", "ModernAbilityContextLabel" + I2S(index), ModernAbilityActionBar__MAB_ContextButton[index], "", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_ContextLabel[index], FRAMEPOINT_BOTTOMRIGHT, ModernAbilityActionBar__MAB_ContextButton[index], FRAMEPOINT_BOTTOMRIGHT, - 0.002, 0.001)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_ContextLabel[index], 0.016, 0.009)
    call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_ContextLabel[index], TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_RIGHT)
    call BlzFrameSetScale(ModernAbilityActionBar__MAB_ContextLabel[index], 0.48)
    call BlzFrameSetText(ModernAbilityActionBar__MAB_ContextLabel[index], label)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_ContextLabel[index], false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_ContextLabel[index], 16)

    call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_ContextTrigger, ModernAbilityActionBar__MAB_ContextButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(ModernAbilityActionBar__MAB_ClearFocusTrigger, ModernAbilityActionBar__MAB_ContextButton[index], FRAMEEVENT_CONTROL_CLICK)
    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_ContextButton[index], false)
endfunction

function ModernAbilityActionBar__MAB_CreateFrames takes nothing returns nothing
    local integer index= 0

    if ModernAbilityActionBar__MAB_FramesCreated then
        return
    endif
    set ModernAbilityActionBar__MAB_FramesCreated=true
    set ModernAbilityActionBar__MAB_ScreenParent=BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    set ModernAbilityActionBar__MAB_Parent=BlzCreateFrameByType("FRAME", "ModernAbilityActionBar", ModernAbilityActionBar__MAB_ScreenParent, "", 0)
    // Full-screen FRAME parents consume mouse input even without a texture.
    // Children use absolute points, so keep this logical parent effectively empty.
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_Parent, 0.0001, 0.0001)
    call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_Parent, FRAMEPOINT_BOTTOMLEFT, 0.000, 0.000)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_Parent, 30)

    set ModernAbilityActionBar__MAB_HeroBorder=BlzCreateFrameByType("BACKDROP", "ModernAbilityHeroBorder", ModernAbilityActionBar__MAB_Parent, "", 0)
    call BlzFrameSetTexture(ModernAbilityActionBar__MAB_HeroBorder, ModernAbilityActionBar__MAB_MEDALLION_TEXTURE, 0, true)
    call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_HeroBorder, FRAMEPOINT_BOTTOMLEFT, 0.132, 0.010)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_HeroBorder, 0.056, 0.056)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_HeroBorder, false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_HeroBorder, 4)

    set ModernAbilityActionBar__MAB_HeroIcon=BlzCreateFrameByType("BACKDROP", "ModernAbilityHeroIcon", ModernAbilityActionBar__MAB_HeroBorder, "", 0)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_HeroIcon, FRAMEPOINT_BOTTOMLEFT, ModernAbilityActionBar__MAB_HeroBorder, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)
    call BlzFrameSetPoint(ModernAbilityActionBar__MAB_HeroIcon, FRAMEPOINT_TOPRIGHT, ModernAbilityActionBar__MAB_HeroBorder, FRAMEPOINT_TOPRIGHT, - 0.006, - 0.006)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_HeroIcon, false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_HeroIcon, 5)

    call ModernAbilityActionBar__MAB_CreateTooltip()
    loop
        exitwhen index >= ModernAbilityLoadout_SLOT_COUNT
        call ModernAbilityActionBar__MAB_CreateSlot(index)
        set index=index + 1
    endloop
    call ModernAbilityActionBar__MAB_CreateElementalFlyout()
    call ModernAbilityActionBar__MAB_CreateContextSlot(0 , 0.128 , "Stealth")
    call ModernAbilityActionBar__MAB_CreateContextSlot(1 , 0.158 , "Block")

    set ModernAbilityActionBar__MAB_TargetingText=BlzCreateFrameByType("TEXT", "ModernAbilityTargetingText", ModernAbilityActionBar__MAB_Parent, "", 0)
    call BlzFrameSetAbsPoint(ModernAbilityActionBar__MAB_TargetingText, FRAMEPOINT_BOTTOM, 0.400, 0.151)
    call BlzFrameSetSize(ModernAbilityActionBar__MAB_TargetingText, 0.420, 0.016)
    call BlzFrameSetTextAlignment(ModernAbilityActionBar__MAB_TargetingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(ModernAbilityActionBar__MAB_TargetingText, 0.78)
    call BlzFrameSetEnable(ModernAbilityActionBar__MAB_TargetingText, false)
    call BlzFrameSetLevel(ModernAbilityActionBar__MAB_TargetingText, 12)
    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_TargetingText, false)
    call BlzFrameSetVisible(ModernAbilityActionBar__MAB_Parent, false)
endfunction

function ModernAbilityActionBar_Refresh takes nothing returns nothing
    call ModernAbilityLoadout_RefreshDefaults(ModernAbilityActionBar__MAB_SelectedUnit)
    set ModernAbilityActionBar__MAB_StaticDirty=true
    call ModernAbilityActionBar__MAB_Update()
endfunction

function ModernAbilityActionBar_Enable takes nothing returns nothing
    if not ModernAbilityActionBar__MAB_Initialized then
        return
    endif
    if not ModernAbilityActionBar__MAB_FramesCreated then
        call ModernAbilityActionBar__MAB_CreateFrames()
    endif
    set ModernAbilityActionBar__MAB_Enabled=true
    set ModernAbilityActionBar__MAB_WasFullscreen=false
    call ModernAbilityActionBar__MAB_ResetSlotCache()
    call ModernAbilityActionBar__MAB_Update()
endfunction

function ModernAbilityActionBar_Disable takes nothing returns nothing
    set ModernAbilityActionBar__MAB_Enabled=false
    call ModernAbilityController_CancelLocal(GetLocalPlayer())
    call ModernAbilityActionBar__MAB_CloseElementalFlyout()
    call ModernAbilityActionBar__MAB_SetParentVisible(false)
    call ModernAbilityActionBar__MAB_ResetSlotCache()
    call ModernAbilityActionBar__MAB_RestoreNativeFrames()
endfunction

function ModernAbilityActionBar_IsEnabled takes nothing returns boolean
    return ModernAbilityActionBar__MAB_Enabled
endfunction

function ModernAbilityActionBar__MAB_OnUnitSelected takes nothing returns nothing
    local unit selectedUnit= GetTriggerUnit()
    local player selectingPlayer= GetTriggerPlayer()

    if selectingPlayer == GetLocalPlayer() and ModernAbilityActionBar__MAB_IsPlayerHero(selectedUnit) then
        if ModernAbilityActionBar__MAB_ElementalHero != null and ModernAbilityActionBar__MAB_ElementalHero != selectedUnit then
            call ModernAbilityActionBar__MAB_CloseElementalFlyout()
        endif
        set ModernAbilityActionBar__MAB_SelectedUnit=selectedUnit
        call ModernAbilityActionBar__MAB_ResetSlotCache()
    endif
    set selectedUnit=null
    set selectingPlayer=null
endfunction

function ModernAbilityActionBar__MAB_OnUnitDeselected takes nothing returns nothing
    local unit deselectedUnit= GetTriggerUnit()
    local player deselectingPlayer= GetTriggerPlayer()

    // Keep the last player hero as the HUD subject while the player selects a
    // world target or an inspect target.
    set deselectedUnit=null
    set deselectingPlayer=null
endfunction

function ModernAbilityActionBar__MAB_OnHeroSkill takes nothing returns nothing
    local unit whichHero= GetTriggerUnit()

    if whichHero == ModernAbilityActionBar__MAB_SelectedUnit then
        call ModernAbilityActionBar_Refresh()
    endif
    set whichHero=null
endfunction

function ModernAbilityActionBar__MAB_OnSpellEffect takes nothing returns nothing
    local unit caster= GetTriggerUnit()
    local integer abilityId= GetSpellAbilityId()
    local integer slot
    local integer index

    if caster == ModernAbilityActionBar__MAB_CachedHero and ModernAbilityActionBar__MAB_Enabled then
        if ModernAbilityActionBar__MAB_IsElementalChoice(abilityId) then
            set abilityId=ModernAbilityActionBar__MAB_SUMMON_ELEMENTAL
        endif
        set slot=ModernAbilityLoadout_FindSlot(caster , abilityId)
        if slot > 0 then
            set index=slot - 1
            set ModernAbilityActionBar__MAB_CooldownActive[index]=true
        endif
    endif

    set caster=null
endfunction

function ModernAbilityActionBar__MAB_DelayedInit takes nothing returns nothing
    call ModernAbilityActionBar__MAB_CreateFrames()
    if ModernAbilityActionBar__MAB_AUTO_ENABLE then
        call ModernAbilityActionBar_Enable()
    endif
    call DestroyTrigger(ModernAbilityActionBar__MAB_InitTrigger)
    set ModernAbilityActionBar__MAB_InitTrigger=null
endfunction

function ModernAbilityActionBar__Init takes nothing returns nothing
    local integer keyIndex= 0
    local oskeytype array actionKey

    if ModernAbilityActionBar__MAB_Initialized then
        return
    endif
    set ModernAbilityActionBar__MAB_Initialized=true

    set ModernAbilityActionBar__MAB_SlotTrigger=CreateTrigger()
    call TriggerAddAction(ModernAbilityActionBar__MAB_SlotTrigger, function ModernAbilityActionBar__MAB_SlotAction)
    set ModernAbilityActionBar__MAB_ElementalTrigger=CreateTrigger()
    call TriggerAddAction(ModernAbilityActionBar__MAB_ElementalTrigger, function ModernAbilityActionBar__MAB_ElementalAction)
    set ModernAbilityActionBar__MAB_ContextTrigger=CreateTrigger()
    call TriggerAddAction(ModernAbilityActionBar__MAB_ContextTrigger, function ModernAbilityActionBar__MAB_ContextAction)
    set ModernAbilityActionBar__MAB_ClearFocusTrigger=CreateTrigger()
    call TriggerAddAction(ModernAbilityActionBar__MAB_ClearFocusTrigger, function ModernAbilityActionBar__MAB_ClearFocusAction)
    set ModernAbilityActionBar__MAB_HoverTrigger=CreateTrigger()
    call TriggerAddAction(ModernAbilityActionBar__MAB_HoverTrigger, function ModernAbilityActionBar__MAB_HoverAction)
    set actionKey[0]=OSKEY_1
    set actionKey[1]=OSKEY_2
    set actionKey[2]=OSKEY_3
    set actionKey[3]=OSKEY_4
    set actionKey[4]=OSKEY_5
    set actionKey[5]=OSKEY_6
    set actionKey[6]=OSKEY_7
    set actionKey[7]=OSKEY_8
    set actionKey[8]=OSKEY_9
    set actionKey[9]=OSKEY_0
    set actionKey[10]=OSKEY_OEM_MINUS
    set actionKey[11]=OSKEY_OEM_PLUS
    set ModernAbilityActionBar__MAB_KeyTrigger=CreateTrigger()
    loop
        exitwhen keyIndex >= ModernAbilityLoadout_SLOT_COUNT
        set ModernAbilityActionBar__MAB_SlotKey[keyIndex]=actionKey[keyIndex]
        set ModernAbilityActionBar__MAB_SlotKeyLabel[keyIndex]=ModernAbilityActionBar__MAB_GetSlotLabel(keyIndex + 1)
        call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), actionKey[keyIndex], 0, true)
        set actionKey[keyIndex]=null
        set keyIndex=keyIndex + 1
    endloop
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_Q, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_W, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_E, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_R, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_A, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_S, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_D, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_F, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_Z, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_X, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_C, 0, true)
    call BlzTriggerRegisterPlayerKeyEvent(ModernAbilityActionBar__MAB_KeyTrigger, Player(0), OSKEY_V, 0, true)
    call TriggerAddAction(ModernAbilityActionBar__MAB_KeyTrigger, function ModernAbilityActionBar__MAB_KeyAction)
    set ModernAbilityActionBar__MAB_InitTrigger=CreateTrigger()
    call TriggerRegisterTimerEvent(ModernAbilityActionBar__MAB_InitTrigger, 0.25, false)
    call TriggerAddAction(ModernAbilityActionBar__MAB_InitTrigger, function ModernAbilityActionBar__MAB_DelayedInit)
    call Events_RegisterPlayerUnitEvent(function ModernAbilityActionBar__MAB_OnUnitSelected , EVENT_PLAYER_UNIT_SELECTED)
    call Events_RegisterPlayerUnitEvent(function ModernAbilityActionBar__MAB_OnUnitDeselected , EVENT_PLAYER_UNIT_DESELECTED)
    call Events_RegisterPlayerUnitEvent(function ModernAbilityActionBar__MAB_OnHeroSkill , EVENT_PLAYER_HERO_SKILL)
    call Events_RegisterSpellEffect(function ModernAbilityActionBar__MAB_OnSpellEffect)
    call TriggerAddAction(ModernPlayerHUD__MHUD_UpdateTrigger, (function ModernAbilityActionBar__MAB_Update)) // INLINED!!
endfunction


//library ModernAbilityActionBar ends












// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityCatalog.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityCatalog.j
// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityLoadout.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityLoadout.j
// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityTargeting.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityTargeting.j
// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityController.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityController.j
// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernPlayerHUD.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernPlayerHUD.j
// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernMinimapHUD.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernMinimapHUD.j
// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityActionBar.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernAbilityActionBar.j
// BEGIN IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernTotemTracker.j


// END IMPORT OF H:\Pelit\PotS_JASS\UI\_Modern\ModernTotemTracker.j

function config takes nothing returns nothing
endfunction

function main takes nothing returns nothing

call ExecuteFunc("ModernAbilityCatalog__Init")
call ExecuteFunc("ModernPlayerHUD__Init")
call ExecuteFunc("ModernMinimapHUD__Init")
call ExecuteFunc("ModernTotemTracker___Init")
call ExecuteFunc("ModernAbilityController__Init")
call ExecuteFunc("ModernAbilityActionBar__Init")

endfunction



//Struct method generated initializers/callers:

