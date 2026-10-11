/*



            Don't edit this
            


*/
library NSLUtils initializer Init requires PlayerUtils, NSLSaveLoadExecutor, NSLCodexStore

	globals
		constant trigger NSL_OnSave = CreateTrigger()
		constant trigger NSL_OnLoad = CreateTrigger()
        string array NSL_PlayerCharId
        boolean array NSL_PlayerLoading
        integer array NSL_PlayerLoadingExpectCount
        integer array NSL_PlayerLoadingCurrentCount
        string array NSL_PlayerLoadingCode
        
        constant trigger SL_OnLoadedTrigger = CreateTrigger()
		integer SL_LoadedPlayerId
        
        private CodexFormat format
	endglobals

    public function OnPlayerSave takes nothing returns nothing
        local player savingPlayer = GetTriggerPlayer()
		local string input = GetEventPlayerChatString()
        local string charId = null

		if(SubString(input, 0, 5) != "-save") then
			return
		endif
        if(StringLength(input) == 5) then
            call PlayerUtils_Print(GetPlayerId(savingPlayer), "|cffff3333[Save Error]|r Please name your save using '-save <character_name>' !")
            return
        endif
        call NSLSaveLoadExecutor_Save(GetPlayerId(savingPlayer), SubString(input, 6, 999))
    endfunction

    private function OnPlayerCodeLoaded takes integer player_id, boolean is_valid, NSL_Code loader returns nothing
        if(is_valid) then
            set format = NSLCodexStore_GetCodexForVersion(loader.code_version)
            if(format == -1) then
                call PlayerUtils_Print(player_id, "|cffff3333[Load Error]|r Code version is unsupported.")
                call loader.destroy()
                return
            endif
        
            call PlayerUtils_Print(player_id, "|cff33ff33[Load Success]|r Code loaded.")
            call format.execute(player_id, loader)
            call loader.destroy()
        else
            call PlayerUtils_Print(player_id, "|cffff3333[Load Error]|r Code is invalid.")
            call loader.destroy()
        endif
    endfunction
    
    public function OnPlayerLoad takes nothing returns nothing
		local string input = GetEventPlayerChatString()
        local player loadingPlayer = GetTriggerPlayer()

		if(SubString(input, 0, 5) != "-load") then
            return
		endif
        if(StringLength(input) == 5) then
            call PlayerUtils_Print(GetPlayerId(loadingPlayer), "|cffff3333[Load Error]|r Please name your load using '-load <character_name>' !")
            return
        endif
        call NSLSaveLoadExecutor_Load(GetPlayerId(loadingPlayer), SubString(input, 6, 999))
	endfunction
    
    private function LoadSaveSlot_OnLoadCount takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local string data = BlzGetTriggerSyncData()
        local User user = User[p]
        
        set NSL_PlayerLoadingExpectCount[user.id] = S2I(data)
        set NSL_PlayerLoadingCurrentCount[user.id] = 0
        set NSL_PlayerLoadingCode[user.id] = ""
    endfunction
    
    private function LoadSaveSlot_OnLoad takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local string data = BlzGetTriggerSyncData()
        local User user = User[p]
        
        set NSL_PlayerLoadingCurrentCount[user.id] = NSL_PlayerLoadingCurrentCount[user.id] + 1
        set NSL_PlayerLoadingCode[user.id] = NSL_PlayerLoadingCode[user.id] + data

        if(NSL_PlayerLoadingCurrentCount[user.id] == NSL_PlayerLoadingExpectCount[user.id]) then
            set NSL_PlayerLoading[user.id] = false
            call NSL_Code.create_load(user.id, NSL_PlayerLoadingCode[user.id], OnPlayerCodeLoaded)
        endif
    endfunction
    
	private function Init takes nothing returns nothing
		local integer i = 0

        call OnSyncStringCount(function LoadSaveSlot_OnLoadCount)
        call OnSyncString(function LoadSaveSlot_OnLoad)

		loop
            if(NSL_UseSimpleSaveLoad) then
                call TriggerRegisterPlayerChatEvent(NSL_OnSave, Player(i), "-save", false)
                call TriggerRegisterPlayerChatEvent(NSL_OnLoad, Player(i), "-load", false)
            endif
            set NSL_PlayerLoading[i] = false
            set NSL_PlayerLoadingExpectCount[i] = 0
            set NSL_PlayerLoadingCurrentCount[i] = 0
            set NSL_PlayerLoadingCode[i] = ""
			set i = i + 1
			exitwhen i == 24
		endloop

		call TriggerAddAction(NSL_OnSave, function OnPlayerSave)
		call TriggerAddAction(NSL_OnLoad, function OnPlayerLoad)

	endfunction

endlibrary