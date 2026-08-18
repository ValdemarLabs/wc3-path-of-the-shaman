/**
    VendorBags

    Author: Valdemar
    Version: 1.2.0

    Description:
    Bag merchant for the PotS shop system. Each purchase replaces the hero's
    permanent bag with the next fixed tier; tiers cannot be skipped.

    Credits:

    How to install:
    Import after Shop and VoicelinesVendorLines. Graknar is bound by unit type
    below; call VendorBags_RegisterUnit for hand-picked vendor units if needed.

    API:
    - set vendorId = VendorBags_GetVendorId()
    - call VendorBags_RegisterUnit(vendor)
    - call VendorBags_RegisterUnitType(unitTypeId)

**/
library VendorBags initializer Init requires Shop, VoicelinesVendorLines
    globals
        private constant integer VBAG_UNIT_TYPE_GRAKNAR = 'o61S'

        private constant integer VBAG_BASE_SLOTS = 4
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

    private function GetPriceForUpgrade takes integer fromCapacity, integer targetCapacity returns integer
        local integer slots = targetCapacity - fromCapacity
        local integer rawPrice = R2I(I2R(slots * VBAG_BASE_PRICE + VBAG_BASE_SLOTS - 1) / I2R(VBAG_BASE_SLOTS))

        return R2I(I2R(rawPrice + VBAG_PRICE_ROUNDING - 1) / I2R(VBAG_PRICE_ROUNDING)) * VBAG_PRICE_ROUNDING
    endfunction

    private function RegisterStock takes nothing returns nothing
        call Shop_AddBagUpgradeService(VBAG_VendorId, "Small Bag", DINV_BAG_TIER_SMALL, GetPriceForUpgrade(DInvBagCapacityStarting, DInvBagCapacitySmall), "Bags")
        call Shop_AddBagUpgradeService(VBAG_VendorId, "Medium Bag", DINV_BAG_TIER_MEDIUM, GetPriceForUpgrade(DInvBagCapacitySmall, DInvBagCapacityMedium), "Bags")
        call Shop_AddBagUpgradeService(VBAG_VendorId, "Large Bag", DINV_BAG_TIER_LARGE, GetPriceForUpgrade(DInvBagCapacityMedium, DInvBagCapacityLarge), "Bags")
        call Shop_AddBagUpgradeService(VBAG_VendorId, "Traveler's Backpack", DINV_BAG_TIER_TRAVELER, GetPriceForUpgrade(DInvBagCapacityLarge, DInvBagCapacityTraveler), "Bags")
        call Shop_AddBagUpgradeService(VBAG_VendorId, "Explorer's Backpack", DINV_BAG_TIER_EXPLORER, GetPriceForUpgrade(DInvBagCapacityTraveler, DInvBagCapacityExplorer), "Bags")
        call Shop_AddBagUpgradeService(VBAG_VendorId, "Adventurer's Backpack", DINV_BAG_TIER_ADVENTURER, GetPriceForUpgrade(DInvBagCapacityExplorer, DInvBagCapacityAdventurer), "Bags")
        call Shop_AddBagUpgradeService(VBAG_VendorId, "Bottomless Bag", DINV_BAG_TIER_BOTTOMLESS, GetPriceForUpgrade(DInvBagCapacityAdventurer, DInvBagCapacityBottomless), "Bags")
    endfunction

    private function BindVoiceProfile takes nothing returns nothing
        call VendorLines_BindUnitTypeProfile(VBAG_UNIT_TYPE_GRAKNAR, VL_VENDOR_PROFILE_OGRE_BONECRUSHER_BAG_MERCHANT_MALE)
        call VendorLines_BindUnitTypeVoiceType(VBAG_UNIT_TYPE_GRAKNAR, VL_OGRE_BONECRUSHER_MALE_1_TYPE)
    endfunction

    private function Init takes nothing returns nothing
        set VBAG_VendorId = Shop_CreateVendor("Graknar", VBAG_UNIT_TYPE_GRAKNAR)
        call Shop_SetVendorTypeLabel(VBAG_VendorId, "Bags")
        call RegisterStock()
        call BindVoiceProfile()
    endfunction
endlibrary
