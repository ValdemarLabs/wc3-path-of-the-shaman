/**
    qSilasReed

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Silas Reed.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Silas Reed's vendor quests automatically.

**/
library qSilasReed initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId

        call QuestsVendor_RegisterFetchQuest('n03D', "Stormhaven Supper", "daily", 6, "Stormhaven Supper", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Bring Maren a fresh catch for Stormhaven's evening tables.", 'I6CV', 8, 35, VL_HUMAN_MALE_1_TYPE, 1007, VL_VENDORQUEST_HUMAN_0007, VL_VENDORQUEST_HUMAN_0008)
        set definitionId = QuestsVendor_RegisterFetchQuest('n03D', "The Deepwater Table", "normal", 9, "The Deepwater Table", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Land twelve Stormhaven fish worthy of the harbor's deepwater feast.", 'I6CV', 12, 65, VL_HUMAN_MALE_1_TYPE, 1023, VL_VENDORQUEST_HUMAN_0023, VL_VENDORQUEST_HUMAN_0024)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_HUMAN_0025, 1025, VL_VENDORQUEST_HUMAN_0026, 1026)
    endfunction
endlibrary
