/**
    qRixitRoadcoin

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Rixit Roadcoin.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Rixit Roadcoin's vendor quests automatically.

**/
library qRixitRoadcoin initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterSupplyQuest('n03X', "A Favor Between Merchants", "daily", 7, "A Favor Between Merchants", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Buy Brakko's trade bundle from Tink Sprocketcrate and return it.", 'n04C', "Tink Sprocketcrate", 'I689', 40, VL_GENERIC_GOBLIN_MALE_2_TYPE, 1003, VL_VENDORQUEST_GOBLIN_0003, VL_VENDORQUEST_GOBLIN_0004)
        local integer normalDefinitionId

        call QuestsVendor_SetSupplyRequiresPurchase(definitionId, true)
        set normalDefinitionId = QuestsVendor_RegisterKillQuest('n03X', "A Cart Worth Guarding", "normal", 10, "A Cart Worth Guarding", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Remove the shadowdancers preying on Rixit's most profitable cart route.", 'nsty', 12, 75, VL_GENERIC_GOBLIN_MALE_2_TYPE, 1017, VL_VENDORQUEST_GOBLIN_0017, VL_VENDORQUEST_GOBLIN_0018)
        call QuestsVendor_SetExtendedDialogue(normalDefinitionId, VL_VENDORQUEST_GOBLIN_0019, 1019, VL_VENDORQUEST_GOBLIN_0020, 1020)
    endfunction
endlibrary
