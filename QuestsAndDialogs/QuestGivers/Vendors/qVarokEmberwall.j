/**
    qVarokEmberwall

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Brakka Bulwark, Orc shield merchant.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Brakka's vendor quest automatically.

**/
library qVarokEmberwall initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('o013', "Straps for the Line", "daily", 5, "Straps for the Line", "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Gather leather for the straps and grips on Brakka's shields.", 'I6A6', 6, 30, VL_VENDORQUEST_ORC_TYPE, 5, "A shield without good straps is just a dinner plate. Bring me six pieces of leather.", "Strong enough to hold when the whole line gets hit. Well done.")
    endfunction
endlibrary
