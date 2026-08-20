/**
    qTawaDeepvein

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Horde Tauren vendor quest content for Tawa Deepvein.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Tawa Deepvein's vendor quest automatically.

**/
library qTawaDeepvein initializer Init requires QuestsVendor, VoicelinesQuests, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterFetchQuest('o01C', "Stonebreaker's Measure", "daily", 10, "Stonebreaker's Measure", "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Bring Tawa six pieces of dense ore from an untainted seam.", 'I67H', 6, 55, VL_GENERIC_TAUREN_MALE_2_TYPE, 1003, VL_VENDORQUEST_TAUREN_0003, VL_VENDORQUEST_TAUREN_0004)
        call qANightToRemember_RegisterVendorType('o01C', VL_GENERIC_TAUREN_MALE_2_TYPE, 1101)
        call QuestsVendor_SetFactionReward(definitionId, "Horde", 20, false)
    endfunction
endlibrary
