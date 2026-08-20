/**
    qRukgarLongroad

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Rukgar Longroad.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Rukgar Longroad's vendor quests automatically.

**/
library qRukgarLongroad initializer Init requires QuestsVendor, VoicelinesQuests, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterSupplyQuest('o00B', "Quartermaster's Parcel", "daily", 6, "Quartermaster's Parcel", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Pick up Rukha's supply parcel from Vargan Warstock and return.", 'o014', "Vargan Warstock", 'I010', 35, VL_GENERIC_ORC_MALE_3_TYPE, 1017, VL_VENDORQUEST_ORC_0017, VL_VENDORQUEST_ORC_0018)
        local integer normalDefinitionId

        call qANightToRemember_RegisterVendorType('o00B', VL_GENERIC_ORC_MALE_3_TYPE, 1101)
        call QuestsVendor_SetSupplyRequiresPurchase(definitionId, false)
        set normalDefinitionId = QuestsVendor_RegisterKillQuest('o00B', "The Road Takes Its Due", "normal", 8, "The Road Takes Its Due", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Clear the gnolls that have repeatedly raided Rukgar's longest caravan route.", 'ngno', 10, 60, VL_GENERIC_ORC_MALE_3_TYPE, 1029, VL_VENDORQUEST_ORC_0029, VL_VENDORQUEST_ORC_0030)
        call QuestsVendor_SetExtendedDialogue(normalDefinitionId, VL_VENDORQUEST_ORC_0031, 1031, VL_VENDORQUEST_ORC_0032, 1032)
    endfunction
endlibrary
