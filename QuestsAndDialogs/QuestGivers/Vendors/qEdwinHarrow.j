/**
    qEdwinHarrow

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Mira Voss, Human potion merchant.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Mira's vendor quest automatically.

**/
library qEdwinHarrow initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n03T', "Morning Herbs", "daily", 6, "Morning Herbs", "ReplaceableTextures\\CommandButtons\\BTNHerb.blp", "Gather herbs for Mira's daily restorative potion batch.", 'I60Y', 8, 35, VL_VENDORQUEST_HUMAN_TYPE, 17, VL_VENDORQUEST_HUMAN_0017, VL_VENDORQUEST_HUMAN_0018)
    endfunction
endlibrary
