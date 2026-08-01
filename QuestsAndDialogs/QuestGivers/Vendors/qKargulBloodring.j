/**
    qKargulBloodring

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Kargul Bloodring, Orc arena vendor.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Kargul's vendor quest automatically.

**/
library qKargulBloodring initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('o00A', "A Worthy Warm-Up", "daily", 4, "A Worthy Warm-Up", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Prove your readiness for the arena by hunting nearby gnolls.", 'ngno', 8, 35, VL_VENDORQUEST_ORC_TYPE, 7, "The ring has no room for stiff fighters. Warm up on eight gnolls and come back standing.", "Blood moving, eyes clear. Now you might survive a real bout.")
    endfunction
endlibrary
