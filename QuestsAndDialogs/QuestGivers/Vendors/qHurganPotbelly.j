/**
    qHurganPotbelly

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Graasha Emberpot, Orc cook.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Graasha's vendor quest automatically.

**/
library qHurganPotbelly initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('o00E', "Meat for the Evening Pot", "daily", 4, "Meat for the Evening Pot", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "Bring fresh meat for Graasha's evening stew.", 'I620', 6, 25, VL_VENDORQUEST_ORC_TYPE, 19, VL_VENDORQUEST_ORC_0019, VL_VENDORQUEST_ORC_0020)
    endfunction
endlibrary
