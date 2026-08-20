/**
    VendorSatyrs

    Author: Valdemar
    Version: 1.2.0

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
    private function Register takes integer unitTypeId, integer catalogType, string profileName, string voiceType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profileName)
        call VendorLines_BindUnitTypeVoiceType(unitTypeId, voiceType)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Satyr")
    endfunction

    private function Init takes nothing returns nothing
        call Register('n02Y', VendorCatalogs_VENDOR_CATALOG_ARENA, VL_VENDOR_PROFILE_SATYR_MALE, VL_GENERIC_SATYR_MALE_1_TYPE)
        call Register('n02Z', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, VL_VENDOR_PROFILE_SATYR_FEMALE, VL_GENERIC_SATYR_FEMALE_1_TYPE)
        call Register('n030', VendorCatalogs_VENDOR_CATALOG_REAGENTS, VL_VENDOR_PROFILE_SATYR_FEMALE, VL_GENERIC_SATYR_FEMALE_1_TYPE)
        call Register('n031', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, VL_VENDOR_PROFILE_SATYR_FEMALE, VL_GENERIC_SATYR_FEMALE_1_TYPE)
        call Register('n032', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, VL_VENDOR_PROFILE_SATYR_MALE, VL_GENERIC_SATYR_MALE_1_TYPE)
        call Register('n033', VendorCatalogs_VENDOR_CATALOG_POTIONS, VL_VENDOR_PROFILE_SATYR_FEMALE, VL_GENERIC_SATYR_FEMALE_1_TYPE)
        call Register('n034', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_SATYR_MALE, VL_GENERIC_SATYR_MALE_1_TYPE)
        call Register('n036', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_SATYR_MALE, VL_GENERIC_SATYR_MALE_1_TYPE)
        call Register('n037', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_SATYR_MALE, VL_GENERIC_SATYR_MALE_1_TYPE)
        call Register('n038', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, VL_VENDOR_PROFILE_SATYR_MALE, VL_GENERIC_SATYR_MALE_1_TYPE)
    endfunction
endlibrary
