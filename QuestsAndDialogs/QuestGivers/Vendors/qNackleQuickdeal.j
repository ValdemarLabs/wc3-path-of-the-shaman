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

        call QuestsVendor_RegisterFetchQuest('n03W', "Essence Speculation", "daily", 10, "Essence Speculation", "ReplaceableTextures\\CommandButtons\\BTNEssenceOfMagic.blp", "Acquire arcane essence before Zizzik's projected market shortage.", 'I6C6', 5, 60, VL_VENDORQUEST_GOBLIN_TYPE, 1, VL_VENDORQUEST_GOBLIN_0001, VL_VENDORQUEST_GOBLIN_0002)
        set definitionId = QuestsVendor_RegisterFetchQuest('n03W', "The Long Investment", "normal", 13, "The Long Investment", "ReplaceableTextures\\CommandButtons\\BTNEssenceOfMagic.blp", "Secure eight measures of arcane essence for Nackle's long-term speculation.", 'I6C6', 8, 90, VL_VENDORQUEST_GOBLIN_TYPE, 21, VL_VENDORQUEST_GOBLIN_0021, VL_VENDORQUEST_GOBLIN_0022)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_GOBLIN_0023, 23, VL_VENDORQUEST_GOBLIN_0024, 24)
    endfunction
endlibrary
