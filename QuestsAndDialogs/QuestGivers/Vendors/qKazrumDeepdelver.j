/**
    qKazrumDeepdelver

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Drogun Deepdelver, Orc miner.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Drogun's vendor quest automatically.

**/
library qKazrumDeepdelver initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('o00D', "The Deep Vein", "daily", 10, "The Deep Vein", "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Bring Drogun a shipment of dense ore from the deeper seams.", 'I67H', 4, 55, VL_VENDORQUEST_ORC_TYPE, 9, VL_VENDORQUEST_ORC_0009, VL_VENDORQUEST_ORC_0010)
    endfunction
endlibrary
