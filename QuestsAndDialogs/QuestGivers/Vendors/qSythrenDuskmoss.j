/**
    qSythrenDuskmoss

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Maltheris, Satyr reagent merchant.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Maltheris's vendor quest automatically.

**/
library qSythrenDuskmoss initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n030', "Essence Without Questions", "daily", 11, "Essence Without Questions", "ReplaceableTextures\\CommandButtons\\BTNEssenceOfMagic.blp", "Bring Maltheris arcane essence without asking who commissioned it.", 'I6C6', 4, 60, VL_SATYR_MALE_1_TYPE, 1005, VL_VENDORQUEST_SATYR_0005, VL_VENDORQUEST_SATYR_0006)
    endfunction
endlibrary
