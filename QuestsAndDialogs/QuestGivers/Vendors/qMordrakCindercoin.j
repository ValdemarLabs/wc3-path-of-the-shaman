/**
    qMordrakCindercoin

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Zagrim Cindercoin, Orc rare-goods dealer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Zagrim's vendor quest automatically.

**/
library qMordrakCindercoin initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('o00T', "No Troll Toll", "daily", 12, "No Troll Toll", "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "Drive dark trolls away from Zagrim's rare-goods route.", 'ndqt', 7, 65, VL_VENDORQUEST_ORC_TYPE, 15, VL_VENDORQUEST_ORC_0015, VL_VENDORQUEST_ORC_0016)
    endfunction
endlibrary
