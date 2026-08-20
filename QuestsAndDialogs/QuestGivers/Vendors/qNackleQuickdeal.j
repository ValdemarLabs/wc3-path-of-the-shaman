/**
    qNackleQuickdeal

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Nackle Quickdeal.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Nackle Quickdeal's vendor quests automatically.

**/
library qNackleQuickdeal initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId

        call QuestsVendor_RegisterFetchQuest('n03W', "Essence Speculation", "daily", 10, "Essence Speculation", "ReplaceableTextures\\CommandButtons\\BTNEssenceOfMagic.blp", "Acquire arcane essence before Zizzik's projected market shortage.", 'I6C6', 5, 60, VL_GENERIC_GOBLIN_MALE_1_TYPE, 1001, VL_VENDORQUEST_GOBLIN_0001, VL_VENDORQUEST_GOBLIN_0002)
        set definitionId = QuestsVendor_RegisterFetchQuest('n03W', "The Long Investment", "normal", 13, "The Long Investment", "ReplaceableTextures\\CommandButtons\\BTNEssenceOfMagic.blp", "Secure eight measures of arcane essence for Nackle's long-term speculation.", 'I6C6', 8, 90, VL_GENERIC_GOBLIN_MALE_1_TYPE, 1021, VL_VENDORQUEST_GOBLIN_0021, VL_VENDORQUEST_GOBLIN_0022)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_GOBLIN_0023, 1023, VL_VENDORQUEST_GOBLIN_0024, 1024)
    endfunction
endlibrary
