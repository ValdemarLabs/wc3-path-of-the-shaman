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
endglobals

library AbilitiesPlayer
    globals
        constant integer ENTRY_ABILITY = 1
    endglobals
    function EnsureInitialized takes nothing returns nothing
    endfunction
    function GetEntryCount takes nothing returns integer
        return 0
    endfunction
    function GetEntryKind takes integer entryIndex returns integer
        return ENTRY_ABILITY
    endfunction
    function GetEntryAbilityId takes integer entryIndex returns integer
        return 0
    endfunction
    function GetEntryByAbilityId takes integer abilityId returns integer
        return 0
    endfunction
    function GetEntryTitle takes integer entryIndex returns string
        return ""
    endfunction
    function GetEntryBodyForLevel takes integer entryIndex, integer abilityLevel returns string
        return ""
    endfunction
endlibrary

library ShamanCommon
    globals
        constant integer HERO_SLOT_NONE = 0
        constant integer HERO_SLOT_NAZGREK = 1
        constant integer HERO_SLOT_ZULKIS = 2
    endglobals
    function IsAlive takes unit whichUnit returns boolean
        set whichUnit = null
        return true
    endfunction
    function IsPlayerHero takes unit whichUnit returns boolean
        set whichUnit = null
        return true
    endfunction
    function GetHeroSlot takes unit whichUnit returns integer
        set whichUnit = null
        return HERO_SLOT_NAZGREK
    endfunction
    function GetHeroBySlot takes integer heroSlot returns unit
        return udg_Nazgrek
    endfunction
endlibrary

library Events
    function Events_RegisterPlayerUnitEvent takes code callback, playerunitevent whichEvent returns nothing
    endfunction
endlibrary

library FullscreenUI
    function IsEnabled takes nothing returns boolean
        return false
    endfunction
endlibrary

library MasterUI
    function ClosePanels takes nothing returns nothing
    endfunction
endlibrary

library AbilitiesLiteUI
    function ShowForUnit takes unit whichUnit returns nothing
        set whichUnit = null
    endfunction
endlibrary

//! import "ModernAbilityCatalog.j"
//! import "ModernAbilityLoadout.j"
//! import "ModernAbilityTargeting.j"
//! import "ModernAbilityController.j"
//! import "ModernPlayerHUD.j"
//! import "ModernAbilityActionBar.j"

function config takes nothing returns nothing
endfunction

function main takes nothing returns nothing
endfunction
