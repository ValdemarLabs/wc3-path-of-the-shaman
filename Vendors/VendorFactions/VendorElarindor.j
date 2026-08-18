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
    private function Register takes integer unitTypeId, integer catalogType, string profile, string voiceType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profile)
        call VendorLines_BindUnitTypeVoiceType(unitTypeId, voiceType)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Elarindor")
    endfunction

    private function Init takes nothing returns nothing
        call Register('h00L', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_ELARINDOR_MALE, VL_ELARINDOR_MALE_1_TYPE)
        call Register('h00P', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_ELARINDOR_FEMALE, VL_ELARINDOR_FEMALE_1_TYPE)
        call Register('n00M', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_ELARINDOR_MALE, VL_ELARINDOR_MALE_2_TYPE)
        call Register('h00Q', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, VL_VENDOR_PROFILE_ELARINDOR_FEMALE, VL_ELARINDOR_FEMALE_2_TYPE)
        call Register('h00N', VendorCatalogs_VENDOR_CATALOG_REAGENTS, VL_VENDOR_PROFILE_ELARINDOR_MALE, VL_ELARINDOR_MALE_1_TYPE)
        call Register('h00R', VendorCatalogs_VENDOR_CATALOG_POTIONS, VL_VENDOR_PROFILE_ELARINDOR_FEMALE, VL_ELARINDOR_FEMALE_1_TYPE)
        call Register('h00O', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, VL_VENDOR_PROFILE_ELARINDOR_MALE, VL_ELARINDOR_MALE_2_TYPE)
        call Register('h00S', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, VL_VENDOR_PROFILE_ELARINDOR_FEMALE, VL_ELARINDOR_FEMALE_2_TYPE)
        call Register('h011', VendorCatalogs_VENDOR_CATALOG_JEWELCRAFTER, VL_VENDOR_PROFILE_ELARINDOR_FEMALE, VL_ELARINDOR_FEMALE_1_TYPE)
        call Register('h012', VendorCatalogs_VENDOR_CATALOG_MAGISTER, VL_VENDOR_PROFILE_ELARINDOR_MALE, VL_ELARINDOR_MALE_1_TYPE)
    endfunction
endlibrary
