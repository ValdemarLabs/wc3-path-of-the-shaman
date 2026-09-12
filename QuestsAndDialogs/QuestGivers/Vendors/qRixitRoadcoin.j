/**
    qRixitRoadcoin

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and normal vendor quest content for Rixit Roadcoin.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    Registers Rixit Roadcoin's vendor quests automatically.

**/
library qRixitRoadcoin initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterSupplyQuest('n03X', "A Favor Between Merchants", "daily", 7, "A Favor Between Merchants", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Buy Brakko's trade bundle from Tink Sprocketcrate and return it.", 'n04C', "Tink Sprocketcrate", 'I689', 40, VL_GENERIC_GOBLIN_MALE_2_TYPE, 1003, VL_VENDORQUEST_GOBLIN_0003, VL_VENDORQUEST_GOBLIN_0004)
        local integer normalDefinitionId
        local integer escortDefinitionId

        call QuestsVendor_SetSupplyRequiresPurchase(definitionId, true)
        set normalDefinitionId = QuestsVendor_RegisterKillQuest('n03X', "A Cart Worth Guarding", "normal", 10, "A Cart Worth Guarding", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Remove the shadowdancers preying on Rixit's most profitable cart route.", 'nsty', 12, 75, VL_GENERIC_GOBLIN_MALE_2_TYPE, 1017, VL_VENDORQUEST_GOBLIN_0017, VL_VENDORQUEST_GOBLIN_0018)
        call QuestsVendor_SetExtendedDialogue(normalDefinitionId, VL_VENDORQUEST_GOBLIN_0019, 1019, VL_VENDORQUEST_GOBLIN_0020, 1020)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('n03X', "Terms and Conditions", 11, "Terms and Conditions", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Protect Rixit Roadcoin while he negotiates with Snikka Sparkdust, then escort him back to his cart route.", 'n047', "Snikka Sparkdust's reagent counter", 90, VL_GENERIC_GOBLIN_MALE_2_TYPE, 1044, VL_VENDORQUEST_GOBLIN_0044, VL_VENDORQUEST_GOBLIN_0045)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0046, 1046, VL_VENDORQUEST_GOBLIN_0047, 1047)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0048, 1048, "I can look threatening. Whether that improves the contract is another matter.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0049, 1049)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0050, 1050)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0051, 1051)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0054_TEXT, 54)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0055_TEXT, 55)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0056_TEXT, 56)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0054_TEXT, 54)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0055_TEXT, 55)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0056_TEXT, 56)
        call QuestsVendor_SetEscortRoundTrip(escortDefinitionId, "Rixit's cart route", VL_VENDORQUEST_GOBLIN_0052, 1052)
        call QuestsVendor_RegisterEscortAmbush(escortDefinitionId, QuestsVendor_ESCORT_LEG_RETURN, 0.40, 'nsty', 4, 400.00, VL_VENDORQUEST_GOBLIN_0053, 1053)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Goblins", 25, false)
    endfunction
endlibrary
