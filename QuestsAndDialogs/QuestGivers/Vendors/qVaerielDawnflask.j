/**
    qVaerielDawnflask

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Elarindor vendor quest content for Vaeriel Dawnflask.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    - Registers Vaeriel's vendor quest automatically.

**/
library qVaerielDawnflask initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        local integer definitionId = VendorQuests_RegisterFetchQuest('n04T', "Dawn's Restorative", "daily", 15, "Dawn's Restorative", "ReplaceableTextures\\CommandButtons\\BTNHerb.blp", "Bring fresh herbs for Vaeriel's restorative draughts.", 'I60Y', 8, 75, VL_VENDORQUEST_ELARINDOR_TYPE, 5, VL_VENDORQUEST_ELARINDOR_0005, VL_VENDORQUEST_ELARINDOR_0006)
        call VendorQuests_SetFactionReward(definitionId, "Elarindor", 15, false)
    endfunction
endlibrary
