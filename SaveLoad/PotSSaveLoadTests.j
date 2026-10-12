/**
    PotSSaveLoadTests

    Author: Valdemar
    Version: 2.1.0

    Description:
    Manually invoked serializer, ordering, schema-migration, malformed-input,
    and capacity tests. This library has no initializer and no gameplay side
    effects until PotSSaveLoadTests_Run is called from a test map.

    Credits:
    - StateSaver by Tomotz, fixture-driven migration testing concept

    How to install:
    Import only in a test map after AbilitiesPlayer and the PotS state libraries. Call
    PotSSaveLoadTests_Run() and inspect the returned boolean and debug output.

    API:
    - PotSSaveLoadTests_Run()

**/
library PotSSaveLoadTests requires PotSSaveConfig, PotSStateData, PotSStateSerializer, PotSStateMigration, AbilitiesPlayer, optional PotSMaxouNSLAdapter
    globals
        private integer PSTEST_Total = 0
        private integer PSTEST_Failed = 0
        private integer PSTEST_SavedCount = 0
        private integer array PSTEST_SavedValue
    endglobals

    private function PSTEST_Check takes boolean condition, string label returns nothing
        set PSTEST_Total = PSTEST_Total + 1
        if not condition then
            set PSTEST_Failed = PSTEST_Failed + 1
            call BJDebugMsg("PotSSaveLoadTests FAILED: " + label)
        endif
    endfunction

    private function PSTEST_BuildSample takes boolean reverseAbilities returns boolean
        call PotSStateData_Reset()
        call PotSStateData_SetHero('H000', 25, 12345, 4, 7)
        call PotSStateData_SetAttributes(41, 32, 57)
        call PotSStateData_SetResources(98765, 4321)
        call PotSStateData_SetVitals(75000, 50000)
        call PotSStateData_SetInventorySize(6)
        if not PotSStateData_AddInventory(0, 'I001', 0) or not PotSStateData_AddInventory(5, -19088743, 9) then
            return false
        endif
        call PotSStateData_SetDInventory(24, 2, 4)
        if not PotSStateData_AddDInventory(1, 'I002', 3) or not PotSStateData_AddDInventory(23, 'I003', 7) then
            return false
        endif
        if not PotSStateData_AddEquipment(1, 'I004', 0) or not PotSStateData_AddEquipment(20, 'I005', 2) then
            return false
        endif
        if reverseAbilities then
            if not PotSStateData_AddAbilitySorted('AZZ1', 2, PotSSaveConfig_ABILITY_SOURCE_TRACKED) or not PotSStateData_AddAbilitySorted('A6A0', 4, PotSSaveConfig_ABILITY_SOURCE_CATALOG) then
                return false
            endif
        else
            if not PotSStateData_AddAbilitySorted('A6A0', 4, PotSSaveConfig_ABILITY_SOURCE_CATALOG) or not PotSStateData_AddAbilitySorted('AZZ1', 2, PotSSaveConfig_ABILITY_SOURCE_TRACKED) then
                return false
            endif
        endif
        if not PotSStateData_AddWorldFlagSorted(93214, 'n001', PotSSaveConfig_WORLD_FLAG_COMPLETED) or not PotSStateData_AddWorldFlagSorted(-7654321, 0, PotSSaveConfig_WORLD_FLAG_COMPLETED) then
            return false
        endif
        return true
    endfunction

    private function PSTEST_SaveCurrentStream takes nothing returns nothing
        local integer i = 0
        set PSTEST_SavedCount = PotSStateSerializer_GetCount()
        loop
            exitwhen i >= PSTEST_SavedCount
            set PSTEST_SavedValue[i] = PotSStateSerializer_GetValue(i)
            set i = i + 1
        endloop
    endfunction

    private function PSTEST_StreamMatchesSaved takes nothing returns boolean
        local integer i = 0
        if PotSStateSerializer_GetCount() != PSTEST_SavedCount then
            return false
        endif
        loop
            exitwhen i >= PSTEST_SavedCount
            if PotSStateSerializer_GetValue(i) != PSTEST_SavedValue[i] then
                return false
            endif
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSTEST_TestRoundTripAndOrdering takes nothing returns nothing
        call PSTEST_Check(PSTEST_BuildSample(false), "build canonical sample")
        call PSTEST_Check(PotSStateSerializer_Serialize(), "serialize canonical sample")
        call PSTEST_Check(PotSStateSerializer_GetCount() == 77, "representative party-hero sample integer count")
        call PSTEST_SaveCurrentStream()

        call PSTEST_Check(PSTEST_BuildSample(true), "build reverse-order sample")
        call PSTEST_Check(PotSStateSerializer_Serialize(), "serialize reverse-order sample")
        call PSTEST_Check(PSTEST_StreamMatchesSaved(), "stable ability and world ordering")
        call PSTEST_Check(PotSStateSerializer_Deserialize(), "deserialize schema 2.1 sample")
        call PSTEST_Check(PotSStateMigration_Migrate(), "migrate current sample")
        call PSTEST_Check(PotSStateMigration_Validate(), "validate current sample")
        call PSTEST_Check(PotSStateData_GetHeroType() == 'H000' and PotSStateData_GetHeroLevel() == 25 and PotSStateData_GetHeroXP() == 12345, "hero identity and progress roundtrip")
        call PSTEST_Check(PotSStateData_GetInventoryCount() == 2 and PotSStateData_GetInventoryCharges(1) == 9 and PotSStateData_GetInventoryType(1) == -19088743, "inventory and signed rawcode roundtrip")
        call PSTEST_Check(PotSStateData_GetDInventoryCapacity() == 24 and PotSStateData_GetDInventoryTier() == 2 and PotSStateData_GetDInventoryAdditional() == 4 and PotSStateData_GetDInventoryCount() == 2 and PotSStateData_GetDInventorySlot(1) == 23, "custom inventory layout roundtrip")
        call PSTEST_Check(PotSStateData_GetEquipmentCount() == 2 and PotSStateData_GetEquipmentSlot(1) == 20 and PotSStateData_GetEquipmentCharges(1) == 2, "equipment layout roundtrip")
        call PSTEST_Check(PotSStateData_GetAbilityCount() == 2 and PotSStateData_GetAbilityId(0) < PotSStateData_GetAbilityId(1), "ability order roundtrip")
        call PSTEST_Check(PotSStateData_GetWorldCount() == 2 and PotSStateData_GetWorldNameHash(0) == -7654321, "signed world identity roundtrip")
        call PSTEST_Check(PotSStateSerializer_Serialize(), "serialize decoded and migrated sample")
        call PSTEST_Check(PSTEST_StreamMatchesSaved(), "save-load-save stream stability")

        call PotSStateData_Reset()
        call PotSStateData_AddAbilitySorted('A6A0', 2, PotSSaveConfig_ABILITY_SOURCE_TRACKED)
        call PotSStateData_AddAbilitySorted('A6A0', 2, PotSSaveConfig_ABILITY_SOURCE_CATALOG)
        call PSTEST_Check(PotSStateData_GetAbilityCount() == 1 and PotSStateData_GetAbilitySource(0) == PotSSaveConfig_ABILITY_SOURCE_CATALOG, "catalog provenance overrides learn-event duplicate")
    endfunction

    private function PSTEST_PushSchema1Fixture takes nothing returns nothing
        call PotSStateSerializer_BeginInput()
        call PotSStateSerializer_PushInput(PotSSaveConfig_MAGIC)
        call PotSStateSerializer_PushInput(1)
        call PotSStateSerializer_PushInput(0)
        call PotSStateSerializer_PushInput(7)
        call PotSStateSerializer_PushInput(PotSSaveConfig_TAG_HERO_IDENTITY)
        call PotSStateSerializer_PushInput(1)
        call PotSStateSerializer_PushInput('H000')
        call PotSStateSerializer_PushInput(PotSSaveConfig_TAG_HERO_PROGRESS)
        call PotSStateSerializer_PushInput(3)
        call PotSStateSerializer_PushInput(12)
        call PotSStateSerializer_PushInput(4400)
        call PotSStateSerializer_PushInput(3)
        call PotSStateSerializer_PushInput(PotSSaveConfig_TAG_HERO_ATTRIBUTES)
        call PotSStateSerializer_PushInput(3)
        call PotSStateSerializer_PushInput(20)
        call PotSStateSerializer_PushInput(21)
        call PotSStateSerializer_PushInput(22)
        call PotSStateSerializer_PushInput(PotSSaveConfig_TAG_ABILITIES)
        call PotSStateSerializer_PushInput(3)
        call PotSStateSerializer_PushInput(1)
        call PotSStateSerializer_PushInput('AZZ1')
        call PotSStateSerializer_PushInput(2)
        call PotSStateSerializer_PushInput(PotSSaveConfig_TAG_INVENTORY)
        call PotSStateSerializer_PushInput(2)
        call PotSStateSerializer_PushInput(6)
        call PotSStateSerializer_PushInput(0)
        call PotSStateSerializer_PushInput(PotSSaveConfig_TAG_RESOURCES)
        call PotSStateSerializer_PushInput(2)
        call PotSStateSerializer_PushInput(100)
        call PotSStateSerializer_PushInput(50)
        call PotSStateSerializer_PushInput(777)
        call PotSStateSerializer_PushInput(2)
        call PotSStateSerializer_PushInput(-12)
        call PotSStateSerializer_PushInput(34)
    endfunction

    private function PSTEST_TestSchema1Migration takes nothing returns nothing
        call PSTEST_PushSchema1Fixture()
        call PSTEST_Check(PotSStateSerializer_Deserialize(), "schema 1 fixture and unknown record decode")
        call PSTEST_Check(PotSStateData_GetAbilityPoints() == -1 and PotSStateData_GetLifeRatio() == -1 and PotSStateData_GetWorldCount() == 0 and PotSStateData_GetDInventoryCapacity() == -1 and PotSStateData_GetEquipmentCount() == 0, "schema 1 optional defaults")
        call PSTEST_Check(PotSStateMigration_Migrate(), "schema 1 to current schema migration")
        call PSTEST_Check(PotSStateData_GetSchemaMajor() == PotSSaveConfig_SCHEMA_MAJOR and PotSStateData_GetSchemaMinor() == PotSSaveConfig_SCHEMA_MINOR, "schema migration target")
        call PSTEST_Check(PotSStateMigration_Validate(), "migrated schema 1 fixture validates")
    endfunction

    private function PSTEST_TestQuestIdentityMigration takes nothing returns nothing
        call PotSStateData_Reset()
        call PotSStateData_SetSchema(1, 0)
        call PotSStateData_AddWorldFlagSorted(8100, 8200, PotSSaveConfig_WORLD_FLAG_COMPLETED)
        call PotSStateMigration_RegisterQuestIdentity(8100, 8200, 9100, 9200)
        call PSTEST_Check(PotSStateMigration_Migrate(), "quest identity migration executes")
        call PSTEST_Check(PotSStateData_GetWorldNameHash(0) == 9100 and PotSStateData_GetWorldGiverType(0) == 9200, "renamed quest identity migrates to current namespace")
    endfunction

    private function PSTEST_TestItemRawcodeMigration takes nothing returns nothing
        call PotSStateData_Reset()
        call PotSStateData_SetSchema(PotSSaveConfig_SCHEMA_MAJOR, PotSSaveConfig_SCHEMA_MINOR)
        call PotSStateData_SetHero('H000', 1, 0, 0, -1)
        call PotSStateData_SetAttributes(1, 1, 1)
        call PotSStateData_SetResources(0, 0)
        call PotSStateData_SetInventorySize(1)
        call PotSStateData_SetVitals(-1, -1)
        call PotSStateData_AddInventory(0, 'IOld', 0)
        call PotSStateData_SetDInventory(1, 0, 0)
        call PotSStateData_AddDInventory(0, 'IOld', 1)
        call PotSStateData_AddEquipment(1, 'IOld', 2)
        call PSTEST_Check(PotSStateMigration_RegisterItemRawcode('IOld', 'INew'), "register item rawcode migration")
        call PSTEST_Check(PotSStateMigration_Migrate(), "item rawcode migration executes")
        call PSTEST_Check(PotSStateData_GetInventoryType(0) == 'INew' and PotSStateData_GetDInventoryType(0) == 'INew' and PotSStateData_GetEquipmentType(0) == 'INew', "item rawcode migration covers every inventory owner")
    endfunction

    private function PSTEST_TestRepresentativeSizes takes nothing returns nothing
        local integer i = 0

        call PotSStateData_Reset()
        call PotSStateData_SetHero('H000', 1, 0, 0, -1)
        call PotSStateData_SetAttributes(1, 1, 1)
        call PotSStateData_SetResources(0, 0)
        call PotSStateData_SetInventorySize(0)
        call PotSStateData_SetVitals(-1, -1)
        call PSTEST_Check(PotSStateSerializer_Serialize() and PotSStateSerializer_GetCount() == 48, "smallest snapshot uses 48 integers")

        call PotSStateData_Reset()
        call PotSStateData_SetHero('H000', 100, 999999, 10, 25)
        call PotSStateData_SetAttributes(100, 100, 100)
        call PotSStateData_SetResources(1000000, 1000000)
        call PotSStateData_SetInventorySize(6)
        call PotSStateData_SetVitals(PotSSaveConfig_VITAL_SCALE, PotSSaveConfig_VITAL_SCALE)
        loop
            exitwhen i >= 6
            call PotSStateData_AddInventory(i, 2000 + i, i)
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= 40
            call PotSStateData_AddAbilitySorted(3000 + i, 5, PotSSaveConfig_ABILITY_SOURCE_TRACKED)
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= 100
            call PotSStateData_AddWorldFlagSorted(4000 + i, 0, PotSSaveConfig_WORLD_FLAG_COMPLETED)
            set i = i + 1
        endloop
        call PSTEST_Check(PotSStateSerializer_Serialize() and PotSStateSerializer_GetCount() == 486, "large representative snapshot uses 486 integers")
        static if LIBRARY_PotSMaxouNSLAdapter then
            call PSTEST_Check(PotSMaxouNSLAdapter_GetEstimatedCodeCharacters(48) == 267, "smallest snapshot estimated code size")
            call PSTEST_Check(PotSMaxouNSLAdapter_GetEstimatedCodeCharacters(486) == 2603, "large representative estimated code size")
            call PSTEST_Check(PotSMaxouNSLAdapter_GetEstimatedCodeCharacters(PotSSaveConfig_MAX_STREAM_VALUES) == 5344, "maximum configured code size")
        endif

        call PotSStateData_Reset()
        call PotSStateData_SetHero('H000', 100, 999999, 10, 25)
        call PotSStateData_SetAttributes(100, 100, 100)
        call PotSStateData_SetResources(1000000, 1000000)
        call PotSStateData_SetInventorySize(PotSSaveConfig_MAX_INVENTORY_SLOTS)
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_INVENTORY_SLOTS
            call PotSStateData_AddInventory(i, 5000 + i, i)
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_ABILITIES
            call PotSStateData_AddAbilitySorted(6000 + i, 5, PotSSaveConfig_ABILITY_SOURCE_TRACKED)
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_WORLD_FLAGS
            call PotSStateData_AddWorldFlagSorted(7000 + i, 0, PotSSaveConfig_WORLD_FLAG_COMPLETED)
            set i = i + 1
        endloop
        call PotSStateData_SetDInventory(PotSSaveConfig_MAX_DINVENTORY_SLOTS, 7, 0)
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_DINVENTORY_SLOTS
            call PotSStateData_AddDInventory(i, 8000 + i, i)
            set i = i + 1
        endloop
        call PSTEST_Check(not PotSStateSerializer_Serialize() and PotSStateSerializer_GetLastError() == PotSSaveConfig_ERROR_CAPACITY, "combined category maximum rejects before file overwrite")
    endfunction

    private function PSTEST_TestCustomStorageValidation takes nothing returns nothing
        call PotSStateData_Reset()
        call PotSStateData_SetHero('H000', 1, 0, 0, -1)
        call PotSStateData_SetAttributes(1, 1, 1)
        call PotSStateData_SetResources(0, 0)
        call PotSStateData_SetInventorySize(0)
        call PotSStateData_SetVitals(-1, -1)
        call PotSStateData_SetDInventory(2, 1, 0)
        call PotSStateData_AddDInventory(0, 'I001', 0)
        call PotSStateData_AddDInventory(0, 'I002', 0)
        call PSTEST_Check(PotSStateSerializer_Serialize(), "serialize duplicate custom-inventory fixture")
        call PSTEST_Check(not PotSStateSerializer_Deserialize() and PotSStateSerializer_GetLastError() == PotSSaveConfig_ERROR_INVALID_DATA, "duplicate custom-inventory slots rejected")

        call PotSStateData_Reset()
        call PotSStateData_SetHero('H000', 1, 0, 0, -1)
        call PotSStateData_SetAttributes(1, 1, 1)
        call PotSStateData_SetResources(0, 0)
        call PotSStateData_SetInventorySize(0)
        call PotSStateData_SetVitals(-1, -1)
        call PotSStateData_AddEquipment(PotSSaveConfig_MAX_EQUIPMENT_SLOTS + 1, 'I003', 0)
        call PSTEST_Check(PotSStateSerializer_Serialize(), "serialize invalid equipment-slot fixture")
        call PSTEST_Check(not PotSStateSerializer_Deserialize() and PotSStateSerializer_GetLastError() == PotSSaveConfig_ERROR_INVALID_DATA, "out-of-range equipment slot rejected")
    endfunction

    private function PSTEST_TestMalformedAndCapacity takes nothing returns nothing
        local integer i = 0

        call PotSStateSerializer_BeginInput()
        call PotSStateSerializer_PushInput(PotSSaveConfig_MAGIC)
        call PotSStateSerializer_PushInput(2)
        call PotSStateSerializer_PushInput(0)
        call PotSStateSerializer_PushInput(1)
        call PotSStateSerializer_PushInput(PotSSaveConfig_TAG_HERO_IDENTITY)
        call PotSStateSerializer_PushInput(2)
        call PotSStateSerializer_PushInput('H000')
        call PSTEST_Check(not PotSStateSerializer_Deserialize(), "truncated record rejected")

        call PotSStateSerializer_BeginInput()
        call PotSStateSerializer_PushInput(PotSSaveConfig_MAGIC)
        call PotSStateSerializer_PushInput(2)
        call PotSStateSerializer_PushInput(0)
        call PotSStateSerializer_PushInput(0)
        call PSTEST_Check(not PotSStateSerializer_Deserialize() and PotSStateSerializer_GetLastError() == PotSSaveConfig_ERROR_INVALID_DATA, "missing required records rejected")

        call PotSStateSerializer_BeginInput()
        call PotSStateSerializer_PushInput(PotSSaveConfig_MAGIC)
        call PotSStateSerializer_PushInput(PotSSaveConfig_SCHEMA_MAJOR)
        call PotSStateSerializer_PushInput(PotSSaveConfig_SCHEMA_MINOR + 1)
        call PotSStateSerializer_PushInput(0)
        call PSTEST_Check(not PotSStateSerializer_Deserialize() and PotSStateSerializer_GetLastError() == PotSSaveConfig_ERROR_UNSUPPORTED_SCHEMA, "future minor schema rejected")

        call PotSStateSerializer_BeginInput()
        loop
            exitwhen i >= PotSSaveConfig_MAX_STREAM_VALUES
            call PSTEST_Check(PotSStateSerializer_PushInput(i), "bounded stream accepts configured value")
            set i = i + 1
        endloop
        call PSTEST_Check(not PotSStateSerializer_PushInput(1) and PotSStateSerializer_GetLastError() == PotSSaveConfig_ERROR_CAPACITY, "oversize stream rejected")
    endfunction

    public function Run takes nothing returns boolean
        set PSTEST_Total = 0
        set PSTEST_Failed = 0
        call PSTEST_TestRoundTripAndOrdering()
        call PSTEST_TestSchema1Migration()
        call PSTEST_TestQuestIdentityMigration()
        call PSTEST_TestItemRawcodeMigration()
        call PSTEST_TestRepresentativeSizes()
        call PSTEST_TestCustomStorageValidation()
        call PSTEST_TestMalformedAndCapacity()
        call BJDebugMsg("PotSSaveLoadTests: " + I2S(PSTEST_Total - PSTEST_Failed) + "/" + I2S(PSTEST_Total) + " checks passed.")
        return PSTEST_Failed == 0
    endfunction
endlibrary
