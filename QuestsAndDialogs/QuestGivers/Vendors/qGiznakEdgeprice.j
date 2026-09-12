/**
    qGiznakEdgeprice

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and normal vendor quest content for Giznak Edgeprice.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    Registers Giznak Edgeprice's vendor quests automatically.

**/
library qGiznakEdgeprice initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis
    private function Init takes nothing returns nothing
        local integer escortDefinitionId

        call QuestsVendor_RegisterKillQuest('n03Y', "Field-Tested Steel", "daily", 5, "Field-Tested Steel", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Field-test Giznak's weapon advice against nearby gnolls.", 'ngno', 9, 35, VL_GENERIC_GOBLIN_MALE_1_TYPE, 1005, VL_VENDORQUEST_GOBLIN_0005, VL_VENDORQUEST_GOBLIN_0006)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('n03Y', "An Edge Worth Selling", 7, "An Edge Worth Selling", "ReplaceableTextures\\CommandButtons\\BTNGoblinLandMine.blp", "Escort Giznak Edgeprice and his weapon samples to Kargun Ashblade's forge for inspection.", 'o011', "Kargun Ashblade's forge", 70, VL_GENERIC_GOBLIN_MALE_1_TYPE, 1036, VL_VENDORQUEST_GOBLIN_0036, VL_VENDORQUEST_GOBLIN_0037)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0038, 1038, VL_VENDORQUEST_GOBLIN_0039, 1039)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0040, 1040, "I cannot promise expensive, but I can promise dangerous.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0041, 1041)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0042, 1042)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_GOBLIN_0043, 1043)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0051_TEXT, 51)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0052_TEXT, 52)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0053_TEXT, 53)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0051_TEXT, 51)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0052_TEXT, 52)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0053_TEXT, 53)
        call QuestsVendor_SetEscortTradeLocked(escortDefinitionId, true)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Goblins", 20, false)
    endfunction
endlibrary
