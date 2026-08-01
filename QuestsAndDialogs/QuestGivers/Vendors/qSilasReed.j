/**
    qSilasReed

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Maren Tidewell, Human fisher.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Maren's vendor quest automatically.

**/
library qSilasReed initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n03D', "Stormhaven Supper", "daily", 6, "Stormhaven Supper", "ReplaceableTextures\\CommandButtons\\BTNFishing.blp", "Bring Maren a fresh catch for Stormhaven's evening tables.", 'I6CV', 8, 35, VL_VENDORQUEST_HUMAN_TYPE, 7, "Stormhaven expects fish on every table tonight. Bring me eight from a clean catch.", "Fresh and firm. The innkeepers will stop shouting for an hour.")
    endfunction
endlibrary
