library NSLImpl initializer Init requires NSLCodeHelper, NSLCodexStore
    globals
        // Saved into the code, requires a matching Codex to load (multi-versioning code support)
        constant integer NSL_CodeVersion = 1
        // Folder name where the save is located at : Documents\Warcraft III\CustomMapData\<<NSL_FolderName>>\SaveChar_<<Save_Name>>.pld
        constant string NSL_FolderName = "MaxouNSL"
         // MUST BE a prime number, used by the code generation to ensure the code is valid and not altered, editing this will render all previous generated codes invalid
		constant integer NSL_Key = 19
        // Allow the integrated -save/-load commands otherwise need to use a manual triggering system
        constant boolean NSL_UseSimpleSaveLoad = true
    endglobals

    // What could prevent a player from loading
    // Return `true` if the player can load, return `false` if he can't load
	public function CanLoad takes integer playerId returns boolean
		return true
	endfunction

    // What could prevent a player from saving
    // Return `true` if the player can save, return `false` if he can't save
	public function CanSave takes integer playerId returns boolean
		return true
	endfunction

    // Load your player's data from the loader
    public function LoadPlayerVer1 takes integer playerId, NSL_Code loader returns nothing
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        // only 4 values in code vers. 1
    endfunction

    public function LoadPlayerVer2 takes integer playerId, NSL_Code loader returns nothing
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        // 2 extra values in code vers. 2
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
        call PlayerUtils_Print(playerId, I2S(NSLCodeHelper_Read_Int(loader)))
    endfunction

    // Save your player's data into the saver
    public function SavePlayer takes integer playerId, NSL_Code saver returns nothing
        call NSLCodeHelper_Save_Int(saver, 100)
        call NSLCodeHelper_Save_Int(saver, 10000)
        call NSLCodeHelper_Save_Int(saver, 0)
        call NSLCodeHelper_Save_Int(saver, 5)
    endfunction
    
    // Register your Codex for each code version supported
    private function Init takes nothing returns nothing
        call NSLCodexStore_Add(1, LoadPlayerVer1)
        call NSLCodexStore_Add(2, LoadPlayerVer2)
    endfunction
endlibrary