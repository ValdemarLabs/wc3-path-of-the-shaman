/**
    qMalyrRunehorn

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Ithryx, Satyr enchanting supplier.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Ithryx's vendor quest automatically.

**/
library qMalyrRunehorn initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterSupplyQuest('n031', "A Sealed Flask", "daily", 10, "A Sealed Flask", "ReplaceableTextures\\CommandButtons\\BTNPotionBlueSmall.blp", "Collect a sealed reagent flask from Selyth and return it to Ithryx.", 'n033', "Selyth Venomcup", 'I6BB', 55, VL_VENDORQUEST_SATYR_TYPE, 7, "Selyth holds a sealed flask for my runes. Bring it here without tasting it.", "The seal remains intact. Perhaps you possess restraint after all.")
    endfunction
endlibrary
