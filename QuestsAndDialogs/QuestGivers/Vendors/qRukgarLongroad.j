/**
    qRukgarLongroad

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
library qRukgarLongroad initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        local integer definitionId = VendorQuests_RegisterSupplyQuest('o00B', "Quartermaster's Parcel", "daily", 6, "Quartermaster's Parcel", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Pick up Rukha's supply parcel from Vargan Warstock and return.", 'o014', "Vargan Warstock", 'I010', 35, VL_VENDORQUEST_ORC_TYPE, 17, VL_VENDORQUEST_ORC_0017, VL_VENDORQUEST_ORC_0018)
        call VendorQuests_SetSupplyRequiresPurchase(definitionId, false)
    endfunction
endlibrary
