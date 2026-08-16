/**
    qMaerithSilvercrest

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and normal vendor quest content for Maerith Silvercrest.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Maerith's vendor quest automatically.

**/
library qMaerithSilvercrest initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterSupplyQuest('h00S', "A Precise Inventory", "daily", 17, "A Precise Inventory", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Collect Maerith's sealed reagent inventory from Sylvaris Dewleaf and return it.", 'h00N', "Sylvaris Dewleaf", 'I010', 90, VL_VENDORQUEST_ELARINDOR_FEMALE_TYPE, 7, VL_VENDORQUEST_ELARINDOR_0007, VL_VENDORQUEST_ELARINDOR_0008)
        local integer normalDefinitionId

        call QuestsVendor_SetFactionReward(definitionId, "Elarindor", 25, false)
        set normalDefinitionId = QuestsVendor_RegisterKillQuest('h00S', "The Quartermaster's Oath", "normal", 18, "The Quartermaster's Oath", "ReplaceableTextures\\CommandButtons\\BTNGhost.blp", "Destroy ten mana wraiths stalking the paths between Elarindor's supply wards.", 'n002', 10, 110, VL_VENDORQUEST_ELARINDOR_FEMALE_TYPE, 13, VL_VENDORQUEST_ELARINDOR_0013, VL_VENDORQUEST_ELARINDOR_0014)
        call QuestsVendor_SetExtendedDialogue(normalDefinitionId, VL_VENDORQUEST_ELARINDOR_0015, 15, VL_VENDORQUEST_ELARINDOR_0016, 16)
        call QuestsVendor_SetFactionReward(normalDefinitionId, "Elarindor", 30, false)
    endfunction
endlibrary
