/**
    qMarshalRowan

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Marshal Rowan, Human quartermaster.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Rowan's vendor quest automatically.

**/
library qMarshalRowan initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterSupplyQuest('n03P', "The Travelling Manifest", "daily", 8, "The Travelling Manifest", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Collect a supply manifest from Elias Roam and return it to Marshal Rowan.", 'n03C', "Elias Roam", 'I010', 45, VL_VENDORQUEST_HUMAN_TYPE, 13, "Elias has today's travelling manifest. Bring the sealed copy back to me.", "The figures match our ledger. That is rarer than it ought to be.")
    endfunction
endlibrary
