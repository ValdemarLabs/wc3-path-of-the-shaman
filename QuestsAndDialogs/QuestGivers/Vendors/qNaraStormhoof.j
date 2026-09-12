/**
    qNaraStormhoof

    Author: Valdemar
    Version: 1.1.0

    Description:
    Daily and one-time escort quest content for Nara Stormhoof.

    Credits:

    How to install:
    Import after QuestsVendor and VoicelinesQuests.

    API:
    - Registers Nara Stormhoof's vendor quest automatically.

**/
library qNaraStormhoof initializer Init requires QuestsVendor, VoicelinesQuests, qANightToRemember
    private function Init takes nothing returns nothing
        local integer definitionId = QuestsVendor_RegisterKillQuest('o01E', "Shadow over the Long Road", "daily", 9, "Shadow over the Long Road", "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp", "Defeat eight shadowdancers stalking Nara's travelling route.", 'nsty', 8, 50, VL_GENERIC_TAUREN_MALE_1_TYPE, 1007, VL_VENDORQUEST_TAUREN_0007, VL_VENDORQUEST_TAUREN_0008)
        local integer escortDefinitionId

        call qANightToRemember_RegisterVendorType('o01E', VL_GENERIC_TAUREN_MALE_1_TYPE, 1101)
        call QuestsVendor_SetFactionReward(definitionId, "Horde", 20, false)
        set escortDefinitionId = QuestsVendor_RegisterEscortQuest('o01E', "A Road Beneath Open Sky", 9, "A Road Beneath Open Sky", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Escort Nara Stormhoof from the shadowed roadside to Koro Windpack's guarded caravan post.", 'o01D', "Koro Windpack's caravan post", 80, VL_GENERIC_TAUREN_MALE_1_TYPE, 1015, VL_VENDORQUEST_TAUREN_0015, VL_VENDORQUEST_TAUREN_0016)
        call QuestsVendor_SetExtendedDialogue(escortDefinitionId, VL_VENDORQUEST_TAUREN_0017, 1017, VL_VENDORQUEST_TAUREN_0018, 1018)
        call QuestsVendor_SetEscortTravelDialogue(escortDefinitionId, VL_VENDORQUEST_TAUREN_0019, 1019, "Stay close to the caravan. I will watch the trail behind us.")
        call QuestsVendor_SetEscortTradeLocked(escortDefinitionId, true)
        call QuestsVendor_SetFactionReward(escortDefinitionId, "Horde", 35, false)
    endfunction
endlibrary
