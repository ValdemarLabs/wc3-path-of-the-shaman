/**
    qBrakkunCoalhand

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Thrag Forgehand, Orc forge supplier.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Thrag's vendor quest automatically.

**/
library qBrakkunCoalhand initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('o00G', "Keep the Forges Hot", "daily", 5, "Keep the Forges Hot", "ReplaceableTextures\\CommandButtons\\BTNHumanLumberUpgrade1.blp", "Collect enough fuel to keep Thrag's communal forges burning.", 'I689', 8, 30, VL_VENDORQUEST_ORC_TYPE, 11, VL_VENDORQUEST_ORC_0011, VL_VENDORQUEST_ORC_0012)
    endfunction
endlibrary
