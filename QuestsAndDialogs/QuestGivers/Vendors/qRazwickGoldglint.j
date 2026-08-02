/**
    qRazwickGoldglint

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Krikzak Raregear, Goblin rare-goods dealer.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Krikzak's vendor quest automatically.

**/
library qRazwickGoldglint initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterSupplyQuest('n04A', "Reagent on Credit", "daily", 12, "Reagent on Credit", "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Buy Krikzak's reagent shipment from Fizzik Hexstock and return it.", 'n047', "Fizzik Hexstock", 'I003', 70, VL_VENDORQUEST_GOBLIN_TYPE, 15, VL_VENDORQUEST_GOBLIN_0015, VL_VENDORQUEST_GOBLIN_0016)
        call QuestsVendor_SetSupplyRequiresPurchase(definitionId, true)
    endfunction
endlibrary
