/**
    VendorTrolls

    Author: Valdemar
    Version: 1.0.0

    Description:
    Assigns Horde Troll vendor unit types to jewelry and voodoo catalogs with
    the shared male Horde Troll merchant voice profile.

    Credits:

    How to install:
    Import after VendorCatalogs and VoicelinesVendorLines.

    API:
    - Registers Horde Troll vendor unit types automatically.

**/
library VendorTrolls initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, VL_VENDOR_PROFILE_TROLL_HORDE_MALE)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Horde")
    endfunction

    private function Init takes nothing returns nothing
        call Register('n05H', VendorCatalogs_VENDOR_CATALOG_JEWELCRAFTER)
        call Register('n05J', VendorCatalogs_VENDOR_CATALOG_VOODOO_GOODS)
    endfunction
endlibrary
