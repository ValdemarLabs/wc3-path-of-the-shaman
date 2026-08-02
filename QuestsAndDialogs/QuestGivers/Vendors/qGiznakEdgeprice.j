/**
    qGiznakEdgeprice

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Razzik Sharpsale, Goblin weapons dealer.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Razzik's vendor quest automatically.

**/
library qGiznakEdgeprice initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterKillQuest('n03Y', "Field-Tested Steel", "daily", 5, "Field-Tested Steel", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Field-test Razzik's weapon advice against nearby gnolls.", 'ngno', 9, 35, VL_VENDORQUEST_GOBLIN_TYPE, 5, VL_VENDORQUEST_GOBLIN_0005, VL_VENDORQUEST_GOBLIN_0006)
    endfunction
endlibrary
