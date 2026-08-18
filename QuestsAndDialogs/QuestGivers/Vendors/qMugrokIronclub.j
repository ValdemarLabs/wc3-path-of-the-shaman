/**
    qMugrokIronclub

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily and normal vendor quest content for Mugrok Ironclub.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Mugrok Ironclub's vendor quests automatically.

**/
library qMugrokIronclub initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId

        call QuestsVendor_RegisterKillQuest('n04E', "Break the Stalkers", "daily", 10, "Break the Stalkers", "ReplaceableTextures\\CommandButtons\\BTNSatyrHellcaller.blp", "Crush the satyr stalkers harassing Mugrak's weapon haulers.", 'nsth', 7, 55, VL_OGRE_BONECRUSHER_MALE_1_TYPE, 1001, VL_VENDORQUEST_BONECRUSHER_0001, VL_VENDORQUEST_BONECRUSHER_0002)
        set definitionId = QuestsVendor_RegisterKillQuest('n04E', "A Weapon's Reputation", "normal", 13, "A Weapon's Reputation", "ReplaceableTextures\\CommandButtons\\BTNSatyrHellcaller.blp", "Build the reputation of Mugrok's steel by crushing twelve satyr stalkers.", 'nsth', 12, 90, VL_OGRE_BONECRUSHER_MALE_1_TYPE, 1011, VL_VENDORQUEST_BONECRUSHER_0011, VL_VENDORQUEST_BONECRUSHER_0012)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_BONECRUSHER_0013, 1013, VL_VENDORQUEST_BONECRUSHER_0014, 1014)
    endfunction
endlibrary
