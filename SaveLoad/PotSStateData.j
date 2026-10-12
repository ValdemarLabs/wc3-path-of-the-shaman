/**
    PotSStateData

    Author: Valdemar
    Version: 2.1.0

    Description:
    Stores one bounded, neutral PotS character snapshot, including normal and
    custom inventory/equipment, while a save or load operation is processed.

    Credits:
    - StateSaver by Tomotz, architectural inspiration

    How to install:
    Import after PotSSaveConfig and before scanner, serializer, migration,
    world-progression, and coordinator libraries.

    API:
    - PotSStateData_Reset()
    - PotSStateData_AddAbilitySorted(rawcode, level, source)
    - PotSStateData_AddInventory(slot, rawcode, charges)
    - PotSStateData_AddDInventory(slot, rawcode, charges)
    - PotSStateData_AddEquipment(slot, rawcode, charges)
    - PotSStateData_AddWorldFlagSorted(nameHash, giverType, state)
    - Getter/setter functions expose the current transient snapshot.

**/
library PotSStateData requires PotSSaveConfig
    globals
        private integer PSD_SchemaMajor = 0
        private integer PSD_SchemaMinor = 0
        private integer PSD_HeroType = 0
        private integer PSD_HeroLevel = 0
        private integer PSD_HeroXP = 0
        private integer PSD_HeroSkillPoints = 0
        private integer PSD_AbilityPoints = -1
        private integer PSD_Strength = 0
        private integer PSD_Agility = 0
        private integer PSD_Intelligence = 0
        private integer PSD_Gold = 0
        private integer PSD_Lumber = 0
        private integer PSD_LifeRatio = -1
        private integer PSD_ManaRatio = -1
        private integer PSD_InventorySize = 0
        private integer PSD_InventoryCount = 0
        private integer array PSD_InventorySlot
        private integer array PSD_InventoryType
        private integer array PSD_InventoryCharges
        private integer PSD_DInventoryCapacity = -1
        private integer PSD_DInventoryTier = 0
        private integer PSD_DInventoryAdditional = 0
        private integer PSD_DInventoryCount = 0
        private integer array PSD_DInventorySlot
        private integer array PSD_DInventoryType
        private integer array PSD_DInventoryCharges
        private integer PSD_EquipmentCount = 0
        private integer array PSD_EquipmentSlot
        private integer array PSD_EquipmentType
        private integer array PSD_EquipmentCharges
        private integer PSD_AbilityCount = 0
        private integer array PSD_AbilityId
        private integer array PSD_AbilityLevel
        private integer array PSD_AbilitySource
        private integer PSD_WorldCount = 0
        private integer array PSD_WorldNameHash
        private integer array PSD_WorldGiverType
        private integer array PSD_WorldState
    endglobals

    public function Reset takes nothing returns nothing
        local integer i = 0

        loop
            exitwhen i >= PotSSaveConfig_MAX_INVENTORY_SLOTS
            set PSD_InventorySlot[i] = 0
            set PSD_InventoryType[i] = 0
            set PSD_InventoryCharges[i] = 0
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_ABILITIES
            set PSD_AbilityId[i] = 0
            set PSD_AbilityLevel[i] = 0
            set PSD_AbilitySource[i] = PotSSaveConfig_ABILITY_SOURCE_UNKNOWN
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_DINVENTORY_SLOTS
            set PSD_DInventorySlot[i] = 0
            set PSD_DInventoryType[i] = 0
            set PSD_DInventoryCharges[i] = 0
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_EQUIPMENT_SLOTS
            set PSD_EquipmentSlot[i] = 0
            set PSD_EquipmentType[i] = 0
            set PSD_EquipmentCharges[i] = 0
            set i = i + 1
        endloop
        set i = 0
        loop
            exitwhen i >= PotSSaveConfig_MAX_WORLD_FLAGS
            set PSD_WorldNameHash[i] = 0
            set PSD_WorldGiverType[i] = 0
            set PSD_WorldState[i] = 0
            set i = i + 1
        endloop

        set PSD_SchemaMajor = PotSSaveConfig_SCHEMA_MAJOR
        set PSD_SchemaMinor = PotSSaveConfig_SCHEMA_MINOR
        set PSD_HeroType = 0
        set PSD_HeroLevel = 0
        set PSD_HeroXP = 0
        set PSD_HeroSkillPoints = 0
        set PSD_AbilityPoints = -1
        set PSD_Strength = 0
        set PSD_Agility = 0
        set PSD_Intelligence = 0
        set PSD_Gold = 0
        set PSD_Lumber = 0
        set PSD_LifeRatio = -1
        set PSD_ManaRatio = -1
        set PSD_InventorySize = 0
        set PSD_InventoryCount = 0
        set PSD_DInventoryCapacity = -1
        set PSD_DInventoryTier = 0
        set PSD_DInventoryAdditional = 0
        set PSD_DInventoryCount = 0
        set PSD_EquipmentCount = 0
        set PSD_AbilityCount = 0
        set PSD_WorldCount = 0
    endfunction

    public function SetSchema takes integer major, integer minor returns nothing
        set PSD_SchemaMajor = major
        set PSD_SchemaMinor = minor
    endfunction

    public function GetSchemaMajor takes nothing returns integer
        return PSD_SchemaMajor
    endfunction

    public function GetSchemaMinor takes nothing returns integer
        return PSD_SchemaMinor
    endfunction

    public function SetHero takes integer unitTypeId, integer level, integer xp, integer skillPoints, integer abilityPoints returns nothing
        set PSD_HeroType = unitTypeId
        set PSD_HeroLevel = level
        set PSD_HeroXP = xp
        set PSD_HeroSkillPoints = skillPoints
        set PSD_AbilityPoints = abilityPoints
    endfunction

    public function GetHeroType takes nothing returns integer
        return PSD_HeroType
    endfunction

    public function SetHeroType takes integer unitTypeId returns nothing
        set PSD_HeroType = unitTypeId
    endfunction

    public function GetHeroLevel takes nothing returns integer
        return PSD_HeroLevel
    endfunction

    public function GetHeroXP takes nothing returns integer
        return PSD_HeroXP
    endfunction

    public function GetHeroSkillPoints takes nothing returns integer
        return PSD_HeroSkillPoints
    endfunction

    public function GetAbilityPoints takes nothing returns integer
        return PSD_AbilityPoints
    endfunction

    public function SetAttributes takes integer strength, integer agility, integer intelligence returns nothing
        set PSD_Strength = strength
        set PSD_Agility = agility
        set PSD_Intelligence = intelligence
    endfunction

    public function GetStrength takes nothing returns integer
        return PSD_Strength
    endfunction

    public function GetAgility takes nothing returns integer
        return PSD_Agility
    endfunction

    public function GetIntelligence takes nothing returns integer
        return PSD_Intelligence
    endfunction

    public function SetResources takes integer gold, integer lumber returns nothing
        set PSD_Gold = gold
        set PSD_Lumber = lumber
    endfunction

    public function GetGold takes nothing returns integer
        return PSD_Gold
    endfunction

    public function GetLumber takes nothing returns integer
        return PSD_Lumber
    endfunction

    public function SetVitals takes integer lifeRatio, integer manaRatio returns nothing
        set PSD_LifeRatio = lifeRatio
        set PSD_ManaRatio = manaRatio
    endfunction

    public function GetLifeRatio takes nothing returns integer
        return PSD_LifeRatio
    endfunction

    public function GetManaRatio takes nothing returns integer
        return PSD_ManaRatio
    endfunction

    public function SetInventorySize takes integer size returns nothing
        set PSD_InventorySize = size
    endfunction

    public function GetInventorySize takes nothing returns integer
        return PSD_InventorySize
    endfunction

    public function AddInventory takes integer slot, integer itemTypeId, integer charges returns boolean
        local integer index = PSD_InventoryCount

        if index >= PotSSaveConfig_MAX_INVENTORY_SLOTS then
            return false
        endif
        set PSD_InventorySlot[index] = slot
        set PSD_InventoryType[index] = itemTypeId
        set PSD_InventoryCharges[index] = charges
        set PSD_InventoryCount = index + 1
        return true
    endfunction

    public function GetInventoryCount takes nothing returns integer
        return PSD_InventoryCount
    endfunction

    public function GetInventorySlot takes integer index returns integer
        return PSD_InventorySlot[index]
    endfunction

    public function GetInventoryType takes integer index returns integer
        return PSD_InventoryType[index]
    endfunction

    public function SetInventoryType takes integer index, integer itemTypeId returns nothing
        set PSD_InventoryType[index] = itemTypeId
    endfunction

    public function GetInventoryCharges takes integer index returns integer
        return PSD_InventoryCharges[index]
    endfunction

    public function SetDInventory takes integer capacity, integer tier, integer additional returns nothing
        set PSD_DInventoryCapacity = capacity
        set PSD_DInventoryTier = tier
        set PSD_DInventoryAdditional = additional
    endfunction

    public function GetDInventoryCapacity takes nothing returns integer
        return PSD_DInventoryCapacity
    endfunction

    public function GetDInventoryTier takes nothing returns integer
        return PSD_DInventoryTier
    endfunction

    public function GetDInventoryAdditional takes nothing returns integer
        return PSD_DInventoryAdditional
    endfunction

    public function AddDInventory takes integer slot, integer itemTypeId, integer charges returns boolean
        local integer index = PSD_DInventoryCount

        if index >= PotSSaveConfig_MAX_DINVENTORY_SLOTS then
            return false
        endif
        set PSD_DInventorySlot[index] = slot
        set PSD_DInventoryType[index] = itemTypeId
        set PSD_DInventoryCharges[index] = charges
        set PSD_DInventoryCount = index + 1
        return true
    endfunction

    public function GetDInventoryCount takes nothing returns integer
        return PSD_DInventoryCount
    endfunction

    public function GetDInventorySlot takes integer index returns integer
        return PSD_DInventorySlot[index]
    endfunction

    public function GetDInventoryType takes integer index returns integer
        return PSD_DInventoryType[index]
    endfunction

    public function SetDInventoryType takes integer index, integer itemTypeId returns nothing
        set PSD_DInventoryType[index] = itemTypeId
    endfunction

    public function GetDInventoryCharges takes integer index returns integer
        return PSD_DInventoryCharges[index]
    endfunction

    public function AddEquipment takes integer slot, integer itemTypeId, integer charges returns boolean
        local integer index = PSD_EquipmentCount

        if index >= PotSSaveConfig_MAX_EQUIPMENT_SLOTS then
            return false
        endif
        set PSD_EquipmentSlot[index] = slot
        set PSD_EquipmentType[index] = itemTypeId
        set PSD_EquipmentCharges[index] = charges
        set PSD_EquipmentCount = index + 1
        return true
    endfunction

    public function GetEquipmentCount takes nothing returns integer
        return PSD_EquipmentCount
    endfunction

    public function GetEquipmentSlot takes integer index returns integer
        return PSD_EquipmentSlot[index]
    endfunction

    public function GetEquipmentType takes integer index returns integer
        return PSD_EquipmentType[index]
    endfunction

    public function SetEquipmentType takes integer index, integer itemTypeId returns nothing
        set PSD_EquipmentType[index] = itemTypeId
    endfunction

    public function GetEquipmentCharges takes integer index returns integer
        return PSD_EquipmentCharges[index]
    endfunction

    private function PSD_FindAbility takes integer abilityId returns integer
        local integer i = 0
        loop
            exitwhen i >= PSD_AbilityCount
            if PSD_AbilityId[i] == abilityId then
                return i
            endif
            set i = i + 1
        endloop
        return -1
    endfunction

    public function AddAbilitySorted takes integer abilityId, integer level, integer source returns boolean
        local integer existing = PSD_FindAbility(abilityId)
        local integer index = PSD_AbilityCount
        local integer insertAt = 0

        if existing >= 0 then
            if level > PSD_AbilityLevel[existing] then
                set PSD_AbilityLevel[existing] = level
            endif
            if PSD_AbilitySource[existing] == PotSSaveConfig_ABILITY_SOURCE_UNKNOWN or source == PotSSaveConfig_ABILITY_SOURCE_CATALOG then
                set PSD_AbilitySource[existing] = source
            endif
            return true
        endif
        if index >= PotSSaveConfig_MAX_ABILITIES then
            return false
        endif

        loop
            exitwhen insertAt >= index or PSD_AbilityId[insertAt] > abilityId
            set insertAt = insertAt + 1
        endloop
        loop
            exitwhen index <= insertAt
            set PSD_AbilityId[index] = PSD_AbilityId[index - 1]
            set PSD_AbilityLevel[index] = PSD_AbilityLevel[index - 1]
            set PSD_AbilitySource[index] = PSD_AbilitySource[index - 1]
            set index = index - 1
        endloop
        set PSD_AbilityId[insertAt] = abilityId
        set PSD_AbilityLevel[insertAt] = level
        set PSD_AbilitySource[insertAt] = source
        set PSD_AbilityCount = PSD_AbilityCount + 1
        return true
    endfunction

    public function GetAbilityCount takes nothing returns integer
        return PSD_AbilityCount
    endfunction

    public function GetAbilityId takes integer index returns integer
        return PSD_AbilityId[index]
    endfunction

    public function SetAbilityId takes integer index, integer abilityId returns nothing
        set PSD_AbilityId[index] = abilityId
    endfunction

    public function GetAbilityLevel takes integer index returns integer
        return PSD_AbilityLevel[index]
    endfunction

    public function GetAbilitySource takes integer index returns integer
        return PSD_AbilitySource[index]
    endfunction

    public function SetAbilitySource takes integer abilityId, integer source returns boolean
        local integer index = PSD_FindAbility(abilityId)
        if index < 0 then
            return false
        endif
        set PSD_AbilitySource[index] = source
        return true
    endfunction

    private function PSD_WorldComesBefore takes integer nameHash, integer giverType, integer index returns boolean
        if nameHash < PSD_WorldNameHash[index] then
            return true
        endif
        return nameHash == PSD_WorldNameHash[index] and giverType < PSD_WorldGiverType[index]
    endfunction

    public function AddWorldFlagSorted takes integer nameHash, integer giverType, integer state returns boolean
        local integer index = PSD_WorldCount
        local integer insertAt = 0

        loop
            exitwhen insertAt >= index or PSD_WorldComesBefore(nameHash, giverType, insertAt)
            if PSD_WorldNameHash[insertAt] == nameHash and PSD_WorldGiverType[insertAt] == giverType then
                return false
            endif
            set insertAt = insertAt + 1
        endloop
        if index >= PotSSaveConfig_MAX_WORLD_FLAGS then
            return false
        endif
        loop
            exitwhen index <= insertAt
            set PSD_WorldNameHash[index] = PSD_WorldNameHash[index - 1]
            set PSD_WorldGiverType[index] = PSD_WorldGiverType[index - 1]
            set PSD_WorldState[index] = PSD_WorldState[index - 1]
            set index = index - 1
        endloop
        set PSD_WorldNameHash[insertAt] = nameHash
        set PSD_WorldGiverType[insertAt] = giverType
        set PSD_WorldState[insertAt] = state
        set PSD_WorldCount = PSD_WorldCount + 1
        return true
    endfunction

    public function GetWorldCount takes nothing returns integer
        return PSD_WorldCount
    endfunction

    public function GetWorldNameHash takes integer index returns integer
        return PSD_WorldNameHash[index]
    endfunction

    public function GetWorldGiverType takes integer index returns integer
        return PSD_WorldGiverType[index]
    endfunction

    public function GetWorldState takes integer index returns integer
        return PSD_WorldState[index]
    endfunction

    public function SetWorldIdentity takes integer index, integer nameHash, integer giverType returns nothing
        if index >= 0 and index < PSD_WorldCount then
            set PSD_WorldNameHash[index] = nameHash
            set PSD_WorldGiverType[index] = giverType
        endif
    endfunction
endlibrary
