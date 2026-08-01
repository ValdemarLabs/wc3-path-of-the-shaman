/**
    qRukhaTrailhoof

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Rukha Trailhoof, Orc travelling merchant.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Rukha's vendor quest automatically.

**/
library qRukhaTrailhoof initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterSupplyQuest('o00B', "Quartermaster's Parcel", "daily", 6, "Quartermaster's Parcel", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Pick up Rukha's supply parcel from Vargan Warstock and return.", 'o014', "Vargan Warstock", 'I010', 35, VL_VENDORQUEST_ORC_TYPE, 17, "Vargan has a parcel for my next run. Pick it up before he puts it back on the shelf.", "Still sealed. Good work keeping curious hands out of it.")
    endfunction
endlibrary
