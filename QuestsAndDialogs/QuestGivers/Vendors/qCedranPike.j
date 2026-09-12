/**
    qCedranPike

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and one-time escort quest content for Cedran Pike,
    Riverbane quartermaster.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Cedran Pike's vendor quests automatically.

**/
library qCedranPike initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer escortDefinitionId

        call QuestsVendor_RegisterSupplyQuest('n03P', "The Travelling Manifest", "daily", 8, "The Travelling Manifest", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Collect a supply manifest from Merrick Wayland and return it to Cedran Pike.", 'n03C', "Merrick Wayland", 'I010', 45, VL_GENERIC_HUMAN_MALE_2_TYPE, 1013, VL_VENDORQUEST_HUMAN_0013, VL_VENDORQUEST_HUMAN_0014)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('n03P', "The Ledger Comes Home", 8, "The Ledger Comes Home", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Escort Cedran Pike and Riverbane's field ledgers from the exposed road to Garrick Holt's forge.", 'n035', "Garrick Holt's Riverbane forge", 70, VL_GENERIC_HUMAN_MALE_2_TYPE, 1038, VL_VENDORQUEST_HUMAN_0038, VL_VENDORQUEST_HUMAN_0039)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_HUMAN_0040, 1040, VL_VENDORQUEST_HUMAN_0041, 1041)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_HUMAN_0042, 1042, "Keep the ledger close. I will make certain nobody reaches it from the rear.")
        call QuestsVendor_SetEscortTradeLocked(escortDefinitionId, true)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Riverbane", 30, false)
    endfunction
endlibrary
