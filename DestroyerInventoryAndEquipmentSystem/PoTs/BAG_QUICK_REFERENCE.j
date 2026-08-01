/*
    DInventory fixed bag tier quick reference

    Read:
        DInvGetBagTierOfUnit(hero)
        DInvBagCapacityOfTier(tier)
        DInvBagNameOfTier(tier)

    Sequential player purchase:
        DInvUpgradeBagForHeroVendor(hero, DINV_BAG_TIER_SMALL)
        DInvUpgradeBagForPlayerVendor(playerId, DINV_BAG_TIER_SMALL)

    Initialization / AI setup:
        DInvSetBagTierForUnit(hero, DINV_BAG_TIER_SMALL)

    Shop registration:
        Shop_AddBagUpgradeService(vendorId, "Small Bag", DINV_BAG_TIER_SMALL, 1000, "Bags")

    Vendor functions return false when the target is not exactly the next tier.
    Charge currency only after a successful direct vendor call.
*/
