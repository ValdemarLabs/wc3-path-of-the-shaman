/**
    qNoktaWildhook

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Nokta Wildhook, Orc fisher.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Nokta's vendor quest automatically.

**/
library qNoktaWildhook initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('o00C', "Jungle Catch", "daily", 7, "Jungle Catch", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Bring Nokta fish for smoking and trade along the jungle paths.", 'I6CU', 8, 35, VL_VENDORQUEST_ORC_TYPE, 21, "The smoke racks are empty. Bring eight good fish before the jungle heat spoils them.", "Fine catch. These will travel farther than most merchants do.")
    endfunction
endlibrary
