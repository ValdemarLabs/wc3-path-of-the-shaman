/**
    qRukgarLongroad

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and normal vendor quest content for Rukgar Longroad.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    Registers Rukgar Longroad's vendor quests automatically.

**/
library qRukgarLongroad initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterSupplyQuest('o00B', "Quartermaster's Parcel", "daily", 6, "Quartermaster's Parcel", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Pick up Rukha's supply parcel from Vargan Warstock and return.", 'o014', "Vargan Warstock", 'I010', 35, VL_GENERIC_ORC_MALE_3_TYPE, 1017, VL_VENDORQUEST_ORC_0017, VL_VENDORQUEST_ORC_0018)
        local integer normalDefinitionId
        local integer escortDefinitionId

        call qANightToRemember_RegisterVendorType('o00B', VL_GENERIC_ORC_MALE_3_TYPE, 1101)
        call QuestsVendor_SetSupplyRequiresPurchase(definitionId, false)
        set normalDefinitionId = QuestsVendor_RegisterKillQuest('o00B', "The Road Takes Its Due", "normal", 8, "The Road Takes Its Due", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Clear the gnolls that have repeatedly raided Rukgar's longest caravan route.", 'ngno', 10, 60, VL_GENERIC_ORC_MALE_3_TYPE, 1029, VL_VENDORQUEST_ORC_0029, VL_VENDORQUEST_ORC_0030)
        call QuestsVendor_SetExtendedDialogue(normalDefinitionId, VL_VENDORQUEST_ORC_0031, 1031, VL_VENDORQUEST_ORC_0032, 1032)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('o00B', "The Provisioner's Circuit", 8, "The Provisioner's Circuit", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Protect Rukgar Longroad while he visits Hurgan Potbelly to settle caravan provisions, then escort him back to his route.", 'o00E', "Hurgan Potbelly's cooking fire", 80, VL_GENERIC_ORC_MALE_3_TYPE, 1053, VL_VENDORQUEST_ORC_0053, VL_VENDORQUEST_ORC_0054)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_ORC_0055, 1055, VL_VENDORQUEST_ORC_0056, 1056)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_ORC_0057, 1057, "Two roads for one payment. At least the provisions should make the return smell better.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0058, 1058)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0059, 1059)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0060, 1060)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0045_TEXT, 45)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0046_TEXT, 46)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0047_TEXT, 47)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0045_TEXT, 45)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0046_TEXT, 46)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0047_TEXT, 47)
        call QuestsVendor_SetEscortRoundTrip(escortDefinitionId, "Rukgar's caravan route", VL_VENDORQUEST_ORC_0061, 1061)
        call QuestsVendor_RegisterEscortAmbush(escortDefinitionId, QuestsVendor_ESCORT_LEG_OUTBOUND, 0.45, 'ngno', 5, 425.00, VL_VENDORQUEST_ORC_0062, 1062)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Horde", 25, false)
    endfunction
endlibrary
