/**
    qTorrenDeepsteel

    Author: Valdemar
    Version: 1.0.0

    Description:
    Normal vendor escort content for Torren Deepsteel.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    Registers Torren Deepsteel's vendor escort automatically.

**/
library qTorrenDeepsteel initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis
    private function Init takes nothing returns nothing
        local integer escortDefinitionId = QuestsVendor_RegisterEscortQuest('h00V', "Hammer to Hammer", 14, "Hammer to Hammer", "ReplaceableTextures\\CommandButtons\\BTNHumanMeleeUpTwo.blp", "Escort Torren Deepsteel and his forge tools from the cracked furnace to Durnik Forgefather's hall.", 'h00T', "Durnik Forgefather's forge hall", 110, VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, 1001, VL_VENDORQUEST_DWARF_0001, VL_VENDORQUEST_DWARF_0002)

        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_DWARF_0003, 1003, VL_VENDORQUEST_DWARF_0004, 1004)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_DWARF_0005, 1005, "I will keep the path clear. You keep the anvil from choosing its own path.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_DWARF_0006, 1006)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_DWARF_0007, 1007)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_DWARF_0008, 1008)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0060_TEXT, 60)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0061_TEXT, 61)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0062_TEXT, 62)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0060_TEXT, 60)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0061_TEXT, 61)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0062_TEXT, 62)
        call QuestsVendor_SetEscortTradeLocked(escortDefinitionId, true)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Morgrim Clan", 30, false)
    endfunction
endlibrary
