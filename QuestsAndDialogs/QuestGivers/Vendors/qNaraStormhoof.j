/**
    qNaraStormhoof

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Horde Tauren vendor quest content for Nara Stormhoof.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Nara Stormhoof's vendor quest automatically.

**/
library qNaraStormhoof initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('o01E', "Shadow over the Long Road", "daily", 9, "Shadow over the Long Road", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Defeat eight shadowdancers stalking Nara's travelling route.", 'nsty', 8, 50, VL_TAUREN_MALE_1_TYPE, 1007, VL_VENDORQUEST_TAUREN_0007, VL_VENDORQUEST_TAUREN_0008)
        call QuestsVendor_SetFactionReward(definitionId, "Horde", 20, false)
    endfunction
endlibrary
