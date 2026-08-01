/**
    qBimbleSizzlepot

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Bimble Sizzlepot, Goblin cook.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Bimble's vendor quest automatically.

**/
library qBimbleSizzlepot initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n043', "Emergency Skewers", "daily", 7, "Emergency Skewers", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "Bring meat for Bimble's unexpectedly successful skewer stall.", 'I620', 7, 40, VL_VENDORQUEST_GOBLIN_TYPE, 11, "The skewers sold out! Bring seven cuts of meat before customers discover patience.", "Back in business. Nothing improves appetite like limited supply.")
    endfunction
endlibrary
