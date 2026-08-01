/**
    qGarrickHolt

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Garrick Holt, Human weaponsmith.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Garrick's vendor quest automatically.

**/
library qGarrickHolt initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n035', "Riverbane Iron", "daily", 5, "Riverbane Iron", "ReplaceableTextures\\CommandButtons\\BTNHumanMeleeUpOne.blp", "Bring Garrick enough iron ore to replace the day's damaged weapons.", 'I67E', 6, 30, VL_VENDORQUEST_HUMAN_TYPE, 1, VL_VENDORQUEST_HUMAN_0001, VL_VENDORQUEST_HUMAN_0002)
    endfunction
endlibrary
