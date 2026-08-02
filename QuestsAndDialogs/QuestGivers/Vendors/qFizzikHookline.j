/**
    qFizzikHookline

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Nibbs Netcaster, Goblin fisher.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Nibbs's vendor quest automatically.

**/
library qFizzikHookline initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n041', "Catch of the Minute", "daily", 6, "Catch of the Minute", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Bring Nibbs enough fish to satisfy a very impatient buyer.", 'I6CU', 9, 35, VL_VENDORQUEST_GOBLIN_TYPE, 7, VL_VENDORQUEST_GOBLIN_0007, VL_VENDORQUEST_GOBLIN_0008)
    endfunction
endlibrary
