/**
    PotSStateMigration

    Author: Valdemar
    Version: 2.1.0

    Description:
    Migrates decoded PotS schema 1/2 snapshots to the current schema, applies
    explicit rawcode rename maps, defaults optional fields, and validates bounds.

    Credits:
    - StateSaver by Tomotz, forward-migration architecture

    How to install:
    Import after PotSStateData and before PotSSaveLoad.

    API:
    - PotSStateMigration_RegisterHeroRawcode(oldId, newId)
    - PotSStateMigration_RegisterAbilityRawcode(oldId, newId)
    - PotSStateMigration_RegisterItemRawcode(oldId, newId)
    - PotSStateMigration_RegisterQuestIdentity(oldNameHash, oldGiverType,
      newNameHash, newGiverType)
    - PotSStateMigration_Migrate()
    - PotSStateMigration_Validate()

**/
library PotSStateMigration requires PotSSaveConfig, PotSStateData, optional AbilitiesPlayer
    globals
        private constant integer PSM_KIND_HERO = 1
        private constant integer PSM_KIND_ABILITY = 2
        private constant integer PSM_KIND_ITEM = 3

        private integer PSM_Count = 0
        private integer array PSM_Kind
        private integer array PSM_OldId
        private integer array PSM_NewId
        private integer PSM_WorldCount = 0
        private integer array PSM_OldWorldNameHash
        private integer array PSM_OldWorldGiverType
        private integer array PSM_NewWorldNameHash
        private integer array PSM_NewWorldGiverType
    endglobals

    private function PSM_Register takes integer kind, integer oldId, integer newId returns boolean
        local integer i = 0
        if oldId == 0 or newId == 0 or oldId == newId or PSM_Count >= PotSSaveConfig_MAX_RAWCODE_MIGRATIONS then
            return false
        endif
        loop
            exitwhen i >= PSM_Count
            if PSM_Kind[i] == kind and PSM_OldId[i] == oldId then
                return false
            endif
            set i = i + 1
        endloop
        set PSM_Kind[PSM_Count] = kind
        set PSM_OldId[PSM_Count] = oldId
        set PSM_NewId[PSM_Count] = newId
        set PSM_Count = PSM_Count + 1
        return true
    endfunction

    private function PSM_Map takes integer kind, integer rawcode returns integer
        local integer i = 0
        loop
            exitwhen i >= PSM_Count
            if PSM_Kind[i] == kind and PSM_OldId[i] == rawcode then
                return PSM_NewId[i]
            endif
            set i = i + 1
        endloop
        return rawcode
    endfunction

    public function RegisterHeroRawcode takes integer oldId, integer newId returns boolean
        return PSM_Register(PSM_KIND_HERO, oldId, newId)
    endfunction

    public function RegisterAbilityRawcode takes integer oldId, integer newId returns boolean
        return PSM_Register(PSM_KIND_ABILITY, oldId, newId)
    endfunction

    public function RegisterItemRawcode takes integer oldId, integer newId returns boolean
        return PSM_Register(PSM_KIND_ITEM, oldId, newId)
    endfunction

    public function RegisterQuestIdentity takes integer oldNameHash, integer oldGiverType, integer newNameHash, integer newGiverType returns boolean
        local integer i = 0
        if (oldNameHash == newNameHash and oldGiverType == newGiverType) or PSM_WorldCount >= PotSSaveConfig_MAX_WORLD_MIGRATIONS then
            return false
        endif
        loop
            exitwhen i >= PSM_WorldCount
            if PSM_OldWorldNameHash[i] == oldNameHash and PSM_OldWorldGiverType[i] == oldGiverType then
                return false
            endif
            set i = i + 1
        endloop
        set PSM_OldWorldNameHash[PSM_WorldCount] = oldNameHash
        set PSM_OldWorldGiverType[PSM_WorldCount] = oldGiverType
        set PSM_NewWorldNameHash[PSM_WorldCount] = newNameHash
        set PSM_NewWorldGiverType[PSM_WorldCount] = newGiverType
        set PSM_WorldCount = PSM_WorldCount + 1
        return true
    endfunction

    private function PSM_MapWorldIndex takes integer nameHash, integer giverType returns integer
        local integer i = 0
        loop
            exitwhen i >= PSM_WorldCount
            if PSM_OldWorldNameHash[i] == nameHash and PSM_OldWorldGiverType[i] == giverType then
                return i
            endif
            set i = i + 1
        endloop
        return -1
    endfunction

    private function PSM_ClassifyAbilities takes nothing returns nothing
        local integer i = 0
        local integer abilityId
        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            if PotSStateData_GetAbilitySource(i) == PotSSaveConfig_ABILITY_SOURCE_UNKNOWN then
                set abilityId = PotSStateData_GetAbilityId(i)
                static if LIBRARY_AbilitiesPlayer then
                    if AbilitiesPlayer_GetEntryByAbilityId(abilityId) > 0 then
                        call PotSStateData_SetAbilitySource(abilityId, PotSSaveConfig_ABILITY_SOURCE_CATALOG)
                    else
                        call PotSStateData_SetAbilitySource(abilityId, PotSSaveConfig_ABILITY_SOURCE_TRACKED)
                    endif
                else
                    call PotSStateData_SetAbilitySource(abilityId, PotSSaveConfig_ABILITY_SOURCE_TRACKED)
                endif
            endif
            set i = i + 1
        endloop
    endfunction

    public function Migrate takes nothing returns boolean
        local integer schemaMajor = PotSStateData_GetSchemaMajor()
        local integer i = 0
        local integer worldMigration

        if schemaMajor < PotSSaveConfig_OLDEST_SCHEMA_MAJOR or schemaMajor > PotSSaveConfig_SCHEMA_MAJOR then
            return false
        endif
        call PotSStateData_SetHeroType(PSM_Map(PSM_KIND_HERO, PotSStateData_GetHeroType()))
        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            call PotSStateData_SetAbilityId(i, PSM_Map(PSM_KIND_ABILITY, PotSStateData_GetAbilityId(i)))
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetInventoryCount()
            call PotSStateData_SetInventoryType(i, PSM_Map(PSM_KIND_ITEM, PotSStateData_GetInventoryType(i)))
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetDInventoryCount()
            call PotSStateData_SetDInventoryType(i, PSM_Map(PSM_KIND_ITEM, PotSStateData_GetDInventoryType(i)))
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetEquipmentCount()
            call PotSStateData_SetEquipmentType(i, PSM_Map(PSM_KIND_ITEM, PotSStateData_GetEquipmentType(i)))
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetWorldCount()
            set worldMigration = PSM_MapWorldIndex(PotSStateData_GetWorldNameHash(i), PotSStateData_GetWorldGiverType(i))
            if worldMigration >= 0 then
                call PotSStateData_SetWorldIdentity(i, PSM_NewWorldNameHash[worldMigration], PSM_NewWorldGiverType[worldMigration])
            endif
            set i = i + 1
        endloop

        // Schema 1 had no provenance record. Catalog entries can be derived;
        // all remaining explicitly saved abilities stay tracked and persistent.
        call PSM_ClassifyAbilities()
        call PotSStateData_SetSchema(PotSSaveConfig_SCHEMA_MAJOR, PotSSaveConfig_SCHEMA_MINOR)
        return true
    endfunction

    public function Validate takes nothing returns boolean
        local integer i = 0
        local integer j
        local integer value

        if PotSStateData_GetHeroType() == 0 or PotSStateData_GetHeroLevel() < 1 or PotSStateData_GetHeroLevel() > 1000 or PotSStateData_GetHeroXP() < 0 or PotSStateData_GetHeroSkillPoints() < 0 then
            return false
        endif
        if PotSStateData_GetAbilityPoints() < -1 or PotSStateData_GetStrength() < 0 or PotSStateData_GetAgility() < 0 or PotSStateData_GetIntelligence() < 0 or PotSStateData_GetGold() < 0 or PotSStateData_GetLumber() < 0 then
            return false
        endif
        set value = PotSStateData_GetLifeRatio()
        if value < -1 or value > PotSSaveConfig_VITAL_SCALE then
            return false
        endif
        set value = PotSStateData_GetManaRatio()
        if value < -1 or value > PotSSaveConfig_VITAL_SCALE then
            return false
        endif
        if PotSStateData_GetInventorySize() < 0 or PotSStateData_GetInventorySize() > PotSSaveConfig_MAX_INVENTORY_SLOTS or PotSStateData_GetInventoryCount() > PotSStateData_GetInventorySize() then
            return false
        endif

        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            if PotSStateData_GetAbilityId(i) == 0 or PotSStateData_GetAbilityLevel(i) <= 0 or PotSStateData_GetAbilityLevel(i) > 1000 then
                return false
            endif
            if PotSStateData_GetAbilitySource(i) != PotSSaveConfig_ABILITY_SOURCE_CATALOG and PotSStateData_GetAbilitySource(i) != PotSSaveConfig_ABILITY_SOURCE_TRACKED then
                return false
            endif
            set j = i + 1
            loop
                exitwhen j >= PotSStateData_GetAbilityCount()
                if PotSStateData_GetAbilityId(i) == PotSStateData_GetAbilityId(j) then
                    return false
                endif
                set j = j + 1
            endloop
            set i = i + 1
        endloop

        set i = 0
        loop
            exitwhen i >= PotSStateData_GetInventoryCount()
            if PotSStateData_GetInventorySlot(i) < 0 or PotSStateData_GetInventorySlot(i) >= PotSStateData_GetInventorySize() or PotSStateData_GetInventoryType(i) == 0 or PotSStateData_GetInventoryCharges(i) < 0 then
                return false
            endif
            set i = i + 1
        endloop
        if PotSStateData_GetDInventoryCapacity() < -1 or PotSStateData_GetDInventoryCapacity() > PotSSaveConfig_MAX_DINVENTORY_SLOTS or PotSStateData_GetDInventoryTier() < 0 or PotSStateData_GetDInventoryTier() > 7 or (PotSStateData_GetDInventoryCapacity() < 0 and PotSStateData_GetDInventoryCount() != 0) or (PotSStateData_GetDInventoryCapacity() >= 0 and PotSStateData_GetDInventoryCount() > PotSStateData_GetDInventoryCapacity()) then
            return false
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetDInventoryCount()
            if PotSStateData_GetDInventorySlot(i) < 0 or PotSStateData_GetDInventorySlot(i) >= PotSStateData_GetDInventoryCapacity() or PotSStateData_GetDInventoryType(i) == 0 or PotSStateData_GetDInventoryCharges(i) < 0 then
                return false
            endif
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetEquipmentCount()
            if PotSStateData_GetEquipmentSlot(i) < 1 or PotSStateData_GetEquipmentSlot(i) > PotSSaveConfig_MAX_EQUIPMENT_SLOTS or PotSStateData_GetEquipmentType(i) == 0 or PotSStateData_GetEquipmentCharges(i) < 0 then
                return false
            endif
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetWorldCount()
            if PotSStateData_GetWorldState(i) != PotSSaveConfig_WORLD_FLAG_COMPLETED then
                return false
            endif
            set j = i + 1
            loop
                exitwhen j >= PotSStateData_GetWorldCount()
                if PotSStateData_GetWorldNameHash(i) == PotSStateData_GetWorldNameHash(j) and PotSStateData_GetWorldGiverType(i) == PotSStateData_GetWorldGiverType(j) then
                    return false
                endif
                set j = j + 1
            endloop
            set i = i + 1
        endloop
        return true
    endfunction
endlibrary
