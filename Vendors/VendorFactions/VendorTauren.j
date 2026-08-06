/**
    VendorTauren

    Author: Valdemar
    Version: 1.0.0

    Description:
    Assigns Horde Tauren vendor unit types to equipment, provision,
    beast-supply, and faction-quartermaster catalogs.

    Credits:

    How to install:
    Import after VendorCatalogs.

    API:
    - Registers Horde Tauren vendor unit types automatically during initialization.

**/
library VendorTauren initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, VL_VENDOR_PROFILE_TAUREN_HORDE_MALE)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Horde")
    endfunction

    private function Init takes nothing returns nothing
        call Register('o015', VendorCatalogs_VENDOR_CATALOG_WEAPONS)
        call Register('o016', VendorCatalogs_VENDOR_CATALOG_ARMOR)
        call Register('o017', VendorCatalogs_VENDOR_CATALOG_SHIELDS)
        call Register('o018', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK)
        call Register('o019', VendorCatalogs_VENDOR_CATALOG_BEAST_SUPPLIES)
        call Register('o01A', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER)
        call Register('o01B', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES)
        call Register('o01C', VendorCatalogs_VENDOR_CATALOG_MINER)
        call Register('o01D', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS)
        call Register('o01E', VendorCatalogs_VENDOR_CATALOG_TRAVELLING)
    endfunction
endlibrary
