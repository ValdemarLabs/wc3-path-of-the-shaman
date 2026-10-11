/*



            Don't edit this
            


*/
library NSLSaveLoadExecutor requires NSLImpl
    globals
        private NSL_Code saver
    endglobals
    
    private function LoadSaveSlot takes player p, string charId returns nothing
        local string s
        local User user = User[p]
        
        if (not SaveFile.exists(charId)) then
            call PlayerUtils_Print(user.id, "|cffff3333[Load Error]|r Did not find any save data.")
            return
        elseif (NSL_PlayerLoading[user.id]) then
            call PlayerUtils_Print(user.id, "|cffffcc00[Load Info]|r Please wait while your character synchronizes.")
        else
            set NSL_PlayerLoading[user.id] = true
            set s = SaveFile.getData(charId)
            if (GetLocalPlayer() == p) then
                call SyncString(s)
            endif
            call ClearTextMessages()
            call PlayerUtils_Print(user.id, "|cffffcc00[Load Info]|r Synchronizing with other players...")
        endif
    endfunction

    private function OnPlayerCodeGenerated takes integer player_id, string generated_code returns nothing
        local string charId = NSL_PlayerCharId[player_id]
		call SaveFile.create(Player(player_id), charId, charId, generated_code)
        if(player_id == GetPlayerId(GetLocalPlayer())) then
            call PlayerUtils_Print(player_id, "|cffffcc00[Save Info]|r Your code has been saved in |cffffcc00Documents\\Warcraft 3\\CustomMapData\\" + SaveFile.getPath(charId) + "|r")
        endif
    endfunction

    public function Load takes integer playerId, string loadSlotName returns nothing
        if(not NSLImpl_CanLoad(playerId)) then
            call PlayerUtils_Print(playerId, "|cffff3333[Load Error]|r You are not allowed to load.")
            return
        endif
        set NSL_PlayerCharId[playerId] = loadSlotName
        call LoadSaveSlot(Player(playerId), NSL_PlayerCharId[playerId])
    endfunction
    
    public function Save takes integer playerId, string saveSlotName returns nothing
        if(not NSLImpl_CanSave(playerId)) then
            call PlayerUtils_Print(playerId, "|cffff3333[Load Error]|r You are not allowed to save.")
            return
        endif
        set saver = NSL_Code.create_save(playerId, OnPlayerCodeGenerated)
        set NSL_PlayerCharId[playerId] = saveSlotName
        call NSLImpl_SavePlayer(playerId, saver)
        call saver.Generate()
    endfunction

endlibrary