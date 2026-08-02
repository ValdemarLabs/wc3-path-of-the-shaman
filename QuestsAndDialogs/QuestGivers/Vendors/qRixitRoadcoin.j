/**
    qRixitRoadcoin

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
library qRixitRoadcoin initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        local integer definitionId = VendorQuests_RegisterSupplyQuest('n03X', "A Favor Between Merchants", "daily", 7, "A Favor Between Merchants", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Buy Brakko's trade bundle from Tink Sprocketcrate and return it.", 'n04C', "Tink Sprocketcrate", 'I689', 40, VL_VENDORQUEST_GOBLIN_TYPE, 3, VL_VENDORQUEST_GOBLIN_0003, VL_VENDORQUEST_GOBLIN_0004)
        call VendorQuests_SetSupplyRequiresPurchase(definitionId, true)
    endfunction
endlibrary
