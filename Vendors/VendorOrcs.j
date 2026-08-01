/**
    VendorOrcs

    Author: Valdemar
    Version: 1.0.0

    Description:
    Assigns the custom Orc vendor unit types to concrete vendor catalogs and
    Fiery Mountain, forest, or Sirensong regional voice profiles.

    Credits:

    How to install:
    Import after VendorCatalogs.

    API:
    - Registers Orc vendor unit types automatically during initialization.

**/
library VendorOrcs initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType, string profile returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profile)
    endfunction

    private function Init takes nothing returns nothing
        // Fiery Mountain equipment and mining vendors.
        call Register('o011', VendorCatalogs_VENDOR_CATALOG_WEAPONS, "Fiery Mountain Orc")
        call Register('o012', VendorCatalogs_VENDOR_CATALOG_ARMOR, "Fiery Mountain Orc")
        call Register('o013', VendorCatalogs_VENDOR_CATALOG_SHIELDS, "Fiery Mountain Orc")
        call Register('o00A', VendorCatalogs_VENDOR_CATALOG_ARENA, "Fiery Mountain Orc")
        call Register('o00D', VendorCatalogs_VENDOR_CATALOG_MINER, "Fiery Mountain Orc")
        call Register('o00G', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, "Fiery Mountain Orc")
        call Register('o00L', VendorCatalogs_VENDOR_CATALOG_MINING_SUPPLIES, "Fiery Mountain Orc")
        call Register('o00T', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, "Fiery Mountain Orc")

        // Sereneglade, Thornwoods, and Riverbane forest vendors.
        call Register('o00B', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, "Forest Orc")
        call Register('o00E', VendorCatalogs_VENDOR_CATALOG_COOK, "Forest Orc")
        call Register('o00H', VendorCatalogs_VENDOR_CATALOG_COOKING_SUPPLIES, "Forest Orc")
        call Register('o00I', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, "Forest Orc")
        call Register('o00K', VendorCatalogs_VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, "Forest Orc")
        call Register('o00M', VendorCatalogs_VENDOR_CATALOG_SKINNING_SUPPLIES, "Forest Orc")
        call Register('o00N', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES, "Forest Orc")
        call Register('o00O', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, "Forest Orc")
        call Register('o00P', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, "Forest Orc")
        call Register('o00R', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK, "Forest Orc")
        call Register('o00S', VendorCatalogs_VENDOR_CATALOG_POTIONS, "Forest Orc")
        call Register('o00U', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, "Forest Orc")
        call Register('o00V', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS, "Forest Orc")
        call Register('o00W', VendorCatalogs_VENDOR_CATALOG_BEAST_SUPPLIES, "Forest Orc")

        // Sirensong coastal and jungle vendors.
        call Register('o00C', VendorCatalogs_VENDOR_CATALOG_FISHER, "Sirensong Jungle Orc")
        call Register('o00F', VendorCatalogs_VENDOR_CATALOG_ALCHEMY_SUPPLIES, "Sirensong Jungle Orc")
        call Register('o00J', VendorCatalogs_VENDOR_CATALOG_FISHING_SUPPLIES, "Sirensong Jungle Orc")
        call Register('o00Q', VendorCatalogs_VENDOR_CATALOG_REAGENTS, "Sirensong Jungle Orc")
        call Register('o00X', VendorCatalogs_VENDOR_CATALOG_WEAPONS, "Sirensong Jungle Orc")
        call Register('o00Y', VendorCatalogs_VENDOR_CATALOG_ARMOR, "Sirensong Jungle Orc")
        call Register('o00Z', VendorCatalogs_VENDOR_CATALOG_SHIELDS, "Sirensong Jungle Orc")
        call Register('o010', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, "Sirensong Jungle Orc")
        call Register('o014', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, "Sirensong Jungle Orc")
    endfunction
endlibrary
