/**
    qElowenStarweaver

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily Elarindor vendor quest content for Elowen Starweaver.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Elowen's vendor quest automatically.

**/
library qElowenStarweaver initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterFetchQuest('h00Q', "Fragments of Elarindor", "daily", 16, "Fragments of Elarindor", "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Gem_Crystal_01.blp", "Gather mana crystals so Elowen can restore protective enchantments around the refuge.", 'I00Y', 5, 80, VL_GENERIC_ELARINDOR_FEMALE_2_TYPE, 1003, VL_VENDORQUEST_ELARINDOR_0003, VL_VENDORQUEST_ELARINDOR_0004)
        call QuestsVendor_SetFactionReward(definitionId, "Elarindor", 20, false)
    endfunction
endlibrary
