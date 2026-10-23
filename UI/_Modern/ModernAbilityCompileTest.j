/**
    ModernAbilityCompileTest

    Description:
    Compile-only dependency contracts for the modern ability HUD modules.

    Credits:
    - None

    How to install:
    Never import this file into the production map. Run it only through the
    repository JassHelper validation command.

    API:
    - None; config/main exist only as compiler entry points.
**/
globals
    unit udg_Nazgrek = null
    unit udg_Zulkis = null
    unit udg_Shadowclaw = null
    unit udg_TamedUnit = null
    unit array udg_UDexUnits
endglobals

//! import "../WidescreenFrameRoot.j"

library AbilitiesPlayer
    globals
        public constant integer ENTRY_ABILITY = 1
    endglobals
    public function EnsureInitialized takes nothing returns nothing
    endfunction
    public function GetEntryCount takes nothing returns integer
        return 0
    endfunction
    public function GetEntryKind takes integer entryIndex returns integer
        return ENTRY_ABILITY
    endfunction
    public function GetEntryAbilityId takes integer entryIndex returns integer
        return 0
    endfunction
    public function GetEntryAddAbilityId takes integer entryIndex returns integer
        return 0
    endfunction
    public function GetEntryByAbilityId takes integer abilityId returns integer
        return 0
    endfunction
    public function GetEntryTitle takes integer entryIndex returns string
        return ""
    endfunction
    public function GetEntryBodyForLevel takes integer entryIndex, integer abilityLevel returns string
        return ""
    endfunction
endlibrary

library ShamanCommon
    globals
        public constant integer HERO_SLOT_NONE = 0
        public constant integer HERO_SLOT_NAZGREK = 1
        public constant integer HERO_SLOT_ZULKIS = 2
    endglobals
    public function IsAlive takes unit whichUnit returns boolean
        set whichUnit = null
        return true
    endfunction
    public function IsPlayerHero takes unit whichUnit returns boolean
        set whichUnit = null
        return true
    endfunction
    public function GetHeroSlot takes unit whichUnit returns integer
        set whichUnit = null
        return HERO_SLOT_NAZGREK
    endfunction
    public function GetHeroBySlot takes integer heroSlot returns unit
        return udg_Nazgrek
    endfunction
endlibrary

library Totems
    globals
        public constant integer SLOT_EARTH = 1
        public constant integer SLOT_FIRE = 2
        public constant integer SLOT_WATER = 3
        public constant integer SLOT_WIND = 4
    endglobals
    public function GetLiveTotemForSlot takes unit caster, integer slot returns unit
        set caster = null
        return null
    endfunction
    public function GetRemainingDuration takes unit totem returns real
        set totem = null
        return 0.00
    endfunction
    public function GetTotalDuration takes unit totem returns real
        set totem = null
        return 0.00
    endfunction
endlibrary

library Events
    function Events_RegisterPlayerUnitEvent takes code callback, playerunitevent whichEvent returns nothing
    endfunction
    function Events_RegisterSpellEffect takes code callback returns nothing
    endfunction
endlibrary

library FullscreenUI
    public function IsEnabled takes nothing returns boolean
        return false
    endfunction
endlibrary

library DynamicMinimap
    function DynamicMinimap_GetMinimapEnlarged takes nothing returns boolean
        return false
    endfunction
    function DynamicMinimap_SetVisible takes boolean visible returns nothing
    endfunction
    function DynamicMinimap_SuppressNextSizeToggle takes nothing returns nothing
    endfunction
endlibrary

library Companions
    function Companions_GetControlledDisplayCount takes nothing returns integer
        return 0
    endfunction
    function Companions_GetControlledDisplayUnit takes integer index returns unit
        return null
    endfunction
    function Companions_IsControlled takes unit whichUnit returns boolean
        set whichUnit = null
        return false
    endfunction
endlibrary

library DInventory
    function DInvToggleUnitForPlayer takes player viewer, unit whichUnit, boolean inspectMode returns boolean
        set viewer = null
        set whichUnit = null
        return true
    endfunction
    function DInvShowUnitForPlayer takes player viewer, unit whichUnit, boolean inspectMode returns boolean
        set viewer = null
        set whichUnit = null
        return true
    endfunction
    function DInvIsPlayerInspecting takes integer playerId returns boolean
        return false
    endfunction
endlibrary

library DEquipment
    function ToggleDEqUIForUnit takes integer playerId, unit whichUnit returns boolean
        set whichUnit = null
        return true
    endfunction
    function DInspectResolveSelectedTarget takes player viewer returns unit
        set viewer = null
        return null
    endfunction
    function DEqShowUnitForPlayer takes player viewer, unit whichUnit, boolean inspectMode returns boolean
        set viewer = null
        set whichUnit = null
        return true
    endfunction
    function DInventoryEquipment_HideForPlayer takes player viewer returns nothing
        set viewer = null
    endfunction
    function DInspectSetExternalButtonForPlayer takes player viewer, boolean externalButton returns nothing
        set viewer = null
    endfunction
endlibrary

library MasterUI
    public function ClosePanels takes nothing returns nothing
    endfunction
endlibrary

library AbilitiesLiteUI
    public function ShowForUnit takes unit whichUnit returns nothing
        set whichUnit = null
    endfunction
    public function GetModernPendingAbilityId takes nothing returns integer
        return 0
    endfunction
    public function ClearModernPendingAbility takes nothing returns nothing
    endfunction
endlibrary

library TalentsUI
    public function ShowForUnit takes unit whichUnit returns nothing
        set whichUnit = null
    endfunction
endlibrary

library StatsUI
    public function Show takes nothing returns nothing
    endfunction
    public function Hide takes nothing returns nothing
    endfunction
    public function IsVisible takes nothing returns boolean
        return false
    endfunction
endlibrary

library StatsLiteUI
    public function Toggle takes nothing returns nothing
    endfunction
    public function IsVisible takes nothing returns boolean
        return false
    endfunction
endlibrary

library TargetUnitUI
    public function Toggle takes nothing returns nothing
    endfunction
    public function IsVisible takes nothing returns boolean
        return false
    endfunction
endlibrary

//! import "ModernAbilityCatalog.j"
//! import "ModernAbilityLoadout.j"
//! import "ModernAbilityTargeting.j"
//! import "ModernAbilityController.j"
//! import "ModernPlayerHUD.j"
//! import "ModernMinimapHUD.j"
//! import "ModernShortcutRail.j"
//! import "ModernAbilityActionBar.j"
//! import "ModernTotemTracker.j"

function config takes nothing returns nothing
endfunction

function main takes nothing returns nothing
endfunction
