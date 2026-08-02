/**
    qOwenMarlow

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Odette Hearth, Human cook.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Odette's vendor quest automatically.

**/
library qOwenMarlow initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n03F', "Stock the Smokehouse", "daily", 6, "Stock the Smokehouse", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "Gather meat for Odette's Stormhaven smokehouse.", 'I61O', 6, 35, VL_VENDORQUEST_HUMAN_TYPE, 9, VL_VENDORQUEST_HUMAN_0009, VL_VENDORQUEST_HUMAN_0010)
    endfunction
endlibrary
