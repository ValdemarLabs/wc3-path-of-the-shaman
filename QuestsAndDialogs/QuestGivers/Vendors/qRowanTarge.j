/**
    qRowanTarge

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Cedric Vale, Human shield merchant.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Cedric's vendor quest automatically.

**/
library qRowanTarge initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterKillQuest('n03A', "Gnolls at the Palisade", "daily", 5, "Gnolls at the Palisade", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Drive gnolls away from Cedric's shield-testing palisade.", 'ngno', 7, 35, VL_HUMAN_MALE_1_TYPE, 1005, VL_VENDORQUEST_HUMAN_0005, VL_VENDORQUEST_HUMAN_0006)
    endfunction
endlibrary
