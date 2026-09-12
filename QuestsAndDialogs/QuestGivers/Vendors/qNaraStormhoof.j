/**
    qNaraStormhoof

    Author: Valdemar
    Version: 1.2.0

    Description:
    Daily and one-time escort quest content for Nara Stormhoof.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    - Registers Nara Stormhoof's vendor quest automatically.

**/
library qNaraStormhoof initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('o01E', "Shadow over the Long Road", "daily", 9, "Shadow over the Long Road", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Defeat eight shadowdancers stalking Nara's travelling route.", 'nsty', 8, 50, VL_GENERIC_TAUREN_MALE_1_TYPE, 1007, VL_VENDORQUEST_TAUREN_0007, VL_VENDORQUEST_TAUREN_0008)
        local integer escortDefinitionId

        call qANightToRemember_RegisterVendorType('o01E', VL_GENERIC_TAUREN_MALE_1_TYPE, 1101)
        call QuestsVendor_SetFactionReward(definitionId, "Horde", 20, false)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('o01E', "A Road Beneath Open Sky", 9, "A Road Beneath Open Sky", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Escort Nara Stormhoof from the shadowed roadside to Koro Windpack's guarded caravan post.", 'o01D', "Koro Windpack's caravan post", 80, VL_GENERIC_TAUREN_MALE_1_TYPE, 1015, VL_VENDORQUEST_TAUREN_0015, VL_VENDORQUEST_TAUREN_0016)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_TAUREN_0017, 1017, VL_VENDORQUEST_TAUREN_0018, 1018)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_TAUREN_0019, 1019, "Stay close to the caravan. I will watch the trail behind us.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_TAUREN_0020, 1020)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_TAUREN_0021, 1021)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_TAUREN_0022, 1022)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0033_TEXT, 33)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0034_TEXT, 34)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0035_TEXT, 35)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0033_TEXT, 33)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0034_TEXT, 34)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0035_TEXT, 35)
        call QuestsVendor_SetEscortTradeLocked(escortDefinitionId, true)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Horde", 35, false)
    endfunction
endlibrary
