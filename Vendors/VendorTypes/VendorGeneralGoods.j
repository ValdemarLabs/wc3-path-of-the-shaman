/**
    GeneralGoodsVendor

    Author: Valdemar
    Version: 1.1.0

    Description:
    Template general goods merchant for the PotS shop system. This vendor sells
    basic potions, salves, water, and field utility items.

    Credits:

    How to install:
    Import after Shop and VoicelinesVendorLines. Replace or extend the unit-type
    constants below for map-specific merchants, then call
    GeneralGoodsVendor_RegisterUnit for hand-picked vendor units if needed.

    API:
    - set vendorId = GeneralGoodsVendor_GetVendorId()
    - call GeneralGoodsVendor_RegisterUnit(vendor)
    - call GeneralGoodsVendor_RegisterUnitType(unitTypeId)
    - call GeneralGoodsVendor_BindAIProfile(profileId)

**/
library GeneralGoodsVendor initializer Init requires Shop, VoicelinesVendorLines, optional AI
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

    private function BindVoiceProfiles takes nothing returns nothing
        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_GOBLIN_MERCHANT, "Goblin General Goods")
        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_UTILITIES_VENDOR, "Forest Orc Supplies")
        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_HORDE_MARKET, "Forest Orc Supplies")
        call VendorLines_BindUnitTypeProfile(VGG_UNIT_TYPE_THRAKNAR, "Forest Orc Supplies")
    endfunction

    private function Init takes nothing returns nothing
        set VGG_VendorId = Shop_CreateVendor("General Goods Merchant", VGG_UNIT_TYPE_GOBLIN_MERCHANT)
        call Shop_SetVendorTypeLabel(VGG_VendorId, "General Goods")
        call GeneralGoodsVendor_RegisterUnitType(VGG_UNIT_TYPE_UTILITIES_VENDOR)
        call GeneralGoodsVendor_RegisterUnitType(VGG_UNIT_TYPE_HORDE_MARKET)
        call GeneralGoodsVendor_RegisterUnitType(VGG_UNIT_TYPE_THRAKNAR)
        call RegisterStock()
        call BindVoiceProfiles()
    endfunction
endlibrary
