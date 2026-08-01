/**
    qElayneWard

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Elayne Ward, Human armorer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Elayne's vendor quest automatically.

**/
library qElayneWard initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n039', "Patches for the Watch", "daily", 5, "Patches for the Watch", "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Gather leather so Elayne can repair the Riverbane watch's armor.", 'I6A6', 7, 30, VL_VENDORQUEST_HUMAN_TYPE, 3, "The watch returned with more holes than armor. Bring seven pieces of leather for patches.", "These will hold. At least until the watch finds another briar patch.")
    endfunction
endlibrary
