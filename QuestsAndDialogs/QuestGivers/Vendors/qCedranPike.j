/**
    qCedranPike

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Marshal Rowan, Human quartermaster.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Rowan's vendor quest automatically.

**/
library qCedranPike initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterSupplyQuest('n03P', "The Travelling Manifest", "daily", 8, "The Travelling Manifest", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Collect a supply manifest from Elias Roam and return it to Marshal Rowan.", 'n03C', "Elias Roam", 'I010', 45, VL_GENERIC_HUMAN_MALE_2_TYPE, 1013, VL_VENDORQUEST_HUMAN_0013, VL_VENDORQUEST_HUMAN_0014)
    endfunction
endlibrary
