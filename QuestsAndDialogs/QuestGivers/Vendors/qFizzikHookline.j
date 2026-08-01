/**
    qFizzikHookline

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Nibbs Netcaster, Goblin fisher.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Nibbs's vendor quest automatically.

**/
library qFizzikHookline initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n041', "Catch of the Minute", "daily", 6, "Catch of the Minute", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Bring Nibbs enough fish to satisfy a very impatient buyer.", 'I6CU', 9, 35, VL_VENDORQUEST_GOBLIN_TYPE, 7, "A buyer wants nine fish immediately, which means I wanted them five minutes ago!", "Still wet and only slightly late. That counts as premium service.")
    endfunction
endlibrary
