/**
    qMaerithSilvercrest

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Elarindor vendor quest content for Maerith Silvercrest.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    - Registers Maerith's vendor quest automatically.

**/
library qMaerithSilvercrest initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        local integer definitionId = VendorQuests_RegisterSupplyQuest('n04V', "A Precise Inventory", "daily", 17, "A Precise Inventory", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Collect Maerith's sealed reagent inventory from Sylvaris Dewleaf and return it.", 'n04S', "Sylvaris Dewleaf", 'I010', 90, VL_VENDORQUEST_ELARINDOR_TYPE, 7, VL_VENDORQUEST_ELARINDOR_0007, VL_VENDORQUEST_ELARINDOR_0008)
        call VendorQuests_SetFactionReward(definitionId, "Elarindor", 25, false)
    endfunction
endlibrary
