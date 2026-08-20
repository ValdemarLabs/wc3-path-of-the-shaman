/**
    qBoranFlintmane

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Horde Tauren vendor quest content for Boran Flintmane.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Boran Flintmane's vendor quest automatically.

**/
library qBoranFlintmane initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterFetchQuest('o01B', "Fuel for the Warforge", "daily", 8, "Fuel for the Warforge", "ReplaceableTextures\\CommandButtons\\BTNHumanLumberUpgrade1.blp", "Bring Boran eight bundles of fuel for the Horde warforge.", 'I689', 8, 45, VL_GENERIC_TAUREN_MALE_1_TYPE, 1001, VL_VENDORQUEST_TAUREN_0001, VL_VENDORQUEST_TAUREN_0002)
        call QuestsVendor_SetFactionReward(definitionId, "Horde", 15, false)
    endfunction
endlibrary
