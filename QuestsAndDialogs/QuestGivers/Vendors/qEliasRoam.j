/**
    qEliasRoam

    Author: Valdemar
    Version: 1.0.0

    Description:
    Vendor quest content for Elias Roam, Human travelling merchant.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Elias's vendor quest automatically.

**/
library qEliasRoam initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('n03C', "The Toll Road", "normal", 11, "The Toll Road", "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "Clear dark trolls from a road Elias intends to reopen for trade.", 'ndqt', 9, 75, VL_VENDORQUEST_HUMAN_TYPE, 15, "Nine dark trolls have turned my best road into their private toll gate. Clear it.", "The road is open. Trade will follow, and trouble will follow trade.")
    endfunction
endlibrary
