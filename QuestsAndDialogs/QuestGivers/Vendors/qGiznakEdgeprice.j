/**
    qGiznakEdgeprice

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Razzik Sharpsale, Goblin weapons dealer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Razzik's vendor quest automatically.

**/
library qGiznakEdgeprice initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('n03Y', "Field-Tested Steel", "daily", 5, "Field-Tested Steel", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Field-test Razzik's weapon advice against nearby gnolls.", 'ngno', 9, 35, VL_VENDORQUEST_GOBLIN_TYPE, 5, "My blades are guaranteed against nine gnolls or your effort back. Go test the claim.", "Nine gnolls and no complaint from the blade. Another satisfied demonstration!")
    endfunction
endlibrary
