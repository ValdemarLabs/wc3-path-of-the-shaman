/**
    qGubmogStewpot

    Author: Valdemar
    Version: 1.0.0

    Description:
    Vendor quest content for Hukka Potstir, Bonecrusher cook.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Hukka's vendor quest automatically.

**/
library qGubmogStewpot initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterFetchQuest('n04J', "The Bigger Stew", "normal", 9, "The Bigger Stew", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "Bring Hukka enough meat to prove that every stew can be made bigger.", 'I61O', 10, 65, VL_VENDORQUEST_BONECRUSHER_TYPE, 9, VL_VENDORQUEST_BONECRUSHER_0009, VL_VENDORQUEST_BONECRUSHER_0010)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_BONECRUSHER_0015, 15, VL_VENDORQUEST_BONECRUSHER_0016, 16)
    endfunction
endlibrary
