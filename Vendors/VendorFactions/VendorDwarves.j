/**
    VendorDwarves

    Author: Valdemar
    Version: 1.0.0

    Description:
    Assigns Morgrim Clan Dwarf vendor unit types to forge, equipment, mining,
    supply, and trade catalogs with a shared Dwarf merchant voice profile.

    Credits:

    How to install:
    Import after VendorCatalogs and VoicelinesVendorLines.

    API:
    - Registers Morgrim Clan Dwarf vendor unit types automatically.

**/
library VendorDwarves initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, VL_VENDOR_PROFILE_DWARF_MORGRIM)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Morgrim Clan")
    endfunction

    private function Init takes nothing returns nothing
        call Register('n05C', VendorCatalogs_VENDOR_CATALOG_BLACKSMITH)
        call Register('n05D', VendorCatalogs_VENDOR_CATALOG_BLACKSMITH)
        call Register('n05E', VendorCatalogs_VENDOR_CATALOG_BLACKSMITH)
        call Register('n05F', VendorCatalogs_VENDOR_CATALOG_WEAPONS)
        call Register('n05G', VendorCatalogs_VENDOR_CATALOG_ARMOR)
        call Register('n05H', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES)
        call Register('n05I', VendorCatalogs_VENDOR_CATALOG_MINER)
        call Register('n05J', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS)
    endfunction
endlibrary
