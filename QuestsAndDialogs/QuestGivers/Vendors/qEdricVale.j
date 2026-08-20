/**
    qEdricVale

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Elayne Ward, Human armorer.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Elayne's vendor quest automatically.

**/
library qEdricVale initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n039', "Patches for the Watch", "daily", 5, "Patches for the Watch", "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Gather leather so Elayne can repair the Riverbane watch's armor.", 'I6A6', 7, 30, VL_GENERIC_HUMAN_MALE_2_TYPE, 1003, VL_VENDORQUEST_HUMAN_0003, VL_VENDORQUEST_HUMAN_0004)
    endfunction
endlibrary
