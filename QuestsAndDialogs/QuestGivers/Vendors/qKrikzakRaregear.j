/**
    qKrikzakRaregear

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Krikzak Raregear, Goblin rare-goods dealer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Krikzak's vendor quest automatically.

**/
library qKrikzakRaregear initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterSupplyQuest('n04A', "Reagent on Credit", "daily", 12, "Reagent on Credit", "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Collect Krikzak's reagent shipment from Fizzik Hexstock and return.", 'n047', "Fizzik Hexstock", 'I003', 70, VL_VENDORQUEST_GOBLIN_TYPE, 15, "Fizzik has one crystal shipment marked for me. Ignore anything he says about interest.", "The right shipment and no scorch marks. A remarkably clean transaction.")
    endfunction
endlibrary
