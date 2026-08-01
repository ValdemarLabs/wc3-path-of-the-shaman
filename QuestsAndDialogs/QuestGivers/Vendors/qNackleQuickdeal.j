/**
    qNackleQuickdeal

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Zizzik Quickdeal, Goblin curiosity dealer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Zizzik's vendor quest automatically.

**/
library qNackleQuickdeal initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n03W', "Essence Speculation", "daily", 10, "Essence Speculation", "ReplaceableTextures\\CommandButtons\\BTNEssenceOfMagic.blp", "Acquire arcane essence before Zizzik's projected market shortage.", 'I6C6', 5, 60, VL_VENDORQUEST_GOBLIN_TYPE, 1, VL_VENDORQUEST_GOBLIN_0001, VL_VENDORQUEST_GOBLIN_0002)
    endfunction
endlibrary
