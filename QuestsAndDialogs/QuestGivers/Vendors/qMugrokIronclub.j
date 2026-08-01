/**
    qMugrokIronclub

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Mugrak Boneedge, Bonecrusher weaponsmith.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Mugrak's vendor quest automatically.

**/
library qMugrokIronclub initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('n04E', "Break the Stalkers", "daily", 10, "Break the Stalkers", "ReplaceableTextures\\CommandButtons\\BTNSatyrHellcaller.blp", "Crush the satyr stalkers harassing Mugrak's weapon haulers.", 'nsth', 7, 55, VL_VENDORQUEST_BONECRUSHER_TYPE, 1, "Stalkers scratch weapon carts. Break seven stalkers. Carts stop scratching.", "Good breaking. Mugrak's carts roll safe now.")
    endfunction
endlibrary
