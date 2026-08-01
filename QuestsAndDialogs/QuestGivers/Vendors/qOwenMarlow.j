/**
    qOwenMarlow

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Odette Hearth, Human cook.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Odette's vendor quest automatically.

**/
library qOwenMarlow initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n03F', "Stock the Smokehouse", "daily", 6, "Stock the Smokehouse", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "Gather meat for Odette's Stormhaven smokehouse.", 'I61O', 6, 35, VL_VENDORQUEST_HUMAN_TYPE, 9, "The smokehouse has room for six more cuts. Bring them while the coals are ready.", "Perfect timing. These can go straight onto the hooks.")
    endfunction
endlibrary
