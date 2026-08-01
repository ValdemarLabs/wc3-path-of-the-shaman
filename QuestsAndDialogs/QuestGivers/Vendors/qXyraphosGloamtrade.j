/**
    qXyraphosGloamtrade

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Xyraphos, Satyr rare-goods dealer.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Xyraphos's vendor quest automatically.

**/
library qXyraphosGloamtrade initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n02Z', "Crystals in the Gloom", "daily", 10, "Crystals in the Gloom", "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Gather enchanting crystals for Xyraphos's secretive clientele.", 'I003', 5, 55, VL_VENDORQUEST_SATYR_TYPE, 3, "My clients demand five flawless crystals and dislike being kept waiting.", "Acceptable clarity. Their origins are no concern of yours.")
    endfunction
endlibrary
