/**
    qElowenStarweaver

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Elarindor vendor quest content for Elowen Starweaver.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    - Registers Elowen's vendor quest automatically.

**/
library qElowenStarweaver initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        local integer definitionId = VendorQuests_RegisterFetchQuest('n04R', "Fragments of Elarindor", "daily", 16, "Fragments of Elarindor", "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Gem_Crystal_01.blp", "Gather mana crystals so Elowen can restore protective enchantments around the refuge.", 'I00Y', 5, 80, VL_VENDORQUEST_ELARINDOR_TYPE, 3, VL_VENDORQUEST_ELARINDOR_0003, VL_VENDORQUEST_ELARINDOR_0004)
        call VendorQuests_SetFactionReward(definitionId, "Elarindor", 20, false)
    endfunction
endlibrary
