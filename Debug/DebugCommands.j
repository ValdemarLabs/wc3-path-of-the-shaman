/**
    DebugCommands

    Author: Valdemar
    Version: 1.12.0

    Description:
    Chat-driven debug commands for Path of the Shaman testing. Commands are
    intentionally routed through a single "/debug " prefix so this library can
    later serve as the foundation for player-facing cheats.

    Credits:

    How to install:
    Import DebugObjectRegistry, Warcraft300TestHarness, and
    Warcraft300P2TestHarness before this library. Import DoodadRender and
    DoodadManager before this library. The registry is generated from the
    latest checked-in item, unit, and ability object exports.

    API:
    - /debug help
    - /debug item create '<rawcode-or-name>'
    - /debug item lookup '<rawcode-or-name>'
    - /debug unit create '<rawcode-or-name>'
    - /debug unit lookup '<rawcode-or-name>'
    - /debug ability give '<rawcode-or-name>'
    - /debug ability lookup '<rawcode-or-name>'
    - /debug fishpool spawn
    - /debug drunk
    - /debug unstuck
    - /debug creeprespawn dungeon respawn [zoneId]
    - /debug unithider hide all
    - /debug unithider unhide all
    - /debug unithider enable
    - /debug unithider disable
    - /debug unithider audit
    - /debug doodadrender distance <distance>
    - /debug performance disable
    - /debug wc3 help

**/
library DebugCommands initializer Init requires DebugObjectRegistry, Ascii, GatherNodes, GatherNodeUnits, GatherNodeSkills, ZonesCore, Dungeon, Drunk, PlayerHome, UnitHider4, DoodadRender, AI, AIRoutines, Companions, TerrainDamage, QuestMaster, WeatherSystem, VendorFloatingText, Warcraft300TestHarness, Warcraft300P2TestHarness
    globals
        private constant string DBG_ROOT = "/debug"
        private constant string DBG_PREFIX = "/debug "
        private constant string DBG_SYNC_PREFIX = "PDBG"
        private constant integer DBG_MAX_LOOKUP_RESULTS = 8
        private constant integer DBG_FISH_POOL_CATEGORY_ID = 9
        private constant integer DBG_PERFORMANCE_SYSTEM_COUNT = 11
        private constant real DBG_PERFORMANCE_STEP_INTERVAL = 5.00

        private trigger DBG_ChatTrigger = null
        private trigger DBG_SyncTrigger = null
        private trigger DBG_SelectTrigger = null
        private trigger DBG_DeselectTrigger = null
        private timer DBG_PerformanceTimer = null
        private player DBG_PerformancePlayer = null
        private integer DBG_PerformanceStep = 0
        private boolean DBG_PerformanceActive = false

        private unit array DBG_SelectedUnit
    endglobals

    private function DBG_StartsWith takes string source, string prefix returns boolean
        local integer prefixLength

        if source == null or prefix == null then
            return false
        endif

        set prefixLength = StringLength(prefix)
        if StringLength(source) < prefixLength then
            return false
        endif

        return SubString(source, 0, prefixLength) == prefix
    endfunction

    private function DBG_Trim takes string value returns string
        local integer startIndex = 0
        local integer endIndex

        if value == null then
            return ""
        endif

        set endIndex = StringLength(value)
        loop
            exitwhen startIndex >= endIndex or SubString(value, startIndex, startIndex + 1) != " "
            set startIndex = startIndex + 1
        endloop

        loop
            exitwhen endIndex <= startIndex or SubString(value, endIndex - 1, endIndex) != " "
            set endIndex = endIndex - 1
        endloop

        return SubString(value, startIndex, endIndex)
    endfunction

    private function DBG_Unquote takes string value returns string
        local string result = DBG_Trim(value)
        local integer length = StringLength(result)
        local string first
        local string last

        if length < 2 then
            return result
        endif

        set first = SubString(result, 0, 1)
        set last = SubString(result, length - 1, length)
        if (first == "'" and last == "'") or (first == "\"" and last == "\"") then
            return DBG_Trim(SubString(result, 1, length - 1))
        endif

        return result
    endfunction

    private function DBG_FindChar takes string value, string token, integer startIndex returns integer
        local integer valueLength

        if value == null or token == null then
            return -1
        endif

        set valueLength = StringLength(value)
        loop
            exitwhen startIndex >= valueLength
            if SubString(value, startIndex, startIndex + 1) == token then
                return startIndex
            endif
            set startIndex = startIndex + 1
        endloop

        return -1
    endfunction

    private function DBG_IsDigit takes string character returns boolean
        return character == "0" or character == "1" or character == "2" or character == "3" or character == "4" or character == "5" or character == "6" or character == "7" or character == "8" or character == "9"
    endfunction

    private function DBG_IsNonNegativeReal takes string value returns boolean
        local integer index = 0
        local integer length = StringLength(value)
        local integer decimalCount = 0
        local integer digitCount = 0
        local string character

        if length == 0 then
            return false
        endif
        loop
            exitwhen index >= length
            set character = SubString(value, index, index + 1)
            if DBG_IsDigit(character) then
                set digitCount = digitCount + 1
            elseif character == "." then
                set decimalCount = decimalCount + 1
                if decimalCount > 1 then
                    return false
                endif
            else
                return false
            endif
            set index = index + 1
        endloop
        return digitCount > 0
    endfunction

    private function DBG_Message takes player whichPlayer, string message returns nothing
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "|cff80dfff[Debug]|r " + message)
    endfunction

    private function DBG_RawCodeText takes integer rawCode returns string
        if rawCode == 0 then
            return "0000"
        endif

        return A2S(rawCode)
    endfunction

    private function DBG_GetSelectedUnit takes player whichPlayer returns unit
        local integer playerId = GetPlayerId(whichPlayer)

        if DBG_SelectedUnit[playerId] == null then
            return null
        endif

        if GetUnitTypeId(DBG_SelectedUnit[playerId]) == 0 then
            set DBG_SelectedUnit[playerId] = null
            return null
        endif

        return DBG_SelectedUnit[playerId]
    endfunction

    private function DBG_GetUnitLabel takes unit whichUnit returns string
        local string name = ""

        if whichUnit == null then
            return "<none>"
        endif

        set name = GetUnitName(whichUnit)
        if name == null then
            set name = ""
        endif
        if name == "" then
            set name = DBG_RawCodeText(GetUnitTypeId(whichUnit))
        endif

        return name
    endfunction

    private function DBG_GetKnownItemName takes integer rawCode returns string
        local string name = DebugObjectRegistry_GetItemDisplayNameByCode(rawCode)

        if name == null then
            set name = ""
        endif
        if name == "" then
            set name = GetObjectName(rawCode)
            if name == null then
                set name = ""
            endif
        endif

        return name
    endfunction

    private function DBG_GetKnownUnitName takes integer rawCode returns string
        local string name = DebugObjectRegistry_GetUnitDisplayNameByCode(rawCode)

        if name == null then
            set name = ""
        endif
        if name == "" then
            set name = GetObjectName(rawCode)
            if name == null then
                set name = ""
            endif
        endif

        return name
    endfunction

    private function DBG_GetKnownAbilityName takes integer rawCode returns string
        local string name = DebugObjectRegistry_GetAbilityDisplayNameByCode(rawCode)

        if name == null then
            set name = ""
        endif
        if name == "" then
            set name = BlzGetAbilityTooltip(rawCode, 0)
            if name == null then
                set name = ""
            endif
        endif
        if name == "" then
            set name = GetObjectName(rawCode)
            if name == null then
                set name = ""
            endif
        endif

        return name
    endfunction

    private function DBG_GetItemDisplayName takes integer rawCode returns string
        local string name = DBG_GetKnownItemName(rawCode)

        if name == "" then
            set name = DBG_RawCodeText(rawCode)
        endif

        return name
    endfunction

    private function DBG_GetUnitDisplayName takes integer rawCode returns string
        local string name = DBG_GetKnownUnitName(rawCode)

        if name == "" then
            set name = DBG_RawCodeText(rawCode)
        endif

        return name
    endfunction

    private function DBG_GetAbilityDisplayName takes integer rawCode returns string
        local string name = DBG_GetKnownAbilityName(rawCode)

        if name == "" then
            set name = DBG_RawCodeText(rawCode)
        endif

        return name
    endfunction

    private function DBG_ResolveItem takes string argument returns integer
        local string query = DBG_Unquote(argument)
        local integer rawCode = 0

        if query == "" then
            return 0
        endif

        if StringLength(query) == 4 then
            set rawCode = BlzS2FourCC(query)
            if DebugObjectRegistry_GetItemIndexByCode(rawCode) != 0 then
                return rawCode
            endif
        endif

        set rawCode = DebugObjectRegistry_FindItem(query)
        if rawCode != 0 then
            return rawCode
        endif

        if StringLength(query) == 4 then
            return BlzS2FourCC(query)
        endif

        return 0
    endfunction

    private function DBG_ResolveUnit takes string argument returns integer
        local string query = DBG_Unquote(argument)
        local integer rawCode = 0

        if query == "" then
            return 0
        endif

        if StringLength(query) == 4 then
            set rawCode = BlzS2FourCC(query)
            if DebugObjectRegistry_GetUnitIndexByCode(rawCode) != 0 then
                return rawCode
            endif
        endif

        set rawCode = DebugObjectRegistry_FindUnit(query)
        if rawCode != 0 then
            return rawCode
        endif

        if StringLength(query) == 4 then
            return BlzS2FourCC(query)
        endif

        return 0
    endfunction

    private function DBG_ResolveAbility takes string argument returns integer
        local string query = DBG_Unquote(argument)
        local integer rawCode = 0

        if query == "" then
            return 0
        endif

        if StringLength(query) == 4 then
            set rawCode = BlzS2FourCC(query)
            if DebugObjectRegistry_GetAbilityIndexByCode(rawCode) != 0 then
                return rawCode
            endif
        endif

        set rawCode = DebugObjectRegistry_FindAbility(query)
        if rawCode != 0 then
            return rawCode
        endif

        if StringLength(query) == 4 then
            return BlzS2FourCC(query)
        endif

        return 0
    endfunction

    private function DBG_PrintItemLookup takes player whichPlayer, string argument returns nothing
        local string query = DBG_Unquote(argument)
        local integer count
        local integer resultNumber = 1
        local integer index
        local integer rawCode = 0
        local string knownName = ""

        if query == "" then
            call DBG_Message(whichPlayer, "Usage: /debug item lookup '<rawcode-or-name>'")
            return
        endif

        if StringLength(query) == 4 then
            set rawCode = BlzS2FourCC(query)
            set knownName = DBG_GetKnownItemName(rawCode)
            if knownName != "" then
                call DBG_Message(whichPlayer, "Raw " + DBG_RawCodeText(rawCode) + ": " + knownName)
            endif
        endif

        set count = DebugObjectRegistry_GetItemMatchCount(query)
        if count <= 0 then
            if knownName == "" then
                call DBG_Message(whichPlayer, "No item matches for \"" + query + "\".")
            endif
            return
        endif

        call DBG_Message(whichPlayer, "Item matches for \"" + query + "\":")
        loop
            exitwhen resultNumber > count or resultNumber > DBG_MAX_LOOKUP_RESULTS
            set index = DebugObjectRegistry_GetItemMatchIndex(query, resultNumber)
            set rawCode = DebugObjectRegistry_GetItemCode(index)
            call DBG_Message(whichPlayer, DBG_RawCodeText(rawCode) + " - " + DebugObjectRegistry_GetItemName(index))
            set resultNumber = resultNumber + 1
        endloop

        if count > DBG_MAX_LOOKUP_RESULTS then
            call DBG_Message(whichPlayer, "And " + I2S(count - DBG_MAX_LOOKUP_RESULTS) + " more item matches.")
        endif
    endfunction

    private function DBG_PrintUnitLookup takes player whichPlayer, string argument returns nothing
        local string query = DBG_Unquote(argument)
        local integer count
        local integer resultNumber = 1
        local integer index
        local integer rawCode = 0
        local string knownName = ""

        if query == "" then
            call DBG_Message(whichPlayer, "Usage: /debug unit lookup '<rawcode-or-name>'")
            return
        endif

        if StringLength(query) == 4 then
            set rawCode = BlzS2FourCC(query)
            set knownName = DBG_GetKnownUnitName(rawCode)
            if knownName != "" then
                call DBG_Message(whichPlayer, "Raw " + DBG_RawCodeText(rawCode) + ": " + knownName)
            endif
        endif

        set count = DebugObjectRegistry_GetUnitMatchCount(query)
        if count <= 0 then
            if knownName == "" then
                call DBG_Message(whichPlayer, "No unit matches for \"" + query + "\".")
            endif
            return
        endif

        call DBG_Message(whichPlayer, "Unit matches for \"" + query + "\":")
        loop
            exitwhen resultNumber > count or resultNumber > DBG_MAX_LOOKUP_RESULTS
            set index = DebugObjectRegistry_GetUnitMatchIndex(query, resultNumber)
            set rawCode = DebugObjectRegistry_GetUnitCode(index)
            call DBG_Message(whichPlayer, DBG_RawCodeText(rawCode) + " - " + DebugObjectRegistry_GetUnitName(index))
            set resultNumber = resultNumber + 1
        endloop

        if count > DBG_MAX_LOOKUP_RESULTS then
            call DBG_Message(whichPlayer, "And " + I2S(count - DBG_MAX_LOOKUP_RESULTS) + " more unit matches.")
        endif
    endfunction

    private function DBG_PrintAbilityLookup takes player whichPlayer, string argument returns nothing
        local string query = DBG_Unquote(argument)
        local integer count
        local integer resultNumber = 1
        local integer index
        local integer rawCode = 0
        local string knownName = ""

        if query == "" then
            call DBG_Message(whichPlayer, "Usage: /debug ability lookup '<rawcode-or-name>'")
            return
        endif

        if StringLength(query) == 4 then
            set rawCode = BlzS2FourCC(query)
            set knownName = DBG_GetKnownAbilityName(rawCode)
            if knownName != "" then
                call DBG_Message(whichPlayer, "Raw " + DBG_RawCodeText(rawCode) + ": " + knownName)
            endif
        endif

        set count = DebugObjectRegistry_GetAbilityMatchCount(query)
        if count <= 0 then
            if knownName == "" then
                call DBG_Message(whichPlayer, "No ability matches for \"" + query + "\".")
            endif
            return
        endif

        call DBG_Message(whichPlayer, "Ability matches for \"" + query + "\":")
        loop
            exitwhen resultNumber > count or resultNumber > DBG_MAX_LOOKUP_RESULTS
            set index = DebugObjectRegistry_GetAbilityMatchIndex(query, resultNumber)
            set rawCode = DebugObjectRegistry_GetAbilityCode(index)
            call DBG_Message(whichPlayer, DBG_RawCodeText(rawCode) + " - " + DebugObjectRegistry_GetAbilityName(index))
            set resultNumber = resultNumber + 1
        endloop

        if count > DBG_MAX_LOOKUP_RESULTS then
            call DBG_Message(whichPlayer, "And " + I2S(count - DBG_MAX_LOOKUP_RESULTS) + " more ability matches.")
        endif
    endfunction

    private function DBG_CreateItemForPlayer takes player whichPlayer, string argument, real cameraX, real cameraY, boolean hasCamera returns nothing
        local string query = DBG_Unquote(argument)
        local integer rawCode = DBG_ResolveItem(query)
        local unit target = null
        local item createdItem = null
        local boolean added = false
        local string itemName = ""

        if query == "" then
            call DBG_Message(whichPlayer, "Usage: /debug item create '<rawcode-or-name>'")
            return
        endif

        if rawCode == 0 then
            call DBG_Message(whichPlayer, "Unknown item: " + query)
            return
        endif

        set itemName = DBG_GetItemDisplayName(rawCode)
        set target = DBG_GetSelectedUnit(whichPlayer)

        if target != null then
            set createdItem = CreateItem(rawCode, GetUnitX(target), GetUnitY(target))
            if createdItem == null then
                call DBG_Message(whichPlayer, "Failed to create item " + DBG_RawCodeText(rawCode) + " (" + itemName + ").")
            else
                set added = UnitAddItem(target, createdItem)
                if added then
                    call DBG_Message(whichPlayer, "Created " + DBG_RawCodeText(rawCode) + " (" + itemName + ") for " + DBG_GetUnitLabel(target) + ".")
                else
                    call DBG_Message(whichPlayer, "Created " + DBG_RawCodeText(rawCode) + " (" + itemName + ") at " + DBG_GetUnitLabel(target) + "; inventory add failed.")
                endif
            endif
        elseif hasCamera then
            set createdItem = CreateItem(rawCode, cameraX, cameraY)
            if createdItem == null then
                call DBG_Message(whichPlayer, "Failed to create item " + DBG_RawCodeText(rawCode) + " (" + itemName + ").")
            else
                call DBG_Message(whichPlayer, "Created " + DBG_RawCodeText(rawCode) + " (" + itemName + ") at camera target.")
            endif
        else
            call DBG_Message(whichPlayer, "No selected unit and no synced camera position. Try the command again.")
        endif

        set createdItem = null
        set target = null
    endfunction

    private function DBG_CreateUnitForPlayer takes player whichPlayer, string argument, real cameraX, real cameraY, boolean hasCamera returns nothing
        local string query = DBG_Unquote(argument)
        local integer rawCode = DBG_ResolveUnit(query)
        local unit createdUnit = null
        local string unitName = ""

        if query == "" then
            call DBG_Message(whichPlayer, "Usage: /debug unit create '<rawcode-or-name>'")
            return
        endif

        if rawCode == 0 then
            call DBG_Message(whichPlayer, "Unknown unit: " + query)
            return
        endif

        if not hasCamera then
            call DBG_Message(whichPlayer, "No synced camera position. Try the command again.")
            return
        endif

        set unitName = DBG_GetUnitDisplayName(rawCode)
        set createdUnit = CreateUnit(whichPlayer, rawCode, cameraX, cameraY, bj_UNIT_FACING)
        if createdUnit == null then
            call DBG_Message(whichPlayer, "Failed to create unit " + DBG_RawCodeText(rawCode) + " (" + unitName + ").")
        else
            call DBG_Message(whichPlayer, "Created " + DBG_RawCodeText(rawCode) + " (" + unitName + ") at camera target.")
        endif

        set createdUnit = null
    endfunction

    private function DBG_IsFishPoolDefinition takes integer defId returns boolean
        return GNU_IsDefinitionEnabled(defId) and GNU_GetDefinitionCategoryId(defId) == DBG_FISH_POOL_CATEGORY_ID and GNU_GetDefinitionProfessionId(defId) == GNS_PROF_FISHING
    endfunction

    private function DBG_GetFishPoolDefinitionCount takes nothing returns integer
        local integer defId = 0
        local integer count = 0
        local integer definitionCount = GNU_GetDefinitionCount()

        loop
            exitwhen defId >= definitionCount
            if DBG_IsFishPoolDefinition(defId) then
                set count = count + 1
            endif
            set defId = defId + 1
        endloop

        return count
    endfunction

    private function DBG_GetFishPoolDefinitionByOrdinal takes integer ordinal returns integer
        local integer defId = 0
        local integer count = 0
        local integer definitionCount = GNU_GetDefinitionCount()

        loop
            exitwhen defId >= definitionCount
            if DBG_IsFishPoolDefinition(defId) then
                set count = count + 1
                if count == ordinal then
                    return defId
                endif
            endif
            set defId = defId + 1
        endloop

        return -1
    endfunction

    private function DBG_SpawnRandomFishPool takes player whichPlayer, real cameraX, real cameraY, boolean hasCamera returns nothing
        local integer fishPoolCount
        local integer defId
        local integer zoneId
        local string zoneName
        local unit spawnedPool = null

        if not hasCamera then
            call DBG_Message(whichPlayer, "No synced camera position. Try the command again.")
            return
        endif

        set fishPoolCount = DBG_GetFishPoolDefinitionCount()
        if fishPoolCount <= 0 then
            call DBG_Message(whichPlayer, "Failed to spawn random fish pool: no enabled fishing pool definitions registered in GatherNodeUnits.")
            return
        endif

        set zoneId = ZonesCore_GetZoneIdAtPoint(cameraX, cameraY)
        if zoneId <= 0 then
            call DBG_Message(whichPlayer, "Failed to spawn random fish pool: camera target is not inside a registered zone.")
            return
        endif

        set defId = DBG_GetFishPoolDefinitionByOrdinal(GetRandomInt(1, fishPoolCount))
        if defId < 0 then
            call DBG_Message(whichPlayer, "Failed to spawn random fish pool: random definition lookup failed.")
            return
        endif

        set spawnedPool = GNU_ForceSpawn(defId, cameraX, cameraY, zoneId)
        set zoneName = ZonesCore_Zones_GetZoneName(zoneId)
        if zoneName == null or zoneName == "" then
            set zoneName = "zone " + I2S(zoneId)
        endif

        if spawnedPool == null then
            call DBG_Message(whichPlayer, "Failed to spawn " + GNU_GetDefinitionName(defId) + " " + DBG_RawCodeText(GNU_GetDefinitionUnitCode(defId)) + " in " + zoneName + ". Check water/terrain restrictions or FishRects.")
        else
            call DBG_Message(whichPlayer, "Spawned " + GNU_GetDefinitionName(defId) + " " + DBG_RawCodeText(GNU_GetDefinitionUnitCode(defId)) + " in " + zoneName + " at camera target.")
        endif

        set spawnedPool = null
    endfunction

    private function DBG_GiveAbilityToSelected takes player whichPlayer, string argument returns nothing
        local string query = DBG_Unquote(argument)
        local integer rawCode = DBG_ResolveAbility(query)
        local unit target = DBG_GetSelectedUnit(whichPlayer)
        local string abilityName = ""

        if query == "" then
            call DBG_Message(whichPlayer, "Usage: /debug ability give '<rawcode-or-name>'")
            set target = null
            return
        endif

        if target == null then
            call DBG_Message(whichPlayer, "Select a unit before giving an ability.")
            return
        endif

        if rawCode == 0 then
            call DBG_Message(whichPlayer, "Unknown ability: " + query)
            set target = null
            return
        endif

        set abilityName = DBG_GetAbilityDisplayName(rawCode)
        if UnitAddAbility(target, rawCode) then
            call DBG_Message(whichPlayer, "Added " + DBG_RawCodeText(rawCode) + " (" + abilityName + ") to " + DBG_GetUnitLabel(target) + ".")
        else
            call DBG_Message(whichPlayer, "Failed to add " + DBG_RawCodeText(rawCode) + " (" + abilityName + ") to " + DBG_GetUnitLabel(target) + ".")
        endif

        set target = null
    endfunction

    private function DBG_RespawnDungeonUnits takes player whichPlayer, string argument returns nothing
        local string trimmed = DBG_Trim(argument)
        local integer zoneId
        local integer dungeonId

        if trimmed == "" then
            call Dungeon_RespawnEveryDungeonNow()
            call DBG_Message(whichPlayer, "Respawned all dead dungeon creeps and bosses.")
            return
        endif

        set zoneId = S2I(trimmed)
        set dungeonId = Dungeon_GetIdByZone(zoneId)
        if zoneId <= 0 or dungeonId <= 0 then
            call DBG_Message(whichPlayer, "Unknown dungeon zone id: " + trimmed)
            return
        endif
        call Dungeon_RespawnAllNow(dungeonId)
        call DBG_Message(whichPlayer, "Respawned dead dungeon creeps and bosses for zone " + I2S(zoneId) + ".")
    endfunction

    private function DBG_ShowSelectedDrunk takes player whichPlayer returns nothing
        local unit target = DBG_GetSelectedUnit(whichPlayer)

        if target == null then
            call DBG_Message(whichPlayer, "Select a unit before using /debug drunk.")
        else
            call DBG_Message(whichPlayer, DBG_GetUnitLabel(target) + " Drunk: " + I2S(Drunk_GetLevel(target)) + "/100.")
        endif
        set target = null
    endfunction

    private function DBG_UnitHiderHideAll takes player whichPlayer returns nothing
        local integer hiddenCount = UnitHider_DebugHideAllExceptTracked()

        call DBG_Message(whichPlayer, "UnitHider force-hid " + I2S(hiddenCount) + " eligible non-tracked units. Normal updates may reveal units inside reference range.")
    endfunction

    private function DBG_UnitHiderUnhideAll takes player whichPlayer returns nothing
        local integer shownCount = UnitHider_DebugUnhideAllExceptTracked()

        call DBG_Message(whichPlayer, "UnitHider unhid " + I2S(shownCount) + " managed non-tracked units. Enabled state unchanged.")
    endfunction

    private function DBG_UnitHiderSetEnabled takes player whichPlayer, boolean enabled returns nothing
        call UnitHider_SetSystemEnabled(enabled)
        if enabled then
            call DBG_Message(whichPlayer, "UnitHider enabled; a full settlement will run on the next system tick.")
        else
            call DBG_Message(whichPlayer, "UnitHider disabled and all UnitHider-managed units were unhidden.")
        endif
    endfunction

    private function DBG_UnitHiderAudit takes player whichPlayer returns nothing
        call UnitHider_DebugAudit(whichPlayer)
    endfunction

    private function DBG_SetDoodadRenderDistance takes player whichPlayer, string argument returns nothing
        local string trimmed = DBG_Trim(argument)
        local real drawDistance

        if not DBG_IsNonNegativeReal(trimmed) then
            call DBG_Message(whichPlayer, "Usage: /debug doodadrender distance <non-negative integer-or-real>")
            return
        endif
        set drawDistance = S2R(trimmed)
        if DoodadRender_SetAllDrawDistances(drawDistance) then
            call DBG_Message(whichPlayer, "Set all DoodadRender distances to " + R2S(drawDistance) + ".")
        else
            call DBG_Message(whichPlayer, "DoodadRender rejected distance " + trimmed + ".")
        endif
    endfunction

    private function DBG_DisableNextPerformanceSystem takes nothing returns nothing
        set DBG_PerformanceStep = DBG_PerformanceStep + 1
        if DBG_PerformanceStep == 1 then
            call AI_DebugPause()
            call DBG_Message(DBG_PerformancePlayer, "Performance step 1/11: disabled AI periodic thinking, random spawning, and random travel.")
        elseif DBG_PerformanceStep == 2 then
            call ExecuteFunc("UnitMovementDisable")
            call DBG_Message(DBG_PerformancePlayer, "Performance step 2/11: disabled the global IsUnitMoving tracker.")
        elseif DBG_PerformanceStep == 3 then
            call TerrainDamage_SetSystemEnabled(false)
            call DBG_Message(DBG_PerformancePlayer, "Performance step 3/11: disabled TerrainDamage scans and terrain-damage timers.")
        elseif DBG_PerformanceStep == 4 then
            call QuestMaster_SetEvaluationEnabled(false)
            call DBG_Message(DBG_PerformancePlayer, "Performance step 4/11: disabled QuestMaster periodic availability evaluation.")
        elseif DBG_PerformanceStep == 5 then
            call AIRoutines_SetSystemEnabled(false)
            call DBG_Message(DBG_PerformancePlayer, "Performance step 5/11: disabled AIRoutines periodic NPC behavior.")
        elseif DBG_PerformanceStep == 6 then
            call Companions_SetPeriodicEnabled(false)
            call DBG_Message(DBG_PerformancePlayer, "Performance step 6/11: disabled Companions idle and order updates.")
        elseif DBG_PerformanceStep == 7 then
            call WeatherSystem_SetFPSOptimization(true)
            call WeatherSystem_SetCloudsEnabled(false)
            call WeatherSystem_SetRipplesEnabled(false)
            call WeatherSystem_SetThunderEnabled(false)
            call WeatherSystem_SetSteamBreathEnabled(false)
            call WeatherSystem_EnableSeasonalWeather(false)
            call DBG_Message(DBG_PerformancePlayer, "Performance step 7/11: disabled optional WeatherSystem effects and seasonal checks.")
        elseif DBG_PerformanceStep == 8 then
            call VendorFloatingText_SetEnabled(false)
            call DBG_Message(DBG_PerformancePlayer, "Performance step 8/11: disabled VendorFloatingText updates.")
        elseif DBG_PerformanceStep == 9 then
            call GN_SetSystemEnabled(false)
            call DBG_Message(DBG_PerformancePlayer, "Performance step 9/11: disabled GatherNodes spawn, respawn, and lifetime work.")
        elseif DBG_PerformanceStep == 10 then
            call UnitHider_DebugPauseProcessing()
            call DBG_Message(DBG_PerformancePlayer, "Performance step 10/11: paused UnitHider4 processing without unhiding units.")
        elseif DBG_PerformanceStep == 11 then
            call DoodadRender_DebugPause()
            call DBG_Message(DBG_PerformancePlayer, "Performance step 11/11: paused DoodadRender without restoring hidden doodads.")
        endif
        if DBG_PerformanceStep >= DBG_PERFORMANCE_SYSTEM_COUNT then
            set DBG_PerformanceActive = false
            call PauseTimer(DBG_PerformanceTimer)
            call DBG_Message(DBG_PerformancePlayer, "Performance sequence complete. Systems stay disabled until the map is reloaded.")
            set DBG_PerformancePlayer = null
        else
            call DBG_Message(DBG_PerformancePlayer, "Observe performance; the next system will be disabled in 5 seconds.")
        endif
    endfunction

    private function DBG_PerformanceTimerExpired takes nothing returns nothing
        call DBG_DisableNextPerformanceSystem()
    endfunction

    private function DBG_StartPerformanceDisable takes player whichPlayer returns nothing
        if DBG_PerformanceActive then
            call DBG_Message(whichPlayer, "Performance disable sequence is already running at step " + I2S(DBG_PerformanceStep) + "/" + I2S(DBG_PERFORMANCE_SYSTEM_COUNT) + ".")
            return
        endif
        set DBG_PerformanceActive = true
        set DBG_PerformancePlayer = whichPlayer
        set DBG_PerformanceStep = 0
        call DBG_Message(whichPlayer, "Starting one-way performance isolation for 11 heavy systems at 5-second intervals.")
        call DBG_DisableNextPerformanceSystem()
        call TimerStart(DBG_PerformanceTimer, DBG_PERFORMANCE_STEP_INTERVAL, true, function DBG_PerformanceTimerExpired)
    endfunction

    private function DBG_ShowHelp takes player whichPlayer returns nothing
        call DBG_Message(whichPlayer, "Commands:")
        call DBG_Message(whichPlayer, "/debug item create '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug item lookup '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug unit create '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug unit lookup '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug ability give '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug ability lookup '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug fishpool spawn")
        call DBG_Message(whichPlayer, "/debug drunk")
        call DBG_Message(whichPlayer, "/debug unstuck (bypasses the 5-minute cooldown)")
        call DBG_Message(whichPlayer, "/debug creeprespawn dungeon respawn [zoneId]")
        call DBG_Message(whichPlayer, "/debug unithider hide all")
        call DBG_Message(whichPlayer, "/debug unithider unhide all")
        call DBG_Message(whichPlayer, "/debug unithider enable")
        call DBG_Message(whichPlayer, "/debug unithider disable")
        call DBG_Message(whichPlayer, "/debug unithider audit")
        call DBG_Message(whichPlayer, "/debug doodadrender distance <distance> (sets tiny, short, medium, and long)")
        call DBG_Message(whichPlayer, "/debug performance disable (one-way; disables 11 heavy systems every 5 seconds)")
        call DBG_Message(whichPlayer, "/debug wc3 help (baseline, camera, fog, and doodad probes)")
        call DBG_Message(whichPlayer, "/debug wc3 effects help (P2 special-effect animation probes)")
        call DBG_Message(whichPlayer, "/debug wc3 minimap help (P2 native/imported minimap probes)")
    endfunction

    private function DBG_ExecuteCommand takes player whichPlayer, string command, real cameraX, real cameraY, boolean hasCamera returns nothing
        local string trimmed = DBG_Trim(command)
        local string lowerCommand = StringCase(trimmed, false)
        local string argument = ""

        if trimmed == "" or lowerCommand == "help" then
            call DBG_ShowHelp(whichPlayer)
        elseif Warcraft300TestHarness_Execute(whichPlayer, lowerCommand) then
            return
        elseif Warcraft300P2TestHarness_Execute(whichPlayer, lowerCommand, cameraX, cameraY, hasCamera) then
            return
        elseif DBG_StartsWith(lowerCommand, "item create ") then
            set argument = SubString(trimmed, StringLength("item create "), StringLength(trimmed))
            call DBG_CreateItemForPlayer(whichPlayer, argument, cameraX, cameraY, hasCamera)
        elseif lowerCommand == "item create" then
            call DBG_CreateItemForPlayer(whichPlayer, "", cameraX, cameraY, hasCamera)
        elseif DBG_StartsWith(lowerCommand, "item lookup ") then
            set argument = SubString(trimmed, StringLength("item lookup "), StringLength(trimmed))
            call DBG_PrintItemLookup(whichPlayer, argument)
        elseif lowerCommand == "item lookup" then
            call DBG_PrintItemLookup(whichPlayer, "")
        elseif DBG_StartsWith(lowerCommand, "unit create ") then
            set argument = SubString(trimmed, StringLength("unit create "), StringLength(trimmed))
            call DBG_CreateUnitForPlayer(whichPlayer, argument, cameraX, cameraY, hasCamera)
        elseif lowerCommand == "unit create" then
            call DBG_CreateUnitForPlayer(whichPlayer, "", cameraX, cameraY, hasCamera)
        elseif DBG_StartsWith(lowerCommand, "unit lookup ") then
            set argument = SubString(trimmed, StringLength("unit lookup "), StringLength(trimmed))
            call DBG_PrintUnitLookup(whichPlayer, argument)
        elseif lowerCommand == "unit lookup" then
            call DBG_PrintUnitLookup(whichPlayer, "")
        elseif DBG_StartsWith(lowerCommand, "ability lookup ") then
            set argument = SubString(trimmed, StringLength("ability lookup "), StringLength(trimmed))
            call DBG_PrintAbilityLookup(whichPlayer, argument)
        elseif lowerCommand == "ability lookup" then
            call DBG_PrintAbilityLookup(whichPlayer, "")
        elseif DBG_StartsWith(lowerCommand, "ability give ") then
            set argument = SubString(trimmed, StringLength("ability give "), StringLength(trimmed))
            call DBG_GiveAbilityToSelected(whichPlayer, argument)
        elseif lowerCommand == "ability give" then
            call DBG_GiveAbilityToSelected(whichPlayer, "")
        elseif DBG_StartsWith(lowerCommand, "ability add ") then
            set argument = SubString(trimmed, StringLength("ability add "), StringLength(trimmed))
            call DBG_GiveAbilityToSelected(whichPlayer, argument)
        elseif lowerCommand == "ability add" then
            call DBG_GiveAbilityToSelected(whichPlayer, "")
        elseif lowerCommand == "fishpool spawn" or lowerCommand == "fish pool spawn" or lowerCommand == "fishing pool spawn" then
            call DBG_SpawnRandomFishPool(whichPlayer, cameraX, cameraY, hasCamera)
        elseif lowerCommand == "drunk" or lowerCommand == "stat drunk" then
            call DBG_ShowSelectedDrunk(whichPlayer)
        elseif lowerCommand == "unstuck" then
            call PlayerHome_UnstuckSelectedHeroes(whichPlayer, true)
        elseif lowerCommand == "creeprespawn dungeon respawn" or lowerCommand == "dungeon respawn" then
            call DBG_RespawnDungeonUnits(whichPlayer, "")
        elseif DBG_StartsWith(lowerCommand, "creeprespawn dungeon respawn ") then
            set argument = SubString(trimmed, StringLength("creeprespawn dungeon respawn "), StringLength(trimmed))
            call DBG_RespawnDungeonUnits(whichPlayer, argument)
        elseif DBG_StartsWith(lowerCommand, "dungeon respawn ") then
            set argument = SubString(trimmed, StringLength("dungeon respawn "), StringLength(trimmed))
            call DBG_RespawnDungeonUnits(whichPlayer, argument)
        elseif lowerCommand == "unithider hide all" or lowerCommand == "unithider hide" or lowerCommand == "unit hider hide all" then
            call DBG_UnitHiderHideAll(whichPlayer)
        elseif lowerCommand == "unithider unhide all" or lowerCommand == "unithider unhide" or lowerCommand == "unit hider unhide all" then
            call DBG_UnitHiderUnhideAll(whichPlayer)
        elseif lowerCommand == "unithider enable" or lowerCommand == "unit hider enable" then
            call DBG_UnitHiderSetEnabled(whichPlayer, true)
        elseif lowerCommand == "unithider disable" or lowerCommand == "unit hider disable" then
            call DBG_UnitHiderSetEnabled(whichPlayer, false)
        elseif lowerCommand == "unithider audit" or lowerCommand == "unit hider audit" then
            call DBG_UnitHiderAudit(whichPlayer)
        elseif DBG_StartsWith(lowerCommand, "doodadrender distance ") then
            set argument = SubString(trimmed, StringLength("doodadrender distance "), StringLength(trimmed))
            call DBG_SetDoodadRenderDistance(whichPlayer, argument)
        elseif lowerCommand == "doodadrender distance" then
            call DBG_SetDoodadRenderDistance(whichPlayer, "")
        elseif lowerCommand == "performance disable" or lowerCommand == "perf disable" then
            call DBG_StartPerformanceDisable(whichPlayer)
        else
            call DBG_Message(whichPlayer, "Unknown command. Use /debug help.")
        endif
    endfunction

    private function DBG_CommandNeedsCamera takes player whichPlayer, string command returns boolean
        local string trimmed = DBG_Trim(command)
        local string lowerCommand = StringCase(trimmed, false)

        if DBG_StartsWith(lowerCommand, "unit create ") or lowerCommand == "unit create" then
            return true
        endif

        if lowerCommand == "wc3 effects create" then
            return true
        endif

        if lowerCommand == "fishpool spawn" or lowerCommand == "fish pool spawn" or lowerCommand == "fishing pool spawn" then
            return true
        endif

        if DBG_StartsWith(lowerCommand, "item create ") or lowerCommand == "item create" then
            return DBG_GetSelectedUnit(whichPlayer) == null
        endif

        return false
    endfunction

    private function DBG_SendCameraCommand takes player whichPlayer, string command returns nothing
        if GetLocalPlayer() == whichPlayer then
            call BlzSendSyncData(DBG_SYNC_PREFIX, R2S(GetCameraTargetPositionX()) + "|" + R2S(GetCameraTargetPositionY()) + "|" + command)
        endif
    endfunction

    private function DBG_OnPlayerChat takes nothing returns nothing
        local player triggerPlayer = GetTriggerPlayer()
        local string message = GetEventPlayerChatString()
        local string messageLower = StringCase(message, false)
        local string command = ""

        if messageLower == DBG_ROOT then
            set command = ""
        elseif DBG_StartsWith(messageLower, DBG_PREFIX) then
            set command = SubString(message, StringLength(DBG_PREFIX), StringLength(message))
        else
            set triggerPlayer = null
            return
        endif

        if DBG_CommandNeedsCamera(triggerPlayer, command) then
            call DBG_SendCameraCommand(triggerPlayer, command)
        else
            call DBG_ExecuteCommand(triggerPlayer, command, 0.00, 0.00, false)
        endif

        set triggerPlayer = null
    endfunction

    private function DBG_OnSync takes nothing returns nothing
        local player triggerPlayer = GetTriggerPlayer()
        local string data = BlzGetTriggerSyncData()
        local integer firstPipe = DBG_FindChar(data, "|", 0)
        local integer secondPipe = -1
        local real cameraX = 0.00
        local real cameraY = 0.00
        local string command = ""

        if firstPipe >= 0 then
            set secondPipe = DBG_FindChar(data, "|", firstPipe + 1)
        endif

        if firstPipe < 0 or secondPipe < 0 then
            call DBG_Message(triggerPlayer, "Invalid camera sync payload.")
            set triggerPlayer = null
            return
        endif

        set cameraX = S2R(SubString(data, 0, firstPipe))
        set cameraY = S2R(SubString(data, firstPipe + 1, secondPipe))
        set command = SubString(data, secondPipe + 1, StringLength(data))
        call DBG_ExecuteCommand(triggerPlayer, command, cameraX, cameraY, true)

        set triggerPlayer = null
    endfunction

    private function DBG_OnUnitSelected takes nothing returns nothing
        set DBG_SelectedUnit[GetPlayerId(GetTriggerPlayer())] = GetTriggerUnit()
    endfunction

    private function DBG_OnUnitDeselected takes nothing returns nothing
        local integer playerId = GetPlayerId(GetTriggerPlayer())

        if DBG_SelectedUnit[playerId] == GetTriggerUnit() then
            set DBG_SelectedUnit[playerId] = null
        endif
    endfunction

    private function DBG_RegisterChatCommands takes nothing returns nothing
        local integer playerIndex = 0

        set DBG_ChatTrigger = CreateTrigger()
        loop
            exitwhen playerIndex == bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerChatEvent(DBG_ChatTrigger, Player(playerIndex), DBG_ROOT, false)
            set playerIndex = playerIndex + 1
        endloop
        call TriggerAddAction(DBG_ChatTrigger, function DBG_OnPlayerChat)
    endfunction

    private function DBG_RegisterSync takes nothing returns nothing
        local integer playerIndex = 0

        set DBG_SyncTrigger = CreateTrigger()
        loop
            exitwhen playerIndex == bj_MAX_PLAYER_SLOTS
            call BlzTriggerRegisterPlayerSyncEvent(DBG_SyncTrigger, Player(playerIndex), DBG_SYNC_PREFIX, false)
            set playerIndex = playerIndex + 1
        endloop
        call TriggerAddAction(DBG_SyncTrigger, function DBG_OnSync)
    endfunction

    private function DBG_RegisterSelectionTracking takes nothing returns nothing
        local integer playerIndex = 0

        set DBG_SelectTrigger = CreateTrigger()
        set DBG_DeselectTrigger = CreateTrigger()
        loop
            exitwhen playerIndex == bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerUnitEvent(DBG_SelectTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_SELECTED, null)
            call TriggerRegisterPlayerUnitEvent(DBG_DeselectTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DESELECTED, null)
            set playerIndex = playerIndex + 1
        endloop
        call TriggerAddAction(DBG_SelectTrigger, function DBG_OnUnitSelected)
        call TriggerAddAction(DBG_DeselectTrigger, function DBG_OnUnitDeselected)
    endfunction

    private function Init takes nothing returns nothing
        set DBG_PerformanceTimer = CreateTimer()
        call DBG_RegisterChatCommands()
        call DBG_RegisterSync()
        call DBG_RegisterSelectionTracking()
    endfunction
endlibrary
