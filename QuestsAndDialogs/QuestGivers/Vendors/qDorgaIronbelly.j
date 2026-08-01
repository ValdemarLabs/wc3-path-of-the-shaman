/**
    qDorgaIronbelly

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Dorga Ironbelly, Bonecrusher armorer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Dorga's vendor quest automatically.

**/
library qDorgaIronbelly initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n04F', "Thick Hide, Thick Armor", "daily", 9, "Thick Hide, Thick Armor", "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeTwo.blp", "Bring Dorga thick leather for reinforcing Bonecrusher armor.", 'I6A7', 6, 50, VL_VENDORQUEST_BONECRUSHER_TYPE, 3, "Dorga needs six thick hides. Thin hide tears when ogre sneezes.", "Thick enough. Dorga makes armor that survives two sneezes.")
    endfunction
endlibrary
