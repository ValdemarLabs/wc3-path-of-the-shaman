/**
    PotSMaxouNSLAdapter

    Author: Valdemar
    Version: 2.1.0

    Description:
    Bridges bounded PotS integer streams to the immutable Maxou NSL codec and
    SaveFile core. It owns distinct PotS slots and no NSL command handlers.

    Credits:
    - Maxou, New Save Load (NSL)
    - TriggerHappy, FileIO and SaveFile

    How to install:
    Import PotSSaveConfig first, then the reusable vendor core (FileIO,
    SaveFile, NSL Size Enum, NSL Helper, NSL Save Load), then this library.
    Do not import the vendor NSLImpl/NSLUtils command example with this bridge.

    API:
    - PotSMaxouNSLAdapter_SetSaveCallback(callback)
    - PotSMaxouNSLAdapter_SetLoadCallback(callback)
    - PotSMaxouNSLAdapter_Save(playerId, slot)
    - PotSMaxouNSLAdapter_Load(playerId, slot)
    - PotSMaxouNSLAdapter_IsValidSlot(slot)

**/
library PotSMaxouNSLAdapter requires PotSSaveConfig, PotSStateSerializer, NSLSaveLoad, SaveFile
    function interface PotSMaxouNSLAdapterCallback takes integer playerId, boolean success, integer errorCode returns nothing

    globals
        private constant integer PNSL_COUNT_BITS = 10
        private constant integer PNSL_VALUE_BITS = 31
        private constant integer PNSL_FILE_CHARACTER_LIMIT = 10000
        private constant string PNSL_SLOT_PREFIX = "pots_"
        private constant string PNSL_ALLOWED_SLOT_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

        private PotSMaxouNSLAdapterCallback PNSL_SaveCallback = 0
        private PotSMaxouNSLAdapterCallback PNSL_LoadCallback = 0
        private string array PNSL_Slot
        private boolean array PNSL_Busy
    endglobals

    private function PNSL_NotifySave takes integer playerId, boolean success, integer errorCode returns nothing
        if PNSL_SaveCallback != 0 then
            call PNSL_SaveCallback.execute(playerId, success, errorCode)
        endif
    endfunction

    private function PNSL_NotifyLoad takes integer playerId, boolean success, integer errorCode returns nothing
        if PNSL_LoadCallback != 0 then
            call PNSL_LoadCallback.execute(playerId, success, errorCode)
        endif
    endfunction

    private function PNSL_ContainsAllowedCharacter takes string value returns boolean
        local integer i = 0
        loop
            exitwhen i >= StringLength(PNSL_ALLOWED_SLOT_CHARS)
            if SubString(PNSL_ALLOWED_SLOT_CHARS, i, i + 1) == value then
                return true
            endif
            set i = i + 1
        endloop
        return false
    endfunction

    private function PNSL_IsValidSlotLength takes string slot, integer maxLength returns boolean
        local integer length = StringLength(slot)
        local integer i = 0
        if slot == null or length < 1 or length > maxLength then
            return false
        endif
        loop
            exitwhen i >= length
            if not PNSL_ContainsAllowedCharacter(SubString(slot, i, i + 1)) then
                return false
            endif
            set i = i + 1
        endloop
        return true
    endfunction

    public function IsValidSlot takes string slot returns boolean
        return PNSL_IsValidSlotLength(slot, PotSSaveConfig_MAX_SLOT_LENGTH)
    endfunction

    private function PNSL_GetCharacterId takes string slot returns string
        return PNSL_SLOT_PREFIX + slot
    endfunction

    public function GetEstimatedCodeCharacters takes integer valueCount returns integer
        return (10 + PNSL_COUNT_BITS + valueCount * 32 + 5) / 6 + 7
    endfunction

    private function PNSL_CanEncodeValue takes integer value returns boolean
        return value >= -2147483647
    endfunction

    private function PNSL_WriteSigned takes NSL_Code saver, integer value returns nothing
        if value < 0 then
            call saver.SV(1, NSL_SIZE_BOOLEAN)
            call saver.SV(-value, PNSL_VALUE_BITS)
        else
            call saver.SV(0, NSL_SIZE_BOOLEAN)
            call saver.SV(value, PNSL_VALUE_BITS)
        endif
    endfunction

    private function PNSL_OnCodeGenerated takes integer playerId, string generatedCode returns nothing
        local string characterId = PNSL_GetCharacterId(PNSL_Slot[playerId])
        local boolean validLength = StringLength(generatedCode) > 7 and StringLength(generatedCode) <= PNSL_FILE_CHARACTER_LIMIT

        set PNSL_Busy[playerId] = false
        if validLength then
            call SaveFile.create(Player(playerId), characterId, characterId, generatedCode)
            call PNSL_NotifySave(playerId, true, PotSSaveConfig_ERROR_NONE)
        else
            call PNSL_NotifySave(playerId, false, PotSSaveConfig_ERROR_CAPACITY)
        endif
    endfunction

    private function PNSL_ReadPayload takes NSL_Code loader returns boolean
        local integer count = loader.RV(PNSL_COUNT_BITS)
        local integer i = 0
        local integer sign
        local integer magnitude
        local integer value

        if count < 1 or count > PotSSaveConfig_MAX_STREAM_VALUES then
            return false
        endif
        call PotSStateSerializer_BeginInput()
        loop
            exitwhen i >= count
            set sign = loader.RV(NSL_SIZE_BOOLEAN)
            set magnitude = loader.RV(PNSL_VALUE_BITS)
            if (sign != 0 and sign != 1) or magnitude < 0 then
                return false
            endif
            set value = magnitude
            if sign == 1 then
                set value = -magnitude
            endif
            if not PotSStateSerializer_PushInput(value) then
                return false
            endif
            set i = i + 1
        endloop
        return PotSStateSerializer_Deserialize()
    endfunction

    private function PNSL_OnCodeLoaded takes integer playerId, boolean isValid, NSL_Code loader returns nothing
        local boolean decoded = false
        local integer errorCode = PotSSaveConfig_ERROR_INVALID_CODE

        if isValid and loader.code_version == NSL_CodeVersion then
            set decoded = PNSL_ReadPayload(loader)
            if not decoded then
                set errorCode = PotSStateSerializer_GetLastError()
                if errorCode == PotSSaveConfig_ERROR_NONE then
                    set errorCode = PotSSaveConfig_ERROR_INVALID_DATA
                endif
            endif
        endif
        call loader.destroy()
        set PNSL_Busy[playerId] = false
        if decoded then
            call PNSL_NotifyLoad(playerId, true, PotSSaveConfig_ERROR_NONE)
        else
            call PNSL_NotifyLoad(playerId, false, errorCode)
        endif
    endfunction

    public function SetSaveCallback takes PotSMaxouNSLAdapterCallback callback returns nothing
        set PNSL_SaveCallback = callback
    endfunction

    public function SetLoadCallback takes PotSMaxouNSLAdapterCallback callback returns nothing
        set PNSL_LoadCallback = callback
    endfunction

    public function Save takes integer playerId, string slot returns boolean
        local integer i = 0
        local NSL_Code saver

        if playerId < 0 or playerId >= bj_MAX_PLAYER_SLOTS or PNSL_Busy[playerId] or not PNSL_IsValidSlotLength(slot, PotSSaveConfig_MAX_SLOT_LENGTH + 2) then
            return false
        endif
        if PotSStateSerializer_GetCount() < 1 or PotSStateSerializer_GetCount() > PotSSaveConfig_MAX_STREAM_VALUES or GetEstimatedCodeCharacters(PotSStateSerializer_GetCount()) > PNSL_FILE_CHARACTER_LIMIT then
            return false
        endif
        loop
            exitwhen i >= PotSStateSerializer_GetCount()
            if not PNSL_CanEncodeValue(PotSStateSerializer_GetValue(i)) then
                return false
            endif
            set i = i + 1
        endloop

        set PNSL_Busy[playerId] = true
        set PNSL_Slot[playerId] = slot
        set saver = NSL_Code.create_save(playerId, PNSL_OnCodeGenerated)
        call saver.SV(PotSStateSerializer_GetCount(), PNSL_COUNT_BITS)
        set i = 0
        loop
            exitwhen i >= PotSStateSerializer_GetCount()
            call PNSL_WriteSigned(saver, PotSStateSerializer_GetValue(i))
            set i = i + 1
        endloop
        call saver.Generate()
        return true
    endfunction

    public function Load takes integer playerId, string slot returns boolean
        local string characterId
        local string playerCode

        if playerId < 0 or playerId >= bj_MAX_PLAYER_SLOTS or PNSL_Busy[playerId] or not PNSL_IsValidSlotLength(slot, PotSSaveConfig_MAX_SLOT_LENGTH + 2) then
            return false
        endif
        set characterId = PNSL_GetCharacterId(slot)
        if not SaveFile.exists(characterId) then
            call PNSL_NotifyLoad(playerId, false, PotSSaveConfig_ERROR_FILE_NOT_FOUND)
            return true
        endif
        set playerCode = SaveFile.getData(characterId)
        if playerCode == null or StringLength(playerCode) <= 7 or StringLength(playerCode) > PNSL_FILE_CHARACTER_LIMIT then
            call PNSL_NotifyLoad(playerId, false, PotSSaveConfig_ERROR_INVALID_CODE)
            return true
        endif

        set PNSL_Busy[playerId] = true
        set PNSL_Slot[playerId] = slot
        call NSL_Code.create_load(playerId, playerCode, PNSL_OnCodeLoaded)
        return true
    endfunction
endlibrary
