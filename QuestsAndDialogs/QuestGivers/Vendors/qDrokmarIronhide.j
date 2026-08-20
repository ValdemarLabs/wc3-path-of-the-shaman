/**
    qDrokmarIronhide

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Mazgura Stonehide, Orc armorer.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Mazgura's vendor quest automatically.

**/
library qDrokmarIronhide initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterKillQuest('o012', "Thin the Shadowdancers", "daily", 8, "Thin the Shadowdancers", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Reduce the satyr threat against Mazgura's hide and metal caravans.", 'nsty', 6, 40, VL_GENERIC_ORC_MALE_4_TYPE, 1003, VL_VENDORQUEST_ORC_0003, VL_VENDORQUEST_ORC_0004)
    endfunction
endlibrary
