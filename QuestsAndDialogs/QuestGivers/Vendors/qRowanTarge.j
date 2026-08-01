/**
    qRowanTarge

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Cedric Vale, Human shield merchant.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Cedric's vendor quest automatically.

**/
library qRowanTarge initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('n03A', "Gnolls at the Palisade", "daily", 5, "Gnolls at the Palisade", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Drive gnolls away from Cedric's shield-testing palisade.", 'ngno', 7, 35, VL_VENDORQUEST_HUMAN_TYPE, 5, "Gnolls keep clawing at the test palisade. Remove seven before they damage the new shields.", "The palisade is quiet, and the dents now come from proper testing.")
    endfunction
endlibrary
