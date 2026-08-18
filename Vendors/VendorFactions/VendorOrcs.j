/**
    VendorOrcs

    Author: Valdemar
    Version: 1.1.0

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
    private function Register takes integer unitTypeId, integer catalogType, string profile, string voiceType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profile)
        call VendorLines_BindUnitTypeVoiceType(unitTypeId, voiceType)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Horde")
    endfunction

    private function Init takes nothing returns nothing
        // Fiery Mountain equipment and mining vendors.
        call Register('o011', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_9_TYPE)
        call Register('o012', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_4_TYPE)
        call Register('o013', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_3_TYPE)
        call Register('o00A', VendorCatalogs_VENDOR_CATALOG_ARENA, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_2_TYPE)
        call Register('o00D', VendorCatalogs_VENDOR_CATALOG_MINER, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_5_TYPE)
        call Register('o00G', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_4_TYPE)
        call Register('o00L', VendorCatalogs_VENDOR_CATALOG_MINING_SUPPLIES, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_5_TYPE)
        call Register('o00T', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_1_TYPE)

        // Sereneglade, Thornwoods, and Riverbane forest vendors.
        call Register('o00B', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_3_TYPE)
        call Register('o00E', VendorCatalogs_VENDOR_CATALOG_COOK, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_5_TYPE)
        call Register('o00H', VendorCatalogs_VENDOR_CATALOG_COOKING_SUPPLIES, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_5_TYPE)
        call Register('o00I', VendorCatalogs_VENDOR_CATALOG_ENCHANTING_SUPPLIES, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_6_TYPE)
        call Register('o00K', VendorCatalogs_VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_4_TYPE)
        call Register('o00M', VendorCatalogs_VENDOR_CATALOG_SKINNING_SUPPLIES, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_1_TYPE)
        call Register('o00N', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_3_TYPE)
        call Register('o00O', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_3_TYPE)
        call Register('o00P', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_1_TYPE)
        call Register('o00R', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_5_TYPE)
        call Register('o00S', VendorCatalogs_VENDOR_CATALOG_POTIONS, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_7_TYPE)
        call Register('o00U', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_1_TYPE)
        call Register('o00V', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_3_TYPE)
        call Register('o00W', VendorCatalogs_VENDOR_CATALOG_BEAST_SUPPLIES, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_4_TYPE)

        // Sirensong coastal and jungle vendors.
        call Register('o00C', VendorCatalogs_VENDOR_CATALOG_FISHER, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_1_TYPE)
        call Register('o00F', VendorCatalogs_VENDOR_CATALOG_ALCHEMY_SUPPLIES, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_7_TYPE)
        call Register('o00J', VendorCatalogs_VENDOR_CATALOG_FISHING_SUPPLIES, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_1_TYPE)
        call Register('o00Q', VendorCatalogs_VENDOR_CATALOG_REAGENTS, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_8_TYPE)
        call Register('o00X', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_9_TYPE)
        call Register('o00Y', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_2_TYPE)
        call Register('o00Z', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_4_TYPE)
        call Register('o010', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_3_TYPE)
        call Register('o014', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_8_TYPE)

        // Tavern, jewelry, and mystical-goods specialists.
        call Register('o01H', VendorCatalogs_VENDOR_CATALOG_BARTENDER, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_5_TYPE)
        call Register('o01I', VendorCatalogs_VENDOR_CATALOG_BARTENDER, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_2_TYPE)
        call Register('o01J', VendorCatalogs_VENDOR_CATALOG_JEWELCRAFTER, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_3_TYPE)
        call Register('o01K', VendorCatalogs_VENDOR_CATALOG_SHAMANIC_GOODS, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_8_TYPE)
        call Register('o01L', VendorCatalogs_VENDOR_CATALOG_SHAMANIC_GOODS, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_ORC_MALE_8_TYPE)
        call Register('o01M', VendorCatalogs_VENDOR_CATALOG_FEL_CURIOS, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_ORC_MALE_6_TYPE)
        call Register('o01N', VendorCatalogs_VENDOR_CATALOG_FEL_CURIOS, VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_ORC_MALE_7_TYPE)
    endfunction
endlibrary
