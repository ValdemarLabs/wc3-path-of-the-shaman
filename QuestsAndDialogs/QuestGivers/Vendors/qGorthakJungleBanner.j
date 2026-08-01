/**
    qGorthakJungleBanner

    Author: Valdemar
    Version: 1.0.0

    Description:
    Vendor quest content for Vargan Warstock, Orc quartermaster.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Vargan's vendor quest automatically.

**/
library qGorthakJungleBanner initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('o014', "Secure the Coastal Stores", "normal", 12, "Secure the Coastal Stores", "ReplaceableTextures\\CommandButtons\\BTNSatyr.blp", "Clear satyr raiders away from the quartermaster's coastal stores.", 'nsat', 10, 80, VL_VENDORQUEST_ORC_TYPE, 23, "Satyr raiders found the coastal stores. Kill ten before they learn what we keep there.", "The stores are safe and the clan's supplies stay in clan hands.")
    endfunction
endlibrary
