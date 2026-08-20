/**
    qAerendirSunblade

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and normal vendor quest content for Aerendir Sunblade.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Aerendir's vendor quest automatically.

**/
library qAerendirSunblade initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('h00L', "Wraiths at the Forge", "daily", 16, "Wraiths at the Forge", "ReplaceableTextures\\CommandButtons\\BTNGhost.blp", "Destroy the mana wraiths drifting toward Aerendir's restored forge.", 'n002', 6, 80, VL_GENERIC_ELARINDOR_MALE_1_TYPE, 1001, VL_VENDORQUEST_ELARINDOR_0001, VL_VENDORQUEST_ELARINDOR_0002)
        local integer normalDefinitionId

        call QuestsVendor_SetFactionReward(definitionId, "Elarindor", 20, false)
        set normalDefinitionId = QuestsVendor_RegisterFetchQuest('h00L', "Relics of the Fallen Forge", "normal", 18, "Relics of the Fallen Forge", "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Gem_Crystal_01.blp", "Recover seven mana crystals from the ruins of Elarindor's fallen forge.", 'I00Y', 7, 110, VL_GENERIC_ELARINDOR_MALE_1_TYPE, 1009, VL_VENDORQUEST_ELARINDOR_0009, VL_VENDORQUEST_ELARINDOR_0010)
        call QuestsVendor_SetExtendedDialogue(normalDefinitionId, VL_VENDORQUEST_ELARINDOR_0011, 1011, VL_VENDORQUEST_ELARINDOR_0012, 1012)
        call QuestsVendor_SetFactionReward(normalDefinitionId, "Elarindor", 25, false)
    endfunction
endlibrary
