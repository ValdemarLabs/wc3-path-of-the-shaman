/**
    qGorthakJungleBanner

    Author: Valdemar
    Version: 1.1.0

    Description:
    Vendor quest content for Gorthak Jungle Banner, Orc quartermaster.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    Registers Gorthak Jungle Banner's vendor quests automatically.

**/
library qGorthakJungleBanner initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('o014', "Secure the Coastal Stores", "normal", 12, "Secure the Coastal Stores", "ReplaceableTextures\\CommandButtons\\BTNSatyr.blp", "Clear satyr raiders away from the quartermaster's coastal stores.", 'nsat', 10, 80, VL_GENERIC_ORC_MALE_8_TYPE, 1023, VL_VENDORQUEST_ORC_0023, VL_VENDORQUEST_ORC_0024)
        local integer escortDefinitionId
        call qANightToRemember_RegisterVendorType('o014', VL_GENERIC_ORC_MALE_8_TYPE, 1101)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_ORC_0033, 1033, VL_VENDORQUEST_ORC_0034, 1034)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('o014', "The Tidehook Inspection", 12, "The Tidehook Inspection", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Guard Gorthak Jungle Banner while he inspects Nargash Tidehook's coastal stores, then escort him back to command.", 'o00C', "Nargash Tidehook's smoke racks", 100, VL_GENERIC_ORC_MALE_8_TYPE, 1063, VL_VENDORQUEST_ORC_0063, VL_VENDORQUEST_ORC_0064)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_ORC_0065, 1065, VL_VENDORQUEST_ORC_0066, 1066)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_ORC_0067, 1067, "I will watch the rear. Quartermasters tend to attract enemies who can count.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0068, 1068)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0069, 1069)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0070, 1070)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0048_TEXT, 48)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0049_TEXT, 49)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0050_TEXT, 50)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0048_TEXT, 48)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0049_TEXT, 49)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0050_TEXT, 50)
        call QuestsVendor_SetEscortRoundTrip(escortDefinitionId, "Gorthak's command post", VL_VENDORQUEST_ORC_0071, 1071)
        call QuestsVendor_RegisterEscortAmbush(escortDefinitionId, QuestsVendor_ESCORT_LEG_OUTBOUND, 0.55, 'nsat', 5, 450.00, VL_VENDORQUEST_ORC_0072, 1072)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Horde", 30, false)
    endfunction
endlibrary
