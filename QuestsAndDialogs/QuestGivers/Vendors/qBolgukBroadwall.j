/**
    qBolgukBroadwall

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Bolguk Broadwall, Bonecrusher shield vendor.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Bolguk's vendor quest automatically.

**/
library qBolgukBroadwall initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n04G', "Heavy Metal", "daily", 11, "Heavy Metal", "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Bring dense ore for Bolguk's oversized shield rims.", 'I67H', 5, 60, VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 1005, VL_VENDORQUEST_BONECRUSHER_0005, VL_VENDORQUEST_BONECRUSHER_0006)
    endfunction
endlibrary
