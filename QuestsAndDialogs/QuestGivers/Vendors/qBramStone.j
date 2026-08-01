/**
    qBramStone

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Bram Stone, Human miner.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Bram's vendor quest automatically.

**/
library qBramStone initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n03E', "Lantern Fuel", "daily", 5, "Lantern Fuel", "ReplaceableTextures\\CommandButtons\\BTNHumanLumberUpgrade1.blp", "Collect fuel for Bram's mine lanterns and heating braziers.", 'I689', 7, 30, VL_VENDORQUEST_HUMAN_TYPE, 11, "Seven bundles of fuel should keep the lower galleries lit through the shift.", "Dry and tightly packed. Nobody gets lost in the dark today.")
    endfunction
endlibrary
