/**
    qGrizzleDrillbit

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Grizzle Drillbit, Goblin miner.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Grizzle's vendor quest automatically.

**/
library qGrizzleDrillbit initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('n042', "Ore Futures", "daily", 7, "Ore Futures", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Bring Grizzle iron ore for a speculative mining contract.", 'I67E', 8, 40, VL_VENDORQUEST_GOBLIN_TYPE, 9, "Eight pieces of iron ore and I can close a very profitable future sale.", "Excellent! Now I only need the future buyer to actually exist.")
    endfunction
endlibrary
