/**
    VendorElarindor

    Author: Valdemar
    Version: 1.0.0

    Description:
    Assigns Elarindor vendor unit types to equipment, arcane supply,
    expedition, and faction-quartermaster catalogs with elven voice profiles.

    Credits:

    How to install:
    Import after VendorCatalogs.

    API:
    - Registers Elarindor vendor unit types automatically during initialization.

**/
library VendorElarindor initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType, string profile returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profile)
    endfunction

    private function Init takes nothing returns nothing
        call Register('n04O', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_ELARINDOR_MALE)
        call Register('n04P', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_ELARINDOR_FEMALE)
        call Register('n04Q', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_ELARINDOR_MALE)
        call Register('n04R', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, VL_VENDOR_PROFILE_ELARINDOR_FEMALE)
        call Register('n04S', VendorCatalogs_VENDOR_CATALOG_REAGENTS, VL_VENDOR_PROFILE_ELARINDOR_MALE)
        call Register('n04T', VendorCatalogs_VENDOR_CATALOG_POTIONS, VL_VENDOR_PROFILE_ELARINDOR_FEMALE)
        call Register('n04U', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, VL_VENDOR_PROFILE_ELARINDOR_MALE)
        call Register('n04V', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, VL_VENDOR_PROFILE_ELARINDOR_FEMALE)
    endfunction
endlibrary
