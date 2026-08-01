/**
    VoicelinesVendorQuests

    Author: Valdemar
    Version: 1.0.0

    Description:
    Shared ExSound key-prefix policy for generic vendor quest dialogue. Many
    vendor NPCs intentionally share the same race-oriented voice type.

    Credits:

    How to install:
    Import after ExSound. Matching sequences are registered in ExSound.j.

    API:
    Global VL_VENDORQUEST_*_TYPE constants are passed to VendorQuests.

**/
library VoicelinesVendorQuests requires ExSound
    globals
        constant string VL_VENDORQUEST_ORC_TYPE = "VendorQuestOrc_"
        constant string VL_VENDORQUEST_SATYR_TYPE = "VendorQuestSatyr_"
        constant string VL_VENDORQUEST_HUMAN_TYPE = "VendorQuestHuman_"
        constant string VL_VENDORQUEST_GOBLIN_TYPE = "VendorQuestGoblin_"
        constant string VL_VENDORQUEST_BONECRUSHER_TYPE = "VendorQuestBonecrusher_"
    endglobals
endlibrary
