/**
    qThurgashOreEye

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Mokkar Orekeeper, Orc mining supplier.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Mokkar's vendor quest automatically.

**/
library qThurgashOreEye initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterSupplyQuest('o00L', "Tools from the Road", "daily", 6, "Tools from the Road", "ReplaceableTextures\\CommandButtons\\BTNPick.blp", "Collect a replacement mining tool from Rukha Trailhoof and return it to Mokkar.", 'o00B', "Rukha Trailhoof", 'I672', 35, VL_VENDORQUEST_ORC_TYPE, 13, "Rukha carries a tool crate meant for me. Fetch one from the road merchant and bring it back.", "No cracks in the haft and the head is straight. Exactly what I ordered.")
    endfunction
endlibrary
