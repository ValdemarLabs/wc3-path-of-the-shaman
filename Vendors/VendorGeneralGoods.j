/**
    GeneralGoodsVendor

    Author: Valdemar
    Version:

    Description:
    Template general goods merchant for the PotS shop system. This vendor sells
    basic potions, salves, water, and field utility items.

    Credits:

    How to install:
    Import after Shop and VendorLines. Replace or extend the unit-type constants
    below for map-specific merchants, then call GeneralGoodsVendor_RegisterUnit
    for hand-picked vendor units if unit-type binding is not enough.

    API:
    - set vendorId = GeneralGoodsVendor_GetVendorId()
    - call GeneralGoodsVendor_RegisterUnit(vendor)
    - call GeneralGoodsVendor_RegisterUnitType(unitTypeId)
    - call GeneralGoodsVendor_BindAIProfile(profileId)

**/
library GeneralGoodsVendor initializer Init requires Shop, VendorLines, optional AI
    globals
        private constant integer VGG_UNIT_TYPE_GOBLIN_MERCHANT = 'nmrk'
        private constant integer VGG_UNIT_TYPE_UTILITIES_VENDOR = 'o62U'
        private constant integer VGG_UNIT_TYPE_HORDE_MARKET = 'o609'
        private constant integer VGG_UNIT_TYPE_THRAKNAR = 'o61U'

        private constant integer VGG_ITEM_MINOR_MANA_POTION = 'I6BS'
        private constant integer VGG_ITEM_MANA_POTION = 'pman'
        private constant integer VGG_ITEM_MINOR_HEALING_POTION = 'I6BD'
        private constant integer VGG_ITEM_HEALING_POTION = 'phea'
        private constant integer VGG_ITEM_SPRING_WATER = 'I60Z'
        private constant integer VGG_ITEM_HEALING_SALVE = 'hslv'
        private constant integer VGG_ITEM_GREATER_HEALING_SALVE = 'I6BC'
        private constant integer VGG_ITEM_MINING_PICK = 'I672'
        private constant integer VGG_ITEM_SKINNING_KNIFE = 'I66M'
        private constant integer VGG_ITEM_CAMP_FIRE = 'I611'

        private integer VGG_VendorId = 0
    endglobals

    public function GetVendorId takes nothing returns integer
        return VGG_VendorId
    endfunction

    public function RegisterUnit takes unit vendor returns boolean
        local boolean result = Shop_RegisterVendorUnit(vendor, VGG_VendorId)

        set vendor = null
        return result
    endfunction

    public function RegisterUnitType takes integer unitTypeId returns boolean
        return Shop_RegisterVendorUnitType(VGG_VendorId, unitTypeId)
    endfunction

    public function BindAIProfile takes integer profileId returns nothing
        static if LIBRARY_AI then
            call AI_AddProfileShopUnitType(profileId, VGG_UNIT_TYPE_GOBLIN_MERCHANT)
            call AI_AddProfileShopUnitType(profileId, VGG_UNIT_TYPE_UTILITIES_VENDOR)
            call AI_AddProfileShopUnitType(profileId, VGG_UNIT_TYPE_HORDE_MARKET)
            call AI_AddProfileShopUnitType(profileId, VGG_UNIT_TYPE_THRAKNAR)
        endif
    endfunction

    private function RegisterStock takes nothing returns nothing
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_MINOR_HEALING_POTION, 35, "Consumables", 200, 8)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_HEALING_POTION, 90, "Consumables", 450, 5)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_HEALING_SALVE, 45, "Consumables", 250, 7)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_GREATER_HEALING_SALVE, 125, "Consumables", 650, 4)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_MINOR_MANA_POTION, 35, "Consumables", 200, 6)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_MANA_POTION, 90, "Consumables", 450, 4)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_SPRING_WATER, 20, "Food and Drink", 120, 6)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_CAMP_FIRE, 35, "Utility", 180, 3)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_MINING_PICK, 75, "Tools", 300, 2)
        call Shop_AddStockEx(VGG_VendorId, VGG_ITEM_SKINNING_KNIFE, 75, "Tools", 300, 2)
    endfunction

    private function RegisterLines takes nothing returns nothing
        call VendorLines_RegisterBasicLines("General Goods Merchant", "Supplies for the road, friend.", "A full pack keeps trouble small.", "Take what you need and leave the rest for someone poorer.", "Safe roads and steady coin.")

        call VendorLines_RegisterLine("General Goods Merchant", VendorLines_LINE_CHATTER, "Rope, water, salves. Heroes always remember them one mile too late.", "")
        call VendorLines_RegisterLine("General Goods Merchant", VendorLines_LINE_CHATTER, "The cheapest supply is the one that gets you home.", "")
        call VendorLines_RegisterLine("General Goods Merchant", VendorLines_LINE_BOUGHT, "Packed and ready. Try not to lose it.", "")
        call VendorLines_RegisterLine("General Goods Merchant", VendorLines_LINE_SOLD, "Used, perhaps. Useless, never.", "")
        call VendorLines_RegisterLine("General Goods Merchant", VendorLines_LINE_BOUGHT_AND_SOLD, "A lighter pack and better supplies. Good business.", "")
        call VendorLines_RegisterLine("General Goods Merchant", VendorLines_LINE_NO_TRANSACTION, "Window-shopping is free. My patience is nearly so.", "")

        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_GOBLIN_MERCHANT, "Goblin General Goods")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_CHATTER, "Guaranteed genuine until proven otherwise!", "")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_CHATTER, "Bulk discount starts immediately after you buy in bulk.", "")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_BOUGHT, "No refunds, but compliments are always accepted.", "")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_SOLD, "I know three people who will pay twice that.", "")
        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_UTILITIES_VENDOR, "Forest Orc Supplies")
        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_HORDE_MARKET, "Forest Orc Supplies")
        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_THRAKNAR, "Forest Orc Supplies")
        call VendorLines_RegisterLine("Forest Orc Supplies", VendorLines_LINE_CHATTER, "Thornwoods punish travelers who pack poorly.", "")
        call VendorLines_RegisterLine("Forest Orc Supplies", VendorLines_LINE_BOUGHT, "Use it well, and return from the wilds.", "")
    endfunction

    private function Init takes nothing returns nothing
        set VGG_VendorId = Shop_CreateVendor("General Goods Merchant", VGG_UNIT_TYPE_GOBLIN_MERCHANT)
        call Shop_SetVendorTypeLabel(VGG_VendorId, "General Goods")
        call GeneralGoodsVendor_RegisterUnitType(VGG_UNIT_TYPE_UTILITIES_VENDOR)
        call GeneralGoodsVendor_RegisterUnitType(VGG_UNIT_TYPE_HORDE_MARKET)
        call GeneralGoodsVendor_RegisterUnitType(VGG_UNIT_TYPE_THRAKNAR)
        call RegisterStock()
        call RegisterLines()
    endfunction
endlibrary
