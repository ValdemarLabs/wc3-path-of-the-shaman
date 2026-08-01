/**
    qBrakkoRoadcoin

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Brakko Roadcoin, Goblin traveller.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Brakko's vendor quest automatically.

**/
library qBrakkoRoadcoin initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterSupplyQuest('n03X', "A Favor Between Merchants", "daily", 7, "A Favor Between Merchants", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Collect Brakko's trade bundle from Tink Sprocketcrate and return.", 'n04C', "Tink Sprocketcrate", 'I689', 40, VL_VENDORQUEST_GOBLIN_TYPE, 3, "Tink owes me a trade bundle. Collect it, and do not agree to any extra fees.", "You paid no surprise fee? Hah! Tink must be losing his edge.")
    endfunction
endlibrary
