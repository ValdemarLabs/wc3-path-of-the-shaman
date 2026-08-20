/**
    qNibbsHotpan

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Bimble Sizzlepot, Goblin cook.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Bimble's vendor quest automatically.

**/
library qNibbsHotpan initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n043', "Emergency Skewers", "daily", 7, "Emergency Skewers", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "Bring meat for Bimble's unexpectedly successful skewer stall.", 'I620', 7, 40, VL_GENERIC_GOBLIN_MALE_3_TYPE, 1011, VL_VENDORQUEST_GOBLIN_0011, VL_VENDORQUEST_GOBLIN_0012)
    endfunction
endlibrary
