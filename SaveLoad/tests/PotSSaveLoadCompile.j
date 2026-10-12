/**
    PotSSaveLoadCompile

    Description:
    Compile-only import harness for the immutable reusable NSL core and the
    new PotS SaveLoad stack. Actual AbilitiesPlayer/AbilityPoints APIs and
    narrow gameplay/custom-inventory contracts exercise every optional path.

    Credits:
    - Maxou, New Save Load (NSL)

    How to install:
    Never import this file into a production map. Feed it to JassHelper with
    the repository's active common.j and blizzard.j only for validation.

    API:
    - None; config/main exist only as compiler entry points.
**/
globals
    // Test contract supplied by the production map's immutable NSLImpl.
    constant integer NSL_CodeVersion = 1
    constant integer NSL_Key = 19
    constant string NSL_FolderName = "MaxouNSL"

    unit udg_Nazgrek = null
    unit udg_Zulkis = null
    integer udg_Companion_GroupSize = 0
endglobals

//! import "../../_CoreSystems/MaxouNSL/Core by Trigger Happy vJASS/FileIO.j"
//! import "../../_CoreSystems/MaxouNSL/Core by Trigger Happy vJASS/SaveFile.j"
//! import "../../_CoreSystems/MaxouNSL/Save Load System vJASS/NSL Size Enum.j"
//! import "../../_CoreSystems/MaxouNSL/Save Load System vJASS/NSL Helper.j"
//! import "../../_CoreSystems/MaxouNSL/Save Load System vJASS/NSL Save Load.j"
//! import "../../_CoreSystems/Imported/Table5BC.j"
//! import "../../_CoreSystems/Imported/Table6.j"

library DInventory requires Table
    globals
        Table2DT DInvItemHandleDB
        TableArray DInventoryDB
        Table3DT EQIDDB
        Table3DT BIDDB
    endglobals

    function BIDOfUnit takes unit hero returns integer
        set hero = null
        return 1
    endfunction

    function EQIDOfUnit takes unit hero returns integer
        set hero = null
        return 1
    endfunction

    function MaxBagCapacityOfBID takes integer playerId, integer bid returns integer
        return 20
    endfunction

    function DInvGetBagTierOfUnit takes unit hero returns integer
        set hero = null
        return 1
    endfunction

    function DInvSetBagTierForUnit takes unit hero, integer tier returns boolean
        set hero = null
        return true
    endfunction

    function DInvDeltaAdditionalSlotsForUnit takes unit hero, integer delta returns nothing
        set hero = null
    endfunction

    function InitializeDInventoryForUnit takes unit hero returns integer
        set hero = null
        return 1
    endfunction

    function GoToItemHeaven takes item whichItem returns nothing
        set whichItem = null
    endfunction

    function IsItemTypeOnExclusionListOfUnit takes integer itemTypeId, unit hero returns boolean
        set hero = null
        return false
    endfunction

    function AddItemTypeToUnitExclusionList takes integer itemTypeId, unit hero returns nothing
        set hero = null
    endfunction

    function RemoveItemTypeFromUnitExclusionList takes integer itemTypeId, unit hero returns nothing
        set hero = null
    endfunction

    function DInvRefreshCapacityTextForBID takes integer bid returns nothing
    endfunction
endlibrary

library DEquipment requires DInventory
    function InitializeDEquipmentForUnit takes unit hero returns integer
        set hero = null
        return 1
    endfunction

    function DEqIsItemASetItem takes item whichItem returns integer
        set whichItem = null
        return 0
    endfunction

    function DEqDecreaseSetEquippedOnUnit takes unit hero, integer setId returns nothing
        set hero = null
    endfunction

    function RemoveDEqStatsOfItemFromUnit takes integer playerId, integer eqid, integer slot, item whichItem, unit hero returns nothing
        set whichItem = null
        set hero = null
    endfunction

    function DEqIncreaseSetEquippedOnUnit takes unit hero, integer setId returns nothing
        set hero = null
    endfunction

    function AddDEqStatsOfItemToUnit takes integer playerId, integer eqid, integer slot, item whichItem, unit hero returns nothing
        set whichItem = null
        set hero = null
    endfunction

    function UpdateDEqCSheet takes integer playerId, unit hero, integer heroHandleId, integer eqid returns nothing
        set hero = null
    endfunction
endlibrary

library GameMode
    public function GetMode takes nothing returns integer
        return 1
    endfunction

    public function GetDifficulty takes nothing returns integer
        return 2
    endfunction
endlibrary

library Start
    public function GetPendingLoadSlot takes nothing returns string
        return ""
    endfunction

    public function ContinueAfterLoad takes nothing returns nothing
    endfunction
endlibrary

//! import "../../Abilities/AbilitiesPlayer.j"
//! import "../../Abilities/AbilityPoints.j"
//! import "../PotSSaveConfig.j"
//! import "../PotSStateData.j"
//! import "../PotSStateTracker.j"

library Abilities
    public function GetEntryLevel takes unit hero, integer entryIndex returns integer
        set hero = null
        return entryIndex
    endfunction
endlibrary

library QuestMaster
    globals
        constant integer QUEST_STATE_COMPLETE = 4
    endglobals

    struct QuestData
        string name
        unit giver
        integer lastEvalState
        quest wcQuest
        boolean discovered
        boolean discoveryPending
        boolean active
        boolean completed
        boolean failed
        integer state

        method refreshQuestLog takes nothing returns nothing
        endmethod

        method updateIcons takes nothing returns nothing
        endmethod
    endstruct

    public function GetQuestCount takes nothing returns integer
        return 0
    endfunction

    public function GetQuestIdByIndex takes integer index returns integer
        return index
    endfunction

    public function GetById takes integer questId returns QuestData
        return questId
    endfunction
endlibrary

//! import "../PotSWorldProgression.j"
//! import "../PotSStateScanner.j"
//! import "../PotSStateSerializer.j"
//! import "../PotSStateMigration.j"
//! import "../PotSMaxouNSLAdapter.j"
//! import "../PotSSaveLoad.j"
//! import "../PotSSaveCommands.j"
//! import "../PotSSaveLoadTests.j"

function config takes nothing returns nothing
endfunction

function main takes nothing returns nothing
endfunction
