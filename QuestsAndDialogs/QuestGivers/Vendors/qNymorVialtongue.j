/**
    qNymorVialtongue

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Selyth Venomcup, Satyr potion merchant.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Selyth's vendor quest automatically.

**/
library qNymorVialtongue initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n033', "Bitter Leaves", "daily", 9, "Bitter Leaves", "ReplaceableTextures\\CommandButtons\\BTNHerb.blp", "Gather bitter herbs for Selyth's daily potion batch.", 'I60Y', 7, 45, VL_VENDORQUEST_SATYR_TYPE, 9, VL_VENDORQUEST_SATYR_0009, VL_VENDORQUEST_SATYR_0010)
    endfunction
endlibrary
