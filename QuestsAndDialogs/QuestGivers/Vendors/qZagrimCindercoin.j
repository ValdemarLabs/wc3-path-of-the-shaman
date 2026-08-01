/**
    qZagrimCindercoin

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
library qZagrimCindercoin initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('o00T', "No Troll Toll", "daily", 12, "No Troll Toll", "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "Drive dark trolls away from Zagrim's rare-goods route.", 'ndqt', 7, 65, VL_VENDORQUEST_ORC_TYPE, 15, "Dark trolls are charging a toll on my best route. Answer with seven broken toll collectors.", "The road belongs to paying customers again. Here is your cut.")
    endfunction
endlibrary
