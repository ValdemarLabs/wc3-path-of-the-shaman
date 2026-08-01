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
        call Register('n035', VendorCatalogs_VENDOR_CATALOG_WEAPONS, "Riverbane Human")
        call Register('n039', VendorCatalogs_VENDOR_CATALOG_ARMOR, "Riverbane Human")
        call Register('n03A', VendorCatalogs_VENDOR_CATALOG_SHIELDS, "Riverbane Human")
        call Register('n03E', VendorCatalogs_VENDOR_CATALOG_MINER, "Riverbane Human")
        call Register('n03G', VendorCatalogs_VENDOR_CATALOG_ALCHEMY_SUPPLIES, "Riverbane Human")
        call Register('n03H', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, "Riverbane Human")
        call Register('n03L', VendorCatalogs_VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, "Riverbane Human")
        call Register('n03M', VendorCatalogs_VENDOR_CATALOG_MINING_SUPPLIES, "Riverbane Human")
        call Register('n03N', VendorCatalogs_VENDOR_CATALOG_SKINNING_SUPPLIES, "Riverbane Human")
        call Register('n03P', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, "Riverbane Human")

        // Stormhaven merchants.
        call Register('n03D', VendorCatalogs_VENDOR_CATALOG_FISHER, "Stormhaven Human")
        call Register('n03F', VendorCatalogs_VENDOR_CATALOG_COOK, "Stormhaven Human")
        call Register('n03I', VendorCatalogs_VENDOR_CATALOG_COOKING_SUPPLIES, "Stormhaven Human")
        call Register('n03J', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, "Stormhaven Human")
        call Register('n03K', VendorCatalogs_VENDOR_CATALOG_FISHING_SUPPLIES, "Stormhaven Human")
        call Register('n03R', VendorCatalogs_VENDOR_CATALOG_REAGENTS, "Stormhaven Human")
        call Register('n03S', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK, "Stormhaven Human")

        // Neutral and travelling merchants.
        call Register('n03B', VendorCatalogs_VENDOR_CATALOG_ARENA, "Neutral Human")
        call Register('n03C', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, "Neutral Human")
        call Register('n03O', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES, "Neutral Human")
        call Register('n03Q', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, "Neutral Human")
        call Register('n03T', VendorCatalogs_VENDOR_CATALOG_POTIONS, "Neutral Human")
        call Register('n03U', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, "Neutral Human")
        call Register('n03V', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, "Neutral Human")
    endfunction
endlibrary
