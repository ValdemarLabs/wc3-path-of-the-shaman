/**
    qNargashTidehook

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Nokta Wildhook, Orc fisher.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Nokta's vendor quest automatically.

**/
library qNargashTidehook initializer Init requires QuestsVendor, VoicelinesQuests, qANightToRemember
    private function Init takes nothing returns nothing
        call qANightToRemember_RegisterVendorType('o00C', VL_GENERIC_ORC_MALE_1_TYPE, 1101)
        call QuestsVendor_RegisterFetchQuest('o00C', "Jungle Catch", "daily", 7, "Jungle Catch", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Bring Nokta fish for smoking and trade along the jungle paths.", 'I6CU', 8, 35, VL_GENERIC_ORC_MALE_1_TYPE, 1021, VL_VENDORQUEST_ORC_0021, VL_VENDORQUEST_ORC_0022)
    endfunction
endlibrary
