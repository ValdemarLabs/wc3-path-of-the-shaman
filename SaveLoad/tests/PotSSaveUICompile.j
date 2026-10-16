/**
    PotSSaveUICompile

    Description:
    Compile-only contracts for the changed startup, GameMode, MasterUI,
    Preloader, and PotSSaveUI integration.

    Credits:
    - None

    How to install:
    Never import this file into a production map. Feed it to JassHelper with
    the repository's active common.j and blizzard.j only for validation.

    API:
    - None; config/main exist only as compiler entry points.
**/
globals
    integer udg_START = 0
    unit udg_Nazgrek = null
    unit udg_Zulkis = null
    unit udg_CompDummy = null
    unit udg_AbilityPreloader = null
    integer udg_CompanionCount = 0
    unit array udg_CompanionUnit
    group udg_TamedUnits = null
    rect gg_rct_IntroV2Nazgrek01 = null
    rect gg_rct_NazgrekIntroPoint = null
    trigger gg_trg_Intro_Cinematic_Orc_Q = null
endglobals

//! import "../../_CoreSystems/Imported/Table6.j"

library Interface
    globals
        constant integer Interface_EVENT_UI_OPEN = 1
        constant integer Interface_EVENT_UI_CLOSE = 2
        constant integer Interface_EVENT_BUTTON_CLICK = 3
        constant integer Interface_EVENT_CONFIRM = 4
        constant integer Interface_EVENT_CANCEL = 5
    endglobals
    function Interface_PlayEventSoundForPlayer takes integer eventId, player whichPlayer returns nothing
        set whichPlayer = null
    endfunction
    function Interface_NotifyUIOpened takes nothing returns nothing
    endfunction
    function Interface_NotifyUIClosed takes nothing returns nothing
    endfunction
endlibrary

library CameraControl
    globals
        constant integer CameraControl_MOUSE_ORBIT_BLOCK_MASTER_UI = 1
    endglobals
    function CameraControl_SetMouseOrbitBlockReason takes player whichPlayer, integer reason, boolean blocked returns nothing
        set whichPlayer = null
    endfunction
    function CameraControl_SetTargetUnit takes player whichPlayer, unit whichUnit returns nothing
        set whichPlayer = null
        set whichUnit = null
    endfunction
    function CameraControl_PanToTarget takes player whichPlayer, real duration returns nothing
        set whichPlayer = null
    endfunction
endlibrary

library ZonesCore
    function ZonesCore_EnableZone takes integer zoneId, boolean enabled returns nothing
    endfunction
endlibrary

library DInventory
    function InitializeDInventoryForUnit takes unit hero returns integer
        set hero = null
        return 1
    endfunction
    function AddItemToUnitExclusionList takes item whichItem, unit hero returns nothing
        set whichItem = null
        set hero = null
    endfunction
    function RemoveItemFromUnitExclusionList takes item whichItem, unit hero returns nothing
        set whichItem = null
        set hero = null
    endfunction
endlibrary

library DEquipment requires DInventory
    function InitializeDEquipmentForUnit takes unit hero returns integer
        set hero = null
        return 1
    endfunction
    function DInvTryEquipBestStoredEquipmentForUnit takes unit hero returns boolean
        set hero = null
        return false
    endfunction
endlibrary

library WeatherSystem
    function WeatherSystem_EnableSeasonalWeather takes boolean enabled returns nothing
    endfunction
endlibrary

library TerrainDamage
    function TerrainDamage_InitUnits takes nothing returns nothing
    endfunction
    function TerrainDamage_InitGroups takes nothing returns nothing
    endfunction
endlibrary

library BridgeSystem
    function BridgeSystem_AddIgnoredUnit takes unit whichUnit returns nothing
        set whichUnit = null
    endfunction
endlibrary

library Companions
    function Companions_GetControlledDisplayCount takes nothing returns integer
        return 0
    endfunction
    function Companions_GetControlledDisplayUnit takes integer index returns unit
        return null
    endfunction
endlibrary

//! import "../../Preload/Start.j"

library Difficulty
    globals
        constant integer DIFFICULTY_STORY = 1
        constant integer DIFFICULTY_NORMAL = 2
        constant integer DIFFICULTY_HARD = 3
    endglobals
    function Difficulty_SetDifficulty takes integer difficulty returns nothing
    endfunction
endlibrary

library ImagesUI
    function ImagesUI_ShowPreload takes string texturePath, string message returns nothing
    endfunction
    function ImagesUI_HidePreload takes nothing returns nothing
    endfunction
    function ImagesUI_SetPreloadText takes string message returns nothing
    endfunction
    function ImagesUI_GetPreloadOverlayParent takes nothing returns framehandle
        return null
    endfunction
    function ShowPreloadTitle takes string title, string message, real fadeIn, real duration, real fadeOut returns nothing
    endfunction
    function HidePreloadTitle takes nothing returns nothing
    endfunction
endlibrary

//! import "../../UI/GameMode.j"

library ExSound
    function ExSound_PreloadAll takes nothing returns nothing
    endfunction
endlibrary

library ExMusic
    function ExMusic_PreloadAll takes nothing returns nothing
    endfunction
    function ExMusic_PlayTrack takes integer trackId returns nothing
    endfunction
endlibrary

library PreloadAbilities
    function Preload_Abilities takes unit loader returns nothing
        set loader = null
    endfunction
endlibrary

library StatsLiteUI
    function StatsLiteUI_Init takes nothing returns nothing
    endfunction
endlibrary

library FullscreenUI
    function FullscreenUI_SetEnabled takes boolean enabled returns nothing
    endfunction
endlibrary

library RegionTitles
endlibrary

//! import "../../UI/MasterUI.j"

library PotSSaveLoad
    function PotSSaveLoad_IsBusy takes player whichPlayer returns boolean
        set whichPlayer = null
        return false
    endfunction
    function PotSSaveLoad_SlotExists takes string slot returns boolean
        return false
    endfunction
    function PotSSaveLoad_GetSlotTitle takes string slot returns string
        return ""
    endfunction
    function PotSSaveLoad_GetSlotMode takes string slot returns integer
        return 1
    endfunction
    function PotSSaveLoad_GetSlotDifficulty takes string slot returns integer
        return 2
    endfunction
    function PotSSaveLoad_RequestSave takes player whichPlayer, string slot returns boolean
        set whichPlayer = null
        return true
    endfunction
    function PotSSaveLoad_RequestLoad takes player whichPlayer, string slot returns boolean
        set whichPlayer = null
        return true
    endfunction
    function PotSSaveLoad_SetLoadAllowed takes player whichPlayer, boolean allowed returns nothing
        set whichPlayer = null
    endfunction
    function PotSSaveLoad_CanRecoverFromLoadFailure takes player whichPlayer returns boolean
        set whichPlayer = null
        return true
    endfunction
    function PotSSaveLoad_AddSaveCompleteAction takes code actionFunc returns triggeraction
        return null
    endfunction
    function PotSSaveLoad_AddSaveFailedAction takes code actionFunc returns triggeraction
        return null
    endfunction
    function PotSSaveLoad_AddLoadFailedAction takes code actionFunc returns triggeraction
        return null
    endfunction
endlibrary

//! import "../PotSSaveUI.j"
//! import "../../Preload/Preloader.j"

function config takes nothing returns nothing
endfunction

function main takes nothing returns nothing
endfunction
