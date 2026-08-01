/**
    qDrokmarIronhide

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Mazgura Stonehide, Orc armorer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Mazgura's vendor quest automatically.

**/
library qDrokmarIronhide initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('o012', "Thin the Shadowdancers", "daily", 8, "Thin the Shadowdancers", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Reduce the satyr threat against Mazgura's hide and metal caravans.", 'nsty', 6, 40, VL_VENDORQUEST_ORC_TYPE, 3, "Shadowdancers keep cutting apart my caravans. Cut down six of them first.", "That should buy my haulers a quiet road for one more night.")
    endfunction
endlibrary
