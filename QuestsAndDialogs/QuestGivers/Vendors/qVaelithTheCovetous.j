/**
    qVaelithTheCovetous

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Vaelith the Covetous.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Vaelith the Covetous's vendor quests automatically.

**/
library qVaelithTheCovetous initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId

        call QuestsVendor_RegisterFetchQuest('n02Z', "Crystals in the Gloom", "daily", 10, "Crystals in the Gloom", "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Gather enchanting crystals for Xyraphos's secretive clientele.", 'I003', 5, 55, VL_VENDORQUEST_SATYR_TYPE, 3, VL_VENDORQUEST_SATYR_0003, VL_VENDORQUEST_SATYR_0004)
        set definitionId = QuestsVendor_RegisterFetchQuest('n02Z', "A Collector's Price", "normal", 12, "A Collector's Price", "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Acquire a complete set of water crystals for Vaelith's private collection.", 'I003', 8, 80, VL_VENDORQUEST_SATYR_TYPE, 13, VL_VENDORQUEST_SATYR_0013, VL_VENDORQUEST_SATYR_0014)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_SATYR_0015, 15, VL_VENDORQUEST_SATYR_0016, 16)
    endfunction
endlibrary
