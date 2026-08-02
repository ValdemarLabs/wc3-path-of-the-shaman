/**
    qKragmogSkullstake

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Gromm Pitmaster, Bonecrusher arena vendor.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Gromm's vendor quest automatically.

**/
library qKragmogSkullstake initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterSupplyQuest('n04H', "Pit Supplies", "daily", 11, "Pit Supplies", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Collect arena supplies from Borlug Clanstock and return them to Gromm.", 'n04N', "Borlug Clanstock", 'I010', 65, VL_VENDORQUEST_BONECRUSHER_TYPE, 7, VL_VENDORQUEST_BONECRUSHER_0007, VL_VENDORQUEST_BONECRUSHER_0008)
    endfunction
endlibrary
