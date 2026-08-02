/**
    qKrikzakDeepcut

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Grizzle Drillbit, Goblin miner.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Grizzle's vendor quest automatically.

**/
library qKrikzakDeepcut initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        call QuestsVendor_RegisterFetchQuest('n042', "Ore Futures", "daily", 7, "Ore Futures", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Bring Grizzle iron ore for a speculative mining contract.", 'I67E', 8, 40, VL_VENDORQUEST_GOBLIN_TYPE, 9, VL_VENDORQUEST_GOBLIN_0009, VL_VENDORQUEST_GOBLIN_0010)
    endfunction
endlibrary
