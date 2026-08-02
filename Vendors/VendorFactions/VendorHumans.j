/**
    VendorHumans

    Author: Valdemar
    Version: 1.0.0

    Description:
    Assigns the custom Human vendor unit types to Riverbane, Stormhaven, and
    neutral merchant roles and voice profiles.

    Credits:

    How to install:
    Import after VendorCatalogs.

    API:
    - Registers Human vendor unit types automatically during initialization.

**/
library VendorHumans initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType, string profile returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profile)
    endfunction

    private function Init takes nothing returns nothing
        // Riverbane merchants.
        call Register('n035', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n039', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03A', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03E', VendorCatalogs_VENDOR_CATALOG_MINER, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03G', VendorCatalogs_VENDOR_CATALOG_ALCHEMY_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03H', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03L', VendorCatalogs_VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03M', VendorCatalogs_VENDOR_CATALOG_MINING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03N', VendorCatalogs_VENDOR_CATALOG_SKINNING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)
        call Register('n03P', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE)

        // Stormhaven merchants.
        call Register('n03D', VendorCatalogs_VENDOR_CATALOG_FISHER, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE)
        call Register('n03F', VendorCatalogs_VENDOR_CATALOG_COOK, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE)
        call Register('n03I', VendorCatalogs_VENDOR_CATALOG_COOKING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE)
        call Register('n03J', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE)
        call Register('n03K', VendorCatalogs_VENDOR_CATALOG_FISHING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE)
        call Register('n03R', VendorCatalogs_VENDOR_CATALOG_REAGENTS, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE)
        call Register('n03S', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE)

        // Neutral and travelling merchants.
        call Register('n03B', VendorCatalogs_VENDOR_CATALOG_ARENA, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE)
        call Register('n03C', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE)
        call Register('n03O', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE)
        call Register('n03Q', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE)
        call Register('n03T', VendorCatalogs_VENDOR_CATALOG_POTIONS, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE)
        call Register('n03U', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE)
        call Register('n03V', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE)

        // Female Riverbane merchants.
        call Register('n04O', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04P', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04Q', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04R', VendorCatalogs_VENDOR_CATALOG_MINER, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04S', VendorCatalogs_VENDOR_CATALOG_ALCHEMY_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04T', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04U', VendorCatalogs_VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04V', VendorCatalogs_VENDOR_CATALOG_MINING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04W', VendorCatalogs_VENDOR_CATALOG_SKINNING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)
        call Register('n04X', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE)

        // Female Stormhaven merchants.
        call Register('n04Y', VendorCatalogs_VENDOR_CATALOG_FISHER, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE)
        call Register('n04Z', VendorCatalogs_VENDOR_CATALOG_COOK, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE)
        call Register('n050', VendorCatalogs_VENDOR_CATALOG_COOKING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE)
        call Register('n051', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE)
        call Register('n052', VendorCatalogs_VENDOR_CATALOG_FISHING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE)
        call Register('n053', VendorCatalogs_VENDOR_CATALOG_REAGENTS, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE)
        call Register('n054', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK, VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE)

        // Female neutral and travelling merchants.
        call Register('n055', VendorCatalogs_VENDOR_CATALOG_ARENA, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE)
        call Register('n056', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE)
        call Register('n057', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE)
        call Register('n058', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE)
        call Register('n059', VendorCatalogs_VENDOR_CATALOG_POTIONS, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE)
        call Register('n05A', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE)
        call Register('n05B', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE)
    endfunction
endlibrary
