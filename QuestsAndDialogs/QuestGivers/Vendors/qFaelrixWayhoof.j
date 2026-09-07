/**
    qFaelrixWayhoof

    Author: Valdemar
    Version: 1.1.0

    Description:
    Vendor quest content for Faelrix Wayhoof, Satyr travelling merchant.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Faelrix Wayhoof's vendor quest automatically.

**/
library qFaelrixWayhoof initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('n038', "Silence on the Old Path", "normal", 13, "Silence on the Old Path", "ReplaceableTextures\\CommandButtons\\BTNSnapDragon.blp", "Kill eight ironjaw basilisks hunting along Faelrix's old trade path.", 'n63R', 8, 85, VL_GENERIC_SATYR_MALE_1_TYPE, 1011, VL_VENDORQUEST_SATYR_0011, VL_VENDORQUEST_SATYR_0012)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_SATYR_0017, 1017, VL_VENDORQUEST_SATYR_0018, 1018)
    endfunction
endlibrary
