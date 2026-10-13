/**
    PotSSaveLoad

    Author: Valdemar
    Version: 2.2.0

    Description:
    Public single-player party save/load facade, fixed-slot metadata, safe-load
    window, preflight, staged restoration, notifications, and restore guard.

    Credits:
    - Maxou, New Save Load (NSL)
    - StateSaver by Tomotz, staged restoration architecture

    How to install:
    Import after every other PotS SaveLoad library and the reusable immutable
    NSL core. Use -pots-save <slot> and -pots-load <slot>.

    API:
    - PotSSaveLoad_RequestSave(player, slot)
    - PotSSaveLoad_RequestLoad(player, slot)
    - PotSSaveLoad_SetHero(player, hero)
    - PotSSaveLoad_SetLoadAllowed(player, allowed)
    - PotSSaveLoad_IsRestoring()
    - PotSSaveLoad_CanRecoverFromLoadFailure(player)
    - PotSSaveLoad_SlotExists/GetSlotTitle/GetSlotMode/GetSlotDifficulty(...)
    - PotSSaveLoad_StartPendingLoad()
    - PotSSaveLoad_AddSaveCompleteAction/SaveFailedAction(...)
    - PotSSaveLoad_AddLoadCompleteAction/LoadFailedAction/WarningAction(...)

**/
library PotSSaveLoad initializer Init requires PotSSaveConfig, PotSStateData, PotSStateTracker, PotSStateScanner, PotSStateSerializer, PotSStateMigration, PotSWorldProgression, PotSMaxouNSLAdapter, optional AbilitiesPlayer, optional AbilityPoints, optional DInventory, optional DEquipment, optional Start, optional GameMode
    globals
        private boolean array PSS_Busy
        private boolean array PSS_Loaded
        private boolean array PSS_LoadAllowed
        private unit array PSS_RegisteredHero
        private unit array PSS_OperationHero
        private item array PSS_PreparedItem
        private integer array PSS_LastError
        private boolean PSS_Restoring = false
        private boolean PSS_ResolveAmbiguous = false
        private timer PSS_LoadWindowTimer = null
        private string array PSS_LogicalSlot
        private integer array PSS_PartyPhase
        private boolean array PSS_PartyHasZulkis
        private integer array PSS_SavedNazgrekLevel
        private integer array PSS_SavedZulkisLevel
        private integer array PSS_ApplyFailureStage
        private string array PSS_ApplyFailureHero
        private integer array PSS_PreflightFailureStage
        private string array PSS_PreflightFailureHero
        private integer PSS_ZulkisStreamCount = 0
        private integer array PSS_ZulkisStreamValue

        private constant integer PSS_PHASE_NONE = 0
        private constant integer PSS_PHASE_SAVE_NAZGREK = 1
        private constant integer PSS_PHASE_SAVE_ZULKIS = 2
        private constant integer PSS_PHASE_LOAD_NAZGREK = 3
        private constant integer PSS_PHASE_LOAD_ZULKIS = 4
        private constant integer PSS_PHASE_VALIDATE_ZULKIS = 5
        private constant integer PSS_APPLY_STAGE_NONE = 0
        private constant integer PSS_APPLY_STAGE_ABILITIES = 1
        private constant integer PSS_APPLY_STAGE_INVENTORY = 2
        private constant integer PSS_APPLY_STAGE_CUSTOM_STORAGE = 3
        private constant integer PSS_APPLY_STAGE_ZULKIS_STREAM = 4
        private constant integer PSS_PREFLIGHT_STAGE_NONE = 0
        private constant integer PSS_PREFLIGHT_STAGE_HERO = 1
        private constant integer PSS_PREFLIGHT_STAGE_ABILITIES = 2
        private constant integer PSS_PREFLIGHT_STAGE_INVENTORY = 3
        private constant integer PSS_PREFLIGHT_STAGE_CUSTOM_STORAGE = 4
        private constant integer PSS_PREFLIGHT_STAGE_WORLD = 5
        private constant string PSS_META_PREFIX = "pots_meta_"

        public trigger OnSaveComplete = CreateTrigger()
        public trigger OnSaveFailed = CreateTrigger()
        public trigger OnLoadComplete = CreateTrigger()
        public trigger OnLoadFailed = CreateTrigger()
        public trigger OnWarning = CreateTrigger()
        public integer EventPlayerId = -1
        public integer EventError = 0
        public integer EventWarningCount = 0
    endglobals

    private function PSS_ErrorText takes integer playerId, integer errorCode returns string
        if errorCode == PotSSaveConfig_ERROR_BUSY then
            return "Another save/load operation is already in progress."
        elseif errorCode == PotSSaveConfig_ERROR_INVALID_SLOT then
            return "Use 1-30 letters, numbers, underscores, or hyphens for the slot."
        elseif errorCode == PotSSaveConfig_ERROR_NO_HERO then
            return "No persistent hero could be resolved."
        elseif errorCode == PotSSaveConfig_ERROR_AMBIGUOUS_HERO then
            return "Select one hero or register it before using this command."
        elseif errorCode == PotSSaveConfig_ERROR_SCAN_FAILED then
            return "The current character state could not be scanned safely."
        elseif errorCode == PotSSaveConfig_ERROR_CAPACITY then
            return "The character state exceeds the configured save capacity."
        elseif errorCode == PotSSaveConfig_ERROR_FILE_NOT_FOUND then
            return "No PotS save exists in that slot."
        elseif errorCode == PotSSaveConfig_ERROR_INVALID_CODE then
            return "NSL rejected the save integrity or player-profile binding. Keep the same player name, NSL key, and NSL code version. Ordinary map edits do not invalidate a code."
        elseif errorCode == PotSSaveConfig_ERROR_UNSUPPORTED_SCHEMA then
            return "The PotS save schema is not supported by this map version."
        elseif errorCode == PotSSaveConfig_ERROR_INVALID_DATA then
            return "The save contains malformed or out-of-range records."
        elseif errorCode == PotSSaveConfig_ERROR_LOAD_LOCKED then
            return "Loading is allowed only during the safe new-game window or an enabled checkpoint."
        elseif errorCode == PotSSaveConfig_ERROR_ALREADY_LOADED then
            return "A character has already been loaded in this session."
        elseif errorCode == PotSSaveConfig_ERROR_PREFLIGHT then
            if PSS_PreflightFailureStage[playerId] == PSS_PREFLIGHT_STAGE_HERO then
                return "The saved " + PSS_PreflightFailureHero[playerId] + " unit rawcode no longer matches the current hero. Register a hero rawcode migration if it was renamed."
            elseif PSS_PreflightFailureStage[playerId] == PSS_PREFLIGHT_STAGE_ABILITIES then
                return "A saved " + PSS_PreflightFailureHero[playerId] + " catalog ability is missing or now has a lower maximum level. Restore it or register an ability rawcode migration."
            elseif PSS_PreflightFailureStage[playerId] == PSS_PREFLIGHT_STAGE_INVENTORY then
                return "A saved " + PSS_PreflightFailureHero[playerId] + " inventory item is unavailable, or the current hero has fewer native inventory slots."
            elseif PSS_PreflightFailureStage[playerId] == PSS_PREFLIGHT_STAGE_CUSTOM_STORAGE then
                return "A saved " + PSS_PreflightFailureHero[playerId] + " custom-inventory/equipment item or required storage system is unavailable."
            elseif PSS_PreflightFailureStage[playerId] == PSS_PREFLIGHT_STAGE_WORLD then
                return "Saved world progression could not be mapped safely. Register a quest identity migration for renamed quest data."
            endif
            return "The current map cannot safely apply required saved content."
        elseif errorCode == PotSSaveConfig_ERROR_APPLY_FAILED then
            if PSS_ApplyFailureStage[playerId] == PSS_APPLY_STAGE_ABILITIES then
                return "The validated " + PSS_ApplyFailureHero[playerId] + " abilities could not be restored. Reload the map before retrying."
            elseif PSS_ApplyFailureStage[playerId] == PSS_APPLY_STAGE_INVENTORY then
                return "The validated " + PSS_ApplyFailureHero[playerId] + " normal inventory could not be restored. Reload the map before retrying."
            elseif PSS_ApplyFailureStage[playerId] == PSS_APPLY_STAGE_CUSTOM_STORAGE then
                return "The validated " + PSS_ApplyFailureHero[playerId] + " custom inventory/equipment could not be restored. Reload the map before retrying."
            elseif PSS_ApplyFailureStage[playerId] == PSS_APPLY_STAGE_ZULKIS_STREAM then
                return "The validated Zul'kis snapshot could not be restored from memory. Reload the map before retrying."
            endif
            return "The validated state could not be fully applied. Reload the map before retrying."
        elseif errorCode == PotSSaveConfig_ERROR_SINGLE_PLAYER_ONLY then
            return "This version supports single-player save/load only."
        endif
        return "Unknown save/load error."
    endfunction

    private function PSS_Message takes integer playerId, string prefix, string message returns nothing
        call DisplayTextToPlayer(Player(playerId), 0.00, 0.00, prefix + message)
    endfunction

    private function PSS_Fire takes trigger whichTrigger, integer playerId, integer errorCode returns nothing
        set EventPlayerId = playerId
        set EventError = errorCode
        call TriggerExecute(whichTrigger)
    endfunction

    private function PSS_Fail takes integer playerId, integer errorCode, boolean loading returns nothing
        if errorCode != PotSSaveConfig_ERROR_BUSY then
            set PSS_Busy[playerId] = false
            set PSS_OperationHero[playerId] = null
            set PSS_PartyPhase[playerId] = PSS_PHASE_NONE
            if loading then
                set PSS_ZulkisStreamCount = 0
            endif
        endif
        set PSS_LastError[playerId] = errorCode
        call PSS_Message(playerId, "|cffff3333[PotS SaveLoad]|r ", PSS_ErrorText(playerId, errorCode))
        if loading then
            call PSS_Fire(OnLoadFailed, playerId, errorCode)
            if errorCode != PotSSaveConfig_ERROR_BUSY then
                static if LIBRARY_Start then
                    if not Start_IsAwaitingLoad() then
                        call ExecuteFunc("Start_ContinueAfterLoad")
                    endif
                else
                    call ExecuteFunc("Start_ContinueAfterLoad")
                endif
            endif
        else
            call PSS_Fire(OnSaveFailed, playerId, errorCode)
        endif
    endfunction

    private function PSS_IsSinglePlayer takes nothing returns boolean
        local integer i = 0
        local integer count = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            if GetPlayerController(Player(i)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING then
                set count = count + 1
            endif
            set i = i + 1
        endloop
        return count <= 1
    endfunction

    private function PSS_ResolveHero takes player whichPlayer returns unit
        local integer playerId = GetPlayerId(whichPlayer)
        local group candidates
        local unit candidate = null
        local unit onlyHero = null
        local unit selectedHero = null
        local integer heroCount = 0
        local integer selectedCount = 0

        set PSS_ResolveAmbiguous = false
        if PSS_RegisteredHero[playerId] != null and GetUnitTypeId(PSS_RegisteredHero[playerId]) != 0 and GetOwningPlayer(PSS_RegisteredHero[playerId]) == whichPlayer and IsUnitType(PSS_RegisteredHero[playerId], UNIT_TYPE_HERO) then
            set whichPlayer = null
            return PSS_RegisteredHero[playerId]
        endif

        set candidates = CreateGroup()
        call GroupEnumUnitsOfPlayer(candidates, whichPlayer, null)
        loop
            set candidate = FirstOfGroup(candidates)
            exitwhen candidate == null
            call GroupRemoveUnit(candidates, candidate)
            if GetUnitTypeId(candidate) != 0 and IsUnitType(candidate, UNIT_TYPE_HERO) and not IsUnitType(candidate, UNIT_TYPE_SUMMONED) then
                set heroCount = heroCount + 1
                set onlyHero = candidate
                if IsUnitSelected(candidate, whichPlayer) then
                    set selectedCount = selectedCount + 1
                    set selectedHero = candidate
                endif
            endif
        endloop
        call DestroyGroup(candidates)
        set candidates = null
        set candidate = null
        set whichPlayer = null

        if selectedCount == 1 then
            set onlyHero = selectedHero
        elseif heroCount != 1 then
            set PSS_ResolveAmbiguous = heroCount > 1
            set onlyHero = null
        endif
        set selectedHero = null
        return onlyHero
    endfunction

    private function PSS_ClearPreparedItems takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_INVENTORY_SLOTS + PotSSaveConfig_MAX_DINVENTORY_SLOTS + PotSSaveConfig_MAX_EQUIPMENT_SLOTS
            if PSS_PreparedItem[i] != null then
                call RemoveItem(PSS_PreparedItem[i])
                set PSS_PreparedItem[i] = null
            endif
            set i = i + 1
        endloop
    endfunction

    private function PSS_PreflightInventory takes unit hero returns boolean
        local integer i = 0
        local item created = null

        call PSS_ClearPreparedItems()
        if PotSStateData_GetInventorySize() > UnitInventorySize(hero) then
            return false
        endif
        loop
            exitwhen i >= PotSStateData_GetInventoryCount()
            set created = CreateItem(PotSStateData_GetInventoryType(i), GetUnitX(hero), GetUnitY(hero))
            if created == null then
                call PSS_ClearPreparedItems()
                return false
            endif
            call SetItemVisible(created, false)
            set PSS_PreparedItem[i] = created
            set i = i + 1
        endloop
        set created = null
        return true
    endfunction

    private function PSS_PreflightCustomItems takes unit hero returns boolean
        local integer i = 0
        local integer preparedIndex
        local item created = null

        if PotSStateData_GetDInventoryCapacity() < 0 and PotSStateData_GetEquipmentCount() == 0 then
            set hero = null
            return true
        endif
        static if not LIBRARY_DInventory then
            set hero = null
            return false
        endif
        static if not LIBRARY_DEquipment then
            if PotSStateData_GetEquipmentCount() > 0 then
                set hero = null
                return false
            endif
        endif
        loop
            exitwhen i >= PotSStateData_GetDInventoryCount()
            set created = CreateItem(PotSStateData_GetDInventoryType(i), GetUnitX(hero), GetUnitY(hero))
            if created == null then
                set hero = null
                return false
            endif
            set preparedIndex = PotSSaveConfig_MAX_INVENTORY_SLOTS + i
            call SetItemVisible(created, false)
            set PSS_PreparedItem[preparedIndex] = created
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetEquipmentCount()
            set created = CreateItem(PotSStateData_GetEquipmentType(i), GetUnitX(hero), GetUnitY(hero))
            if created == null then
                set hero = null
                return false
            endif
            set preparedIndex = PotSSaveConfig_MAX_INVENTORY_SLOTS + PotSSaveConfig_MAX_DINVENTORY_SLOTS + i
            call SetItemVisible(created, false)
            set PSS_PreparedItem[preparedIndex] = created
            set i = i + 1
        endloop
        set created = null
        set hero = null
        return true
    endfunction

    private function PSS_PreflightAbilities takes nothing returns boolean
        local integer i = 0
        local integer entryIndex

        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            if PotSStateData_GetAbilitySource(i) == PotSSaveConfig_ABILITY_SOURCE_CATALOG then
                set entryIndex = 0
                static if LIBRARY_AbilitiesPlayer then
                    set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(PotSStateData_GetAbilityId(i))
                endif
                if entryIndex == 0 then
                    return false
                endif
                static if LIBRARY_AbilitiesPlayer then
                    if PotSStateData_GetAbilityLevel(i) > AbilitiesPlayer_GetEntryMaxLevel(entryIndex) then
                        return false
                    endif
                endif
            endif
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSS_Preflight takes unit hero returns boolean
        local integer playerId

        if hero == null then
            return false
        endif
        set playerId = GetPlayerId(GetOwningPlayer(hero))
        set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_NONE
        if hero == udg_Zulkis then
            set PSS_PreflightFailureHero[playerId] = "Zul'kis"
        else
            set PSS_PreflightFailureHero[playerId] = "Nazgrek"
        endif
        if hero == null or GetUnitTypeId(hero) != PotSStateData_GetHeroType() then
            set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_HERO
            return false
        endif
        if not PSS_PreflightAbilities() then
            set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_ABILITIES
            call PSS_ClearPreparedItems()
            return false
        endif
        if not PSS_PreflightInventory(hero) then
            set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_INVENTORY
            call PSS_ClearPreparedItems()
            return false
        endif
        if not PSS_PreflightCustomItems(hero) then
            set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_CUSTOM_STORAGE
            call PSS_ClearPreparedItems()
            return false
        endif
        if not PotSWorldProgression_Preflight() then
            set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_WORLD
            call PSS_ClearPreparedItems()
            return false
        endif
        return true
    endfunction

    private function PSS_RemoveCatalogAbility takes unit hero, integer entryIndex returns nothing
        static if LIBRARY_AbilitiesPlayer then
            local integer abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
            local integer addAbilityId = AbilitiesPlayer_GetEntryAddAbilityId(entryIndex)
            local integer permanentAbilityId = AbilitiesPlayer_GetEntryPermanentAbilityId(entryIndex)

            if abilityId != 0 then
                call UnitMakeAbilityPermanent(hero, false, abilityId)
                call UnitRemoveAbility(hero, abilityId)
            endif
            if addAbilityId != 0 and addAbilityId != abilityId then
                call UnitMakeAbilityPermanent(hero, false, addAbilityId)
                call UnitRemoveAbility(hero, addAbilityId)
            endif
            if permanentAbilityId != 0 and permanentAbilityId != abilityId and permanentAbilityId != addAbilityId then
                call UnitMakeAbilityPermanent(hero, false, permanentAbilityId)
                call UnitRemoveAbility(hero, permanentAbilityId)
            endif
        endif
    endfunction

    private function PSS_ClearPersistentAbilities takes unit hero returns nothing
        local integer i = 0
        local integer abilityId

        static if LIBRARY_AbilitiesPlayer then
            set i = 1
            loop
                exitwhen i > AbilitiesPlayer_GetEntryCount()
                call PSS_RemoveCatalogAbility(hero, i)
                set i = i + 1
            endloop
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateTracker_GetCount(hero)
            set abilityId = PotSStateTracker_GetAbilityId(hero, i)
            call UnitMakeAbilityPermanent(hero, false, abilityId)
            call UnitRemoveAbility(hero, abilityId)
            set i = i + 1
        endloop
        call PotSStateTracker_ClearHero(hero)
    endfunction

    private function PSS_ApplyCatalogAbility takes unit hero, integer entryIndex, integer level returns boolean
        static if LIBRARY_AbilitiesPlayer then
            local integer abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
            local integer addAbilityId = AbilitiesPlayer_GetEntryAddAbilityId(entryIndex)
            local integer permanentAbilityId = AbilitiesPlayer_GetEntryPermanentAbilityId(entryIndex)

            if GetUnitAbilityLevel(hero, addAbilityId) <= 0 and not UnitAddAbility(hero, addAbilityId) then
                return false
            endif
            call UnitMakeAbilityPermanent(hero, true, addAbilityId)
            call UnitMakeAbilityPermanent(hero, true, abilityId)
            if permanentAbilityId != 0 then
                call UnitMakeAbilityPermanent(hero, true, permanentAbilityId)
            endif
            if level > 1 then
                call SetUnitAbilityLevel(hero, abilityId, level)
            endif
            return GetUnitAbilityLevel(hero, abilityId) == level
        endif
        return false
    endfunction

    private function PSS_ApplyAbilities takes unit hero returns boolean
        local integer i = 0
        local integer abilityId
        local integer level
        local integer entryIndex

        call PSS_ClearPersistentAbilities(hero)
        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            set abilityId = PotSStateData_GetAbilityId(i)
            set level = PotSStateData_GetAbilityLevel(i)
            set entryIndex = 0
            static if LIBRARY_AbilitiesPlayer then
                set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
            endif
            if entryIndex > 0 then
                if not PSS_ApplyCatalogAbility(hero, entryIndex, level) then
                    return false
                endif
            else
                if GetUnitAbilityLevel(hero, abilityId) <= 0 and not UnitAddAbility(hero, abilityId) then
                    return false
                endif
                call UnitMakeAbilityPermanent(hero, true, abilityId)
                if level > 1 then
                    call SetUnitAbilityLevel(hero, abilityId, level)
                endif
                if GetUnitAbilityLevel(hero, abilityId) != level then
                    return false
                endif
            endif
            set i = i + 1
        endloop
        call PotSStateTracker_RestoreFromSnapshot(hero)
        return true
    endfunction

    private function PSS_ApplyInventory takes unit hero returns boolean
        local integer slot = 0
        local integer i = 0
        local integer itemTypeId
        local item whichItem = null
        local boolean temporaryTypeExclusion = false

        call PSS_ClearPreparedItems()
        loop
            exitwhen slot >= UnitInventorySize(hero)
            set whichItem = UnitItemInSlot(hero, slot)
            if whichItem != null then
                call RemoveItem(whichItem)
            endif
            set slot = slot + 1
        endloop
        set whichItem = null

        loop
            exitwhen i >= PotSStateData_GetInventoryCount()
            set itemTypeId = PotSStateData_GetInventoryType(i)
            static if LIBRARY_DInventory then
                set temporaryTypeExclusion = not IsItemTypeOnExclusionListOfUnit(itemTypeId, hero)
                if temporaryTypeExclusion then
                    call AddItemTypeToUnitExclusionList(itemTypeId, hero)
                endif
            endif
            if not UnitAddItemToSlotById(hero, itemTypeId, PotSStateData_GetInventorySlot(i)) then
                static if LIBRARY_DInventory then
                    if temporaryTypeExclusion then
                        call RemoveItemTypeFromUnitExclusionList(itemTypeId, hero)
                    endif
                endif
                return false
            endif
            static if LIBRARY_DInventory then
                if temporaryTypeExclusion then
                    call RemoveItemTypeFromUnitExclusionList(itemTypeId, hero)
                endif
            endif
            set whichItem = UnitItemInSlot(hero, PotSStateData_GetInventorySlot(i))
            if whichItem == null or GetItemTypeId(whichItem) != itemTypeId then
                set whichItem = null
                return false
            endif
            call SetItemCharges(whichItem, PotSStateData_GetInventoryCharges(i))
            set i = i + 1
        endloop
        set whichItem = null
        return true
    endfunction

    private function PSS_ClearDInventoryAndEquipment takes unit hero returns nothing
        static if LIBRARY_DInventory then
            local integer pid = GetPlayerId(GetOwningPlayer(hero))
            local integer bid = BIDOfUnit(hero)
            local integer eqid = EQIDOfUnit(hero)
            local integer slot = 1
            local integer setId
            local integer itemHandleId
            local integer capacity
            local item whichItem = null

            static if LIBRARY_DEquipment then
                if eqid > 0 then
                    loop
                        exitwhen slot > PotSSaveConfig_MAX_EQUIPMENT_SLOTS
                        set whichItem = EQIDDB[eqid][4].item[slot]
                        if whichItem != null then
                            set setId = DEqIsItemASetItem(whichItem)
                            if setId != 0 then
                                call DEqDecreaseSetEquippedOnUnit(hero, setId)
                            endif
                            call RemoveDEqStatsOfItemFromUnit(pid, eqid, slot, whichItem, hero)
                            set itemHandleId = GetHandleId(whichItem)
                            call EQIDDB[eqid][4].item.remove(slot)
                            set DInvItemHandleDB[itemHandleId].integer[0] = 0
                            set DInvItemHandleDB[itemHandleId].integer[1] = 0
                            set DInvItemHandleDB[itemHandleId].integer[2] = 0
                            set DInvItemHandleDB[itemHandleId].integer[4] = 0
                            set DInvItemHandleDB[itemHandleId].integer[6] = 0
                            call RemoveItem(whichItem)
                        endif
                        set slot = slot + 1
                    endloop
                endif
            endif
            if bid > 0 then
                set capacity = MaxBagCapacityOfBID(pid, bid)
                set slot = 0
                loop
                    exitwhen slot >= capacity
                    set whichItem = DInventoryDB[bid].item[slot]
                    if whichItem != null then
                        set itemHandleId = GetHandleId(whichItem)
                        call DInventoryDB[bid].item.remove(slot)
                        set DInvItemHandleDB[itemHandleId].integer[0] = 0
                        set DInvItemHandleDB[itemHandleId].integer[1] = 0
                        set DInvItemHandleDB[itemHandleId].integer[2] = 0
                        set DInvItemHandleDB[itemHandleId].integer[4] = 0
                        set DInvItemHandleDB[itemHandleId].integer[6] = 0
                        call RemoveItem(whichItem)
                    endif
                    set slot = slot + 1
                endloop
                call DInvRefreshCapacityTextForBID(bid)
            endif
            set whichItem = null
        endif
        set hero = null
    endfunction

    private function PSS_ApplyDInventoryAndEquipment takes unit hero returns boolean
        static if LIBRARY_DInventory then
            local integer pid
            local integer bid
            local integer eqid
            local integer currentAdditional
            local integer i = 0
            local integer slot
            local integer itemHandleId
            local integer setId
            local item whichItem = null

            if PotSStateData_GetDInventoryCapacity() < 0 and PotSStateData_GetEquipmentCount() == 0 then
                set hero = null
                return true
            endif
            call InitializeDInventoryForUnit(hero)
            static if LIBRARY_DEquipment then
                call InitializeDEquipmentForUnit(hero)
            endif
            set pid = GetPlayerId(GetOwningPlayer(hero))
            set bid = BIDOfUnit(hero)
            set eqid = EQIDOfUnit(hero)
            if bid < 1 or eqid < 1 then
                set hero = null
                return false
            endif

            call PSS_ClearDInventoryAndEquipment(hero)
            if not DInvSetBagTierForUnit(hero, PotSStateData_GetDInventoryTier()) then
                set hero = null
                return false
            endif
            set currentAdditional = BIDDB[bid][0].integer[1]
            call DInvDeltaAdditionalSlotsForUnit(hero, PotSStateData_GetDInventoryAdditional() - currentAdditional)
            if MaxBagCapacityOfBID(pid, bid) != PotSStateData_GetDInventoryCapacity() then
                set hero = null
                return false
            endif

            loop
                exitwhen i >= PotSStateData_GetDInventoryCount()
                set slot = PotSStateData_GetDInventorySlot(i)
                set whichItem = CreateItem(PotSStateData_GetDInventoryType(i), GetUnitX(hero), GetUnitY(hero))
                if whichItem == null or DInventoryDB[bid].item[slot] != null then
                    set whichItem = null
                    set hero = null
                    return false
                endif
                call SetItemCharges(whichItem, PotSStateData_GetDInventoryCharges(i))
                set itemHandleId = GetHandleId(whichItem)
                set DInventoryDB[bid].item[slot] = whichItem
                set DInvItemHandleDB[itemHandleId].integer[0] = pid + 1
                set DInvItemHandleDB[itemHandleId].integer[1] = bid
                set DInvItemHandleDB[itemHandleId].integer[2] = slot
                set DInvItemHandleDB[itemHandleId].integer[4] = 0
                set DInvItemHandleDB[itemHandleId].integer[6] = eqid
                call GoToItemHeaven(whichItem)
                set i = i + 1
            endloop

            static if LIBRARY_DEquipment then
                set i = 0
                loop
                    exitwhen i >= PotSStateData_GetEquipmentCount()
                    set slot = PotSStateData_GetEquipmentSlot(i)
                    set whichItem = CreateItem(PotSStateData_GetEquipmentType(i), GetUnitX(hero), GetUnitY(hero))
                    if whichItem == null or EQIDDB[eqid][4].item[slot] != null then
                        set whichItem = null
                        set hero = null
                        return false
                    endif
                    call SetItemCharges(whichItem, PotSStateData_GetEquipmentCharges(i))
                    call GoToItemHeaven(whichItem)
                    set itemHandleId = GetHandleId(whichItem)
                    set EQIDDB[eqid][4].item[slot] = whichItem
                    set DInvItemHandleDB[itemHandleId].integer[0] = pid + 1
                    set DInvItemHandleDB[itemHandleId].integer[1] = bid
                    set DInvItemHandleDB[itemHandleId].integer[2] = 0
                    set DInvItemHandleDB[itemHandleId].integer[4] = slot
                    set DInvItemHandleDB[itemHandleId].integer[6] = eqid
                    set setId = DEqIsItemASetItem(whichItem)
                    if setId != 0 then
                        call DEqIncreaseSetEquippedOnUnit(hero, setId)
                    endif
                    call AddDEqStatsOfItemToUnit(pid, eqid, slot, whichItem, hero)
                    set i = i + 1
                endloop
                call UpdateDEqCSheet(pid, hero, GetHandleId(hero), eqid)
            endif
            call DInvRefreshCapacityTextForBID(bid)
            set whichItem = null
            set hero = null
            return true
        endif
        set hero = null
        return PotSStateData_GetDInventoryCapacity() < 0 and PotSStateData_GetEquipmentCount() == 0
    endfunction

    private function PSS_ApplyHero takes player whichPlayer, unit hero returns boolean
        local integer playerId = GetPlayerId(whichPlayer)
        local integer skillDelta
        local boolean abilityPointsWereEnabled = false

        set PSS_ApplyFailureStage[playerId] = PSS_APPLY_STAGE_NONE
        if hero == udg_Zulkis then
            set PSS_ApplyFailureHero[playerId] = "Zul'kis"
        else
            set PSS_ApplyFailureHero[playerId] = "Nazgrek"
        endif

        static if LIBRARY_AbilityPoints then
            set abilityPointsWereEnabled = AbilityPoints_IsHeroLevelUpEnabled()
            call AbilityPoints_DisableHeroLevelUp()
        endif
        call SetHeroXP(hero, PotSStateData_GetHeroXP(), false)
        if GetHeroLevel(hero) != PotSStateData_GetHeroLevel() then
            call SetHeroLevel(hero, PotSStateData_GetHeroLevel(), false)
        endif
        call SetHeroStr(hero, PotSStateData_GetStrength(), true)
        call SetHeroAgi(hero, PotSStateData_GetAgility(), true)
        call SetHeroInt(hero, PotSStateData_GetIntelligence(), true)
        set skillDelta = PotSStateData_GetHeroSkillPoints() - GetHeroSkillPoints(hero)
        if skillDelta != 0 then
            call UnitModifySkillPoints(hero, skillDelta)
        endif
        static if LIBRARY_AbilityPoints then
            if PotSStateData_GetAbilityPoints() >= 0 then
                call AbilityPoints_Set(hero, PotSStateData_GetAbilityPoints())
            endif
            call AbilityPoints_SetHeroLevelUpEnabled(abilityPointsWereEnabled)
        endif

        if not PSS_ApplyAbilities(hero) then
            set PSS_ApplyFailureStage[playerId] = PSS_APPLY_STAGE_ABILITIES
            set whichPlayer = null
            set hero = null
            return false
        endif
        if not PSS_ApplyInventory(hero) then
            set PSS_ApplyFailureStage[playerId] = PSS_APPLY_STAGE_INVENTORY
            set whichPlayer = null
            set hero = null
            return false
        endif
        if not PSS_ApplyDInventoryAndEquipment(hero) then
            set PSS_ApplyFailureStage[playerId] = PSS_APPLY_STAGE_CUSTOM_STORAGE
            set whichPlayer = null
            set hero = null
            return false
        endif
        call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD, PotSStateData_GetGold())
        call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER, PotSStateData_GetLumber())
        if PotSStateData_GetLifeRatio() >= 0 then
            call SetUnitState(hero, UNIT_STATE_LIFE, GetUnitState(hero, UNIT_STATE_MAX_LIFE) * I2R(PotSStateData_GetLifeRatio()) / I2R(PotSSaveConfig_VITAL_SCALE))
        endif
        if PotSStateData_GetManaRatio() >= 0 then
            call SetUnitState(hero, UNIT_STATE_MANA, GetUnitState(hero, UNIT_STATE_MAX_MANA) * I2R(PotSStateData_GetManaRatio()) / I2R(PotSSaveConfig_VITAL_SCALE))
        endif
        call PotSWorldProgression_Apply()
        set whichPlayer = null
        set hero = null
        return true
    endfunction

    private function PSS_IsPartyHeroValid takes unit hero, player owner returns boolean
        return hero != null and GetUnitTypeId(hero) != 0 and IsUnitType(hero, UNIT_TYPE_HERO) and GetOwningPlayer(hero) == owner
    endfunction

    private function PSS_GetMetaId takes string slot returns string
        return PSS_META_PREFIX + slot
    endfunction

    private function PSS_WriteSlotMeta takes integer playerId returns nothing
        local string slot = PSS_LogicalSlot[playerId]
        local string title = slot + " - Nazgrek Lv. " + I2S(PSS_SavedNazgrekLevel[playerId])
        local string data
        local integer heroCount = 1
        local integer mode = 1
        local integer difficulty = 2

        if PSS_PartyHasZulkis[playerId] then
            set heroCount = 2
            set title = title + ", Zul'kis Lv. " + I2S(PSS_SavedZulkisLevel[playerId])
        endif
        static if LIBRARY_GameMode then
            set mode = GameMode_GetMode()
            set difficulty = GameMode_GetDifficulty()
        endif
        set data = I2S(heroCount) + "|" + I2S(mode) + "|" + I2S(difficulty)
        call SaveFile.create(Player(playerId), title, PSS_GetMetaId(slot), data)
    endfunction

    private function PSS_GetMetaValue takes string slot, integer wantedIndex, integer defaultValue returns integer
        local string data = SaveFile.getData(PSS_GetMetaId(slot))
        local string token = ""
        local string character
        local integer index = 0
        local integer i = 0

        if data == null or data == "" then
            return defaultValue
        endif
        loop
            exitwhen i > StringLength(data)
            set character = SubString(data, i, i + 1)
            if character == "|" or i == StringLength(data) then
                if index == wantedIndex then
                    return S2I(token)
                endif
                set token = ""
                set index = index + 1
            else
                set token = token + character
            endif
            set i = i + 1
        endloop
        return defaultValue
    endfunction

    private function PSS_CacheZulkisStream takes nothing returns boolean
        local integer i = 0
        local integer count = PotSStateSerializer_GetCount()

        if count < 1 or count > PotSSaveConfig_MAX_STREAM_VALUES then
            return false
        endif
        set PSS_ZulkisStreamCount = count
        loop
            exitwhen i >= count
            set PSS_ZulkisStreamValue[i] = PotSStateSerializer_GetValue(i)
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSS_RestoreZulkisStream takes nothing returns boolean
        local integer i = 0

        if PSS_ZulkisStreamCount < 1 or PSS_ZulkisStreamCount > PotSSaveConfig_MAX_STREAM_VALUES then
            return false
        endif
        call PotSStateSerializer_BeginInput()
        loop
            exitwhen i >= PSS_ZulkisStreamCount
            if not PotSStateSerializer_PushInput(PSS_ZulkisStreamValue[i]) then
                return false
            endif
            set i = i + 1
        endloop
        return PotSStateSerializer_Deserialize()
    endfunction

    private function PSS_PrepareHeroStream takes integer playerId, unit hero returns boolean
        local integer errorCode

        set PSS_LastError[playerId] = PotSSaveConfig_ERROR_NONE
        if not PotSStateScanner_Scan(Player(playerId), hero) then
            set PSS_LastError[playerId] = PotSSaveConfig_ERROR_SCAN_FAILED
            set hero = null
            return false
        elseif not PotSStateMigration_Validate() then
            set PSS_LastError[playerId] = PotSSaveConfig_ERROR_INVALID_DATA
            set hero = null
            return false
        elseif not PotSStateSerializer_Serialize() then
            set errorCode = PotSStateSerializer_GetLastError()
            if errorCode == PotSSaveConfig_ERROR_NONE then
                set errorCode = PotSSaveConfig_ERROR_SCAN_FAILED
            endif
            set PSS_LastError[playerId] = errorCode
            set hero = null
            return false
        endif
        set hero = null
        return true
    endfunction

    private function PSS_ScanAndSaveHero takes integer playerId, unit hero, string physicalSlot returns boolean
        if not PSS_PrepareHeroStream(playerId, hero) then
            set hero = null
            return false
        endif
        // Publish the level from the exact snapshot being encoded rather than
        // from mutable hero handles retained across the two async saves.
        if PSS_PartyPhase[playerId] == PSS_PHASE_SAVE_NAZGREK then
            set PSS_SavedNazgrekLevel[playerId] = PotSStateData_GetHeroLevel()
        elseif PSS_PartyPhase[playerId] == PSS_PHASE_SAVE_ZULKIS then
            set PSS_SavedZulkisLevel[playerId] = PotSStateData_GetHeroLevel()
        endif
        set PSS_OperationHero[playerId] = hero
        if not PotSMaxouNSLAdapter_Save(playerId, physicalSlot) then
            set PSS_LastError[playerId] = PotSSaveConfig_ERROR_INVALID_SLOT
            set PSS_OperationHero[playerId] = null
            set hero = null
            return false
        endif
        set hero = null
        return true
    endfunction

    private function PSS_PrepareZulkisForLoad takes integer playerId returns unit
        local unit hero = udg_Zulkis
        local unit nazgrek = udg_Nazgrek

        if hero == null or GetUnitTypeId(hero) == 0 or not IsUnitType(hero, UNIT_TYPE_HERO) then
            set nazgrek = null
            set hero = null
            return null
        endif
        call SetUnitOwner(hero, Player(playerId), true)
        call SetUnitInvulnerable(hero, false)
        call PauseUnit(hero, false)
        call ShowUnit(hero, true)
        if nazgrek != null and GetUnitTypeId(nazgrek) != 0 then
            call SetUnitPosition(hero, GetUnitX(nazgrek) + 96.00, GetUnitY(nazgrek))
        endif
        static if LIBRARY_DInventory then
            call InitializeDInventoryForUnit(hero)
        endif
        static if LIBRARY_DEquipment then
            call InitializeDEquipmentForUnit(hero)
        endif
        set nazgrek = null
        return hero
    endfunction

    private function PSS_FinishSuccessfulLoad takes integer playerId returns nothing
        set PSS_Restoring = false
        set PSS_Busy[playerId] = false
        set PSS_Loaded[playerId] = true
        set PSS_LoadAllowed[playerId] = false
        set PSS_LastError[playerId] = PotSSaveConfig_ERROR_NONE
        set PSS_OperationHero[playerId] = null
        set PSS_PartyPhase[playerId] = PSS_PHASE_NONE
        set PSS_ZulkisStreamCount = 0
        set EventWarningCount = PotSWorldProgression_GetSkippedCount()
        if EventWarningCount > 0 then
            call PSS_Message(playerId, "|cffffcc00[PotS SaveLoad]|r ", "Skipped " + I2S(EventWarningCount) + " saved quest entries that are not uniquely present in this map version.")
            call PSS_Fire(OnWarning, playerId, PotSSaveConfig_ERROR_NONE)
        endif
        call PSS_Message(playerId, "|cff33ff33[PotS SaveLoad]|r ", "Load completed.")
        call PSS_Fire(OnLoadComplete, playerId, PotSSaveConfig_ERROR_NONE)
        call ExecuteFunc("Start_ContinueAfterLoad")
    endfunction

    private function PSS_OnBackendSave takes integer playerId, boolean success, integer errorCode returns nothing
        local unit zulkis = null

        if not success then
            set PSS_PartyPhase[playerId] = PSS_PHASE_NONE
            call PSS_Fail(playerId, errorCode, false)
            return
        endif
        if PSS_PartyPhase[playerId] == PSS_PHASE_SAVE_NAZGREK and PSS_PartyHasZulkis[playerId] then
            set zulkis = udg_Zulkis
            set PSS_PartyPhase[playerId] = PSS_PHASE_SAVE_ZULKIS
            if not PSS_ScanAndSaveHero(playerId, zulkis, PSS_LogicalSlot[playerId] + "_z") then
                set zulkis = null
                set PSS_PartyPhase[playerId] = PSS_PHASE_NONE
                call PSS_Fail(playerId, PSS_LastError[playerId], false)
                return
            endif
            set zulkis = null
            return
        endif

        call PSS_WriteSlotMeta(playerId)
        set PSS_Busy[playerId] = false
        set PSS_OperationHero[playerId] = null
        set PSS_PartyPhase[playerId] = PSS_PHASE_NONE
        set PSS_LastError[playerId] = PotSSaveConfig_ERROR_NONE
        call PSS_Message(playerId, "|cff33ff33[PotS SaveLoad]|r ", "Party save completed.")
        call PSS_Fire(OnSaveComplete, playerId, PotSSaveConfig_ERROR_NONE)
    endfunction

    private function PSS_OnBackendLoad takes integer playerId, boolean success, integer errorCode returns nothing
        local unit hero = PSS_OperationHero[playerId]

        if not success then
            set PSS_OperationHero[playerId] = null
            set hero = null
            call PSS_Fail(playerId, errorCode, true)
            return
        endif
        if PSS_PartyPhase[playerId] == PSS_PHASE_VALIDATE_ZULKIS and not PSS_CacheZulkisStream() then
            set PSS_OperationHero[playerId] = null
            set hero = null
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_CAPACITY, true)
            return
        endif
        if not PotSStateMigration_Migrate() or not PotSStateMigration_Validate() then
            set PSS_OperationHero[playerId] = null
            set hero = null
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_INVALID_DATA, true)
            return
        endif
        if not PSS_Preflight(hero) then
            call PSS_ClearPreparedItems()
            set PSS_OperationHero[playerId] = null
            set hero = null
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_PREFLIGHT, true)
            return
        endif
        if PSS_PartyPhase[playerId] == PSS_PHASE_VALIDATE_ZULKIS then
            call PSS_ClearPreparedItems()
            set hero = udg_Nazgrek
            if not PSS_IsPartyHeroValid(hero, Player(playerId)) then
                set PSS_OperationHero[playerId] = null
                set hero = null
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_NO_HERO, true)
                return
            endif
            set PSS_PartyPhase[playerId] = PSS_PHASE_LOAD_NAZGREK
            set PSS_OperationHero[playerId] = hero
            if not PotSMaxouNSLAdapter_Load(playerId, PSS_LogicalSlot[playerId] + "_n") then
                set PSS_OperationHero[playerId] = null
                set hero = null
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_INVALID_SLOT, true)
                return
            endif
            set hero = null
            return
        endif

        set PSS_Restoring = true
        call PotSStateTracker_SetSuppressed(true)
        if not PSS_ApplyHero(Player(playerId), hero) then
            call PotSStateTracker_SetSuppressed(false)
            call PSS_ClearPreparedItems()
            set PSS_Restoring = false
            set PSS_Loaded[playerId] = true
            set PSS_LoadAllowed[playerId] = false
            set PSS_OperationHero[playerId] = null
            set hero = null
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_APPLY_FAILED, true)
            return
        endif
        call PotSStateTracker_SetSuppressed(false)
        set PSS_Restoring = false
        if PSS_PartyPhase[playerId] == PSS_PHASE_LOAD_NAZGREK and PSS_PartyHasZulkis[playerId] then
            set hero = PSS_PrepareZulkisForLoad(playerId)
            if hero == null then
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_NO_HERO, true)
                return
            endif
            set PSS_PartyPhase[playerId] = PSS_PHASE_LOAD_ZULKIS
            set PSS_OperationHero[playerId] = hero
            if not PSS_RestoreZulkisStream() then
                set PSS_ApplyFailureStage[playerId] = PSS_APPLY_STAGE_ZULKIS_STREAM
                set PSS_ApplyFailureHero[playerId] = "Zul'kis"
                set PSS_Loaded[playerId] = true
                set PSS_LoadAllowed[playerId] = false
                set hero = null
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_APPLY_FAILED, true)
                return
            endif
            call PSS_OnBackendLoad(playerId, true, PotSSaveConfig_ERROR_NONE)
            set hero = null
            return
        endif
        call PSS_FinishSuccessfulLoad(playerId)
        set hero = null
    endfunction

    public function RequestSave takes player whichPlayer, string slot returns boolean
        local integer playerId
        local unit hero
        local unit zulkis

        if whichPlayer == null then
            return false
        endif
        set playerId = GetPlayerId(whichPlayer)
        set PSS_ApplyFailureStage[playerId] = PSS_APPLY_STAGE_NONE
        set PSS_ApplyFailureHero[playerId] = "character"
        set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_NONE
        set PSS_PreflightFailureHero[playerId] = "character"
        if not PSS_IsSinglePlayer() then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_SINGLE_PLAYER_ONLY, false)
            set whichPlayer = null
            return false
        elseif PSS_Busy[playerId] then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_BUSY, false)
            set whichPlayer = null
            return false
        elseif not PotSMaxouNSLAdapter_IsValidSlot(slot) then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_INVALID_SLOT, false)
            set whichPlayer = null
            return false
        endif

        set hero = udg_Nazgrek
        if not PSS_IsPartyHeroValid(hero, whichPlayer) then
            set hero = PSS_ResolveHero(whichPlayer)
        endif
        // Never let the generic fallback publish Zul'kis under Nazgrek's
        // physical party slot while Nazgrek is temporarily unavailable.
        if hero == udg_Zulkis then
            set hero = null
        endif
        if hero == null then
            if PSS_ResolveAmbiguous then
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_AMBIGUOUS_HERO, false)
            else
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_NO_HERO, false)
            endif
            set whichPlayer = null
            return false
        endif
        set PSS_LogicalSlot[playerId] = slot
        set PSS_PartyPhase[playerId] = PSS_PHASE_SAVE_NAZGREK
        set PSS_SavedNazgrekLevel[playerId] = 0
        set PSS_SavedZulkisLevel[playerId] = 0
        set zulkis = udg_Zulkis
        set PSS_PartyHasZulkis[playerId] = zulkis != hero and PSS_IsPartyHeroValid(zulkis, whichPlayer)
        if PSS_PartyHasZulkis[playerId] and not PSS_PrepareHeroStream(playerId, zulkis) then
            set hero = null
            set zulkis = null
            set whichPlayer = null
            call PSS_Fail(playerId, PSS_LastError[playerId], false)
            return false
        endif
        set PSS_Busy[playerId] = true
        if not PSS_ScanAndSaveHero(playerId, hero, slot + "_n") then
            set PSS_OperationHero[playerId] = null
            set hero = null
            set zulkis = null
            set whichPlayer = null
            call PSS_Fail(playerId, PSS_LastError[playerId], false)
            return false
        endif
        set hero = null
        set zulkis = null
        set whichPlayer = null
        return true
    endfunction

    public function RequestLoad takes player whichPlayer, string slot returns boolean
        local integer playerId
        local unit hero

        if whichPlayer == null then
            return false
        endif
        set playerId = GetPlayerId(whichPlayer)
        set PSS_ApplyFailureStage[playerId] = PSS_APPLY_STAGE_NONE
        set PSS_ApplyFailureHero[playerId] = "character"
        set PSS_PreflightFailureStage[playerId] = PSS_PREFLIGHT_STAGE_NONE
        set PSS_PreflightFailureHero[playerId] = "character"
        if not PSS_IsSinglePlayer() then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_SINGLE_PLAYER_ONLY, true)
            set whichPlayer = null
            return false
        elseif PSS_Busy[playerId] then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_BUSY, true)
            set whichPlayer = null
            return false
        elseif PSS_Loaded[playerId] then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_ALREADY_LOADED, true)
            set whichPlayer = null
            return false
        elseif not PSS_LoadAllowed[playerId] then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_LOAD_LOCKED, true)
            set whichPlayer = null
            return false
        elseif not PotSMaxouNSLAdapter_IsValidSlot(slot) then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_INVALID_SLOT, true)
            set whichPlayer = null
            return false
        elseif not SaveFile.exists(PSS_GetMetaId(slot)) or not SaveFile.exists("pots_" + slot + "_n") then
            call PSS_Fail(playerId, PotSSaveConfig_ERROR_FILE_NOT_FOUND, true)
            set whichPlayer = null
            return false
        endif

        set hero = udg_Nazgrek
        if not PSS_IsPartyHeroValid(hero, whichPlayer) then
            set hero = PSS_ResolveHero(whichPlayer)
        endif
        if hero == udg_Zulkis then
            set hero = null
        endif
        if hero == null then
            if PSS_ResolveAmbiguous then
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_AMBIGUOUS_HERO, true)
            else
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_NO_HERO, true)
            endif
            set whichPlayer = null
            return false
        endif

        set PSS_Busy[playerId] = true
        set PSS_ZulkisStreamCount = 0
        set PSS_LogicalSlot[playerId] = slot
        set PSS_PartyHasZulkis[playerId] = SaveFile.exists(PSS_GetMetaId(slot)) and PSS_GetMetaValue(slot, 0, 1) >= 2
        if PSS_PartyHasZulkis[playerId] then
            if udg_Zulkis == null or GetUnitTypeId(udg_Zulkis) == 0 or not IsUnitType(udg_Zulkis, UNIT_TYPE_HERO) then
                set PSS_Busy[playerId] = false
                set hero = null
                set whichPlayer = null
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_NO_HERO, true)
                return false
            elseif not SaveFile.exists("pots_" + slot + "_z") then
                set PSS_Busy[playerId] = false
                set hero = null
                set whichPlayer = null
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_FILE_NOT_FOUND, true)
                return false
            endif
            set PSS_PartyPhase[playerId] = PSS_PHASE_VALIDATE_ZULKIS
            set PSS_OperationHero[playerId] = udg_Zulkis
            if not PotSMaxouNSLAdapter_Load(playerId, slot + "_z") then
                set PSS_OperationHero[playerId] = null
                set hero = null
                set whichPlayer = null
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_INVALID_SLOT, true)
                return false
            endif
        else
            set PSS_PartyPhase[playerId] = PSS_PHASE_LOAD_NAZGREK
            set PSS_OperationHero[playerId] = hero
            if not PotSMaxouNSLAdapter_Load(playerId, slot + "_n") then
                set PSS_OperationHero[playerId] = null
                set hero = null
                set whichPlayer = null
                call PSS_Fail(playerId, PotSSaveConfig_ERROR_INVALID_SLOT, true)
                return false
            endif
        endif
        set hero = null
        set whichPlayer = null
        return true
    endfunction

    public function SetHero takes player whichPlayer, unit hero returns boolean
        local integer playerId
        if whichPlayer == null or hero == null or GetOwningPlayer(hero) != whichPlayer or not IsUnitType(hero, UNIT_TYPE_HERO) then
            set whichPlayer = null
            set hero = null
            return false
        endif
        set playerId = GetPlayerId(whichPlayer)
        set PSS_RegisteredHero[playerId] = hero
        set whichPlayer = null
        set hero = null
        return true
    endfunction

    public function SetLoadAllowed takes player whichPlayer, boolean allowed returns nothing
        if whichPlayer != null then
            set PSS_LoadAllowed[GetPlayerId(whichPlayer)] = allowed
            if allowed and PSS_LoadWindowTimer != null then
                call PauseTimer(PSS_LoadWindowTimer)
                call DestroyTimer(PSS_LoadWindowTimer)
                set PSS_LoadWindowTimer = null
            endif
        endif
        set whichPlayer = null
    endfunction

    public function IsRestoring takes nothing returns boolean
        return PSS_Restoring
    endfunction

    public function CanRecoverFromLoadFailure takes player whichPlayer returns boolean
        local boolean result = false
        if whichPlayer != null then
            set result = not PSS_Loaded[GetPlayerId(whichPlayer)]
        endif
        set whichPlayer = null
        return result
    endfunction

    public function GetLastError takes player whichPlayer returns integer
        local integer result = PotSSaveConfig_ERROR_INVALID_DATA
        if whichPlayer != null then
            set result = PSS_LastError[GetPlayerId(whichPlayer)]
        endif
        set whichPlayer = null
        return result
    endfunction

    public function IsBusy takes player whichPlayer returns boolean
        local boolean result = false
        if whichPlayer != null then
            set result = PSS_Busy[GetPlayerId(whichPlayer)]
        endif
        set whichPlayer = null
        return result
    endfunction

    public function SlotExists takes string slot returns boolean
        if not PotSMaxouNSLAdapter_IsValidSlot(slot) then
            return false
        endif
        if not SaveFile.exists(PSS_GetMetaId(slot)) or not SaveFile.exists("pots_" + slot + "_n") then
            return false
        endif
        return PSS_GetMetaValue(slot, 0, 1) < 2 or SaveFile.exists("pots_" + slot + "_z")
    endfunction

    public function GetSlotTitle takes string slot returns string
        if not SlotExists(slot) then
            return ""
        endif
        return SaveFile.getTitle(PSS_GetMetaId(slot))
    endfunction

    public function GetSlotMode takes string slot returns integer
        return PSS_GetMetaValue(slot, 1, 1)
    endfunction

    public function GetSlotDifficulty takes string slot returns integer
        return PSS_GetMetaValue(slot, 2, 2)
    endfunction

    public function StartPendingLoad takes nothing returns nothing
        static if LIBRARY_Start then
            local string slot = Start_GetPendingLoadSlot()
            if slot != "" then
                call RequestLoad(Player(0), slot)
            else
                call ExecuteFunc("Start_ContinueAfterLoad")
            endif
        else
            call ExecuteFunc("Start_ContinueAfterLoad")
        endif
    endfunction

    public function AddSaveCompleteAction takes code actionFunc returns triggeraction
        return TriggerAddAction(OnSaveComplete, actionFunc)
    endfunction

    public function AddSaveFailedAction takes code actionFunc returns triggeraction
        return TriggerAddAction(OnSaveFailed, actionFunc)
    endfunction

    public function AddLoadCompleteAction takes code actionFunc returns triggeraction
        return TriggerAddAction(OnLoadComplete, actionFunc)
    endfunction

    public function AddLoadFailedAction takes code actionFunc returns triggeraction
        return TriggerAddAction(OnLoadFailed, actionFunc)
    endfunction

    public function AddWarningAction takes code actionFunc returns triggeraction
        return TriggerAddAction(OnWarning, actionFunc)
    endfunction

    private function PSS_CloseInitialLoadWindow takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set PSS_LoadAllowed[i] = false
            set i = i + 1
        endloop
        call DestroyTimer(PSS_LoadWindowTimer)
        set PSS_LoadWindowTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set PSS_LoadAllowed[i] = true
            set i = i + 1
        endloop
        call PotSMaxouNSLAdapter_SetSaveCallback(PSS_OnBackendSave)
        call PotSMaxouNSLAdapter_SetLoadCallback(PSS_OnBackendLoad)
        set PSS_LoadWindowTimer = CreateTimer()
        call TimerStart(PSS_LoadWindowTimer, PotSSaveConfig_LOAD_WINDOW_SECONDS, false, function PSS_CloseInitialLoadWindow)
    endfunction
endlibrary
