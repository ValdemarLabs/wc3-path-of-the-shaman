/**
    VendorBags

    Author: Valdemar
    Version: 2.0.2

    Description:
    Shared racial and faction bag merchants for the PotS shop system. Each
    purchase replaces the hero's permanent bag with the next fixed tier;
    tiers cannot be skipped.

    Credits:

    How to install:
    Import after Shop, VoicelinesVendorLines, and Reputation. Replace each
    'XXXX' placeholder after creating its unit type in World Editor, then
    import VendorDialogs after this library so placed generic bag vendors are
    discovered automatically.

    API:
    - set vendorId = VendorBags_GetVendorId()
    - call VendorBags_RegisterUnit(vendor)
    - call VendorBags_RegisterUnitType(unitTypeId)
    - call VendorBags_RegisterUnitTypeEx(unitTypeId, displayName, profile, voiceType, factionName)
    - VendorBags_UNIT_TYPE_* constants expose configured Object Editor rawcodes;
      'XXXX' marks identities whose unit type has not been created yet.

**/
library VendorBags initializer Init requires Shop, VoicelinesVendorLines, Reputation
    globals
        public constant integer UNIT_TYPE_GRAKNAR = 'o61S'

        private constant integer VBAG_UNIT_TYPE_PLACEHOLDER = 'XXXX'

        // Implemented Horde merchants: two regional Orcs. Gorvak still needs a
        // distinct Object Editor unit type; o01O belongs to a non-vendor Shaman.
        public constant integer UNIT_TYPE_GORVAK = 'XXXX'
        public constant integer UNIT_TYPE_THREKKA = 'o01P'
        public constant integer UNIT_TYPE_MAZRUK = 'o01Q'

        // Planned racial and faction merchants. Replace each placeholder after
        // creating its distinct unit type in World Editor.
        public constant integer UNIT_TYPE_HAMU = 'XXXX'
        public constant integer UNIT_TYPE_JARKU = 'XXXX'
        public constant integer UNIT_TYPE_KEXXI = 'XXXX'
        public constant integer UNIT_TYPE_NIBZI = 'XXXX'
        public constant integer UNIT_TYPE_VARETH = 'XXXX'
        public constant integer UNIT_TYPE_BRUGMOK = 'XXXX'
        public constant integer UNIT_TYPE_GARETH = 'XXXX'
        public constant integer UNIT_TYPE_ELSPETH = 'XXXX'
        public constant integer UNIT_TYPE_TOMAS = 'XXXX'
        public constant integer UNIT_TYPE_CAELIRA = 'XXXX'
        public constant integer UNIT_TYPE_BROLIN = 'XXXX'

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
        if unitTypeId == VBAG_UNIT_TYPE_PLACEHOLDER then
            return false
        endif
        return Shop_RegisterVendorUnitType(VBAG_VendorId, unitTypeId)
    endfunction

    public function RegisterUnitTypeEx takes integer unitTypeId, string displayName, string profile, string voiceType, string factionName returns boolean
        local boolean result = VendorBags_RegisterUnitType(unitTypeId)

        if not result then
            return false
        endif
        if displayName != null and displayName != "" then
            call Shop_SetVendorUnitTypeName(unitTypeId, displayName)
        endif
        if profile != null and profile != "" then
            call VendorLines_BindUnitTypeProfile(unitTypeId, profile)
        endif
        if voiceType != null and voiceType != "" then
            call VendorLines_BindUnitTypeVoiceType(unitTypeId, voiceType)
        endif
        if factionName != null and factionName != "" then
            call Reputation_RegisterUnitTypeFaction(unitTypeId, factionName)
        endif
        return true
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

    private function RegisterVendorTypes takes nothing returns nothing
        // Graknar retains his placed-unit owner's faction and quest-giver identity.
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_GRAKNAR, "Graknar", VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_GENERIC_ORC_MALE_5_TYPE, "")

        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_GORVAK, "Gorvak Packhide", VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, VL_GENERIC_ORC_MALE_1_TYPE, "Horde")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_THREKKA, "Threkka Trailpack", VL_VENDOR_PROFILE_ORC_FOREST_MALE, VL_GENERIC_ORC_MALE_3_TYPE, "Horde")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_MAZRUK, "Mazruk Reedstrap", VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, VL_GENERIC_ORC_MALE_8_TYPE, "Horde")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_HAMU, "Hamu Broadpack", VL_VENDOR_PROFILE_TAUREN_HORDE_MALE, VL_GENERIC_TAUREN_MALE_1_TYPE, "Horde")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_JARKU, "Jarku Packweaver", VL_VENDOR_PROFILE_TROLL_HORDE_MALE, VL_GENERIC_TROLL_MALE_1_TYPE, "Horde")

        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_KEXXI, "Kexxi Bagbolt", VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE, VL_GENERIC_GOBLIN_MALE_1_TYPE, "Goblins")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_NIBZI, "Nibzi Cargozip", VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE, VL_GENERIC_GOBLIN_MALE_2_TYPE, "Goblins")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_VARETH, "Vareth Hidehoard", VL_VENDOR_PROFILE_SATYR_MALE, VL_GENERIC_SATYR_MALE_1_TYPE, "Satyr")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_BRUGMOK, "Brugmok Sackback", VL_VENDOR_PROFILE_OGRE_BONECRUSHER_MALE, VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Bonecrusher Clan")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_GARETH, "Gareth Saddler", VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE, VL_GENERIC_HUMAN_MALE_1_TYPE, "Riverbane")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_ELSPETH, "Elspeth Cordwain", VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE, VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Stormhaven")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_TOMAS, "Tomas Waypack", VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE, VL_GENERIC_HUMAN_MALE_2_TYPE, "Human Citizen")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_CAELIRA, "Caelira Starstitch", VL_VENDOR_PROFILE_ELARINDOR_FEMALE, VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, "Elarindor")
        call VendorBags_RegisterUnitTypeEx(UNIT_TYPE_BROLIN, "Brolin Strapforge", VL_VENDOR_PROFILE_DWARF_MORGRIM_MALE, VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Morgrim Clan")
    endfunction

    private function Init takes nothing returns nothing
        set VBAG_VendorId = Shop_CreateVendor("Bag Merchant", 0)
        call Shop_SetVendorTypeLabel(VBAG_VendorId, VendorLines_TYPE_BAGS)
        call RegisterVendorTypes()
        call RegisterStock()
    endfunction
endlibrary
