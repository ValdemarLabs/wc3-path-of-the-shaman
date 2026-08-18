/**
    qVaerielDawnflask

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily Elarindor vendor quest content for Vaeriel Dawnflask.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Vaeriel's vendor quest automatically.

**/
library qVaerielDawnflask initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterFetchQuest('h00R', "Dawn's Restorative", "daily", 15, "Dawn's Restorative", "ReplaceableTextures\\CommandButtons\\BTNHerb.blp", "Bring fresh herbs for Vaeriel's restorative draughts.", 'I60Y', 8, 75, VL_ELARINDOR_FEMALE_1_TYPE, 1005, VL_VENDORQUEST_ELARINDOR_0005, VL_VENDORQUEST_ELARINDOR_0006)
        call QuestsVendor_SetFactionReward(definitionId, "Elarindor", 15, false)
    endfunction
endlibrary
