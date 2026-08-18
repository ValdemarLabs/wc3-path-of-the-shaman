/**
    qXyrosBloodwager

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Vaelthorn, Satyr arena vendor.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Vaelthorn's vendor quest automatically.

**/
library qXyrosBloodwager initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterKillQuest('n02Y', "Cull the Stalkers", "daily", 9, "Cull the Stalkers", "ReplaceableTextures\\CommandButtons\\BTNSatyrHellcaller.blp", "Cull hostile satyr stalkers competing for Vaelthorn's arena recruits.", 'nsth', 6, 45, VL_SATYR_MALE_1_TYPE, 1001, VL_VENDORQUEST_SATYR_0001, VL_VENDORQUEST_SATYR_0002)
    endfunction
endlibrary
