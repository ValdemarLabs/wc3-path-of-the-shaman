/**
    qMugrokIronclub

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and normal vendor quest content for Mugrok Ironclub.

    Credits:

    How to install:
    Import after QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, and
    VoicelinesZulkis.

    API:
    Registers Mugrok Ironclub's vendor quests automatically.

**/
library qMugrokIronclub initializer Init requires QuestsVendor, VoicelinesQuests, VoicelinesNazgrek, VoicelinesZulkis
    private function Init takes nothing returns nothing
        local integer definitionId
        local integer escortDefinitionId

        call QuestsVendor_RegisterKillQuest('n04E', "Break the Stalkers", "daily", 10, "Break the Stalkers", "ReplaceableTextures\\CommandButtons\\BTNSatyrHellcaller.blp", "Crush the satyr stalkers harassing Mugrak's weapon haulers.", 'nsth', 7, 55, VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 1001, VL_VENDORQUEST_BONECRUSHER_0001, VL_VENDORQUEST_BONECRUSHER_0002)
        set definitionId = QuestsVendor_RegisterKillQuest('n04E', "A Weapon's Reputation", "normal", 13, "A Weapon's Reputation", "ReplaceableTextures\\CommandButtons\\BTNSatyrHellcaller.blp", "Build the reputation of Mugrok's steel by crushing twelve satyr stalkers.", 'nsth', 12, 90, VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 1011, VL_VENDORQUEST_BONECRUSHER_0011, VL_VENDORQUEST_BONECRUSHER_0012)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_BONECRUSHER_0013, 1013, VL_VENDORQUEST_BONECRUSHER_0014, 1014)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('n04E', "Armor for the Arm", 12, "Armor for the Arm", "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp", "Protect Mugrok Ironclub while Grumbar Thickhide fits his new armor, then escort Mugrok back to his weapon cart.", 'n04F', "Grumbar Thickhide's armor stand", 95, VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 1026, VL_VENDORQUEST_BONECRUSHER_0026, VL_VENDORQUEST_BONECRUSHER_0027)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_BONECRUSHER_0028, 1028, VL_VENDORQUEST_BONECRUSHER_0029, 1029)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_BONECRUSHER_0030, 1030, "I will watch for arrows. You watch that the armor keeps pace.")
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_BONECRUSHER_0031, 1031)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_BONECRUSHER_0032, 1032)
        call QuestsVendor_RegisterEscortProgressVariant(escortDefinitionId, VL_VENDORQUEST_BONECRUSHER_0033, 1033)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0057_TEXT, 57)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0058_TEXT, 58)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0059_TEXT, 59)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0057_TEXT, 57)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0058_TEXT, 58)
        call QuestsVendor_RegisterEscortHeroProgressVariant(escortDefinitionId, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0059_TEXT, 59)
        call QuestsVendor_SetEscortRoundTrip(escortDefinitionId, "Mugrok's weapon cart", VL_VENDORQUEST_BONECRUSHER_0034, 1034)
        call QuestsVendor_RegisterEscortAmbush(escortDefinitionId, QuestsVendor_ESCORT_LEG_OUTBOUND, 0.50, 'nsth', 4, 425.00, VL_VENDORQUEST_BONECRUSHER_0035, 1035)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Bonecrusher Clan", 25, false)
    endfunction
endlibrary
