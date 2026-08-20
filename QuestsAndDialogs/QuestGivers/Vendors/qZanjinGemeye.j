/**
    qZanjinGemeye

    Author: Valdemar
    Version: 1.0.0

    Description:
    Registers Zanjin Gemeye as a Horde witness for A Night To Remember.

    Credits:

    How to install:
    Import after qANightToRemember and VoicelinesQuests.

    API:
    Registers automatically.

**/
library qZanjinGemeye initializer Init requires qANightToRemember, VoicelinesQuests
    private function Init takes nothing returns nothing
        call qANightToRemember_RegisterVendorType('n05H', VL_GENERIC_TROLL_MALE_1_TYPE, 1001)
    endfunction
endlibrary
