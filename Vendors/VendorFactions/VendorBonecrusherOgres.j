/**
    VendorBonecrusherOgres

    Author: Valdemar
    Version: 1.1.0

    Description:
    Assigns custom Bonecrusher Ogre vendor unit types to heavy equipment,
    arena, profession, quartermaster, and trade catalogs.

    Credits:

    How to install:
    Import after VendorCatalogs.

    API:
    - Registers Bonecrusher Ogre vendor unit types automatically during initialization.

**/
library VendorBonecrusherOgres initializer Init requires VendorCatalogs
    private function Register takes integer unitTypeId, integer catalogType returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, VL_VENDOR_PROFILE_OGRE_BONECRUSHER_MALE)
        call VendorLines_BindUnitTypeVoiceType(unitTypeId, VL_OGRE_BONECRUSHER_MALE_1_TYPE)
        call Reputation_RegisterUnitTypeFaction(unitTypeId, "Bonecrusher Clan")
    endfunction

    private function Init takes nothing returns nothing
        call Register('n04E', VendorCatalogs_VENDOR_CATALOG_WEAPONS)
        call Register('n04F', VendorCatalogs_VENDOR_CATALOG_ARMOR)
        call Register('n04G', VendorCatalogs_VENDOR_CATALOG_SHIELDS)
        call Register('n04H', VendorCatalogs_VENDOR_CATALOG_ARENA)
        call Register('n04I', VendorCatalogs_VENDOR_CATALOG_MINER)
        call Register('n04J', VendorCatalogs_VENDOR_CATALOG_COOK)
        call Register('n04K', VendorCatalogs_VENDOR_CATALOG_BLACKSMITHING_SUPPLIES)
        call Register('n04L', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES)
        call Register('n04M', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER)
        call Register('n04N', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS)
        call Register('n05G', VendorCatalogs_VENDOR_CATALOG_BARTENDER)
    endfunction
endlibrary
