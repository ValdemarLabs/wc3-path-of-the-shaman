/**
    VendorBags

    Author: Valdemar
    Version:

    Description:
    Bag-space merchant template for the PotS shop system. This vendor sells
    direct DInventory slot upgrades instead of dummy bag items.

    Credits:

    How to install:
    Import after Shop and VendorLines. Graknar is bound by unit type below; call
    VendorBags_RegisterUnit for hand-picked vendor units if unit-type binding is
    not enough.

    API:
    - set vendorId = VendorBags_GetVendorId()
    - call VendorBags_RegisterUnit(vendor)
    - call VendorBags_RegisterUnitType(unitTypeId)
    - call VendorBags_BindAIProfile(profileId)

**/
library VendorBags initializer Init requires Shop, VendorLines, optional AI
    globals
        private constant integer VBAG_UNIT_TYPE_GRAKNAR = 'o61S'

        private constant integer VBAG_SMALL_SLOTS = 6
        private constant integer VBAG_MEDIUM_SLOTS = 12
        private constant integer VBAG_LARGE_SLOTS = 20
        private constant integer VBAG_BASE_SLOTS = 6
        private constant integer VBAG_BASE_PRICE = 1000
        private constant integer VBAG_PRICE_ROUNDING = 500

        private integer VBAG_VendorId = 0
    endglobals

    public function GetVendorId takes nothing returns integer
        return VBAG_VendorId
    endfunction

    public function RegisterUnit takes unit vendor returns boolean
        local boolean result = Shop_RegisterVendorUnit(vendor, VBAG_VendorId)

        set vendor = null
        return result
    endfunction

    public function RegisterUnitType takes integer unitTypeId returns boolean
        return Shop_RegisterVendorUnitType(VBAG_VendorId, unitTypeId)
    endfunction

    public function BindAIProfile takes integer profileId returns nothing
        static if LIBRARY_AI then
            call AI_AddProfileShopUnitType(profileId, VBAG_UNIT_TYPE_GRAKNAR)
        endif
    endfunction

    private function GetPriceForSlots takes integer slots returns integer
        local integer rawPrice = (slots * VBAG_BASE_PRICE + VBAG_BASE_SLOTS - 1) / VBAG_BASE_SLOTS

        return ((rawPrice + VBAG_PRICE_ROUNDING - 1) / VBAG_PRICE_ROUNDING) * VBAG_PRICE_ROUNDING
    endfunction

    private function RegisterStock takes nothing returns nothing
        call Shop_AddBagSlotServiceEx(VBAG_VendorId, "Small Bag Upgrade", VBAG_SMALL_SLOTS, GetPriceForSlots(VBAG_SMALL_SLOTS), "Bags", 1200, 1)
        call Shop_AddBagSlotServiceEx(VBAG_VendorId, "Medium Bag Upgrade", VBAG_MEDIUM_SLOTS, GetPriceForSlots(VBAG_MEDIUM_SLOTS), "Bags", 2200, 1)
        call Shop_AddBagSlotServiceEx(VBAG_VendorId, "Large Bag Upgrade", VBAG_LARGE_SLOTS, GetPriceForSlots(VBAG_LARGE_SLOTS), "Bags", 0, 0)
    endfunction

    private function RegisterLines takes nothing returns nothing
        call VendorLines_RegisterBasicLines("Graknar", "Strong bags. Strong price.", "A bigger pack saves longer walks.", "No bag to carry. I make your pack bigger now.", "Travel lighter, come back richer.")
    endfunction

    private function Init takes nothing returns nothing
        set VBAG_VendorId = Shop_CreateVendor("Graknar", VBAG_UNIT_TYPE_GRAKNAR)
        call RegisterStock()
        call RegisterLines()
    endfunction
endlibrary
