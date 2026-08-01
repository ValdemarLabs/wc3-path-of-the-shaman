/**
    qGrizzikBloodbet

    Author: Valdemar
    Version: 1.0.0

    Description:
    Vendor quest content for Wixx Prizebroker, Goblin arena quartermaster.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Wixx's vendor quest automatically.

**/
library qGrizzikBloodbet initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterKillQuest('n046', "Prizefighter's Proof", "normal", 11, "Prizefighter's Proof", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Demonstrate arena-worthy aggression by defeating satyr shadowdancers.", 'nsty', 10, 85, VL_VENDORQUEST_GOBLIN_TYPE, 13, VL_VENDORQUEST_GOBLIN_0013, VL_VENDORQUEST_GOBLIN_0014)
    endfunction
endlibrary
