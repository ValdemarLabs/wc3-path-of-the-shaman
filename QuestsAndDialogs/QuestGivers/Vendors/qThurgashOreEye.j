/**
    qThurgashOreEye

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Mokkar Orekeeper, Orc mining supplier.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Mokkar's vendor quest automatically.

**/
library qThurgashOreEye initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterSupplyQuest('o00L', "Tools from the Road", "daily", 6, "Tools from the Road", "ReplaceableTextures\\CommandButtons\\BTNPick.blp", "Collect a replacement mining tool from Rukha Trailhoof and return it to Mokkar.", 'o00B', "Rukha Trailhoof", 'I672', 35, VL_ORC_MALE_5_TYPE, 1013, VL_VENDORQUEST_ORC_0013, VL_VENDORQUEST_ORC_0014)
    endfunction
endlibrary
