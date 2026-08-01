/**
    VendorGoblins

    Author: Valdemar
    Version: 1.0.0

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
    private function Register takes integer unitTypeId, integer catalogType, string profile returns nothing
        call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, profile)
    endfunction

    private function Init takes nothing returns nothing
        call Register('n03W', VendorCatalogs_VENDOR_CATALOG_RANDOMIZED_GOODS, "Goblin Travelling Merchant")
        call Register('n03X', VendorCatalogs_VENDOR_CATALOG_TRAVELLING, "Goblin Travelling Merchant")
        call Register('n03Y', VendorCatalogs_VENDOR_CATALOG_WEAPONS, "Goblin Riverbane")
        call Register('n03Z', VendorCatalogs_VENDOR_CATALOG_ARMOR, "Goblin Riverbane")
        call Register('n040', VendorCatalogs_VENDOR_CATALOG_SHIELDS, "Goblin Riverbane")
        call Register('n041', VendorCatalogs_VENDOR_CATALOG_FISHER, "Goblin Stormhaven")
        call Register('n042', VendorCatalogs_VENDOR_CATALOG_MINER, "Goblin Riverbane")
        call Register('n043', VendorCatalogs_VENDOR_CATALOG_COOK, "Goblin Sirensong")
        call Register('n044', VendorCatalogs_VENDOR_CATALOG_ALCHEMY_SUPPLIES, "Goblin Sirensong")
        call Register('n045', VendorCatalogs_VENDOR_CATALOG_PROFESSION_SUPPLIES, "Goblin Riverbane")
        call Register('n046', VendorCatalogs_VENDOR_CATALOG_QUARTERMASTER, "Goblin Arena Vendor")
        call Register('n047', VendorCatalogs_VENDOR_CATALOG_REAGENTS, "Goblin Sirensong")
        call Register('n048', VendorCatalogs_VENDOR_CATALOG_FOOD_AND_DRINK, "Goblin Stormhaven")
        call Register('n049', VendorCatalogs_VENDOR_CATALOG_POTIONS, "Goblin Riverbane")
        call Register('n04A', VendorCatalogs_VENDOR_CATALOG_RARE_GOODS, "Goblin Travelling Merchant")
        call Register('n04B', VendorCatalogs_VENDOR_CATALOG_ADVENTURING_SUPPLIES, "Goblin Travelling Merchant")
        call Register('n04C', VendorCatalogs_VENDOR_CATALOG_TRADE_GOODS, "Goblin Stormhaven")
        call Register('n04D', VendorCatalogs_VENDOR_CATALOG_BEAST_SUPPLIES, "Goblin Sirensong")
    endfunction
endlibrary
