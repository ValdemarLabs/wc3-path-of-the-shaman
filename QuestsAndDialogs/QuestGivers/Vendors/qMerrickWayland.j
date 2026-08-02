/**
    qMerrickWayland

    Author: Valdemar
    Version: 1.0.0

    Description:
    Vendor quest content for Elias Roam, Human travelling merchant.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Elias's vendor quest automatically.

**/
library qMerrickWayland initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('n03C', "The Toll Road", "normal", 11, "The Toll Road", "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "Clear dark trolls from a road Elias intends to reopen for trade.", 'ndqt', 9, 75, VL_VENDORQUEST_HUMAN_TYPE, 15, VL_VENDORQUEST_HUMAN_0015, VL_VENDORQUEST_HUMAN_0016)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_HUMAN_0027, 27, VL_VENDORQUEST_HUMAN_0028, 28)
    endfunction
endlibrary
