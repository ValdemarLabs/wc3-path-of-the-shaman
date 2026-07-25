/**
    DebugCommands

    Author: Valdemar
    Version:

    Description:
    Chat-driven debug commands for Path of the Shaman testing. Commands are
    intentionally routed through a single "/debug " prefix so this library can
    later serve as the foundation for player-facing cheats.

    Credits:

    How to install:
    Import DebugObjectRegistry before this library. The registry is generated
    from the latest checked-in item, unit, and ability object exports.

    API:
    - /debug help
    - /debug item create '<rawcode-or-name>'
    - /debug item lookup '<rawcode-or-name>'
    - /debug unit create '<rawcode-or-name>'
    - /debug unit lookup '<rawcode-or-name>'
    - /debug ability give '<rawcode-or-name>'
    - /debug ability lookup '<rawcode-or-name>'

**/
library DebugCommands initializer Init requires DebugObjectRegistry, Ascii
    globals
        private constant string DBG_ROOT = "/debug"
        private constant string DBG_PREFIX = "/debug "
        private constant string DBG_SYNC_PREFIX = "PDBG"
        private constant integer DBG_MAX_LOOKUP_RESULTS = 8

        private trigger DBG_ChatTrigger = null
        private trigger DBG_SyncTrigger = null
        private trigger DBG_SelectTrigger = null
        private trigger DBG_DeselectTrigger = null

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

    private function DBG_ShowHelp takes player whichPlayer returns nothing
        call DBG_Message(whichPlayer, "Commands:")
        call DBG_Message(whichPlayer, "/debug item create '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug item lookup '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug unit create '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug unit lookup '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug ability give '<rawcode-or-name>'")
        call DBG_Message(whichPlayer, "/debug ability lookup '<rawcode-or-name>'")
    endfunction

    private function DBG_ExecuteCommand takes player whichPlayer, string command, real cameraX, real cameraY, boolean hasCamera returns nothing
        local string trimmed = DBG_Trim(command)
        local string lowerCommand = StringCase(trimmed, false)
        local string argument = ""

        if trimmed == "" or lowerCommand == "help" then
            call DBG_ShowHelp(whichPlayer)
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
        call DBG_RegisterChatCommands()
        call DBG_RegisterSync()
        call DBG_RegisterSelectionTracking()
    endfunction
endlibrary
