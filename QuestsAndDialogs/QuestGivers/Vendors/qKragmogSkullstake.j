/**
    qKragmogSkullstake

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Kragmog Skullstake, Bonecrusher arena vendor.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Kragmog's vendor quest automatically.

**/
library qKragmogSkullstake initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterSupplyQuest('n04H', "Pit Supplies", "daily", 11, "Pit Supplies", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Collect Kragmog's arena supplies from Grothak Heavytrade and return them.", 'n04N', "Grothak Heavytrade", 'I010', 65, VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 1007, VL_VENDORQUEST_BONECRUSHER_0007, VL_VENDORQUEST_BONECRUSHER_0008)
    endfunction
endlibrary
