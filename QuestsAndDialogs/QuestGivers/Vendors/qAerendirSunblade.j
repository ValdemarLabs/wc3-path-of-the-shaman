/**
    qAerendirSunblade

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily Elarindor vendor quest content for Aerendir Sunblade.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    - Registers Aerendir's vendor quest automatically.

**/
library qAerendirSunblade initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        local integer definitionId = VendorQuests_RegisterKillQuest('h00L', "Wraiths at the Forge", "daily", 16, "Wraiths at the Forge", "ReplaceableTextures\\CommandButtons\\BTNGhost.blp", "Destroy the mana wraiths drifting toward Aerendir's restored forge.", 'n002', 6, 80, VL_VENDORQUEST_ELARINDOR_TYPE, 1, VL_VENDORQUEST_ELARINDOR_0001, VL_VENDORQUEST_ELARINDOR_0002)
        call VendorQuests_SetFactionReward(definitionId, "Elarindor", 20, false)
    endfunction
endlibrary
