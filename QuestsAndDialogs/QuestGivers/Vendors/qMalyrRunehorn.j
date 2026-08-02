/**
    qMalyrRunehorn

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Ithryx, Satyr enchanting supplier.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Ithryx's vendor quest automatically.

**/
library qMalyrRunehorn initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterSupplyQuest('n031', "A Sealed Flask", "daily", 10, "A Sealed Flask", "ReplaceableTextures\\CommandButtons\\BTNPotionBlueSmall.blp", "Collect a sealed reagent flask from Selyth and return it to Ithryx.", 'n033', "Selyth Venomcup", 'I6BB', 55, VL_VENDORQUEST_SATYR_TYPE, 7, VL_VENDORQUEST_SATYR_0007, VL_VENDORQUEST_SATYR_0008)
    endfunction
endlibrary
