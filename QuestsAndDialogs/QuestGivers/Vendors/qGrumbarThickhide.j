/**
    qGrumbarThickhide

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Dorga Ironbelly, Bonecrusher armorer.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Dorga's vendor quest automatically.

**/
library qGrumbarThickhide initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n04F', "Thick Hide, Thick Armor", "daily", 9, "Thick Hide, Thick Armor", "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeTwo.blp", "Bring Dorga thick leather for reinforcing Bonecrusher armor.", 'I6A7', 6, 50, VL_OGRE_BONECRUSHER_MALE_1_TYPE, 1003, VL_VENDORQUEST_BONECRUSHER_0003, VL_VENDORQUEST_BONECRUSHER_0004)
    endfunction
endlibrary
