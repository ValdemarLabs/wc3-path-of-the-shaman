/**
    qRokjinHexsmoke

    Author: Valdemar
    Version: 1.0.0

    Description:
    Registers Rokjin Hexsmoke as a Horde witness for A Night To Remember.

    Credits:

    How to install:
    Import after qANightToRemember and VoicelinesQuests.

    API:
    Registers automatically.

**/
library qRokjinHexsmoke initializer Init requires qANightToRemember, VoicelinesQuests
    private function Init takes nothing returns nothing
        call qANightToRemember_RegisterVendorType('n05J', VL_GENERIC_TROLL_MALE_2_TYPE, 1001)
    endfunction
endlibrary
