/**
    VendorSatyrs

    Author: Valdemar
    Version: 1.1.0

    Description:
    Assigns the custom Satyr vendor unit types to arcane, arena, equipment,
    travelling, and rare-goods vendor catalogs.

    Credits:

    How to install:
    Import after VendorCatalogs.

    API:
    - Registers Satyr vendor unit types automatically during initialization.

**/
library VendorSatyrs initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, VL_VENDOR_PROFILE_SATYR_MALE)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Satyr")
    endfunction

    private function Init takes nothing returns nothing
        call Register('n02Y', VendorCatalogs_VENDOR_CATALOG_ARENA)
        call Register('n02Z', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS)
        call Register('n030', VendorCatalogs_VENDOR_CATALOG_REAGENTS)
        call Register('n031', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES)
        call Register('n032', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS)
        call Register('n033', VendorCatalogs_VENDOR_CATALOG_POTIONS)
        call Register('n034', VendorCatalogs_VENDOR_CATALOG_WEAPONS)
        call Register('n036', VendorCatalogs_VENDOR_CATALOG_ARMOR)
        call Register('n037', VendorCatalogs_VENDOR_CATALOG_SHIELDS)
        call Register('n038', VendorCatalogs_VENDOR_CATALOG_TRAVELLING)
    endfunction
endlibrary
