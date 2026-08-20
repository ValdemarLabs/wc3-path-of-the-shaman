/**
    VendorGoblins

    Author: Valdemar
    Version: 1.1.0

    Description:
    Assigns custom Goblin vendor unit types to travelling, randomized,
    profession, equipment, arena, and general trade catalogs.

    Credits:

    How to install:
    Import after VendorCatalogs.

    API:
    - Registers Goblin vendor unit types automatically during initialization.

**/
library VendorGoblins initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType, string profile, string voiceType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profile)
        call VendorLines_BindUnitTypeVoiceType(unitTypeId, voiceType)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Goblins")
    endfunction

    private function Init takes nothing returns nothing
        call Register('n03W', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE, VL_GENERIC_GOBLIN_MALE_1_TYPE)
        call Register('n03X', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE, VL_GENERIC_GOBLIN_MALE_2_TYPE)
        call Register('n03Y', VendorCatalogs_VENDOR_CATALOG_WEAPONS, VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE, VL_GENERIC_GOBLIN_MALE_1_TYPE)
        call Register('n03Z', VendorCatalogs_VENDOR_CATALOG_ARMOR, VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE, VL_GENERIC_GOBLIN_MALE_2_TYPE)
        call Register('n040', VendorCatalogs_VENDOR_CATALOG_SHIELDS, VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE, VL_GENERIC_GOBLIN_MALE_3_TYPE)
        call Register('n041', VendorCatalogs_VENDOR_CATALOG_FISHER, VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE, VL_GENERIC_GOBLIN_MALE_3_TYPE)
        call Register('n042', VendorCatalogs_VENDOR_CATALOG_MINER, VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE, VL_GENERIC_GOBLIN_MALE_4_TYPE)
        call Register('n043', VendorCatalogs_VENDOR_CATALOG_COOK, VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE, VL_GENERIC_GOBLIN_MALE_3_TYPE)
        call Register('n044', VendorCatalogs_VENDOR_CATALOG_ALCHEMY_SUPPLIES, VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE, VL_GENERIC_GOBLIN_MALE_4_TYPE)
        call Register('n045', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES, VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE, VL_GENERIC_GOBLIN_MALE_1_TYPE)
        call Register('n046', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, VL_VENDOR_PROFILE_GOBLIN_ARENA_MALE, VL_GENERIC_GOBLIN_MALE_3_TYPE)
        call Register('n047', VendorCatalogs_VENDOR_CATALOG_REAGENTS, VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE, VL_GENERIC_GOBLIN_MALE_1_TYPE)
        call Register('n048', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK, VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE, VL_GENERIC_GOBLIN_MALE_4_TYPE)
        call Register('n049', VendorCatalogs_VENDOR_CATALOG_POTIONS, VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE, VL_GENERIC_GOBLIN_MALE_2_TYPE)
        call Register('n04A', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE, VL_GENERIC_GOBLIN_MALE_4_TYPE)
        call Register('n04B', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE, VL_GENERIC_GOBLIN_MALE_1_TYPE)
        call Register('n04C', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS, VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE, VL_GENERIC_GOBLIN_MALE_1_TYPE)
        call Register('n04D', VendorCatalogs_VENDOR_CATALOG_BEAST_SUPPLIES, VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE, VL_GENERIC_GOBLIN_MALE_2_TYPE)
        call Register('n05F', VendorCatalogs_VENDOR_CATALOG_BARTENDER, VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE, VL_GENERIC_GOBLIN_MALE_2_TYPE)
        call Register('n05I', VendorCatalogs_VENDOR_CATALOG_JEWELCRAFTER, VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE, VL_GENERIC_GOBLIN_MALE_2_TYPE)
    endfunction
endlibrary
