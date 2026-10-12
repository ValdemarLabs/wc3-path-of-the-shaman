/**
    PotSStateScanner

    Author: Valdemar
    Version: 2.1.0

    Description:
    Scans one resolved persistent hero, normal and custom inventory/equipment,
    trusted learned abilities, resources, and optional durable quest progress
    into PotSStateData without performing file IO.

    Credits:
    - StateSaver by Tomotz, scanner architecture

    How to install:
    Import after PotSStateData, PotSStateTracker, and PotSWorldProgression.
    AbilitiesPlayer, Abilities, and AbilityPoints are optional PotS adapters.

    API:
    - PotSStateScanner_Scan(player, hero)

**/
library PotSStateScanner requires PotSSaveConfig, PotSStateData, PotSStateTracker, PotSWorldProgression, optional AbilitiesPlayer, optional Abilities, optional AbilityPoints, optional DInventory, optional DEquipment
    private function PSS_AddCatalogEntry takes unit hero, integer entryIndex returns boolean
        static if LIBRARY_AbilitiesPlayer then
            local integer abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
            local integer level

            static if LIBRARY_Abilities then
                set level = Abilities_GetEntryLevel(hero, entryIndex)
            else
                set level = GetUnitAbilityLevel(hero, abilityId)
            endif
            if abilityId != 0 and level > 0 then
                return PotSStateData_AddAbilitySorted(abilityId, level, PotSSaveConfig_ABILITY_SOURCE_CATALOG)
            endif
        endif
        return true
    endfunction

    private function PSS_ScanAbilities takes unit hero returns boolean
        local integer index = 0
        local integer abilityId
        local integer entryIndex
        local integer level
        local ability whichAbility = null

        loop
            exitwhen index >= PotSSaveConfig_MAX_ENUMERATED_ABILITIES
            set whichAbility = BlzGetUnitAbilityByIndex(hero, index)
            exitwhen whichAbility == null
            set abilityId = BlzGetAbilityId(whichAbility)
            set entryIndex = 0
            static if LIBRARY_AbilitiesPlayer then
                set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
            endif
            if entryIndex > 0 then
                if not PSS_AddCatalogEntry(hero, entryIndex) then
                    set whichAbility = null
                    return false
                endif
            elseif PotSStateTracker_IsTracked(hero, abilityId) then
                set level = GetUnitAbilityLevel(hero, abilityId)
                if level > 0 and not PotSStateData_AddAbilitySorted(abilityId, level, PotSSaveConfig_ABILITY_SOURCE_TRACKED) then
                    set whichAbility = null
                    return false
                endif
            endif
            set index = index + 1
        endloop
        if index >= PotSSaveConfig_MAX_ENUMERATED_ABILITIES and whichAbility != null then
            set whichAbility = null
            return false
        endif
        set whichAbility = null

        static if LIBRARY_AbilitiesPlayer then
            set index = 1
            loop
                exitwhen index > AbilitiesPlayer_GetEntryCount()
                if not PSS_AddCatalogEntry(hero, index) then
                    return false
                endif
                set index = index + 1
            endloop
        endif

        set index = 0
        loop
            exitwhen index >= PotSStateTracker_GetCount(hero)
            set abilityId = PotSStateTracker_GetAbilityId(hero, index)
            set level = GetUnitAbilityLevel(hero, abilityId)
            if level > 0 and not PotSStateData_AddAbilitySorted(abilityId, level, PotSSaveConfig_ABILITY_SOURCE_TRACKED) then
                return false
            endif
            set index = index + 1
        endloop
        return true
    endfunction

    private function PSS_ScanInventory takes unit hero returns boolean
        local integer size = UnitInventorySize(hero)
        local integer slot = 0
        local item whichItem = null

        if size < 0 or size > PotSSaveConfig_MAX_INVENTORY_SLOTS then
            return false
        endif
        call PotSStateData_SetInventorySize(size)
        loop
            exitwhen slot >= size
            set whichItem = UnitItemInSlot(hero, slot)
            if whichItem != null then
                if not PotSStateData_AddInventory(slot, GetItemTypeId(whichItem), GetItemCharges(whichItem)) then
                    set whichItem = null
                    return false
                endif
            endif
            set slot = slot + 1
        endloop
        set whichItem = null
        return true
    endfunction

    private function PSS_ScanDInventory takes unit hero returns boolean
        static if LIBRARY_DInventory then
            local integer pid = GetPlayerId(GetOwningPlayer(hero))
            local integer bid = BIDOfUnit(hero)
            local integer capacity
            local integer slot = 0
            local item whichItem = null

            if bid < 1 then
                call PotSStateData_SetDInventory(-1, 0, 0)
                set hero = null
                return true
            endif
            set capacity = MaxBagCapacityOfBID(pid, bid)
            if capacity < 0 or capacity > PotSSaveConfig_MAX_DINVENTORY_SLOTS then
                set hero = null
                return false
            endif
            call PotSStateData_SetDInventory(capacity, DInvGetBagTierOfUnit(hero), BIDDB[bid][0].integer[1])
            loop
                exitwhen slot >= capacity
                set whichItem = DInventoryDB[bid].item[slot]
                if whichItem != null and not PotSStateData_AddDInventory(slot, GetItemTypeId(whichItem), GetItemCharges(whichItem)) then
                    set whichItem = null
                    set hero = null
                    return false
                endif
                set slot = slot + 1
            endloop
            set whichItem = null
        else
            call PotSStateData_SetDInventory(-1, 0, 0)
        endif
        set hero = null
        return true
    endfunction

    private function PSS_ScanEquipment takes unit hero returns boolean
        static if LIBRARY_DEquipment then
            local integer eqid = EQIDOfUnit(hero)
            local integer slot = 1
            local item whichItem = null

            if eqid < 1 then
                set hero = null
                return true
            endif
            loop
                exitwhen slot > PotSSaveConfig_MAX_EQUIPMENT_SLOTS
                set whichItem = EQIDDB[eqid][4].item[slot]
                if whichItem != null and not PotSStateData_AddEquipment(slot, GetItemTypeId(whichItem), GetItemCharges(whichItem)) then
                    set whichItem = null
                    set hero = null
                    return false
                endif
                set slot = slot + 1
            endloop
            set whichItem = null
        endif
        set hero = null
        return true
    endfunction

    private function PSS_ScaledRatio takes real currentValue, real maxValue returns integer
        local integer result

        if maxValue <= 0.00 then
            return -1
        endif
        set result = R2I(currentValue * I2R(PotSSaveConfig_VITAL_SCALE) / maxValue + 0.50)
        if result < 0 then
            return 0
        elseif result > PotSSaveConfig_VITAL_SCALE then
            return PotSSaveConfig_VITAL_SCALE
        endif
        return result
    endfunction

    public function Scan takes player whichPlayer, unit hero returns boolean
        local integer abilityPoints = -1

        if whichPlayer == null or hero == null or GetOwningPlayer(hero) != whichPlayer or not IsUnitType(hero, UNIT_TYPE_HERO) then
            set whichPlayer = null
            set hero = null
            return false
        endif

        call PotSStateData_Reset()
        static if LIBRARY_AbilityPoints then
            set abilityPoints = AbilityPoints_Get(hero)
        endif
        call PotSStateData_SetHero(GetUnitTypeId(hero), GetHeroLevel(hero), GetHeroXP(hero), GetHeroSkillPoints(hero), abilityPoints)
        call PotSStateData_SetAttributes(GetHeroStr(hero, false), GetHeroAgi(hero, false), GetHeroInt(hero, false))
        call PotSStateData_SetResources(GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD), GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER))
        call PotSStateData_SetVitals(PSS_ScaledRatio(GetUnitState(hero, UNIT_STATE_LIFE), GetUnitState(hero, UNIT_STATE_MAX_LIFE)), PSS_ScaledRatio(GetUnitState(hero, UNIT_STATE_MANA), GetUnitState(hero, UNIT_STATE_MAX_MANA)))

        if not PSS_ScanInventory(hero) or not PSS_ScanDInventory(hero) or not PSS_ScanEquipment(hero) or not PSS_ScanAbilities(hero) or not PotSWorldProgression_Scan() then
            set whichPlayer = null
            set hero = null
            return false
        endif

        set whichPlayer = null
        set hero = null
        return true
    endfunction
endlibrary
