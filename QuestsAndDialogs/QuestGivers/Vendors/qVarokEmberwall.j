/**
    qVarokEmberwall

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Brakka Bulwark, Orc shield merchant.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Brakka's vendor quest automatically.

**/
library qVarokEmberwall initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('o013', "Straps for the Line", "daily", 5, "Straps for the Line", "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Gather leather for the straps and grips on Brakka's shields.", 'I6A6', 6, 30, VL_VENDORQUEST_ORC_TYPE, 5, VL_VENDORQUEST_ORC_0005, VL_VENDORQUEST_ORC_0006)
    endfunction
endlibrary
