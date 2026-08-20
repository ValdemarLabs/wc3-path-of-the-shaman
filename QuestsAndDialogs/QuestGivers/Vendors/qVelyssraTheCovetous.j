/**
    qVelyssraTheCovetous

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Velyssra the Covetous.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Velyssra the Covetous's vendor quests automatically.

**/
library qVelyssraTheCovetous initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId

        call QuestsVendor_RegisterFetchQuest('n02Z', "Crystals in the Gloom", "daily", 10, "Crystals in the Gloom", "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Gather enchanting crystals for Velyssra's secretive clientele.", 'I003', 5, 55, VL_GENERIC_SATYR_FEMALE_1_TYPE, 1003, VL_VENDORQUEST_SATYR_0003, VL_VENDORQUEST_SATYR_0004)
        set definitionId = QuestsVendor_RegisterFetchQuest('n02Z', "A Collector's Price", "normal", 12, "A Collector's Price", "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Acquire a complete set of water crystals for Velyssra's private collection.", 'I003', 8, 80, VL_GENERIC_SATYR_FEMALE_1_TYPE, 1013, VL_VENDORQUEST_SATYR_0013, VL_VENDORQUEST_SATYR_0014)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_SATYR_0015, 1015, VL_VENDORQUEST_SATYR_0016, 1016)
    endfunction
endlibrary
