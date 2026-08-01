/**
    qKrunnBroadshield

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Krunn Broadshield, Bonecrusher shield vendor.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Krunn's vendor quest automatically.

**/
library qKrunnBroadshield initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n04G', "Heavy Metal", "daily", 11, "Heavy Metal", "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Bring dense ore for Krunn's oversized shield rims.", 'I67H', 5, 60, VL_VENDORQUEST_BONECRUSHER_TYPE, 5, "Krunn needs five heavy rocks with metal inside. Shield must be heavier than Krunn.", "Good metal. Shield will fall over before it breaks.")
    endfunction
endlibrary
