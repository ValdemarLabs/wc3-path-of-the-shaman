/**
    qMordrakCindercoin

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Zagrim Cindercoin, Orc rare-goods dealer.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Zagrim's vendor quest automatically.

**/
library qMordrakCindercoin initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterKillQuest('o00T', "No Troll Toll", "daily", 12, "No Troll Toll", "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "Drive dark trolls away from Zagrim's rare-goods route.", 'ndqt', 7, 65, VL_GENERIC_ORC_MALE_1_TYPE, 1015, VL_VENDORQUEST_ORC_0015, VL_VENDORQUEST_ORC_0016)
    endfunction
endlibrary
