/**
    qKrikzakDeepcut

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Krikzak Deepcut, Goblin miner.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Krikzak's vendor quest automatically.

**/
library qKrikzakDeepcut initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n042', "Ore Futures", "daily", 7, "Ore Futures", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Bring Krikzak iron ore for a speculative mining contract.", 'I67E', 8, 40, VL_GENERIC_GOBLIN_MALE_4_TYPE, 1009, VL_VENDORQUEST_GOBLIN_0009, VL_VENDORQUEST_GOBLIN_0010)
    endfunction
endlibrary
