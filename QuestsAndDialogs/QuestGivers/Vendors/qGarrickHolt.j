/**
    qGarrickHolt

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Garrick Holt.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Garrick Holt's vendor quests automatically.

**/
library qGarrickHolt initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId

        call QuestsVendor_RegisterFetchQuest('n035', "Riverbane Iron", "daily", 5, "Riverbane Iron", "ReplaceableTextures\\CommandButtons\\BTNHumanMeleeUpOne.blp", "Bring Garrick enough iron ore to replace the day's damaged weapons.", 'I67E', 6, 30, VL_HUMAN_MALE_1_TYPE, 1001, VL_VENDORQUEST_HUMAN_0001, VL_VENDORQUEST_HUMAN_0002)
        set definitionId = QuestsVendor_RegisterFetchQuest('n035', "Riverbane's Reserve", "normal", 10, "Riverbane's Reserve", "ReplaceableTextures\\CommandButtons\\BTNHumanMeleeUpOne.blp", "Build Riverbane's emergency reserve with ten pieces of dense ore.", 'I67H', 10, 75, VL_HUMAN_MALE_1_TYPE, 1019, VL_VENDORQUEST_HUMAN_0019, VL_VENDORQUEST_HUMAN_0020)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_HUMAN_0021, 1021, VL_VENDORQUEST_HUMAN_0022, 1022)
    endfunction
endlibrary
