/**
    qGrizzikBloodbet

    Author: Valdemar
    Version: 1.0.0

    Description:
    Vendor quest content for Wixx Prizebroker, Goblin arena quartermaster.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    Registers Wixx's vendor quest automatically.

**/
library qGrizzikBloodbet initializer Init requires QuestsVendor, VoicelinesQuests
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('n046', "Prizefighter's Proof", "normal", 11, "Prizefighter's Proof", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Demonstrate arena-worthy aggression by defeating satyr shadowdancers.", 'nsty', 10, 85, VL_VENDORQUEST_GOBLIN_TYPE, 13, VL_VENDORQUEST_GOBLIN_0013, VL_VENDORQUEST_GOBLIN_0014)
        call QuestsVendor_SetExtendedDialogue(definitionId, VL_VENDORQUEST_GOBLIN_0025, 25, VL_VENDORQUEST_GOBLIN_0026, 26)
    endfunction
endlibrary
