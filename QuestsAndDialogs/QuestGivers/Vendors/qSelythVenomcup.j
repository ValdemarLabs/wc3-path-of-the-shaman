/**
    qSelythVenomcup

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and one-time escort quest content for Selyth Venomcup,
    Satyr potion merchant.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Selyth's vendor quest automatically.

**/
library qSelythVenomcup initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer escortDefinitionId

        call QuestsVendor_RegisterFetchQuest('n033', "Bitter Leaves", "daily", 9, "Bitter Leaves", "ReplaceableTextures\\CommandButtons\\BTNHerb.blp", "Gather bitter herbs for Selyth's daily potion batch.", 'I60Y', 7, 45, VL_GENERIC_SATYR_FEMALE_1_TYPE, 1009, VL_VENDORQUEST_SATYR_0009, VL_VENDORQUEST_SATYR_0010)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('n033', "Bottles in the Gloom", 9, "Bottles in the Gloom", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Escort Selyth Venomcup and her volatile potion stock from the ruined path to Velyssra's warded enclave.", 'n02Z', "Velyssra's warded enclave", 70, VL_GENERIC_SATYR_FEMALE_1_TYPE, 1028, VL_VENDORQUEST_SATYR_0028, VL_VENDORQUEST_SATYR_0029)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_SATYR_0030, 1030, VL_VENDORQUEST_SATYR_0031, 1031)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_SATYR_0032, 1032, "If the crate starts hissing, I am putting more distance between us.")
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Satyr", 25, false)
    endfunction
endlibrary
