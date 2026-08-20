/**
    qGorthakJungleBanner

    Author: Valdemar
    Version: 1.0.0

    Description:
    Vendor quest content for Vargan Warstock, Orc quartermaster.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Vargan's vendor quest automatically.

**/
library qGorthakJungleBanner initializer Init requires QuestsVendor, VoicelinesQuests, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('o014', "Secure the Coastal Stores", "normal", 12, "Secure the Coastal Stores", "ReplaceableTextures\\CommandButtons\\BTNSatyr.blp", "Clear satyr raiders away from the quartermaster's coastal stores.", 'nsat', 10, 80, VL_GENERIC_ORC_MALE_8_TYPE, 1023, VL_VENDORQUEST_ORC_0023, VL_VENDORQUEST_ORC_0024)
        call qANightToRemember_RegisterVendorType('o014', VL_GENERIC_ORC_MALE_8_TYPE, 1101)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_ORC_0033, 1033, VL_VENDORQUEST_ORC_0034, 1034)
    endfunction
endlibrary
