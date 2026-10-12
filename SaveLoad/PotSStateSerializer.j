/**
    PotSStateSerializer

    Author: Valdemar
    Version: 2.1.0

    Description:
    Converts PotSStateData to and from a bounded deterministic stream of
    tagged, length-prefixed integers independent of NSL's code format.

    Credits:
    - StateSaver by Tomotz, versioned serialization concept

    How to install:
    Import after PotSSaveConfig and PotSStateData and before migration and the
    Maxou NSL adapter.

    API:
    - PotSStateSerializer_Serialize()
    - PotSStateSerializer_BeginInput()/PushInput(value)
    - PotSStateSerializer_Deserialize()
    - PotSStateSerializer_GetCount()/GetValue(index)

**/
library PotSStateSerializer requires PotSSaveConfig, PotSStateData
    globals
        private integer PSSER_Count = 0
        private integer array PSSER_Value
        private integer PSSER_LastError = 0
    endglobals

    private function PSSER_Fail takes integer errorCode returns boolean
        set PSSER_LastError = errorCode
        return false
    endfunction

    private function PSSER_Push takes integer value returns boolean
        if PSSER_Count >= PotSSaveConfig_MAX_STREAM_VALUES then
            return PSSER_Fail(PotSSaveConfig_ERROR_CAPACITY)
        endif
        set PSSER_Value[PSSER_Count] = value
        set PSSER_Count = PSSER_Count + 1
        return true
    endfunction

    private function PSSER_Record takes integer tag, integer length returns boolean
        if not PSSER_Push(tag) then
            return false
        endif
        return PSSER_Push(length)
    endfunction

    public function BeginInput takes nothing returns nothing
        set PSSER_Count = 0
        set PSSER_LastError = PotSSaveConfig_ERROR_NONE
    endfunction

    public function PushInput takes integer value returns boolean
        return PSSER_Push(value)
    endfunction

    public function GetCount takes nothing returns integer
        return PSSER_Count
    endfunction

    public function GetValue takes integer index returns integer
        return PSSER_Value[index]
    endfunction

    public function GetLastError takes nothing returns integer
        return PSSER_LastError
    endfunction

    private function PSSER_CountTrackedAbilities takes nothing returns integer
        local integer count = 0
        local integer i = 0
        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            if PotSStateData_GetAbilitySource(i) == PotSSaveConfig_ABILITY_SOURCE_TRACKED then
                set count = count + 1
            endif
            set i = i + 1
        endloop
        return count
    endfunction

    public function Serialize takes nothing returns boolean
        local integer i = 0
        local integer trackedCount = PSSER_CountTrackedAbilities()
        local integer recordCount = 11

        call BeginInput()
        if not PSSER_Push(PotSSaveConfig_MAGIC) or not PSSER_Push(PotSSaveConfig_SCHEMA_MAJOR) or not PSSER_Push(PotSSaveConfig_SCHEMA_MINOR) or not PSSER_Push(recordCount) then
            return false
        endif

        if not PSSER_Record(PotSSaveConfig_TAG_HERO_IDENTITY, 1) or not PSSER_Push(PotSStateData_GetHeroType()) then
            return false
        endif
        if not PSSER_Record(PotSSaveConfig_TAG_HERO_PROGRESS, 4) or not PSSER_Push(PotSStateData_GetHeroLevel()) or not PSSER_Push(PotSStateData_GetHeroXP()) or not PSSER_Push(PotSStateData_GetHeroSkillPoints()) or not PSSER_Push(PotSStateData_GetAbilityPoints()) then
            return false
        endif
        if not PSSER_Record(PotSSaveConfig_TAG_HERO_ATTRIBUTES, 3) or not PSSER_Push(PotSStateData_GetStrength()) or not PSSER_Push(PotSStateData_GetAgility()) or not PSSER_Push(PotSStateData_GetIntelligence()) then
            return false
        endif

        if not PSSER_Record(PotSSaveConfig_TAG_ABILITIES, 1 + PotSStateData_GetAbilityCount() * 2) or not PSSER_Push(PotSStateData_GetAbilityCount()) then
            return false
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            if not PSSER_Push(PotSStateData_GetAbilityId(i)) or not PSSER_Push(PotSStateData_GetAbilityLevel(i)) then
                return false
            endif
            set i = i + 1
        endloop

        if not PSSER_Record(PotSSaveConfig_TAG_INVENTORY, 2 + PotSStateData_GetInventoryCount() * 3) or not PSSER_Push(PotSStateData_GetInventorySize()) or not PSSER_Push(PotSStateData_GetInventoryCount()) then
            return false
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetInventoryCount()
            if not PSSER_Push(PotSStateData_GetInventorySlot(i)) or not PSSER_Push(PotSStateData_GetInventoryType(i)) or not PSSER_Push(PotSStateData_GetInventoryCharges(i)) then
                return false
            endif
            set i = i + 1
        endloop

        if not PSSER_Record(PotSSaveConfig_TAG_DINVENTORY, 4 + PotSStateData_GetDInventoryCount() * 3) or not PSSER_Push(PotSStateData_GetDInventoryCapacity()) or not PSSER_Push(PotSStateData_GetDInventoryTier()) or not PSSER_Push(PotSStateData_GetDInventoryAdditional()) or not PSSER_Push(PotSStateData_GetDInventoryCount()) then
            return false
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetDInventoryCount()
            if not PSSER_Push(PotSStateData_GetDInventorySlot(i)) or not PSSER_Push(PotSStateData_GetDInventoryType(i)) or not PSSER_Push(PotSStateData_GetDInventoryCharges(i)) then
                return false
            endif
            set i = i + 1
        endloop

        if not PSSER_Record(PotSSaveConfig_TAG_EQUIPMENT, 1 + PotSStateData_GetEquipmentCount() * 3) or not PSSER_Push(PotSStateData_GetEquipmentCount()) then
            return false
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetEquipmentCount()
            if not PSSER_Push(PotSStateData_GetEquipmentSlot(i)) or not PSSER_Push(PotSStateData_GetEquipmentType(i)) or not PSSER_Push(PotSStateData_GetEquipmentCharges(i)) then
                return false
            endif
            set i = i + 1
        endloop

        if not PSSER_Record(PotSSaveConfig_TAG_RESOURCES, 2) or not PSSER_Push(PotSStateData_GetGold()) or not PSSER_Push(PotSStateData_GetLumber()) then
            return false
        endif
        if not PSSER_Record(PotSSaveConfig_TAG_VITALS, 2) or not PSSER_Push(PotSStateData_GetLifeRatio()) or not PSSER_Push(PotSStateData_GetManaRatio()) then
            return false
        endif

        if not PSSER_Record(PotSSaveConfig_TAG_ABILITY_PROVENANCE, 1 + trackedCount) or not PSSER_Push(trackedCount) then
            return false
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            if PotSStateData_GetAbilitySource(i) == PotSSaveConfig_ABILITY_SOURCE_TRACKED then
                if not PSSER_Push(PotSStateData_GetAbilityId(i)) then
                    return false
                endif
            endif
            set i = i + 1
        endloop

        if not PSSER_Record(PotSSaveConfig_TAG_QUESTS, 1 + PotSStateData_GetWorldCount() * 3) or not PSSER_Push(PotSStateData_GetWorldCount()) then
            return false
        endif
        set i = 0
        loop
            exitwhen i >= PotSStateData_GetWorldCount()
            if not PSSER_Push(PotSStateData_GetWorldNameHash(i)) or not PSSER_Push(PotSStateData_GetWorldGiverType(i)) or not PSSER_Push(PotSStateData_GetWorldState(i)) then
                return false
            endif
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSSER_ReadHeroIdentity takes integer start, integer length returns boolean
        if length != 1 or PSSER_Value[start] == 0 then
            return false
        endif
        call PotSStateData_SetHero(PSSER_Value[start], 0, 0, 0, -1)
        return true
    endfunction

    private function PSSER_ReadHeroProgress takes integer start, integer length returns boolean
        if length == 3 then
            call PotSStateData_SetHero(PotSStateData_GetHeroType(), PSSER_Value[start], PSSER_Value[start + 1], PSSER_Value[start + 2], -1)
            return true
        elseif length == 4 then
            call PotSStateData_SetHero(PotSStateData_GetHeroType(), PSSER_Value[start], PSSER_Value[start + 1], PSSER_Value[start + 2], PSSER_Value[start + 3])
            return true
        endif
        return false
    endfunction

    private function PSSER_ReadAttributes takes integer start, integer length returns boolean
        if length != 3 then
            return false
        endif
        call PotSStateData_SetAttributes(PSSER_Value[start], PSSER_Value[start + 1], PSSER_Value[start + 2])
        return true
    endfunction

    private function PSSER_ReadAbilities takes integer start, integer length returns boolean
        local integer count
        local integer i = 0
        local integer cursor = start + 1

        if length < 1 then
            return false
        endif
        set count = PSSER_Value[start]
        if count < 0 or count > PotSSaveConfig_MAX_ABILITIES or length != 1 + count * 2 then
            return false
        endif
        loop
            exitwhen i >= count
            if PSSER_Value[cursor] == 0 or PSSER_Value[cursor + 1] <= 0 or not PotSStateData_AddAbilitySorted(PSSER_Value[cursor], PSSER_Value[cursor + 1], PotSSaveConfig_ABILITY_SOURCE_UNKNOWN) then
                return false
            endif
            set cursor = cursor + 2
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSSER_InventorySlotAlreadyUsed takes integer slot returns boolean
        local integer i = 0
        loop
            exitwhen i >= PotSStateData_GetInventoryCount()
            if PotSStateData_GetInventorySlot(i) == slot then
                return true
            endif
            set i = i + 1
        endloop
        return false
    endfunction

    private function PSSER_ReadInventory takes integer start, integer length returns boolean
        local integer size
        local integer count
        local integer i = 0
        local integer cursor = start + 2
        local integer slot

        if length < 2 then
            return false
        endif
        set size = PSSER_Value[start]
        set count = PSSER_Value[start + 1]
        if size < 0 or size > PotSSaveConfig_MAX_INVENTORY_SLOTS or count < 0 or count > size or length != 2 + count * 3 then
            return false
        endif
        call PotSStateData_SetInventorySize(size)
        loop
            exitwhen i >= count
            set slot = PSSER_Value[cursor]
            if slot < 0 or slot >= size or PSSER_InventorySlotAlreadyUsed(slot) or PSSER_Value[cursor + 1] == 0 or PSSER_Value[cursor + 2] < 0 then
                return false
            endif
            if not PotSStateData_AddInventory(slot, PSSER_Value[cursor + 1], PSSER_Value[cursor + 2]) then
                return false
            endif
            set cursor = cursor + 3
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSSER_DInventorySlotAlreadyUsed takes integer slot returns boolean
        local integer i = 0
        loop
            exitwhen i >= PotSStateData_GetDInventoryCount()
            if PotSStateData_GetDInventorySlot(i) == slot then
                return true
            endif
            set i = i + 1
        endloop
        return false
    endfunction

    private function PSSER_ReadDInventory takes integer start, integer length returns boolean
        local integer capacity
        local integer count
        local integer i = 0
        local integer cursor = start + 4
        local integer slot

        if length < 4 then
            return false
        endif
        set capacity = PSSER_Value[start]
        set count = PSSER_Value[start + 3]
        if capacity < -1 or capacity > PotSSaveConfig_MAX_DINVENTORY_SLOTS or count < 0 or count > PotSSaveConfig_MAX_DINVENTORY_SLOTS or (capacity < 0 and count != 0) or (capacity >= 0 and count > capacity) or length != 4 + count * 3 then
            return false
        endif
        call PotSStateData_SetDInventory(capacity, PSSER_Value[start + 1], PSSER_Value[start + 2])
        loop
            exitwhen i >= count
            set slot = PSSER_Value[cursor]
            if slot < 0 or slot >= capacity or PSSER_DInventorySlotAlreadyUsed(slot) or PSSER_Value[cursor + 1] == 0 or PSSER_Value[cursor + 2] < 0 then
                return false
            endif
            if not PotSStateData_AddDInventory(slot, PSSER_Value[cursor + 1], PSSER_Value[cursor + 2]) then
                return false
            endif
            set cursor = cursor + 3
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSSER_EquipmentSlotAlreadyUsed takes integer slot returns boolean
        local integer i = 0
        loop
            exitwhen i >= PotSStateData_GetEquipmentCount()
            if PotSStateData_GetEquipmentSlot(i) == slot then
                return true
            endif
            set i = i + 1
        endloop
        return false
    endfunction

    private function PSSER_ReadEquipment takes integer start, integer length returns boolean
        local integer count
        local integer i = 0
        local integer cursor = start + 1
        local integer slot

        if length < 1 then
            return false
        endif
        set count = PSSER_Value[start]
        if count < 0 or count > PotSSaveConfig_MAX_EQUIPMENT_SLOTS or length != 1 + count * 3 then
            return false
        endif
        loop
            exitwhen i >= count
            set slot = PSSER_Value[cursor]
            if slot < 1 or slot > PotSSaveConfig_MAX_EQUIPMENT_SLOTS or PSSER_EquipmentSlotAlreadyUsed(slot) or PSSER_Value[cursor + 1] == 0 or PSSER_Value[cursor + 2] < 0 then
                return false
            endif
            if not PotSStateData_AddEquipment(slot, PSSER_Value[cursor + 1], PSSER_Value[cursor + 2]) then
                return false
            endif
            set cursor = cursor + 3
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSSER_ReadResources takes integer start, integer length returns boolean
        if length != 2 then
            return false
        endif
        call PotSStateData_SetResources(PSSER_Value[start], PSSER_Value[start + 1])
        return true
    endfunction

    private function PSSER_ReadVitals takes integer start, integer length returns boolean
        if length != 2 then
            return false
        endif
        call PotSStateData_SetVitals(PSSER_Value[start], PSSER_Value[start + 1])
        return true
    endfunction

    private function PSSER_ReadProvenance takes integer start, integer length returns boolean
        local integer count
        local integer i = 0

        if length < 1 then
            return false
        endif
        set count = PSSER_Value[start]
        if count < 0 or count > PotSSaveConfig_MAX_ABILITIES or length != 1 + count then
            return false
        endif
        loop
            exitwhen i >= count
            if not PotSStateData_SetAbilitySource(PSSER_Value[start + 1 + i], PotSSaveConfig_ABILITY_SOURCE_TRACKED) then
                return false
            endif
            set i = i + 1
        endloop
        return true
    endfunction

    private function PSSER_ReadWorld takes integer start, integer length returns boolean
        local integer count
        local integer i = 0
        local integer cursor = start + 1

        if length < 1 then
            return false
        endif
        set count = PSSER_Value[start]
        if count < 0 or count > PotSSaveConfig_MAX_WORLD_FLAGS or length != 1 + count * 3 then
            return false
        endif
        loop
            exitwhen i >= count
            if not PotSStateData_AddWorldFlagSorted(PSSER_Value[cursor], PSSER_Value[cursor + 1], PSSER_Value[cursor + 2]) then
                return false
            endif
            set cursor = cursor + 3
            set i = i + 1
        endloop
        return true
    endfunction

    public function Deserialize takes nothing returns boolean
        local integer schemaMajor
        local integer schemaMinor
        local integer recordCount
        local integer recordIndex = 0
        local integer cursor = 4
        local integer tag
        local integer length
        local boolean sawHero = false
        local boolean sawProgress = false
        local boolean sawAttributes = false
        local boolean sawAbilities = false
        local boolean sawInventory = false
        local boolean sawDInventory = false
        local boolean sawEquipment = false
        local boolean sawResources = false
        local boolean sawVitals = false
        local boolean sawProvenance = false
        local boolean sawWorld = false
        local boolean valid = true

        set PSSER_LastError = PotSSaveConfig_ERROR_NONE
        if PSSER_Count < 4 or PSSER_Value[0] != PotSSaveConfig_MAGIC then
            return PSSER_Fail(PotSSaveConfig_ERROR_INVALID_DATA)
        endif
        set schemaMajor = PSSER_Value[1]
        set schemaMinor = PSSER_Value[2]
        set recordCount = PSSER_Value[3]
        if schemaMajor < PotSSaveConfig_OLDEST_SCHEMA_MAJOR or schemaMajor > PotSSaveConfig_SCHEMA_MAJOR or (schemaMajor == PotSSaveConfig_SCHEMA_MAJOR and schemaMinor > PotSSaveConfig_SCHEMA_MINOR) or schemaMinor < 0 or recordCount < 0 or recordCount > PotSSaveConfig_MAX_RECORDS then
            return PSSER_Fail(PotSSaveConfig_ERROR_UNSUPPORTED_SCHEMA)
        endif

        call PotSStateData_Reset()
        call PotSStateData_SetSchema(schemaMajor, schemaMinor)
        loop
            exitwhen recordIndex >= recordCount or not valid
            if cursor + 2 > PSSER_Count then
                set valid = false
            else
                set tag = PSSER_Value[cursor]
                set length = PSSER_Value[cursor + 1]
                set cursor = cursor + 2
                if length < 0 or length > PSSER_Count - cursor then
                    set valid = false
                elseif tag == PotSSaveConfig_TAG_HERO_IDENTITY then
                    set valid = not sawHero and PSSER_ReadHeroIdentity(cursor, length)
                    set sawHero = true
                elseif tag == PotSSaveConfig_TAG_HERO_PROGRESS then
                    set valid = sawHero and not sawProgress and PSSER_ReadHeroProgress(cursor, length)
                    set sawProgress = true
                elseif tag == PotSSaveConfig_TAG_HERO_ATTRIBUTES then
                    set valid = not sawAttributes and PSSER_ReadAttributes(cursor, length)
                    set sawAttributes = true
                elseif tag == PotSSaveConfig_TAG_ABILITIES then
                    set valid = not sawAbilities and PSSER_ReadAbilities(cursor, length)
                    set sawAbilities = true
                elseif tag == PotSSaveConfig_TAG_INVENTORY then
                    set valid = not sawInventory and PSSER_ReadInventory(cursor, length)
                    set sawInventory = true
                elseif tag == PotSSaveConfig_TAG_DINVENTORY then
                    set valid = not sawDInventory and PSSER_ReadDInventory(cursor, length)
                    set sawDInventory = true
                elseif tag == PotSSaveConfig_TAG_EQUIPMENT then
                    set valid = not sawEquipment and PSSER_ReadEquipment(cursor, length)
                    set sawEquipment = true
                elseif tag == PotSSaveConfig_TAG_RESOURCES then
                    set valid = not sawResources and PSSER_ReadResources(cursor, length)
                    set sawResources = true
                elseif tag == PotSSaveConfig_TAG_VITALS then
                    set valid = not sawVitals and PSSER_ReadVitals(cursor, length)
                    set sawVitals = true
                elseif tag == PotSSaveConfig_TAG_ABILITY_PROVENANCE then
                    set valid = sawAbilities and not sawProvenance and PSSER_ReadProvenance(cursor, length)
                    set sawProvenance = true
                elseif tag == PotSSaveConfig_TAG_QUESTS then
                    set valid = not sawWorld and PSSER_ReadWorld(cursor, length)
                    set sawWorld = true
                endif
                set cursor = cursor + length
            endif
            set recordIndex = recordIndex + 1
        endloop

        if not valid or recordIndex != recordCount or cursor != PSSER_Count or not sawHero or not sawProgress or not sawAttributes or not sawAbilities or not sawInventory or not sawResources then
            return PSSER_Fail(PotSSaveConfig_ERROR_INVALID_DATA)
        endif
        return true
    endfunction
endlibrary
