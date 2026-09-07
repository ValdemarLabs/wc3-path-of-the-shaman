/**
    qXyrosBloodwager

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily vendor quest content for Xyros Bloodwager, Satyr arena vendor.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Xyros Bloodwager's vendor quest automatically.

**/
library qXyrosBloodwager initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterKillQuest('n02Y', "Cull the Stalkers", "daily", 9, "Cull the Stalkers", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Cull six gnolls stalking the road used by Xyros's arena recruits.", 'ngno', 6, 45, VL_GENERIC_SATYR_MALE_1_TYPE, 1001, VL_VENDORQUEST_SATYR_0001, VL_VENDORQUEST_SATYR_0002)
    endfunction
endlibrary
