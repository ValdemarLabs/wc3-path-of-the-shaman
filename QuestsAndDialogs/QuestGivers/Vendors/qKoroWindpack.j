/**
    qKoroWindpack

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Horde Tauren vendor quest content for Koro Windpack.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Koro Windpack's vendor quest automatically.

**/
library qKoroWindpack initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('o01D', "Gnolls on the Supply Trail", "daily", 7, "Gnolls on the Supply Trail", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Defeat eight gnolls threatening Koro's supply trail.", 'ngno', 8, 40, VL_VENDORQUEST_TAUREN_TYPE, 5, VL_VENDORQUEST_TAUREN_0005, VL_VENDORQUEST_TAUREN_0006)
        call QuestsVendor_SetFactionReward(definitionId, "Horde", 15, false)
    endfunction
endlibrary
