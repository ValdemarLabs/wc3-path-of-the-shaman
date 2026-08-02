/**
    qKargunAshblade

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Kargun Ashblade.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Kargun Ashblade's vendor quests automatically.

**/
library qKargunAshblade initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId

        call QuestsVendor_RegisterFetchQuest('o011', "Ore for the Edge", "daily", 4, "Ore for the Edge", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Bring Ghorak iron ore suitable for sharpening the day's weapon stock.", 'I67E', 5, 25, VL_VENDORQUEST_ORC_TYPE, 1, VL_VENDORQUEST_ORC_0001, VL_VENDORQUEST_ORC_0002)
        set definitionId = QuestsVendor_RegisterKillQuest('o011', "Steel Proven in Blood", "normal", 10, "Steel Proven in Blood", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Temper Kargun's newest steel by defeating dark trolls with it.", 'ndqt', 12, 75, VL_VENDORQUEST_ORC_TYPE, 25, VL_VENDORQUEST_ORC_0025, VL_VENDORQUEST_ORC_0026)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_ORC_0027, 27, VL_VENDORQUEST_ORC_0028, 28)
    endfunction
endlibrary
