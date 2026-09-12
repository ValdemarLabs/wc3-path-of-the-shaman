/**
    qKargunAshblade

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and normal vendor quest content for Kargun Ashblade.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    Registers Kargun Ashblade's vendor quests automatically.

**/
library qKargunAshblade initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId
        local integer escortDefinitionId

        call qANightToRemember_RegisterVendorType('o011', VL_GENERIC_ORC_MALE_9_TYPE, 1101)
        call QuestsVendor_RegisterFetchQuest('o011', "Ore for the Edge", "daily", 4, "Ore for the Edge", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Bring Ghorak iron ore suitable for sharpening the day's weapon stock.", 'I67E', 5, 25, VL_GENERIC_ORC_MALE_9_TYPE, 1001, VL_VENDORQUEST_ORC_0001, VL_VENDORQUEST_ORC_0002)
        set definitionId = QuestsVendor_RegisterKillQuest('o011', "Steel Proven in Blood", "normal", 10, "Steel Proven in Blood", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Temper Kargun's newest steel by defeating dark trolls with it.", 'ndqt', 12, 75, VL_GENERIC_ORC_MALE_9_TYPE, 1025, VL_VENDORQUEST_ORC_0025, VL_VENDORQUEST_ORC_0026)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_ORC_0027, 1027, VL_VENDORQUEST_ORC_0028, 1028)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('o011', "Steel for the Ring", 11, "Steel for the Ring", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Escort Kargun Ashblade and a commissioned arena blade to Ghorak Bloodmark's quartermaster post.", 'o00A', "Ghorak Bloodmark's arena post", 90, VL_GENERIC_ORC_MALE_9_TYPE, 1044, VL_VENDORQUEST_ORC_0044, VL_VENDORQUEST_ORC_0045)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_ORC_0046, 1046, VL_VENDORQUEST_ORC_0047, 1047)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_ORC_0048, 1048, "Then keep the wrapped edge behind our shields until Ghorak signs for it.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0049, 1049)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0050, 1050)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_ORC_0051, 1051)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0042_TEXT, 42)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0043_TEXT, 43)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0044_TEXT, 44)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0042_TEXT, 42)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0043_TEXT, 43)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0044_TEXT, 44)
        call QuestsVendor_RegisterEscortAmbush(escortDefinitionId, QuestsVendor_ESCORT_LEG_OUTBOUND, 0.55, 'ndqt', 4, 400.00, VL_VENDORQUEST_ORC_0052, 1052)
        call QuestsVendor_SetEscortTradeLocked(escortDefinitionId, true)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Horde", 30, false)
    endfunction
endlibrary
