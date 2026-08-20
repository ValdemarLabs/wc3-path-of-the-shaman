/**
    qIthryssaRunehorn

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Ithryssa Runehorn, Satyr enchanting supplier.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Ithryssa's vendor quest automatically.

**/
library qIthryssaRunehorn initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterSupplyQuest('n031', "A Sealed Flask", "daily", 10, "A Sealed Flask", "ReplaceableTextures\\CommandButtons\\BTNPotionBlueSmall.blp", "Collect a sealed reagent flask from Selyth and return it to Ithryssa.", 'n033', "Selyth Venomcup", 'I6BB', 55, VL_GENERIC_SATYR_FEMALE_1_TYPE, 1007, VL_VENDORQUEST_SATYR_0007, VL_VENDORQUEST_SATYR_0008)
    endfunction
endlibrary
