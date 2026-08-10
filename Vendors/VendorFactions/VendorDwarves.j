/**
    VendorDwarves

    Author: Valdemar
    Version: 1.0.0

    Description:
    Assigns Morgrim Clan Dwarf vendor unit types to forge, equipment, mining,
    supply, and trade catalogs with a shared male Dwarf merchant voice profile.

    Credits:

    How to install:
    Import after VendorCatalogs and VoicelinesVendorLines.

    API:
    - Registers Morgrim Clan Dwarf vendor unit types automatically.

**/
library VendorDwarves initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, VL_VENDOR_PROFILE_DWARF_MORGRIM_MALE)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Morgrim Clan")
    endfunction

    private function Init takes nothing returns nothing
        call Register('h00T', VendorCatalogs_VENDOR_CATALOG_BLACKSMITH)
        call Register('h00U', VendorCatalogs_VENDOR_CATALOG_BLACKSMITH)
        call Register('h00V', VendorCatalogs_VENDOR_CATALOG_BLACKSMITH)
        call Register('h00W', VendorCatalogs_VENDOR_CATALOG_WEAPONS)
        call Register('h00X', VendorCatalogs_VENDOR_CATALOG_ARMOR)
        call Register('h00Y', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES)
        call Register('h00Z', VendorCatalogs_VENDOR_CATALOG_MINER)
        call Register('h010', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS)
    endfunction
endlibrary
