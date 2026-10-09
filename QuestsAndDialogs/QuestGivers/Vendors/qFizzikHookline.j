/**
    qFizzikHookline

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Fizzik Hookline, Goblin fisher.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Fizzik's vendor quest automatically.

**/
library qFizzikHookline initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n041', "Catch of the Minute", "daily", 6, "Catch of the Minute", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Bring Fizzik enough fish to satisfy a very impatient buyer.", 'I6CU', 9, 35, VL_GENERIC_GOBLIN_MALE_3_TYPE, 1007, VL_VENDORQUEST_GOBLIN_0007, VL_VENDORQUEST_GOBLIN_0008)
    endfunction
endlibrary
