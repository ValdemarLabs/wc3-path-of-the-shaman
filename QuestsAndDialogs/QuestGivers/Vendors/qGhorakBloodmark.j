/**
    qGhorakBloodmark

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Kargul Bloodring, Orc arena vendor.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Kargul's vendor quest automatically.

**/
library qGhorakBloodmark initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterKillQuest('o00A', "A Worthy Warm-Up", "daily", 4, "A Worthy Warm-Up", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Prove your readiness for the arena by hunting nearby gnolls.", 'ngno', 8, 35, VL_ORC_MALE_2_TYPE, 1007, VL_VENDORQUEST_ORC_0007, VL_VENDORQUEST_ORC_0008)
    endfunction
endlibrary
