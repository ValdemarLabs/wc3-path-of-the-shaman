/**
    qKragmogSkullstake

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Gromm Pitmaster, Bonecrusher arena vendor.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Gromm's vendor quest automatically.

**/
library qKragmogSkullstake initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterSupplyQuest('n04H', "Pit Supplies", "daily", 11, "Pit Supplies", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Collect arena supplies from Borlug Clanstock and return them to Gromm.", 'n04N', "Borlug Clanstock", 'I010', 65, VL_VENDORQUEST_BONECRUSHER_TYPE, 7, "Borlug has pit supplies. Bring crate here. Do not eat crate.", "Crate full. Fighters eat contents. Maybe crate later.")
    endfunction
endlibrary
